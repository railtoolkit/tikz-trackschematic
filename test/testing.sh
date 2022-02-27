#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

# Halt on error
set -e

## -- pass getopts

usage() { echo "Usage: testing.sh [-q]"; }

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
# colors
Red="\033[0;31m"
Green="\033[0;32m"
Reset="\033[0;m"
# directory
TESTDIR="../test"
if [ -d ../tikz-trackschematic ]; then
  cd test/
fi

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
if [ ! -d $TESTDIR ]; then
  echo "${Red}Do not find test directory!${Reset}"
  exit 1
fi

if [ "`echo -n`" = "-n" ]; then
  n=""
  c="\c"
else
  n="-n"
  c=""
fi

## -- Testing

mkdir -p .tex
test_status=0
# Start with an empty List:
FAILED=""

if [ $verbose = 1 ]; then
  echo "==========="
  echo "Comparison of the expected appearance with the freshly created."
  echo "-----------"
fi

for TEST in `ls $TESTDIR/*.tex`; do
  # setup
  FILE=$(basename "$TEST") # remove path
  NAME=${FILE%.*} # remove extension
  add_to_list=0
  #
  if [ $verbose = 1 ]; then
    echo "$NAME test:"
  fi
  #
  #
  ## TeX build
  #
  exit_code_pdflatex=0
  pdflatex -output-directory=.tex -interaction=batchmode -halt-on-error ${NAME}.tex >> /dev/null 2>&1 || exit_code_pdflatex=1
  # understanding TeX statistics:
  #   -> https://tex.stackexchange.com/questions/26208/components-of-latexs-memory-usage
  # TOP=$(grep -n "Here is how much of TeX's memory you used:" .tex/${NAME}.log | cut -d: -f1)
  # BOTTOM=$(($(grep -n "stack positions out of" .tex/${NAME}.log | cut -d: -f1) + 1))
  # awk "NR>$TOP&&NR<$BOTTOM" .tex/${NAME}.log  > .tex/${NAME}.statistics.log
  memory_usage=$(grep "words of memory out of" .tex/${NAME}.log | cut -d " " -f2)
  memory_usage=$(($memory_usage/1000))
  if [ $exit_code_pdflatex = 0 ]; then
    if [ $verbose = 1 ]; then
      echo $n " - ${Green}build succesful${Reset}: $c"
      echo "${memory_usage}k of memory used."
      # cat .tex/${NAME}.statistics.log
    fi
  else
    test_status=1
    add_to_list=1
    if [ $verbose = 1 ]; then
      echo " - ${Red}build failed${Reset}."
    fi
  fi
  #
  #
  ## compare images
  #
  # compare metrics
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
  #
  exit_code_compare=0
  compare -metric RMSE -colorspace RGB .tex/${NAME}.pdf ${NAME}_expected.pdf NULL: >> /dev/null 2>&1 || exit_code_compare=1
  if [ $exit_code_compare = 0 ]; then
    if [ $verbose = 1 ]; then
      echo " - ${Green}comparison succesful${Reset}."
    fi
  else
    test_status=1
    add_to_list=1
    if [ $verbose = 1 ]; then
      echo " - ${Red}comparison failed${Reset}."
    fi
  fi
  #
  #
  ## if a test failed add to list
  if [ $add_to_list = 1 ]; then
    if [ -z "$FAILED" ]; then
      # first item
      FAILED="$NAME"
    else
      FAILED="$FAILED, $NAME"
    fi
  fi
done

## -- finishing

if [ $test_status = 0 ]; then
  if [ $verbose = 1 ]; then
    echo "-----------"
    echo "${Green}All tests passed!${Reset}"
  fi
  exit 0
else
  if [ $verbose = 1 ]; then
    echo "-----------"
    echo "${Red}The following tests failed: ${FAILED}!${Reset}"
  else
    echo "${Red}Some or all tests failed!${Reset}"
  fi
  exit 1
fi

EOF