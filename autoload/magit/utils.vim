
" magit#utils#ls_all: list all files (including hidden ones) in a given path
" return : list of filenames
function! magit#utils#ls_all(path)
	return split(globpath(a:path, '.[^.]*', 1) . "\n" .
				\ globpath(a:path, '*', 1), '\n')
endfunction

let s:submodule_list = []
" magit#utils#refresh_submodule_list: this function refresh the List s:submodule_list
" magit#utils#is_submodule() is using s:submodule_list
function! magit#utils#refresh_submodule_list()
	let s:submodule_list = magit#git#submodule_list()
endfunction

" magit#utils#is_submodule search if dirname is in s:submodule_list 
" param[in] dirname: must end with /
" INFO: must be called from top work tree
function! magit#utils#is_submodule(dirname)
	return ( index(s:submodule_list, a:dirname) != -1 )
endfunction

" magit#utils#chdir will change the directory respecting
" local/tab-local/global directory settings.
function! magit#utils#chdir(dir)
  " This is a dirty hack to fix tcd breakages on neovim.
  " Future work should be based on nvim API.
  if exists(':tcd')
    let chdir = haslocaldir() ? 'lcd' : haslocaldir(-1, 0) ? 'tcd' : 'cd'
  else
    let chdir = exists('*haslocaldir') && haslocaldir() ? 'lcd' : 'cd'
  endif
  execute chdir fnameescape(a:dir)
endfunction

" magit#utils#clear_undo: this function clear local undo history.
" vimagit wants to clear undo history after each changes in vimagit buffer by
" vimagit backend.
" Use this function with caution: to be effective, the undo must be ack'ed
" with a change. The hack is the line
" exe "normal a \<BS>\<Esc>"
" We move on first line to make this trick where it should be no folding
function! magit#utils#clear_undo()
	let old_undolevels = &l:undolevels
	let cur_pos = line('.')
	setlocal undolevels=-1
	call cursor(1, 0)
	exe "normal a \<BS>\<Esc>"
	call cursor(cur_pos, 0)
	let &l:undolevels = old_undolevels
	unlet old_undolevels
endfunction

" magit#utils#underline: helper function to underline a string
" param[in] title: string to underline
" return a string composed of strlen(title) '='
function! magit#utils#underline(title)
	return substitute(a:title, ".", "=", "g")
endfunction

" magit#utils#strip: helper function to strip a string
" WARNING: it only works with monoline string
" param[in] string: string to strip
" return: stripped string
function! magit#utils#strip(string)
	return substitute(a:string, '^\s*\(.\{-}\)\s*\n\=$', '\1', '')
endfunction

" magit#utils#strip_array: helper function to strip an array (remove empty rows
" on both sides)
" param[in] array: array to strop
" return: stripped array
function! magit#utils#strip_array(array)
	let array_len = len(a:array)
	let start = 0
	while ( start < array_len && a:array[start] == '' )
		let start += 1
	endwhile
	let end = array_len - 1
	while ( end >= 0 && a:array[end] == '' )
		let end -= 1
	endwhile
	return a:array[ start : end ]
endfunction

" magit#utils#join_list: helper function to concatente a list of strings with newlines
" param[in] list: List to concat
" return: concatenated list
function! magit#utils#join_list(list)
	return join(a:list, "\n") . "\n"
endfunction

" magit#utils#add_quotes: helper function to protect filename with quotes
" return quoted filename
function! magit#utils#add_quotes(filename)
	return '"' . a:filename . '"'
endfunction

" magit#utils#remove_quotes: helper function to remove quotes aroudn filename
" return unquoted filename
function! magit#utils#remove_quotes(filename)
	let ret=matchlist(a:filename, '"\([^"]*\)"')
	if ( empty(ret) )
		throw 'no quotes found: ' . a:filename
	endif
	return ret[1]
endfunction

" magit#utils#fatten: flat a nested list. it return a one dimensional list with
" primary elements
" https://gist.github.com/dahu/3322468
" param[in] list: a List, can be nested or not
" return: one dimensional list
function! magit#utils#flatten(list)
	let val = []
	for elem in a:list
		if type(elem) == type([])
			call extend(val, magit#utils#flatten(elem))
		else
			call extend(val, [elem])
		endif
		unlet elem
	endfor
	return val
endfunction

" magit#utils#append_file: helper function to append to a file
" Version working with file *possibly* containing trailing newline
" param[in] file: filename to append
" param[in] lines: List of lines to append
function! magit#utils#append_file(file, lines)
	let fcontents=[]
	if ( filereadable(a:file) )
		let fcontents=readfile(a:file, 'b')
	endif
	if !empty(fcontents) && empty(fcontents[-1])
		call remove(fcontents, -1)
	endif
	call writefile(fcontents+a:lines, a:file, 'b')
endfunction

" s:bufnr: local variable to store current magit buffer id
let s:bufnr = 0
" magit#utils#setbufnr: function to set current magit buffer id
" param[in] bufnr: current magit buffer id
function! magit#utils#setbufnr(bufnr)
	let s:bufnr = a:bufnr
endfunction

" magit#utils#bufnr: function to get current magit buffer id
" return: current magit buffer id
function! magit#utils#bufnr()
	return s:bufnr
endfunction

" magit#utils#search_buffer_in_windows: search if a buffer is displayed in one
" of opened windows
" NOTE: windo command modify winnr('#'), if you want to use it, save it before
" calling this function
" param[in] filename: filename to search
" return: window id, 0 if not found
function! magit#utils#search_buffer_in_windows(filename)
	let cur_win = winnr()
	let last_win = winnr('#')
	let files={}
	windo if ( !empty(@%) ) | let files[@%] = winnr() | endif
	execute last_win."wincmd w"
	execute cur_win."wincmd w"
	return ( has_key(files, buffer_name(a:filename)) ) ?
				\files[buffer_name(a:filename)] : 0
endfunction

function! magit#utils#start_profile(...)
	let prof_file = ( a:0 == 1 ) ? a:1 : "/tmp/vimagit.log"
	profdel *
	execute "profile start " . prof_file . " | profile pause"
	profile file *
	profile func *
	profile continue
endfunction
