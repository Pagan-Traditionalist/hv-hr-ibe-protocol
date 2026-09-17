#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(jsonlite))

EXPECTED_PROTOCOL <- "HVHR-IBE-RB-1.2"

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

# ---- Stages 1-5: locked artifacts ----
lock_times <- vector("list", 5)
for (stage in 1:5) {
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
  check_file_hash(rec$artifact_path, rec$artifact_md5, paste0("Stage ", stage, " artifact"))
  lock_times[[stage]] <- parse_utc(rec$locked_at, paste0("Stage ", stage, " locked_at"))
}

# ---- Stage 6: independent constructions ----
stage6 <- read_json_rel("receipts/stage06.json", "Stage 6 receipt")
constructor_ids <- character()
freeze_times <- as.POSIXct(character(), tz = "UTC")
stage6_start <- as.POSIXct(NA)

if (!is.null(stage6)) {
  check_protocol(stage6, "Stage 6")
  if (!identical(as.integer(stage6$stage %||% -1), 6L)) add_fail("Stage 6 receipt has wrong stage number")
  if (!(as.character(stage6$status %||% "") %in% c("FROZEN", "PASS"))) add_fail("Stage 6 status must be FROZEN or PASS")
  if (!is_zero(stage6$unresolved_fail_items)) add_fail("Stage 6 unresolved_fail_items must be 0")

  stage6_start <- parse_utc(stage6$stage_started_at, "Stage 6 stage_started_at")
  check_file_hash(stage6$packet_manifest_path, stage6$packet_manifest_md5, "Stage 6 packet manifest")

  constructions <- stage6$constructions %||% list()
  if (length(constructions) != 3) add_fail("Stage 6 must contain exactly three constructions")

  hypotheses <- vapply(constructions, function(x) as.character(x$hypothesis %||% ""), character(1))
  if (!setequal(hypotheses, c("H-R", "H-A", "H-V"))) {
    add_fail("Stage 6 constructions must contain H-R, H-A, and H-V exactly once")
  }
  if (anyDuplicated(hypotheses)) add_fail("Stage 6 hypothesis entries must be unique")

  constructor_ids <- vapply(constructions, function(x) as.character(x$constructor_id %||% ""), character(1))
  if (any(!nzchar(constructor_ids))) add_fail("Every Stage 6 construction needs constructor_id")
  if (anyDuplicated(constructor_ids)) add_fail("Stage 6 constructor identities must be distinct")

  packet_hashes <- vapply(constructions, function(x) as.character(x$packet_manifest_md5 %||% ""), character(1))
  if (any(!nzchar(packet_hashes))) add_fail("Every Stage 6 construction must declare packet_manifest_md5")
  if (length(unique(tolower(packet_hashes))) != 1) add_fail("All Stage 6 constructors must use the same official packet fingerprint")
  if (nzchar(as.character(stage6$packet_manifest_md5 %||% "")) &&
      any(tolower(packet_hashes) != tolower(as.character(stage6$packet_manifest_md5)))) {
    add_fail("Constructor packet fingerprints must match the Stage 6 packet manifest fingerprint")
  }

  for (i in seq_along(constructions)) {
    x <- constructions[[i]]
    label <- paste0("Stage 6 ", x$hypothesis %||% paste0("construction ", i))
    check_file_hash(x$artifact_path, x$artifact_md5, paste0(label, " artifact"))
    if (!isTRUE(x$blind_first_pass_attested)) add_fail(paste0(label, " blind_first_pass_attested must be true"))
    ft <- parse_utc(x$frozen_at, paste0(label, " frozen_at"))
    freeze_times <- c(freeze_times, ft)
    if (!is.na(ft) && !is.na(stage6_start) && ft < stage6_start) add_fail(paste0(label, " frozen_at precedes Stage 6 start"))
  }

  for (stage in 1:5) {
    lt <- lock_times[[stage]]
    if (!is.null(lt) && !is.na(lt) && !is.na(stage6_start) && lt > stage6_start) {
      add_fail(paste0("Stage ", stage, " was locked after Stage 6 began"))
    }
  }
}

# ---- Stage 7: sterile comparative audit ----
stage7 <- read_json_rel("receipts/stage07.json", "Stage 7 receipt")
stage7_done <- as.POSIXct(NA)

