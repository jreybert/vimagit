" magit#git#get_status: this function returns the git status output formated
" into a List of Dict as
" [ {staged', 'unstaged', 'filename'}, ... ]
function! magit#git#get_status()
	let file_list = []

	" systemlist v7.4.248 problem again
	" we can't use git status -z here, because system doesn't make the
	" difference between NUL and NL. -status z terminate entries with NUL,
	" instead of NF
	let status_list=magit#utils#systemlist("git status --porcelain")
	for file_status_line in status_list
		let line_match = matchlist(file_status_line, '\(.\)\(.\) \%(.\{-\} -> \)\?"\?\(.\{-\}\)"\?$')
		let filename = line_match[3]
		call add(file_list, { 'staged': line_match[1], 'unstaged': line_match[2], 'filename': filename })
	endfor
	return file_list
endfunction

