#!/usr/bin/env sh

echo "specify version ( e.g. v0.5 ):"
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
cp src/tikzlibrarytrackschematic.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.code.tex
cp src/tikzlibrarytrackschematic.constructions.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.constructions.code.tex
cp src/tikzlibrarytrackschematic.messures.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.messures.code.tex
cp src/tikzlibrarytrackschematic.topology.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.topology.code.tex
cp src/tikzlibrarytrackschematic.trafficcontrol.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.trafficcontrol.code.tex
cp src/tikzlibrarytrackschematic.vehicles.code.tex tikz-trackschematic-$VERSION/tikzlibrarytrackschematic.vehicles.code.tex

# zip package
zip -r tikz-trackschematic-$VERSION.zip tikz-trackschematic-$VERSION/*

#cleanup
rm -rf tikz-trackschematic-$VERSION/*
rmdir tikz-trackschematic-$VERSION