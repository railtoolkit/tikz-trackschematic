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

 -h, --help               Display this help message.

 -s, --silent             Run script in silent mode.
                          The -s option overrides any previous -v or -d options.

 -v, --verbose            Run script in verbose mode.
                          The -v option overrides any previous -s or -d options.

 -d, --debug              Run script in debug mode.
                          The -d option overrides any previous -s or -v options.

 -m, --messy              Do not clean up afterwards.

 -n, --non-interactive    Run script with no interaction.

 -i, --install-dev        Install as dev-package in local TeX Live environment.
                          The -i option overrides any previous -u option.

 -u, --uninstall-dev      Deinstall dev-package from local TeX Live environment.
                          The -u option overrides any previous -i option.

 -x, --memory-increase    Increase available TeX memory.

 -t, --test               Tests the current src/ against the test/.

 -c, --compile-doc        Compile documentation sources.

 -y, --compile-symbology  Compile symbology sources.

 -r, --release VERSION    Creates a .zip with the release for given VERSION in
                          Semantic Versioning with leading 'v', e.g: v1.0.0

EOF
}

## -- processes getopts
VERBOSITY=2  # set by cli argument
NOINTERACT=0 # set by cli argument
INSTALL=0    # set by cli argument
TEXMEMORY=0  # set by cli argument
TESTING=0    # set by cli argument
COMPILE=0    # set by cli argument
SYMBOLOGY=0  # set by cli argument
RELEASE=0    # set by cli argument
CLEANUP=1    # set by cli argument

process_arguments() {
  while true; do
    # loop condition - test for empty string:
    if [ -z "$1" ]; then break; fi
    # loop test
    case $1 in
      -h|--help)
        print_usage
        exit 0
        ;;
      -s|--silent)
        VERBOSITY=0
        ;;
      -v|--verbose)
        VERBOSITY=3
        ;;
      -d|--debug)
        VERBOSITY=4
        ;;
      -m|--messy)
        CLEANUP=0
        ;;
      -n|--non-interactive)
        NOINTERACT=1
        ;;
      -i|--install-dev)
        INSTALL=1
        ;;
      -u|--uninstall-dev)
        INSTALL=2
        ;;
      -x|--memory-increase)
        TEXMEMORY=1
        ;;
      -t|--test)
        TESTING=1
        ;;
      -c|--compile-doc)
        COMPILE=1
        ;;
      -y|--compile-symbology)
        SYMBOLOGY=1
        ;;
      -r|--release)
        RELEASE=1
        shift
        if [ -z "$1" ] || [ "`echo $1 | cut -c1-1`" = "-" ]; then
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

## -- run variables
# 
PDFTOPPM_CONVERT=0 # set by check_pdftoppm
POLICY_MOD=0       # set by check_imagemagick_policy
#
ERROR_OCCURRED=0

## -- logging functions

## colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
COLOR_RESET="\033[0;m"

## cross platform echo option
if [ "`echo -n`" = "-n" ]; then
  n=""; c="\c"
else
  n="-n"; c=""
fi

log() {
  NO_LINE_BREAK=0
  case $2 in
    -n) NO_LINE_BREAK=1;;
  esac

  COLOR=${COLOR_RESET}
  case $1 in
    1) COLOR=${RED};;
    2) COLOR=${GREEN};;
    4) COLOR=${YELLOW};;
  esac
  
  if [ $VERBOSITY -ge $1 ]; then
    shift
    if [ $NO_LINE_BREAK = 0 ]; then
      echo "${COLOR}$@${COLOR_RESET}" | fold -s
    else
      shift
      echo $n "${COLOR}$@ $c${COLOR_RESET}" | fold -s
    fi
  fi
}
log_show()  { log 0 $@; } # will always show
log_error() { log 1 $@; } # print message in RED   ; but not when --silent
log_info()  { log 2 $@; } # print message in GREEN ; but not when --silent
log_note()  { log 3 $@; } # print message          ; with --verbose and --debug
log_debug() { log 4 $@; } # print message in YELLOW; only with --debug

