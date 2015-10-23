" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-23
" @Revision:    42
" GetLatestVimScripts: 0 0 :AutoInstall: ttodo.vim

if &cp || exists("loaded_ttodo")
    finish
endif
let loaded_ttodo = 1

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:ttodo_nmap')
    let g:ttodo_nmap = '<Leader>1'   "{{{2
endif


if !exists('g:ttodo_nmap_important')
    let g:ttodo_nmap_important = '<Leader>!'   "{{{2
endif


" :display: :Ttodo[!] [ARGS] [INITIAL FILTER]
"
" ARGS is an argument list. The following arguments are supported:
"   --path=PATH ... Search files in this path (default: use 
"                   |g:ttodo#dirs|)
"   --pattern=PAT . Search files matching this pattern (default: 
"                   |g:ttodo#file_pattern|)
"   --pref=PREF ... PREF is the name of a preferences set in 
"                   |g:ttodo#prefs| (default: "default")
"   --due=DATE .... show only tasks with due dates >= DATE. DATE can be
"                   - a DATE in the form YYYY-MM-DD or
"                   - a number of days or
"                   - a number of weeks as in "4w"
"                   (default: |g:ttodo#default_due|)
"   --pri=PRI ..... Show tasks with a priority matching [PRI] (see 
"                   |/[]|)
"   --undated ..... Show tasks with no due dates when using the due 
"                   argument
"   --done ........ Show done tasks
"
" When the [!] is included show only important tasks.
" 
" INITIAL FILTER is a |regexp| for filtering the task list. The 
" interpretation of INITIAL FILTER depends on the value of 
" |g:tlib#input#filter_mode|. The format of INITIAL FILTER depends on 
" the value of |g:ttodo#viewer|.
"
" NOTE: The use of INITIAL FILTER requires the trag_vim plugin to be 
" installed.
command! -bang -nargs=* Ttodo call ttodo#Show(!empty("<bang>"), [<f-args>])


if !empty(g:ttodo_nmap)
    exec 'noremap' g:ttodo_nmap ':Ttodo<cr>'
endif


if !empty(g:ttodo_nmap_important)
    exec 'noremap' g:ttodo_nmap_important ':Ttodo!<cr>'
endif


let &cpo = s:save_cpo
unlet s:save_cpo
