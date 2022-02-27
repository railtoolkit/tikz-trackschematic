## -- increase available memory for snippets.tex

## find local texmf.cnf
# kpsewhich -a texmf.cnf
# returns /usr/local/texlive/2021/texmf.cnf

## append in /usr/local/texlive/2021/texmf.cnf
# % increase available memory
# main_memory = 12000000
# extra_mem_bot = 12000000
# font_mem_size = 12000000
# pool_size = 12000000
# buf_size = 12000000

## run
# sudo mktexlsr

## compile order
# 1. manual
# 2. symbology-table
# 3. snippets