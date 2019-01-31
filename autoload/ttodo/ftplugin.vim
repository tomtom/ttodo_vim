" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2019-01-11
" @Revision:    452


if !exists('g:ttodo#ftplugin#notefmt')
    if exists('g:ttodo#ftplugin#notef') " && g:ttodo#ftplugin#notef !=# 'notes/%s/%s-%s.md'
        let g:ttodo#ftplugin#notefmt = printf(g:ttodo#ftplugin#notef, '${name}', '${date}', '${index}')
    else
        let g:ttodo#ftplugin#notefmt = 'notes/${year}/${name}/${date}-${index}.md'   "{{{2
    endif
endif


if !exists('g:ttodo#ftplugin#note_prefix')
    " Prefix for references to notes.
    "
    " Possible (potentially useful) values:
    "   - todo:// (opens the file in SimpleTask)
    "   - root:// (SimpleTask: path relative to todo.txt file)
    "   - file:// (less useful since it would require an absolute path)
    let g:ttodo#ftplugin#note_prefix = 'root://'   "{{{2
endif


if !exists('g:ttodo#ftplugin#edit_note')
    " If non-empty, edit a newly added reference to a note right away.
    "
    " Possible (potentially useful) values:
    "   - split
    "   - hide edit
    "   - tabedit
    let g:ttodo#ftplugin#edit_note = ''   "{{{2
endif


if !exists('g:ttodo#ftplugin#add_at_eof')
    " If true, the <cr> or <c-cr> map will make ttodo add a new task at 
    " the end of the file. Otherwise the task will be added below the 
    " current line.
    " Subtasks will always be added below the current line.
    let g:ttodo#ftplugin#add_at_eof = 1   "{{{2
endif


if !exists('g:ttodo#ftplugin#rec_copy')
    " If true, marking a recurring task as "done" will mark the old task 
    " as completed and will then create a new updated task.
    let g:ttodo#ftplugin#rec_copy = 1   "{{{2
endif


if !exists('g:ttodo#ftplugin#new_subtask_copy_pri')
    " If true, copy the parent task's priority when creating subtasks.
    let g:ttodo#ftplugin#new_subtask_copy_pri = 0   "{{{2
endif


if !exists('g:ttodo#ftplugin#done_filename_rewrite_expr')
    let g:ttodo#ftplugin#done_filename_rewrite_expr = 'substitute(%s, ''\<todo\(_.\{-}\)\?\.txt$'', ''done\1.txt'', '''')'   "{{{2
endif