## -- user interaction

user_confirmation () {
  if [ ! $NOINTERACT = 1 ]; then
    log_show $@
    log_show -n "(y/n)"
    while true; do
      read -p "" answer
      case $answer in
        [Yy]* ) break;;
        [Nn]* ) exit 1;;
        * ) log_show "Please answer yes or no.";;
      esac
    done
  fi
}

## -- commands

check_path() {
  # test for project specific files
  STATUS=0
  set -- doc/tikz-trackschematic-documentation.sty src/tikz-trackschematic.sty test/turnout.tex
  for FILE in "$@"; do
    if [ ! -e $FILE ]; then
      STATUS=1
    fi
  done
  
  if [ $STATUS = 0 ]; then
    log_note "Build script is within the project folder."
    return 0
  fi

  log_error "Please run this script from inside the project folder!"
  exit 1
}

## checks for installed software

sedi () {
  ## cross platform sed -i option without a backup file name
  # https://stackoverflow.com/questions/2320564/sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd-osx
  sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}

check_zip() {
  # check for zip
  STATUS=0
  command -v zip >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "zip found"
    return 0
  fi
  
  log_error "Program 'zip' not found. Be sure to have zip installed!"
  exit 1
}

check_sudo() {
  # checks if sudo is available
  STATUS=0
  rootrun=""
  # If we are root, we do note require sudo
  if [ "$EUID"  = 0 ]; then
    log_note "you are root"
    return 0
  fi

  command -v sudo >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "sudo found"
    rootrun="sudo"
    return 0
  else
    log_debug "sudo failed."
  fi

  log_error "This script must be run as root!"
  exit 1
}

check_texlive() {
  # check for kpsewhich (and mktexlsr)
  STATUS=0
  command -v kpsewhich >/dev/null 2>&1 || STATUS=1
  command -v mktexlsr  >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "kpsewhich and mktexlsr found"
    TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
    return 0
  fi
  
  log_error "Program 'kpsewhich' or 'mktexlsr' not found. Be sure to use texlive or mactex!"
  exit 1
}

check_latexmk() {
  # check for latexmk
  STATUS=0
  command -v latexmk >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "latexmk found"
    return 0
  fi
  
  log_error "Program 'latexmk' not found. Be sure to have texlive or mactex installed!"
  exit 1
}

check_pdflatex() {
  # check for pdflatex
  STATUS=0
  command -v pdflatex >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "pdflatex found"
    return 0
  fi
  
  log_error "Program 'pdflatex' not found. Be sure to have texlive or mactex installed!"
  exit 1
}

check_imagemagick() {
  # check for ImageMagick/compare
  STATUS=0
  command -v compare >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "compare found"
    return 0
  fi
  
  log_error "Program 'compare' not found. Be sure to have ImageMagick installed!"
  exit 1
}

check_pdftoppm() {
  # check for poppler/pdftoppm
  STATUS=0
  command -v pdftoppm >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "pdftoppm found"
    PDFTOPPM_CONVERT=1
    return 0
  fi
  
  log_note "Program 'pdftoppm' not found."
  # no # exit 1 ## can still modify ImageMagick policy!
}

check_pdf2svg() {
  # check for pdf2svg
  STATUS=0
  command -v pdf2svg >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "pdf2svg found"
    svg_convert="pdf2svg"
    return 0
  fi

  # check for poppler/pdftocairo
  STATUS=0
  command -v pdftocairo >/dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "pdftocairo found"
    svg_convert="pdftocairo -svg"
    return 0
  fi
  
  log_note "Program 'pdf2svg' or 'pdftocairo' not found."
  exit 1
}