if (!is.null(stage7)) {
  check_protocol(stage7, "Stage 7")
  if (!identical(as.integer(stage7$stage %||% -1), 7L)) add_fail("Stage 7 receipt has wrong stage number")
  if (!(as.character(stage7$status %||% "") %in% c("FROZEN", "PASS"))) add_fail("Stage 7 status must be FROZEN or PASS")
  if (!is_zero(stage7$unresolved_fail_items)) add_fail("Stage 7 unresolved_fail_items must be 0")

  auditor_id <- as.character(stage7$auditor_id %||% "")
  if (!nzchar(auditor_id)) add_fail("Stage 7 auditor_id is missing")
  if (nzchar(auditor_id) && auditor_id %in% constructor_ids) add_fail("Stage 7 auditor must not be a Stage 6 constructor")

  audit_start <- parse_utc(stage7$audit_started_at, "Stage 7 audit_started_at")
  stage7_done <- parse_utc(stage7$completed_at, "Stage 7 completed_at")
  if (!is.na(audit_start) && !is.na(stage7_done) && stage7_done < audit_start) add_fail("Stage 7 completed_at precedes audit_started_at")
  if (length(freeze_times) == 3 && all(!is.na(freeze_times)) && !is.na(audit_start) && audit_start < max(freeze_times)) {
    add_fail("Stage 7 began before all Stage 6 constructions were frozen")
  }

  check_file_hash(stage7$artifact_path, stage7$artifact_md5, "Stage 7 audit artifact")
  check_file_hash(stage7$matrix_path, stage7$matrix_md5, "Stage 7 structured audit matrix")

  matrix <- read_json_rel(as.character(stage7$matrix_path %||% ""), "Stage 7 structured audit matrix")
  if (!is.null(matrix)) {
    check_protocol(matrix, "Stage 7 matrix")

    expected_criteria <- paste0("C", 1:8)
    matrix_criteria <- unlist(matrix$criteria %||% list(), use.names = FALSE)
    if (!setequal(as.character(matrix_criteria), expected_criteria)) add_fail("Stage 7 matrix criteria must be exactly C1-C8")

    cells <- matrix$cells %||% list()
    cell_keys <- vapply(cells, function(x) paste(x$court %||% "", x$node %||% "", x$criterion %||% "", sep = "|"), character(1))
    if (anyDuplicated(cell_keys)) add_fail("Stage 7 matrix contains duplicate court/node/criterion cells")

    for (court in c("Court1", "Court2")) {
      legal <- if (court == "Court1") c("H-R+", "H-A+", "≈", "insuf") else c("H-R+", "H-V+", "≈", "insuf")
      for (node in c("B", "T", "G", "C")) {
        for (criterion in expected_criteria) {
          key <- paste(court, node, criterion, sep = "|")
          hits <- which(cell_keys == key)
          if (length(hits) != 1) {
            add_fail(paste0("Stage 7 matrix missing required cell: ", key))
          } else {
            label <- as.character(cells[[hits]]$label %||% "")
            if (!(label %in% legal)) add_fail(paste0("Illegal ordinal label in ", key, ": ", label))
          }
        }
      }
    }

    aggs <- matrix$aggregations %||% list()
    agg_keys <- vapply(aggs, function(x) paste(x$court %||% "", x$node %||% "", x$lens %||% "", sep = "|"), character(1))
    if (anyDuplicated(agg_keys)) add_fail("Stage 7 matrix contains duplicate aggregation rows")

    for (court in c("Court1", "Court2")) {
      legal_net <- if (court == "Court1") c("H-R ahead", "H-A ahead", "underdetermined") else c("H-R ahead", "H-V ahead", "underdetermined")
      for (node in c("B", "T", "G", "C")) {
        for (lens in c("Equal", "C3-heavy", "C1-heavy")) {
          key <- paste(court, node, lens, sep = "|")
          hits <- which(agg_keys == key)
          if (length(hits) != 1) {
            add_fail(paste0("Stage 7 matrix missing required aggregation: ", key))
          } else {
            row <- aggs[[hits]]
            net <- as.character(row$net %||% "")
            if (!(net %in% legal_net)) add_fail(paste0("Illegal aggregation net in ", key, ": ", net))
            tag <- as.character(row$honesty_tag %||% "")
            if (lens == "C3-heavy" && !(tag %in% c("ARGUED+LOCKED", "SMUGGLED"))) {
              add_fail(paste0("C3-heavy aggregation missing legal honesty_tag in ", key))
            }
            if (lens == "C1-heavy" && !(tag %in% c("EVIDENCE-BRIDGE", "SLOGAN-FIT"))) {
              add_fail(paste0("C1-heavy aggregation missing legal honesty_tag in ", key))
            }
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
  auditor_id <- as.character(stage7$auditor_id %||% "")
  if (nzchar(reader_id) && (reader_id %in% constructor_ids || identical(reader_id, auditor_id))) {
    add_fail("Neutrality reader must be independent of Stage 6 constructors and the Stage 7 auditor")
  }

  check_file_hash(neutrality$artifact_path, neutrality$artifact_md5, "Neutrality Gate artifact")
  checked_at <- parse_utc(neutrality$checked_at, "Neutrality checked_at")
  if (!is.na(stage7_done) && !is.na(checked_at) && checked_at < stage7_done) {
    add_fail("Neutrality Gate completed before Stage 7 completed")
  }
}

result <- if (length(failures) == 0) "PASS" else "FAIL"
status <- list(
  protocol_version = EXPECTED_PROTOCOL,
  result = result,
  stage8_allowed = identical(result, "PASS"),
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

cat("Stage 8 allowed: true\n")
quit(save = "no", status = 0)
