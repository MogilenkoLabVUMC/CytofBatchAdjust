#!/usr/bin/env Rscript
# Pass any R expression after --args, e.g.
#   docker run image batchadjust basedir=...
args <- commandArgs(trailingOnly = TRUE)
source("/opt/batchadjust/BatchAdjust.R", chdir = TRUE)
eval(parse(text = paste0("BatchAdjust(", paste(args, collapse = ","), ")")))