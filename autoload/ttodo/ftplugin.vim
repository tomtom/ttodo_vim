" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-13
" @Revision:    148


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


" function! ttodo#ftplugin#WithVikitasks(fn, ...) abort "{{{3
"     if g:ttodo#use_vikitasks
"         Tlibtrace 'ttodo', a:fn, a:000
"         let ftdef = vikitasks#ft#todotxt#GetInstance()
"         let args = map(copy(a:000), 'type(v:val) == 1 && v:val ==# "{ftdef}" ? ftdef : v:val')
"         " Tlibtrace 'ttodo', args " DBG
"         return call(a:fn, args)
"     else
"         throw 'Ttodo: the vikitasks plugin is required to complete this action'
"     endif
" endf


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
            let line .= ' archive:'. date
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
    let task = ttodo#ParseTask(line)
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


function! ttodo#ftplugin#New(move, copytags, mode) abort "{{{3
    " TLogVAR a:move, a:copytags
    if a:mode == 'i'
        let o = "\<c-m>"
    else
        let o = "o"
    endif
    if indent('.') > 0 && empty(a:move)
        return o
    elseif a:move == '>'
        return o ."\<c-t>"
    else
        let new = strftime(g:tlib#date#date_format)
        let task = ttodo#ParseTask(getline('.'))
        if a:copytags
            if !empty(task.lists)
                let new .= ' '. join(map(copy(task.lists), '"@".v:val'))
            endif
            if !empty(task.tags)
                let new .= ' '. join(map(copy(task.tags), '"+".v:val'))
            endif
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
    " call ttodo#ftplugin#WithVikitasks("vikitasks#ItemMarkDone", a:count, "{ftdef}")
    let donedate = strftime(g:vikitasks#date_fmt)
    for lnum in range(line('.'), line('.') + a:count)
        let line = getline(lnum)
        if !s:IsDone(line)
            let task = ttodo#ParseTask(line)
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
                continue
            endif
        endif
        exec lnum .'s/^\s*\zs\C\%(x\s\+\%('. g:tlib#date#date_rx .'\s\+\)\?\)\?/x '. donedate .' /'
    endfor
endf


function! ttodo#ftplugin#MarkDue(unit, count) abort "{{{3
    if s:IsDone(getline('.'))
        throw 'ttodo#ftplugin#SetCategory: Cannot change finshed task'
    endif
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
    " exec 's/\%(\sdue:'. g:tlib#date#date_rx .'\|$\)/ due:'. 
    let today = strftime(g:tlib#date#date_format)
    let due = tlib#date#Shift(today, n . a:unit)
    call s:MarkDueDate(due)
    " let count1 = a:count == 0 ? 1 : a:count
    " if a:unit ==# 'd'
    "     call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInDays", 0, count1, "{ftdef}")
    " elseif a:unit ==# 'w'
    "     call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInWeeks", 0, count1, "{ftdef}")
    " elseif a:unit ==# 'm'
    "     call ttodo#ftplugin#WithVikitasks("vikitasks#ItemsMarkDueInMonths", 0, count1, "{ftdef}")
    " else
    "     throw 'ttodo#ftplugin#MarkDue: Unsupported unit: '. a:unit
    " endif
endf


function! s:MarkDueDate(date) abort "{{{3
    exec 's/\C\%(\s\+due:'. g:tlib#date#date_rx .'\|$\)/ due:'. a:date .'/'
endf


function! ttodo#ftplugin#SetCategory(count) abort "{{{3
    " TLogVAR a:count
    " call ttodo#ftplugin#WithVikitasks("vikitasks#ItemChangeCategory", a:count, "", "{ftdef}")
    if s:IsDone(getline('.'))
        throw 'ttodo#ftplugin#SetCategory: Cannot change finshed task'
    endif
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
endf


function! ttodo#ftplugin#Agent(world, selected, fn, ...) abort "{{{3
    " TLogVAR a:fn, a:000
    let cmd = printf('call call(%s, %s)', string(a:fn), string(a:000))
    Tlibtrace 'ttodo', cmd
    let world = tlib#qfl#RunCmdOnSelected(a:world, a:selected, cmd)
    return world
endf

