" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-29
" @Revision:    3


function! ttodo#ftplugin#WithVikitasks(fn, ...) abort "{{{3
    TLibTrace 'ttodo', a:fn, a:000
    let ftdef = vikitasks#ft#todotxt#GetInstance()
    let args = map(copy(a:000), 'type(v:val) == 1 && v:val ==# "{ftdef}" ? ftdef : v:val')
    " TLibTrace 'ttodo', args " DBG
    return call(a:fn, args)
endf

