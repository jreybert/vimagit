scriptencoding utf-8

"if exists('g:loaded_magit') || !executable('git') || &cp
"  finish
"endif
"let g:loaded_magit = 1
" Initialisation {{{

" FIXME: find if there is a minimum vim version required
" if v:version < 703
" endif

let g:magit_unstaged_buffer_name = "magit-playground"

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
call s:set('g:magit_commit_mapping',            "C")
call s:set('g:magit_reload_mapping',            "R")

call s:set('g:magit_enabled',               1)

" }}}

" {{{ Internal functions

let s:magit_staged_section=         'Staged stuff'
let s:magit_unstaged_section=       'Unstaged stuff'
let s:magit_commit_section_start=   'Commit stuff'
let s:magit_commit_section_end=     'Commit stuff end'

function! magit#underline(title)
	return substitute(a:title, ".", "=", "g")
endfunction

function! magit#strip(string)
	return substitute(a:string, '^\s*\(.\{-}\)\s*\n$', '\1', '')
endfunction

function! magit#decorate_section(string)
	return '&@'.a:string.'@&'
endfunction

function! magit#join_list(list)
	return join(a:list, "\n") . "\n"
endfunction

" magit#get_staged: this function writes in current buffer all staged files
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! magit#get_staged()
	put =''
	put =magit#decorate_section(s:magit_staged_section)
	put =magit#decorate_section(magit#underline(s:magit_staged_section))
	put =''
	silent! read !git diff --staged --no-color
endfunction

" magit#get_unstaged: this function writes in current buffer all unstaged
" and untracked files
" WARNING: this function writes in file, it should only be called through
" protected functions like magit#update_buffer
function! magit#get_unstaged()
	put =''
	put =magit#decorate_section(s:magit_unstaged_section)
	put =magit#decorate_section(magit#underline(s:magit_unstaged_section))
	put =''

	silent! read !git diff --no-color
	silent! read !git ls-files --others --exclude-standard | while read -r i; do git diff --no-color -- /dev/null "$i"; done
endfunction

let s:magit_commit_mode=0
function! magit#get_commit_section()
	put =''
	put =magit#decorate_section(s:magit_commit_section_start)
	put =magit#decorate_section(magit#underline(s:magit_commit_section_start))
	put =''

	let git_dir=magit#strip(system("git rev-parse --git-dir"))
	" refresh the COMMIT_EDITMSG file
	silent! call system("GIT_EDITOR=/bin/false git commit -e 2> /dev/null")
	let commit_msg=join(readfile(git_dir . '/COMMIT_EDITMSG'), "\n") . "\n"
	put =commit_msg
	put =magit#decorate_section(s:magit_commit_section_end)
endfunction

" magit#search_block: helper function, to get a block of text, giving a start
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
function! magit#search_block(start_pattern, end_pattern, upper_limit_pattern)
	let l:winview = winsaveview()

	let upper_limit=0
	if ( a:upper_limit_pattern != "" )
		let upper_limit=search(a:upper_limit_pattern, "bnW")
	endif

	" important if backward regex is at the beginning of the current line
	call cursor(0, 100)
	let start=search(a:start_pattern[0], "bW")
	if ( start == 0 )
		call winrestview(l:winview)
		return [1, ""]
	endif
	if ( start < upper_limit )
		call winrestview(l:winview)
		return [1, ""]
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
		return [1, ""]
	endif

	let lines=getline(start, end)

	call winrestview(l:winview)
	return [0, lines]
endfunction

let s:diff_re  = '^diff --git'
let s:hunk_re  = '^@@ -\(\d\+\),\?\(\d*\) +\(\d\+\),\?\(\d*\) @@'
let s:bin_re   = '^Binary files '
let s:title_re = '^##\%([^#]\|\s\)\+##$'
let s:eof_re   = '\%$'

function! magit#git_commit()
	let commit_section_pat_start='^'.magit#decorate_section(s:magit_commit_section_start).'$'
	let commit_section_pat_end='^'.magit#decorate_section(s:magit_commit_section_end).'$'
	let [ret, commit_msg]=magit#search_block([commit_section_pat_start, +2], [ [commit_section_pat_end, -1] ], "")
	silent let git_result=system("git commit --file -", commit_msg)
endfunction

" magit#select_file: select the whole diff file, relative to the current
" cursor position
" nota: if the cursor is not in a diff file when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the patch for the whole file
function! magit#select_file()
	return magit#search_block([s:diff_re, 0], [ [s:diff_re, -1], [s:title_re, -2], [s:bin_re, 0], [ s:eof_re, 0 ] ], "")