check_imagemagick_policy() {
  STATUS=1
  convert -list policy | grep -q "pattern: PDF" || STATUS=0
  if [ $STATUS = 0 ]; then
    log_note "ImageMagick allows to convert PDFs. Great!"
    return 0
  else
    log_note "ImageMagick does not allow to convert PDFs."

    ## check for alternative
    check_pdftoppm # if pdftoppm is available, then PDFTOPPM_CONVERT=1

    if [ $PDFTOPPM_CONVERT = 0 ]; then
      ## modify ImageMagick-6/policy.xml
      user_confirmation "Be sure to have either poppler(-utils) installed or an ImageMagick \
                         policy which allows for PDF conversion! Do you wish to temporaly remove \
                         the policy preventing ImageMagick from converting PDFs?"

      check_sudo

      POLICY_PATH=$(convert -list policy | grep "Path" | awk "NR==1" | cut -d " " -f2) # default /etc/ImageMagick-*/policy.xml
      if [ ! -e $POLICY_PATH ]; then
        VERSION=$(convert --version | grep "Version" | cut -d " " -f3 | cut -d "." -f1 )
        POLICY_PATH="/etc/ImageMagick-${VERSION}/policy.xml"
        if [ ! -e $POLICY_PATH ]; then
          log_error "ImageMagick policy is preventing converting PDFs to PNGs and program \
                    'pdftoppm' was not found. Modifying the policy temporaly failed! Be sure \
                    to have either poppler(-utils) installed or an ImageMagick policy which \
                    allows for PDF conversion!"
          exit 1
        fi
      fi

      POLICY_MOD=1
      $rootrun sed -i".backup" 's/^.*policy.*coder.*none.*PDF.*//' $POLICY_PATH
      log_note "Modified ${POLICY_PATH}!"
    fi
  fi
}

check_trackschematic() {
  # check for tikz-trackschematic
  STATUS=0
  TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
  DEVDIR=$(find $TEXMFLOCAL -name 'tikz-trackschematic-dev')

  ls $DEVDIR/tikz-trackschematic-dev.sty >> /dev/null 2>&1 || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "Package tikz-trackschematic-dev found."
    return 0
  fi
  
  log_note "Package 'tikz-trackschematic-dev' not found - using project src/."

  export TEXINPUTS=.:$(pwd)/src/:$TEXINPUTS
}

## checks for updated repository

check_version_number() {
  while true; do
    # loop condition - test format of $VERSION_STR:
    echo "$VERSION_STR" | egrep -q "v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)?" && break;
    # loop test
    if [ $NOINTERACT = 0 ]; then
      log_error "Your version '$VERSION_STR' has not the correct format!"
      log_show -n "Please specify as Semantic Versioning ( e.g. v1.0.0 ): "
      read VERSION_STR
    else
      log_error "Your version '$VERSION_STR' has not the correct format! \
                Please use Semantic Versioning with leading 'v'"
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
    log_note "Version $VERSION_NUM is present in versionhistory.tex."
    return 0
  fi
  
  log_error "Version $VERSION_NUM not found in versionhistory.tex. \
            Be sure to edit versionhistory.tex and specify current version!"
  exit 1
}

check_changelog() {
  # check if $VERSION is present in CHANGELOG.md
  STATUS=0
  grep -qs "Version \[$VERSION_NUM\]" CHANGELOG.md || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "Version $VERSION_NUM is present in CHANGELOG.md."
    return 0
  fi
  
  log_error "Version $VERSION_NUM not found in CHANGELOG.md. \
            Be sure to edit CHANGELOG.md and specify current version!"
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
    log_note "The date $DATE was extracted from versionhistory.tex and CHANGELOG.md."
    return 0
  fi
  
  log_error "The date in versionhistory.tex and CHANGELOG.md did not match.\
            Be sure to edit versionhistory.tex or CHANGELOG.md and modifiy the date!"
  exit 1
}

