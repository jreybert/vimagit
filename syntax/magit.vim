if exists("b:current_syntax")
  finish
endif

let s:vimagit_path = fnameescape(resolve(expand('<sfile>:p:h')))
execute 'source ' . s:vimagit_path . '/../common/magit_common.vim'

syn case match
syn sync minlines=50

syn include @diff syntax/diff.vim

execute 'syn match titleEntry "' . g:magit_section_re . '\n\%(.*\n\)\{-}=\+"'
hi def link titleEntry Comment

execute 'syn region commitMsg start=/' . g:magit_sections.commit . '/ end=/\%(' . g:magit_section_re . '\)\@=/ contains=titleEntry'
execute 'syn match commitMsgExceed "\%(=\+\n\+\_^.\{' . g:magit_commit_title_limit . '}\)\@<=.*$" contained containedin=commitMsg'
hi def link commitMsgExceed Comment

execute 'syn match stashEntry "' . g:magit_stash_re . '"'
hi def link stashEntry String

execute 'syn match fileEntry "' . g:magit_file_re . '"'
hi def link fileEntry String

execute 'syn region gitStash start=/' . g:magit_stash_re . '/ end=/\%(' .
 \ g:magit_stash_re . '\)\@=/ contains=stashEntry fold'

execute 'syn region gitFile start=/' . g:magit_file_re . '/ end=/\%(' .
			\ g:magit_end_diff_re . '\)\@=/ contains=gitHunk,fileEntry fold'

execute 'syn region gitHunk start=/' .
 \ g:magit_hunk_re . '/ end=/\%(' . g:magit_end_diff_re . '\|' . g:magit_hunk_re 
 \ '\)\@=/ contains=@diff fold'

execute 'syn match gitInfoRepo   "\%(' . g:magit_section_info.cur_repo . '\)\@<=.*$" oneline'
execute 'syn match gitInfoHead "\%(' . g:magit_section_info.cur_head . '\s*\)\@<=\S\+" oneline'
execute 'syn match gitInfoUpstream "\%(' . g:magit_section_info.cur_upstream . '\s*\)\@<=\S\+" oneline'
execute 'syn match gitInfoPush "\%(' . g:magit_section_info.cur_push . '\s*\)\@<=\S\+" oneline'
execute 'syn match gitCommitMode "\%(' . g:magit_section_info.commit_mode . '\)\@<=.*$" oneline'
"execute 'syn match gitInfoCommit "\%(' . g:magit_section_info.cur_commit . '\)\@<=.*$" contains=infoSha1 oneline'
"syntax match infoSha1 containedin=gitInfoCommit "\x\{7,}"

highlight default link gitInfoRepo Directory
highlight default link gitInfoHead Identifier
highlight default link gitInfoUpstream Identifier
highlight default link gitInfoPush Identifier
highlight default link gitCommitMode Special
highlight default link infoSha1 Identifier

let b:current_syntax = "magit"
