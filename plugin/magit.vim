scriptencoding utf-8

if exists('g:loaded_magit') || !executable('git') || &cp
  finish
endif
let g:loaded_magit = 1

let g:vimagit_version = [1, 7, 3]

" Initialisation {{{

" FIXME: find if there is a minimum vim version required
" if v:version < 703
" endif

" source common file. variables in common file are shared with plugin and
" syntax files
let g:vimagit_path = fnameescape(resolve(expand('<sfile>:p:h')))
execute 'source ' . g:vimagit_path . '/../common/magit_common.vim'

" these mappings are broadly applied, for all vim buffers
let g:magit_show_magit_mapping     = get(g:, 'magit_show_magit_mapping',        '<leader>M' )

" user options
let g:magit_enabled                = get(g:, 'magit_enabled',                   1)
let g:magit_show_help              = get(g:, 'magit_show_help',                 0)
let g:magit_default_show_all_files = get(g:, 'magit_default_show_all_files',    1)
let g:magit_default_fold_level     = get(g:, 'magit_default_fold_level',        1)
let g:magit_auto_close             = get(g:, 'magit_auto_close',                0)
let g:magit_auto_foldopen            = get(g:, 'magit_auto_foldopen',               1)
let g:magit_default_sections       = get(g:, 'magit_default_sections',          ['info', 'global_help', 'commit', 'staged', 'unstaged'])
let g:magit_discard_untracked_do_delete = get(g:, 'magit_discard_untracked_do_delete',        0)

let g:magit_refresh_gutter         = get(g:, 'magit_refresh_gutter'   ,         1)
" Should deprecate the following
let g:magit_refresh_gitgutter      = get(g:, 'magit_refresh_gitgutter',         0)

let g:magit_commit_title_limit     = get(g:, 'magit_commit_title_limit',        50)

let g:magit_scrolloff              = get(g:, 'magit_scrolloff',                 3)

let g:magit_warning_max_lines      = get(g:, 'magit_warning_max_lines',         10000)

let g:magit_git_cmd                = get(g:, 'magit_git_cmd'          ,         "git")

execute "nnoremap <silent> " . g:magit_show_magit_mapping . " :call magit#show_magit('v')<cr>"

if (g:magit_refresh_gutter == 1 || g:magit_refresh_gitgutter == 1)
  autocmd User VimagitUpdateFile
    \ if ( exists("*gitgutter#process_buffer") ) |
    \   call gitgutter#process_buffer(bufnr(g:magit_last_updated_buffer), 0) |
    \ elseif ( exists("*sy#util#refresh_windows") ) |
    \   call sy#util#refresh_windows() |
    \ endif
endif
" }}}

" s:mg_cut_str cut a string given a limit size
" param[in] str string to cut
" param[in] limit maximum number of column
" return string cut on limit
function! s:mg_cut_str(str, limit)
	if ( len(a:str) < a:limit )
		return a:str
	elseif ( ( a:limit - 3 ) < 0 )
		return ""
	else
		return printf("%.*s...", a:limit - 3, a:str)
	endif
endfunction

" s:mg_get_info: this function writes in current buffer current git state
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_info()
	let align_w=12

	let repo_line=printf("%-*s %s",
				\ align_w,
				\ g:magit_section_info.cur_repo,
				\ magit#git#top_dir())

	try
		let head_br=magit#git#get_branch_name("HEAD")
	catch 'shell_error'
		let head_br="Empty repository"
	endtry
	let upstream_br=magit#git#get_remote_branch("HEAD", "upstream")
	let push_br=magit#git#get_remote_branch("HEAD", "push")
	let max_br_w = max([len(head_br), len(upstream_br), len(push_br)])

	let limit=winwidth(0)-align_w-max_br_w-3
	let head_msg=s:mg_cut_str(magit#git#get_commit_subject("HEAD"), limit)
	let upstream_msg=s:mg_cut_str(magit#git#get_commit_subject(upstream_br), limit)
	let push_msg=s:mg_cut_str(magit#git#get_commit_subject(push_br), limit)

	let head_line=magit#utils#strip(printf("%-*s %-*s %s", 
				\ align_w, g:magit_section_info.cur_head,
				\ max_br_w, head_br, head_msg))
	let upstream_line=magit#utils#strip(printf("%-*s %-*s %s",
				\ align_w, g:magit_section_info.cur_upstream,
				\ max_br_w, upstream_br, upstream_msg))
	let push_line=magit#utils#strip(printf("%-*s %-*s %s",
				\ align_w, g:magit_section_info.cur_push,
				\ max_br_w, push_br, push_msg))


	silent put =g:magit_sections.info
	silent put =magit#utils#underline(g:magit_sections.info)
	silent put =''
	silent put =repo_line
	silent put =head_line
	silent put =upstream_line
	silent put =push_line

	if ( b:magit_current_commit_mode != '' )
		let commit_mode_line=printf("%-*s %s",
				\ align_w, g:magit_section_info.commit_mode,
				\ g:magit_commit_mode[b:magit_current_commit_mode])
		silent put =commit_mode_line
	endif
	silent put =''
	silent put ='Press ? to display help'
	silent put =''
	silent put =''
