autocmd BufNewFile,BufRead *todo.txt if exists('g:ttodo_enable_ftdetect') && g:ttodo_enable_ftdetect | call ttodo#FiletypeDetect(expand("<afile>:p")) | endif
autocmd BufNewFile,BufRead done.txt if exists('g:ttodo_enable_ftdetect') && g:ttodo_enable_ftdetect | call ttodo#FiletypeDetect(expand("<afile>:p")) | endif
