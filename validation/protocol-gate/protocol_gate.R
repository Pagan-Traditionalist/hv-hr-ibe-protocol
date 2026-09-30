#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(jsonlite))

EXPECTED_PROTOCOL <- "HVHR-IBE-RB-1.9"

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1) {
  stop("Usage: Rscript validation/protocol-gate/protocol_gate.R /path/to/live-run")
}

run_root <- normalizePath(args[[1]], mustWork = TRUE)
failures <- character()

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}

add_fail <- function(message) {
  failures <<- c(failures, message)
}

is_zero <- function(x) {
  !is.null(x) && length(x) == 1 && !is.na(suppressWarnings(as.numeric(x))) && as.numeric(x) == 0
}

parse_utc <- function(x, label) {
  if (is.null(x) || length(x) != 1 || !nzchar(as.character(x))) {
    add_fail(paste0(label, " is missing"))
    return(as.POSIXct(NA))
  }
  out <- as.POSIXct(as.character(x), format = "%Y-%m-%dT%H:%M:%OSZ", tz = "UTC")
  if (is.na(out)) add_fail(paste0(label, " is not a UTC ISO-8601 timestamp ending in Z"))
  out
}

read_json_rel <- function(path, label) {
  full <- file.path(run_root, path)
  if (!file.exists(full)) {
    add_fail(paste0(label, " missing: ", path))
    return(NULL)
  }
  tryCatch(
    fromJSON(full, simplifyVector = FALSE),
    error = function(e) {
      add_fail(paste0(label, " is not valid JSON: ", conditionMessage(e)))
      NULL
    }
  )
}

actual_md5 <- function(path) {
  full <- file.path(run_root, path)
  if (!file.exists(full)) return(NA_character_)
  unname(tools::md5sum(full))
}

check_file_hash <- function(path, expected, label) {
  if (is.null(path) || !nzchar(as.character(path))) {
    add_fail(paste0(label, " path missing"))
    return(FALSE)
  }
  full <- file.path(run_root, as.character(path))
  if (!file.exists(full)) {
    add_fail(paste0(label, " missing: ", path))
    return(FALSE)
  }
  if (is.null(expected) || !nzchar(as.character(expected))) {
    add_fail(paste0(label, " fingerprint missing"))
    return(FALSE)
  }
  got <- actual_md5(as.character(path))
  if (!identical(tolower(got), tolower(as.character(expected)))) {
    add_fail(paste0(label, " fingerprint mismatch: ", path))
    return(FALSE)
  }
  TRUE
}

check_protocol <- function(rec, label) {
  if (is.null(rec)) return(FALSE)
  if (!identical(as.character(rec$protocol_version %||% ""), EXPECTED_PROTOCOL)) {
    add_fail(paste0(label, " protocol_version must equal ", EXPECTED_PROTOCOL))
    return(FALSE)
  }
  TRUE
}

# ---- Stages 1-2: locked artifacts ----
lock_times <- vector("list", 2)
for (stage in 1:2) {
  rel <- sprintf("receipts/stage%02d.json", stage)
  rec <- read_json_rel(rel, paste0("Stage ", stage, " receipt"))
  if (is.null(rec)) next

  check_protocol(rec, paste0("Stage ", stage))
  if (!identical(as.integer(rec$stage %||% -1), stage)) {
    add_fail(paste0("Stage ", stage, " receipt has wrong stage number"))
  }
  if (!(as.character(rec$status %||% "") %in% c("LOCKED", "FROZEN", "PASS"))) {
    add_fail(paste0("Stage ", stage, " status must be LOCKED, FROZEN, or PASS"))
  }
  if (!is_zero(rec$unresolved_fail_items)) {
    add_fail(paste0("Stage ", stage, " unresolved_fail_items must be 0"))
  }
  if (!nzchar(as.character(rec$locked_by %||% ""))) {
    add_fail(paste0("Stage ", stage, " locked_by is missing"))
  }
  expected_components <- if (stage == 1L) c("hypotheses", "criteria", "presuppositions") else c("record", "dossier")
  components <- as.character(unlist(rec$completed_components %||% list(), use.names = FALSE))
  if (!identical(components, expected_components)) {
    add_fail(paste0("Stage ", stage, " must include all required components in order"))
  }
  check_file_hash(rec$artifact_path, rec$artifact_md5, paste0("Stage ", stage, " artifact"))
  lock_times[[stage]] <- parse_utc(rec$locked_at, paste0("Stage ", stage, " locked_at"))
}

