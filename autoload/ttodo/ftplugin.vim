" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-09
" @Revision:    67


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
    " If false, invoking the <cr> or <c-cr> map with a count will make 
    " ttodo add a new task at the end of the file. Otherwise the task 
    " will be added below the current line.
    " If true, the meaning of the count is reversed.
    let g:ttodo#ftplugin#add_at_eof = 0   "{{{2
endif


function! ttodo#ftplugin#WithVikitasks(fn, ...) abort "{{{3
    Tlibtrace 'ttodo', a:fn, a:000
    let ftdef = vikitasks#ft#todotxt#GetInstance()
    let args = map(copy(a:000), 'type(v:val) == 1 && v:val ==# "{ftdef}" ? ftdef : v:val')
    " Tlibtrace 'ttodo', args " DBG
    return call(a:fn, args)
endf


function! ttodo#ftplugin#Archive(filename) abort "{{{3
    if g:ttodo#use_vikitasks
        let arc = fnamemodify(a:filename, ':p:h') .'/done.txt'
        if filereadable(arc) && !filewritable(arc)
            throw 'TTodo: Cannot write: '. arc
        endif
        if !filewritable(a:filename)
            throw 'TTodo: Cannot write: '. a:filename
        endif
        let ftdef = vikitasks#ft#todotxt#GetInstance()
        let done = []
        let undone = []
        for line in readfile(a:filename)
            if line =~# '^x\s'
                let line = ftdef.ArchiveItem(line)
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


function! ttodo#ftplugin#New(move, copytags) abort "{{{3
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
    exec 'norm!' a:move . 'o'. new .' '
endf

