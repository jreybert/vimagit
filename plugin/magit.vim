scriptencoding utf-8

if exists('g:loaded_magit') || !executable('git') || &cp
  finish
endif
let g:loaded_magit = 1

" Initialisation {{{

" FIXME: find if there is a minimum vim version required
" if v:version < 703
" endif

" source common file. variables in common file are shared with plugin and
" syntax files
execute 'source ' . resolve(expand('<sfile>:p:h')) . '/../common/magit_common.vim'

" g:magit_unstaged_buffer_name: vim buffer name for vimagit
let g:magit_unstaged_buffer_name = "magit-playground"

" s:set: helper function to set user definable variable
" param[in] var: variable to set
" param[in] default: default value if not already set by the user
" return: no
function! s:set(var, default)
	if !exists(a:var)
		if type(a:default)
			execute 'let' a:var '=' string(a:default)
		else
			execute 'let' a:var '=' a:default
		endif
	endif
endfunction

call s:set('g:magit_stage_file_mapping',        "F")
call s:set('g:magit_stage_hunk_mapping',        "S")
call s:set('g:magit_discard_hunk_mapping',      "DDD")
call s:set('g:magit_commit_mapping_command',    "w<cr>")
call s:set('g:magit_commit_mapping1',           "C")
call s:set('g:magit_commit_mapping2',           "CC")
call s:set('g:magit_commit_amend_mapping',      "CA")
call s:set('g:magit_commit_fixup_mapping',      "CF")
call s:set('g:magit_reload_mapping',            "R")
call s:set('g:magit_ignore_mapping',            "I")
call s:set('g:magit_close_mapping',             "q")
call s:set('g:magit_toggle_help_mapping',       "h")
call s:set('g:magit_folding_mapping',           "<cr>")

call s:set('g:magit_enabled',                   1)
call s:set('g:magit_show_help',                 1)

" }}}

" {{{ Internal functions

" s:magit_top_dir: top directory of git tree
" it is evaluated only once
" FIXME: it won't work when playing with multiple git directories wihtin one
" vim session
let s:magit_top_dir=''
" s:mg_top_dir: return the absolute path of current git worktree
" return top directory
function! s:mg_top_dir()
	if ( s:magit_top_dir == '' )
		let s:magit_top_dir=<SID>mg_strip(system("git rev-parse --show-toplevel")) . "/"
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
" s:mg_git_dir: return the absolute path of current git worktree
" return git directory
function! s:mg_git_dir()
	if ( s:magit_git_dir == '' )
		let s:magit_git_dir=<SID>mg_strip(system("git rev-parse --git-dir")) . "/"
		if ( v:shell_error != 0 )
			echoerr "Git error: " . s:magit_git_dir
		endif
	endif
	return s:magit_git_dir
endfunction

" s:magit_cd_cmd: plugin variable to choose lcd/cd command, 'lcd' if exists,
" 'cd' otherwise
let s:magit_cd_cmd = exists('*haslocaldir') && haslocaldir() ? 'lcd ' : 'cd '

" s:mg_system: wrapper for system, which only takes String as input in vim,
" although it can take String or List input in neovim.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args
" return: command output as a string
function! s:mg_system(...)
	let dir = getcwd()
	try
		execute s:magit_cd_cmd . <SID>mg_top_dir()
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

" s:mg_systemlist: wrapper for systemlist, which only exists in neovim for
" the moment.
" INFO: temporarly change pwd to git top directory, then restore to previous
" pwd at the end of function
" param[in] ...: command + optional args to execute, args can be List or String
" return: command output as a list
function! s:mg_systemlist(...)
	let dir = getcwd()
	try
		execute s:magit_cd_cmd . <SID>mg_top_dir()
		" systemlist since v7.4.248
		if exists('*systemlist')
			return call('systemlist', a:000)
		else
			return split(call('<SID>mg_system', a:000), '\n')
		endif
	finally
		execute s:magit_cd_cmd . dir
	endtry
endfunction

" s:mg_underline: helper function to underline a string
" param[in] title: string to underline
" return a string composed of strlen(title) '='
function! s:mg_underline(title)
	return substitute(a:title, ".", "=", "g")
endfunction