if (all(vapply(lock_times, function(x) !is.null(x) && !is.na(x), logical(1)))) {
  if (lock_times[[2]] < lock_times[[1]]) add_fail("Stage 2 locked before Stage 1")
}

# ---- Stage 3: independent constructions ----
stage3 <- read_json_rel("receipts/stage03.json", "Stage 3 receipt")
constructor_ids <- character()
freeze_times <- as.POSIXct(character(), tz = "UTC")
stage3_start <- as.POSIXct(NA)

if (!is.null(stage3)) {
  check_protocol(stage3, "Stage 3")
  if (!identical(as.integer(stage3$stage %||% -1), 3L)) add_fail("Stage 3 receipt has wrong stage number")
  if (!(as.character(stage3$status %||% "") %in% c("FROZEN", "PASS"))) add_fail("Stage 3 status must be FROZEN or PASS")
  if (!is_zero(stage3$unresolved_fail_items)) add_fail("Stage 3 unresolved_fail_items must be 0")

  stage3_start <- parse_utc(stage3$stage_started_at, "Stage 3 stage_started_at")
  check_file_hash(stage3$packet_manifest_path, stage3$packet_manifest_md5, "Stage 3 packet manifest")

  constructions <- stage3$constructions %||% list()
  if (length(constructions) != 2) add_fail("Stage 3 must contain exactly two constructions")

  hypotheses <- vapply(constructions, function(x) as.character(x$hypothesis %||% ""), character(1))
  if (!setequal(hypotheses, c("H-R", "H-V"))) {
    add_fail("Stage 3 constructions must contain H-R and H-V exactly once")
  }
  if (anyDuplicated(hypotheses)) add_fail("Stage 3 hypothesis entries must be unique")

  constructor_ids <- vapply(constructions, function(x) as.character(x$constructor_id %||% ""), character(1))
  if (any(!nzchar(constructor_ids))) add_fail("Every Stage 3 construction needs constructor_id")
  if (anyDuplicated(constructor_ids)) add_fail("Stage 3 constructor identities must be distinct")

  packet_hashes <- vapply(constructions, function(x) as.character(x$packet_manifest_md5 %||% ""), character(1))
  if (any(!nzchar(packet_hashes))) add_fail("Every Stage 3 construction must declare packet_manifest_md5")
  if (length(unique(tolower(packet_hashes))) != 1) add_fail("All Stage 3 constructors must use the same official packet fingerprint")
  if (nzchar(as.character(stage3$packet_manifest_md5 %||% "")) &&
      any(tolower(packet_hashes) != tolower(as.character(stage3$packet_manifest_md5)))) {
    add_fail("Constructor packet fingerprints must match the Stage 3 packet manifest fingerprint")
  }

  for (i in seq_along(constructions)) {
    x <- constructions[[i]]
    label <- paste0("Stage 3 ", x$hypothesis %||% paste0("construction ", i))
    check_file_hash(x$artifact_path, x$artifact_md5, paste0(label, " artifact"))
    if (!isTRUE(x$blind_first_pass_attested)) add_fail(paste0(label, " blind_first_pass_attested must be true"))
    ft <- parse_utc(x$frozen_at, paste0(label, " frozen_at"))
    freeze_times <- c(freeze_times, ft)
    if (!is.na(ft) && !is.na(stage3_start) && ft < stage3_start) add_fail(paste0(label, " frozen_at precedes Stage 3 start"))
  }

  for (stage in 1:2) {
    lt <- lock_times[[stage]]
    if (!is.null(lt) && !is.na(lt) && !is.na(stage3_start) && lt > stage3_start) {
      add_fail(paste0("Stage ", stage, " was locked after Stage 3 began"))
    }
  }
}

# ---- Stage 4: sterile comparative audit ----
stage4 <- read_json_rel("receipts/stage04.json", "Stage 4 receipt")
stage4_done <- as.POSIXct(NA)

