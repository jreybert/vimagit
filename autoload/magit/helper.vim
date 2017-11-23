
" magit#helper#get_filename: helper function to get the current filename, according to
" cursor position
" return: filename
function! magit#helper#get_filename()
	return substitute(getline(search(g:magit_file_re, "cbnW")), g:magit_file_re, '\2', '')
endfunction

" magit#helper#get_hunkheader_line_nb: helper function to get the current hunk
" header line number, according to cursor position
" return: hunk header line number
function! magit#helper#get_hunkheader_line_nb()
	return search(g:magit_hunk_re, "cbnW")
endfunction

" magit#utils#get_section: helper function to get the current section, according to
" cursor position
" return: section id, empty string if no section found
function! magit#helper#get_section()
	let section_line=getline(search(g:magit_section_re, "bnW"))
	for [section_name, section_str] in items(g:magit_sections)
		if ( section_line == section_str )
			return section_name
		endif
	endfor
	return ''
endfunction


