
let g:magit_stage_file_mapping     = get(g:, 'magit_stage_file_mapping',        'F' )
let g:magit_stage_hunk_mapping     = get(g:, 'magit_stage_hunk_mapping',        'S' )
let g:magit_stage_line_mapping     = get(g:, 'magit_stage_line_mapping',        'L' )
let g:magit_mark_line_mapping      = get(g:, 'magit_mark_line_mapping',         'M' )
let g:magit_commit_mapping         = get(g:, 'magit_commit_mapping',            'CC' )
let g:magit_commit_amend_mapping   = get(g:, 'magit_commit_amend_mapping',      'CA' )
let g:magit_commit_fixup_mapping   = get(g:, 'magit_commit_fixup_mapping',      'CF' )
let g:magit_close_commit_mapping   = get(g:, 'magit_close_commit_mapping',      'CU' )
let g:magit_reload_mapping         = get(g:, 'magit_reload_mapping',            'R' )
let g:magit_edit_mapping           = get(g:, 'magit_edit_mapping',              'E' )

let g:magit_jump_next_hunk         = get(g:, 'magit_jump_next_hunk',            '<C-N>')
let g:magit_jump_prev_hunk         = get(g:, 'magit_jump_prev_hunk',            '<C-P>')

let g:magit_ignore_mapping         = get(g:, 'magit_ignore_mapping',            'I' )
let g:magit_discard_hunk_mapping   = get(g:, 'magit_discard_hunk_mapping',      'DDD' )

let g:magit_close_mapping          = get(g:, 'magit_close_mapping',             'q' )
let g:magit_toggle_help_mapping    = get(g:, 'magit_toggle_help_mapping',       '?' )

let g:magit_diff_shrink            = get(g:, 'magit_diff_shrink',               '-' )
let g:magit_diff_enlarge           = get(g:, 'magit_diff_enlarge',              '+' )
let g:magit_diff_reset             = get(g:, 'magit_diff_reset',                '0' )

let g:magit_folding_toggle_mapping = get(g:, 'magit_folding_toggle_mapping',    [ '<CR>' ])
let g:magit_folding_open_mapping   = get(g:, 'magit_folding_open_mapping',      [ 'zo', 'zO' ])
let g:magit_folding_close_mapping  = get(g:, 'magit_folding_close_mapping',     [ 'zc', 'zC' ])

" magit#open_close_folding_wrapper: wrapper function to
" magit#open_close_folding. If line under cursor is not a cursor, execute
" normal behavior
" param[in] mapping: which has been set
" param[in] visible : boolean, force visible value. If not set, toggle
" visibility
function! s:mg_open_close_folding_wrapper(mapping, ...)
	if ( getline(".") =~ g:magit_file_re )
		return call('magit#open_close_folding', a:000)
	elseif ( foldlevel(line(".")) == 2 )
		if ( foldclosed(line('.')) == -1 )
			foldclose
		else
			foldopen
		endif
	else
		silent! execute "silent! normal! " . a:mapping
	endif
endfunction

