scriptencoding utf-8

"if exists('g:loaded_magit') || !executable('git') || &cp
"  finish
"endif
"let g:loaded_magit = 1
let g:magit_unstaged_buffer_name = "magit-unstaged"

function! s:set(var, default)
	if !exists(a:var)
		if type(a:default)
			execute 'let' a:var '=' string(a:default)
		else
			execute 'let' a:var '=' a:default
		endif
	endif
endfunction

call s:set('g:magit_enabled',               1)

function! magit#get_unstaged()
	if ( @% != g:magit_unstaged_buffer_name )
		echoerr "Not in magit buffer " . g:magit_unstaged_buffer_name . " but in " . @%
		return
	endif
	silent! execute "normal! ggdG"
	silent! read !git diff
	silent! read !git ls-files --others --exclude-standard | while read -r i; do git diff --no-color -- /dev/null "$i"; done
endfunction

function! magit#show_magit(orientation)
	vnew 
	setlocal buftype=nofile bufhidden=delete noswapfile filetype=gitdiff foldmethod=syntax nowrapscan
	execute "file " . g:magit_unstaged_buffer_name
	nnoremap <buffer> <silent> F :call magit#stage_file()<cr>
	call magit#get_unstaged()
	execute "normal! gg"
endfunction

function! magit#search_block(start_pattern, end_pattern, last_line)
	let save_reg_a = @0
	let @0 = ""
	execute "normal! $"
	let v:errmsg = ""
	execute a:start_pattern . ',' . a:end_pattern . a:last_line . ' y'
	let ret = (v:errmsg != "")
	let selection = @0
	execute "normal! ^"
	let @0 = save_reg_a
	return [v:errmsg != "", selection]
endfunction

function! magit#select_file()
	let selection = ""
	let [ret, selection] = magit#search_block("?diff --git?", "/diff --git/", "-1")
	if (ret != 0)
		let [ret, selection] = magit#search_block("?diff --git?", "/\\%$/", "")
	endif
	return [ret, selection]
endfunction

function! magit#stage_file()
	let [ret, selection] = magit#select_file()
	if ( ret != 0 )
		echoerr "Not in a file region"
		return
	endif
	call system("git apply --cached -", selection)
	call magit#get_unstaged()
endfunction

command! Magit call magit#show_magit("v")
