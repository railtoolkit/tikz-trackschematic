#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

####
# This script produces a .zip-file in accordance to the requirements for CTAN.
# For more information see https://ctan.org/help/upload-pkg.
####

# Halt on error
set -e

## -- pass getopts

usage() { echo "Usage: create-release.sh [-v version]"; }

verbose=1
batch_mode=0

while getopts ":v" opt; do
  case ${opt} in
    v ) batch_mode=1
        verbose=0
      ;;
    \? ) usage
         exit 1
      ;;
  esac
done

## -- cross platform helpers

if [ "`echo -n`" = "-n" ]; then
  n=""
  c="\c"
else
  n="-n"
  c=""
fi

# https://stackoverflow.com/questions/2320564/sed-i-command-for-in-place-editing-to-work-with-both-gnu-sed-and-bsd-osx
sedi () {
    sed --version >/dev/null 2>&1 && sed -i -- "$@" || sed -i "" "$@"
}

## -- get input

if [ "$batch_mode" = 0 ]; then
  echo $n "specify version ( e.g. v0.6 ): $c"
  read VERSION_STR
else
  VERSION_STR=$2
fi
# remove leading character "v"
VERSION_NUM=$(echo $VERSION_STR | cut -c 2-)

RELEASE="tikz-trackschematic-$VERSION_STR"

## -- commands

# check for zip
check_zip() {
  status=0
  command -v zip >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
      echo "zip found"
    fi
    return 0
  fi
  
  echo "Program 'zip' not found."
  echo "Be sure to have zip installed!"
  exit 1
}

check_versionhistory() {
  # check if $VERSION is present in doc/versionhistory.tex
  status=0
  grep -qs "vhEntry{$VERSION_NUM" doc/versionhistory.tex || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
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
  status=0
  grep -qs "Version \[$VERSION_NUM\]" CHANGELOG.md || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
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
    if [ $verbose = 1 ]; then
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
  status=0
  LINE=$(grep "\[$VERSION_NUM\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "...$VERSION_STR"  || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
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
  status=0
  LINE=$(grep "\[Unreleased\]: https://" CHANGELOG.md)
  echo $LINE | grep -qs "/$VERSION_STR..."  || status=1
  if [ $status = 0 ]; then
    if [ $verbose = 1 ]; then
      echo "The URL for [Unreleased] was also updated in CHANGELOG.md! Thx!"
    fi
    return 0
  fi
  
  echo "WARNING: URL for [Unreleased] in CHANGELOG.md does not reflect the current version $VERSION_NUM."
  echo "WARNING: Be sure to edit CHANGELOG.md and specify current version!"

  if [ "$batch_mode" -eq 0 ]; then
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

## -- creating the release

## check for installed software
check_zip

## check if $VERSION is present in README.md and versionhistory.tex
check_versionhistory
check_changelog
check_date
check_url1
check_url2

## create backup-file und update VERSIONDATE in tikz-trackschematic.sty
sed -i".backup" -e"s/%\[VERSIONDATE/\[$DATE $VERSION_STR/g" src/tikz-trackschematic.sty
sedi "/%%\[SCRIPT\]/d" src/tikz-trackschematic.sty
if [ $verbose = 1 ]; then
  echo "Updated version in src/tikz-trackschematic.sty"
fi

## -- (OPTIONAL) recompile manual.tex, examples, symboly_table and snippets.tex` 


## -- create zip-archive
# create temporary folder
TMP=$RELEASE
mkdir -p $TMP

# copy README and .sty-file
cp README.md $TMP/README.md
cp doc/tikz-trackschematic-documentation.sty  $TMP/

# copy and rename documentation
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
if [ $verbose = 1 ]; then
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
if [ $verbose = 1 ]; then
  echo "copied src-files"
fi

# zip package
zip -r $RELEASE.zip $TMP/*
if [ $verbose = 1 ]; then
  echo "compressed the release in $RELEASE.zip"
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
# remove TMP-folder
rm -rf $TMP
# undo changes to tikz-trackschematic.sty by sed
mv src/tikz-trackschematic.sty.backup src/tikz-trackschematic.sty
rm release-note-tmp.md
if [ $verbose = 1 ]; then
  echo "clean up done!"
fi