function! ttodo#ftplugin#Archive(filename) abort "{{{3
    let basename = fnamemodify(a:filename, ':t')
    if exists('g:ttodo#ftplugin#done_filename_rewrite_expr') && !empty(g:ttodo#ftplugin#done_filename_rewrite_expr)
        let arc = eval(printf(g:ttodo#ftplugin#done_filename_rewrite_expr, string(fnamemodify(a:filename, ':p'))))
    else
        let arc = fnamemodify(a:filename, ':p:h') .'/done.txt'
    endif
    if filereadable(arc) && !filewritable(arc)
        throw 'TTodo: Cannot write: '. arc
    endif
    if !filewritable(a:filename)
        throw 'TTodo: Cannot write: '. a:filename
    endif
    let done = []
    let undone = []
    let today = strftime(g:tlib#date#date_format)
    let filetasks = ttodo#GetFileTasks({}, a:filename, {})
    let lines = readfile(a:filename)
    for lnum0 in range(len(lines))
        let qfi = filetasks.GetQfeByLnum(lnum0 + 1)
        if empty(qfi)
            continue
        elseif has_key(qfi, 'task')
            let task = qfi.task
        else
            throw 'ttodo#ftplugin#Archive: Unexpected item lnum='. (lnum0 + 1) .': '. string(qfi)
        endif
        " let line = lines[lnum0]
        let line = task.text
        if line != lines[lnum0]
            throw 'Ttodo: Internal error: Lines differ: '. string(line) .' != '. string(lines[lnum0])
        endif
        if get(task, 'done', 0) && !get(task, 'has_subtasks', 0) && !get(task, 'pending', 0)
            let dline = tlib#string#TrimLeft(line)
            let dline .= ' archive:'. today
            let dline .= ' source:'. basename
            call add(done, dline)
        else
            call add(undone, line)
        endif
    endfor
    if !empty(done)
        if filereadable(arc)
            let done = readfile(arc) + done
        endif
        call writefile(done, arc)
        call writefile(undone, a:filename)
    endif
endf


function! ttodo#ftplugin#ArchiveCurrentBuffer() abort "{{{3
    update
    call ttodo#ftplugin#Archive(expand('%:p'))
    edit
endf


function! ttodo#ftplugin#Note() abort "{{{3
    let line = getline('.')
    let task = ttodo#ParseTask(line, expand('%:p'))
    Tlibtrace 'ttodo', task
    let nname = get(task.lists, 0, 'misc')
    let nname = substitute(nname, '\W', '_', 'g')
    let date = strftime('%Y%m%d')
    let year = strftime('%Y')
    let dir = expand('%:p:h')
    Tlibtrace 'ttodo', nname, dir
    let fargs = {'name': nname, 'date': date, 'year': year, 'index': 0}
    while 1
        let shortname = tlib#string#Format(g:ttodo#ftplugin#notefmt, fargs, '$')
        let filename = tlib#file#Join([dir, shortname])
        if filereadable(filename)
            let fargs.n += 1
        else
            let notename = g:ttodo#ftplugin#note_prefix . shortname
            break
        endif
    endwh
    Tlibtrace 'ttodo', filename
    call setline('.', join([line, notename]))
    call tlib#dir#Ensure(fnamemodify(filename, ':p:h'))
    if !empty(g:ttodo#ftplugin#edit_note)
        exec g:ttodo#ftplugin#edit_note fnameescape(filename)
    endif
endf


" Values for copytags:
"   1 ... Copy tags
"   2 ... Copy tags & mark as dependency
function! ttodo#ftplugin#New(move, copytags, mode, ...) abort "{{{3
    Tlibtrace 'ttodo', a:move, a:copytags, a:mode, a:000
    if a:mode == 'i'
        let o = "\<c-m>"
    else
        let o = "o"
    endif
    let new = strftime(g:tlib#date#date_format)
    if a:copytags == 2
        let [isnew, id] = s:EnsureIdAtLine(line('.'))
        if isnew
            if a:mode == 'i'
                let o = "\<End> id:". id . o
            else
                let o = 'A id:'. id ."\<Esc>". o
            endif
        endif
        let new .= ' dep:'. id
    endif
    let i0 = indent('.')
    Tlibtrace 'ttodo', o, new, i0
    " new item after indented line
    if i0 > 0 && empty(a:move)
        let move_down = ''
        for pos1 in range(line('.') + 1, line('$'))
            let i1 = indent(pos1)
            Tlibtrace 'ttodo', i1
            if i1 > i0
                let move_down .= 'j'
            else
                break
            endif
        endfor
        let keys = o . new .' '
        if !empty(move_down)
            let keys .= "\<Esc>ddk" . move_down . 'pA'
        endif
        Tlibtrace 'ttodo', keys
        return keys
    else
        let task = a:0 >= 1 ? a:1 : ttodo#ParseTask(getline('.'), expand('%:p'))
        if a:move == '>'
            let new = new .' '
            if g:ttodo#ftplugin#new_subtask_copy_pri
                Tlibtrace 'ttodo', g:ttodo#ftplugin#new_subtask_copy_pri, new
                let new = s:MaybeCopyPriority(task, new)
            endif
            let prefix = matchstr(getline('.'), '^\s\+')
            Tlibtrace 'ttodo', prefix
            if g:ttodo#ftplugin#add_at_eof
                for lnum in range(line('.'), line('$') - 1)
                    let i1 = indent(lnum + 1)
                    Tlibtrace 'ttodo', lnum, i0, i1
                    if i1 == 0 || i1 <= i0
                        let expr = lnum .'gg'. o ."\<Esc>I". prefix ."\<c-t>". new
                        Tlibtrace 'ttodo', expr
                        return expr
                    endif
                endfor
            endif
            Tlibtrace 'ttodo', o, new
            return o ."\<c-t>" . new
        else
            let o .= "\<home>"
            if a:copytags > 0
                let new = ttodo#MaybeAppend(new, ttodo#FormatTags('@', task.lists))
                let new = ttodo#MaybeAppend(new, ttodo#FormatTags('+', task.tags))
                let new = ttodo#MaybeAppend(new, join(task.notes))
            endif
            let new = s:MaybeCopyPriority(task, new)
            let move = a:move
            if empty(move) && i0 == 0
                let move = g:ttodo#ftplugin#add_at_eof ? 'G' : ''
                " else " TODO: find last line with same indent
            endif
            if a:mode == 'i' && !empty(move)
                let move = "\<c-\>\<c-o>"
            endif
            Tlibtrace 'ttodo', move, o, new
            return move . o . new .' '
        endif
    endif
endf


function! s:MaybeCopyPriority(task, text) abort "{{{3
    if has_key(a:task, 'pri')
        return ttodo#MaybeSetPriority(a:text, a:task.pri)
    else
        return a:text
    endif
endf


function! s:IsDone(line) abort "{{{3
    return a:line =~# '^\s*x\s'
endf


function! ttodo#ftplugin#MarkDone(count, ...) abort "{{{3
    TVarArg ['ignore_rec', 0]
    Tlibtrace 'ttodo', a:count, ignore_rec
    let donedate = strftime(g:tlib#date#date_format)
    let lnum0 = line('.')
    for lnum in range(lnum0, lnum0 + a:count)
        let line = getline(lnum)
        Tlibtrace 'ttodo', lnum, line
        let task = ttodo#ParseTask(line, expand('%:p'))
        Tlibtrace 'ttodo', task
        if !get(task, 'done', 0)
            if !ignore_rec
                let rec = get(task, 'rec', '')
                if !empty(rec)
                    if get(task, 'subtask', 0)
                        echohl Error
                        echom "TTodo: Cannot complete subtasks with a 'rec:' tag:" line
                        continue
                    elseif get(task, 'has_subtask', 0)
                        " TODO: Must copy the whole tree
                        echohl Error
                        echom "TTodo: Cannot complete top tasks with a 'rec:' tag:" line
                        continue
                    else
                        if g:ttodo#ftplugin#rec_copy
                            call ttodo#ftplugin#MarkDone(0, 1)
                            let line = ttodo#SetCreateDate(line)
                            call append('$', line)
                            let lnum = line('$')
                        endif
                        let shift = matchstr(rec, '\d\+\a$')
                        let due = get(task, 'due', '')
                        if !empty(due)
                            let refdate = rec =~ '^+' ? due : donedate
                            Tlibtrace 'ttodo', rec, due, shift, refdate
                            while 1
                                let due = tlib#date#Shift(due, shift)
                                Tlibtrace 'ttodo', due
                                if due > refdate
                                    break
                                endif
                            endwh
                            exec lnum
                            call s:MarkDueDate(due)
                        endif
                        if has_key(task, 't') && task.t =~# g:tlib#date#date_rx
                            let t0 = task.t
                            let t1 = tlib#date#Shift(t0, shift)
                            Tlibtrace 'ttodo', t1
                            exec lnum
                            call s:SetTag('t', g:tlib#date#date_rx, t1)
                        endif
                        continue
                    endif
                endif
            endif
            if get(task, 'next', 0)
                if line =~ '@next\s\+'
                    let line = substitute(line, '@next\s\+', '', '')
                else
                    let line = substitute(line, '\s\+@next\>', '', '')
                endif
                " call setline(lnum, line)
            endif
        endif
        if get(task, 'subtask', 0) && !has_key(task, 'parent')
            let parent = s:GetParentID(lnum)
            if !empty(parent)
                let line = line .' parent:'. parent
                " call setline(lnum, line .' parent:'. parent)
            endif
        endif
        let line = substitute(line, '^\s*\zs\C\%(x\s\+\%('. g:tlib#date#date_rx .'\s\+\)\?\)\?', 'x '. donedate .' ', '')
        call setline(lnum, line)
        " exec lnum .'s/^\s*\zs\C\%(x\s\+\%('. g:tlib#date#date_rx .'\s\+\)\?\)\?/x '. donedate .' /'
    endfor
    exec lnum0 + a:count
endf


function! s:GetIdAtLine(lnum) abort "{{{3
    let line = getline(a:lnum)
    let filename = expand('%:p')
    let task = ttodo#ParseTask(line, filename)
    if !has_key(task, 'id')
        exec a:lnum
        call ttodo#ftplugin#AddId(0)
        let task = ttodo#ParseTask(getline(a:lnum), filename)
    endif
    return task.id
endf


function! s:GetParentID(lnum0) abort "{{{3
    let indent0 = indent(a:lnum0)
    " let filename = expand('%:p')
    for lnum in range(a:lnum0 - 1, 1, -1)
        let indent = indent(lnum)
        if indent < indent0
            return s:GetIdAtLine(lnum)
            " let line = getline(lnum)
            " let task = ttodo#ParseTask(line, filename)
            " if !has_key(task, 'id')
            "     exec lnum
            "     call ttodo#ftplugin#AddId(0)
            "     let task = ttodo#ParseTask(getline(lnum), filename)
            " endif
            " return task.id
        endif
    endfor
    return ''
endf


function! ttodo#ftplugin#MarkDue(unit, count) abort "{{{3
    if a:count == -1
    elseif s:IsDone(getline('.'))
        echohl WarningMsg
        throw 'Ttodo: Cannot change finshed task'
        echohl NONE
    else
        if type(a:count) == 0
            let n = a:count
        elseif type(a:count) == 1
            let n = ttodo#InputNumber(a:count)
            if n < 0
                return
            endif
        else
            throw 'ttodo#ftplugin#MarkDue: count must be a number or a string'
        endif
        let task = ttodo#ParseTask(getline('.'), expand('%:p'))
        " let due = strftime(g:tlib#date#date_format)
        let due = get(task, 'due', strftime(g:tlib#date#date_format))
        let shift = n . a:unit
        let due = tlib#date#Shift(due, shift)
        call s:MarkDueDate(due)
        if has_key(task, 't') && task.t =~# g:tlib#date#date_rx
            let t0 = task.t
            let t1 = tlib#date#Shift(t0, shift)
            Tlibtrace 'ttodo', t1
            call s:SetTag('t', g:tlib#date#date_rx, t1)
        endif
    endif
endf


function! s:MarkDueDate(date) abort "{{{3
    call s:SetTag('due', '\%(\<today\>\|'. g:tlib#date#date_rx .'\)', a:date)
    " exec 's/\C\%(\s\+due:'. g:tlib#date#date_rx .'\|$\)/ due:'. a:date .'/'
endf


function! s:SetTag(name, rx, value) abort "{{{3
    exec 's/\C\%(\s\+'. a:name .':'. escape(a:rx, '/') .'\|$\)/ '. a:name .':'. escape(a:value, '/') .'/'
endf


function! ttodo#ftplugin#SetPriority(count, ...) abort "{{{3
    " TLogVAR a:count
    if s:IsDone(getline('.'))
        echohl WarningMsg
        throw 'Ttodo: Cannot change finshed task'
        echohl NONE
    else
        let category = a:0 >= 1 ? a:1 : tlib#string#Input('New task category [A-Z]: ')
        let category = toupper(category)
        if category =~ '\C^[A-Z]$'
            exec 's/^\s*\zs\C\%((\u)\s\+\)\?/('. category .') /'
        else
            echohl WarningMsg
            echom 'Invalid category (must be A-Z):' category
            echohl NONE
        endif
    endif
endf


function! ttodo#ftplugin#Agent(world, selected, fn, ...) abort "{{{3
    " TLogVAR a:fn, a:000
    let cmd = printf('call call(%s, %s)', string(a:fn), string(map(copy(a:000), 's:AgentEvalArg(v:val)')))
    Tlibtrace 'ttodo', cmd
    let world = tlib#qfl#RunCmdOnSelected(a:world, a:selected, cmd)
    return world
endf


function! s:AgentEvalArg(arg) abort "{{{3
    if type(a:arg) == 1 && a:arg =~ '^\\='
        return eval(substitute(a:arg, '^\\=', '', ''))
    elseif type(a:arg) == 1 && a:arg =~ '^".\{-}"$'
        return matchstr(a:arg, '^"\zs.\{-}\ze"$')
    else
        return a:arg
    endif
endf


function! s:EnsureIdAtLine(lnum, ...) abort "{{{3
    let filename = a:0 >= 1 ? a:1 : expand('%:p')
    let filetasks = a:0 >= 2 ? a:2 : ttodo#GetFileTasks({}, filename, {})
    let fqfl = filetasks.qfl
    let line = getline(a:lnum)
    let task = ttodo#ParseTask(line, filename)
    if !has_key(task, 'id')
        let qfe = filetasks.GetQfeByLnum(a:lnum)
        let ttask = string(empty(qfe) ? task : qfe)
        if v:version < 800 || !has('+reltime')
            let id = tlib#hash#Adler32(ttask)
        else
            " let id = 't'. tlib#number#ConvertBase(localtime(), 36)
            let id = tlib#number#ConvertBase(str2nr(substitute(reltimestr(reltime()), '\.', '', '')), 36)
        endif
        Tlibtrace 'ttodo', id
        return [1, id]
    else
        return [0, task.id]
    endif
endf


function! ttodo#ftplugin#AddId(count) abort "{{{3
    let filename = expand('%:p')
    let filetasks = ttodo#GetFileTasks({}, filename, {})
    let fqfl = filetasks.qfl
    for lnum in range(line('.'), line('.') + a:count)
        let [isnew, id] = s:EnsureIdAtLine(lnum, filename, filetasks)
        if isnew
            let line = getline(lnum) .' id:'. id
            Tlibtrace 'ttodo', lnum, line
            call setline(lnum, line)
        endif
    endfor
endf


function! ttodo#ftplugin#SyntaxDue() abort "{{{3
    let overdue_rx = ttodo#GetOverdueRx({'bufname': '%'})
    if !empty(overdue_rx)
        exec 'syntax match TtodoOverdue /'. escape(overdue_rx, '/') .'/'
    endif
    exec 'syntax match TtodoDue /\<due:\%(today\|'. strftime(g:tlib#date#date_format) .'\)\>/'
endf


function! ttodo#ftplugin#AddDep() abort "{{{3
    let filename = expand('%:p')
    let filetasks = ttodo#GetFileTasks({}, filename, {})
    " TLogVAR len(filetasks.qfl), len(filetasks.task_by_id)
    let with_id = values(map(copy(filetasks.task_by_id), 'v:key ."\t". v:val.text'))
    if empty(with_id)
        echom 'ttodo#ftplugin#AddDep: No IDs'
    else
        let dep = tlib#input#List('s', 'Select dependency:', with_id)
        if !empty(dep)
            let id = matchstr(dep, '^[^\t]\+\ze\t')
            call setline('.', getline('.') .' dep:'. id)
        endif
    endif
endf


function! ttodo#ftplugin#Duplicate(count, markdone) abort "{{{3
    " let pos = getpos('.')
    Tlibtrace 'ttodo', a:count, a:markdone
    for lnum in range(line('.'), line('.') + a:count - 1)
        Tlibtrace 'ttodo', lnum
        exec lnum
        if indent('.') > 0
            norm! yy
            if a:count > 0
                exec lnum + a:count - 1
            endif
            norm! p
        else
            norm! yyGp
        endif
        if a:markdone
            let p1 = getpos('.')
            exec lnum
            " call setpos('.', pos)
            call ttodo#ftplugin#MarkDone(0)
            call setpos('.', p1)
        endif
    endfor
endf

