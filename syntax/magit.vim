" Vim syntax file
" Language:     magit buffer syntax
" Maintainer:	Jerome Reybert <jreybert@gmail.com>

if exists("b:current_syntax")
  finish
endif

execute 'source ' . resolve(expand('<sfile>:p:h')) . '/../common/magit_common.vim'

syn case match
syn sync minlines=50

syn include @diff syntax/diff.vim

execute 'syn match titleEntry "' . g:section_re . '" contains=titleSign'
if has("conceal")
	syn match titleSign contained "\%(&@\|@&\)" conceal
else
	syn match titleSign contained "\%(&@\|@&\)"
endif
hi def link titleEntry String
hi def link titleSign  Ignore

execute 'syn match stashEntry "' . g:stash_re . '"'
hi def link stashEntry String

execute 'syn match fileEntry "' . g:file_re . '"'
hi def link fileEntry String

execute 'syn region gitTitle start=/^$\n' . g:section_re . '/ end=/^$/ contains=titleEntry'

execute 'syn region gitStash start=/' . g:stash_re . '/ end=/^\%(' .
 \ g:stash_re . '\)\@=/ contains=gitDiff,stashEntry fold'

execute 'syn region gitFile start=/' . g:file_re . '/ end=/^\%(' .
 \ g:file_re . '\|' . g:section_re '\)\@=/ contains=gitDiff,fileEntry fold'

execute 'syn region gitDiff start=/' . g:diff_re . '/ end=/^\%(' .
 \ g:diff_re . '\|' . g:section_re. '\|' . g:stash_re . '\|' . g:file_re .
 \ '\)\@=/ contains=@diff,gitHunk fold'

execute 'syn region gitHunk start=/' .
 \ g:hunk_re . '/ end=/^\%(' .
 \ g:diff_re . '\|' . g:hunk_re . '\|' . g:section_re. '\|' . g:stash_re . '\|' . g:file_re .
 \ '\)\@=/ contains=@diff fold contained'

let b:current_syntax = "magit"
