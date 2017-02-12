" @Author:      Tom Link (micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2017-02-12
" @Revision:    117
" GetLatestVimScripts: 5262 0 :AutoInstall: ttodo.vim

if &cp || exists("loaded_ttodo")
    finish
endif
let loaded_ttodo = 100

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:ttodo_nmap')
    " Call |:Ttodo|.
    let g:ttodo_nmap = '<Leader>1'   "{{{2
endif


if !exists('g:ttodo_nmap_important')
    " Call |:Ttodonext|.
    let g:ttodo_nmap_important = '<Leader>!'   "{{{2
endif


if !exists('g:ttodo_localmap')
    " Call |:Ttodo| with `%:p:h/TODO.TXT`.
    let g:ttodo_localmap = '<Localleader>1'   "{{{2
endif


if !exists('g:ttodo_enable_ftdetect')
    " Set this variable to 1 in |vimrc| in order to enable the ttodo 
    " filetype for todo.txt files.
    let g:ttodo_enable_ftdetect = 1   "{{{2
endif


" :display: :Ttodo[!] [ARGS] [INITIAL FILTER]
"
" ARGS is an argument list. The following arguments are supported:
"   --pref=PREF .... PREF is the name of a preferences set in 
"                    |g:ttodo#prefs| (default: "default")
"   --due=DATE ..... show only tasks with due dates >= DATE. DATE can be
"                    - a DATE in the form YYYY-MM-DD or
"                    - a number of days or
"                    - a number of weeks as in "4w"
"                    (default: |g:ttodo#default_due|)
"   --undated ...... Show tasks with no due dates when using the due 
"                    argument
"   --done ......... Show completed tasks
"   --pending ...... Show tasks with open dependencies
"   --hidden ....... Show hidden tasks, i.e. tasks with a "h:1" tag or 
"                    tasks matching |g:ttodo#task_hide_rx|
"   --bufnr=BUFNR .. A comma-separated list of buffer numbers (must be 
"                    numbers)
"   --bufname=EXPR . A buffer name expression (see |bufname()|)
"   --files=FILE1,FILE2... .. A comma-separated list of todo.txt files
"   --path=PATH .... Search files in this path (default: use 
"                    |g:ttodo#dirs|)
"   --pattern=PAT .. Search files matching this pattern (default: 
"                    |g:ttodo#file_pattern|)
"   --encoding=ENC . Encoding of the task files (default: &enc)
"   --sort=FIELDS .. default: |g:ttodo#sort|
"   --has_subtasks . Show tasks with open subtasks (i.e. indented tasks 
"                    below the parent task)
"   --pri=PRI ..................... Show tasks with a priority matching 
"                                   [PRI] (see |/[]|)
"   --ignore_pri=PRI .............. Ignore tasks with a priority 
"                                   matching [PRI] (see |/[]|)
"   --has_lists=LIST1,.. .......... Show tasks with matching lists
"   --ignore_lists=LIST1,.. ....... Ignore tasks with matching lista
"   --has_tags=TAG1,.. ............ Show tasks with matching taga
"   --ignore_tags=TAG1,.. ......... Ignore tasks with matching tags
"   -A=RX, --file_include_rx=RX ... Default: |g:ttodo#file_include_rx|
"   -R=RX, --file_exclude_rx=RX ... Default: |g:ttodo#file_exclude_rx|
"   -i=RX, --task_include_rx=RX ... Default: |g:ttodo#task_include_rx|
"   -x=RX, --task_exclude_rx=RX ... Default: |g:ttodo#task_exclude_rx|
"
" When the [!] is included show only important tasks.
" 
" INITIAL FILTER is a |regexp| for filtering the task list. The 
" interpretation of INITIAL FILTER depends on the value of 
" |g:tlib#input#filter_mode|. The format of INITIAL FILTER depends on 
" the value of |g:ttodo#viewer|.
command! -bang -nargs=* -complete=customlist,ttodo#CComplete Ttodo call ttodo#Show(!empty("<bang>"), [<f-args>])


" Add a new task.
command! -nargs=+ -complete=customlist,ttodo#CComplete Ttodonew call ttodo#NewTask([<f-args>])


" Show newly (maybe semi-automatically) added tasks, i.e. tasks that are in the @Inbox list.
command! -bar Ttodoinbox Ttodo --has_lists=Inbox


" Show tasks that should be done next, i.e. tasks that are in the @next 
" list.
command! -bar Ttodonext Ttodo --has_lists=next


" Scan todo files and notes for some text -- see |:Trag| for details.
"
" NOTE: This command requires the trag VIM plugin to be installed.
command! -bang -nargs=+ Ttodogrep if exists(':Trag') == 2 | Trag<bang> --file_sources=*ttodo#FileSources <args> | else | echom ':Ttodogrep requires the trag_vim plugin to be installed!' | endif


if !empty(g:ttodo_nmap)
    exec 'noremap' g:ttodo_nmap ':Ttodo<cr>'
endif


if !empty(g:ttodo_nmap_important)
    exec 'noremap' g:ttodo_nmap_important ':Ttodonext<cr>'
endif


if !empty(g:ttodo_localmap)
    exec 'noremap' g:ttodo_localmap ':Ttodo --path=.<cr>'
endif


let &cpo = s:save_cpo
unlet s:save_cpo