endfunction

" s:mg_display_files: display in current buffer files, filtered by some
" parameters
" param[in] mode: files mode, can be 'staged' or 'unstaged'
" param[in] curdir: directory containing files (only needed for untracked
" directory)
" param[in] depth: current directory depth (only needed for untracked
" directory)
function! s:mg_display_files(mode, curdir, depth)

	" FIXME: ouch, must store subdirs in more efficient way
	for filename in b:state.get_filenames(a:mode)
		let file = b:state.get_file(a:mode, filename, 0)
		if ( file.depth != a:depth || filename !~ a:curdir . '.*' )
			continue
		endif
		silent put =file.get_filename_header()
		let file.line_pos = line('.')

		if ( file.dir != 0 )
			if ( file.visible == 1 )
				call s:mg_display_files(a:mode, filename, a:depth + 1)
				continue
			endif
		endif

		if ( file.visible == 0 )
			silent put =''
			continue
		endif
		if ( file.exists == 0 )
			echoerr "Error, " . filename . " should not exists"
		endif
		let hunks = file.get_hunks()
		for hunk in hunks
			if ( hunk.header != '' )
				silent put =hunk.header
				let hunk.line_pos = line('.')
			endif
			if ( !empty(hunk.lines) )
				silent put =hunk.lines
			endif
		endfor
		silent put =''
	endfor
endfunction

" s:mg_get_staged_section: this function writes in current buffer all staged
" or unstaged files, using b:state.dict information
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] mode: 'staged' or 'unstaged'
function! s:mg_get_staged_section(mode)
	silent put =g:magit_sections[a:mode]
	call magit#mapping#get_section_help(a:mode)
	silent put =magit#utils#underline(g:magit_sections[a:mode])
	silent put =''
	call s:mg_display_files(a:mode, '', 0)
	silent put =''
endfunction

" s:mg_get_stashes: this function write in current buffer all stashes
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_stashes()
	try
		silent! let stash_list=magit#sys#systemlist(g:magit_git_cmd . " stash list")
	catch 'shell_error'
		call magit#sys#print_shell_error()
		return
	endtry

	if (!empty(stash_list))
		silent put =g:magit_sections.stash
		silent put =magit#utils#underline(g:magit_sections.stash)
		silent put =''

		for stash in stash_list
			let stash_id=substitute(stash, '^\(stash@{\d\+}\):.*$', '\1', '')
			silent put =stash
			silent! execute "read !git stash show -p " . stash_id
		endfor
		silent put =''
		silent put =''
	endif
endfunction

" b:magit_current_commit_msg: this variable store the current commit message,
" saving it among refreshes (remember? the whole buffer is wiped at each
" refresh).
let b:magit_current_commit_msg = []

" s:mg_get_commit_section: this function writes in current buffer the commit
" section. It is a commit message, depending on b:magit_current_commit_mode
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] b:magit_current_commit_mode: this function uses global commit mode
"       'CC': prepare a brand new commit message
"       'CA': get the last commit message
function! s:mg_get_commit_section()
	if ( b:magit_current_commit_mode != '' )
		silent put =g:magit_sections.commit
		silent put =magit#utils#underline(g:magit_sections.commit)

		let git_dir=magit#git#git_dir()
		" refresh the COMMIT_EDITMSG file
		if ( b:magit_current_commit_mode == 'CC' )
			silent! call magit#sys#system_noraise("GIT_EDITOR=/bin/false " .
						\ g:magit_git_cmd . " -c commit.verbose=no commit -e 2> /dev/null")
		elseif ( b:magit_current_commit_mode == 'CA' )
			silent! call magit#sys#system_noraise("GIT_EDITOR=/bin/false " .
						\ g:magit_git_cmd . " -c commit.verbose=no commit --amend -e 2> /dev/null")
		endif
		if ( !empty(b:magit_current_commit_msg) )
			silent put =b:magit_current_commit_msg
		elseif ( filereadable(git_dir . 'COMMIT_EDITMSG') )
			let comment_char=magit#git#get_config("core.commentChar", '#')
			let commit_msg=magit#utils#join_list(filter(readfile(git_dir . 'COMMIT_EDITMSG'), 'v:val !~ "^' . comment_char . '"'))
			silent put =commit_msg
		endif
		silent put =''
		silent put =''
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
" param[in]: end_pattern_on_cursor: boolean, if true end pattern is also
" search on cursor position
" return: [startline, endline]
function! s:mg_search_block(start_pattern, end_pattern, upper_limit_pattern,
			\ end_pattern_on_cursor)

	let upper_limit=0
	if ( a:upper_limit_pattern != "" )
		let upper_limit=search(a:upper_limit_pattern, "cbnW")
	endif

	let start=search(a:start_pattern[0], "cbnW")
	if ( start == 0 || start < upper_limit )
		throw "out_of_block"
	endif
	let start+=a:start_pattern[1]

	let end=0
	let min=line('$')
	for end_p in a:end_pattern
		let curr_end=search(end_p[0], a:end_pattern_on_cursor ? "c" : "" . "nW")
		if ( curr_end != 0 && curr_end <= min )
			let end=curr_end + end_p[1]
			let min=curr_end
		endif
	endfor
	if ( end == 0 )
		throw "out_of_block"
	endif

	return [start,end]
