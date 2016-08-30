scriptencoding utf-8

if exists('g:loaded_magit') || !executable('git') || &cp
  finish
endif
let g:loaded_magit = 1

let g:vimagit_version = [1, 6, 0]

" Initialisation {{{

" FIXME: find if there is a minimum vim version required
" if v:version < 703
" endif

" source common file. variables in common file are shared with plugin and
" syntax files
execute 'source ' . resolve(expand('<sfile>:p:h')) . '/../common/magit_common.vim'

" these mappings are broadly applied, for all vim buffers
let g:magit_show_magit_mapping     = get(g:, 'magit_show_magit_mapping',        '<leader>M' )

" these mapping are applied locally, for magit buffer only
let g:magit_stage_file_mapping     = get(g:, 'magit_stage_file_mapping',        'F' )
let g:magit_stage_hunk_mapping     = get(g:, 'magit_stage_hunk_mapping',        'S' )
let g:magit_stage_line_mapping     = get(g:, 'magit_stage_line_mapping',        'L' )
let g:magit_mark_line_mapping      = get(g:, 'magit_mark_line_mapping',         'M' )
let g:magit_discard_hunk_mapping   = get(g:, 'magit_discard_hunk_mapping',      'DDD' )
let g:magit_commit_mapping         = get(g:, 'magit_commit_mapping',            'CC' )
let g:magit_commit_amend_mapping   = get(g:, 'magit_commit_amend_mapping',      'CA' )
let g:magit_commit_fixup_mapping   = get(g:, 'magit_commit_fixup_mapping',      'CF' )
let g:magit_close_commit_mapping   = get(g:, 'magit_close_commit_mapping',      'CU' )
let g:magit_reload_mapping         = get(g:, 'magit_reload_mapping',            'R' )
let g:magit_edit_mapping           = get(g:, 'magit_edit_mapping',              'E' )
let g:magit_ignore_mapping         = get(g:, 'magit_ignore_mapping',            'I' )
let g:magit_close_mapping          = get(g:, 'magit_close_mapping',             'q' )
let g:magit_toggle_help_mapping    = get(g:, 'magit_toggle_help_mapping',       '?' )

let g:magit_folding_toggle_mapping = get(g:, 'magit_folding_toggle_mapping',    [ '<CR>' ])
let g:magit_folding_open_mapping   = get(g:, 'magit_folding_open_mapping',      [ 'zo', 'zO' ])
let g:magit_folding_close_mapping  = get(g:, 'magit_folding_close_mapping',     [ 'zc', 'zC' ])

let g:magit_jump_next_hunk         = get(g:, 'magit_jump_next_hunk',            'N')
let g:magit_jump_prev_hunk         = get(g:, 'magit_jump_prev_hunk',            'P')
" user options
let g:magit_enabled                = get(g:, 'magit_enabled',                   1)
let g:magit_show_help              = get(g:, 'magit_show_help',                 0)
let g:magit_default_show_all_files = get(g:, 'magit_default_show_all_files',    1)
let g:magit_default_fold_level     = get(g:, 'magit_default_fold_level',        1)
let g:magit_default_sections       = get(g:, 'magit_default_sections',          ['info', 'global_help', 'commit', 'staged', 'unstaged'])
let g:magit_discard_untracked_do_delete = get(g:, 'magit_discard_untracked_do_delete',        0)

let g:magit_refresh_gitgutter      = get(g:, 'magit_refresh_gitgutter',         1)
let g:magit_warning_max_lines      = get(g:, 'magit_warning_max_lines',         10000)

let g:magit_git_cmd                = get(g:, 'magit_git_cmd'          ,         "git")

execute "nnoremap <silent> " . g:magit_show_magit_mapping . " :call magit#show_magit('v')<cr>"

if ( g:magit_refresh_gitgutter == 1 )
	autocmd User VimagitUpdateFile
			\ if ( exists("*gitgutter#process_buffer") ) |
			\ 	call gitgutter#process_buffer(bufnr(g:magit_last_updated_buffer), 0) |
			\ endif
endif
" }}}

" {{{ Internal functions

