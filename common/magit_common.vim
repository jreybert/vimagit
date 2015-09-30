let g:magit_git_status_code = {
 \ 'M': 'modified', 
 \ 'A': 'added',
 \ 'D': 'deleted',
 \ 'R': 'renamed',
 \ 'C': 'copied',
 \ 'U': 'updated but unmerged',
 \ '?': 'untracked',
 \ '!': 'ignored'
 \ }

" Regular expressions used to select blocks
let g:file_re  = '^\('
for status_code in values(g:magit_git_status_code)
	let g:file_re .= status_code . '\|'
endfor
let g:file_re .= status_code . 'unknown status\): \(.*\)$'
let g:diff_re  = '^diff --git'
let g:stash_re = '^stash@{\d\+}:'
let g:hunk_re  = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
let g:bin_re   = '^Binary files '
let g:title_re = '^&@\%([^&@]\|\s\)\+@&$'
let g:eof_re   = '\%$'


