if exists("b:current_syntax")
  finish
endif

execute 'source ' . resolve(expand('<sfile>:p:h')) . '/../common/magit_common.vim'

syn case match
syn sync minlines=50

syn include @diff syntax/diff.vim

execute 'syn match titleEntry "' . g:magit_section_re . '\n=\+"'
hi def link titleEntry Comment

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

execute 'syn region gitInfo start=/^' . g:magit_sections.info . '$/ end=/' .
 \ g:magit_section_re . '/'

execute 'syn region gitInfoRepo start=/^' . g:magit_section_info.cur_repo .
 \ ':\s*.*/hs=s+20 end=/$/ oneline'
highlight default link gitInfoRepo Directory
execute 'syn region gitInfoBranch start=/^' . g:magit_section_info.cur_branch .
 \ ':\s*.*/hs=s+20 end=/$/ oneline'
highlight default link gitInfoBranch Identifier
execute 'syn region gitCommitMode start=/^' . g:magit_section_info.commit_mode .
 \ ':\s*.*/hs=s+20 end=/$/ oneline'
highlight default link gitCommitMode Special

execute 'syn region gitInfoCommit start=/^' . g:magit_section_info.cur_commit .
 \ ':\s*\(.*\)/ end=/$/ contains=infoSha1 oneline'
syntax match infoSha1 containedin=gitInfoCommit "\x\{7}"
highlight default link infoSha1 Identifier


let b:current_syntax = "magit"