" s:mg_strip: helper function to strip a string
" WARNING: it only works with monoline string
" param[in] string: string to strip
" return: stripped string
function! s:mg_strip(string)
	return substitute(a:string, '^\s*\(.\{-}\)\s*\n\=$', '\1', '')
endfunction

" s:mg_join_list: helper function to concatente a list of strings with newlines
" param[in] list: List to to concat
" return: concatenated list
function! s:mg_join_list(list)
	return join(a:list, "\n") . "\n"
endfunction

" s:mg_fatten: flat a nested list. it return a one dimensional list with
" primary elements
" https://gist.github.com/dahu/3322468
" param[in] list: a List, can be nested or not
" return: one dimensional list
function! s:mg_flatten(list)
  let val = []
  for elem in a:list
    if type(elem) == type([])
      call extend(val, <SID>mg_flatten(elem))
    else
      call extend(val, [elem])
    endif
    unlet elem
  endfor
  return val
endfunction

" s:mg_append_file: helper function to append to a file
" Version working with file *possibly* containing trailing newline
" param[in] file: filename to append
" param[in] lines: List of lines to append
function! s:mg_append_file(file, lines)
	let fcontents=[]
	if ( filereadable(a:file) )
		let fcontents=readfile(a:file, 'b')
	endif
	if !empty(fcontents) && empty(fcontents[-1])
		call remove(fcontents, -1)
	endif
	call writefile(fcontents+a:lines, a:file, 'b')
endfunction

" s:mg_get_status_list: this function returns the git status output formated
" into a List of Dict as
" [ {staged', 'unstaged', 'filename'}, ... ]
function! s:mg_get_status_list()
	let file_list = []

	let status_list=<SID>mg_systemlist("git status --porcelain")
	for file_status_line in status_list
		let line_match = matchlist(file_status_line, '\(.\)\(.\) \(.*\)$')
		let filename = line_match[3]
		if ( filename =~ " -> " )
			" git status add quotes " for file names with spaces only for rename mode
			let filename=substitute(filename, '.* -> \(.*\)$', '\1', '')
		endif
		call add(file_list, { 'staged': line_match[1], 'unstaged': line_match[2], 'filename': filename })
	endfor
	return file_list
endfunction

" s:magit_inline_help: Dict containing inline help for each section
let s:magit_inline_help = {
			\ 'staged': [
\'S      if cursor in diff header, unstage file',
\'       if cursor in hunk, unstage hunk',
\'F      if cursor in diff header or hunk, unstage file',
\],
			\ 'unstaged': [
\'S      if cursor in diff header, stage file',
\'       if cursor in hunk, stage hunk',
\'F      if cursor in diff header or hunk, stage file',
\'DDD    discard file changes (warning, changes will be lost)',
\'I      add file in .gitgnore',
\],
			\ 'global': [
\'C CC   set commit mode to normal, and show "Commit message" section',
\'CA     set commit mode amend, and show "Commit message" section with previous',
\'       commit message',
\'CF     amend staged changes to previous commit without modifying the previous',
\'       commit message',
\'R      refresh magit buffer',
\'q      close magit buffer',
\'h      toggle help showing in magit buffer',
\'',
\'To disable inline default appearance, add "let g:magit_show_help=0" to .vimrc',
\'You will still be able to toggle inline help with h',
\],
			\ 'commit': [
\'C CC   commit all staged changes with commit mode previously set (normal or',
\':w<cr> amend) with message written in this section',
\],
\}

" s:mg_get_inline_help_line_nb: this function returns the number of lines of
" a given section, or 0 if help is disabled.
" param[in] section: section identifier
" return number of lines
function! s:mg_get_inline_help_line_nb(section)
	return ( g:magit_show_help == 1 ) ?
		\ len(s:magit_inline_help[a:section]) : 0
endfunction

" s:mg_section_help: this function writes in current buffer the inline help
" for a given section, it does nothing if inline help is disabled.
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] section: section identifier
function! s:mg_section_help(section)
	if ( g:magit_show_help == 1 )
		silent put =s:magit_inline_help[a:section]
	endif
endfunction

