#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

#
# Variables in upper case, e.g.: $VARIABLE
# Functions in lower case as action with underscore, e.g.: do_something
#
# Halt on error
set -e

## -- print usage
print_usage() {
cat << EOF  
Usage: ./build.sh [OPTIONS]
install, test or release a package for tikz-trackschematic

 -h, --help               Display help

 -v, --verbose            Run script in verbose mode.

 -b, --batch-mode         Run script with no interaction.

 -l, --local-dev-install  Install as dev-package in local TeX Live environment

 -t, --test               Tests the current src/ against the test/

 -r, --release VERSION    Creates a .zip with the release for given VERSION
                          Semantic Versioning with leading 'v', e.g: v1.0.0

EOF
}

## -- processes getopts

VERBOSE=0
BATCHMODE=0
INSTALL=0
TESTING=0
RELEASE=0

process_arguments() {
  while true; do
    # loop condition - test for empty string:
    if [ -z "$1" ]; then
      break;
    fi
    # loop test
    case $1 in
      -h|--help)
        print_usage
        exit 0
        ;;
      -v|--verbose)
        VERBOSE=1
        ;;
      -b|--batch-mode)
        BATCHMODE=1
        ;;
      -l|--local-dev-install)
        INSTALL=1
        ;;
      -t|--test)
        TESTING=1
        ;;
      -r|--release)
        RELEASE=1
        shift
        if [ -z "$1" ]; then
          print_usage
          exit 1
        fi
        if [ ${1:0:1} = "-" ]; then
          print_usage
          exit 1
        fi
        VERSION_STR=$1
        ;;
      *)
        print_usage
        exit 1
        ;;
    esac
    shift
  done
}

## -- colors
RED="\033[0;31m"
GREEN="\033[0;32m"
COLOR_RESET="\033[0;m"

## -- cross platform helpers

if [ "`echo -n`" = "-n" ]; then
  n=""; c="\c"
else
  n="-n"; c=""
fi

# https://stackoverflow.com/questions/2320564/sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd-osx
sedi () {
  sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}

## -- commands

check_path() {
  if [ ! -d ../tikz-trackschematic ]; then
    echo "${RED}Please run this script from inside the project folder!${COLOR_RESET}"
    exit 1
  fi
}

check_zip() {
  # check for zip
  STATUS=0
  command -v zip >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "zip found"
    fi
    return 0
  fi
  
  echo "Program 'zip' not found."
  echo "Be sure to have zip installed!"
  exit 1
}

check_version_number() {
  while true; do
    # loop condition - test format of $VERSION_STR:
    echo "$VERSION_STR" | egrep -q "v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)?" && break;
    # loop test
    if [ "$BATCHMODE" = 0 ]; then
      echo "${RED}Your version '$VERSION_STR' has not the correct format!${COLOR_RESET}"
      echo $n "Please specify as Semantic Versioning ( e.g. v1.0.0 ): $c"
      read VERSION_STR
    else
      echo "${RED}Your version '$VERSION_STR' has not the correct format!${COLOR_RESET}"
      echo "Please use Semantic Versioning with leading 'v'"
      exit 1
    fi
  done
  # remove leading 'v'
  VERSION_NUM=$(echo $VERSION_STR | cut -c 2-)
}

check_versionhistory() {
  # check if $VERSION is present in doc/versionhistory.tex
  STATUS=0
  grep -qs "vhEntry{$VERSION_NUM" doc/versionhistory.tex || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "Version $VERSION_NUM is present in versionhistory.tex."
    fi
    return 0
  fi
  
  echo "Version $VERSION_NUM not found in versionhistory.tex."
  echo "Be sure to edit versionhistory.tex and specify current version!"
  exit 1
}

check_changelog() {
  # check if $VERSION is present in CHANGELOG.md
  STATUS=0
  grep -qs "Version \[$VERSION_NUM\]" CHANGELOG.md || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "Version $VERSION_NUM is present in CHANGELOG.md."
    fi
    return 0
  fi
  
  echo "Version $VERSION_NUM not found in CHANGELOG.md."
  echo "Be sure to edit CHANGELOG.md and specify current version!"
  exit 1
}

