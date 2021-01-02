#!/usr/bin/env sh

# Copyright (c) 2018 - 2021, Martin Scheidt (ISC license)
# Permission to use, copy, modify, and/or distribute this file for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

echo "specify version ( e.g. v0.6 ):"
read VERSION

# create temporary folder
mkdir tikz-trackschematic-$VERSION

# copy README and .sty-file
cp README.md tikz-trackschematic-$VERSION/README.md
cp doc/tikz-trackschematic-documentation.sty  tikz-trackschematic-$VERSION/tikz-trackschematic-documentation.sty

# copy and rename documentation
cp doc/manual.pdf  tikz-trackschematic-$VERSION/tikz-trackschematic.pdf
cp doc/manual.tex  tikz-trackschematic-$VERSION/tikz-trackschematic.tex
cp doc/snippets.pdf  tikz-trackschematic-$VERSION/tikz-trackschematic-snippets.pdf
cp doc/snippets.tex  tikz-trackschematic-$VERSION/tikz-trackschematic-snippets.tex
mkdir tikz-trackschematic-$VERSION/tikz-trackschematic-examples
mkdir tikz-trackschematic-$VERSION/tikz-trackschematic-snippets
cp -R doc/examples/*  tikz-trackschematic-$VERSION/tikz-trackschematic-examples
cp -R doc/snippets/*  tikz-trackschematic-$VERSION/tikz-trackschematic-snippets

# copy src
cp src/tikz-trackschematic.sty tikz-trackschematic-$VERSION/tikz-trackschematic.sty
cp src/tikzlibrarytrackschematic.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.code.tex
cp src/tikzlibrarytrackschematic.constructions.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.constructions.code.tex
cp src/tikzlibrarytrackschematic.electrics.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.electrics.code.tex
cp src/tikzlibrarytrackschematic.measures.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.measures.code.tex
cp src/tikzlibrarytrackschematic.topology.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.topology.code.tex
cp src/tikzlibrarytrackschematic.trafficcontrol.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.trafficcontrol.code.tex
cp src/tikzlibrarytrackschematic.vehicles.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.vehicles.code.tex

# zip package
zip -r tikz-trackschematic-$VERSION.zip tikz-trackschematic-$VERSION/*

#cleanup
rm -rf tikz-trackschematic-$VERSION/*
rmdir tikz-trackschematic-$VERSION