" s:mg_get_info: this function writes in current buffer current git state
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_info()
	silent put =''
	silent put =g:magit_sections['info']
	silent put =<SID>mg_underline(g:magit_sections['info'])
	silent put =''
	let branch=<SID>mg_system("git rev-parse --abbrev-ref HEAD")
	let commit=<SID>mg_system("git show -s --oneline")
	silent put ='Current branch: ' . branch
	silent put ='Last commit:    ' . commit
	silent put =''
endfunction

" s:mg_diff_dict: big main global variable, containing all diffs
" It is formatted as follow
" { 'staged_or_unstaged': staged/unstaged
"     [
"         { 'filename':
"             { 'visible': bool,
"               'status' : g:magit_git_status_code,
"               'exists' : bool
"               'diff'   : [ [header], [hunk0], [hunk1], ...]
"             }
"          },
"          ...
"      ]
" }
let s:mg_diff_dict = { 'staged': {}, 'unstaged': {} }

function! s:mg_add_file_diff_dict(mode, diff_dict_mode, status, filename)
	let dev_null = ( a:status == '?' ) ? " /dev/null " : " "
	let staged_flag = ( a:mode == 'staged' ) ? " --staged " : " "
	let diff_cmd="git diff --no-ext-diff " . staged_flag . "--no-color --patch -- " . dev_null . " " .  a:filename
	let diff_list=s:mg_systemlist(diff_cmd)
	if ( empty(diff_list) )
		echoerr "diff command \"" . diff_cmd . "\" returned nothing"
	endif
	if (!has_key(a:diff_dict_mode, a:filename))
		let a:diff_dict_mode[a:filename] = {}
		let a:diff_dict_mode[a:filename]['visible'] = 0
	endif
	let a:diff_dict_mode[a:filename]['diff'] = []
	let a:diff_dict_mode[a:filename]['exists'] = 1
	let a:diff_dict_mode[a:filename]['status'] = a:status
	let index = 0
	call add(a:diff_dict_mode[a:filename]['diff'], [])
	for diff_line in diff_list
		if ( diff_line =~ "^@.*" )
			let index+=1
			call add(a:diff_dict_mode[a:filename]['diff'], [])
		endif
		call add(a:diff_dict_mode[a:filename]['diff'][index], diff_line)
	endfor
endfunction

" s:mg_update_diff_dict: update s:mg_diff_dict
" if a file does not exists anymore (because all its changes have been
" committed, deleted, discarded), it is removed from s:mg_diff_dict
" else, its diff is discarded and regenrated
" what is resilient is its 'visible' parameter
function! s:mg_update_diff_dict()
	for diff_dict_mode in values(s:mg_diff_dict)
		for file in values(diff_dict_mode)
			let file['exists'] = 0
			" always discard previous diff
			unlet file['diff']
		endfor
	endfor

	for [mode, diff_dict_mode] in items(s:mg_diff_dict)

		let status_list = s:mg_get_status_list()
		for file_status in status_list
			let status=file_status[mode]

			" untracked code apperas in staged column, we skip it
			if ( status == ' ' || ( ( mode == 'staged' ) && status == '?' ) )
				continue
			endif
			call <SID>mg_add_file_diff_dict(mode, diff_dict_mode, status, file_status['filename'])
		endfor
	endfor

	" remove files that have changed their mode or been committed/deleted/discarded...
	for diff_dict_mode in values(s:mg_diff_dict)
		for [key, file] in items(diff_dict_mode)
			if ( file['exists'] == 0 )
				unlet diff_dict_mode[key]
			endif
		endfor
	endfor
endfunction


" s:mg_get_staged_section: this function writes in current buffer all staged
" or unstaged files, using s:mg_diff_dict information
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] mode: 'staged' or 'unstaged'
function! s:mg_get_staged_section(mode)
	put =''
	put =g:magit_sections[a:mode]
	call <SID>mg_section_help(a:mode)
	put =s:mg_underline(g:magit_sections[a:mode])
	put =''

	for [ filename, file_props ] in items(s:mg_diff_dict[a:mode])
		put =g:magit_git_status_code[file_props['status']] . ': ' . filename
		if ( file_props['visible'] == 0 )
			put =''
			continue
		endif
		if ( file_props['exists'] == 0 )
			echoerr "Error, " . filename . " should not exists"
		endif
		for diff_line in file_props['diff']
			silent put =diff_line
		endfor
		put =''
	endfor
