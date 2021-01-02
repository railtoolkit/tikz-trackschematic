# TikZ-trackschematic

------------

# Installation

The tikz library is contained in the files:
* tikz-trackschematic.sty
* tikzlibrarytrackschematic.code.tex,
* tikzlibrarytrackschematic.topology.code.tex,
* tikzlibrarytrackschematic.trafficcontrol.code.tex,
* tikzlibrarytrackschematic.vehicles.code.tex,
* tikzlibrarytrackschematic.constructions.code.tex,
* tikzlibrarytrackschematic.electrics.code.tex, and
* tikzlibrarytrackschematic.measures.code.tex.

These files should be copied wherever TeX can find it, for example in your $TEXMF folder.
The library can then be loaded through the command
```TeX
\usepackage{tikz-trackschematic}
```
in any TeX file.

------------

# Minimal working example

```TeX
\documentclass{standalone}
\usepackage{tikz-trackschematic}
\begin{document}

  \begin{tikzpicture}

    \coordinate (A)   at (0,0);
    \coordinate (B)   at (6,0);
    \coordinate (T)   at (5,0);

    \maintrack (A) -- (B);
    \train[forward] at (T) label (train);

  \end{tikzpicture}

\end{document}
```
results in:

![train on a track](https://glossary.ivev.bau.tu-bs.de/tiki-download_file.php?fileId=28&display&scale=.4 "train on a track")

------------

# Symbology and meaning

A transnational symbol library with common traits of railway operation. 
A [glossary](https://glossary.ivev.bau.tu-bs.de/tiki-index.php?page=_Symbology) for further information regarding meaning of the symbols.

------------

# History

## Version 0.6

  * created an encapsulating package for future flexibility
  * added symbols for direction control, track marking, pylons and electric wiring
  * change symbol for friction bufferstop;
  * changed load command to \usepackage{tikz-trackschematic}

## Version 0.5.1
  
  * modified symbol "end of movement authority"
  * added symbols "braking point" and "danger point"

## Version 0.5
  
  * new improved syntax for topology
  * documentation

## Version 0.4

  * added document for symbology
  * renamed overview to snippets
  * reworked library for common tikz library layout

## Version 0.3

  * moved snippet folder to root folder
  * added shunting movements
  * added points to turnouts
  * added moving trains
  * defined and used color foreground and background


## Version 0.2

  * added transmitters
  * reorganized src library
  * minor improvements

## Version 0.1

  Basic concept of a library with railway topology symbols and some examples.

------------

# Roadmap

  * rethink syntax
  * provide option for internationalziation (i18n)
  * replace "\gettikzxy" with "\path let" syntax
  * rewrite library with better coding skills

------------

# Acknowledgement

  This project has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No. 826347.

------------

# License
  
  [![Open Source Initiative Approved License logo](https://opensource.org/files/OSIApproved_100X125.png)](https://opensource.org)

  Copyright (c) 2018 - 2021, Martin Scheidt \<m.scheidt@tu-bs.de\> (ISC License)

  Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.