endfunction

" magit#select_file_header: select the upper diff header, relative to the current
" cursor position
" nota: if the cursor is not in a diff file when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the diff header
function! magit#select_file_header()
	return magit#search_block([s:diff_re, 0], [ [s:hunk_re, -1] ], "")
endfunction

" magit#select_hunk: select a hunk, from the current cursor position
" nota: if the cursor is not in a hunk when the function is called, this
" function will fail
" return: a List
"         @[0]: return value
"         @[1]: List of lines containing the hunk
function! magit#select_hunk()
	return magit#search_block([s:hunk_re, 0], [ [s:hunk_re, -1], [s:diff_re, -1], [s:title_re, -2], [ s:eof_re, 0 ] ], s:diff_re)
endfunction

" magit#git_apply: helper function to stage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git_apply(selection)
	let selection=magit#join_list(a:selection)
	silent let git_result=system("git apply --cached -", selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
	endif
endfunction

" magit#git_unapply: helper function to unstage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git_unapply(selection)
	silent let git_result=system("git apply --cached --reverse -", a:selection)
	if ( v:shell_error != 0 )
		echoerr "Git error: " . git_result
	endif
endfunction

" }}}

" {{{ User functions and commands

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
	silent! execute "normal! ggdG"
	
	if ( s:magit_commit_mode == 1 )
		call magit#get_commit_section()
	endif
	call magit#get_staged()
	call magit#get_unstaged()

	call winrestview(l:winview)
endfunction

function! magit#show_magit(orientation)
	vnew 
	setlocal buftype=nofile
	setlocal bufhidden=delete
	setlocal noswapfile
	setlocal foldmethod=syntax
	setlocal nowrapscan
	setlocal foldlevel=1
	setlocal filetype=gitdiff
	"setlocal readonly

	execute "file " . g:magit_unstaged_buffer_name

	execute "nnoremap <buffer> <silent> " . g:magit_stage_file_mapping . " :call magit#stage_file()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_stage_hunk_mapping . " :call magit#stage_hunk()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_reload_mapping .     " :call magit#update_buffer()<cr>"
	execute "nnoremap <buffer> <silent> " . g:magit_commit_mapping .     " :call magit#commit_command()<cr>"
	
	call magit#update_buffer()
	execute "normal! gg"
endfunction

function! magit#get_section()
	let section_line=search('^&@[a-zA-Z ]\+@&$', "bnW")
	return substitute(getline(section_line), '^&@\([a-zA-Z ]\+\)@&$', '\1', '')
endfunction

" magit#stage_hunk: this function stage a single hunk, from the current
" cursor position
" return: no
function! magit#stage_hunk()
	let [ret, header] = magit#select_file_header()
	if ( ret != 0 )
		echoerr "Can't find diff header"
		return
	endif
	let [ret, hunk] = magit#select_hunk()
	if ( ret != 0 )
		echoerr "Not in a hunk region"
		return
	endif
	let section=magit#get_section()
	if ( section == s:magit_unstaged_section )
		call magit#git_apply(header + hunk)
	elseif ( section == s:magit_staged_section )
		call magit#git_unapply(header + hunk)
	else
		echoerr "Must be in \"".s:magit_unstaged_section."\" or \"".s:magit_staged_section."\" section"
	endif
	call magit#update_buffer()
endfunction

" magit#stage_hunk: this function stage a whole file, from the current
" cursor position
" return: no
function! magit#stage_file()
	let [ret, selection] = magit#select_file()
	if ( ret != 0 )
		echoerr "Not in a file region"
		return
	endif
	let section=magit#get_section()
	if ( section == s:magit_unstaged_section )
		call magit#git_apply(selection)
	elseif ( section == s:magit_staged_section )
		call magit#git_unapply(selection)
	else
		echoerr "Must be in \"".s:magit_unstaged_section."\" or \"".s:magit_staged_section."\" section"
	endif
	call magit#update_buffer()
endfunction

function! magit#commit_command()
	let section=magit#get_section()
	if ( section == s:magit_commit_section_start )
		if ( s:magit_commit_mode == 0 )
			echoerr "Error, commit section should not be enabled"
			return
		endif
		call magit#git_commit()
		let s:magit_commit_mode=0
	else
		let s:magit_commit_mode=1
	endif
	call magit#update_buffer()
endfunction

command! Magit call magit#show_magit("v")

" }}}
