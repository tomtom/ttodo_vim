" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-03.
" @Revision:    16

if exists("b:did_ftplugin") || !g:ttodo#use_vikitasks
    finish
endif
let b:did_ftplugin = 1
let s:save_cpo = &cpo
set cpo&vim

setl tw=0

exec 'nnoremap <buffer>' g:ttodo#mapleader .'x :<C-U>call ttodo#ftplugin#WithVikitasks("vikitasks#ItemMarkDone", v:count, "{ftdef}")<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'d :<C-U>call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInDays", 0, v:count1, "{ftdef}")<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'w :<C-U>call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInWeeks", 0, v:count1, "{ftdef}")<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'m :<C-U>call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInMonths", 0, v:count1, "{ftdef}")<cr>'
exec 'nnoremap <buffer>' g:ttodo#mapleader .'p :<C-U>call ttodo#ftplugin#WithVikitasks("vikitasks#ItemChangeCategory", v:count, "", "{ftdef}")<cr>'


let &cpo = s:save_cpo
unlet s:save_cpo
