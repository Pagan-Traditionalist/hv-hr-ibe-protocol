#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(jsonlite))

full_args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", full_args, value = TRUE)
if (length(file_arg) != 1) stop("Unable to locate test script path")
this_file <- normalizePath(sub("^--file=", "", file_arg))
repo_root <- normalizePath(file.path(dirname(this_file), "..", "..", ".."))
gate_script <- file.path(repo_root, "validation", "protocol-gate", "protocol_gate.R")

write_text <- function(path, text) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(text, path, useBytes = TRUE)
}

md5_rel <- function(root, rel) unname(tools::md5sum(file.path(root, rel)))

write_json_file <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
}

make_matrix <- function() {
  cells <- list()
  k <- 1
  for (court in c("Court1", "Court2")) {
    for (node in c("B", "T", "G", "C")) {
      for (criterion in paste0("C", 1:8)) {
        label <- if (court == "Court1") {
          if (criterion %in% c("C1", "C3")) "H-R+" else if (criterion == "C2") "H-A+" else "≈"
        } else {
          if (criterion %in% c("C1", "C3")) "H-R+" else if (criterion == "C2") "H-V+" else "≈"
        }
        cells[[k]] <- list(court = court, node = node, criterion = criterion, label = label)
        k <- k + 1
      }
    }
  }

  aggs <- list()
  k <- 1
  for (court in c("Court1", "Court2")) {
    for (node in c("B", "T", "G", "C")) {
      aggs[[k]] <- list(court = court, node = node, lens = "Equal", net = "H-R ahead")
      k <- k + 1
      aggs[[k]] <- list(court = court, node = node, lens = "C3-heavy", net = "H-R ahead", honesty_tag = "ARGUED+LOCKED")
      k <- k + 1
      aggs[[k]] <- list(court = court, node = node, lens = "C1-heavy", net = "H-R ahead", honesty_tag = "EVIDENCE-BRIDGE")
      k <- k + 1
    }
  }

  list(
    protocol_version = "HVHR-IBE-RB-1.3",
    criteria = as.list(paste0("C", 1:8)),
    cells = cells,
    aggregations = aggs
  )
}

make_valid_run <- function() {
  root <- tempfile("hvhr-run-")
  dir.create(root, recursive = TRUE)
  dir.create(file.path(root, "receipts"), recursive = TRUE)

  artifact_paths <- c(
    "ART-01-hypotheses.md",
    "ART-02-criteria-lock.md",
    "ART-03-presupposition-tree.md",
    "ART-04-record-lock.md",
    "ART-05-dossier.md"
  )

  for (rel in artifact_paths) write_text(file.path(root, rel), paste0("Synthetic artifact ", rel))
  component_names <- c("hypotheses", "criteria", "presuppositions", "record", "dossier")
  for (stage in 1:2) {
    indices <- if (stage == 1) 1:3 else 4:5
    artifacts <- lapply(indices, function(i) list(
      component = component_names[[i]], artifact_path = artifact_paths[[i]],
      artifact_md5 = md5_rel(root, artifact_paths[[i]])
    ))
    rec <- list(
      protocol_version = "HVHR-IBE-RB-1.3", stage = stage, status = "LOCKED",
      artifacts = artifacts, locked_at = sprintf("2026-09-16T01:%02d:00Z", stage),
      locked_by = "Owner", unresolved_fail_items = 0
    )
    write_json_file(rec, file.path(root, "receipts", sprintf("stage%02d.json", stage)))
  }

  write_text(file.path(root, "packet-manifest.json"), "synthetic official packet")
  packet_md5 <- md5_rel(root, "packet-manifest.json")

  construction_paths <- list(
    "H-R" = "ART-06a-HR-memo.md",
    "H-A" = "ART-06c-HA-memo.md",
    "H-V" = "ART-06b-HV-memo.md"
  )
  constructor_ids <- c("Constructor-HR", "Constructor-HA", "Constructor-HV")
  freeze_times <- c("2026-09-16T03:00:00Z", "2026-09-16T03:05:00Z", "2026-09-16T03:10:00Z")

  constructions <- list()
  j <- 1
  for (hyp in names(construction_paths)) {
    rel <- construction_paths[[hyp]]
    write_text(file.path(root, rel), paste0("Synthetic ", hyp, " memo"))
    constructions[[j]] <- list(
      hypothesis = hyp,
      constructor_id = constructor_ids[[j]],
      artifact_path = rel,
      artifact_md5 = md5_rel(root, rel),
      packet_manifest_md5 = packet_md5,
      frozen_at = freeze_times[[j]],
      blind_first_pass_attested = TRUE
    )
    j <- j + 1
  }

  stage3 <- list(
    protocol_version = "HVHR-IBE-RB-1.3",
    stage = 3,
    status = "FROZEN",
    stage_started_at = "2026-09-16T02:00:00Z",
    packet_manifest_path = "packet-manifest.json",
    packet_manifest_md5 = packet_md5,
    constructions = constructions,
    unresolved_fail_items = 0
  )
  write_json_file(stage3, file.path(root, "receipts", "stage03.json"))

  write_text(file.path(root, "ART-07-audit.md"), "Synthetic audit")
  matrix <- make_matrix()
  matrix_rel <- "receipts/stage04-audit-matrix.json"
  write_json_file(matrix, file.path(root, matrix_rel))

  stage4 <- list(
    protocol_version = "HVHR-IBE-RB-1.3",
    stage = 4,
    status = "PASS",
    auditor_id = "Auditor-Sterile",
    audit_started_at = "2026-09-16T04:00:00Z",
    completed_at = "2026-09-16T05:00:00Z",
    artifact_path = "ART-07-audit.md",
    artifact_md5 = md5_rel(root, "ART-07-audit.md"),
    matrix_path = matrix_rel,
    matrix_md5 = md5_rel(root, matrix_rel),
    unresolved_fail_items = 0
  )
  write_json_file(stage4, file.path(root, "receipts", "stage04.json"))

  write_text(file.path(root, "NEUTRALITY_GATE.md"), "Synthetic Neutrality Gate PASS")
  neutrality <- list(
    protocol_version = "HVHR-IBE-RB-1.3",
    status = "PASS",
    independent_reader_id = "Neutrality-Reader",
    artifact_path = "NEUTRALITY_GATE.md",
    artifact_md5 = md5_rel(root, "NEUTRALITY_GATE.md"),
    checked_at = "2026-09-16T05:30:00Z",
    unresolved_fail_items = 0
  )
  write_json_file(neutrality, file.path(root, "receipts", "neutrality.json"))

  root
}

