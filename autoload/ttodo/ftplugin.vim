" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-23
" @Revision:    205


if !exists('g:ttodo#ftplugin#notef')
    let g:ttodo#ftplugin#notef = 'notes/%s/%s-%s.md'   "{{{2
endif


if !exists('g:ttodo#ftplugin#note_prefix')
    let g:ttodo#ftplugin#note_prefix = 'file://'   "{{{2
endif


if !exists('g:ttodo#ftplugin#edit_note')
    let g:ttodo#ftplugin#edit_note = 'split'   "{{{2
endif


if !exists('g:ttodo#ftplugin#add_at_eof')
    " If true, the <cr> or <c-cr> map will make ttodo add a new task at 
    " the end of the file. Otherwise the task will be added below the 
    " current line.
    " Subtasks will always be added below the current line.
    let g:ttodo#ftplugin#add_at_eof = 0   "{{{2
endif


function! ttodo#ftplugin#Archive(filename) abort "{{{3
    let arc = fnamemodify(a:filename, ':p:h') .'/done.txt'
    if filereadable(arc) && !filewritable(arc)
        throw 'TTodo: Cannot write: '. arc
    endif
    if !filewritable(a:filename)
        throw 'TTodo: Cannot write: '. a:filename
    endif
    let done = []
    let undone = []
    let today = strftime(g:tlib#date#date_format)
    for line in readfile(a:filename)
        if line =~# '^x\s'
            let line .= ' archive:'. today
            call add(done, line)
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
    let dir = expand('%:p:h')
    Tlibtrace 'ttodo', nname, dir
    let n = 0
    while 1
        let shortname = printf(g:ttodo#ftplugin#notef, nname, date, n)
        let filename = tlib#file#Join([dir, shortname])
        if filereadable(filename)
            let n += 1
        else
            let notename = g:ttodo#ftplugin#note_prefix . shortname
            break
        endif
    endwh
    Tlibtrace 'ttodo', filename
    call setline('.', join([line, notename]))
    call tlib#dir#Ensure(fnamemodify(filename, ':p:h'))
    exec g:ttodo#ftplugin#edit_note fnameescape(filename)
endf


function! ttodo#ftplugin#New(move, copytags, mode, ...) abort "{{{3
    " TLogVAR a:move, a:copytags
    if a:mode == 'i'
        let o = "\<c-m>"
    else
        let o = "o"
    endif
    let new = strftime(g:tlib#date#date_format)
    if indent('.') > 0 && empty(a:move)
        return o . new .' '
    elseif a:move == '>'
        return o ."\<c-t>" . new .' '
    else
        let o .= "\<home>"
        let task = a:0 >= 1 ? a:1 : ttodo#ParseTask(getline('.'), expand('%:p'))
        if a:copytags
            let new = ttodo#MaybeAppend(new, ttodo#FormatTags('@', task.lists))
            let new = ttodo#MaybeAppend(new, ttodo#FormatTags('+', task.tags))
        endif
        if has_key(task, 'pri')
            let new = '('. task.pri .') '. new
        endif
        let move = a:move
        if a:mode == 'i' && !empty(move)
            let move = "\<c-\>\<c-o>"
        endif
        return move . o . new .' '
    endif
endf


function! s:IsDone(line) abort "{{{3
    return a:line =~# '^\s*x\s'
endf


function! ttodo#ftplugin#MarkDone(count) abort "{{{3
    let donedate = strftime(g:tlib#date#date_format)
    for lnum in range(line('.'), line('.') + a:count)
        let line = getline(lnum)
        if !s:IsDone(line)
            let task = ttodo#ParseTask(line, expand('%:p'))
            let rec = get(task, 'rec', '')
            if !empty(rec)
                let due = get(task, 'due', '')
                let shift = matchstr(rec, '\d\+\a$')
                let refdate = rec =~ '^+' && !empty(due) ? due : donedate
                let ndue = empty(due) ? donedate : due
                " TLogVAR rec, due, shift, refdate
                while ndue <= refdate
                    let ndue = tlib#date#Shift(ndue, shift)
                    " TLogVAR ndue
                endwh
                exec lnum
                call s:MarkDueDate(ndue)
                if has_key(task, 't') && task.t =~# g:tlib#date#date_rx
                    let t0 = task.t
                    let t0s = tlib#date#SecondsSince1970(t0)
                    let dues = tlib#date#SecondsSince1970(due)
                    let t0diff = dues - t0s
                    let ndues = tlib#date#SecondsSince1970(ndue)
                    let t1s = ndues - t0diff
                    let t1 = tlib#date#Format(t1s)
                    call s:SetTag('t', g:tlib#date#date_rx, t1)
                endif
                continue
            endif
        endif
        if get(task, 'subtask', 0) && !has_key(task, 'parent')
            let parent = s:GetParentId(lnum)
            if !empty(parent)
                call setline(lnum, line .' parent:'. parent)
            endif
        endif
        exec lnum .'s/^\s*\zs\C\%(x\s\+\%('. g:tlib#date#date_rx .'\s\+\)\?\)\?/x '. donedate .' /'
    endfor
    exec line('.') + a:count
endf


function! s:GetParentId(lnum0) abort "{{{3
    let indent0 = indent(a:lnum0)
    let filename = expand('%:p')
    for lnum in range(a:lnum0 - 1, 1, -1)
        let indent = indent(lnum)
        if indent < indent0
            let line = getline(lnum)
            let task = ttodo#ParseTask(line, filename)
            if !has_key(task, 'id')
                exec lnum
                call ttodo#ftplugin#AddId(0)
                let task = ttodo#ParseTask(getline(lnum), filename)
            endif
            return task.id
        endif
    endfor
    return ''
endf


function! ttodo#ftplugin#MarkDue(unit, count) abort "{{{3
    if s:IsDone(getline('.'))
        echohl WarningMsg
        throw 'Ttodo: Cannot change finshed task'
        echohl NONE
    else
        if type(a:count) == 0
            let n = a:count
        elseif type(a:count) == 1
            call inputsave()
            let counts = input(a:count)
            call inputrestore()
            if empty(counts)
                return
            else
                let n = str2nr(counts)
            endif
        else
            throw 'ttodo#ftplugin#MarkDue: count must be a number or a string'
        endif
        let today = strftime(g:tlib#date#date_format)
        let due = tlib#date#Shift(today, n . a:unit)
        call s:MarkDueDate(due)
    endif
endf


function! s:MarkDueDate(date) abort "{{{3
    call s:SetTag('due', g:tlib#date#date_rx, a:date)
    " exec 's/\C\%(\s\+due:'. g:tlib#date#date_rx .'\|$\)/ due:'. a:date .'/'
endf


function! s:SetTag(name, rx, value) abort "{{{3
    exec 's/\C\%(\s\+'. a:name .':'. escape(a:rx, '/') .'\|$\)/ '. a:name .':'. escape(a:value, '/') .'/'
endf


function! ttodo#ftplugin#SetPriority(count) abort "{{{3
    " TLogVAR a:count
    if s:IsDone(getline('.'))
        echohl WarningMsg
        throw 'Ttodo: Cannot change finshed task'
        echohl NONE
    else
        call inputsave()
        let category = input('New task category [A-Z]: ')
        call inputrestore()
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
    let cmd = printf('call call(%s, %s)', string(a:fn), string(a:000))
    Tlibtrace 'ttodo', cmd
    let world = tlib#qfl#RunCmdOnSelected(a:world, a:selected, cmd)
    return world
endf


function! ttodo#ftplugin#AddId(count) abort "{{{3
    let filename = expand('%:p')
    let fqfl = ttodo#GetCachedFileTasks({}, filename, {})
    for lnum in range(line('.'), line('.') + a:count)
        let line = getline(lnum)
        let task = ttodo#ParseTask(line, filename)
        if !has_key(task, 'id')
            let qfe = get(filter(copy(fqfl), 'v:val.lnum == lnum'), 0, {})
            let tline = empty(qfe) ? line : qfe.text
            let id = tlib#hash#Adler32(tline)
            let line .= ' id:'. id
            call setline(lnum, line)
        endif
    endfor
endf

