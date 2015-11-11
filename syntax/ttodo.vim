" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     https://github.com/tomtom
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Last Change: 2015-11-11.

if version < 600
    syntax clear
elseif exists("b:current_syntax")
    finish
endif

if has('conceal') && &enc == 'utf-8'
    let s:sym_cluster = []
    for [s:name, s:chars, s:cchar] in [
                \ ['Dash', '--', '—'],
                \ ['Unequal', '!=', '≠'],
                \ ['Identity', '==', '≡'],
                \ ['Approx', '~~', '≈'],
                \ ['ArrowLR', '<-\+>', '↔'],
                \ ['ArrowL', '<-\+', '←'],
                \ ['ArrowR', '-\+>', '→'],
                \ ['ARROWLR', '<=\+>', '⇔'],
                \ ['ARROWL', '<=\+', '⇐'],
                \ ['ARROWR', '=\+>', '⇒'],
                \ ['ArrowTildeLR', '<~\+>', '↭'],
                \ ['ArrowTildeL', '<~\+', '↜'],
                \ ['ArrowTildeR', '~\+>', '↝'],
                \ ['Ellipsis', '...', '…'],
                \ ]
        
        exec 'syn match ttodoSymbol'. s:name .' /\V'. s:chars .'/ conceal cchar='. s:cchar
    endfor
    unlet! s:sym_cluster s:name s:chars s:cchar
endif

syntax match TtodoPri /([D-Z])/
syntax match TtodoPriA /(A)/
syntax match TtodoPriB /(B)/
syntax match TtodoPriC /(C)/
syntax match TtodoList /@\S\+/
syntax match TtodoKeyword /+\S\+/
syntax match TtodoTag /\<\a\+:\S\+/
syntax match TtodoDate /\<\d\{4}-\d\d-\d\d\>/
syntax match TtodoTime /\<\d\d:\d\d\>/
" syntax match TtodoDone /\<x \d\{4}-\d\d-\d\d\s.*$/
syntax match TtodoDone /^\s*x\s.*$/
syntax cluster TtodoTask contains=TtodoPri,TtodoPriA,TtodoPriB,TtodoPriC,TtodoList,TtodoKeyword,TtodoTag,TtodoDate,TtodoTime,TtodoDone

hi def link TtodoPri Special
hi def TtodoPriA term=bold,underline cterm=bold gui=bold guifg=Black ctermfg=Black ctermbg=Red guibg=Red
hi def TtodoPriB term=bold,underline cterm=bold gui=bold guifg=Black ctermfg=Black ctermbg=Brown guibg=Orange
hi def TtodoPriC term=bold,underline cterm=bold gui=bold guifg=Black ctermfg=Black ctermbg=Yellow guibg=Yellow

hi def link TtodoList Identifier
hi def link TtodoKeyword Constant
hi def link TtodoTag Type
hi def link TtodoDate Statement
hi def link TtodoTime Statement
hi def link TtodoDone Comment

let b:current_syntax = 'ttodo'