endfunction

" s:mg_get_stashes: this function write in current buffer all stashes
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_stashes()
	silent! let stash_list=<SID>mg_systemlist("git stash list")
	if ( v:shell_error != 0 )
		echoerr "Git error: " . stash_list
	endif

	if (!empty(stash_list))
		silent put =''
		silent put =g:magit_sections['stash']
		silent put =<SID>mg_underline(g:magit_sections['stash'])
		silent put =''

		for stash in stash_list
			let stash_id=substitute(stash, '^\(stash@{\d\+}\):.*$', '\1', '')
			put =stash
			silent! execute "read !git stash show -p " . stash_id
		endfor
	endif
endfunction

" s:magit_commit_mode: global variable which states in which commit mode we are
" values are:
"       '': not in commit mode
"       'CC': normal commit mode, next commit command will create a new commit
"       'CA': amend commit mode, next commit command will ament current commit
"       'CF': fixup commit mode, it should not be a global state mode
let s:magit_commit_mode=''

" s:mg_get_commit_section: this function writes in current buffer the commit
" section. It is a commit message, depending on s:magit_commit_mode
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] s:magit_commit_mode: this function uses global commit mode
"       'CC': prepare a brand new commit message
"       'CA': get the last commit message
function! s:mg_get_commit_section()
	let commit_mode_str=""
	if ( s:magit_commit_mode == 'CC' )
		let commit_mode_str="normal"
	elseif ( s:magit_commit_mode == 'CA' )
		let commit_mode_str="amend"
	endif
	silent put =''
	silent put =g:magit_sections['commit_start']
	silent put ='Commit mode: '.commit_mode_str
	call <SID>mg_section_help('commit')
	silent put =<SID>mg_underline(g:magit_sections['commit_start'])
	silent put =''

	let git_dir=<SID>mg_git_dir()
	" refresh the COMMIT_EDITMSG file
	if ( s:magit_commit_mode == 'CC' )
		silent! call <SID>mg_system("GIT_EDITOR=/bin/false git commit -e 2> /dev/null")
	elseif ( s:magit_commit_mode == 'CA' )
		silent! call <SID>mg_system("GIT_EDITOR=/bin/false git commit --amend -e 2> /dev/null")
	endif
	if ( filereadable(git_dir . 'COMMIT_EDITMSG') )
		let comment_char=<SID>mg_comment_char()
		let commit_msg=<SID>mg_join_list(filter(readfile(git_dir . 'COMMIT_EDITMSG'), 'v:val !~ "^' . comment_char . '"'))
		put =commit_msg
	endif
	put =g:magit_sections['commit_end']
endfunction

" s:mg_comment_char: this function gets the commentChar from git config
function! s:mg_comment_char()
	silent! let git_result=<SID>mg_strip(<SID>mg_system("git config --get core.commentChar"))
	if ( v:shell_error != 0 )
		return '#'
	else
		return git_result
	endif
endfunction

" s:mg_search_block: helper function, to get a block of text, giving a start
" and multiple end pattern
" a "pattern parameter" is a List:
"   @[0]: end pattern regex
"   @[1]: number of line to exclude above (negative), below (positive) or none (0)
" param[in] start_pattern: start "pattern parameter", which will be search
" backward (cursor position is set to end of line before searching, to find the
" pattern if on the current line)
" param[in] end_pattern: list of end "pattern parameter". Each pattern is 
" searched in order. It'll choose the match with the minimum line number
" (smallest region search)
" param[in] upperlimit_pattern: regex of upper limit. If start_pattern line is
" inferior to upper_limit line, block is discarded
" return: a list.
"      @[0]: return status
"      @[1]: List of selected block lines
function! s:mg_search_block(start_pattern, end_pattern, upper_limit_pattern)
	let l:winview = winsaveview()

	let upper_limit=0
	if ( a:upper_limit_pattern != "" )
		let upper_limit=search(a:upper_limit_pattern, "cbnW")
	endif

	let start=search(a:start_pattern[0], "cbW")
	if ( start == 0 )
		call winrestview(l:winview)
		throw "out_of_block"
	endif
	if ( start < upper_limit )
		call winrestview(l:winview)
		throw "out_of_block"
	endif
	let start+=a:start_pattern[1]

	let end=0
	let min=line('$')
	for end_p in a:end_pattern
		let curr_end=search(end_p[0], "nW")
		if ( curr_end != 0 && curr_end <= min )
			let end=curr_end + end_p[1]
			let min=curr_end
		endif
	endfor
	if ( end == 0 )
		call winrestview(l:winview)
		throw "out_of_block"
	endif

	let lines=getline(start, end)

	call winrestview(l:winview)
	return lines
