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

## -- variables
TESTDIR="../test"

## -- commands

check_tex_distro() {
  # check for latexmk
  status=0
  command -v pdflatex >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
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
  DEVDIR="tex/latex/local/tikz-trackschematic-dev"

  ls $TEXMFLOCAL/$DEVDIR/tikz-trackschematic-dev.sty >> /dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
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
    if [ $verbose = 1 ]; then
      echo "compare found"
    fi
    return 0
  fi
  
  echo "Program 'compare' not found."
  echo "Be sure to have ImageMagick installed!"
  exit 1
}

## -- checking system

check_tex_distro
check_trackschematic
check_imagemagick

if [ "`echo -n`" = "-n" ]; then
  n=""
  c="\c"
else
  n="-n"
  c=""
fi

## -- doing the tests

mkdir -p .testing

if [ $verbose = 1 ]; then
  echo "==========="
  echo "Comparison of the expected appearance with the freshly created."
  echo "-----------"
fi

for TEST in `ls $TESTDIR/*.tex`; do
  FILE=$(basename "$TEST") # remove path
  NAME=${FILE%.*} # remove extension
  if [ $verbose = 1 ]; then
    echo $n "'$NAME' test: $c"
  fi
  pdflatex -output-directory=.testing -interaction=batchmode -halt-on-error $FILE 2>&1 > /dev/null
  compare -metric DSSIM -colorspace RGB .testing/${NAME}.pdf ${NAME}_expected.pdf NULL:
  if [ $verbose = 1 ]; then
    echo "% difference." # it is actually not in percent! But it helps them humans...
  fi
done

if [ $verbose = 1 ]; then
  echo "-----------"
  echo "tests passed!"
fi
