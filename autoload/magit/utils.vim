
" magit#utils#ls_all: list all files (including hidden ones) in a given path
" return : list of filenames
function! magit#utils#ls_all(path) abort
	return split(globpath(a:path, '.[^.]*', 1) . "\n" .
				\ globpath(a:path, '*', 1), '\n')
endfunction

let s:submodule_list = []
" magit#utils#refresh_submodule_list: this function refresh the List s:submodule_list
" magit#utils#is_submodule() is using s:submodule_list
function! magit#utils#refresh_submodule_list() abort
	let s:submodule_list = map(split(magit#git#submodule_status(), "\n"), 'split(v:val)[1]')
endfunction

" magit#utils#is_submodule search if dirname is in s:submodule_list 
" param[in] dirname: must end with /
" INFO: must be called from top work tree
function! magit#utils#is_submodule(dirname) abort
	return ( index(s:submodule_list, a:dirname) != -1 )
endfunction

" magit#utils#chdir will change the directory respecting
" local/tab-local/global directory settings.
function! magit#utils#chdir(dir) abort
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
function! magit#utils#clear_undo() abort
	let old_undolevels = &l:undolevels
	let cur_pos = line('.')
	setlocal undolevels=-1
	call cursor(1, 0)
	exe "normal a \<BS>\<Esc>"
	call cursor(cur_pos, 0)
	let &l:undolevels = old_undolevels
	unlet old_undolevels
endfunction

" magit#utils#system: wrapper for system, which only takes String as input in vim,
" although it can take String or List input in neovim.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args
" return: command output as a string
function! magit#utils#system(...) abort
	let dir = getcwd()
	try
		call magit#utils#chdir(magit#git#top_dir())
		" List as system() input is since v7.4.247, it is safe to check
		" systemlist, which is sine v7.4.248
		if exists('*systemlist')
			return call('system', a:000)
		else
			if ( a:0 == 2 )
				if ( type(a:2) == type([]) )
					" ouch, this one is tough: input is very very sensitive, join
					" MUST BE done with "\n", not '\n' !!
					let arg=join(a:2, "\n")
				else
					let arg=a:2
				endif
				return system(a:1, arg)
			else
				return system(a:1)
			endif
		endif
	finally
		call magit#utils#chdir(dir)
	endtry
endfunction

" magit#utils#systemlist: wrapper for systemlist, which only exists in neovim for
" the moment.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
function! magit#utils#systemlist(...) abort
	let dir = getcwd()
	try
		call magit#utils#chdir(magit#git#top_dir())
		" systemlist since v7.4.248
		if exists('*systemlist')
			return call('systemlist', a:000)
		else
			return split(call('magit#utils#system', a:000), '\n')
		endif
	finally
		call magit#utils#chdir(dir)
	endtry
endfunction

" magit#utils#underline: helper function to underline a string
" param[in] title: string to underline
" return a string composed of strlen(title) '='
function! magit#utils#underline(title) abort
	return substitute(a:title, ".", "=", "g")
endfunction

" magit#utils#strip: helper function to strip a string
" WARNING: it only works with monoline string
" param[in] string: string to strip
" return: stripped string
function! magit#utils#strip(string) abort
	return substitute(a:string, '^\s*\(.\{-}\)\s*\n\=$', '\1', '')
endfunction

" magit#utils#strip_array: helper function to strip an array (remove empty rows
" on both sides)
" param[in] array: array to strop
" return: stripped array
function! magit#utils#strip_array(array) abort
	let array_len = len(a:array)
	let start = 0
	while ( start < array_len && a:array[start] ==# '' )
		let start += 1
	endwhile
	let end = array_len - 1
	while ( end >= 0 && a:array[end] ==# '' )
		let end -= 1
	endwhile
	return a:array[ start : end ]
endfunction

" magit#utils#join_list: helper function to concatente a list of strings with newlines
" param[in] list: List to concat
" return: concatenated list
function! magit#utils#join_list(list) abort
	return join(a:list, "\n") . "\n"
endfunction

" magit#utils#add_quotes: helper function to protect filename with quotes
" return quoted filename
function! magit#utils#add_quotes(filename) abort
	return '"' . a:filename . '"'
endfunction

" magit#utils#remove_quotes: helper function to remove quotes aroudn filename
" return unquoted filename
function! magit#utils#remove_quotes(filename) abort
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
function! magit#utils#flatten(list) abort
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
function! magit#utils#append_file(file, lines) abort
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
function! magit#utils#setbufnr(bufnr) abort
	let s:bufnr = a:bufnr
endfunction

" magit#utils#bufnr: function to get current magit buffer id
" return: current magit buffer id
function! magit#utils#bufnr() abort
	return s:bufnr
endfunction

" magit#utils#search_buffer_in_windows: search if a buffer is displayed in one
" of opened windows
" NOTE: windo command modify winnr('#'), if you want to use it, save it before
" calling this function
" param[in] filename: filename to search
" return: window id, 0 if not found
function! magit#utils#search_buffer_in_windows(filename) abort
	let cur_win = winnr()
	let last_win = winnr('#')
	let files={}
	windo if ( !empty(@%) ) | let files[@%] = winnr() | endif
	execute last_win."wincmd w"
	execute cur_win."wincmd w"
	return ( has_key(files, buffer_name(a:filename)) ) ?
				\files[buffer_name(a:filename)] : 0
endfunction

function! magit#utils#start_profile(...) abort
	let prof_file = ( a:0 == 1 ) ? a:1 : "/tmp/vimagit.log"
	execute "profile start " . prof_file . " | profile pause"
	profile! file */plugin/magit.vim
	profile! file */autoload/magit/*
	profile! file */common/magit_common.vim
	profile! file */syntax/magit.vim
	profile continue
endfunction
