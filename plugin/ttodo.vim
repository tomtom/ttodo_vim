" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-21
" @Revision:    16
" GetLatestVimScripts: 0 0 :AutoInstall: ttodo.vim

if &cp || exists("loaded_ttodo")
    finish
endif
let loaded_ttodo = 1

let s:save_cpo = &cpo
set cpo&vim


" :display: :Ttodo [PREF=default] [CONFIG] [/INITIAL FILTER]
" PREF is the name of a preferences set in |g:ttodo#prefs|.
"
" CONFIG is an argument list. The following arguments are supported:
"   due=DATE ... show only tasks with due dates >= DATE. DATE can be
"                - a DATE in the form YYYY-MM-DD or
"                - a number of days or
"                - a number of weeks as in "4w".
"   +undated ... Show tasks with no due dates when using the due 
"                argument
"   +done ...... Show done tasks
" 
" INITIAL FILTER is a |regexp| for filtering the task list. The 
" interpretation of INITIAL FILTER depends on the value of 
" |g:tlib#input#filter_mode|. The INITIAL FILTER is only effective if 
" |g.ttodo#cwindow| is "trag".
"
" NOTE: The use of INITIAL FILTER requires the trag_vim plugin to be 
" installed.
command! -bang -nargs=* Ttodo call ttodo#Show(!empty("<bang>"), <q-args>)


let &cpo = s:save_cpo
unlet s:save_cpo
