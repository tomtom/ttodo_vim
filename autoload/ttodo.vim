" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2016-01-06
" @Revision:    1292


if !exists('g:loaded_tlib') || g:loaded_tlib < 119
    runtime plugin/tlib.vim
    if !exists('g:loaded_tlib') || g:loaded_tlib < 119
        echoerr 'tlib >= 1.19 is required'
        finish
    endif
endif


if !exists('g:ttodo#dirs')
    " A list of directories containing todo.txt files. An item in this 
    " list can be either:
    "   - a directory as string
    "   - a list of [directory, options]
    "   - a dictionary of {'dir': directory, 'opts': options}
    "
    " Options is a dictionary that may contain the following keys:
    "
    "   lists: LIST OF STRINGS .... Additional lists
    "   tags: LIST OF STRINGS ..... Additional tags
    "   inbox: BASENAME ........... Basename for new tasks (see 
    "                               |g:ttodo#inbox|)
    "   inboxfile: FILENAME ....... Full filename for new tasks
    "   file_pattern: GLOB ........ See |g:ttodo#file_pattern|
    "   file_include_rx: REGEXP ... See |g:ttodo#file_include_rx|
    "   file_exclude_rx: REGEXP ... See |g:ttodo#file_exclude_rx|
    "   encoding: ENC ............. If ENC != 'enc', then the file 
    "                               contents will be transcoded with 
    "                               |iconv()|
    "
    " |g:ttodo#fileargs| provides an alternative way to define 
    " file-specific options.
    "
    " If the todotxt plugin is used, |g:todotxt#dir| is added to the 
    " list.
    "
    " Changes to this variable will have an effect only after restart.
    let g:ttodo#dirs = []
endif


if !exists('g:ttodo#fileargs')
    " A dictionary of {filename |regexp|: {additional args}} -- see 
    " |g:ttodo#dirs| for details on supported arguments.
    let g:ttodo#fileargs = {}   "{{{2
endif


if !exists('g:ttodo#file_pattern')
    " A glob pattern matching todo.txt files.
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


if !exists('g:ttodo#task_hide_rx')
    let g:ttodo#task_hide_rx = ''   "{{{2
endif


if !exists('g:ttodo#viewer')
    " Supported values:
    "   tlib ...... Use the tlib_vim plugin; the syntax of |:Ttodo|'s 
    "               initial filter depends on the value of 
    "               |g:tlib#input#filter_mode|
    "   :COMMAND .. E.g. `:cwindow` or `:CtrlPQuickfix`. In this case 
    "               initial filter is a standard |regexp|.
    let g:ttodo#viewer = 'tlib'   "{{{2
endif


if !exists('g:ttodo#sort')
    " A comma-separated list of fields that determine the sort order for 
    " |:Ttodo| and |:Ttodosort|.
    "
    " A "-" as prefix reverses the sort order.
    let g:ttodo#sort = '-overdue,pri,due,done,lists,tags,idx'   "{{{2
endif


if !exists('g:ttodo#sort_defaults')
    " :nodoc:
    let g:ttodo#sort_defaults = {
                \ 'pri': 'T',
                \ 'overdue': 0,
                \ 'due': strftime(g:tlib#date#date_format, localtime() + g:tlib#date#dayshift * 28),
                \ }
endif


if !exists('g:ttodo#prefs')
    " A dictionary of configurations that can be invoked with the 
    " `--pref=NAME` command line option from |:Ttodo|.
    "
    " If no preference is given, "default" is used.
    let g:ttodo#prefs = {'default': {'ignore_pri': 'X-Z'}, 'important': {'undated': 1, 'due': '2w', 'pri': 'A-C'}}   "{{{2
    if exists('g:ttodo#prefs_user')
        let g:ttodo#prefs = tlib#eval#Extend(g:ttodo#prefs, g:ttodo#prefs_user)
    endif
endif


if !exists('g:ttodo#default_t')
    " If a task has no threshold date defined, assign this default threshold date.
    let g:ttodo#default_t = '-31d'   "{{{2
endif


