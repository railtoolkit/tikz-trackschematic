#!/usr/bin/env sh

# Copyright (c) 2018 - 2022, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

LATEX=$(which pdflatex)
PDF2SVG=$(which pdf2svg)
CONVERT=$(which convert)

mkdir -p .tex

for FILE in symbols_tikz/*.tikz; do
  SYMBOL=$(basename $FILE .tikz)
  echo "converting: $SYMBOL"

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
  # $LATEX -output-directory=.tex tmp.tex
  $LATEX -output-directory=.tex -interaction=batchmode tmp.tex 2>&1 > /dev/null

  ## -- copy and convert symbols
  $PDF2SVG .tex/tmp.pdf symbols_svg/$SYMBOL.svg
  $CONVERT -density 300 .tex/tmp.pdf symbols_png/$SYMBOL.png
  mv .tex/tmp.pdf symbols_pdf/$SYMBOL.pdf

done

## -- cleanup
rm -rf .tex/
rm tmp.tex