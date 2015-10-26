" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-26
" @Revision:    216


if !exists('g:loaded_tlib') || g:loaded_tlib < 115
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 115
        echoerr 'tlib >= 1.15 is required'
        finish
    endif
endif


if !exists('g:ttodo#dirs')
    let g:ttodo#dirs = []   "{{{2
    if exists('g:todotxt#dir')
        call add(g:ttodo#dirs, g:todotxt#dir)
    endif
endif


if !exists('g:ttodo#file_pattern')
    let g:ttodo#file_pattern = '*.txt'   "{{{2
endif


if !exists('g:ttodo#file_exclude_rx')
    let g:ttodo#file_exclude_rx = '[\/]done\.txt$'   "{{{2
endif


if !exists('g:ttodo#task_include_rx')
    let g:ttodo#task_include_rx = ''   "{{{2
endif


if !exists('g:ttodo#task_exclude_rx')
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


if !exists('g:ttodo#prefs')
    let g:ttodo#prefs = {'default': {'hidden': 0, 'done': 0}, 'important': {'hidden': 0, 'done': 0, 'due': '1w', 'pri': 'A-C'}}   "{{{2
    if exists('g:ttodo#prefs_user')
        let g:ttodo#prefs = tlib#eval#Extend(g:ttodo#prefs, g:ttodo#prefs_user)
    endif
endif


if !exists('g:ttodo#date_rx')
    let g:ttodo#date_rx = '\<\d\{4}-\d\d-\d\d\>'   "{{{2
endif


if !exists('g:ttodo#date_format')
    let g:ttodo#date_format = '%Y-%m-%d'   "{{{2
endif


if !exists('g:ttodo#default_pri')
    let g:ttodo#default_pri = 'T'   "{{{2
endif


if !exists('g:ttodo#default_due')
    let g:ttodo#default_due = strftime(g:ttodo#date_format, localtime() + g:tlib#date#dayshift * 14)   "{{{2
endif


if !exists('g:ttodo#parse_rx')
    let g:ttodo#parse_rx = {'due': '\<due:\zs'. g:ttodo#date_rx .'\>', 't': '\<t:\zs'. g:ttodo#date_rx .'\>', 'pri': '^(\zs\u\ze)', 'hidden?': '\<h:1\>', 'done?': '^\Cx\ze\s'}   "{{{2
endif


if !exists('g:ttodo#rewrite_gsub')
    let g:ttodo#rewrite_gsub = [['^\%((\u)\s\+\)\?\zs\d\{4}-\d\d-\d\d\s\+', '']]   "{{{2
endif


let s:ttodo_args = {
            \ 'help': ':Ttodo',
            \ 'handle_exit_code': 1,
            \ }


function! s:GetFiles(args) abort "{{{3
    let path = get(a:args, 'path', join(g:ttodo#dirs, ','))
    let pattern = get(a:args, 'pattern', g:ttodo#file_pattern)
    let files = split(globpath(path, pattern), '\n')
    let task_include_rx = get(a:args, 'task_include_rx', g:ttodo#task_include_rx)
    let file_exclude_rx = get(a:args, 'file_exclude_rx', g:ttodo#file_exclude_rx)
    let files = filter(files, 'v:val !~# file_exclude_rx')
    return files
endf


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
        let fqfl = filter(copy(fqfl), '!empty(v:val.text) && (empty(task_include_rx) || v:val.text =~ task_include_rx) && (empty(task_exclude_rx) || v:val.text !~ task_exclude_rx)')
        if !empty(fqfl)
            let qfl = extend(qfl, fqfl) 
        endif
    endfor
    return qfl
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
        call filter(tasks, 'empty(get(v:val.task, "done", ""))')
    endif
    if !get(a:args, 'hidden', 0)
        call filter(tasks, 'empty(get(v:val.task, "hidden", ""))')
    endif
    if has_key(a:args, 'pri')
        call filter(tasks, 'get(v:val.task, "pri", g:ttodo#default_pri) =~# ''^['. a:args.pri .']$''')
    endif
    return tasks
endf


function! s:SortTasks(args, qfl) abort "{{{3
    " TLogVAR a:qfl
    let qfl = sort(a:qfl, 's:SortTask')
    return qfl
endf


function! s:SortTask(a, b) abort "{{{3
    let a = a:a.task
    let b = a:b.task
    for item in ['pri', 'due', 'done', 'text']
        let default = exists('g:ttodo#default_'. item) ? g:ttodo#default_{item} : ''
        let aa = get(a, item, default)
        let bb = get(b, item, default)
        if aa != bb
            return aa > bb ? 1 : -1
        endif
    endfor
    return 0
endf


function! ttodo#Show(bang, args) abort "{{{3
    let args = tlib#arg#GetOpts(a:args, s:ttodo_args, 1)
    if args.__exit__
        return
    else
        " TLogVAR args
        let pref = get(args, 'pref', a:bang ? 'important' : 'default')
        let args = extend(copy(g:ttodo#prefs[pref]), args)
        let qfl = s:FilterTasks(args)
        let qfl = s:SortTasks(args, qfl)
        let flt = get(args, '__rest__', [])
        if !empty(qfl)
            if g:ttodo#viewer ==# 'tlib'
                let w = {}
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


function! ttodo#CComplete(ArgLead, CmdLine, CursorPos) abort "{{{3
    " let lead = matchstr(a:ArgLead, '\w\+$')
    let lead = a:ArgLead
    if empty(lead)
        return []
    else
        let words = {'-h': 1, '--help': 1
                    \, '--path=': 1, '--pri=': 1, '--pref=': 1, '--due=': 1
                    \, '--undated': 1, '--done': 1, '--hidden': 1
                    \, '--no-undated': 1, '--no-done': 1, '--no-hidden': 1
                    \ }
        let nchar = len(lead)
        call filter(words, 'strpart(v:key, 0, nchar) ==# lead')
        for task in s:GetTasks({})
            for word in split(task.text, '\s\+')
                if strpart(word, 0, nchar) ==# lead
                    let words[word] = 1
                endif
            endfor
        endfor
        return sort(keys(words))
    endif
endf

