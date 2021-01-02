#!/usr/bin/env sh

# Copyright (c) 2018 - 2021, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

LATEXMK=`which latexmk`
PDF2SVG=`which pdf2svg`

SYMBOLS='
  block_clearing_point_forward
  block_signal_forward
  braking_point_forward
  bridge
  bufferstop_forward
  clearing_point
  combined_signal_forward
  danger_point_forward
  derailer_left_forward
  diamond_crossing_left
  distant_signal_forward
  distant_speed_signal_forward
  double-slip_turnout_left
  end_of_movement_authority_forward
  interlocking
  level_crossing_single
  main_track
  parked_vehicles
  platform_left
  route_clearing_point_forward
  route_signal_forward
  secondary_track
  shunt_limit_forward
  shunt_signal_forward
  shunt_signal_forward_locked
  speed_signal_forward
  train_direction_forward
  train_drive_automatic
  train_drive_human
  train_ghost_direction_forward
  train_moving_fast_forward
  train_moving_forward
  train_moving_slow_forward
  train_shunt_mode_forward
  train_shunting_forward
  transmitter_right
  transmitter_right_forward
  turnout_left_forward
  turnout_left_forward_left_position
  turnout_left_forward_moving_points
  turnout_left_forward_right_position
  turnout_with_fouling_left_forward
  view_point_forward
'

for SYMBOL in $SYMBOLS; do IFS=",";
  set -- $SYMBOL;
  # header tex file 
  echo '\\documentclass[tikz,border=2,preview=true,convert]{standalone}' > tmp.tex
  echo '\\IfFileExists{tikzlibrarytrackschematic-dev.code.tex}{%' >> tmp.tex
  echo '\\usetikzlibrary{trackschematic-dev.topology}' >> tmp.tex
  echo '\\usetikzlibrary{trackschematic-dev.trafficcontrol}' >> tmp.tex
  echo '\\usetikzlibrary{trackschematic-dev.vehicles}' >> tmp.tex
  echo '\\usetikzlibrary{trackschematic-dev.constructions}' >> tmp.tex
  echo '\\usetikzlibrary{trackschematic-dev.measures}' >> tmp.tex
  echo '}{\\usetikzlibrary{trackschematic}}' >> tmp.tex
  echo '\\begin{document}' >> tmp.tex
  echo '\\begin{tikzpicture}[font=\\sffamily]' >> tmp.tex
  echo '\\path (-0.1,-1.1) rectangle (6.1,1.1);' >> tmp.tex
  # input symbol
  echo '\\input{../snippets/'$1'.tikz}' >> tmp.tex
  # footer tex file
  echo '\\end{tikzpicture}' >> tmp.tex
  echo '\\end{document}' >> tmp.tex
  # compile tmp.tex
  $LATEXMK -auxdir=.tex -outdir=.tex -bibtex- -f -pdf -shell-escape -interaction=nonstopmode tmp.tex
  # copy and convert symbols
  mv tmp-0.png symbols_png/$1.png
  $PDF2SVG tmp.pdf symbols_svg/$1.svg
  mv tmp.pdf symbols_pdf/$1.pdf
  # cleanup
  $LATEXMK -c
  rm tmp.tex
done
