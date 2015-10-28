if exists("b:current_syntax")
  finish
endif

execute 'source ' . resolve(expand('<sfile>:p:h')) . '/../common/magit_common.vim'

syn case match
syn sync minlines=50

syn include @diff syntax/diff.vim

execute 'syn match titleEntry "' . g:magit_section_re . '" contains=titleSign'
if has("conceal")
	syn match titleSign contained "\%(&@\|@&\)" conceal
else
	syn match titleSign contained "\%(&@\|@&\)"
endif
hi def link titleEntry String
hi def link titleSign  Ignore

execute 'syn match stashEntry "' . g:magit_stash_re . '"'
hi def link stashEntry String

execute 'syn match fileEntry "' . g:magit_file_re . '"'
hi def link fileEntry String

execute 'syn region gitTitle start=/^$\n' . g:magit_section_re . '/ end=/^$/ contains=titleEntry'

execute 'syn region gitStash start=/' . g:magit_stash_re . '/ end=/\%(' .
 \ g:magit_stash_re . '\)\@=/ contains=stashEntry fold'

execute 'syn region gitFile start=/' . g:magit_file_re . '/ end=/\%(' .
			\ g:magit_end_diff_re . '\)\@=/ contains=gitHunk,fileEntry fold'

execute 'syn region gitHunk start=/' .
 \ g:magit_hunk_re . '/ end=/\%(' . g:magit_end_diff_re . '\|' . g:magit_hunk_re 
 \ '\)\@=/ contains=@diff fold'

let b:current_syntax = "magit"
