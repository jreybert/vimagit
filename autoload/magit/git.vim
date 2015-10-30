let s:git_cmd="GIT_CONFIG=/dev/null GIT_CONFIG_NOSYSTEM=1 XDG_CONFIG_HOME=/ git"

" magit#git#get_status: this function returns the git status output formated
" into a List of Dict as
" [ {staged', 'unstaged', 'filename'}, ... ]
function! magit#git#get_status()
	let file_list = []

	" systemlist v7.4.248 problem again
	" we can't use git status -z here, because system doesn't make the
	" difference between NUL and NL. -status z terminate entries with NUL,
	" instead of NF
	let status_list=magit#utils#systemlist(s:git_cmd . " status --porcelain")
	for file_status_line in status_list
		let line_match = matchlist(file_status_line, '\(.\)\(.\) \%(.\{-\} -> \)\?"\?\(.\{-\}\)"\?$')
		let filename = line_match[3]
		call add(file_list, { 'staged': line_match[1], 'unstaged': line_match[2], 'filename': filename })
	endfor
	return file_list
endfunction

" s:magit_top_dir: top directory of git tree
" it is evaluated only once
" FIXME: it won't work when playing with multiple git directories wihtin one
" vim session
let s:magit_top_dir=''
" magit#git#top_dir: return the absolute path of current git worktree
" return top directory
function! magit#git#top_dir()
	if ( s:magit_top_dir == '' )
		let s:magit_top_dir=magit#utils#strip(
			\ system(s:git_cmd . " rev-parse --show-toplevel")) . "/"
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
" magit#git#git_dir: return the absolute path of current git worktree
" return git directory
function! magit#git#git_dir()
	if ( s:magit_git_dir == '' )
		let s:magit_git_dir=magit#utils#strip(system(s:git_cmd . " rev-parse --git-dir")) . "/"
		if ( v:shell_error != 0 )
			echoerr "Git error: " . s:magit_git_dir
		endif
	endif
	return s:magit_git_dir
endfunction

" magit#git#git_add: helper function to add a whole file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
function! magit#git#git_add(filename)
	let git_cmd=s:git_cmd . " add -- " . a:filename
	silent let git_result=magit#utils#system(git_cmd)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Git cmd: " . git_cmd
	endif
endfunction

" magit#git#git_reset: helper function to add a whole file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
function! magit#git#git_reset(filename)
	let git_cmd=s:git_cmd . " reset -- " . a:filename
	silent let git_result=magit#utils#system(git_cmd)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Git cmd: " . git_cmd
	endif
endfunction

" magit#git#git_apply: helper function to stage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git#git_apply(header, selection)
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	let git_cmd=s:git_cmd . " apply --recount --no-index --cached -"
	silent let git_result=magit#utils#system(git_cmd, selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Git cmd: " . git_cmd
		echoerr "Tried to aply this"
		echoerr string(selection)
	endif
endfunction

" magit#git#git_unapply: helper function to unstage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git#git_unapply(header, selection, mode)
	let cached_flag=''
	if ( a:mode == 'staged' )
		let cached_flag=' --cached '
	endif
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	silent let git_result=magit#utils#system(
		\ s:git_cmd . " apply --recount --no-index " . cached_flag . " --reverse - ",
		\ selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Tried to unaply this"
		echoerr string(selection)
	endif
endfunction

function! magit#git#submodule_status()
	return system(s:git_cmd . " submodule status")
endfunction