" s:magit_inline_help: Dict containing inline help for each section
let s:magit_inline_help = {
			\ 'staged': [
\g:magit_stage_hunk_mapping
\.'      if cursor on filename header, unstage file',
\'       if cursor in hunk, unstage hunk',
\g:magit_stage_file_mapping
\.'      if cursor on filename header or hunk, unstage whole file',
\],
			\ 'unstaged': [
\g:magit_stage_hunk_mapping
\.'      if cursor on filename header, stage file',
\'       if cursor in hunk, stage hunk',
\'       if visual selection in hunk (with v), stage selection',
\'       if lines marked in hunk (with M), stage marked lines',
\g:magit_stage_line_mapping
\.'      stage the line under the cursor',
\g:magit_mark_line_mapping
\.'      if cursor in hunk, mark line under cursor "to be staged"',
\'       if visual selection in hunk (with v), mark selected lines "to be'
\'       staged"',
\g:magit_stage_file_mapping
\.'      if cursor on filename header or hunk, stage whole file',
\g:magit_edit_mapping
\.'      edit, jump cursor to file containing this hunk',
\g:magit_jump_next_hunk.','.g:magit_jump_prev_hunk
\.  '    move to Next/Previous hunk in magit buffer',
\g:magit_discard_hunk_mapping
\.  '    discard file changes (warning, changes will be lost)',
\g:magit_ignore_mapping
\.'      add file in .gitgnore',
\],
			\ 'global': [
\g:magit_folding_toggle_mapping[0]
\.   '   if cursor on filename header line, unhide diffs for this file',
\g:magit_commit_mapping
\. '     set commit mode to normal, and show "Commit message" section',
\g:magit_commit_amend_mapping
\. '     set commit mode amend, and show "Commit message" section with previous',
\'       commit message',
\g:magit_commit_fixup_mapping
\. '     amend staged changes to previous commit without modifying the previous',
\'       commit message',
\g:magit_close_commit_mapping
\. '     commit undo, cancel and close current commit message',
\g:magit_reload_mapping
\.'      refresh magit buffer',
\g:magit_close_mapping
\.'      close magit buffer',
\g:magit_toggle_help_mapping
\.'      toggle help showing in magit buffer',
\],
			\ 'commit': [
\g:magit_commit_mapping
\. '     commit all staged changes with commit mode previously set (normal or',
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
	let branch=magit#utils#system(g:magit_git_cmd . " rev-parse --abbrev-ref HEAD")
	let commit=magit#utils#system(g:magit_git_cmd . " show -s --oneline")
	silent put =g:magit_section_info.cur_repo    . ': ' . magit#git#top_dir()
	silent put =g:magit_section_info.cur_branch  . ':     ' . branch
	silent put =g:magit_section_info.cur_commit  . ':        ' . commit
	if ( b:magit_current_commit_mode != '' )
	silent put =g:magit_section_info.commit_mode . ':        '
				\ . g:magit_commit_mode[b:magit_current_commit_mode]
	endif
	silent put =''
	silent put ='Press ? to display help'
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
	silent put =''
	silent put =g:magit_sections[a:mode]
	call <SID>mg_section_help(a:mode)
	silent put =magit#utils#underline(g:magit_sections[a:mode])
	silent put =''
	call s:mg_display_files(a:mode, '', 0)
endfunction

" s:mg_get_stashes: this function write in current buffer all stashes
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! s:mg_get_stashes()
	silent! let stash_list=magit#utils#systemlist(g:magit_git_cmd . " stash list")
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
			silent put =stash
			silent! execute "read !git stash show -p " . stash_id
		endfor
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
		silent put =''
		silent put =g:magit_sections.commit
		call <SID>mg_section_help('commit')
		silent put =magit#utils#underline(g:magit_sections.commit)

		let git_dir=magit#git#git_dir()
		" refresh the COMMIT_EDITMSG file
		if ( b:magit_current_commit_mode == 'CC' )
			silent! call magit#utils#system("GIT_EDITOR=/bin/false " .
						\ g:magit_git_cmd . " commit -e 2> /dev/null")
		elseif ( b:magit_current_commit_mode == 'CA' )
			silent! call magit#utils#system("GIT_EDITOR=/bin/false " .
						\ g:magit_git_cmd . " commit --amend -e 2> /dev/null")
		endif
		if ( filereadable(git_dir . 'COMMIT_EDITMSG') )
			let comment_char=magit#git#get_config("core.commentChar", '#')
			let commit_msg=magit#utils#join_list(filter(readfile(git_dir . 'COMMIT_EDITMSG'), 'v:val !~ "^' . comment_char . '"'))
			silent put =commit_msg
		endif
		if ( !empty(b:magit_current_commit_msg) )
			silent put =b:magit_current_commit_msg
		endif
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
	let commit_section_pat_end='^'.g:magit_sections[g:magit_default_sections[match(g:magit_default_sections, 'commit')+1]].'$'
	let commit_jump_line = 2 + <SID>mg_get_inline_help_line_nb('commit')
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
		silent let git_result=magit#utils#system(g:magit_git_cmd .
					\ " commit --amend -C HEAD")
	else
		let commit_flag=""
		if ( empty( magit#get_staged_files() ) )
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
		silent! let git_result=magit#utils#system(commit_cmd, commit_msg)
		let b:magit_current_commit_mode=''
		let b:magit_current_commit_msg=[]
	endif
	if ( v:shell_error != 0 )
		echohl ErrorMsg
		echom "Git error: " . git_result
		echom "Git cmd: " . commit_cmd
		echohl None
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
	let section=<SID>mg_get_section()
	let filename=<SID>mg_get_filename()
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
	\ 'global_help': { 'fn': function("s:mg_section_help"), 'arg': ['global']},
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
" VimagitUpdateFile event is raised
function! magit#update_buffer(...)
	let buffer_name=bufname("%")
	if ( buffer_name !~ 'magit://.*' )
		echoerr "Not in magit buffer but in " . buffer_name
		return
	endif

	if ( b:magit_current_commit_mode != '' )
		try
			let b:magit_current_commit_msg = s:mg_get_commit_msg(1)
		catch /^out_of_block$/
			let b:magit_current_commit_msg = []
		endtry
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
	
	call b:state.update()

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

	if ( b:magit_current_commit_mode != '' && b:magit_commit_newly_open == 1 )
		let commit_section_pat_start='^'.g:magit_sections.commit.'$'
		silent! let section_line=search(commit_section_pat_start, "w")
		silent! call cursor(section_line+2+<SID>mg_get_inline_help_line_nb('commit'), 0)
		if exists('#User#VimagitEnterCommit')
			doautocmd User VimagitEnterCommit
		endif
		let b:magit_commit_newly_open = 0
	endif

	set filetype=magit

	let g:magit_last_updated_buffer = ''
	if ( a:0 == 1 )
		let abs_filename = magit#git#top_dir() . a:1
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
		echom "make sure that current opened file or vim current directory points to a git repository"
		echom "search paths:"
		for path in try_paths
			echom path
		endfor
		echohl None
		throw 'magit_not_in_git_repo'
	endif

	let buffer_name='magit://' . git_dir

	let magit_win = magit#utils#search_buffer_in_windows(buffer_name)

	if ( magit_win != 0 )
		silent execute magit_win."wincmd w"
	elseif ( a:display == 'v' )
		silent execute "vnew " . buffer_name
	elseif ( a:display == 'h' )
		silent execute "new " . buffer_name
	elseif ( a:display == 'c' )
		if ( !bufexists(buffer_name) )
			if ( bufname("%") == "" )
				silent keepalt enew
			else
				silent enew
			endif
			silent execute "file " . buffer_name
		endif
	else
		throw 'parameter_error'
	endif

	silent execute "buffer " . buffer_name

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
	let &l:foldlevel = b:magit_default_fold_level
	setlocal filetype=magit
	"setlocal readonly

	let b:state = deepcopy(g:magit#state#state)
	" s:magit_commit_mode: global variable which states in which commit mode we are
	" values are:
	"       '': not in commit mode
	"       'CC': normal commit mode, next commit command will create a new commit
	"       'CA': amend commit mode, next commit command will ament current commit
	"       'CF': fixup commit mode, it should not be a global state mode
	let b:magit_current_commit_mode=''
	let b:magit_commit_newly_open=0

	call magit#utils#setbufnr(bufnr(buffer_name))
	call magit#sign#init()

	execute "nnoremap <buffer> <silent> " . g:magit_stage_file_mapping .   " :call magit#stage_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping .   " :call magit#stage_hunk(0)<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_discard_hunk_mapping . " :call magit#stage_hunk(1)<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_reload_mapping .       " :call magit#update_buffer()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_edit_mapping .         " :call magit#jump_to()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_mapping .       " :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_amend_mapping . " :call magit#commit_command('CA')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_fixup_mapping . " :call magit#commit_command('CF')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_close_commit_mapping . " :call magit#close_commit()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_ignore_mapping .       " :call magit#ignore_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_close_mapping .        " :call magit#close_magit()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_toggle_help_mapping .  " :call magit#toggle_help()<cr>"

	execute "nnoremap <buffer> <silent> " . g:magit_stage_line_mapping .   " :call magit#stage_vselect()<cr>"
	execute "xnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping .   " :call magit#stage_vselect()<cr>"
	
	execute "nnoremap <buffer> <silent> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"
	execute "xnoremap <buffer> <silent> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"

	execute "nnoremap <buffer> <silent> " . g:magit_jump_next_hunk .       " :call magit#jump_hunk('N')<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_jump_prev_hunk .       " :call magit#jump_hunk('P')<cr>"

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

	if exists('#User#VimagitBufferInit')
		doautocmd User VimagitBufferInit
	endif

	call magit#update_buffer()
	execute "normal! gg"
endfunction

function! magit#close_magit()
	try
		close
	catch /^Vim\%((\a\+)\)\=:E444/
		try
			edit #
		catch /^Vim\%((\a\+)\)\=:E\%(194\|499\)/
			quit
		endtry
	endtry
endfunction

function! s:mg_stage_closed_file(discard)
	if ( getline(".") =~ g:magit_file_re )
		let list = matchlist(getline("."), g:magit_file_re)
		let filename = list[2]
		let section=<SID>mg_get_section()
		
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
					if ( file.status == '?' )
						if ( g:magit_discard_untracked_do_delete == 1 )
							if ( delete(filename) != 0 )
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

			call magit#update_buffer(filename)
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
	let section=<SID>mg_get_section()
	let filename=<SID>mg_get_filename()
	let header = b:state.get_file(section, filename).get_header()
	
	let file = b:state.get_file(section, filename, 0)
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
			if ( file.must_be_added() )
				call magit#git#git_checkout(magit#utils#add_quotes(filename))
			else
				call magit#git#git_unapply(header, a:selection, 'unstaged')
			endif
		else
			echoerr "Must be in \"" .
						\ g:magit_sections.unstaged . "\" section"
		endif
	endif

	call magit#update_buffer(filename)
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
	let ignore_file=<SID>mg_get_filename()
	call magit#utils#append_file(magit#git#top_dir() . ".gitignore",
			\ [ ignore_file ] )
	call magit#update_buffer()
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
		let section=<SID>mg_get_section()
		if ( section == 'commit' )
			if ( b:magit_current_commit_mode == '' )
				echoerr "Error, commit section should not be enabled"
				return
			endif
			" when we do commit, it is prefered ot commit the way we prepared it
			" (.i.e normal or amend), whatever we commit with CC or CA.
			call <SID>mg_git_commit(b:magit_current_commit_mode)
		else
			let b:magit_current_commit_mode=a:mode
			let b:magit_commit_newly_open=1
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
  call magit#update_buffer()
endfunction

" magit#jump_hunk: function to jump among hunks
" it closes the current fold (if any), jump to next hunk and unfold it
" param[in] dir: can be 'N' (for next) or 'P' (for previous)
function! magit#jump_hunk(dir)
	let back = ( a:dir == 'P' ) ? 'b' : ''
	let line = search("^@@ ", back . 'wn')
	if ( line != 0 )
		if ( foldlevel(line('.')) == 2 )
			try
				foldclose
			catch /^Vim\%((\a\+)\)\=:E490/
			endtry
		endif
		call cursor(line, 0)
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
	let section=<SID>mg_get_section()
	let filename=fnameescape(magit#git#top_dir() . <SID>mg_get_filename())
	let line=substitute(s:mg_get_hunkheader(),
				\ '^@@ -\d\+,\d\+ +\(\d\+\),\d\+ @@.*$', '\1', "")
	let context = magit#git#get_config("diff.context", 3)
	let line += context

	" winnr('#') is overwritten by magit#get_win()
	let last_win = winnr('#')
	let buf_win = magit#utils#search_buffer_in_windows(filename)
	let buf_win = ( buf_win == 0 ) ? last_win : buf_win
	if ( buf_win == 0 || winnr('$') == 1 )
		rightbelow vnew
	else
		execute buf_win."wincmd w"
	endif

		execute "edit " . "+" . line . " " filename
endfunction

function! magit#show_version()
	return g:vimagit_version[0] . "." .
				\ g:vimagit_version[1] . "." .
				\ g:vimagit_version[2]
endfunction

command! Magit call magit#show_magit('v')
command! MagitOnly call magit#show_magit('c')

" }}}
