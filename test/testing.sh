#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

## -- log functions
# Halt on error
set -e

ECHO=`which echo`

error_occured=0

exec 3>&2 # logging stream (file descriptor 3) defaults to STDERR
verbosity=2 # default to show warnings
silent_lvl=0
err_lvl=1
wrn_lvl=2
inf_lvl=3
dbg_lvl=4

log_n() { log $silent_lvl "NOTE: $1"; } # Always prints
log_e() { log $err_lvl "ERROR: $1"; }
log_w() { log $wrn_lvl "WARNING: $1"; }
log_i() { log $inf_lvl "INFO: $1"; } # "info" is already a command
log_d() { log $dbg_lvl "DEBUG: $1"; }
log() {
  if [ $verbosity -ge $1 ]; then
    # Expand escaped characters, wrap at 70 chars, indent wrapped lines
    $ECHO "$2" | fold -w80 -s >&3 || true
  fi
  $ECHO "$2" | fold -w80 -s >> $logfile || true
}

## -- commands
check_tex_distro() {
  # check for latexmk
  status=0
  command -v pdflatex >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    log_d "pdflatex found"
    return 0
  fi
  
  log_e "Program 'pdflatex' not found."
  log_e "Be sure to have texlive or mactex installed!"
  exit 1
}

check_imagemagick() {
  # check for latexmk
  status=0
  command -v compare >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    log_d "compare found"
    return 0
  fi
  
  log_e "Program 'compare' not found."
  log_e "Be sure to have imagemagick installed!"
  exit 1
}

#-------------------------------------------------------------------------------

check_tex_distro
check_imagemagick

mkdir -p .testing

for TEST in $1*.tex; do
  echo "Testing: ${TEST%.*}"
  pdflatex -output-directory=.testing -interaction=batchmode -halt-on-error $TEST 2>&1 > /dev/null
  compare -metric DSSIM -colorspace RGB .testing/${TEST%.*}.pdf ${TEST%.*}_expected.pdf .testing/${TEST%.*}_diff.png
  echo "% difference"
done

log_n "tests passed!"
