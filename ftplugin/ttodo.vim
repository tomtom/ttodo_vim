" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-24.
" @Revision:    88

if exists("b:did_ftplugin")
    finish
endif
let b:did_ftplugin = 1
let s:save_cpo = &cpo
set cpo&vim

setl tw=0
setl commentstring=x\ %s

exec 'nnoremap <buffer>' g:ttodo#mapleader .'x :<C-U>call ttodo#ftplugin#MarkDone(v:count)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'d :<C-U>call ttodo#ftplugin#MarkDue("d", v:count)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'w :<C-U>call ttodo#ftplugin#MarkDue("w", v:count1)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'m :<C-U>call ttodo#ftplugin#MarkDue("m", v:count1)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'y :<C-U>call ttodo#ftplugin#SetPriority(v:count)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'a :<C-U>call ttodo#ftplugin#ArchiveCurrentBuffer()<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'n :<C-U>call ttodo#ftplugin#Note()<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'i :<C-U>call ttodo#ftplugin#AddId(v:count)<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'b :<C-U>Ttodo --bufname=%<cr>'

nnoremap <buffer> <expr> <cr> ttodo#ftplugin#New(g:ttodo#ftplugin#add_at_eof ? "G" : "", 0, "n")
nnoremap <buffer> <expr> <c-cr> ttodo#ftplugin#New(g:ttodo#ftplugin#add_at_eof ? "G" : "", 1, "n")
nnoremap <buffer> <expr> <s-cr> ttodo#ftplugin#New(">", 1, "n")

inoremap <buffer> <expr> <cr> ttodo#ftplugin#New(g:ttodo#ftplugin#add_at_eof ? "G" : "", 0, "i")
inoremap <buffer> <expr> <c-cr> ttodo#ftplugin#New(g:ttodo#ftplugin#add_at_eof ? "G" : "", 1, "i")
inoremap <buffer> <expr> <s-cr> ttodo#ftplugin#New(">", 1, "i")


" Sort the tasks in the current buffer.
"
" Sorting task outlines (i.e. subtasks) is not supported.
command! -buffer -bar -nargs=* -complete=customlist,ttodo#CComplete Ttodosort call ttodo#SortBuffer([<f-args>])

" Archive completed tasks in the current buffer.
command! -buffer -bar Ttodoarchive call ttodo#ftplugin#ArchiveCurrentBuffer()

" View the tasks in the current buffer.
command! -buffer -bar -nargs=* Ttodobuffer Ttodo --bufname=% <args>

" Add a new task to the task at the cursor.
command! -buffer -bar Ttodonote call ttodo#ftplugin#Note()


let &cpo = s:save_cpo
unlet s:save_cpo
