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
#
# compare metrics
#
# AE:    absolute error count, number of different pixels (-fuzz affected)
# DSSIM: structural dissimilarity index
# FUZZ:  mean color distance
# MAE:   mean absolute error (normalized), average channel error distance
# MEPP:  mean error per pixel (normalized mean error, normalized peak error)
# MSE:   mean error squared, average of the channel error squared
# NCC:   normalized cross correlation
# PAE:   peak absolute (normalized peak absolute)
# PHASH: perceptual hash for the sRGB and HCLp colorspaces.
# PSNR:  peak signal to noise ratio
# RMSE:  root mean squared (normalized root mean squared)
# SSIM:  structural similarity index

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
    echo $n " - '$NAME' test: $c"
  fi
  pdflatex -output-directory=.testing -interaction=batchmode -halt-on-error $FILE 2>&1 > /dev/null
  if [ $verbose = 1 ]; then
    echo $n "build complete, $c" # it is actually not in percent! But it helps them humans...
  fi
  compare -metric RMSE -colorspace RGB .testing/${NAME}.pdf ${NAME}_expected.pdf NULL:
  if [ $verbose = 1 ]; then
    echo "% difference." # it is actually not in percent! But it helps them humans...
  fi
done

if [ $verbose = 1 ]; then
  echo "-----------"
  echo "tests passed!"
fi
