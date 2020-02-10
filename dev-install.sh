#! /bin/sh

echo "specify path for installation!"
echo "( e.g. /usr/local/texlive/2019/texmf-dist/tex/latex ):"
read INSTALLPATH

DIR=$(pwd -P)

DEVDIR="tikz-trackschematic-dev"

mkdir $INSTALLPATH/$DEVDIR

ln -s $DIR/src/tikzlibrarytrackschematic.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.code.tex
ln -s $DIR/src/tikzlibrarytrackschematic.constructions.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.constructions.code.tex
ln -s $DIR/src/tikzlibrarytrackschematic.messures.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.messures.code.tex
ln -s $DIR/src/tikzlibrarytrackschematic.topology.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.topology.code.tex
ln -s $DIR/src/tikzlibrarytrackschematic.trafficcontrol.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.trafficcontrol.code.tex
ln -s $DIR/src/tikzlibrarytrackschematic.vehicles.code.tex $INSTALLPATH/$DEVDIR/tikzlibrarytrackschematic-dev.vehicles.code.tex