if !exists('g:ttodo#parse_rx')
    ":nodoc:
    let g:ttodo#parse_rx = {
                \ 'id': '\<id:\zs\w\+',
                \ 'parent': '\<parent:\zs\w\+',
                \ 'dep': '\<dep:\zs\w\+',
                \ 'subtask?': '^\s\+',
                \ 'created': '^\C\%(x\s\+'. g:tlib#date#date_rx .'\s\+\)\?\%((\u)\s\+\)\?\zs'. g:tlib#date#date_rx,
                \ 'due': '\<due:\zs'. g:tlib#date#date_rx .'\>',
                \ 't': '\<t:\zs\%(-\d\+[d]\|'. g:tlib#date#date_rx .'\)\>',
                \ 'pri': '^\s*(\zs\u\ze)',
                \ 'hidden?': '\%(\<h:1\>\|'. g:ttodo#task_hide_rx .'\)',
                \ 'done?': '^\C\s*x\ze\s',
                \ 'donedate': '^\Cx\s\+\zs'. g:tlib#date#date_rx,
                \ 'rec': '\<rec:\zs+\?\d\+[dwmy]\ze\>',
                \ }
endif
if exists('g:ttodo#parse_rx_user')
    call extend(g:ttodo#parse_rx, g:ttodo#parse_rx_user)
endif


if !exists('g:ttodo#rewrite_gsub')
    ":nodoc:
    let g:ttodo#rewrite_gsub = [
                \ ['^\C\%((\u)\s\+\)\?\zs'. g:tlib#date#date_rx .'\s*', ''],
                \ ['\%(^\|\s\+\)\%(id\|parent\|t\):\S\+', ''],
                \ ]
endif
if exists('g:ttodo#rewrite_gsub_user')
    call extend(g:ttodo#rewrite_gsub, g:ttodo#rewrite_gsub_user)
endif


if !exists('g:ttodo#mapleader')
    let g:ttodo#mapleader = '<LocalLeader>t'   "{{{2
endif


if !exists('g:ttodo#new_task')
    " Defintion for tasks added via |:Ttodonew|.
    let g:ttodo#new_task = {'lists': ['inbox'], 'pri': 'C'}   "{{{2
endif


if !exists('g:ttodo#inbox')
    " A file basename (no directory).
    "
    " Tasks added by |:Ttodonew| will be added to this file in the 
    " default (i.e. the first) directory in |g:ttodo#dirs|.
    let g:ttodo#inbox = 'todo.txt'  "{{{2
endif


call tlib#type#Define('ttodo_type_itemdef_opts', {'__name__': 's', '__rx__': 's'})


let s:list_env = {
            \ 'qfl_short_filename': 1,
            \ 'qfl_list_syntax': 'ttodo',
            \ 'qfl_list_syntax_nextgroup': '@TtodoTask',
            \ 'set_syntax': 'ttodo#InitListBuffer',
            \ 'scratch': '__Ttodo__',
            \ }

let s:list_env['key_map'] = {
            \     'default': {
            \             24 : {'key': 24, 'agent': 'ttodo#ftplugin#Agent', 'args': ['ttodo#ftplugin#MarkDone', 0], 'key_name': '<c-x>', 'help': 'Mark done'},
            \             4 : {'key': 4, 'agent': 'ttodo#ftplugin#Agent', 'args': ['ttodo#ftplugin#MarkDue', 'd', '\=str2nr(tlib#string#Input("Number of days: "))'], 'key_name': '<c-d>', 'help': 'Mark as due in N days'},
            \             23 : {'key': 23, 'agent': 'ttodo#ftplugin#Agent', 'args': ['ttodo#ftplugin#MarkDue', 'w', '\=str2nr(tlib#string#Input("Number of weeks: "))'], 'key_name': '<c-w>', 'help': 'Mark as due in N weeks'},
            \             25 : {'key': 25, 'agent': 'ttodo#ftplugin#Agent', 'args': ['ttodo#ftplugin#SetPriority', 0], 'key_name': '<c-y>', 'help': 'Change task category'},
            \     }
            \ }

if exists('g:ttodo#world_user')
    let s:list_env = tlib#eval#Extend(s:list_env, g:ttodo#world_user)
endif


let s:ttodo_dirs = {}


function! ttodo#GetDirs() abort "{{{3
    return s:ttodo_dirs
endf


function! s:GetOpt(opts, name) abort "{{{3
    return get(a:opts, a:name, g:ttodo#{a:name})
endf


" :display: s:ItemDef(var, item, ?opts={})
" Register a new directory with todo.txt files. The first directory is 
" the default directory for |g:ttodo#inbox|.
function! s:ItemDef(item, first) abort "{{{3
    if type(a:item) == 1
        let item  = a:item
        let opts = {}
    elseif type(a:item) == 3
        let [item, opts] = a:item
    elseif type(a:item) == 4
        let item  = get(a:item, 'file', get(a:item, 'dir', ''))
        if empty(item)
            throw 'Ttodo: No item: '. string(a:item)
        endif
        let opts = get(a:item, 'opts', {})
    else
        throw 'Ttodo: Unsupported value for g:ttodo#dirs: '. string(g:ttodo#dirs)
    endif
    Tlibtrace 'ttodo', item, keys(opts)
    if a:first
        let opts.default = 1
    endif
    let opts.__name__ = item
    let opts.__rx__ = '\V\^'. join(map(split(item, '[\/]', 1), 'tlib#rx#Escape(v:val, "V")'), '[\\/]')
    Tlibassert tlib#type#Has(opts, 'ttodo_type_itemdef_opts')
    return {item : opts}
endf


function! s:ItemsDefs(items, first) abort "{{{3
    let itemsdefs = {}
    let i = 0
    for item in a:items
        call extend(itemsdefs, s:ItemDef(item, a:first && i == 0))
        let i += 1
    endfor
    return itemsdefs
endf


if !empty(g:ttodo#dirs)
    call extend(s:ttodo_dirs, s:ItemsDefs(g:ttodo#dirs, empty(s:ttodo_dirs)))
endif


if exists('g:todotxt#dir')
    call extend(s:ttodo_dirs, s:ItemDef(g:todotxt#dir, empty(s:ttodo_dirs)))
endif


function! s:GetDefaultDirDef(args, default) abort "{{{3
    let dirsdefs = s:GetDirsDefs(a:args)
    " TLogVAR dirsdefs
    let default_dirs = filter(copy(dirsdefs), 'get(v:val, "default", 0)')
    " TLogVAR keys(default_dirs)
    if empty(default_dirs)
        return {'__name__': a:default}
    else
        return default_dirs[keys(default_dirs)[0]]
    endif
endf


let s:ttodo_args = {
            \ 'help': ':Ttodo',
            \ 'handle_exit_code': 1,
            \ 'values': {
            \   'bufname': {'type': 1},
            \   'bufnr': {'type': 1},
            \   'done': {'type': -1},
            \   'due': {'type': 1, 'validate': 'tlib#date#IsDate'},
            \   'encoding': {'type': 1},
            \   'file_exclude_rx': {'type': 1},
            \   'file_include_rx': {'type': 1},
            \   'hidden': {'type': -1},
            \   'inbox': {'type': 1},
            \   'pending': {'type': -1},
            \   'has_subtasks': {'type': -1},
            \   'has_lists': {'type': 3, 'complete_customlist': 'ttodo#CollectTags("lists")'},
            \   'has_tags': {'type': 3, 'complete_customlist': 'ttodo#CollectTags("tags")'},
            \   'lists': {'type': 3, 'complete_customlist': 'ttodo#CollectTags("lists")'},
            \   'tags': {'type': 3, 'complete_customlist': 'ttodo#CollectTags("tags")'},
            \   'sortseps': {'type': 3, 'complete_customlist': '["lists", "tags"]'},
            \   'files': {'type': 3, 'complete': 'files'},
            \   'dirs': {'type': 3, 'complete': 'dirs'},
            \   'path': {'type': 1, 'complete': 'dirs'},
            \   'pref': {'type': 1, 'complete_customlist': 'keys(g:ttodo#prefs)'},
            \   'pri': {'type': 1, 'complete_customlist': '["", "A-", "A-C", "W", "X-Z"]'},
            \   'sort': {'type': 1, 'complete_customlist': 'map(keys(g:ttodo#parse_rx), "substitute(v:val, ''\\W$'', '''', ''g'')")'},
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
    let bufname = get(a:args, 'bufname', '')
    let filedefs = []
    if !empty(bufname)
        call add(filedefs, {'fileargs': {}, 'file': bufname(bufname)})
    else
        let bufnr = get(a:args, 'bufnr', '')
        if !empty(bufnr)
            let bufnrs = tlib#string#SplitCommaList(bufnr)
            let files = map(bufnrs, 'bufname(str2nr(v:val))')
            for file in files
                call add(filedefs, {'fileargs': {}, 'file': file})
            endfor
        else
            if has_key(a:args, 'files')
                call extend(filedefs, map(s:ItemsDefs(a:args.files, 1), '{"fileargs": v:val, "file": v:key}'))
            else
                let dirsdefs = s:GetDirsDefs(a:args)
                for [dir, dirargs] in items(dirsdefs)
                    Tlibtrace 'ttodo', dir, keys(dirargs)
                    let pattern = get(a:args, 'pattern', s:GetOpt(dirargs, 'file_pattern'))
                    Tlibtrace 'ttodo', pattern
                    let files = tlib#file#Glob(tlib#file#Join([dir, pattern]))
                    let file_include_rx = get(a:args, 'file_include_rx', s:GetOpt(a:args, 'file_include_rx'))
                    if !empty(file_include_rx)
                        let files = filter(files, 'v:val =~# file_include_rx')
                    endif
                    let file_exclude_rx = get(a:args, 'file_exclude_rx', s:GetOpt(a:args, 'file_exclude_rx'))
                    if !empty(file_exclude_rx)
                        let files = filter(files, 'v:val !~# file_exclude_rx')
                        for file in files
                            call add(filedefs, {'fileargs': dirargs, 'file': file})
                        endfor
                    endif
                endfor
            endif
        endif
    endif
    let filedefs = map(filedefs, 's:EnrichWithFileargs(v:val)')
    Tlibtrace 'ttodo', len(filedefs)
    Tlibassert tlib#type#Are(copy(filedefs), 'dict')
    Tlibassert tlib#type#Have(copy(filedefs), ['fileargs', 'file'])
    return filedefs
endf


function! s:GetDirsDefs(args) abort "{{{3
    let dirs = s:GetDirs(a:args)
    if empty(dirs)
        throw 'TTodo: Please set dirs via g:ttodo#dirs'
    endif
    let dirsdefs = s:ItemsDefs(dirs, 1)
    return dirsdefs
endf


function! s:GetDirs(args) abort "{{{3
    if has_key(a:args, 'path')
        let dirs = tlib#string#SplitCommaList(a:args.path)
    elseif has_key(a:args, 'dirs')
        let dirs = a:args.dirs
    else
        let dirs = keys(s:ttodo_dirs)
    endif
    return dirs
endf


function! s:EnrichWithFileargs(filedef) abort "{{{3
    " TLogVAR a:filedef
    let filename = a:filedef.file
    for [rx, fileargs] in items(g:ttodo#fileargs)
        " TLogVAR rx
        if filename =~# rx
            " TLogVAR fileargs
            let a:filedef.fileargs = tlib#eval#Extend(copy(a:filedef.fileargs), fileargs)
            " TLogVAR a:filedef.fileargs
        endif
    endfor
    return a:filedef
endf


let s:filetasks = {}

function! s:filetasks.GetQfeByLnum(lnum) abort dict "{{{3
    return get(self.qfe_by_lnum, ''. a:lnum, {})
    " for qfe in self.qfl
    "     if qfe.lnum == a:lnum
    "         return qfe
    "     endif
    " endfor
    " return {}
endf


":nodoc:
function! ttodo#GetFileTasks(args, file, fileargs) abort "{{{3
    " TLogVAR a:file, keys(a:fileargs)
    let qfl = []
    let task_by_id = {}
    let qfe_by_lnum = {}
    let children = {}
    let lnum = 0
    let pred_idx = -1
    let filelines = s:GetLines(a:file, a:fileargs)
    let source = filelines.source
    for line in filelines.lines
        let lnum += 1
        let task = ttodo#ParseTask(line, a:file, a:args)
        let id = get(task, 'id', '')
        let task.__source__ = source
        " TLogVAR task
        if get(task, 'subtask', 0) && pred_idx >= 0
            " TLogVAR task
            let indentstr = matchstr(line, '^\%(\s\{1,'. &shiftwidth .'}\)\+')
            " TLogVAR indentstr
            let indentstr = substitute(indentstr, '\%(\s\{1,'. &shiftwidth .'}\)', '+', 'g')
            let indent = len(indentstr)
            " TLogVAR indentstr, indent
            let line = substitute(line, '^\s\+', '', '')
            let parent_idx = pred_idx
            let parent = qfl[parent_idx]
            " TLogVAR -1, parent
            while get(parent.task, '__indent__', 0) >= indent
                let parent_idx = parent.task.__parent_idx__
                let parent = qfl[parent_idx]
            endwh
            let parent_indent = get(parent.task, '__indent__', 0)
            " TLogVAR indent, parent_indent, parent_idx, parent
            if !task.done
                " let parent.task.has_subtasks = get(parent.task, 'has_subtasks', 0) + 1
                let parent.task.has_subtasks = 1
                " TLogVAR parent, parent_idx, pred_idx
                let qfl[parent_idx] = parent
            endif
            if has_key(task, 'due') && task.due > get(parent.task, 'due', task.due)
                echohl WarningMsg
                echom 'WARN ttodo#GetFileTasks: subtask has due date after the parent''s task due date: '. line
                echohl NONE
            endif
            let task0 = task
            let task = tlib#eval#Extend(copy(parent.task), task)
            let task.has_subtasks = 0
            let task.__level__ = get(parent.task, '__level__', 0) + 1
            let task.__indent__ = indent
            let task.__parent_idx__ = parent_idx
            if !has_key(children, parent_idx)
                let children[parent_idx] = {}
            endif
            let children[parent_idx][pred_idx + 1] = 1
            " TLogVAR task, qfl[parent_idx]
            let line .= ' | '. substitute(s:FormatTask(a:args, copy(parent), 0).text, '^\C\s*\%(x\s\+\)\?\%((\u)\s\+\)\?', '', '')
            if has_key(parent.task, 'pri') && !has_key(task0, 'pri')
                " TLogVAR task0
                let line = '('. parent.task.pri .') '. line
            endif
            " TLogVAR line
        else
            " TLogVAR a:file, a:fileargs, line
            for [prefix, key] in [['@', 'lists'], ['+', 'tags']]
                if has_key(a:fileargs, key)
                    let vals = a:fileargs[key]
                    let task[key] += vals
                    let line = ttodo#MaybeAppend(line, ttodo#FormatTags(prefix, vals))
                endif
            endfor
            " TLogVAR line
        endif
        let pred_idx += 1
        let task.idx = pred_idx
        let qfe = {"filename": a:file, "lnum": lnum, "text": line, "task": task}
        call add(qfl, qfe)
        if !empty(id)
            let task_by_id[id] = task
        endif
        let qfe_by_lnum[lnum] = qfe
    endfor
    let qfl = map(qfl, 's:SetPending(v:key, v:val, task_by_id)')
    let filetasks = extend({'qfl': qfl, 'task_by_id': task_by_id, 'qfe_by_lnum': qfe_by_lnum}, s:filetasks)
    return filetasks
endf


function! s:SetPending(idx, qfe, task_by_id) abort "{{{3
    let deps = get(a:qfe.task, 'dep', '')
    if !empty(deps)
        for dep in tlib#string#SplitCommaList(deps)
            if has_key(a:task_by_id, dep)
                let done = get(a:task_by_id[dep], 'done', 1)
                if !done
                    let a:qfe.task.pending = 1
                    " TLogVAR a:idx, done
                    break
                endif
            endif
        endfor
    endif
    return a:qfe
endf


function! s:GetLines(filename, fileargs) abort "{{{3
    let bufnr = bufnr(a:filename)
    if bufnr == -1 || !bufloaded(bufnr)
        let lines = readfile(a:filename)
        if has('iconv')
            " TLogVAR keys(a:fileargs)
            let tenc = get(a:fileargs, 'encoding', &enc)
            " TLogVAR tenc, &enc
            if tenc != &enc
                let lines = map(lines, 'iconv(v:val, tenc, &enc)')
            endif
        endif
        return {'source': 'file', 'lines': lines}
    else
        return {'source': 'buffer', 'lines': getbufline(bufnr, 1, '$')}
    endif
endf


function! s:GetTasks(args) abort "{{{3
    let qfl = []
    for filedef in s:GetFiles(a:args)
        let filetasks = ttodo#GetFileTasks(a:args, filedef.file, filedef.fileargs)
        if !empty(filetasks)
            let qfl = extend(qfl, filetasks.qfl)
        endif
    endfor
    return qfl
endf


let s:parsed_tasks = {}


function! ttodo#ParseTask(task, file, ...) abort "{{{3
    TVarArg ['args', {}]
    let cid = join([a:task, a:file, get(args, 'lists', []), get(args, 'tags', [])], "\n")
    if has_key(s:parsed_tasks, cid)
        " TLogVAR cid
        let task = deepcopy(s:parsed_tasks[cid])
    else
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
        let task.lists = filter(map(split(a:task, '\ze@'), 'matchstr(v:val, ''^@\zs\S\+'')'), '!empty(v:val)') + get(args, 'lists', [])
        let task.tags = filter(map(split(a:task, '\ze+'), 'matchstr(v:val, ''^+\zs\S\+'')'), '!empty(v:val)') + get(args, 'tags', [])
        let task.file = a:file
        let s:parsed_tasks[cid] = deepcopy(task)
    endif
    return task
endf


function! s:FilterTasks(args) abort "{{{3
    let qfl = s:GetTasks(a:args)
    let task_include_rx = get(a:args, 'task_include_rx', g:ttodo#task_include_rx)
    let task_exclude_rx = get(a:args, 'task_exclude_rx', g:ttodo#task_exclude_rx)
    let qfl = filter(qfl, '(empty(task_include_rx) || v:val.text =~ task_include_rx) && (empty(task_exclude_rx) || v:val.text !~ task_exclude_rx)')
    if has_key(a:args, 'due')
        let due = a:args.due
        let today = strftime(g:tlib#date#date_format)
        if due =~ '^t%\[oday]$'
            call filter(qfl, 'empty(get(v:val.task, "due", "")) || get(v:val.task, "due", "") <= '. string(today))
        elseif due =~ '^\d\+-\d\+-\d\+$'
            call filter(qfl, 'empty(get(v:val.task, "due", "")) || get(v:val.task, "due", "") <= '. string(due))
        else
            if due =~ '^\d\+w$'
                let due = matchstr(due, '^\d\+') * 7
            endif
            call filter(qfl, 'empty(get(v:val.task, "due", "")) || tlib#date#DiffInDays(v:val.task.due) <= '. due)
        endif
        if !get(a:args, 'undated', 0)
            call filter(qfl, '!empty(get(v:val.task, "due", ""))')
        endif
    endif
    for lst in ['lists', 'tags']
        let key = 'has_'. lst
        if has_key(a:args, key)
            let vals = a:args[key]
            call filter(qfl, 's:HasAnyList(v:val.task[lst], vals)')
        endif
    endfor
    if !get(a:args, 'has_subtasks', 0)
        call filter(qfl, 'get(v:val.task, "has_subtasks", 0) == 0')
    endif
    if !get(a:args, 'done', 0)
        call filter(qfl, '!get(v:val.task, "done", 0)')
    endif
    if !get(a:args, 'hidden', 0)
        call filter(qfl, 'empty(get(v:val.task, "hidden", ""))')
    endif
    if !get(a:args, 'pending', 0)
        call filter(qfl, '!get(v:val.task, "pending", 0)')
    endif
    if has_key(a:args, 'pri')
        call filter(qfl, 'get(v:val.task, "pri", "") =~# ''^['. a:args.pri .']$''')
    endif
    if get(a:args, 'threshold', 1)
        let today = strftime(g:tlib#date#date_format)
        call filter(qfl, 's:CheckThreshold(get(v:val.task, "t", ""), get(v:val.task, "due", ""), today)')
    endif
    return qfl
endf


function! s:HasAnyList(tags, vals) abort "{{{3
    let rv = !empty(filter(copy(a:tags), 'index(a:vals, v:val) != -1'))
    " TLogVAR a:tags, a:vals, rv
    return rv
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


let s:sort_params = {}


function! s:sort_params.GetSortItem(qfe, task, item, default) abort dict "{{{3
    let val = get(a:task, a:item, get(a:qfe, a:item, a:default))
    if type(val) > 1
        let tmp = val
        unlet val
        let val = string(tmp)
        unlet tmp
    endif
    return val
endf


" function! s:sort_params.GetSortTasks(a, b) abort dict "{{{3
"     let api = get(a:a, '__parent_idx__', -1)
"     let bpi = get(a:b, '__parent_idx__', -1)
"     while api != bpi
"         " let al = get(a:a, '__level__', 0)
"         " let bl = get(a:b, '__level__', 0)
"     endwh
"     return 
" endf


function! s:SortTasks(args, qfl) abort "{{{3
    " TLogVAR a:qfl
    let params = {'qfl': a:qfl, 'fields': tlib#string#SplitCommaList(get(a:args, 'sort', g:ttodo#sort))}
    let params = extend(params, s:sort_params, 'keep')
    let qfl = sort(a:qfl, 's:SortTask', params)
    return qfl
endf


function! s:SortTask(a, b) dict abort "{{{3
    let a = a:a.task
    let b = a:b.task
    for item in self.fields
        if item =~# '^-\S\+$'
            let mul = -1
            let item = substitute(item, '^-', '', '')
        else
            let mul = 1
        endif
        let default = get(g:ttodo#sort_defaults, item, '')
        let aa = self.GetSortItem(a:a, a, item, default)
        let bb = self.GetSortItem(a:b, b, item, default)
        if item == 'overdue'
            " TLogVAR aa, bb, default, a, b
        endif
        if aa != bb
            return mul * (aa > bb ? 1 : -1)
        endif
        unlet aa bb default
    endfor
    return 0
endf


function! s:FormatTask(args, qfe, maybe_iconv) abort "{{{3
    " TLogVAR a:qfe
    let text = a:qfe.text
    let text0 = text
    " TLogVAR text0
    for [rx, subst] in g:ttodo#rewrite_gsub
        let text = substitute(text, rx, subst, 'g')
        " TLogVAR rx, subst, text
    endfor
    if text !=# text0
        let qfe = copy(a:qfe)
        let qfe.text = text
        return qfe
    else
        return a:qfe
    endif
endf


function! ttodo#GetOpts(bang, cmdargs) abort "{{{3
    let args = tlib#arg#GetOpts(a:cmdargs, s:ttodo_args)
    let pref = get(args, 'pref', a:bang ? 'important' : 'default')
    Tlibtrace 'ttodo', pref
    let args = tlib#eval#Extend(copy(g:ttodo#prefs[pref]), args)
    Tlibtrace 'ttodo', keys(args)
    return args
endf


":nodoc:
function! ttodo#Show(bang, cmdargs) abort "{{{3
    let args = ttodo#GetOpts(a:bang, a:cmdargs)
    Tlibtrace 'ttodo', args
    " TLogVAR args
    if args.__exit__
        return
    else
        " TLogVAR args
        let qfl = copy(s:FilterTasks(args))
        let qfl = s:SortTasks(args, qfl)
        let qfl = map(qfl, 's:FormatTask(args, v:val, 1)')
        let flt = get(args, '__rest__', [])
        if !empty(qfl)
            if g:ttodo#viewer ==# 'tlib'
                let w = copy(s:list_env)
                if !empty(flt)
                    Tlibtrace 'ttodo', flt
                    let w.initial_filter = [[""], flt]
                endif
                let overdue_rx = s:QflOverdueRx(qfl)
                if !empty(overdue_rx)
                    let w.overdue_rx = overdue_rx
                endif
                call tlib#qfl#QflList(qfl, w)
            elseif g:ttodo#viewer =~# '^:'
                if exists(g:ttodo#viewer) == 2
                    if !empty(flt)
                        let qfl = filter(qfl, 's:FilterQFL(v:val, flt)')
                    endif
                    call setqflist(qfl)
                    exec g:ttodo#viewer
                endif
            else
                throw 'TTodo: Unsupported value for g:ttodo#viewer: '. string(g:ttodo#viewer)
            endif
        endif
    endif
endf


function! ttodo#GetOverdueRx(args) abort "{{{3
    let qfl = s:GetTasks(a:args)
    return s:QflOverdueRx(qfl)
endf


function! s:QflOverdueRx(qfl) abort "{{{3
    let overdue = filter(copy(a:qfl), 'get(v:val.task, "overdue", 0)')
    if !empty(overdue)
        return '\V\<due:\%('. join(map(overdue, 'v:val.task.due'), '\|') .'\)\>'
    else
        return ''
    endif
endf


function! ttodo#InitListBuffer() dict abort "{{{3
    call call('tlib#qfl#SetSyntax', [], self)
    if has_key(self, 'overdue_rx')
        Tlibtrace self.overdue_rx
        " TLogVAR self.overdue_rx
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
        elseif a:ArgLead =~# '^@'
            let words = map(ttodo#CollectTags("lists"), '"@". v:val')
            let nchar = len(a:ArgLead)
            call filter(words, 'strpart(v:val, 0, nchar) ==# a:ArgLead')
        elseif a:ArgLead =~# '^+'
            let words = map(ttodo#CollectTags("tags"), '"+". v:val')
            let nchar = len(a:ArgLead)
            call filter(words, 'strpart(v:val, 0, nchar) ==# a:ArgLead')
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


function! ttodo#CollectTags(type) abort "{{{3
    let args = {}
    if &ft == 'ttodo'
        let args.bufname = '%'
    endif
    let tasks = s:GetTasks(args)
    let tags = map(copy(tasks), 'v:val.task[a:type]')
    let tags = tlib#list#Flatten(tags)
    let tags = filter(tags, '!empty(v:val)')
    let tags = tlib#list#Uniq(tags)
    let tags = sort(tags)
    return tags
endf


function! ttodo#FiletypeDetect(...) abort "{{{3
    let filename = a:0 >= 1 ? a:1 : expand('%:p')
    " TLogVAR filename
    let bdir = substitute(filename, '\\', '/', 'g')
    let bdir = substitute(bdir, '/[^/]\+$', '', '')
    let dirs = map(keys(s:ttodo_dirs), 'substitute(resolve(fnamemodify(v:val, ":p:h")), ''\\'', ''/'', ''g'')')
    " TLogVAR bdir, dirs
    if index(dirs, bdir, 0, !has('fname_case')) != -1
        setf ttodo
        " TLogVAR &ft
    endif
endf


" If called with --sortseps=tags,lists, an empty line is inserted after 
" each main (i.e. first) list or tag.
"
" Sorting doesn't work for outlines, i.e. tasks with subtasks.
function! ttodo#SortBuffer(cmdargs) abort "{{{3
    let args = ttodo#GetOpts(0, a:cmdargs)
    let filename = expand('%:p')
    let filetasks = ttodo#GetFileTasks(args, filename, {})
    let qfl = filetasks.qfl
    if !empty(filter(copy(qfl), 'get(v:val.task, "subtask", 0)'))
        throw 'ttodo#SortBuffer: Cannot sort task outlines!'
    endif
    let qfl = s:SortTasks(args, qfl)
    let seps = get(args, 'sortseps', []) 
    " TLogVAR seps
    if empty(seps)
        let tasks = map(qfl, 'v:val.task.text')
    else
        let tasks = []
        let last = {}
        for qfe in qfl
            for sep in seps
                if !empty(last) && get(get(last.task, sep, []), 0, '') != get(get(qfe.task, sep, []), 0, '')
                    " TLogVAR last, qfe
                    call add(tasks, '')
                    break
                endif
            endfor
            call add(tasks, qfe.task.text)
            let last = qfe
        endfor
    endif
    let pos = getpos('.')
    try
        1,$delete
        call append(1, tasks)
        1delete
    finally
        call setpos('.', pos)
    endtry
endf


function! ttodo#NewTask(cmdargs) abort "{{{3
    let args = extend(copy(g:ttodo#new_task), ttodo#GetOpts(0, a:cmdargs))
    let filename = get(args, 'inboxfile', '')
    if empty(filename)
        let dirdef = s:GetDefaultDirDef(args, '.')
        " TLogVAR keys(dirdef), dirdef.__name__
        let filename = tlib#file#Join([dirdef.__name__, get(args, 'inbox', get(dirdef, 'inbox', g:ttodo#inbox))])
    endif
    let text = join(args.__rest__)
    let text = ttodo#MaybeAppend(text, get(args, 'suffix', ''))
    let text = ttodo#MaybeAppend(text, ttodo#FormatTags('@', get(args, 'lists', [])))
    let text = ttodo#MaybeAppend(text, ttodo#FormatTags('+', get(args, 'tags', [])))
    let args = extend(args, ttodo#ParseTask(text, filename))
    exec 'tab drop' fnameescape(filename)
    let text = substitute(text, '\C^\s*(\u)\s*', '', '')
    exec 'norm!' ttodo#ftplugin#New('G', 0, 'n', args) . text
endf


function! ttodo#FormatTags(prefix, lists) abort "{{{3
    " TLogVAR a:prefix, a:lists
    return join(map(copy(a:lists), 'a:prefix . v:val'))
endf


function! ttodo#MaybeAppend(text, suffix) abort "{{{3
    if empty(a:suffix)
        return a:text
    else
        return a:text .' '. a:suffix
    endif
endf


function! ttodo#FileSources(args) abort "{{{3
    Tlibtrace 'ttodo', a:args
    let args = a:args
    let pref = get(args, 'pref', 'default')
    Tlibtrace 'ttodo', pref
    let args = tlib#eval#Extend(copy(g:ttodo#prefs[pref]), args)
    let pattern = get(args, 'glob', get(args, 'deep', 1) ? '**' : '*')
    let globs = {}
    let dirsdefs = s:GetDirsDefs(args)
    for [dir, dirargs] in items(dirsdefs)
        let glob = tlib#file#Join([dir, pattern])
        Tlibtrace 'ttodo', glob
        let globs[glob] = 1
    endfor
    return keys(globs)
endf

