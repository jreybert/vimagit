
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

function! magit#mapping#set_default()

	execute "nnoremap <buffer><silent><nowait> " . g:magit_stage_file_mapping .   " :call magit#stage_file()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_stage_hunk_mapping .   " :call magit#stage_hunk(0)<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_discard_hunk_mapping . " :call magit#stage_hunk(1)<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_reload_mapping .       " :call magit#update_buffer()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_edit_mapping .         " :call magit#jump_to()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_commit_mapping .       " :call magit#commit_command('CC')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_commit_amend_mapping . " :call magit#commit_command('CA')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_commit_fixup_mapping . " :call magit#commit_command('CF')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_close_commit_mapping . " :call magit#close_commit()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_ignore_mapping .       " :call magit#ignore_file()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_close_mapping .        " :call magit#close_magit()<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_diff_shrink .          " :call magit#update_diff('-')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_diff_enlarge .         " :call magit#update_diff('+')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_diff_reset .           " :call magit#update_diff('0')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_toggle_help_mapping .  " :call magit#toggle_help()<cr>"

	execute "nnoremap <buffer><silent><nowait> " . g:magit_stage_line_mapping .   " :call magit#stage_vselect()<cr>"
	execute "xnoremap <buffer><silent><nowait> " . g:magit_stage_hunk_mapping .   " :call magit#stage_vselect()<cr>"
	
	execute "nnoremap <buffer><silent><nowait> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"
	execute "xnoremap <buffer><silent><nowait> " . g:magit_mark_line_mapping .    " :call magit#mark_vselect()<cr>"

	execute "nnoremap <buffer><silent><nowait> " . g:magit_jump_next_hunk .       " :call magit#jump_hunk('N')<cr>"
	execute "nnoremap <buffer><silent><nowait> " . g:magit_jump_prev_hunk .       " :call magit#jump_hunk('P')<cr>"
	for mapping in g:magit_folding_toggle_mapping
		" trick to pass '<cr>' in a mapping command without being interpreted
		let func_arg = ( mapping ==? "<cr>" ) ? '+' : mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call magit#open_close_folding_wrapper('" . func_arg . "')<return>"
	endfor
	for mapping in g:magit_folding_open_mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call magit#open_close_folding_wrapper('" . mapping . "', 1)<return>"
	endfor
	for mapping in g:magit_folding_close_mapping
		execute "nnoremap <buffer><silent><nowait> " . mapping . " :call magit#open_close_folding_wrapper('" . mapping . "', 0)<return>"
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
\. '     set commit mode to normal, and show "Commit message" section',
\'       In commit mode, commit all staged changes with commit mode previously',
\'       set (normal or amend) with message written in this section',
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

