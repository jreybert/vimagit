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

" g:magit_buffer_name: vim buffer name for vimagit
let g:magit_buffer_name = "magit-playground"

let s:state = deepcopy(magit#state#state)

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

" these mappings are broadly applied, for all vim buffers
call s:set('g:magit_show_magit_mapping',        '<leader>M' )

" these mapping are applied locally, for magit buffer only
call s:set('g:magit_stage_file_mapping',        'F' )
call s:set('g:magit_stage_hunk_mapping',        'S' )
call s:set('g:magit_stage_line_mapping',        'L' )
call s:set('g:magit_mark_line_mapping',         'M' )
call s:set('g:magit_discard_hunk_mapping',      'DDD' )
call s:set('g:magit_commit_mapping_command',    'w<cr>' )
call s:set('g:magit_commit_mapping',            'CC' )
call s:set('g:magit_commit_amend_mapping',      'CA' )
call s:set('g:magit_commit_fixup_mapping',      'CF' )
call s:set('g:magit_reload_mapping',            'R' )
call s:set('g:magit_ignore_mapping',            'I' )
call s:set('g:magit_close_mapping',             'q' )
call s:set('g:magit_toggle_help_mapping',       'h' )

call s:set('g:magit_folding_toggle_mapping',    [ '<CR>' ])
call s:set('g:magit_folding_open_mapping',      [ 'zo', 'zO' ])
call s:set('g:magit_folding_close_mapping',     [ 'zc', 'zC' ])

" user options
call s:set('g:magit_enabled',                   1)
call s:set('g:magit_show_help',                 1)
call s:set('g:magit_default_show_all_files',    0)
call s:set('g:magit_default_fold_level',        1)

call s:set('g:magit_warning_max_lines',         10000)

execute "nnoremap <silent> " . g:magit_show_magit_mapping . " :call magit#show_magit('v')<cr>"
" }}}

" {{{ Internal functions

" s:magit_inline_help: Dict containing inline help for each section
let s:magit_inline_help = {
			\ 'staged': [
\'S      if cursor on filename header, unstage file',
\'       if cursor in hunk, unstage hunk',
\'F      if cursor on filename header or hunk, unstage whole file',
\],
			\ 'unstaged': [
\'S      if cursor on filename header, stage file',
\'       if cursor in hunk, stage hunk',
\'       if visual selection in hunk (with v), stage selection',
\'       if lines marked in hunk (with M), stage marked lines',
\'L      stage the line under the cursor',
\'M      if cursor in hunk, mark line under cursor "to be staged"',
\'       if visual selection in hunk (with v), mark selected lines "to be'
\'       staged"',
\'F      if cursor on filename header or hunk, stage whole file',
\'DDD    discard file changes (warning, changes will be lost)',
\'I      add file in .gitgnore',
\],
			\ 'global': [
\'<CR>   if cursor on filename header line, unhide diffs for this file',
\'CC     set commit mode to normal, and show "Commit message" section',
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
\'CC,:w  commit all staged changes with commit mode previously set (normal or',
\'       amend) with message written in this section',
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
	silent put =g:magit_sections.info
	silent put =magit#utils#underline(g:magit_sections.info)
	silent put =''
	let branch=magit#utils#system("git rev-parse --abbrev-ref HEAD")
	let commit=magit#utils#system("git show -s --oneline")
	silent put ='Current branch: ' . branch
	silent put ='Last commit:    ' . commit
	silent put =''
endfunction

function! s:mg_display_files(mode, curdir, depth)

	" FIXME: ouch, must store subdirs in more efficient way
	for filename in sort(keys(s:state.get_files(a:mode)))
		let file = s:state.get_file(a:mode, filename, 0)
		if ( file.depth != a:depth || filename !~ a:curdir . '.*' )
			continue
		endif
		if ( file.empty == 1 )
			put =g:magit_git_status_code.E . ': ' . filename
		elseif ( file.symlink != '' )
			put =g:magit_git_status_code.L . ': ' . filename . ' -> ' . file.symlink
		elseif ( file.dir != 0 )
			put =g:magit_git_status_code.N . ': ' . filename
			if ( file.visible == 1 )
				call s:mg_display_files(a:mode, filename, a:depth + 1)
				continue
			endif
		else
			put =g:magit_git_status_code[file.status] . ': ' . filename
		endif
		if ( file.visible == 0 )
			put =''
			continue
		endif
		if ( file.exists == 0 )
			echoerr "Error, " . filename . " should not exists"
		endif
		let hunks = file.get_hunks()
		for hunk in hunks
			silent put =hunk.header
			silent put =hunk.lines
		endfor
		put =''
	endfor
endfunction

" s:mg_get_staged_section: this function writes in current buffer all staged
" or unstaged files, using s:state.dict information
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] mode: 'staged' or 'unstaged'
function! s:mg_get_staged_section(mode)
	put =''
	put =g:magit_sections[a:mode]
	call <SID>mg_section_help(a:mode)
	put =magit#utils#underline(g:magit_sections[a:mode])
	put =''
	call s:mg_display_files(a:mode, '', 0)
endfunction

" s:mg_get_stashes: this function write in current buffer all stashes
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_stashes()
	silent! let stash_list=magit#utils#systemlist("git stash list")
	if ( v:shell_error != 0 )
		echoerr "Git error: " . stash_list
	endif

	if (!empty(stash_list))
		silent put =''
		silent put =g:magit_sections.stash
		silent put =magit#utils#underline(g:magit_sections.stash)
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
	silent put =g:magit_sections.commit_start
	silent put ='Commit mode: '.commit_mode_str
	call <SID>mg_section_help('commit')
	silent put =magit#utils#underline(g:magit_sections.commit_start)
	silent put =''

	let git_dir=magit#utils#git_dir()
	" refresh the COMMIT_EDITMSG file
	if ( s:magit_commit_mode == 'CC' )
		silent! call magit#utils#system("GIT_EDITOR=/bin/false git commit -e 2> /dev/null")
	elseif ( s:magit_commit_mode == 'CA' )
		silent! call magit#utils#system("GIT_EDITOR=/bin/false git commit --amend -e 2> /dev/null")
	endif
	if ( filereadable(git_dir . 'COMMIT_EDITMSG') )
		let comment_char=<SID>mg_comment_char()
		let commit_msg=magit#utils#join_list(filter(readfile(git_dir . 'COMMIT_EDITMSG'), 'v:val !~ "^' . comment_char . '"'))
		put =commit_msg
	endif
	put =g:magit_sections.commit_end
endfunction

" s:mg_comment_char: this function gets the commentChar from git config
function! s:mg_comment_char()
	silent! let git_result=magit#utils#strip(
				\ magit#utils#system("git config --get core.commentChar"))
	if ( v:shell_error != 0 )
		return '#'
	else
		return git_result
	endif
endfunction

" s:mg_search_block: helper function, to get start and end line of a block,
" giving a start and multiple end pattern
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
" return: [startline, endline]
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

	call winrestview(l:winview)

	return [start,end]
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
		silent let git_result=magit#utils#system("git commit --amend -C HEAD")
	else
		let commit_section_pat_start='^'.g:magit_sections.commit_start.'$'
		let commit_section_pat_end='^'.g:magit_sections.commit_end.'$'
		let commit_jump_line = 3 + <SID>mg_get_inline_help_line_nb('commit')
		let [start, end] = <SID>mg_search_block(
		 \ [commit_section_pat_start, commit_jump_line],
		 \ [ [commit_section_pat_end, -1] ], "")
		let commit_msg = getline(start, end)
		let amend_flag=""
		if ( a:mode == 'CA' )
			let amend_flag=" --amend "
		endif
		silent! let git_result=magit#utils#system(
					\ "git commit " . amend_flag . " --file - ", commit_msg)
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
function! s:mg_git_apply(header, selection)
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	let git_cmd="git apply --recount --no-index --cached -"
	silent let git_result=magit#utils#system(git_cmd, selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Git cmd: " . git_cmd
		echoerr "Tried to aply this"
		echoerr string(selection)
	endif
endfunction

" s:mg_git_unapply: helper function to unstage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! s:mg_git_unapply(header, selection, mode)
	let cached_flag=''
	if ( a:mode == 'staged' )
		let cached_flag=' --cached '
	endif
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	silent let git_result=magit#utils#system(
		\ "git apply --recount --no-index " . cached_flag . " --reverse - ",
		\ selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
		echoerr "Tried to unaply this"
		echoerr string(selection)
	endif
endfunction

" s:mg_create_diff_from_select: craft the diff to apply from a selection
" in a chunk
" remarks: it works with full lines, and can not span over multiple chunks
" param[in] select_lines: List containing all selected line numbers
" return: List containing the diff to apply, including the chunk header (must
" be applied with git apply --recount)
function! s:mg_create_diff_from_select(select_lines)
	let start_select_line = a:select_lines[0]
	let end_select_line = a:select_lines[-1]
	let [starthunk,endhunk] = <SID>mg_select_hunk_block()
	if ( start_select_line < starthunk || end_select_line > endhunk )
		throw 'out of hunk selection'
	endif
	let section=<SID>mg_get_section()
	let filename=<SID>mg_get_filename()
	let hunks = s:state.get_file(section, filename).get_hunks()
	for hunk in hunks
		if ( hunk.header == getline(starthunk) )
			let current_hunk = hunk
			break
		endif
	endfor
	let selection = []
	call add(selection, current_hunk.header)

	let current_line = starthunk + 1
	for hunk_line in current_hunk.lines
		if ( index(a:select_lines, current_line) != -1 )
			call add(selection, getline(current_line))
		elseif ( hunk_line =~ '^+.*' )
			" just ignore these lines
		elseif ( hunk_line =~ '^-.*' )
			call add(selection, substitute(hunk_line, '^-\(.*\)$', ' \1', ''))
		elseif ( hunk_line =~ '^ .*' )
			call add(selection, hunk_line)
		else
			throw 'visual selection error: ' . hunk_line
		endif
		let current_line += 1
	endfor
	return selection
endfunction

" s:mg_mark_lines_in_hunk: this function toggle marks for selected lines in a
" hunk.
" if a hunk contains marked lines, only these lines will be (un)staged on next
" (un)stage command
" param[in] start_select_line,end_select_line: limits of the selection
function! s:mg_mark_lines_in_hunk(start_select_line, end_select_line)
	let [starthunk,endhunk] = <SID>mg_select_hunk_block()
	if ( a:start_select_line < starthunk || a:end_select_line > endhunk )
		throw 'out of hunk selection'
	endif
	return magit#sign#toggle_signs('M', a:start_select_line, a:end_select_line)
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

" s:mg_get_filename: helper function to get the current filename, according to
" cursor position
" return: filename
function! s:mg_get_filename()
	return substitute(getline(search(g:magit_file_re, "cbnW")), g:magit_file_re, '\2', '')
endfunction

" s:mg_get_hunkheader: helper function to get the current hunk header,
" according to cursor position
" return: hunk header
function! s:mg_get_hunkheader()
	return getline(search(g:magit_hunk_re, "cbnW"))
endfunction

" }}}

" {{{ User functions and commands

" magit#open_close_folding_wrapper: wrapper function to
" magit#open_close_folding. If line under cursor is not a cursor, execute
" normal behavior
" param[in] mapping: which has been set
" param[in] visible : boolean, force visible value. If not set, toggle
" visibility
function! magit#open_close_folding_wrapper(mapping, ...)
	if ( getline(".") =~ g:magit_file_re )
		return call('magit#open_close_folding', a:000)
	else
		silent! execute "silent! normal! " . a:mapping
	endif
endfunction

" magit#open_close_folding()
" param[in] visible : boolean, force visible value. If not set, toggle
" visibility
function! magit#open_close_folding(...)
	let list = matchlist(getline("."), g:magit_file_re)
	if ( empty(list) )
		throw 'non file header line: ' . getline(".")
	endif
	let filename = list[2]
	let section=<SID>mg_get_section()
	" if first param is set, force visible to this value
	" else, toggle value
	let file = s:state.get_file(section, filename, 0)
	if ( a:0 == 1 )
		call file.set_visible(a:1)
	else
		call file.toggle_visible()
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
	if ( @% != g:magit_buffer_name )
		echoerr "Not in magit buffer " . g:magit_buffer_name . " but in " . @%
		return
	endif
	" FIXME: find a way to save folding state. According to help, this won't
	" help:
	" > This does not save fold information.
	" Playing with foldenable around does not help.
	" mkview does not help either.
	let l:winview = winsaveview()

	" remove all signs (needed as long as we wipe buffer)
	call magit#sign#remove_all()
	
	" delete buffer
	silent! execute "silent :%delete _"
	
	call <SID>mg_get_info()
	call <SID>mg_section_help('global')
	if ( s:magit_commit_mode != '' )
		call <SID>mg_get_commit_section()
	endif
	call s:state.update()

	if ( s:state.nb_diff_lines > g:magit_warning_max_lines && b:magit_warning_answered_yes == 0 )
		let ret = input("There are " . s:state.nb_diff_lines . " diff lines to display. Do you want to display all diffs? y(es) / N(o) : ", "")
		if ( ret !~? '^y\%(e\%(s\)\?\)\?$' )
			let b:magit_default_show_all_files = 0
			call s:state.set_files_visible(0)
		else
			let b:magit_warning_answered_yes = 1
		endif
	endif

	call <SID>mg_get_staged_section('staged')
	call <SID>mg_get_staged_section('unstaged')
	call <SID>mg_get_stashes()

	call winrestview(l:winview)

	if ( s:magit_commit_mode != '' )
		let commit_section_pat_start='^'.g:magit_sections.commit_start.'$'
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
" param[in] display:
"     'v': vertical split
"     'h': horizontal split
"     'c': current buffer (should be used when opening vim in vimagit mode
function! magit#show_magit(display, ...)
	if ( magit#utils#strip(system("git rev-parse --is-inside-work-tree")) != 'true' )
		echoerr "Magit must be started from a git repository"
		return
	endif
	if ( a:display == 'v' )
		vnew 
	elseif ( a:display == 'h' )
		new 
	elseif ( a:display == 'c' )
		"nothing, use current buffer
	else
		throw 'parameter_error'
	endif

	let b:magit_default_show_all_files = g:magit_default_show_all_files
	let b:magit_default_fold_level = g:magit_default_fold_level
	let b:magit_warning_answered_yes = 0

	if ( a:0 > 0 )
		let b:magit_default_show_all_files = a:1
	endif
	if ( a:0 > 1 )
		let b:magit_default_fold_level = a:2
	endif

	silent! execute "bdelete " . g:magit_buffer_name
	execute "file " . g:magit_buffer_name

	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal foldmethod=syntax
	let &l:foldlevel = b:magit_default_fold_level
	setlocal filetype=magit
	"setlocal readonly

	call magit#utils#setbufnr(bufnr(g:magit_buffer_name))
	call magit#sign#init()

	execute "nnoremap <buffer> <silent> " . g:magit_stage_file_mapping .   " :call magit#stage_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping .   " :call magit#stage_hunk(0)<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_discard_hunk_mapping . " :call magit#stage_hunk(1)<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_reload_mapping .       " :call magit#update_buffer()<cr>"
	execute "cnoremap <buffer> <silent> " . g:magit_commit_mapping_command." :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_mapping .       " :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_amend_mapping . " :call magit#commit_command('CA')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_fixup_mapping . " :call magit#commit_command('CF')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_ignore_mapping .       " :call magit#ignore_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_close_mapping .        " :close<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_toggle_help_mapping .  " :call magit#toggle_help()<cr>"

	execute "nnoremap <buffer> <silent> " . g:magit_stage_line_mapping .   " :call magit#stage_vselect()<cr>"
	execute "xnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping .   " :call magit#stage_vselect()<cr>"
	
	execute "nnoremap <buffer> <silent> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"
	execute "xnoremap <buffer> <silent> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"
	
	for mapping in g:magit_folding_toggle_mapping
		" trick to pass '<cr>' in a mapping command without being interpreted
		let func_arg = ( mapping ==? "<cr>" ) ? '+' : mapping
		execute "nnoremap <buffer> <silent> " . mapping . " :call magit#open_close_folding_wrapper('" . func_arg . "')<cr>"
	endfor
	for mapping in g:magit_folding_open_mapping
		execute "nnoremap <buffer> <silent> " . mapping . " :call magit#open_close_folding_wrapper('" . mapping . "', 1)<cr>"
	endfor
	for mapping in g:magit_folding_close_mapping
		execute "nnoremap <buffer> <silent> " . mapping . " :call magit#open_close_folding_wrapper('" . mapping . "', 0)<cr>"
	endfor
	
	call magit#update_buffer()
	execute "normal! gg"
endfunction

function! s:mg_select_closed_file()
	if ( getline(".") =~ g:magit_file_re )
		let list = matchlist(getline("."), g:magit_file_re)
		let filename = list[2]
		let section=<SID>mg_get_section()
		
		let file = s:state.get_file(section, filename)
		if ( file.is_visible() == 0 ||
			\ file.is_dir() == 1 )
			let selection = s:state.get_file(section, filename).get_flat_hunks()
			return selection
		endif
	endif
	throw "out_of_block"
endfunction

" magit#stage_block: this function (un)stage a block, according to parameter
" INFO: in unstaged section, it stages the hunk, and in staged section, it
" unstages the hunk
" param[in] block_type: can be 'file' or 'hunk'
" param[in] discard: boolean, if true, discard instead of (un)stage
" return: no
function! magit#stage_block(selection, discard) abort
	let section=<SID>mg_get_section()
	let filename=<SID>mg_get_filename()
	let header = s:state.get_file(section, filename).get_header()
	
	let file = s:state.get_file(section, filename, 0)
	if ( a:discard == 0 )
		if ( section == 'unstaged' )
			if ( file.must_be_added() )
				call magit#utils#system('git add ' .
					\ magit#utils#add_quotes(filename))
			else
				call <SID>mg_git_apply(header, a:selection)
			endif
		elseif ( section == 'staged' )
			if ( file.must_be_added() )
				call magit#utils#system('git reset ' .
					\ magit#utils#add_quotes(filename))
			else
				call <SID>mg_git_unapply(header, a:selection, 'staged')
			endif
		else
			echoerr "Must be in \"" . 
						\ g:magit_sections.staged . "\" or \"" . 
						\ g:magit_sections.unstaged . "\" section"
		endif
	else
		if ( section == 'unstaged' )
			if ( file.must_be_added() )
				call delete(filename)
			else
				call <SID>mg_git_unapply(header, a:selection, 'unstaged')
			endif
		else
			echoerr "Must be in \"" . 
						\ g:magit_sections.unstaged . "\" section"
		endif
	endif

	call magit#update_buffer()
endfunction

" magit#stage_file: this function (un)stage a whole file, from the current
" cursor position
" INFO: in unstaged section, it stages the file, and in staged section, it
" unstages the file
" return: no
function! magit#stage_file()
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		let [start, end] = <SID>mg_select_file_block()
		let selection = getline(start, end)
	endtry
	return magit#stage_block(selection, 0)
endfunction
"
" magit#stage_hunk: this function (un)stage/discard a hunk, from the current
" cursor position
" INFO: in unstaged section, it stages the hunk, and in staged section, it
" unstages the hunk
" param[in] discard:
"     - when set to 0, (un)stage
"     - when set to 1, discard
" return: no
function! magit#stage_hunk(discard)
	try
		let selection = <SID>mg_select_closed_file()
	catch 'out_of_block'
		try
			let [start,end] = <SID>mg_select_hunk_block()
		catch 'out_of_block'
			let [start,end] = <SID>mg_select_file_block()
		endtry
		let marked_lines = magit#sign#find_stage_signs(start, end)
		if ( empty(marked_lines) )
			let selection = getline(start, end)
		else
			let selection = <SID>mg_create_diff_from_select(
						\ map(keys(marked_lines), 'str2nr(v:val)'))
			call magit#sign#remove_signs(marked_lines)
		endif
	endtry
	return magit#stage_block(selection, a:discard)
endfunction

" magit#stage_vselect: this function (un)stage text being sectected in Visual
" mode
" remarks: it works with full lines, and can not span over multiple chunks
" INFO: in unstaged section, it stages the file, and in staged section, it
" unstages the file
" return: no
function! magit#stage_vselect() range
	" func-range a:firstline a:lastline seems to work at least from vim 7.2
	let lines = []
	let curline = a:firstline
	while ( curline <= a:lastline )
		call add(lines, curline)
		let curline += 1
	endwhile
	let selection = <SID>mg_create_diff_from_select(lines)
	return magit#stage_block(selection, 0)
endfunction

" magit#mark_vselect: wrapper function to mark selected lines (see
" mg_mark_lines_in_hunk)
function! magit#mark_vselect() range
	return <SID>mg_mark_lines_in_hunk(a:firstline, a:lastline)
endfunction

" magit#ignore_file: this function add the file under cursor to .gitignore
" FIXME: git diff adds some strange characters to end of line
function! magit#ignore_file() abort
	let ignore_file=<SID>mg_get_filename()
	call magit#utils#append_file(magit#utils#top_dir() . ".gitignore",
			\ [ ignore_file ] )
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

command! Magit call magit#show_magit('v')

" }}}