endfunction

" s:mg_git_commit: commit staged stuff with message prepared in commit section
" param[in] mode: mode to commit
"       'CF': don't use commit section, just amend previous commit with staged
"       stuff, without modifying message
"       'CC': commit staged stuff with message in commit section to a brand new
"       commit
"       'CA': commit staged stuff with message in commit section amending last
"       commit
" return no
function! s:mg_git_commit(mode) abort
	if ( a:mode == 'CF' )
		silent let git_result=<SID>mg_system("git commit --amend -C HEAD")
	else
		let commit_section_pat_start='^'.g:magit_sections['commit_start'].'$'
		let commit_section_pat_end='^'.g:magit_sections['commit_end'].'$'
		let commit_jump_line = 3 + <SID>mg_get_inline_help_line_nb('commit')
		let commit_msg = <SID>mg_search_block(
		 \ [commit_section_pat_start, commit_jump_line],
		 \ [ [commit_section_pat_end, -1] ], "")
		let amend_flag=""
		if ( a:mode == 'CA' )
			let amend_flag=" --amend "
		endif
		silent! let git_result=<SID>mg_system("git commit " . amend_flag . " --file - ", commit_msg)
	endif
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
	endif
endfunction

" s:mg_select_file_block: select the whole diff file, relative to the current
" cursor position
" nota: if the cursor is not in a diff file when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the patch for the whole file
function! s:mg_select_file_block()
	return <SID>mg_search_block(
				\ [g:magit_file_re, 1],
				\ [ [g:magit_file_re, -1],
				\   [g:magit_stash_re, -1],
				\   [g:magit_section_re, -2],
				\   [g:magit_bin_re, 0],
				\   [g:magit_eof_re, 0 ]
				\ ],
				\ "")
endfunction

" s:mg_select_header_block: select the upper diff header, relative to the current
" cursor position
" nota: if the cursor is not in a diff file when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the diff header
function! s:mg_select_header_block()
	return <SID>mg_search_block(
				\ [g:magit_file_re, 1],
				\ [ [g:magit_hunk_re, -1] ],
				\ "")
endfunction

" s:mg_select_hunk_block: select a hunk, from the current cursor position
" nota: if the cursor is not in a hunk when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the hunk
function! s:mg_select_hunk_block()
	return <SID>mg_search_block(
				\ [g:magit_hunk_re, 0],
				\ [ [g:magit_hunk_re, -1],
				\   [g:magit_file_re, -1],
				\   [g:magit_stash_re, -1],
				\   [g:magit_section_re, -2],
				\   [g:magit_eof_re, 0 ]
				\ ],
				\ g:magit_file_re)
endfunction

