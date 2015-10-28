" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-28
" @Revision:    368


if !exists('g:loaded_tlib') || g:loaded_tlib < 116
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 116
        echoerr 'tlib >= 1.16 is required'
        finish
    endif
endif


if !exists('g:ttodo#dirs')
    " List of directories where your todo.txt files reside.
    let g:ttodo#dirs = []   "{{{2
    if exists('g:todotxt#dir')
        call add(g:ttodo#dirs, g:todotxt#dir)
    endif
endif


let g:ttodo#date_rx = '\<\(\d\{4}\)-\(\d\d\)-\(\d\d\)\>'
let g:ttodo#date_format = '%Y-%m-%d'


if !exists('g:ttodo#file_pattern')
    " A glob pattern matching todo.txt files in |g:ttodo#dirs|.
    let g:ttodo#file_pattern = '*.txt'   "{{{2
endif


if !exists('g:ttodo#file_include_rx')
    " Consider only files matching this |regexp|.
    let g:ttodo#file_include_rx = ''   "{{{2
endif


if !exists('g:ttodo#file_exclude_rx')
    " Ignore files matching this |regexp|.
    let g:ttodo#file_exclude_rx = '[\/]done\.txt$'   "{{{2
endif


if !exists('g:ttodo#task_include_rx')
    " Include only tasks matching this |regexp| in the list.
    let g:ttodo#task_include_rx = ''   "{{{2
endif


if !exists('g:ttodo#task_exclude_rx')
    " Exclude tasks matching this |regexp| from the list.
    let g:ttodo#task_exclude_rx = ''   "{{{2
endif


if !exists('g:ttodo#viewer')
    " Supported values:
    "   tlib ...... Use the tlib_vim plugin; the syntax of |:Ttodo|'s 
    "               initial filter depends on the value of 
    "               |g:tlib#input#filter_mode|
    "   :COMMAND .. E.g. `:cwindow`. In this case initial filter is a 
    "               standard |regexp|.
    let g:ttodo#viewer = exists('g:loaded_tlib') ? 'tlib' : ':cwindow'   "{{{2
endif


if !exists('g:ttodo#sort')
    let g:ttodo#sort = 'pri,due,done,text'   "{{{2
endif


if !exists('g:ttodo#prefs')
    " A dictionary of configurations that can be invoked with the 
    " `--pref=NAME` command line option from |:Ttodo|.
    "
    " If no preference is given, "default" is used.
    let g:ttodo#prefs = {'default': {'hidden': 0, 'done': 0}, 'important': {'hidden': 0, 'done': 0, 'undated': 1, 'due': '2w', 'pri': 'A-C'}}   "{{{2
    if exists('g:ttodo#prefs_user')
        let g:ttodo#prefs = tlib#eval#Extend(g:ttodo#prefs, g:ttodo#prefs_user)
    endif
endif


if !exists('g:ttodo#default_pri')
    " If a task has no priortiy defined, assign this default priortiy.
    let g:ttodo#default_pri = 'T'   "{{{2
endif


if !exists('g:ttodo#default_due')
    " If a task has no due date defined, assign this default due date.
    let g:ttodo#default_due = strftime(g:ttodo#date_format, localtime() + g:tlib#date#dayshift * 14)   "{{{2
endif


if !exists('g:ttodo#parse_rx')
    ":nodoc:
    let g:ttodo#parse_rx = {'due': '\<due:\zs'. g:ttodo#date_rx .'\>', 't': '\<t:\zs'. g:ttodo#date_rx .'\>', 'pri': '^(\zs\u\ze)', 'hidden?': '\<h:1\>', 'done?': '^\Cx\ze\s', 'donedate': '^\Cx\s\+\zs'. g:ttodo#date_rx, 'rec': '\<rec:\zs+\?\d\+[dwmy]\ze\>'}   "{{{2
endif


if !exists('g:ttodo#rewrite_gsub')
    ":nodoc:
    let g:ttodo#rewrite_gsub = [['^\%((\u)\s\+\)\?\zs\d\{4}-\d\d-\d\d\s\+', '']]   "{{{2
endif


if !exists('g:ttodo#use_vikitasks')
    let g:ttodo#use_vikitasks = exists('g:loaded_vikitasks')   "{{{2
endif


if !exists('g:ttodo#debug')
    let g:ttodo#debug = 0   "{{{2
endif


if g:ttodo#debug
    call tlib#debug#Init()
endif


let s:list_env = {
            \ 'qfl_short_filename': 1,
            \ 'qfl_list_syntax': 'ttodo',
            \ 'qfl_list_syntax_nextgroup': '@TtodoTask',
            \ 'scratch': '__Ttodo__',
            \ }

if g:ttodo#use_vikitasks
    let s:list_env['key_map'] = {
            \     'default': {
            \         "\<f2>" : {'key': "\<f2>", 'agent': 'vikitasks#AgentKeymap', 'key_name': '<f2>', 'help': 'Switch to vikitasks keymap'},
            \             24 : {'key': 24, 'agent': 'vikitasks#AgentMarkDone', 'key_name': '<c-x>', 'help': 'Mark done'},
            \             4 : {'key': 4, 'agent': 'vikitasks#AgentDueDays', 'key_name': '<c-d>', 'help': 'Mark as due in N days'},
            \             23 : {'key': 23, 'agent': 'vikitasks#AgentDueWeeks', 'key_name': '<c-w>', 'help': 'Mark as due in N weeks'},
            \             3 : {'key': 3, 'agent': 'vikitasks#AgentItemChangeCategory', 'key_name': '<c-c>', 'help': 'Change task category'},
            \             14 : {'key': 14, 'agent': 'vikitasks#AgentPaste', 'key_name': '<c-n>', 'help': 'Paste selected items in a new buffer'},
            \     },
            \     'vikitasks': extend(copy(g:tlib#input#keyagents_InputList_s),
            \         {
            \             char2nr('x') : {'agent': 'vikitasks#AgentMarkDone', 'key_name': 'x', 'help': 'Mark done'},
            \             char2nr('d')  : {'agent': 'vikitasks#AgentDueDays', 'key_name': 'd', 'help': 'Mark as due in N days'},
            \             char2nr('w')  : {'agent': 'vikitasks#AgentDueWeeks', 'key_name': 'w', 'help': 'Mark as due in N weeks'},
            \             char2nr('m')  : {'agent': 'vikitasks#AgentDueMonths', 'key_name': 'w', 'help': 'Mark as due in N months'},
            \             char2nr('c') : {'agent': 'vikitasks#AgentItemChangeCategory', 'key_name': 'c', 'help': 'Change task category'},
            \             char2nr('k') : {'agent': 'vikitasks#AgentSelectCategory', 'key_name': 'k', 'help': 'Select tasks of a category'},
            \            'unknown_key': {'agent': 'tlib#agent#Null', 'key_name': 'other keys', 'help': 'ignore key'},
            \         }
            \     )
            \ }
endif

if exists('g:ttodo#world_user')
    let s:list_env = tlib#eval#Extend(s:list_env, g:ttodo#world_user)
endif


let s:ttodo_args = {
            \ 'help': ':Ttodo',
            \ 'handle_exit_code': 1,
            \ 'values': {
            \   'done': {'type': -1},
            \   'due': {'type': 1},
            \   'file_exclude_rx': {'type': 1},
            \   'file_include_rx': {'type': 1},
            \   'hidden': {'type': -1},
            \   'path': {'type': 1},
            \   'pref': {'type': 1},
            \   'pri': {'type': 1},
            \   'sort': {'type': 1},
            \   'task_exclude_rx': {'type': 1},
            \   'task_include_rx': {'type': 1},
            \   'undated': {'type': -1},
            \   'threshold': {'type': -1},
            \ },
            \ 'flags': {
            \   'A': '--file_include_rx', 'R': '--file_exclude_rx',
            \   'i': '--task_include_rx', 'x': '--task_exclude_rx',
            \ },
            \ }


function! s:GetFiles(args) abort "{{{3
    let path = get(a:args, 'path', join(g:ttodo#dirs, ','))
    if empty(path)
        throw 'TTodo: Please set g:ttodo#dirs'
    endif
    let pattern = get(a:args, 'pattern', g:ttodo#file_pattern)
    TLibTrace g:ttodo#debug, path, pattern
    let files = split(globpath(path, pattern), '\n')
    let task_include_rx = get(a:args, 'task_include_rx', g:ttodo#task_include_rx)
    let file_include_rx = get(a:args, 'file_include_rx', g:ttodo#file_include_rx)
    if !empty(file_include_rx)
        let files = filter(files, 'v:val =~# file_include_rx')
    endif
    let file_exclude_rx = get(a:args, 'file_exclude_rx', g:ttodo#file_exclude_rx)
    if !empty(file_exclude_rx)
        let files = filter(files, 'v:val !~# file_exclude_rx')
    endif
    TLibTrace g:ttodo#debug, files
    return files
endf


":nodoc:
function! ttodo#GetFileTasks(args, file) abort "{{{3
    let qfl = []
    let lnum = 0
    for line in readfile(a:file)
        let lnum += 1
        for [rx, subst] in g:ttodo#rewrite_gsub
            let line = substitute(line, rx, subst, 'g')
        endfor
        call add(qfl, {"filename": a:file, "lnum": lnum, "text": line, "task": s:ParseTask(a:args, line)})
    endfor
    return qfl
endf


function! s:GetFileTasks(args, file) abort "{{{3
    let cfile = tlib#cache#Filename('ttodo_tasks', a:file, 1)
    let fqfl = tlib#cache#Value(cfile, 'ttodo#GetFileTasks', getftime(a:file), [a:args, a:file], {'in_memory': 1})
    return fqfl
endf


function! s:GetTasks(args) abort "{{{3
    let qfl = []
    let task_include_rx = get(a:args, 'task_include_rx', g:ttodo#task_include_rx)
    let task_exclude_rx = get(a:args, 'task_exclude_rx', g:ttodo#task_exclude_rx)
    for file in s:GetFiles(a:args)
        let fqfl = s:GetFileTasks(a:args, file)
        TLogVAR file, fqfl
        let rqfl = filter(copy(fqfl), 'get(v:val.task, "done", 0) && !empty(get(v:val.task, "rec", ""))')
        TLogVAR 1, rqfl
        let rqfl = map(rqfl, 's:RecurringTask(v:val, a:args)')
        TLogVAR 2, rqfl
        let rqfl = filter(rqfl, '!empty(v:val)')
        if !empty(rqfl)
            let qfl = extend(qfl, rqfl) 
        endif
        let fqfl = filter(copy(fqfl), '!empty(v:val.text) && (empty(task_include_rx) || v:val.text =~ task_include_rx) && (empty(task_exclude_rx) || v:val.text !~ task_exclude_rx)')
        if !empty(fqfl)
            let qfl = extend(qfl, fqfl) 
        endif
    endfor
    return qfl
endf


function! s:RecurringTask(qfe, args) abort "{{{3
    " TODO Handle done recurring tasks
    let qfe = copy(a:qfe)
    let text = qfe.text
    let text = substitute(text, '^\Cx\s\+'. g:ttodo#date_rx .'\s\+\%(\d\d:\d\d\s\+\)\?', '', '')
    let due = qfe.task.rec =~ '^+' ? qfe.task.due : qfe.task.donedate
    if empty(due)
        echohl WarningMsg
        echom 'Ttodo: Cannot set due date for recurring task:' qfe.text
        echohl NONE
        return {}
    else
        let ndue = due
        let today = strftime(g:ttodo#date_format)
        while ndue < today
            let ndue = s:ShiftDate(ndue, matchstr(qfe.task.rec, '\d\+\a$'))
            TLogVAR ndue
        endwh
        if text =~# '\<due:'. g:ttodo#date_rx
            let text = substitute(text, '\<due:\zs'. g:ttodo#date_rx, ndue, '')
        else
            let text .= ' due:'. ndue
        endif
        let qfe.text = text
        let qfe.task = s:ParseTask(a:args, text)
        return qfe
    endif
endf


function! s:ShiftDate(date, shift) abort "{{{3
    let n = str2nr(matchstr(a:shift, '\d\+'))
    let ml = matchlist(a:date, g:ttodo#date_rx)
    TLogVAR a:date, a:shift, n, ml
    if a:shift =~ 'd$'
        let secs = tlib#date#SecondsSince1970(a:date) + g:tlib#date#dayshift * n
        TLogVAR secs
        let date = strftime(g:ttodo#date_format, secs)
    elseif a:shift =~ 'w$'
        let secs = tlib#date#SecondsSince1970(a:date) + g:tlib#date#dayshift * n * 7
        let date = strftime(g:ttodo#date_format, secs)
    elseif a:shift =~ 'm$'
        let d = str2nr(ml[1])
        let ms = str2nr(ml[2]) + n
        let m = ms % 12 + 1
        let yr = str2nr(ml[1]) + ms / 12
        let date = printf('%04d-%02d-%02d', yr, m, d)
    elseif a:shift =~ 'y$'
        let yr = str2nr(ml[1]) + n
        let date = substitute(a:date, '^\d\{4}', yr, '')
    endif
    TLogVAR date
    return date
endf


function! s:ParseTask(args, task) abort "{{{3
    let task = {'text': a:task}
    for [key, rx] in items(g:ttodo#parse_rx)
        let val = matchstr(a:task, rx)
        if key =~ '?$'
            let key = substitute(key, '?$', '', '')
            let task[key] = !empty(val)
        elseif !empty(val)
            let task[key] = val
        endif
    endfor
    let task.lists = map(split(a:task, '\ze@'), 'matchstr(v:val, "^@\S\+")')
    let task.tags = map(split(a:task, '\ze+'), 'matchstr(v:val, "^+\S\+")')
    return task
endf


function! s:FilterTasks(args) abort "{{{3
    let tasks = s:GetTasks(a:args)
    if has_key(a:args, 'due')
        let due = a:args.due
        let today = strftime(g:ttodo#date_format)
        if due =~ '^t%\[oday]$'
            call filter(tasks, 'empty(get(v:val.task, "due", "")) || get(v:val.task, "due", "") <= '. string(today))
        elseif due =~ '^\d\+-\d\+-\d\+$'
            call filter(tasks, 'empty(get(v:val.task, "due", "")) || get(v:val.task, "due", "") <= '. string(due))
        else
            if due =~ '^\d\+w$'
                let due = matchstr(due, '^\d\+') * 7
            endif
            call filter(tasks, 'empty(get(v:val.task, "due", "")) || tlib#date#DiffInDays(v:val.task.due) <= '. due)
        endif
        if !get(a:args, 'undated', 0)
            call filter(tasks, '!empty(get(v:val.task, "due", ""))')
        endif
    endif
    if !get(a:args, 'done', 0)
        call filter(tasks, '!get(v:val.task, "done", 0)')
    endif
    if !get(a:args, 'hidden', 0)
        call filter(tasks, 'empty(get(v:val.task, "hidden", ""))')
    endif
    if has_key(a:args, 'pri')
        call filter(tasks, 'get(v:val.task, "pri", g:ttodo#default_pri) =~# ''^['. a:args.pri .']$''')
    endif
    if get(a:args, 'threshold', 1)
        let today = strftime(g:ttodo#date_format)
        call filter(tasks, 's:CheckThreshold(get(v:val.task, "t", ""), get(v:val.task, "due", ""), today)')
    endif
    return tasks
endf


function! s:CheckThreshold(t, due, today) abort "{{{3
    if !empty(a:t)
        if a:t =~ '^'. g:ttodo#date_rx .'$'
            return a:today <= a:t
        endif
    endif
    return 1
endf


function! s:SortTasks(args, qfl) abort "{{{3
    " TLogVAR a:qfl
    let s:sort_fields = split(get(a:args, 'sort', g:ttodo#sort), ',')
    let qfl = sort(a:qfl, 's:SortTask')
    return qfl
endf


function! s:SortTask(a, b) abort "{{{3
    let a = a:a.task
    let b = a:b.task
    for item in s:sort_fields
        let default = exists('g:ttodo#default_'. item) ? g:ttodo#default_{item} : ''
        let aa = get(a, item, default)
        let bb = get(b, item, default)
        if aa != bb
            return aa > bb ? 1 : -1
        endif
    endfor
    return 0
endf


":nodoc:
function! ttodo#Show(bang, args) abort "{{{3
    let args = tlib#arg#GetOpts(a:args, s:ttodo_args, 1)
    TLibTrace g:ttodo#debug, args
    " TLogVAR args
    if args.__exit__
        return
    else
        " TLogVAR args
        let pref = get(args, 'pref', a:bang ? 'important' : 'default')
        TLibTrace g:ttodo#debug, pref
        let args = tlib#eval#Extend(copy(g:ttodo#prefs[pref]), args)
        TLibTrace g:ttodo#debug, args
        let qfl = s:FilterTasks(args)
        let qfl = s:SortTasks(args, qfl)
        let flt = get(args, '__rest__', [])
        if !empty(qfl)
            if g:ttodo#viewer ==# 'tlib'
                let w = s:list_env
                if !empty(flt)
                    let w.initial_filter = [[""], flt]
                endif
                " let index_next_syntax = {}
                " let n = 0
                " let today = strftime(g:ttodo#date_format)
                " for qfe in qfl
                "     let n += 1
                "     let due = get(qfe.task, 'due', '')
                "     if empty(due) || due > today
                "         break
                "     endif
                "     let index_next_syntax[n] = 'TtodoOverdue'
                " endfor
                " if !empty(index_next_syntax)
                "     let w.index_next_syntax = index_next_syntax
                " endif
                " TLogVAR w, qfl
                call tlib#qfl#QflList(qfl, w)
            elseif g:ttodo#viewer =~# '^:'
                if !empty(flt)
                    let qfl = filter(qfl, 's:FilterQFL(v:val, flt)')
                endif
                call setqflist(qfl)
                exec g:ttodo#viewer
            else
                throw 'TTodo: Unsupported value for g:ttodo#viewer: '. string(g:ttodo#viewer)
            endif
        endif
    endif
endf


function! s:FilterQFL(item, flts) abort "{{{3
    let text = a:item.text
    for flt in a:flts
        if text !~ flt
            return 0
        endif
    endfor
    return 1
endf


":nodoc:
function! ttodo#CComplete(ArgLead, CmdLine, CursorPos) abort "{{{3
    let words = tlib#arg#CComplete(s:ttodo_args, a:ArgLead)
    if !empty(a:ArgLead)
        let nchar = len(a:ArgLead)
        let texts = {}
        for task in s:GetTasks({})
            for word in split(task.text, '\s\+')
                if strpart(word, 0, nchar) ==# a:ArgLead
                    let texts[word] = 1
                endif
            endfor
        endfor
        let words += sort(keys(texts))
    endif
    return words
endf


function! ttodo#FiletypeDetect() abort "{{{3
    let bdir = expand('%:p:h')
    if index(g:ttodo#dirs, bdir, 0, !has('fname_case')) != -1
        setf ttodo
    endif
endf