if (!is.null(stage4)) {
  check_protocol(stage4, "Stage 4")
  if (!identical(as.integer(stage4$stage %||% -1), 4L)) add_fail("Stage 4 receipt has wrong stage number")
  if (!(as.character(stage4$status %||% "") %in% c("FROZEN", "PASS"))) add_fail("Stage 4 status must be FROZEN or PASS")
  if (!is_zero(stage4$unresolved_fail_items)) add_fail("Stage 4 unresolved_fail_items must be 0")

  auditor_id <- as.character(stage4$auditor_id %||% "")
  if (!nzchar(auditor_id)) add_fail("Stage 4 auditor_id is missing")
  if (nzchar(auditor_id) && auditor_id %in% constructor_ids) add_fail("Stage 4 auditor must not be a Stage 3 constructor")

  audit_start <- parse_utc(stage4$audit_started_at, "Stage 4 audit_started_at")
  stage4_done <- parse_utc(stage4$completed_at, "Stage 4 completed_at")
  if (!is.na(audit_start) && !is.na(stage4_done) && stage4_done < audit_start) add_fail("Stage 4 completed_at precedes audit_started_at")
  if (length(freeze_times) == 2 && all(!is.na(freeze_times)) && !is.na(audit_start) && audit_start < max(freeze_times)) {
    add_fail("Stage 4 began before all Stage 3 constructions were frozen")
  }

  check_file_hash(stage4$artifact_path, stage4$artifact_md5, "Stage 4 audit artifact")
  check_file_hash(stage4$matrix_path, stage4$matrix_md5, "Stage 4 structured audit matrix")

  matrix <- read_json_rel(as.character(stage4$matrix_path %||% ""), "Stage 4 structured audit matrix")
  if (!is.null(matrix)) {
    check_protocol(matrix, "Stage 4 matrix")

    expected_criteria <- paste0("C", 1:8)
    matrix_criteria <- unlist(matrix$criteria %||% list(), use.names = FALSE)
    if (!setequal(as.character(matrix_criteria), expected_criteria)) add_fail("Stage 4 matrix criteria must be exactly C1-C8")

    cells <- matrix$cells %||% list()
    if (length(cells) != 32) add_fail("Stage 4 matrix must contain exactly 32 comparison cells")
    if (any(vapply(cells, function(x) !identical(as.character(x$court %||% ""), "HR-HV"), logical(1)))) {
      add_fail("Stage 4 matrix contains an unexpected comparison")
    }
    cell_keys <- vapply(cells, function(x) paste(x$court %||% "", x$node %||% "", x$criterion %||% "", sep = "|"), character(1))
    if (anyDuplicated(cell_keys)) add_fail("Stage 4 matrix contains duplicate court/node/criterion cells")

    for (court in "HR-HV") {
      legal <- c("H-R+", "H-V+", "≈", "insuf")
      for (node in c("B", "T", "G", "C")) {
        for (criterion in expected_criteria) {
          key <- paste(court, node, criterion, sep = "|")
          hits <- which(cell_keys == key)
          if (length(hits) != 1) {
            add_fail(paste0("Stage 4 matrix missing required cell: ", key))
          } else {
            label <- as.character(cells[[hits]]$label %||% "")
            if (!(label %in% legal)) add_fail(paste0("Illegal ordinal label in ", key, ": ", label))
          }
        }
      }
    }


  }
}

# ---- Independent Neutrality Gate ----
neutrality <- read_json_rel("receipts/neutrality.json", "Neutrality receipt")
if (!is.null(neutrality)) {
  check_protocol(neutrality, "Neutrality")
  if (!identical(as.character(neutrality$status %||% ""), "PASS")) add_fail("Neutrality Gate must return PASS")
  if (!is_zero(neutrality$unresolved_fail_items)) add_fail("Neutrality unresolved_fail_items must be 0")

  reader_id <- as.character(neutrality$independent_reader_id %||% "")
  if (!nzchar(reader_id)) add_fail("Neutrality independent_reader_id is missing")
  auditor_id <- as.character(stage4$auditor_id %||% "")
  if (nzchar(reader_id) && (reader_id %in% constructor_ids || identical(reader_id, auditor_id))) {
    add_fail("Neutrality reader must be independent of Stage 3 constructors and the Stage 4 auditor")
  }

  check_file_hash(neutrality$artifact_path, neutrality$artifact_md5, "Neutrality Gate artifact")
  checked_at <- parse_utc(neutrality$checked_at, "Neutrality checked_at")
  if (!is.na(stage4_done) && !is.na(checked_at) && checked_at < stage4_done) {
    add_fail("Neutrality Gate completed before Stage 4 completed")
  }
}

result <- if (length(failures) == 0) "PASS" else "FAIL"
status <- list(
  protocol_version = EXPECTED_PROTOCOL,
  result = result,
  stage5_allowed = identical(result, "PASS"),
  checked_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  failures = unname(failures)
)

status_path <- file.path(run_root, "protocol_gate_status.json")
write_json(status, status_path, auto_unbox = TRUE, pretty = TRUE, null = "null")

cat(paste0("Protocol Gate: ", result, "\n"))
if (length(failures) > 0) {
  for (f in failures) cat(paste0("- ", f, "\n"))
  quit(save = "no", status = 1)
}

cat("Stage 5 allowed: true\n")
quit(save = "no", status = 0)
