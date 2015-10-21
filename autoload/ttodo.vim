" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-21
" @Revision:    102


if !exists('g:ttodo#dirs')
    let g:ttodo#dirs = []   "{{{2
    if exists('g:todotxt#dir')
        call add(g:ttodo#dirs, g:todotxt#dir)
    endif
endif


if !exists('g:ttodo#pattern')
    let g:ttodo#pattern = '*.txt'   "{{{2
endif


if !exists('g:ttodo#exclude_rx')
    let g:ttodo#exclude_rx = '[\/]done\.txt$'   "{{{2
endif


if !exists('g:ttodo#task_include_rx')
    let g:ttodo#task_include_rx = ''   "{{{2
endif


if !exists('g:ttodo#task_exclude_rx')
    let g:ttodo#task_exclude_rx = ''   "{{{2
endif


if !exists('g:ttodo#cwindow')
    let g:ttodo#cwindow = exists(':Tragcw') == 2 ? 'trag' : ':cwindow'   "{{{2
endif


if !exists('g:ttodo#prefs')
    let g:ttodo#prefs = {'default': {'done': 0}}   "{{{2
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
    let g:ttodo#parse_rx = {'due': '\<due:\zs'. g:ttodo#date_rx .'\>', 't': '\<t:\zs'. g:ttodo#date_rx .'\>', 'pri': '^(\zs\u\ze)', 'done?': '^\cx\ze\s'}   "{{{2
endif


function! s:GetFiles() abort "{{{3
    let path = join(g:ttodo#dirs, ',')
    let files = split(globpath(path, g:ttodo#pattern), '\n')
    let files = filter(files, 'v:val !~# g:ttodo#exclude_rx')
    return files
endf


function! s:GetTasks() abort "{{{3
    let qfl = []
    for file in s:GetFiles()
        let lnum = 1
        for line in readfile(file)
            if (empty(g:ttodo#task_include_rx) || line =~ g:ttodo#task_include_rx) && (empty(g:ttodo#task_exclude_rx) || line !~ g:ttodo#task_exclude_rx)
                call add(qfl, {"filename": file, "lnum": lnum, "text": line, "task": s:ParseTask(line)})
            endif
            let lnum += 1
        endfor
    endfor
    return qfl
endf


function! s:ParseTask(task) abort "{{{3
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
    let tasks = s:GetTasks()
    if has_key(a:args, 'due')
        let due = a:args.due
        let today = strftime(g:ttodo#date_format)
        if due =~ '^t%\[oday]$'
            call filter(tasks, 'empty(v:val.task.due) || v:val.task.due <= '. string(today))
        elseif due =~ '^\d\+-\d\+-\d\+$'
            call filter(tasks, 'empty(v:val.task.due) || v:val.task.due <= '. string(due))
        else
            if due =~ '^\d\+w$'
                let due = matchstr(due, '^\d\+') * 7
            endif
            call filter(tasks, 'empty(v:val.task.due) || tlib#date#DiffInDays(v:val.task.due) <= '. due)
        endif
        if !get(a:args, 'undated', 0)
            call filter(tasks, 'empty(v:val.task.due)')
        endif
    endif
    if !get(a:args, 'done', 0)
        call filter(tasks, 'empty(v:val.task.done)')
    endif
    return tasks
endf


function! s:SortTasks(qfl) abort "{{{3
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


function! ttodo#Show(bang, qargs) abort "{{{3
    let args = tlib#arg#StringAsKeyArgsEqual(a:qargs)
    if has_key(args, "0") && has_key(g:ttodo#prefs, args['0'])
        let args = extend(copy(g:ttodo#prefs[args['0']]), args)
    else
        let args = extend(copy(g:ttodo#prefs['default']), args)
    endif
    let qfl = s:FilterTasks(args)
    let qfl = s:SortTasks(qfl)
    if !empty(qfl)
        if g:ttodo#cwindow ==# 'trag'
            let w = {}
            if has_key(args, '__posargs__')
                let flt = map(copy(args.__posargs__), 'args[v:val]')
                for i in range(len(flt))
                    if flt[i] =~# '^/'
                        let flt = flt[i : -1]
                        let flt[0] = substitute(flt[0], '^/', '', '')
                        let w.initial_filter = [flt]
                    endif
                endfor
            endif
            " TLogVAR w, qfl
            call trag#BrowseList(w, qfl)
        elseif g:ttodo#cwindow =~# '^:'
            call setqflist(qfl)
            exec g:ttodo#cwindow
        else
            throw 'TTodo: Unsupported value for g:ttodo#cwindow: '. string(g.ttodo#cwindow)
        endif
    endif
endf

