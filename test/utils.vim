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

" wrapper to execute command, echoerr'ing complete message in case of error
function! Git_cmd(...)
	let ret=call('system', a:000)
	if ( v:shell_error != 0 )
		echoerr "Error:\ncommand:\n" . join(a:000, "\n") . "\nret:\n" . ret
	endif
	return ret
endfunction

" helper function to get a commit message (without sha1)
function! Git_commit_msg(sha1)
	let commit_cmd="git show --src-prefix='' --dst-prefix='' --format='%s%B' " . a:sha1 .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(commit_cmd)
endfunction

" helper function to get status of a given file
function! Git_status(file)
	call Cd_test()
	let status_cmd="git status --porcelain -- " . a:file
	let status=Git_cmd(status_cmd)
	call Cd_test_sub()
	return status
endfunction

" helper function to get the diff of a file, in staged or unstaged mode
function! Git_diff(state, file)
	let staged_flag = ( a:state == 'staged' ) ? ' --staged ' : ''
	let diff_cmd="git diff --no-color --no-ext-diff --src-prefix='' --dst-prefix='' " .
				\ staged_flag . " -- " . a:file .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(diff_cmd)
endfunction

" helper function to:
" - check if output is conform to gold file if VIMAGIT_CRAFT_EXPECT == 0
" - generate gold file with output if VIMAGIT_CRAFT_EXPECT == 0
function! Expect_diff(gold_file, test_diff)
	if ( Is_crafting() == 0 )
		let diff_cmd="diff " . a:gold_file . " - "
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
		call cursor(0, virtcol('$'))
	else
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

" search a file header in magit buffer, for example 'added: bootstrap', move
" the cursor and return the line
function! Search_file(mode)
	call search(substitute(a:mode, '.*', '\u\0', '') . ' changes')
	return search("^.*: " . $VIMAGIT_TEST_FILENAME)
endfunction

" get the filename we curently test
function! Get_filename()
	return $VIMAGIT_TEST_FILENAME
endfunction

" get a safe to use string of filename we curently test (for golden files)
function! Get_safe_filename()
	return substitute($VIMAGIT_TEST_FILENAME, '[/.]', '_', 'g')
endfunction
