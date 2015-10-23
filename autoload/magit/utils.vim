" s:magit_top_dir: top directory of git tree
" it is evaluated only once
" FIXME: it won't work when playing with multiple git directories wihtin one
" vim session
let s:magit_top_dir=''
" magit#utils#top_dir: return the absolute path of current git worktree
" return top directory
function! magit#utils#top_dir()
	if ( s:magit_top_dir == '' )
		let s:magit_top_dir=magit#utils#strip(
			\ system("git rev-parse --show-toplevel")) . "/"
		if ( v:shell_error != 0 )
			echoerr "Git error: " . s:magit_top_dir
		endif
	endif
	return s:magit_top_dir
endfunction

" s:magit_git_dir: git directory
" it is evaluated only once
" FIXME: it won't work when playing with multiple git directories wihtin one
" vim session
let s:magit_git_dir=''
" magit#utils#git_dir: return the absolute path of current git worktree
" return git directory
function! magit#utils#git_dir()
	if ( s:magit_git_dir == '' )
		let s:magit_git_dir=magit#utils#strip(system("git rev-parse --git-dir")) . "/"
		if ( v:shell_error != 0 )
			echoerr "Git error: " . s:magit_git_dir
		endif
	endif
	return s:magit_git_dir
endfunction

" s:magit#utils#is_binary: check if file is a binary file
" param[in] filename: the file path. it must quoted if it contains spaces
function! magit#utils#is_binary(filename)
	return ( match(system("file --mime " . a:filename ),
				\ a:filename . ".*charset=binary") != -1 )
endfunction

let s:submodule_list = []
" magit#utils#refresh_submodule_list: this function refresh the List s:submodule_list
" magit#utils#is_submodule() is using s:submodule_list
function! magit#utils#refresh_submodule_list()
	let s:submodule_list = map(split(system("git submodule status"), "\n"), 'split(v:val)[1]')
endfunction

" magit#utils#is_submodule search if dirname is in s:submodule_list 
" param[in] dirname: must end with /
" INFO: must be called from top work tree
function! magit#utils#is_submodule(dirname)
	return ( index(s:submodule_list, a:dirname) != -1 )
endfunction

" s:magit_cd_cmd: plugin variable to choose lcd/cd command, 'lcd' if exists,
" 'cd' otherwise
let s:magit_cd_cmd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '
" magit#utils#lcd: helper function to lcd. use cd if lcd doesn't exists
function! magit#utils#lcd(dir)
	execute s:magit_cd_cmd . a:dir
endfunction

" magit#utils#system: wrapper for system, which only takes String as input in vim,
" although it can take String or List input in neovim.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args
" return: command output as a string
function! magit#utils#system(...)
	let dir = getcwd()
	try
		execute s:magit_cd_cmd . magit#utils#top_dir()
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
		execute s:magit_cd_cmd . dir
	endtry
endfunction

" magit#utils#systemlist: wrapper for systemlist, which only exists in neovim for
" the moment.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
function! magit#utils#systemlist(...)
	let dir = getcwd()
	try
		execute s:magit_cd_cmd . magit#utils#top_dir()
		" systemlist since v7.4.248
		if exists('*systemlist')
			return call('systemlist', a:000)
		else
			return split(call('magit#utils#system', a:000), '\n')
		endif
	finally
		execute s:magit_cd_cmd . dir
	endtry
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

" magit#utils#join_list: helper function to concatente a list of strings with newlines
" param[in] list: List to to concat
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
