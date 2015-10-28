" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-10-28.

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif


syntax match TtodoPri /(\u)/
syntax match TtodoList /@\S\+/
syntax match TtodoKeyword /+\S\+/
syntax match TtodoTag /\<\a\+:\S\+/
syntax match TtodoDate /\<\d\{4}-\d\d-\d\d\>/
syntax match TtodoTime /\<\d\d:\d\d\>/
" syntax match TtodoDone /\<x \d\{4}-\d\d-\d\d\s.*$/
syntax match TtodoDone /^x\s.*$/
syntax cluster TtodoTask contains=TtodoPri,TtodoList,TtodoKeyword,TtodoTag,TtodoDate,TtodoTime,TtodoDone

hi def link TtodoPri Special
hi def link TtodoList Identifier
hi def link TtodoKeyword Constant
hi def link TtodoTag Type
hi def link TtodoDate Statement
hi def link TtodoTime Statement
hi def link TtodoDone Comment

let b:current_syntax = 'ttodo'
