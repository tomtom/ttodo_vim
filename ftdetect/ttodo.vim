autocmd BufNewFile,BufRead *todo.txt if &ft != 'ttodo' && exists('g:ttodo_enable_ftdetect') && g:ttodo_enable_ftdetect | call ttodo#FiletypeDetect(expand("<afile>:p")) | endif
autocmd BufNewFile,BufRead *TODO.TXT if &ft != 'ttodo' && exists('g:ttodo_enable_ftdetect') && g:ttodo_enable_ftdetect | call ttodo#FiletypeDetect(expand("<afile>:p")) | endif
autocmd BufNewFile,BufRead done.txt if &ft != 'ttodo' && exists('g:ttodo_enable_ftdetect') && g:ttodo_enable_ftdetect | call ttodo#FiletypeDetect(expand("<afile>:p")) | endif
