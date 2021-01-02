#!/usr/bin/env sh

# Copyright (c) 2018 - 2021, Martin Scheidt (ISC license)
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
TEXlsr=`which mktexlsr`

check_texlive() {
  # check for kpsewhich
  status=0
  command -v kpsewhich >/dev/null 2>&1 || status=1
  if [ $status = 0 ]; then
    log_d "kpsewhich found"
    return 0
  fi
  
  log_e "Program 'kpsewhich' not found."
  log_e "Be sure to use texlive or mactex!"
  exit 1
}

# checks if sudo is available
check_sudo() {
  rootrun=""
  # If we are root, we do note require sudo
  if [ "$EUID"  = 0 ]; then
    log_d "you are root"
    return 0
  fi

  if sudo -v >/dev/null 2>&1; then
    log_d "sudo ok"
    rootrun="sudo"
  else
    log_d "sudo failed"
    # Check if user is root (might be unnecessary)
    if ! [ $(id -u) = 0 ]; then
      log_e "This script must be run as root" 1>&2
      exit 1
    fi
  fi
}

#-------------------------------------------------------------------------------

check_texlive
check_sudo

TEXMFLOCAL=$(kpsewhich --var-value TEXMFLOCAL)

DEVDIR="tikz-trackschematic-dev"

PROJECTDIR=$(pwd -P)

echo ""
echo "Do you wish to link this package from"
echo "$PROJECTDIR/src to"
echo "$TEXMFLOCAL/tex/latex/$DEVDIR?"
echo "(y/n)"
while true; do
  read -p "" answer
  case $answer in
    [Yy]* ) break;;
    [Nn]* ) exit 1;;
    * ) echo "Please answer yes or no.";;
  esac
done

if [ ! -d "$TEXMFLOCAL/tex/latex/$DEVDIR" ]; then
  $rootrun mkdir -p $TEXMFLOCAL/tex/latex/$DEVDIR
fi


$rootrun ln -sfn $PROJECTDIR/src/tikz-trackschematic.sty $TEXMFLOCAL/tex/latex/$DEVDIR/tikz-trackschematic-dev.sty
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.constructions.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.constructions.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.electrics.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.electrics.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.measures.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.measures.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.topology.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.topology.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.trafficcontrol.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.trafficcontrol.code.tex
$rootrun ln -sfn $PROJECTDIR/src/tikzlibrarytrackschematic.vehicles.code.tex $TEXMFLOCAL/tex/latex/$DEVDIR/tikzlibrarytrackschematic-dev.vehicles.code.tex

$rootrun $TEXlsr --quiet
