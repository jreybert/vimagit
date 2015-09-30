" Section names
" These are used to beautify the magit buffer and to help for some block
" selection
let g:magit_sections = {
 \ 'staged':         'Staged changes',
 \ 'unstaged':       'Unstaged changes',
 \ 'commit_start':   'Commit message',
 \ 'commit_end':     'Commit message end',
 \ 'stash':          'Stash list'
 \ }

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
let g:file_re .= 'unknown status\): \(.*\)$'

let g:section_re  = '^\('
for section_name in values(g:magit_sections)
	let g:section_re .= section_name . '\|'
endfor
let g:section_re .= 'unknown section\)$'
let g:diff_re  = '^diff --git'
let g:stash_re = '^stash@{\d\+}:'
let g:hunk_re  = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
let g:bin_re   = '^Binary files '
let g:title_re = '^&@\%([^&@]\|\s\)\+@&$'
let g:eof_re   = '\%$'