endfunction

" s:mg_get_commit_msg: get the commit meesgae currently in commit section
" return a string containg the commit message
" \param[in] out_of_block (optional): if set, will first move the cursor to
" the commit block before getting content
function! s:mg_get_commit_msg(...)
	let commit_section_pat_start='^'.g:magit_sections.commit.'$'
	" Get next section pattern with g:magit_default_sections order
	let commit_position = match(g:magit_default_sections, 'commit')
	if ( commit_position + 1 == len(g:magit_default_sections) )
	  let commit_section_pat_end='\%$'
	else
	  let commit_section_pat_end='^'.g:magit_sections[g:magit_default_sections[commit_position+1]].'$'
	endif

	let commit_jump_line = 2
	let out_of_block = a:0 == 1 ? a:1 : 0
	if ( out_of_block )
		let old_pos=line('.')
		let commit_pos=search(commit_section_pat_start, "cw")
		if ( commit_pos != 0 )
			call cursor(commit_pos+1, 0)
		endif
	endif
	try
		let [start, end] = <SID>mg_search_block(
					\ [commit_section_pat_start, commit_jump_line],
					\ [ [commit_section_pat_end, -1] ], "", 1)
	finally
		if ( out_of_block && commit_pos != 0 )
			call cursor(old_pos, 0)
		endif
	endtry
	return magit#utils#strip_array(getline(start, end))
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
		try
			silent let git_result=magit#sys#system(g:magit_git_cmd .
						\ " commit --amend -C HEAD")
		catch 'shell_error'
			call magit#sys#print_shell_error()
			echoerr "Commit fix failed"
		endtry
	else
		let commit_flag=""
		if ( a:mode != 'CA' && empty( magit#get_staged_files() ) )
			let choice = confirm(
				\ "Do you really want to commit without any staged files?",
				\ "&Yes\n&No", 2)
			if ( choice != 1 )
				return
			else
				let commit_flag.=" --allow-empty "
			endif
		endif

		let commit_msg=s:mg_get_commit_msg()
		if ( empty( commit_msg ) )
			let choice = confirm(
				\ "Do you really want to commit with an empty message?",
				\ "&Yes\n&No", 2)
			if ( choice != 1 )
				return
			else
				let commit_flag.=" --allow-empty-message "
			endif
		endif

		if ( a:mode == 'CA' )
			let commit_flag.=" --amend "
		endif
		let commit_cmd=g:magit_git_cmd . " commit " . commit_flag .
					\ " --file - "
		try
			silent! let git_result=magit#sys#system(commit_cmd, commit_msg)
		catch 'shell_error'
			call magit#sys#print_shell_error()
			echoerr "Commit failed"
		endtry
		let b:magit_current_commit_mode=''
		let b:magit_current_commit_msg=[]
	endif
	let b:magit_just_commited = 1
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
				\ [ [g:magit_end_diff_re, 0],
				\   [g:magit_file_re, -1],
				\   [g:magit_stash_re, -1],
				\   [g:magit_section_re, -2],
				\   [g:magit_bin_re, 0],
				\   [g:magit_eof_re, 0 ]
				\ ],
				\ "",
				\ 0)
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
				\   [g:magit_end_diff_re, 0],
				\   [g:magit_file_re, -1],
				\   [g:magit_stash_re, -1],
				\   [g:magit_section_re, -2],
				\   [g:magit_eof_re, 0 ]
				\ ],
				\ g:magit_file_re,
				\ 0)
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
	let section=magit#helper#get_section()
	let filename=magit#helper#get_filename()
	let hunks = b:state.get_file(section, filename).get_hunks()
	for hunk in hunks
		if ( hunk.header == getline(starthunk) )
			let current_hunk = hunk
			break
		endif
	endfor
	let selection = []
	call add(selection, current_hunk.header)

	let current_line = starthunk + 1
	" when staging by visual selection, lines out of selection must be
	" ignored. To do so, + lines are simply ignored, - lines are considered as
	" untouched.
	" For unstaging, - lines must be ignored and + lines considered untouched.
	if ( section == 'unstaged' )
		let remove_line_char = '+'
		let replace_line_char = '-'
	else
		let remove_line_char = '-'
		let replace_line_char = '+'
	endif
	for hunk_line in current_hunk.lines
		if ( index(a:select_lines, current_line) != -1 )
			call add(selection, getline(current_line))
		elseif ( hunk_line =~ '^'.remove_line_char.'.*' )
			" just ignore these lines
		elseif ( hunk_line =~ '^'.replace_line_char.'.*' )
			call add(selection, substitute(hunk_line,
						\ '^'.replace_line_char.'\(.*\)$', ' \1', ''))
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

" }}}

" {{{ User functions and commands

