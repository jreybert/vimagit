
" g:mg_diff_dict: big main global variable, containing all diffs
" It is formatted as follow
" { 'staged_or_unstaged': staged/unstaged
"     [
"         { 'filename':
"             { 'visible': bool,
"               'status' : g:magit_git_status_code,
"               'exists' : bool
"               'diff'   : [ [header], [hunk0], [hunk1], ...]
"             }
"          },
"          ...
"      ]
" }
let g:mg_diff_dict = { 'staged': {}, 'unstaged': {} }

" magit#state#get_file: mg_diff_dict accessor for file
" param[in] mode: can be staged or unstaged
" param[in] filename: filename to access
" param[in] create: boolean. If 1, non existing file in Dict will be created.
" if 0, 'file_doesnt_exists' exception will be thrown
" return: Dict of file
function! magit#state#get_file(mode, filename, create)
	let file_exists = has_key(g:mg_diff_dict[a:mode], a:filename)
	if ( file_exists == 0 && a:create == 1 )
		let g:mg_diff_dict[a:mode][a:filename] = {}
		let g:mg_diff_dict[a:mode][a:filename]['visible'] = 0
	elseif ( file_exists == 0 && a:create == 0 )
		throw 'file_doesnt_exists'
	endif
	return g:mg_diff_dict[a:mode][a:filename]
endfunction

" magit#state#get_header: mg_diff_dict accessor for diff header
" param[in] mode: can be staged or unstaged
" param[in] filename: header of filename to access
" return: List of diff header lines
function! magit#state#get_header(mode, filename)
	let diff_dict_file = magit#state#get_file(a:mode, a:filename, 0)
	return diff_dict_file['diff'][0]
endfunction

" magit#state#get_hunks: mg_diff_dict accessor for hunks
" param[in] mode: can be staged or unstaged
" param[in] filename: hunks of filename to access
" return: List of List of hunks lines
function! magit#state#get_hunks(mode, filename)
	let diff_dict_file = magit#state#get_file(a:mode, a:filename, 0)
	return diff_dict_file['diff'][1:-1]
endfunction

" magit#state#add_file: mg_diff_dict method to add a file with all its
" properties (filename, exists, status, header and hunks)
" param[in] mode: can be staged or unstaged
" param[in] status: one character status code of the file (AMDRCU?)
" param[in] filename: filename
function! magit#state#add_file(mode, status, filename)
	let dev_null = ( a:status == '?' ) ? " /dev/null " : " "
	let staged_flag = ( a:mode == 'staged' ) ? " --staged " : " "
	let diff_cmd="git diff --no-ext-diff " . staged_flag .
				\ "--no-color --patch -- " . dev_null . " "
				\ .  magit#utils#add_quotes(a:filename)
	let diff_list=magit#utils#systemlist(diff_cmd)
	if ( empty(diff_list) )
		echoerr "diff command \"" . diff_cmd . "\" returned nothing"
	endif
	let diff_dict_file = magit#state#get_file(a:mode, a:filename, 1)
	let diff_dict_file['diff'] = []
	let diff_dict_file['exists'] = 1
	let diff_dict_file['status'] = a:status
	let diff_dict_file['empty'] = 0
	let diff_dict_file['binary'] = 0
	let diff_dict_file['symlink'] = ''
	if ( a:status == '?' && getftype(a:filename) == 'link' )
		let diff_dict_file['symlink'] = resolve(a:filename)
		call add(diff_dict_file['diff'], ['no header'])
		call add(diff_dict_file['diff'], ['New symbolic link file'])
	elseif ( a:status == '?' && getfsize(a:filename) == 0 )
		let diff_dict_file['empty'] = 1
		call add(diff_dict_file['diff'], ['no header'])
		call add(diff_dict_file['diff'], ['New empty file'])
	elseif ( match(system("file --mime " .
				\ magit#utils#add_quotes(a:filename)),
				\ a:filename . ".*charset=binary") != -1 )
		let diff_dict_file['binary'] = 1
		call add(diff_dict_file['diff'], ['no header'])
		call add(diff_dict_file['diff'], ['Binary file'])
	else
		let index = 0
		call add(diff_dict_file['diff'], [])
		for diff_line in diff_list
			if ( diff_line =~ "^@.*" )
				let index+=1
				call add(diff_dict_file['diff'], [])
			endif
			call add(diff_dict_file['diff'][index], diff_line)
		endfor
	endif
endfunction

" magit#state#update: update g:mg_diff_dict
" if a file does not exists anymore (because all its changes have been
" committed, deleted, discarded), it is removed from g:mg_diff_dict
" else, its diff is discarded and regenrated
" what is resilient is its 'visible' parameter
function! magit#state#update()
	for diff_dict_mode in values(g:mg_diff_dict)
		for file in values(diff_dict_mode)
			let file['exists'] = 0
			" always discard previous diff
			unlet file['diff']
		endfor
	endfor

	for [mode, diff_dict_mode] in items(g:mg_diff_dict)

		let status_list = magit#git#get_status()
		for file_status in status_list
			let status=file_status[mode]

			" untracked code apperas in staged column, we skip it
			if ( status == ' ' || ( ( mode == 'staged' ) && status == '?' ) )
				continue
			endif
			call magit#state#add_file(mode, status, file_status['filename'])
		endfor
	endfor

	" remove files that have changed their mode or been committed/deleted/discarded...
	for diff_dict_mode in values(g:mg_diff_dict)
		for [key, file] in items(diff_dict_mode)
			if ( file['exists'] == 0 )
				unlet diff_dict_mode[key]
			endif
		endfor
	endfor
endfunction