run_gate <- function(root) {
  out <- system2(file.path(R.home("bin"), "Rscript"), c(gate_script, root), stdout = TRUE, stderr = TRUE)
  code <- attr(out, "status")
  if (is.null(code)) code <- 0L
  status_path <- file.path(root, "protocol_gate_status.json")
  status <- if (file.exists(status_path)) fromJSON(status_path, simplifyVector = TRUE) else NULL
  list(code = code, output = out, status = status)
}

# PASS case
run1 <- make_valid_run()
res1 <- run_gate(run1)
stopifnot(res1$code == 0L)
stopifnot(identical(res1$status$result, "PASS"))
stopifnot(isTRUE(res1$status$stage5_allowed))

# FAIL: locked artifact changed after receipt
run2 <- make_valid_run()
cat("\nTAMPERED", file = file.path(run2, "ART-02-criteria-lock.md"), append = TRUE)
res2 <- run_gate(run2)
stopifnot(res2$code != 0L)
stopifnot(identical(res2$status$result, "FAIL"))
stopifnot(!isTRUE(res2$status$stage5_allowed))

# FAIL: auditor is also a constructor
run3 <- make_valid_run()
stage4_path <- file.path(run3, "receipts", "stage04.json")
stage4 <- fromJSON(stage4_path, simplifyVector = FALSE)
stage4$auditor_id <- "Constructor-HR"
write_json_file(stage4, stage4_path)
res3 <- run_gate(run3)
stopifnot(res3$code != 0L)
stopifnot(any(grepl("auditor must not be a Stage 3 constructor", res3$status$failures, fixed = TRUE)))

# FAIL: missing one required Stage-4 aggregation, with receipt hash updated so failure is structural
run4 <- make_valid_run()
matrix_path <- file.path(run4, "receipts", "stage04-audit-matrix.json")
matrix <- fromJSON(matrix_path, simplifyVector = FALSE)
matrix$aggregations <- matrix$aggregations[-length(matrix$aggregations)]
write_json_file(matrix, matrix_path)
stage4_path <- file.path(run4, "receipts", "stage04.json")
stage4 <- fromJSON(stage4_path, simplifyVector = FALSE)
stage4$matrix_md5 <- md5_rel(run4, "receipts/stage04-audit-matrix.json")
write_json_file(stage4, stage4_path)
res4 <- run_gate(run4)
stopifnot(res4$code != 0L)
stopifnot(any(grepl("missing required aggregation", res4$status$failures, fixed = TRUE)))

# FAIL: consolidation must not allow a missing criterion lock.
run5 <- make_valid_run()
lock_path <- file.path(run5, "receipts", "stage01.json")
rec <- fromJSON(lock_path, simplifyVector = FALSE)
rec$artifacts <- rec$artifacts[-2]
write_json_file(rec, lock_path)
res5 <- run_gate(run5)
stopifnot(res5$code != 0L)
stopifnot(any(grepl("required components", res5$status$failures, fixed = TRUE)))

# FAIL: evidence cannot lock before framing.
run6 <- make_valid_run()
lock_path <- file.path(run6, "receipts", "stage02.json")
rec <- fromJSON(lock_path, simplifyVector = FALSE)
rec$locked_at <- "2026-09-16T00:00:00Z"
write_json_file(rec, lock_path)
res6 <- run_gate(run6)
stopifnot(res6$code != 0L)
stopifnot(any(grepl("Stage 2 locked before Stage 1", res6$status$failures, fixed = TRUE)))

# FAIL: old eight-stage version must not be accepted as a new run.
run7 <- make_valid_run()
lock_path <- file.path(run7, "receipts", "stage01.json")
rec <- fromJSON(lock_path, simplifyVector = FALSE)
rec$protocol_version <- "HVHR-IBE-RB-1.2"
write_json_file(rec, lock_path)
res7 <- run_gate(run7)
stopifnot(res7$code != 0L)
stopifnot(!isTRUE(res7$status$stage5_allowed))

cat("All protocol-gate tests passed.\n")

