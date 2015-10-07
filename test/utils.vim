if ( ! ( exists("$VIMAGIT_PATH") && exists("$VADER_PATH") && exists("$TEST_PATH") ) 
\ && ( ! ( isdirectory("$VIMAGIT_PATH") && isdirectory("$VADER_PATH") && isdirectory("$TEST_PATH") ) ) )
	echoerr "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH'"
endif

let g:test_dir = $VIMAGIT_PATH . '/test/'
let g:index_regex = "\"^index [[:xdigit:]]\\{7\\}\\.\\.[[:xdigit:]]\\{7\\}\""

function! Is_crafting()
	return exists("$VIMAGIT_CRAFT_EXPECT") ? $VIMAGIT_CRAFT_EXPECT : 0
endfunction

function! Move_relative(nb_lines)
	call cursor(line('.') + a:nb_lines, 0)
endfunction

function! Git_cmd(...)
	let ret=call('system', a:000)
	if ( v:shell_error != 0 )
		echoerr "Error:\ncommand:\n" . join(a:000, "\n") . "\nret:\n" . ret
	endif
	return ret
endfunction

function! Git_commit_msg(sha1)
	let commit_cmd="git show --src-prefix='' --dst-prefix='' --format='%s%B' " . a:sha1 .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(commit_cmd)
endfunction

function! Git_status(file)
	let status_cmd="git status --porcelain -- " . a:file
	return Git_cmd(status_cmd)
endfunction

function! Git_diff(state, file)
	let staged_flag = ( a:state == 'staged' ) ? ' --staged ' : ''
	let diff_cmd="git diff --no-color --no-ext-diff --src-prefix='' --dst-prefix='' " .
				\ staged_flag . " -- " . a:file .
				\ " | \\grep -v " . g:index_regex
	return Git_cmd(diff_cmd)
endfunction

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

function! Cd_vimagit()
	cd $VIMAGIT_PATH
endfunction

function! Cd_test()
	cd $TEST_PATH
endfunction

function! Cd_test_sub()
	cd $TEST_SUB_PATH
endfunction
