#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

# Halt on error
set -e

## -- pass getopts

usage() { echo "Usage: dev-install.sh [-q]"; }

verbose=1

while getopts ":q" opt; do
  case ${opt} in
    q ) verbose=0
      ;;
    \? ) usage
         exit 1
      ;;
  esac
done

## -- commands

check_tex_distro() {
  # check for latexmk
  status=0
  command -v pdflatex >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ "$verbose" -eq 1 ]; then
      echo "pdflatex found"
    fi
    return 0
  fi
  
  echo "Program 'pdflatex' not found."
  echo "Be sure to have texlive or mactex installed!"
  exit 1
}

check_trackschematic() {
  # check for tikz-trackschematic
  status=0
  TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
  DEVDIR="tex/latex/tikz-trackschematic-dev"

  ls $TEXMFLOCAL/$DEVDIR/tikz-trackschematic.sty >> /dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ "$verbose" -eq 1 ]; then
      echo "tikz-trackschematic-dev found"
    fi
    return 0
  fi
  
  echo "Library 'tikz-trackschematic-dev' not found."
  echo "Be sure to have tikz-trackschematic-dev installed!"
  exit 1
}

check_imagemagick() {
  # check for ImageMagick/compare
  status=0
  command -v compare >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ "$verbose" -eq 1 ]; then
      echo "compare found"
    fi
    return 0
  fi
  
  echo "Program 'compare' not found."
  echo "Be sure to have ImageMagick installed!"
  exit 1
}

#-------------------------------------------------------------------------------

check_tex_distro
check_trackschematic
check_imagemagick

mkdir -p .testing

for TEST in $1*.tex; do
  if [ "$verbose" -eq 1 ]; then
    echo "Testing: ${TEST%.*}"
  fi
  pdflatex -output-directory=.testing -interaction=batchmode -halt-on-error $TEST 2>&1 > /dev/null
  compare -metric DSSIM -colorspace RGB .testing/${TEST%.*}.pdf ${TEST%.*}_expected.pdf .testing/${TEST%.*}_diff.png
  if [ "$verbose" -eq 1 ]; then
    echo "% difference"
  fi
done

if [ "$verbose" -eq 1 ]; then
  echo "tests passed!"
fi
