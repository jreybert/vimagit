" ======= system wrappers =======
" Recent vim/neovim versions introduced a new handy function, systemlist:
"  > Same as |system()|, but returns a |List| with lines (parts of
"  > output separated by NL) with NULs transformed into NLs.
" In the same time, they introduced the capabilty of system to take a list as
" parameter
" These two new behavior are emulated if not present.
" Moreover, v:shell_error are detected and an exception is thrown if any.
" Matching functions, without exception raising, are available. The problem is
" that if an error is awaited, the exception thrown discards the return value.

" s:system: magit#sys#system internal, with explicit catch shell error
" parameter
" param[in] ...: command + optional args
" return: command output as a string
function! s:magit_system(...)
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

" s:systemlist: magit#sys#systemlist internal, with explicit catch shell
" error parameter
" param[in] catch: boolean, do we throw an exception in case of shell error
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
function! s:magit_systemlist(...)
	let dir = getcwd()
	try
		call magit#utils#chdir(magit#git#top_dir())
		" systemlist since v7.4.248
		if exists('*systemlist')
			return call('systemlist', a:000)
		else
			return split(call('s:magit_system', a:000), '\n')
		endif
	finally
		call magit#utils#chdir(dir)
	endtry
endfunction

" magit#sys#system: wrapper for system, which only takes String as input in vim,
" although it can take String or List input in neovim.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args
" return: command output as a string
" throw 'shell_error' in case of shell error
function! magit#sys#system(...)
	let ret = call('s:magit_system', a:000)
	if ( v:shell_error != 0 )
		let b:magit_shell_error = string(ret)
		let b:magit_shell_cmd = string(a:000)
		throw 'shell_error'
	endif
	return ret
endfunction

" magit#sys#systemlist: wrapper for systemlist, which only exists in neovim for
" the moment.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
" throw 'shell_error' in case of shell error
function! magit#sys#systemlist(...)
	let ret = call('s:magit_systemlist', a:000)
	if ( v:shell_error != 0 )
		let b:magit_shell_error = string(ret)
		let b:magit_shell_cmd = string(a:000)
		throw 'shell_error'
	endif
	return ret
endfunction

" magit#sys#system_noraise: magit#sys#system alias, without error
" exception
" param[in] ...: command + optional args
" return: command output as a string
function! magit#sys#system_noraise(...)
	return call('s:magit_system', a:000)
endfunction

" magit#sys#systemlist_noraise: magit#sys#systemlist alias, without error
" exception
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
function! magit#sys#systemlist_noraise(...)
	return call('s:magit_systemlist', a:000)
endfunction

function! magit#sys#print_shell_error()
	echohl WarningMsg
	echom "Shell command error"
	echom "Cmd: " . b:magit_shell_cmd
	echom "Error msg: " . b:magit_shell_error
	echohl None
endfunction