check_date() {
  ## extract DATE from versionhistory.tex and CHANGELOG.md
  LINE_1=$(grep "vhEntry{$VERSION_NUM" doc/versionhistory.tex)
  LINE_2=$(grep "Version \[$VERSION_NUM\]" CHANGELOG.md)
  DATEISO_1=$(echo $LINE_1 | egrep -o '[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])')
  DATEISO_2=$(echo $LINE_2 | egrep -o '[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])')

  if [ $DATEISO_1 = $DATEISO_2 ]; then
    # DATE=$(date "+%Y-%m-%d")
    DATE="$DATEISO_1" 
    if [ $VERBOSE = 1 ]; then
      echo "The date $DATE was extracted from versionhistory.tex and CHANGELOG.md."
    fi
    return 0
  fi
  
  echo "The date in versionhistory.tex and CHANGELOG.md did not match."
  echo "Be sure to edit versionhistory.tex or CHANGELOG.md and modifiy the date!"
  exit 1
}

check_url1() {
  ## extract urls from CHANGELOG.md
  STATUS=0
  LINE=$(grep "\[$VERSION_NUM\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "...$VERSION_STR"  || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "Version $VERSION_NUM URL is present in CHANGELOG.md."
    fi
    return 0
  fi
  
  echo "Version $VERSION_NUM URL was not found in CHANGELOG.md."
  echo "Be sure to edit CHANGELOG.md and specify a URL for the current version!"
  exit 1
}

check_url2() {
  ## extract urls from CHANGELOG.md
  STATUS=0
  LINE=$(grep "\[Unreleased\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "/$VERSION_STR..."  || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "The URL for [Unreleased] was also updated in CHANGELOG.md! Thx!"
    fi
    return 0
  fi
  
  echo "WARNING: URL for [Unreleased] in CHANGELOG.md does not reflect the current version $VERSION_NUM."
  echo "WARNING: Be sure to edit CHANGELOG.md and specify current version!"

  if [ "$BATCHMODE" -eq 0 ]; then
    echo "Do you wish to continue without updated URL for [Unreleased]?"
    echo $n "(y/n) $c"
    while true; do
      read -p "" answer
      case $answer in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  else
    echo "ERROR: Aborting in batch mode!"
    exit 1
  fi
}

create_release() {
  if [ $BATCHMODE = 0 ]; then
    echo ""
    echo "Do you wish to create a release for the version $VERSION_NUM?"
    echo $n "(y/n) $c"
    while true; do
      read -p "" answer
      case $answer in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi

  ## create backup-file und update VERSIONDATE in tikz-trackschematic.sty
  sed -i".backup" -e"s/%\[VERSIONDATE/\[$DATE $VERSION_STR/g" src/tikz-trackschematic.sty
  sedi "/%%\[SCRIPT\]/d" src/tikz-trackschematic.sty
  if [ $VERBOSE = 1 ]; then
    echo "Updated version in src/tikz-trackschematic.sty"
  fi

  ## -- create zip-archive
  # create temporary folder
  TMP=$RELEASE
  mkdir -p $TMP

  # copy README, CHANGELOG, LICENSE and CITATION
  cp README.md $TMP/README.md
  cp CHANGELOG.md $TMP/CHANGELOG.md
  cp LICENSE $TMP/LICENSE
  cp CITATION.cff $TMP/CITATION.cff

  # copy and rename documentation
  cp doc/tikz-trackschematic-documentation.sty  $TMP/
  cp doc/manual.pdf  $TMP/tikz-trackschematic.pdf
  cp doc/manual.tex  $TMP/tikz-trackschematic.tex
  cp doc/snippets.pdf  $TMP/tikz-trackschematic-snippets.pdf
  cp doc/snippets.tex  $TMP/tikz-trackschematic-snippets.tex
  cp doc/symbology-table.pdf  $TMP/tikz-trackschematic-symbology-table.pdf
  cp doc/symbology-table.tex  $TMP/tikz-trackschematic-symbology-table.tex
  mkdir $TMP/tikz-trackschematic-examples
  mkdir $TMP/tikz-trackschematic-snippets
  cp -R doc/examples/*  $TMP/tikz-trackschematic-examples/
  cp -R doc/snippets/*  $TMP/tikz-trackschematic-snippets/
  if [ $VERBOSE = 1 ]; then
    echo "copied documentation"
  fi

  # copy src-files
  for SRC in src/*; do
    EXT=${SRC##*.}
    # do not copy backup created by sed
    if [ $EXT != "backup" ]; then
      cp $SRC $TMP/
    fi
  done
  if [ $VERBOSE = 1 ]; then
    echo "copied src-files"
  fi

  # zip package
  if [ $VERBOSE = 1 ]; then
    zip -r $RELEASE.zip $TMP/*
    echo "compressed the release in $RELEASE.zip"
  else
    zip -r $RELEASE.zip $TMP/*  >/dev/null 2>&1
  fi

  ## -- cleanup
  # remove TMP-folder
  rm -rf $TMP
  # undo changes to tikz-trackschematic.sty by sed
  mv src/tikz-trackschematic.sty.backup src/tikz-trackschematic.sty
  if [ $VERBOSE = 1 ]; then
    echo "clean up done!"
  fi
}

create_release_notes() {
  if [ $BATCHMODE = 0 ]; then
    echo ""
    echo "Do you wish to create a release notes for the version $VERSION_NUM?"
    echo $n "(y/n) $c"
    while true; do
      read -p "" answer
      case $answer in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi
  ## -- create release note as excerpt from CHANGELOG.md
  # determine beginning and end in CHANGELOG.md 
  TOP=$(grep -n "Version \[$VERSION_NUM\]" CHANGELOG.md | cut -d: -f1)
  awk "NR>$TOP" CHANGELOG.md > release-note-tmp.md
  BOTTOM=$(grep -n -m 1 "## Version" release-note-tmp.md | cut -d: -f1)
  BOTTOM=$(( $TOP + $BOTTOM ))
  BOTTOM=$(( $BOTTOM - 2 ))
  TOP=$(( $TOP + 1 ))
  # extract the excerpt
  awk "NR>$TOP&&NR<$BOTTOM" CHANGELOG.md > release-note-$VERSION_STR.md
  sedi "s/###/##/g" release-note-$VERSION_STR.md


  ## -- cleanup
  # remove TMP-file
  rm release-note-tmp.md
}

check_sudo() {
  # checks if sudo is available
  rootrun=""
  # If we are root, we do note require sudo
  if [ "$EUID"  = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "you are root"
    fi
    return 0
  fi

  if sudo -v >/dev/null 2>&1; then
    if [ $VERBOSE = 1 ]; then
      echo "sudo ok"
    fi
    rootrun="sudo"
  else
    echo "sudo failed"
    # Check if user is root (might be unnecessary)
    if ! [ $(id -u) = 0 ]; then
      echo "This script must be run as root" 1>&2
      exit 1
    fi
  fi
}

check_texlive() {
  # check for kpsewhich (and mktexlsr)
  STATUS=0
  command -v kpsewhich >/dev/null 2>&1 || STATUS=1
  command -v mktexlsr  >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "kpsewhich and mktexlsr found"
    fi
    TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
    return 0
  fi
  
  echo "Program 'kpsewhich' not found."
  echo "Be sure to use texlive or mactex!"
  exit 1
}

check_pdflatex() {
  # check for pdflatex
  STATUS=0
  command -v pdflatex >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
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
  STATUS=0
  TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
  DEVDIR="tex/latex/local/tikz-trackschematic-dev"

  ls $TEXMFLOCAL/$DEVDIR/tikz-trackschematic-dev.sty >> /dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
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
  STATUS=0
  command -v compare >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "compare found"
    fi
    return 0
  fi
  
  echo "Program 'compare' not found."
  echo "Be sure to have ImageMagick installed!"
  exit 1
}

run_test_cases() {

  cd test/
  TESTDIR="../test"

  mkdir -p .tex
  STATUS=0

  # Start with an empty List:
  FAILED=""

  if [ $VERBOSE = 1 ]; then
    echo "==========="
    echo "Comparison of the expected appearance with the freshly created."
    echo "-----------"
  fi

  for TEST in `ls $TESTDIR/*.tex`; do
    # setup
    FILE=$(basename "$TEST") # remove path
    NAME=${FILE%.*} # remove extension
    ADD_TO_LIST=0
    #
    if [ $VERBOSE = 1 ]; then
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
      if [ $VERBOSE = 1 ]; then
        echo $n " - ${GREEN}build succesful${COLOR_RESET}: $c"
        echo "${memory_usage}k of memory used."
        # cat .tex/${NAME}.statistics.log
      fi
    else
      STATUS=1
      ADD_TO_LIST=1
      if [ $VERBOSE = 1 ]; then
        echo " - ${RED}build failed${COLOR_RESET}."
      fi
    fi
    #
    #
    ## compare images with following compare metrics
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
    EXIT_CODE=0
    compare -metric RMSE -colorspace RGB .tex/${NAME}.pdf ${NAME}_expected.pdf NULL: >> /dev/null 2>&1 || EXIT_CODE=1
    if [ $EXIT_CODE = 0 ]; then
      if [ $VERBOSE = 1 ]; then
        echo " - ${GREEN}comparison succesful${COLOR_RESET}."
      fi
    else
      STATUS=1
      ADD_TO_LIST=1
      if [ $VERBOSE = 1 ]; then
        echo " - ${RED}comparison failed${COLOR_RESET}."
      fi
    fi
    ## if a test failed add to list
    if [ $ADD_TO_LIST = 1 ]; then
      if [ -z "$FAILED" ]; then
        # first item
        FAILED="$NAME"
      else
        FAILED="$FAILED, $NAME"
      fi
    fi
  done

  if [ $STATUS = 0 ]; then
    if [ $VERBOSE = 1 ]; then
      echo "-----------"
      echo "${GREEN}All tests passed!${COLOR_RESET}"
    fi
    exit 0
  else
    if [ $VERBOSE = 1 ]; then
      echo "-----------"
      echo "${RED}The following tests failed: ${FAILED}!${COLOR_RESET}"
    else
      echo "${RED}Some or all tests failed!${COLOR_RESET}"
    fi
    exit 1
  fi
}

link_dev_files() {
  # destination folder inside the TeX Live installation
  DEVDIR="tex/latex/local/tikz-trackschematic-dev"
  PROJECTDIR=$(pwd -P)
  if [ $BATCHMODE = 0 ]; then
    echo ""
    echo "Do you wish to link this package from"
    echo "$PROJECTDIR/src to"
    echo "$TEXMFLOCAL/$DEVDIR?"
    echo $n "(y/n) $c"
    while true; do
      read -p "" answer
      case $answer in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) echo "Please answer yes or no.";;
      esac
    done
  fi

  # make sure that destination folder exists
  if [ ! -d "$TEXMFLOCAL/$DEVDIR" ]; then
    $rootrun mkdir -p $TEXMFLOCAL/$DEVDIR
  fi

  # link every file in src/ and rename it
  for SRC in src/*; do
    FILE=$(basename "$SRC") # remove path
    NAME=${FILE%.*} # remove extension
    PREFIX=${NAME%%.*}
    POSTFIX=${NAME#*.}
    EXT=${SRC##*.}

    if [ "$PREFIX" = "$POSTFIX" ]; then
      DST="$PREFIX-dev.$EXT"
    else
      DST="$PREFIX-dev.$POSTFIX.$EXT"
    fi

    $rootrun ln -sfn $PROJECTDIR/$SRC $TEXMFLOCAL/$DEVDIR/$DST

    if [ $VERBOSE = 1 ]; then
      echo "linked '$DST'"
    fi
  done

  # update TeX Live installation
  TEXlsr=`which mktexlsr`
  if [ $VERBOSE = 1 ]; then
    $rootrun $TEXlsr
  else
    $rootrun $TEXlsr --quiet
  fi
}

## -- execution
## Process user arguments
process_arguments $@

## do what is requested
if [ $INSTALL = 1 ]; then
  ##
  check_path
  check_texlive
  check_sudo

  ##
  link_dev_files

fi

if [ $TESTING = 1 ]; then
  ##
  check_path
  check_pdflatex
  check_trackschematic
  check_imagemagick
  if [ ! -d $TESTDIR ]; then
    echo "${RED}Did not find test directory!${COLOR_RESET}"
    exit 1
  fi

  ##
  run_test_cases

fi

if [ $RELEASE = 1 ]; then
  ####
  # This script produces a .zip-file in accordance to the requirements for CTAN.
  # For more information see https://ctan.org/help/upload-pkg.
  ####

  ## check if version ist in the correct format
  check_version_number
  RELEASE="tikz-trackschematic-$VERSION_STR"

  ## check if $VERSION is present in README.md and versionhistory.tex
  check_versionhistory
  check_changelog
  check_url1
  check_url2
  check_date

  ## check for installed software
  check_zip

  ##
  create_release
  create_release_notes
fi

#EOF