" magit#open_close_folding()
" param[in] visible : boolean, force visible value. If not set, toggle
" visibility
function! magit#open_close_folding(...)
	let list = matchlist(getline("."), g:magit_file_re)
	if ( empty(list) )
		throw 'non file header line: ' . getline(".")
	endif
	let filename = list[2]
	let section=magit#helper#get_section()
	" if first param is set, force visible to this value
	" else, toggle value
	let file = b:state.get_file(section, filename, 0)
	if ( a:0 == 1 )
		call file.set_visible(a:1)
	else
		call file.toggle_visible()
	endif
	call magit#update_buffer()
endfunction

let g:magit_last_updated_buffer = ''

" s:mg_display_functions: Dict wrapping all display related functions
" This Dict should be accessed through g:magit_default_sections
let s:mg_display_functions = {
	\ 'info':        { 'fn': function("s:mg_get_info"), 'arg': []},
	\ 'global_help': { 'fn': function("magit#mapping#get_section_help"), 'arg': ['global']},
	\ 'commit':      { 'fn': function("s:mg_get_commit_section"), 'arg': []},
	\ 'staged':      { 'fn': function("s:mg_get_staged_section"), 'arg': ['staged']},
	\ 'unstaged':    { 'fn': function("s:mg_get_staged_section"), 'arg': ['unstaged']},
	\ 'stash':       { 'fn': function("s:mg_get_stashes"), 'arg': []},
\ }

