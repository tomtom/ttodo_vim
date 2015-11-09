" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-09
" @Revision:    505


if !exists('g:loaded_tlib') || g:loaded_tlib < 116
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 116
        echoerr 'tlib >= 1.16 is required'
        finish
    endif
endif


if !exists('g:ttodo#dirs')
    " List of directories where your todo.txt files reside.
    "
    " If the todotxt plugin is used, |g:todotxt#dir| is added to the 
    " list.
    let g:ttodo#dirs = []   "{{{2
    if exists('g:todotxt#dir')
        call add(g:ttodo#dirs, g:todotxt#dir)
    endif
endif


if !exists('g:ttodo#file_pattern')
    " A glob pattern matching todo.txt files in |g:ttodo#dirs|.
    let g:ttodo#file_pattern = '*todo.txt'   "{{{2
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
    let g:ttodo#default_due = strftime(g:tlib#date#date_format, localtime() + g:tlib#date#dayshift * 14)   "{{{2
endif


if !exists('g:ttodo#default_t')
    " If a task has no threshold date defined, assign this default threshold date.
    let g:ttodo#default_t = '-31d'   "{{{2
endif


if !exists('g:ttodo#parse_rx')
    ":nodoc:
    let g:ttodo#parse_rx = {'due': '\<due:\zs'. g:tlib#date#date_rx .'\>', 't': '\<t:\zs'. g:tlib#date#date_rx .'\>', 'pri': '^(\zs\u\ze)', 'hidden?': '\<h:1\>', 'done?': '^\Cx\ze\s', 'donedate': '^\Cx\s\+\zs'. g:tlib#date#date_rx, 'rec': '\<rec:\zs+\?\d\+[dwmy]\ze\>'}   "{{{2
endif


if !exists('g:ttodo#rewrite_gsub')
    ":nodoc:
    let g:ttodo#rewrite_gsub = [['^\%((\u)\s\+\)\?\zs\d\{4}-\d\d-\d\d\s\+', '']]   "{{{2
endif


if !exists('g:ttodo#use_vikitasks')
    let g:ttodo#use_vikitasks = exists('g:loaded_vikitasks') && g:loaded_vikitasks >= 102   "{{{2
endif


if !exists('g:ttodo#mapleader')
    let g:ttodo#mapleader = '<LocalLeader>t'   "{{{2
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
            \ 'set_syntax': 'ttodo#InitListBuffer',
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
            \   'files': {'type': 1, 'complete': 'files'},
            \   'path': {'type': 1, 'complete': 'dirs'},
            \   'pref': {'type': 1, 'complete_customlist': 'keys(g:ttodo#prefs)'},
            \   'pri': {'type': 1, 'complete_customlist': '["", "A-", "A-C", "W", "X-Z"]'},
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
    let filess = get(a:args, 'files', '')
    if !empty(filess)
        let files = tlib#string#SplitCommaList(filess)
    else
        let path = get(a:args, 'path', join(g:ttodo#dirs, ','))
        if empty(path)
            throw 'TTodo: Please set g:ttodo#dirs'
        endif
        let pattern = get(a:args, 'pattern', g:ttodo#file_pattern)
        Tlibtrace 'ttodo', path, pattern
        let files = tlib#file#Globpath(path, pattern)
        let task_include_rx = get(a:args, 'task_include_rx', g:ttodo#task_include_rx)
        let file_include_rx = get(a:args, 'file_include_rx', g:ttodo#file_include_rx)
        if !empty(file_include_rx)
            let files = filter(files, 'v:val =~# file_include_rx')
        endif
        let file_exclude_rx = get(a:args, 'file_exclude_rx', g:ttodo#file_exclude_rx)
        if !empty(file_exclude_rx)
            let files = filter(files, 'v:val !~# file_exclude_rx')
        endif
    endif
    Tlibtrace 'ttodo', files
    return files
endf


":nodoc:
function! ttodo#GetFileTasks(args, file) abort "{{{3
    let qfl = []
    let lnum = 0
    for line in s:GetLines(a:file)
        let lnum += 1
        for [rx, subst] in g:ttodo#rewrite_gsub
            let line = substitute(line, rx, subst, 'g')
        endfor
        if line =~ '^\s\+' && !empty(qfl)
            let line = substitute(line, '^\%(\s\{'. &shiftwidth .'}\)', ' ', 'g')
            let qfl[-1].text .= ' '. &showbreak . line
        else
            call add(qfl, {"filename": a:file, "lnum": lnum, "text": line, "task": ttodo#ParseTask(line)})
        endif
    endfor
    return qfl
endf


function! s:GetLines(filename) abort "{{{3
    let bufnr = bufnr(a:filename)
    if bufnr == -1 || !bufloaded(bufnr)
        return readfile(a:filename)
    else
        return getbufline(bufnr, 1, '$')
    endif
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


function! ttodo#ParseTask(task) abort "{{{3
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
    if has_key(task, 'due')
        if task.due < strftime(g:tlib#date#date_format)
            let task.overdue = 1
        endif
    endif
    let task.lists = filter(map(split(a:task, '\ze@'), 'matchstr(v:val, ''^@\zs\S\+'')'), '!empty(v:val)')
    let task.tags = filter(map(split(a:task, '\ze+'), 'matchstr(v:val, ''^+\zs\S\+'')'), '!empty(v:val)')
    return task
endf


function! s:FilterTasks(args) abort "{{{3
    let tasks = s:GetTasks(a:args)
    if has_key(a:args, 'due')
        let due = a:args.due
        let today = strftime(g:tlib#date#date_format)
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
        let today = strftime(g:tlib#date#date_format)
        call filter(tasks, 's:CheckThreshold(get(v:val.task, "t", ""), get(v:val.task, "due", ""), today)')
    endif
    return tasks
endf


function! s:CheckThreshold(t, due, today) abort "{{{3
    " TLogVAR a:t, a:due, a:today
    let t = 0
    let tn = ''
    if !empty(a:t)
        if a:t =~ '^'. g:tlib#date#date_rx .'$'
            let t = a:t
        elseif !empty(a:due)
            let tn = a:t
        endif
    else
        let tn = g:ttodo#default_t
    endif
    if t == 0 && !empty(tn) && !empty(a:due)
        let n = str2nr(matchstr(tn, '^-\?\d\+\ze[d]$'))
        if n != 0
            if tn =~ 'd$'
                let t = strftime(g:tlib#date#date_format, tlib#date#SecondsSince1970(a:due) + n * g:tlib#date#dayshift)
            endif
        endif
    endif
    " TLogVAR tn, t
    if !empty(t)
        return a:today >= t
    else
        return 1
    endif
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
    Tlibtrace 'ttodo', args
    " TLogVAR args
    if args.__exit__
        return
    else
        " TLogVAR args
        let pref = get(args, 'pref', a:bang ? 'important' : 'default')
        Tlibtrace 'ttodo', pref
        let args = tlib#eval#Extend(copy(g:ttodo#prefs[pref]), args)
        Tlibtrace 'ttodo', args
        let qfl = s:FilterTasks(args)
        let qfl = s:SortTasks(args, qfl)
        let flt = get(args, '__rest__', [])
        if !empty(qfl)
            if g:ttodo#viewer ==# 'tlib'
                let w = s:list_env
                if !empty(flt)
                    let w.initial_filter = [[""], flt]
                endif
                let overdue = filter(copy(qfl), 'get(v:val.task, "overdue", 0)')
                if !empty(overdue)
                    let w.overdue_rx = '\V\<due:\%('. join(map(overdue, 'v:val.task.due'), '\|') .'\)\>'
                endif
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


function! ttodo#InitListBuffer() dict abort "{{{3
    call call('tlib#qfl#SetSyntax', [], self)
    if has_key(self, 'overdue_rx')
        Tlibtrace self.overdue_rx
        TLogVAR self.overdue_rx
        exec 'syntax match TtodoOverdue /'. escape(self.overdue_rx, '/') .'/ contained containedin=TtodoTag'
        hi def link TtodoOverdue ErrorMsg
        syntax cluster TtodoTask add=TtodoOverdue
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
        if a:ArgLead =~# '^--pref='
            let words = keys(g:ttodo#prefs)
            let apref = substitute(a:ArgLead, '^--pref=', '', '')
            if !empty(apref)
                let nchar = len(apref)
                call filter(words, 'strpart(v:val, 0, nchar) ==# apref')
            endif
            let words = map(words, '"--pref=". v:val')
        else
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
    endif
    return words
endf


function! ttodo#FiletypeDetect(...) abort "{{{3
    let filename = a:0 >= 1 ? a:1 : expand('%:p')
    " TLogVAR filename
    let bdir = substitute(filename, '\\', '/', 'g')
    let bdir = substitute(bdir, '/[^/]\+$', '', '')
    let dirs = map(copy(g:ttodo#dirs), 'substitute(resolve(fnamemodify(v:val, ":p:h")), ''\\'', ''/'', ''g'')')
    " TLogVAR bdir, dirs
    if index(dirs, bdir, 0, !has('fname_case')) != -1
        setf ttodo
        " TLogVAR &ft
    endif
endf