" s:nmapping_wrapper: wrapper for normal mapping commands
" it needs a wrapper because some mappings must only be enabled in some
" sections. For example, wa want that 'S' mapping to be enabled in staged and
" unstaged sections, but not in commit section.
" param[in] mapping the key for the mapping (lhs)
" param[in] function the function to call (rhs)
" param[in] ... : optional, section, the regex of the sections where to enable the
" mapping. If there is no section parameter or if the section parameter regex
" match the current section, the rhs is called. Otherwise, the mapping is
" applied to its original meaning.
function! s:nmapping_wrapper(mapping, function, ...)
	if ( a:0 == 0 || magit#helper#get_section() =~ a:1 )
		execute "call " . a:function
	else
		" feedkeys(..., 'n') is prefered over execute normal!
		" normal! does not enter in insert mode
		call feedkeys(a:mapping, 'n')
	endif
endfunction

" s:xmapping_wrapper: wrapper for visual mapping commands
" it needs a wrapper because some mappings must only be enabled in some
" sections. For example, wa want that 'S' mapping to be enabled in staged and
" unstaged sections, but not in commit section.
" param[in] mapping the key for the mapping (lhs)
" param[in] function the function to call (rhs)
" param[in] ... : optional, section, the regex of the sections where to enable the
" mapping. If there is no section parameter or if the section parameter regex
" match the current section, the rhs is called. Otherwise, the mapping is
" applied to its original meaning.
function! s:xmapping_wrapper(mapping, function, ...) range
	if ( a:0 == 0 || magit#helper#get_section() =~ a:1 )
		execute a:firstline . "," . a:lastline . "call " . a:function
	else
		" feedkeys(..., 'n') is prefered over execute normal!
		" normal! does not enter in insert mode
		call feedkeys(a:mapping, 'n')
	endif
endfunction
" s:mg_set_mapping: helper function to setup the mapping
" param[in] mode the mapping mode, one letter. Can be 'n', 'x', 'i', ...
" param[in] mapping the key for the mapping (lhs)
" param[in] function the function to call (rhs)
" param[in] ... : optional, section, the regex of the section(s)
function! s:mg_set_mapping(mode, mapping, function, ...)
	if ( a:0 == 1 )
		execute a:mode . "noremap <buffer><silent><nowait> "
					\ . a:mapping .
					\ " :call <SID>" . a:mode . "mapping_wrapper(\"" .
					\ a:mapping . "\", \"" .
					\ a:function . "\"" .
					\ ", \'" . a:1 . "\'" .
					\ ")<cr>"
	else
		execute a:mode . "noremap <buffer><silent><nowait> "
					\ . a:mapping .
					\ " :call  " .
					\ a:function . "<cr>"
	endif
endfunction

function! magit#mapping#set_default()

	call s:mg_set_mapping('n', g:magit_stage_hunk_mapping,
				\"magit#stage_hunk(0)", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('n', g:magit_stage_file_mapping,
				\ "magit#stage_file()", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('n', g:magit_discard_hunk_mapping,
				\ "magit#stage_hunk(1)", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('n', g:magit_stage_line_mapping,
				\ "magit#stage_vselect()", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('x', g:magit_stage_hunk_mapping,
				\ "magit#stage_vselect()", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('n', g:magit_mark_line_mapping,
				\ "magit#mark_vselect()", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('x', g:magit_mark_line_mapping,
				\ "magit#mark_vselect()", '\<\%(un\)\?staged\>')

	call s:mg_set_mapping('n', g:magit_ignore_mapping,
				\ "magit#ignore_file()", '\<\%(un\)\?staged\>')
	call s:mg_set_mapping('n', g:magit_edit_mapping,
				\ "magit#jump_to()", '\<\%(un\)\?staged\>')

	call s:mg_set_mapping('n', g:magit_reload_mapping,
				\ "magit#update_buffer()")
	call s:mg_set_mapping('n', g:magit_close_mapping,
				\ "magit#close_magit()")
	call s:mg_set_mapping('n', g:magit_diff_shrink,
				\ "magit#update_diff('-')")
	call s:mg_set_mapping('n', g:magit_diff_enlarge,
				\ "magit#update_diff('+')")
	call s:mg_set_mapping('n', g:magit_diff_reset,
				\ "magit#update_diff('0')")
	call s:mg_set_mapping('n', g:magit_toggle_help_mapping,
				\ "magit#toggle_help()")

	call s:mg_set_mapping('n', g:magit_commit_mapping,
				\ "magit#commit_command('CC')")
	call s:mg_set_mapping('n', g:magit_commit_amend_mapping,
				\ "magit#commit_command('CA')")
	call s:mg_set_mapping('n', g:magit_commit_fixup_mapping,
				\ "magit#commit_command('CF')")
	call s:mg_set_mapping('n', g:magit_close_commit_mapping,
				\ "magit#close_commit()")

	call s:mg_set_mapping('n', g:magit_jump_next_hunk,
				\ "magit#jump_hunk('N')")
	call s:mg_set_mapping('n', g:magit_jump_prev_hunk,
				\ "magit#jump_hunk('P')")

	for mapping in g:magit_folding_toggle_mapping
		" trick to pass '<cr>' in a mapping command without being interpreted
		let func_arg = ( mapping ==? "<cr>" ) ? '+' : mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call <SID>mg_open_close_folding_wrapper('" . func_arg . "')<return>"
	endfor
	for mapping in g:magit_folding_open_mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call <SID>mg_open_close_folding_wrapper('" . mapping . "', 1)<return>"
	endfor
	for mapping in g:magit_folding_close_mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call <SID>mg_open_close_folding_wrapper('" . mapping . "', 0)<return>"
	endfor

	" s:magit_inline_help: Dict containing inline help for each section
	let s:magit_inline_help = {
			\ 'staged': [
\g:magit_stage_hunk_mapping
\.'      if cursor on filename header, unstage file',
\'       if cursor in hunk, unstage hunk',
\'       if visual selection in hunk (with v), unstage selection',
\'       if lines marked in hunk (with ' . g:magit_mark_line_mapping . '), unstage marked lines',
\g:magit_stage_line_mapping
\.'      unstage the line under the cursor',
\g:magit_mark_line_mapping
\.'      if cursor in hunk, mark line under cursor "to be unstaged"',
\'       if visual selection in hunk (with v), mark selected lines "to be unstaged"',
\g:magit_stage_file_mapping
\.'      if cursor on filename header or hunk, unstage whole file',
\g:magit_edit_mapping
\.'      edit, jump cursor to file containing this hunk',
\g:magit_jump_next_hunk.','.g:magit_jump_prev_hunk
\.  '    move to Next/Previous hunk in magit buffer',
\],
			\ 'unstaged': [
\g:magit_stage_hunk_mapping
\.'      if cursor on filename header, stage file',
\'       if cursor in hunk, stage hunk',
\'       if visual selection in hunk (with v), stage selection',
\'       if lines marked in hunk (with ' . g:magit_mark_line_mapping . '), stage marked lines',
\g:magit_stage_line_mapping
\.'      stage the line under the cursor',
\g:magit_mark_line_mapping
\.'      if cursor in hunk, mark line under cursor "to be staged"',
\'       if visual selection in hunk (with v), mark selected lines "to be staged"',
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
\g:magit_sections['help'],
\g:magit_folding_toggle_mapping[0]
\.   '   if cursor on filename header line, unhide diffs for this file',
\g:magit_commit_mapping
\. '     From stage mode: set commit mode in normal flavor',
\'       From commit mode: commit all staged changes with commit flavor',
\'       (normal or amend) with message in "Commit message" section',
\g:magit_commit_amend_mapping
\. '     From stage or commit mode: set commit mode in amend flavor, and',
\'       display "Commit message" section with previous commit message.',
\g:magit_commit_fixup_mapping
\. '     From stage mode: amend staged changes to previous commit without',
\'       modifying the previous commit message',
\g:magit_close_commit_mapping
\. '     commit undo, cancel and close current commit message',
\g:magit_reload_mapping
\.'      refresh magit buffer',
\g:magit_diff_shrink.','.g:magit_diff_enlarge.','.g:magit_diff_reset
\.    '  shrink,enlarge,reset diff context',
\g:magit_close_mapping
\.'      close magit buffer',
\g:magit_toggle_help_mapping
\.'      toggle help showing in magit buffer',
\'======='
\],
\}
endfunction

" s:mg_get_inline_help_line_nb: this function returns the number of lines of
" a given section, or 0 if help is disabled.
" param[in] section: section identifier
" return number of lines
function! magit#mapping#get_section_help_line_nb(section)
	return ( g:magit_show_help == 1 ) ?
		\ len(s:magit_inline_help[a:section]) : 0
endfunction

" s:mg_section_help: this function writes in current buffer the inline help
" for a given section, it does nothing if inline help is disabled.
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
" param[in] section: section identifier
function! magit#mapping#get_section_help(section)
	if ( g:magit_show_help == 1 )
		silent put =s:magit_inline_help[a:section]
	endif
endfunction