" magit#update_buffer: this function:
" 1. checks that current buffer is the wanted one
" 2. save window state (cursor position...)
" 3. delete buffer
" 4. fills with unstage stuff
" 5. restore window state
" param[in] updated file (optional): this filename is updated to absolute
" path, set in g:magit_last_updated_buffer and the User autocmd
" param[in] current section (optional)
" param[in] current hunk id
" when params 1 & 2 & 3 are set, it means
" that a stage/unstage action occured. We try to smartly set the cursor
" position after the refresh
"  - on current file on closest hunk if still contains hunks in current section
"  - else on next file if any
"  - else on previous file if any
"  - or cursor stay where it is
" VimagitUpdateFile event is raised
function! magit#update_buffer(...)
	let buffer_name=bufname("%")
	" (//|\\\\) is to handle old vim 7.4-0 fnameescape behavior on Windows
	if ( buffer_name !~ "\\v^magit:(//|\\\\).*" )
		echoerr "Not in magit buffer but in " . buffer_name
		return
	endif
	
	if ( a:0 >= 1 )
		let cur_filename = a:1
	endif
	if ( a:0 >= 2 )
		let cur_section = a:2
	endif
	if ( a:0 >= 3 )
		let cur_hunk_id = a:3
	endif

	if ( b:magit_current_commit_mode != '' )
		try
			let b:magit_current_commit_msg = s:mg_get_commit_msg(1)
		catch /^out_of_block$/
			let b:magit_current_commit_msg = []
		endtry
		call s:set_mode_write()
	else
		call s:set_mode_read()
	endif
	" FIXME: find a way to save folding state. According to help, this won't
	" help:
	" > This does not save fold information.
	" Playing with foldenable around does not help.
	" mkview does not help either.
	let l:winview = winsaveview()

	" remove all signs (needed as long as we wipe buffer)
	call magit#sign#remove_all()

	" remove folding while we are updating the buffer. writing to the buffer
	" while the folding is enabled can be veryyyyy slow.
	" One last strange thing is that, the first time the buffer is written, it
	" is not slow at all. It is slow the second time, at first refresh (can be
	" order of seconds). Then at third time (2nd refresh), it is fast again.
	" refs:
	" https://github.com/jreybert/vimagit/issues/170
	" https://github.com/jreybert/vimagit/issues/36 (maybe)
	setlocal foldmethod=manual
	" delete buffer
	silent! execute "silent :%delete _"

	" be smart for the cursor position after refresh, if stage/unstaged
	" occured
	if ( a:0 >= 2 )
		let filenames = b:state.get_filenames(cur_section)
		let pos = match(filenames, cur_filename)
		let next_filename = (pos < len(filenames) - 1) ? filenames[pos+1] : ''
		let prev_filename = (pos > 0) ? filenames[pos-1] : ''
	endif

	call b:state.update()

	if ( g:magit_auto_close == 1 &&
				\ b:magit_just_commited == 1 &&
				\ empty(b:state.get_filenames('staged')) &&
				\ empty(b:state.get_filenames('unstaged')) )
		let b:magit_just_commited = 0
		call magit#close_magit()
		return
	endif

	for section in g:magit_default_sections
		try
			let func = s:mg_display_functions[section]
		catch
			echohl WarningMsg
			echom 'unknown section to display: ' . section
			echom 'please check your redefinition of g:magit_default_sections'
			echohl None
		endtry
		call call(func.fn, func.arg)
	endfor

	call winrestview(l:winview)

	call magit#utils#clear_undo()

	setlocal filetype=magit
	setlocal foldmethod=syntax

	if ( b:magit_current_commit_mode != '' && b:magit_commit_newly_open == 1 )
		let commit_section_pat_start='^'.g:magit_sections.commit.'$'
		silent! let section_line=search(commit_section_pat_start, "w")
		silent! call cursor(section_line+2+magit#mapping#get_section_help_line_nb('commit'), 0)
		if exists('#User#VimagitEnterCommit')
			doautocmd User VimagitEnterCommit
		endif
		let b:magit_commit_newly_open = 0
	endif

	let g:magit_last_updated_buffer = ''
	if ( a:0 >= 1 )
		let abs_filename = magit#git#top_dir() . cur_filename
		if ( bufexists(abs_filename) )
			let g:magit_last_updated_buffer = abs_filename
			if exists('#User#VimagitUpdateFile')
				doautocmd User VimagitUpdateFile
			endif
		endif
	endif

	if exists('#User#VimagitRefresh')
		doautocmd User VimagitRefresh
	endif

	if ( a:0 >= 3 )
		if (b:state.get_files_nb(cur_section) > 0)
			" if, in this order, current file, next file, previous file exists in
			" current section, move cursor to it
			let cur_file = 1
			for fname in [cur_filename, next_filename, prev_filename]
				try
					let file = b:state.get_file(cur_section, fname)
					if ( cur_file )
						let hunk_id = max([0, min([len(file.get_hunks())-1, cur_hunk_id])])
						let cur_file = 0
					else
						let hunk_id = 0
					endif

					if ( file.is_visible() )
						call cursor(file.get_hunks()[hunk_id].line_pos, 0)
						if ( g:magit_auto_foldopen )
							foldopen
						endif
					else
						call cursor(file.line_pos, 0)
					endif
					break
				catch 'file_doesnt_exists'
				endtry
			endfor
		else
			" if current section is empty, move cursor to top to other section
			if (cur_section == 'staged')
				let cur_section = 'unstaged'
			elseif (cur_section == 'unstaged')
				let cur_section = 'staged'
			endif
			let section_line=search(g:magit_sections[cur_section], "bnw")
			call cursor(section_line, 0)
		endif
		silent execute "normal! zt"
	endif

	if exists(':AirlineRefresh')
		execute "AirlineRefresh"
	endif

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
	if ( &filetype == 'netrw' )
		let cur_file = ""
		let cur_file_path = b:netrw_curdir
	else
		let cur_file = expand("%:p")
		let cur_file_path = isdirectory(cur_file) ? cur_file : fnamemodify(cur_file, ":h")
	endif

	let git_dir=''
	let try_paths = [ cur_file_path, getcwd() ]
	for path in try_paths
		let git_dir=magit#git#is_work_tree(path)
		if ( git_dir != '' )
			break
		endif
	endfor

	if ( git_dir == '' )
		echohl ErrorMsg
		echom "magit can not find any git repository"
		echohl None
		echom "make sure that current opened file or vim current directory points to a git repository"
		echom "search paths:"
		for path in try_paths
			echom path
		endfor
		return
	endif

	let buffer_name=fnameescape('magit://' . git_dir)

	let magit_win = magit#utils#search_buffer_in_windows(buffer_name)

	if ( magit_win != 0 )
		silent execute magit_win."wincmd w"
	elseif ( a:display == 'v' )
		silent execute "vnew " . buffer_name
		" next is a workaround for vader, revert as soon as vader bug is fixed
		" https://github.com/junegunn/vader.vim/issues/135
		silent execute "buffer " . buffer_name
		let b:magit_only = 0
	elseif ( a:display == 'h' )
		silent execute "new " . buffer_name
		let b:magit_only = 0
	elseif ( a:display == 'c' )
		if ( !bufexists(buffer_name) )
			if ( bufname("%") == "" )
				silent keepalt enew
			else
				silent enew
			endif
			silent execute "file " . buffer_name
		else
			silent execute "buffer " . buffer_name
		endif
		let b:magit_only = 1
	else
		throw 'parameter_error'
	endif

	call magit#git#set_top_dir(git_dir)

	let b:magit_default_show_all_files = g:magit_default_show_all_files
	let b:magit_default_fold_level = g:magit_default_fold_level
	let b:magit_warning_max_lines_answered = 0

	if ( a:0 > 0 )
		let b:magit_default_show_all_files = a:1
	endif
	if ( a:0 > 1 )
		let b:magit_default_fold_level = a:2
	endif

	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	setlocal foldmethod=syntax
	setlocal foldnestmax=20
	setlocal nobuflisted
	setlocal nomodeline
	let &l:foldlevel = b:magit_default_fold_level
	setlocal filetype=magit
	if ( g:magit_scrolloff != -1 )
		if ( has("patch-8.1.0864") )
			let &l:scrolloff = g:magit_scrolloff
		else
			let s:default_scrolloff=&scrolloff
			" ugly hack, scrolloff is a global only option before patch 8.1.0864
			execute "autocmd BufLeave " . buffer_name . " :set scrolloff=" . s:default_scrolloff
			execute "autocmd BufEnter " . buffer_name . " :set scrolloff=" . g:magit_scrolloff
			let &scrolloff = g:magit_scrolloff
		endif
	endif

	augroup vimagit_buffer
	autocmd!
	" catch write command
	execute "autocmd BufWriteCmd " . buffer_name . " :call magit#commit_command('CC')"

	" let magit buffer in read mode when cursor is not in file, to avoid
	" unfortunate commit with a :wall command out of magit buffer if a commit
	" message is ongoing
	execute "autocmd BufEnter " . buffer_name . "
	      \ :if ( exists('b:magit_current_commit_mode') &&
	      \ b:magit_current_commit_mode != '' ) |
	      \   call s:set_mode_write() |
	      \ endif"
	execute "autocmd BufLeave " . buffer_name . "
	      \ :if ( exists('b:magit_current_commit_mode') &&
	      \ b:magit_current_commit_mode != '' ) |
	      \   call s:set_mode_read() |
	      \ endif"
	augroup END

	" s:magit_commit_mode: global variable which states in which commit mode we are
	" values are:
	"       '': not in commit mode
	"       'CC': normal commit mode, next commit command will create a new commit
	"       'CA': amend commit mode, next commit command will ament current commit
	"       'CF': fixup commit mode, it should not be a global state mode
	let b:magit_current_commit_mode=''
	let b:magit_commit_newly_open=0

	let b:magit_diff_context=3

	let b:magit_just_commited = 0

	if ( magit#git#check_repo() != 0 )
		echohl ErrorMsg
		echom "git repository seems to be corrupted"
		echohl None
		echom "To be safe, vimagit ends now"
		echom "Check your repository health with git fsck"
		echom "If the result shows no problem, open an issue"
		return
	endif

	let b:state = deepcopy(g:magit#state#state)
	call magit#utils#setbufnr(bufnr(buffer_name))
	call magit#sign#init()

	call magit#mapping#set_default()

	if exists('#User#VimagitBufferInit')
		doautocmd User VimagitBufferInit
	endif

	call magit#update_buffer()

	function! s:jump_first_file()
		let unstaged_files = b:state.get_files_ordered('unstaged')
		if ( !empty(unstaged_files) )
			call cursor(unstaged_files[0].line_pos, 0)
		else
			let staged_files = b:state.get_files_ordered('staged')
			if ( !empty(staged_files) )
				call cursor(staged_files[0].line_pos, 0)
			endif
		endif
	endfunction
	" move cursor to (in priority order if not found):
	"  - current file unstaged
	"  - current file staged
	"  - first unstaged file
	"  - first stage file
	let cur_filename = matchlist(cur_file, git_dir . '\(.*\)')
	if ( !empty(cur_filename) )
		let cur_file = cur_filename[1]
		try
			let file = b:state.get_file('unstaged', cur_file, 0)
			call cursor(file.line_pos, 0)
		catch 'file_doesnt_exists'
			try
				let file = b:state.get_file('staged', cur_file, 0)
				call cursor(file.line_pos, 0)
			catch 'file_doesnt_exists'
				call s:jump_first_file()
			endtry
		endtry
	else
		call s:jump_first_file()
	endif

endfunction

function! magit#close_magit()
	if ( b:magit_only == 0 )
		close
	else
		try
			edit #
		catch /^Vim\%((\a\+)\)\=:E\%(194\|499\)/
			try
				close
			catch /^Vim\%((\a\+)\)\=:E444/
				quit
			endtry
		endtry
	endif
endfunction

function! s:mg_stage_closed_file(discard)
	if ( getline(".") =~ g:magit_file_re )
		let list = matchlist(getline("."), g:magit_file_re)
		let filename = list[2]
		let section=magit#helper#get_section()
		
		let file = b:state.get_file(section, filename)
		if ( file.is_visible() == 0 ||
			\ file.is_dir() == 1 )
			if ( a:discard == 0 )
				if ( section == 'unstaged' )
					call magit#git#git_add(magit#utils#add_quotes(filename))
				elseif ( section == 'staged' )
					call magit#git#git_reset(magit#utils#add_quotes(filename))
				else
					echoerr "Must be in \"" .
								\ g:magit_sections.staged . "\" or \"" .
								\ g:magit_sections.unstaged . "\" section"
				endif
			else
				if ( section == 'unstaged' )
					if ( file.status == '?' || file.must_be_added() )
						if ( g:magit_discard_untracked_do_delete == 1 )
							if ( delete(filename, "rf") != 0 )
								echoerr "Can not delete \"" . filename . "\""
								return
							endif
						else
							echohl WarningMsg
							echomsg "By default, vimagit won't discard "
								\ "untracked file (which means delete this file)"
							echomsg "You can force this behaviour, "
								\ "setting g:magit_discard_untracked_do_delete=1"
							echohl None
							return
						endif
					else
						call magit#git#git_checkout(magit#utils#add_quotes(filename))
					endif
				else
					echohl WarningMsg
					echomsg "Can not discard file in \"" .
								\ g:magit_sections.staged . "\" section, "
								\ "unstage file first."
					echohl None
					return
				endif
			endif

			call magit#update_buffer(filename, section, 0)

			return
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
	let section=magit#helper#get_section()
	let filename=magit#helper#get_filename()

	let file = b:state.get_file(section, filename, 0)
	let header = file.get_header()

	" find current hunk position in file matching against current selection
	" header
	try
		let hunk_id = match(map(deepcopy(file.get_hunks()), 'v:val.header'), "\\V" . a:selection[0])
	catch /^Vim\%((\a\+)\)\=:E874/
		echoerr "Escape issue with '" . a:selection[0] ."'"
		return
	endtry


	if ( a:discard == 0 )
		if ( section == 'unstaged' )
			if ( file.must_be_added() )
				call magit#git#git_add(magit#utils#add_quotes(filename))
			else
				call magit#git#git_apply(header, a:selection)
			endif
		elseif ( section == 'staged' )
			if ( file.must_be_added() )
				call magit#git#git_reset(magit#utils#add_quotes(filename))
			else
				call magit#git#git_unapply(header, a:selection, 'staged')
			endif
		else
			echoerr "Must be in \"" .
						\ g:magit_sections.staged . "\" or \"" .
						\ g:magit_sections.unstaged . "\" section"
		endif
	else
		if ( section == 'unstaged' )
			if ( file.status == '?' || file.must_be_added() )
				if ( g:magit_discard_untracked_do_delete == 1 )
					if ( delete(filename, "rf") != 0 )
						echoerr "Can not delete \"" . filename . "\""
						return
					endif
				else
					echohl WarningMsg
					echomsg "By default, vimagit won't discard "
								\ "untracked file (which means delete this file)"
					echomsg "You can force this behaviour, "
								\ "setting g:magit_discard_untracked_do_delete=1"
					echohl None
					return
				endif
			else
				call magit#git#git_unapply(header, a:selection, 'unstaged')
			endif
		else
			echoerr "Must be in \"" .
						\ g:magit_sections.unstaged . "\" section"
		endif
	endif

	call magit#update_buffer(filename, section, hunk_id)

endfunction

" magit#stage_file: this function (un)stage a whole file, from the current
" cursor position
" INFO: in unstaged section, it stages the file, and in staged section, it
" unstages the file
" return: no
function! magit#stage_file()
	try
		call <SID>mg_stage_closed_file(0)
		return
	catch 'out_of_block'
		try
			let [start, end] = <SID>mg_select_file_block()
		catch /^out_of_block$/
			echohl ErrorMsg
			echomsg "Error while staging."
			echohl None
			echomsg "Your cursor must be:"
			echomsg " - on a file header line"
			echomsg " - or on a hunk header line"
			echomsg " - or within a hunk"
			echomsg "If you repect one of previous points, please open a new issue:"
			echomsg "https://github.com/jreybert/vimagit/issues/new"
			return
		endtry
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
		call <SID>mg_stage_closed_file(a:discard)
		return
	catch 'out_of_block'
		try
			let [start,end] = <SID>mg_select_hunk_block()
		catch 'out_of_block'
			try
				let [start,end] = <SID>mg_select_file_block()
			catch /^out_of_block$/
				echohl ErrorMsg
				echomsg "Error while staging."
				echohl None
				echomsg "Your cursor must be:"
				echomsg " - on a file header line"
				echomsg " - or on a hunk header line"
				echomsg " - or within a hunk"
				echomsg "If you repect one of previous points, please open a new issue:"
				echomsg "https://github.com/jreybert/vimagit/issues/new"
				return
			endtry
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
	try
		let selection = <SID>mg_create_diff_from_select(lines)
	catch /^out_of_block$/
		echohl ErrorMsg
		echomsg "Error while staging a visual selection."
		echohl None
		echomsg "Visual selection staging has currently some limitations:"
		echomsg " - selection must be limited within a single hunk"
		echomsg " - only work for staging, not for unstaging"
		echomsg "If you repect current limitations, please open a new issue:"
		echomsg "https://github.com/jreybert/vimagit/issues/new"
		return
	endtry
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
	let ignore_file=magit#helper#get_filename()
	call magit#utils#append_file(magit#git#top_dir() . ".gitignore",
			\ [ ignore_file ] )
	call magit#update_buffer()
endfunction

" set magit buffer in write mode
function! s:set_mode_write()
	setlocal buftype=acwrite
endfunction

" set magit buffer in read only mode
function! s:set_mode_read()
	setlocal buftype=nofile
endfunction

" magit#commit_command: entry function for commit mode
" INFO: it has a different effect if current section is commit section or not
" param[in] mode: commit mode
"   'CF': do not set global b:magit_current_commit_mode, directly call magit#git_commit
"   'CA'/'CF': if in commit section mode, call magit#git_commit, else just set
"   global state variable b:magit_current_commit_mode,
function! magit#commit_command(mode)
	if ( a:mode == 'CF' )
		call <SID>mg_git_commit(a:mode)
	else
		let section=magit#helper#get_section()
		if ( section == 'commit' &&
\			!(b:magit_current_commit_mode == 'CC' && a:mode == 'CA' ) )
			if ( b:magit_current_commit_mode == '' )
				echoerr "Error, commit section should not be enabled"
				return
			endif
			" when we do commit, it is prefered ot commit the way we prepared it
			" (.i.e normal or amend), whatever we commit with CC or CA.
			call <SID>mg_git_commit(b:magit_current_commit_mode)
			if exists('#User#VimagitLeaveCommit')
				doautocmd User VimagitLeaveCommit
			endif
		else
			let b:magit_current_commit_mode=a:mode
			let b:magit_commit_newly_open=1
			call s:set_mode_write()
			setlocal nomodified
		endif
	endif
	call magit#update_buffer()
endfunction

" magit#close_commit: cancel for commit mode
" close commit section if opened
function! magit#close_commit()
  if ( b:magit_current_commit_mode == '' )
    return
  endif

  let git_dir=magit#git#git_dir()
  let commit_editmsg=git_dir . 'COMMIT_EDITMSG'
  if ( filereadable(commit_editmsg) )
    let commit_msg=s:mg_get_commit_msg()
    call writefile(commit_msg, commit_editmsg)
  endif

  let b:magit_current_commit_mode=''
  let b:magit_current_commit_msg=[]
  if exists('#User#VimagitLeaveCommit')
	  doautocmd User VimagitLeaveCommit
  endif
  call magit#update_buffer()
endfunction

" magit#jump_hunk: function to jump among hunks
" it closes the current fold (if any), jump to next hunk and unfold it
" param[in] dir: can be 'N' (for next) or 'P' (for previous)
function! magit#jump_hunk(dir)
	let back = ( a:dir == 'P' ) ? 'b' : ''
	let line = search('\%(^@@ \|' . g:magit_file_re . '\)', back . 'wn')
	if ( line != 0 )
		if ( foldlevel(line('.')) == 2 )
			try
				foldclose
			catch /^Vim\%((\a\+)\)\=:E490/
			endtry
		endif
		call cursor(line, 0)

		if ( foldlevel(line('.')) == 0 )
			return
		endif
		" if current line if an header file of an open file, go next
		if ( foldlevel(line('.')) == 1 )
			let line = search('\%(^@@ \|' . g:magit_file_re . '\)', back . 'wn')
			call cursor(line, 0)
		endif
		while ( foldclosed(line) != -1 )
			try
				foldopen
			catch /^Vim\%((\a\+)\)\=:E490/
				break
			endtry
		endwhile
		silent execute "normal! zt"
	endif
endfunction

" magit#get_staged_files: function returning an array with staged files names
" return: an array with staged files names
function! magit#get_staged_files()
	return keys(b:state.dict.staged)
endfunction

" magit#get_staged_files: function returning an array with unstaged files
" names
" return: an array with unstaged files names
function! magit#get_unstaged_files()
	return keys(b:state.dict.unstaged)
endfunction

" magit#jump_to: function to move cursor to the file location of the current
" hunk
" if this file is already displayed in a window, jump to the window, if not,
" jump to last window and open buffer, at the beginning of the hunk
function! magit#jump_to()
	let section=magit#helper#get_section()
	let filename=fnameescape(magit#git#top_dir() . magit#helper#get_filename())
	let header_line_nb=magit#helper#get_hunkheader_line_nb()

	let line_in_file=substitute(getline(header_line_nb),
				\ '^@@ -\d\+,\d\+ +\(\d\+\),\d\+ @@.*$', '\1', "")

	" header_line_nb+2: +2 because we skip the header and the fist line
	let hunk_extract=getline(header_line_nb+2, line('.'))
	let line_in_hunk = len(filter(hunk_extract, 'v:val =~ "^[ +]"'))
	let line_in_file += line_in_hunk

	" winnr('#') is overwritten by magit#get_win()
	let last_win = winnr('#')
	let buf_win = magit#utils#search_buffer_in_windows(filename)
	let buf_win = ( buf_win == 0 ) ? last_win : buf_win
	if ( buf_win == 0 || winnr('$') == 1 )
		rightbelow vnew
	else
		execute buf_win."wincmd w"
	endif

	try
		execute "edit " . "+" . line_in_file . " " filename
	catch
		if ( v:exception == 'Vim:Interrupt' && buf_win == 0)
			close
		elseif ( v:exception != 'Vim(edit):E325: ATTENTION' )
			throw v:exception
		endif
	endtry
endfunction

function! magit#update_diff(way)
	if ( a:way == "+" )
		let b:magit_diff_context+=1
	elseif ( a:way == "0" )
		let b:magit_diff_context=3
	elseif ( b:magit_diff_context > 1 )
		let b:magit_diff_context-=1
	endif
  call magit#update_buffer()
endfunction

function! magit#show_version()
	return g:vimagit_version[0] . "." .
				\ g:vimagit_version[1] . "." .
				\ g:vimagit_version[2]
endfunction

function! magit#get_current_mode()
	if ( b:magit_current_commit_mode == '' )
		return "STAGING"
	elseif ( b:magit_current_commit_mode == 'CC' )
		return "COMMIT"
	elseif ( b:magit_current_commit_mode == 'CA' )
		return "AMEND"
	endif
endfunction

command! Magit call magit#show_magit('v')
command! MagitOnly call magit#show_magit('c')

" }}}
