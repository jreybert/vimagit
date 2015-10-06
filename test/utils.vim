if ( ! ( exists("$VIMAGIT_PATH") && exists("$VADER_PATH") && exists("$TEST_PATH") ) 
\ && ( ! ( isdirectory("$VIMAGIT_PATH") && isdirectory("$VADER_PATH") && isdirectory("$TEST_PATH") ) ) )
	echoerr "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH'"
endif

let g:test_dir = $VIMAGIT_PATH . '/test/'

function! Move_relative(nb_lines)
	call cursor(line('.') + a:nb_lines, 0)
endfunction

function! Git_diff(state, file, output)
	let staged_flag = ( a:state == 'staged' ) ? ' --staged ' : ''
	let diff_cmd="git diff --no-color --no-ext-diff --src-prefix='' --dst-prefix='' " .
				\ staged_flag . " -- " . a:file .
				\ " | \\grep -v \"^index [[:xdigit:]]\\{7\\}\\.\\.[[:xdigit:]]\\{7\\}\" > " .
				\ a:output)
	let diff=system(diff_cmd)
	if ( v:shell_error != 0 )
		echoerr "git diff: " . diff
	endif
	return v:shell_error
endfunction

function! Expect_diff(gold_file, test_file)
    let diff=system("diff " . a:gold_file . " " . a:test_file)
	if ( v:shell_error != 0 )
		echoerr "diff: " . diff
	endif
	return v:shell_error
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
