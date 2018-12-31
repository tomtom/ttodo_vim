" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2018-12-31
" @Revision:    4

if g:loaded_tcomment < 400
    call tcomment#DefineType('ttodo', 'x '. strftime(g:tlib#date#date_format) .' %s')
else
    call tcomment#type#Define('ttodo', 'h:1 %s')
endif

