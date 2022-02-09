#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

# Halt on error
set -e

## -- pass getopts

usage() { echo "Usage: dev-install.sh [-q] [-b]"; }

verbose=1
batch_mode=0

while getopts ":qb" opt; do
  case ${opt} in
    q ) verbose=0
      ;;
    b ) batch_mode=1
        verbose=0
      ;;
    \? ) usage
         exit 1
      ;;
  esac
done

## -- variables

# destination folder inside the TeX Live installation
DEVDIR="tex/latex/local/tikz-trackschematic-dev"

## -- commands

# check for kpsewhich (and mktexlsr)
check_texlive() {
  status=0
  command -v kpsewhich >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    if [ "$verbose" -eq 1 ]; then
      echo "kpsewhich found"
    fi
    return 0
  fi
  
  echo "Program 'kpsewhich' not found."
  echo "Be sure to use texlive or mactex!"
  exit 1
}

# checks if sudo is available
check_sudo() {
  rootrun=""
  # If we are root, we do note require sudo
  if [ "$EUID"  = 0 ]; then
    if [ "$verbose" -eq 1 ]; then
      echo "you are root"
    fi
    return 0
  fi

  if sudo -v >/dev/null 2>&1; then
    if [ "$verbose" -eq 1 ]; then
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

## -- checking system

check_texlive
check_sudo

TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)
PROJECTDIR=$(pwd -P)

if [ "$batch_mode" -eq 0 ]; then
  echo ""
  echo "Do you wish to link this package from"
  echo "$PROJECTDIR/src to"
  echo "$TEXMFLOCAL/$DEVDIR?"
  echo "(y/n)"
  while true; do
    read -p "" answer
    case $answer in
      [Yy]* ) break;;
      [Nn]* ) exit 1;;
      * ) echo "Please answer yes or no.";;
    esac
  done
fi

## -- copying files

# make sure that destination folder exists
if [ ! -d "$TEXMFLOCAL/$DEVDIR" ]; then
  $rootrun mkdir -p $TEXMFLOCAL/$DEVDIR
fi

# copy every file in src/ and rename it
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

  if [ "$verbose" -eq 1 ]; then
    echo "linked '$DST'"
  fi
done

# update TeX Live installation
TEXlsr=`which mktexlsr`
if [ "$verbose" -eq 1 ]; then
  $rootrun $TEXlsr
else
  $rootrun $TEXlsr --quiet
fi
