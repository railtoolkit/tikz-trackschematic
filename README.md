# installation

todo

# Usage

```TeX
\documentclass[tikz]{standalone}
\usetikzlibrary{trackschematic}
\begin{document}

  \begin{tikzpicture}
    \coordinate (A)   at (0,0);
    \coordinate (B)   at (6,0);

    \coordinate (T)   at (5,0);

    \draw[MainTrack] (A) -- (B);
    \pic at (T) {train_moving_forward};
  \end{tikzpicture}

\end{document}
```

------------
# History

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

  * encapsulation of symbols in package for tex infrastructure
  * provide option for internationalziation (i18n)
  * write usefull documentation
  * re-think syntax