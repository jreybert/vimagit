"This file contains utility functions for tests, and wrapper around
"environment variables. Env var are the way found to run the same test with
"different configurations.

" These environment variables must be exported from bash
" $VIMAGIT_PATH: vimagit plugin root path
" $VADER_PATH: vader plugin root path
" $TEST_PATH: git dir used for test root path
" $TEST_SUB_PATH: git dir used for test subdir path (we want to test vimagit commands from subdirs)
" $VIMAGIT_TEST_FILENAME: filename we test (stage/unstage/ignore...)
" $VIMAGIT_TEST_FROM_EOL: change cursor initial position before a command test see Cursor_position()
" Optionals
" $VIMAGIT_CRAFT_EXPECT: see Is_crafting() and Expect_diff()
if ( ! ( exists("$VIMAGIT_PATH") && exists("$VADER_PATH") && exists("$TEST_PATH") && exists("$TEST_SUB_PATH") )  
\ && ( ! ( isdirectory("$VIMAGIT_PATH") && isdirectory("$VADER_PATH") && isdirectory("$TEST_PATH")  && isdirectory("$TEST_PATH"."/"."$TEST_SUB_PATH")) ) )
	echoerr "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH' '$TEST_SUB_PATH'"
endif

if ( ! ( exists('$VIMAGIT_TEST_FILENAME') ) )
	echoerr "env VIMAGIT_TEST_FILENAME is not set"
endif


" directory containing test scripts and golden files
let g:test_script_dir = $VIMAGIT_PATH . '/test/'
" regex to discard sha1 lines in diff, commit, ... git messages
" we don't want them because they change at each run, we can't put them in
" golden files
let g:index_regex = "\"^index [[:xdigit:]]\\{7\\}\\.\\.[[:xdigit:]]\\{7\\}\""

" this method is used to generate gold files
" when envvar VIMAGIT_CRAFT_EXPECT is set, we don't check diff with gold
" files, we create them.
function! Is_crafting()
	return exists("$VIMAGIT_CRAFT_EXPECT") ? $VIMAGIT_CRAFT_EXPECT : 0
endfunction

" helper function to move cursor few lines up or down
function! Move_relative(nb_lines)
	call cursor(line('.') + a:nb_lines, 0)
endfunction

function! Git_verbose_log(...)
	if ( $VIMGAGIT_TEST_VERBOSE == "1" )
		call call('vader#log', a:000)
	endif
endfunction

" wrapper to execute command, echoerr'ing complete message in case of error
function! Git_cmd(...)
	call Git_verbose_log('Git_cmd: ' . string(a:000))
	let ret=call('system', a:000)
	if ( v:shell_error != 0 )
		echoerr "Error:\ncommand:\n" . join(a:000, "\n") . "\nret:\n" . ret
	endif
	call Git_verbose_log('Ret: ' . ret)
	return ret
endfunction

" helper function to get a commit message (without sha1)
function! Git_commit_msg(sha1)
	let commit_cmd="git show --src-prefix='' --dst-prefix='' --format='%B' " . a:sha1 .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(commit_cmd)
endfunction

" helper function to get status of a given file
function! Git_status(file)
	call Cd_test()
	let status=filter(split(system("git status --porcelain"), "\n"), 'v:val =~ "' . a:file . '"')[0] . "\n"
	call Cd_test_sub()
	return status
endfunction

function! Git_add_quotes(filename)
	return '"' . a:filename . '"'
endfunction

" helper function to get the diff of a file, in staged or unstaged mode
function! Git_diff(state, ...)
	let staged_flag = ( a:state == 'staged' ) ? ' --staged ' : ''
	if ( a:0 == 1 )
		let file = " -- " . Git_add_quotes(a:1)
	else
		let file = ""
	endif

	let diff_cmd="git diff --no-color --no-ext-diff --src-prefix='' --dst-prefix='' " .
				\ staged_flag . file .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(diff_cmd)
endfunction

" helper function to:
" - check if output is conform to gold file if VIMAGIT_CRAFT_EXPECT == 0
" - generate gold file with output if VIMAGIT_CRAFT_EXPECT == 0
function! Expect_diff(gold_file, test_diff)
	if ( Is_crafting() == 0 )
		call Git_verbose_log("Expect diff: " . a:test_diff)
		call Git_verbose_log("With golden file: " . a:gold_file)
		let diff_cmd="diff " . Git_add_quotes(a:gold_file) . " - "
		let diff=system(diff_cmd, a:test_diff)
		if ( v:shell_error != 0 )
			echoerr "diff: " . diff
			echoerr "diffcmd: " . diff_cmd
		endif
		return v:shell_error
	else
		let ret=writefile(split(a:test_diff, '\n'), a:gold_file, "w")
		if ( ret != 0 )
			echoerr 'Error while writing ' . a:gold_file
		endif
	endif
endfunction

" we want to test every magit command with cursor at the begenning and at the
" end of the line before calling the command
function! Cursor_position()
	if ( exists("$VIMAGIT_TEST_FROM_EOL") ? $VIMAGIT_TEST_FROM_EOL : 0 )
		call Git_verbose_log('Move to end of line')
		call cursor(0, virtcol('$'))
	else
		call Git_verbose_log('Move to start of line')
		call cursor(0, 1)
	endif
endfunction

" set cwd to vimagit path
function! Cd_vimagit()
	cd $VIMAGIT_PATH
endfunction

" set cwd to git test directory root
function! Cd_test()
	cd $TEST_PATH
endfunction

" set cwd to git test directory subdir (see $TEST_SUB_PATH)
function! Cd_test_sub()
	cd $TEST_SUB_PATH
endfunction

" get the filename we curently test
" optional parameter for renamed file. In this case, we want to (un)stage 2 times
function! Get_filename(...)
	if ( a:0 == 1 )
		return split($VIMAGIT_TEST_FILENAME, '|')[a:1]
	else
		return $VIMAGIT_TEST_FILENAME
endfunction

" search a file header in magit buffer, for example 'added: bootstrap', move
" the cursor and return the line
function! Search_file(mode, ...)
	call search(substitute(a:mode, '.*', '\u\0', '') . ' changes')
	call Git_verbose_log('Search mode: "' . a:mode . '" => ' . getline('.'))
	let pattern='^.*: ' . call('Get_filename', a:000) . '\%( -> .*\)\?$'
	let ret = search(pattern)
	call Git_verbose_log('Search: "' . pattern . '" => ' . getline('.') . ' @line' . line('.'))
	return ret
endfunction

function! Search_pattern(pattern)
	let ret = search(a:pattern)
	call Git_verbose_log('Search: "' . a:pattern . '" => ' . getline('.') . ' @line' . line('.'))
endfunction

" get a safe to use string of filename we curently test (for golden files)
function! Get_safe_filename(...)
	return substitute(call('Get_filename', a:000), '[/. ]', '_', 'g')
endfunction