check_url1() {
  ## extract urls from CHANGELOG.md
  STATUS=0
  LINE=$(grep "\[$VERSION_NUM\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "...$VERSION_STR"  || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "Version $VERSION_NUM URL is present in CHANGELOG.md."
    return 0
  fi
  
  log_error "Version $VERSION_NUM URL was not found in CHANGELOG.md. \
            Be sure to edit CHANGELOG.md and specify a URL for the current version!"
  exit 1
}

check_url2() {
  ## extract urls from CHANGELOG.md
  STATUS=0
  LINE=$(grep "\[Unreleased\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "/$VERSION_STR..."  || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "The URL for [Unreleased] was also updated in CHANGELOG.md! Thx!"
    return 0
  fi
  
  log_show "WARNING: URL for [Unreleased] in CHANGELOG.md does not reflect the current version $VERSION_NUM."
  log_show "WARNING: Be sure to edit CHANGELOG.md and specify current version!"
  
  user_confirmation "Do you wish to continue without updated URL for [Unreleased]?"

  if [ $NOINTERACT = 1 ]; then
    log_error "Aborting in batch mode!"
    exit 1
  fi
}

## functionality

create_release() {
  ####
  # This function produces a .zip-file in accordance to the requirements for CTAN.
  # For more information see https://ctan.org/help/upload-pkg.
  ####
  user_confirmation "Do you wish to create a release for the version $VERSION_NUM?"

  ## create backup-file und update VERSIONDATE in tikz-trackschematic.sty
  sed -i".backup" -e"s/%\[VERSIONDATE/\[$DATE $VERSION_STR/g" src/tikz-trackschematic.sty
  sedi "/%%\[SCRIPT\]/d" src/tikz-trackschematic.sty
  log_note "Updated version in src/tikz-trackschematic.sty"

  ## -- create zip-archive
  # create temporary folder
  TMP="tikz-trackschematic-$VERSION_STR"
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
  log_note "copied documentation"

  # copy src-files
  for SRC in src/*; do
    EXT=${SRC##*.}
    # do not copy backup created by sed
    if [ $EXT != "backup" ]; then
      cp $SRC $TMP/
    fi
  done
  log_note "copied src-files"

  # zip package
  zip -r $TMP.zip $TMP/*  >/dev/null 2>&1
  log_note "compressed the release in $TMP.zip"
}

create_release_notes() {
  user_confirmation "Do you wish to create a release notes for the version $VERSION_NUM?"

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
}

run_compile_documentation() {
  ## compile order
  # 1. manual, symbology-table, snippets
  # 2. examples
  # 3. symbology
  cd doc/
  mkdir -p .tex
  log_debug "entered documentation dir"

  ## 1. main documentation
  set -- manual symbology-table snippets
  for NAME in "$@"; do
    log_info -n "compiling $NAME:"
    #
    ## TeX build
    EXIT_CODE=0
    /usr/bin/time -p -o .tex/${NAME}.time \
      latexmk -pdf -f -g -emulate-aux-dir -auxdir=.tex -outdir=.tex $NAME.tex >> /dev/null 2>&1 || EXIT_CODE=1
    #
    TIME=$(awk "NR==2" .tex/${NAME}.time | cut -d " " -f2)
    # understanding TeX statistics:
    #   -> https://tex.stackexchange.com/questions/26208/components-of-latexs-memory-usage
    MEMORY_USAGE=$(grep "words of memory out of" .tex/${NAME}.log | cut -d " " -f2)
    MEMORY_USAGE=$(($MEMORY_USAGE/1000))
    #
    if [ $EXIT_CODE = 0 ]; then
      log_info  " - build successful in ${TIME}s and with ${MEMORY_USAGE}k memory."
      #
      mv .tex/$NAME.pdf $NAME.pdf
      log_debug "copied $NAME to doc/"
    else
      ERROR_OCCURRED=1
      log_error " - build failed."
    fi
  done

  ## 2. examples
  cd examples/
  mkdir -p .tex
  EXAMPLEDIR="../examples"
  for EXAMPLE in `ls $EXAMPLEDIR/*.tex`; do
    FILE=$(basename "$EXAMPLE") # remove path
    NAME=${FILE%.*} # remove extension
    #
    log_info -n "compiling $FILE:"
    #
    ## TeX build
    EXIT_CODE=0
    /usr/bin/time -p -o .tex/${NAME}.time \
      latexmk -pdf -f -g -emulate-aux-dir -auxdir=.tex -outdir=.tex $NAME.tex >> /dev/null 2>&1 || EXIT_CODE=1
    #
    TIME=$(awk "NR==2" .tex/${NAME}.time | cut -d " " -f2)
    # understanding TeX statistics:
    #   -> https://tex.stackexchange.com/questions/26208/components-of-latexs-memory-usage
    MEMORY_USAGE=$(grep "words of memory out of" .tex/${NAME}.log | cut -d " " -f2)
    MEMORY_USAGE=$(($MEMORY_USAGE/1000))
    #
    if [ $EXIT_CODE = 0 ]; then
      log_info  " - build successful in ${TIME}s and with ${MEMORY_USAGE}k memory."
      #
      mv .tex/$NAME.pdf $NAME.pdf
      log_debug "copied $NAME to doc/examples/"
      #
      if [ $PDFTOPPM_CONVERT = 0 ]; then
        # 'compare' will convert the pdf to png
        # -> this reasonably fast!
        convert -density 300 ${NAME}.pdf ${NAME}.png >> /dev/null 2>&1
      else
        # use 'pdftoppm' convert the pdf to png
        # -> this is slower!
        pdftoppm -png -r 300 -singlefile ${NAME}.pdf ${NAME}.png
      fi
      log_debug "converted $NAME.pdf to PNG"
    else
      ERROR_OCCURRED=1
      log_error " - build failed."
    fi
  done
  cd ..

  ## 3. symbology

  cd ..
}

run_compile_symbology() {
  cd doc/symbology/
  mkdir -p .tex

  for FILE in symbols_tikz/*.tikz; do
    SYMBOL=$(basename $FILE .tikz)
    log_note "converting: $SYMBOL"

    ## -- header tex file 
    echo '\\documentclass[tikz,border=0]{standalone}' > tmp.tex
    echo '\\usepackage[dev]{tikz-trackschematic}' >> tmp.tex
    echo '\\begin{document}' >> tmp.tex
    echo '\\begin{tikzpicture}[font=\\sffamily]' >> tmp.tex

    ## -- input symbol
    echo '\\input{'$FILE'}' >> tmp.tex

    ## -- footer tex file
    echo '\\end{tikzpicture}' >> tmp.tex
    echo '\\end{document}' >> tmp.tex

    # echo "---------------"
    # cat tmp.tex
    # echo "---------------"

    ## -- compile tmp.tex
    # pdflatex -output-directory=.tex tmp.tex
    pdflatex -output-directory=.tex -interaction=batchmode tmp.tex 2>&1 > /dev/null

    ## -- copy and convert symbols
    ## SVG
    $svg_convert .tex/tmp.pdf symbols_svg/$SYMBOL.svg
    #
    ## PNG
    if [ $PDFTOPPM_CONVERT = 0 ]; then
      # 'compare' will convert the pdf to png
      # -> this reasonably fast!
      convert -density 600 .tex/tmp.pdf symbols_png/$SYMBOL.png >> /dev/null 2>&1
    else
      # use 'pdftoppm' convert the pdf to png
      # -> this is slower!
      pdftoppm -png -r 600 -singlefile .tex/tmp.pdf symbols_png/$SYMBOL.png
    fi
    #
    mv .tex/tmp.pdf symbols_pdf/$SYMBOL.pdf
  done

  cd ../..
}

run_test_cases() {

  cd test/
  TESTDIR="../test"

  mkdir -p .tex
  STATUS=0

  # Start with an empty List:
  FAILED=""

  for TEST in `ls $TESTDIR/*.tex`; do
    # setup
    FILE=$(basename "$TEST") # remove path
    NAME=${FILE%.*} # remove extension
    ADD_TO_LIST=0
    #
    log_info "$NAME test:"
    #
    #
    ## TeX build
    #
    EXIT_CODE=0
    /usr/bin/time -p -o .tex/${NAME}.time \
      pdflatex -output-directory=.tex -interaction=NOINTERACT -halt-on-error ${NAME}.tex >> /dev/null 2>&1 || EXIT_CODE=1
    #
    TIME=$(awk "NR==2" .tex/${NAME}.time | cut -d " " -f2)
    # understanding TeX statistics:
    #   -> https://tex.stackexchange.com/questions/26208/components-of-latexs-memory-usage
    MEMORY_USAGE=$(grep "words of memory out of" .tex/${NAME}.log | cut -d " " -f2)
    MEMORY_USAGE=$(($MEMORY_USAGE/1000))
    #
    if [ $EXIT_CODE = 0 ]; then
      log_info  " - build successful in ${TIME}s and with ${MEMORY_USAGE}k memory."
    else
      STATUS=1
      ADD_TO_LIST=1
      log_error " - build failed."
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
    if [ $PDFTOPPM_CONVERT = 0 ]; then
      # 'compare' will convert the pdf to png
      # unless the policy of ImageMagick prevents it
      # -> this reasonably fast!
      compare -metric RMSE -colorspace RGB .tex/${NAME}.pdf ${NAME}_expected.pdf NULL: >> /dev/null 2>&1 || EXIT_CODE=1
    else
      # use 'pdftoppm' convert the pdf to png
      # then use 'compare' for comparison without converting
      # -> this is slower!
      pdftoppm -png -r 144 -singlefile .tex/${NAME}.pdf .tex/${NAME}
      pdftoppm -png -r 144 -singlefile ${NAME}_expected.pdf .tex/${NAME}_expected
      compare -metric RMSE -colorspace RGB .tex/${NAME}.png .tex/${NAME}_expected.png NULL: >> /dev/null 2>&1 || EXIT_CODE=1
    fi

    if [ $EXIT_CODE = 0 ]; then
      log_info  " - comparison successful."
    else
      STATUS=1
      ADD_TO_LIST=1
      log_error " - comparison failed."
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
    log_info "\n=> All tests passed!\n"
  else
    log_error "\n=> Some or all tests failed!"
    log_debug "The following tests failed: ${FAILED}!"
    ERROR_OCCURRED=1
  fi

  cd ..
}

link_dev_files() {
  # destination folder inside the TeX Live installation
  TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
  DEVDIR="$TEXMFLOCAL/tex/latex/tikz-trackschematic-dev"
  PROJECTDIR=$(pwd -P)

  user_confirmation "Do you wish to install this package for development to $DEVDIR?"

  # make sure that destination folder exists
  if [ ! -d "$DEVDIR" ]; then
    $rootrun mkdir -p $DEVDIR
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

    $rootrun ln -sfn $PROJECTDIR/$SRC $DEVDIR/$DST

    if [ $VERBOSITY = 1 ]; then
      echo "linked '$DST'"
    fi
  done

  # update TeX Live installation
  TEXlsr=`which mktexlsr`
  if [ $VERBOSITY -ge 3 ]; then
    $rootrun $TEXlsr
  else
    $rootrun $TEXlsr --quiet
  fi
}

remove_dev_files() {
  # destination folder inside the TeX Live installation
  cd $DEVDIR # from check_trackschematic
  user_confirmation "Do you wish to remove the package '$DEVDIR'?"

  log_note "removing $DEVDIR!"
  $rootrun rm -f *
  cd ..
  $rootrun rmdir tikz-trackschematic-dev

  # update TeX Live installation
  TEXlsr=`which mktexlsr`
  if [ $VERBOSITY -ge 3 ]; then
    $rootrun $TEXlsr
  else
    $rootrun $TEXlsr --quiet
  fi
}

change_tex_memory() {
  ## compiling snipptes.tex may run out of memory!
  ## to increase available memory find local texmf.cnf:
  TEXMF_PATH=$(kpsewhich -a texmf.cnf | awk "NR==1") # default .../texlive/YYYY/texmf.cnf
  log_note "Found local texmf.cnf at $TEXMF_PATH"
  ##
  ## check for already made changes
  STATUS=0
  grep -qs '%% \[tikz-trackschematic\] increase available memory' $TEXMF_PATH || STATUS=1
  if [ $STATUS = 0 ]; then
    log_note "$TEXMF_PATH has already been modified!"
    return 0
  fi
  ##
  user_confirmation "Do you wish to increase TeX memory by modifying the file $TEXMF_PATH?"
  ## increase available memory
  echo '%% [tikz-trackschematic] increase available memory' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  echo 'main_memory = 12000000' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  echo 'extra_mem_bot = 12000000' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  echo 'font_mem_size = 12000000' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  echo 'pool_size = 12000000' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  echo 'buf_size = 12000000' | $rootrun tee -a $TEXMF_PATH >> /dev/null 2>&1
  ## update TeX Live installation
  TEXlsr=`which mktexlsr`
  if [ $VERBOSITY -ge 3 ]; then
    $rootrun $TEXlsr
  else
    $rootrun $TEXlsr --quiet
  fi
}

cleanup() {
  ## -- cleanup
  ## from create_release
  if [ $CLEANUP = 1 ]; then
    if [ $RELEASE = 1 ]; then
      # remove TMP-folder
      rm -rf $TMP
      # undo changes to tikz-trackschematic.sty by sed
      mv src/tikz-trackschematic.sty.backup src/tikz-trackschematic.sty
      # remove TMP-release-note
      rm release-note-tmp.md
    fi

    ## from check_imagemagick_policy
    if [ $POLICY_MOD = 1 ]; then
      # undo changes to /etc/ImageMagick-6/policy.xml by sed
      $rootrun mv ${POLICY_PATH}.backup $POLICY_PATH
    fi

    ## from run_compile
    if [ $COMPILE = 1 ]; then
      # remove TMP-folder
      rm -rf doc/examples/.tex
      rm -rf doc/.tex
    fi

    ## from run_symbology
    if [ $SYMBOLOGY = 1 ]; then
      # remove TMP-folder
      rm -rf doc/symbology/.tex/
      rm doc/symbology/tmp.tex
    fi

    ## from run_test_cases
    if [ $TESTING = 1 ]; then
      # remove TMP-folder
      rm -rf test/.tex
    fi

    ##
    log_note "Clean up done!"
  fi
}

## -- execution
## Process user arguments
process_arguments $@
check_path 

## do what is requested
if [ $INSTALL = 1 ]; then
  ## install package
  check_texlive
  check_sudo

  ##
  link_dev_files
fi

if [ $INSTALL = 2 ]; then
  ## deinstall package
  check_texlive
  check_trackschematic
  check_sudo

  ##
  remove_dev_files
fi

if [ $TEXMEMORY = 1 ]; then
  ##
  check_texlive
  check_sudo

  ##
  change_tex_memory
fi

if [ $TESTING = 1 ]; then
  ##
  check_pdflatex
  check_trackschematic
  check_imagemagick
  check_imagemagick_policy

  ##
  run_test_cases
fi

if [ $COMPILE = 1 ]; then
  ##
  check_latexmk
  check_trackschematic
  check_imagemagick
  check_imagemagick_policy

  ##
  run_compile_documentation
fi

if [ $SYMBOLOGY = 1 ]; then
  ##
  check_pdflatex
  check_trackschematic
  check_imagemagick
  check_imagemagick_policy
  check_pdf2svg

  ##
  run_compile_symbology
fi

if [ $RELEASE = 1 ]; then
  ## check if version ist in the correct format
  check_version_number

  ## check if $VERSION is present in CHANGELOG.md and versionhistory.tex
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

##
cleanup
##
if [ $ERROR_OCCURRED = 0 ]; then
  exit 0
else
  exit 1
fi
#EOF