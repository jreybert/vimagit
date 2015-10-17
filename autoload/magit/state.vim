function! magit#state#is_file_visible(section, filename) dict
	return ( has_key(self.dict[a:section], a:filename) &&
		 \ ( self.dict[a:section][a:filename]['visible'] == 1 ) )
endfunction

function! magit#state#get_files(mode) dict
	return self.dict[a:mode]
endfunction

" magit#state#get_file: function accessor for file
" param[in] mode: can be staged or unstaged
" param[in] filename: filename to access
" param[in] create: boolean. If 1, non existing file in Dict will be created.
" if 0, 'file_doesnt_exists' exception will be thrown
" return: Dict of file
function! magit#state#get_file(mode, filename, create) dict
	let file_exists = has_key(self.dict[a:mode], a:filename)
	if ( file_exists == 0 && a:create == 1 )
		let self.dict[a:mode][a:filename] = {}
		let self.dict[a:mode][a:filename]['visible'] = 0
	elseif ( file_exists == 0 && a:create == 0 )
		throw 'file_doesnt_exists'
	endif
	return self.dict[a:mode][a:filename]
endfunction

" magit#state#get_header: function accessor for diff header
" param[in] mode: can be staged or unstaged
" param[in] filename: header of filename to access
" return: List of diff header lines
function! magit#state#get_header(mode, filename) dict
	let diff_dict_file = self.get_file(a:mode, a:filename, 0)
	return diff_dict_file['diff'][0]
endfunction

" magit#state#get_hunks: function accessor for hunks
" param[in] mode: can be staged or unstaged
" param[in] filename: hunks of filename to access
" return: List of List of hunks lines
function! magit#state#get_hunks(mode, filename) dict
	let diff_dict_file = self.get_file(a:mode, a:filename, 0)
	return diff_dict_file['diff'][1:-1]
endfunction

" magit#state#add_file: method to add a file with all its
" properties (filename, exists, status, header and hunks)
" param[in] mode: can be staged or unstaged
" param[in] status: one character status code of the file (AMDRCU?)
" param[in] filename: filename
function! magit#state#add_file(mode, status, filename) dict
	let dev_null = ( a:status == '?' ) ? " /dev/null " : " "
	let staged_flag = ( a:mode == 'staged' ) ? " --staged " : " "
	let diff_cmd="git diff --no-ext-diff " . staged_flag .
				\ "--no-color --patch -- " . dev_null . " "
				\ .  magit#utils#add_quotes(a:filename)
	let diff_list=magit#utils#systemlist(diff_cmd)
	if ( empty(diff_list) )
		echoerr "diff command \"" . diff_cmd . "\" returned nothing"
	endif
	let diff_dict_file = self.get_file(a:mode, a:filename, 1)
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

" magit#state#update: update self.dict
" if a file does not exists anymore (because all its changes have been
" committed, deleted, discarded), it is removed from g:mg_diff_dict
" else, its diff is discarded and regenrated
" what is resilient is its 'visible' parameter
function! magit#state#update() dict
	for diff_dict_mode in values(self.dict)
		for file in values(diff_dict_mode)
			let file['exists'] = 0
			" always discard previous diff
			unlet file['diff']
		endfor
	endfor

	for [mode, diff_dict_mode] in items(self.dict)

		let status_list = magit#git#get_status()
		for file_status in status_list
			let status=file_status[mode]

			" untracked code apperas in staged column, we skip it
			if ( status == ' ' || ( ( mode == 'staged' ) && status == '?' ) )
				continue
			endif
			call self.add_file(mode, status, file_status['filename'])
		endfor
	endfor

	" remove files that have changed their mode or been committed/deleted/discarded...
	for diff_dict_mode in values(self.dict)
		for [key, file] in items(diff_dict_mode)
			if ( file['exists'] == 0 )
				unlet diff_dict_mode[key]
			endif
		endfor
	endfor
endfunction

" dict: structure containing all diffs
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
let magit#state#state = {
			\ 'get_file': function("magit#state#get_file"),
			\ 'get_files': function("magit#state#get_files"),
			\ 'get_header': function("magit#state#get_header"),
			\ 'get_hunks': function("magit#state#get_hunks"),
			\ 'add_file': function("magit#state#add_file"),
			\ 'is_file_visible': function("magit#state#is_file_visible"),
			\ 'update': function("magit#state#update"),
			\ 'dict': { 'staged': {}, 'unstaged': {}},
			\ }

