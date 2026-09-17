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
    protocol_version = "HVHR-IBE-RB-1.2",
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

  for (i in seq_along(artifact_paths)) {
    write_text(file.path(root, artifact_paths[[i]]), paste0("Synthetic Stage ", i, " artifact"))
    rec <- list(
      protocol_version = "HVHR-IBE-RB-1.2",
      stage = i,
      status = "LOCKED",
      artifact_path = artifact_paths[[i]],
      artifact_md5 = md5_rel(root, artifact_paths[[i]]),
      locked_at = sprintf("2026-09-16T01:%02d:00Z", i),
      locked_by = "Owner",
      unresolved_fail_items = 0
    )
    write_json_file(rec, file.path(root, "receipts", sprintf("stage%02d.json", i)))
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

  stage6 <- list(
    protocol_version = "HVHR-IBE-RB-1.2",
    stage = 6,
    status = "FROZEN",
    stage_started_at = "2026-09-16T02:00:00Z",
    packet_manifest_path = "packet-manifest.json",
    packet_manifest_md5 = packet_md5,
    constructions = constructions,
    unresolved_fail_items = 0
  )
  write_json_file(stage6, file.path(root, "receipts", "stage06.json"))

  write_text(file.path(root, "ART-07-audit.md"), "Synthetic audit")
  matrix <- make_matrix()
  matrix_rel <- "receipts/stage07-audit-matrix.json"
  write_json_file(matrix, file.path(root, matrix_rel))

  stage7 <- list(
    protocol_version = "HVHR-IBE-RB-1.2",
    stage = 7,
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
  write_json_file(stage7, file.path(root, "receipts", "stage07.json"))

  write_text(file.path(root, "NEUTRALITY_GATE.md"), "Synthetic Neutrality Gate PASS")
  neutrality <- list(
    protocol_version = "HVHR-IBE-RB-1.2",
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
stopifnot(isTRUE(res1$status$stage8_allowed))

# FAIL: locked artifact changed after receipt
run2 <- make_valid_run()
cat("\nTAMPERED", file = file.path(run2, "ART-02-criteria-lock.md"), append = TRUE)
res2 <- run_gate(run2)
stopifnot(res2$code != 0L)
stopifnot(identical(res2$status$result, "FAIL"))
stopifnot(!isTRUE(res2$status$stage8_allowed))

# FAIL: auditor is also a constructor
run3 <- make_valid_run()
stage7_path <- file.path(run3, "receipts", "stage07.json")
stage7 <- fromJSON(stage7_path, simplifyVector = FALSE)
stage7$auditor_id <- "Constructor-HR"
write_json_file(stage7, stage7_path)
res3 <- run_gate(run3)
stopifnot(res3$code != 0L)
stopifnot(any(grepl("auditor must not be a Stage 6 constructor", res3$status$failures, fixed = TRUE)))

# FAIL: missing one required Stage-7 aggregation, with receipt hash updated so failure is structural
run4 <- make_valid_run()
matrix_path <- file.path(run4, "receipts", "stage07-audit-matrix.json")
matrix <- fromJSON(matrix_path, simplifyVector = FALSE)
matrix$aggregations <- matrix$aggregations[-length(matrix$aggregations)]
write_json_file(matrix, matrix_path)
stage7_path <- file.path(run4, "receipts", "stage07.json")
stage7 <- fromJSON(stage7_path, simplifyVector = FALSE)
stage7$matrix_md5 <- md5_rel(run4, "receipts/stage07-audit-matrix.json")
write_json_file(stage7, stage7_path)
res4 <- run_gate(run4)
stopifnot(res4$code != 0L)
stopifnot(any(grepl("missing required aggregation", res4$status$failures, fixed = TRUE)))

cat("All protocol-gate tests passed.\n")