" s:mg_git_apply: helper function to stage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! s:mg_git_apply(selection)
	let selection = a:selection
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	silent let git_result=<SID>mg_system("git apply --no-index --cached -", selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Tried to aply this"
		echoerr string(a:selection)
	endif
endfunction

" s:mg_git_unapply: helper function to unstage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! s:mg_git_unapply(selection, mode)
	let cached_flag=''
	if ( a:mode == 'staged' )
		let cached_flag=' --cached '
	endif
	let selection = a:selection
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	silent let git_result=<SID>mg_system("git apply --no-index " . cached_flag . " --reverse - ", selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Tried to unaply this"
		echoerr string(a:selection)
	endif
endfunction

" s:mg_get_section: helper function to get the current section, according to
" cursor position
" return: section id, empty string if no section found
function! s:mg_get_section()
	let section_line=getline(search(g:magit_section_re, "bnW"))
	for [section_name, section_str] in items(g:magit_sections)
		if ( section_line == section_str )
			return section_name
		endif
	endfor
	return ''
endfunction
" }}}

" {{{ User functions and commands

" magit#open_close_folding()
" param[in] visible : boolean, force visible value
function! magit#open_close_folding(...)
	if ( getline(".") =~ g:magit_file_re )
		let list = matchlist(getline("."), g:magit_file_re)
		let filename = list[2]
		let section=<SID>mg_get_section()
		" if first param is set, force visible to this value
		" else, toggle value
		let s:mg_diff_dict[section][filename]['visible'] =
		 \ ( a:0 == 1 ) ? a:1 :
		 \ ( s:mg_diff_dict[section][filename]['visible'] == 0 ) ? 1 : 0
	endif
	call magit#update_buffer()
endfunction


" magit#update_buffer: this function:
" 1. checks that current buffer is the wanted one
" 2. save window state (cursor position...)
" 3. delete buffer
" 4. fills with unstage stuff
" 5. restore window state
function! magit#update_buffer()
	if ( @% != g:magit_unstaged_buffer_name )
		echoerr "Not in magit buffer " . g:magit_unstaged_buffer_name . " but in " . @%
		return
	endif
	" FIXME: find a way to save folding state. According to help, this won't
	" help:
	" > This does not save fold information.
	" Playing with foldenable around does not help.
	" mkview does not help either.
	let l:winview = winsaveview()
	silent! %d
	
	call <SID>mg_get_info()
	call <SID>mg_section_help('global')
	if ( s:magit_commit_mode != '' )
		call <SID>mg_get_commit_section()
	endif
	call <SID>mg_update_diff_dict()
	call <SID>mg_get_staged_section('staged')
	call <SID>mg_get_staged_section('unstaged')
	call <SID>mg_get_stashes()

	call winrestview(l:winview)

	if ( s:magit_commit_mode != '' )
		let commit_section_pat_start='^'.g:magit_sections['commit_start'].'$'
		silent! let section_line=search(commit_section_pat_start, "w")
		silent! call cursor(section_line+3+<SID>mg_get_inline_help_line_nb('commit'), 0)
	endif

	set filetype=magit

endfunction

" magit#toggle_help: toggle inline help showing in magit buffer
function! magit#toggle_help()
	let g:magit_show_help = ( g:magit_show_help == 0 ) ? 1 : 0
	call magit#update_buffer()
endfunction

" magit#show_magit: prepare and show magit buffer
" it also set local mappings to magit buffer
function! magit#show_magit(orientation)
	if ( <SID>mg_strip(system("git rev-parse --is-inside-work-tree")) != 'true' )
		echoerr "Magit must be started from a git repository"
		return
	endif
	vnew 
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal foldmethod=syntax
	setlocal foldlevel=1
	setlocal filetype=magit
	"setlocal readonly

	silent! execute "bdelete " . g:magit_unstaged_buffer_name
	execute "file " . g:magit_unstaged_buffer_name

	execute "nnoremap <buffer> <silent> " . g:magit_stage_file_mapping .   " :call magit#stage_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping .   " :call magit#stage_hunk()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_discard_hunk_mapping . " :call magit#discard_hunk()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_reload_mapping .       " :call magit#update_buffer()<cr>"
	execute "cnoremap <buffer> <silent> " . g:magit_commit_mapping_command." :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_mapping1 .      " :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_mapping2 .      " :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_amend_mapping . " :call magit#commit_command('CA')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_fixup_mapping . " :call magit#commit_command('CF')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_ignore_mapping .       " :call magit#ignore_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_close_mapping .        " :close<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_toggle_help_mapping .  " :call magit#toggle_help()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_folding_mapping .      " :call magit#open_close_folding()<cr>"
	
	call magit#update_buffer()
	execute "normal! gg"
endfunction

function! s:mg_select_closed_file()
	if ( getline(".") =~ g:magit_file_re )
		let list = matchlist(getline("."), g:magit_file_re)
		let filename = list[2]
		let section=<SID>mg_get_section()
		if ( has_key(s:mg_diff_dict[section], filename) &&
		 \ ( s:mg_diff_dict[section][filename]['visible'] == 0 ) )
			let selection = <SID>mg_flatten(s:mg_diff_dict[section][filename]['diff'])
			return selection
		endif
	endif
	throw "out_of_block"
endfunction

" magit#stage_hunk: this function stage a single hunk, from the current
" cursor position
" INFO: in unstaged section, it stages the hunk, and in staged section, it
" unstages the hunk
" return: no
function! magit#stage_hunk() abort
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		let header = <SID>mg_select_header_block()
		try
			let hunk = <SID>mg_select_hunk_block()
			let selection = header + hunk
		catch 'out_of_block'
			let selection = <SID>mg_select_file_block()
		endtry
	endtry
	let section=<SID>mg_get_section()
	if ( section == 'unstaged' )
		call <SID>mg_git_apply(selection)
	elseif ( section == 'staged' )
		call <SID>mg_git_unapply(selection, 'staged')
	else
		echoerr "Must be in \"" . 
		 \ g:magit_sections['staged'] . "\" or \"" . 
		 \ g:magit_sections['unstaged'] . "\" section"
	endif
	call magit#update_buffer()
endfunction

" magit#stage_file: this function stage a whole file, from the current
" cursor position
" INFO: in unstaged section, it stages the file, and in staged section, it
" unstages the file
" return: no
function! magit#stage_file() abort
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		let selection = <SID>mg_select_file_block()
	endtry

	let section=<SID>mg_get_section()
	if ( section == 'unstaged' )
		call <SID>mg_git_apply(selection)
	elseif ( section == 'staged' )
		call <SID>mg_git_unapply(selection, 'staged')
	else
		echoerr "Must be in \"" . 
		 \ g:magit_sections['staged'] . "\" or \"" . 
		 \ g:magit_sections['unstaged'] . "\" section"
	endif
	call magit#update_buffer()
endfunction

" magit#discard_hunk: this function discard a single hunk, from the current
" cursor position
" INFO: only works in unstaged section
" return: no
function! magit#discard_hunk() abort
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		let header = <SID>mg_select_header_block()
		try
			let hunk = <SID>mg_select_hunk_block()
			let selection = header + hunk
		catch 'out_of_block'
			let selection = <SID>mg_select_file_block()
		endtry
	endtry
	let section=<SID>mg_get_section()
	if ( section == 'unstaged' )
		call <SID>mg_git_unapply(selection, 'unstaged')
	else
		echoerr "Must be in \"" . 
		 \ g:magit_sections['unstaged'] . "\" section"
	endif
	call magit#update_buffer()
endfunction

" magit#ignore_file: this function add the file under cursor to .gitignore
" FIXME: git diff adds some strange characters to end of line
function! magit#ignore_file() abort
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		let selection = <SID>mg_select_file_block()
	endtry
	let ignore_file=""
	for line in selection
		if ( match(line, "^+++ ") != -1 )
			let ignore_file=<SID>mg_strip(substitute(line, '^+++ ./\(.*\)$', '\1', ''))
			break
		endif
	endfor
	if ( ignore_file == "" )
		echoerr "Can not find file to ignore"
		return
	endif
	call <SID>mg_append_file(<SID>mg_top_dir() . ".gitignore", [ ignore_file ] )
	call magit#update_buffer()
endfunction

" magit#commit_command: entry function for commit mode
" INFO: it has a different effect if current section is commit section or not
" param[in] mode: commit mode
"   'CF': do not set global s:magit_commit_mode, directly call magit#git_commit
"   'CA'/'CF': if in commit section mode, call magit#git_commit, else just set
"   global state variable s:magit_commit_mode,
function! magit#commit_command(mode)
	if ( a:mode == 'CF' )
		call <SID>mg_git_commit(a:mode)
	else
		let section=<SID>mg_get_section()
		if ( section == 'commit_start' )
			if ( s:magit_commit_mode == '' )
				echoerr "Error, commit section should not be enabled"
				return
			endif
			" when we do commit, it is prefered ot commit the way we prepared it
			" (.i.e normal or amend), whatever we commit with CC or CA.
			call <SID>mg_git_commit(s:magit_commit_mode)
			let s:magit_commit_mode=''
		else
			let s:magit_commit_mode=a:mode
		endif
	endif
	call magit#update_buffer()
endfunction

command! Magit call magit#show_magit("v")

" }}}
