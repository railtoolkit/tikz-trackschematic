# TikZ-trackschematic

------------

# Installation

The tikz library is contained in the files:
* tikzlibrarytrackschematic.code.tex,
* tikzlibrarytrackschematic.topology.code.tex,
* tikzlibrarytrackschematic.trafficcontrol.code.tex,
* tikzlibrarytrackschematic.vehicles.code.tex,
* tikzlibrarytrackschematic.constructions.code.tex, and
* tikzlibrarytrackschematic.messures.code.tex.
These files should be copied wherever TeX can find it, for example in your TEXMF folder. The library can then be loaded through the command \usetikzlibrary{trackschematic} in any tex file.

------------

# Usage

```TeX
\documentclass[tikz]{standalone}
\usetikzlibrary{trackschematic}
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

------------

# History

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
  * rewrite library with better coding skills

------------

# Acknowledgement

  This project has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No. 826347.

------------

# License
  
  ISC License

  Copyright (c) 2018 - 2020, Martin Scheidt \<m.scheidt@tu-bs.de\>

  Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.

  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.