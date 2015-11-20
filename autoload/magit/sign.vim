" Got lot of stuf from vim-gitgutter
" https://github.com/airblade/vim-gitgutter

" Vim doesn't namespace sign ids so every plugin shares the same
" namespace.  Sign ids are simply integers so to avoid clashes with other
" signs we guess at a clear run.
"
" Note also we currently never reset s:next_sign_id.
let s:first_sign_id = 42000
let s:next_sign_id  = s:first_sign_id
let s:dummy_sign_id = s:first_sign_id - 1
" Remove-all-signs optimisation requires Vim 7.3.596+.
let s:supports_star = v:version > 703 || (v:version == 703 && has("patch596"))

function! magit#sign#remove_all(...)
	if ( a:0 == 1 )
		let pattern = a:1
	else
		let pattern = '^Magit.*'
	endif
	let signs = magit#sign#find_signs(pattern, 1, line('$'))
	call magit#sign#remove_signs(signs)
endfunction

" magit#sign#remove_signs: unplace a list of signs
" param[in] sign_ids: list of signs dict
function! magit#sign#remove_signs(sign_ids)
    let bufnr = magit#utils#bufnr()
    for sign in values(a:sign_ids)
        execute "sign unplace" sign.id
    endfor
endfunction

function! magit#sign#add_sign(line, type, bufnr)
	let id = <SID>get_next_sign_id()
	execute ":sign place " . id .
		\ " line=" . a:line . " name=" . s:magit_mark_signs[a:type] .
		\ " buffer=" . a:bufnr
	return id
endfunction

function! magit#sign#remove_sign(id)
	execute ":sign unplace " . a:id
endfunction

" s:get_next_sign_id: helper function to increment sign ids
function! s:get_next_sign_id()
	let next_id = s:next_sign_id
	let s:next_sign_id += 1
	return next_id
endfunction

" magit#sign#find_signs: this function returns signs matching a pattern in a
" range of lines
" param[in] pattern: regex pattern to match
" param[in] startline,endline: range of lines
" FIXME: find since which version "sign place" is sorted
function! magit#sign#find_signs(pattern, startline, endline)
	let bufnr = magit#utils#bufnr()
	" <line_number (string)>: {'id': <id (number)>, 'name': <name (string)>}
	let found_signs = {}

	redir => signs
	silent execute "sign place buffer=" . bufnr
	redir END

	for sign_line in filter(split(signs, '\n'), 'v:val =~# "="')
		" Typical sign line:  line=88 id=1234 name=GitGutterLineAdded
		" We assume splitting is faster than a regexp.
		let components  = split(sign_line)
		let name        = split(components[2], '=')[1]
		let line_number = str2nr(split(components[0], '=')[1])
		if ( name =~# a:pattern &&
			\ line_number >= a:startline &&
			\ line_number <= a:endline )
			let id = str2nr(split(components[1], '=')[1])
			let found_signs[line_number] = {'id': id, 'name': name}
		endif
	endfor
	return found_signs
endfunction

" magit#sign#find_stage_signs: helper function to get marked lines for stage
" param[in] startline,endline: range of lines
" return Dict of marked lines
function! magit#sign#find_stage_signs(startline, endline)
	return magit#sign#find_signs(s:magit_mark_signs.M, a:startline, a:endline)
endfunction

" s:magit_mark_sign: string of the sign for lines to be staged
let s:magit_mark_signs = {'M': 'MagitTBS', 'S': 'MagitBS', 'E': 'MagitBE'}

" magit#sign#init: initializer function for signs
function! magit#sign#init()
	execute "sign define " . s:magit_mark_signs.M . " text=S> linehl=Visual"
	execute "sign define " . s:magit_mark_signs.S
	execute "sign define " . s:magit_mark_signs.E
endfunction

" magit#sign#toggle_signs: toggle marks for range of lines
" marked lines are unmarked, non marked are marked
" param[in] type; type of sign to toggle (see s:magit_mark_signs)
" param[in] startline,endline: range of lines
function! magit#sign#toggle_signs(type, startline, endline)
	let bufnr = magit#utils#bufnr()
	let current_signs = magit#sign#find_signs(s:magit_mark_signs[a:type], a:startline, a:endline)
	let line = a:startline
	while ( line <= a:endline )
		if ( has_key(current_signs, line) == 0 )
			call magit#sign#add_sign(line, a:type, bufnr)
		else
			call magit#sign#remove_sign(current_signs[line].id)
		endif
		let line += 1
	endwhile
endfunction
