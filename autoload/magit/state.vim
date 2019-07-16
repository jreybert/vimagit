" magit#state#is_file_visible: file getter function
" return if file is visible
function! magit#state#is_file_visible() dict
	return self.visible
endfunction

" magit#state#set_file_visible: file setter function
" param[in] val: visible state to set to file
function! magit#state#set_file_visible(val) dict
	let self.visible = a:val
endfunction

" magit#state#toggle_file_visible: file setter function, toggle file visible
" state
function! magit#state#toggle_file_visible() dict
	let self.visible = ( self.visible == 0 ) ? 1 : 0
endfunction

" magit#state#init_file_visible: init file visible status, among several conditions
function! magit#state#init_file_visible() dict
	if ( !self.new )
		return self.is_visible()
	else
		if ( self.status == 'M' || b:magit_default_show_all_files > 1 )
			call self.set_visible(b:magit_default_show_all_files)
		endif
		return self.is_visible()
	endif
endfunction

" magit#state#is_file_dir: file getter function
" return 1 if current file is a directory, 0 otherwise
function! magit#state#is_file_dir() dict
	return self.dir != 0
endfunction

" magit#state#must_be_added: file helper function
" there are some conditions where files must be widely added (git add), not
" 'diff applied' (git apply)
" return 1 if file must 
function! magit#state#must_be_added() dict
	return ( self.empty == 1 ||
		\ self.symlink != '' ||
		\ self.dir != 0 ||
		\ self.binary == 1 ||
		\ self.submodule == 1 )
endfunction

" magit#state#file_get_hunks: function accessor for hunks objects
" return: List of List of hunks lines
function! magit#state#file_get_hunks() dict
	return self.diff.hunks
endfunction

" magit#state#file_get_flat_hunks: function accessor for hunks lines
" return: all hunks lines of a file, including hunk headers
function! magit#state#file_get_flat_hunks() dict
	let hunks = self.diff.hunks
	let lines = []
	for hunk in hunks
		call add(lines, hunk.header)
		call add(lines, hunk.lines)
	endfor
	return lines
endfunction

" s:hunk_template: template for hunk object (nested in s:diff_template)
" WARNING: this variable must be deepcopy()'ied
let s:hunk_template = {
\	'header': '',
\	'line_pos': 0,
\	'lines': [],
\	'marks': [],
\}

" s:diff_template: template for diff object (nested in s:file_template)
" WARNING: this variable must be deepcopy()'ied
let s:diff_template = {
\	'len': 0,
\	'header': [],
\	'hunks': [s:hunk_template],
\}

" s:file_template: template for file object
" WARNING: this variable must be deepcopy()'ied
let s:file_template = {
\	'new': 1,
\	'exists': 0,
\	'visible': 0,
\	'filename': '',
\	'status': '',
\	'empty': 0,
\	'dir': 0,
\	'binary': 0,
\	'submodule': 0,
\	'symlink': '',
\	'diff': s:diff_template,
\	'line_pos': 0,
\	'is_dir': function("magit#state#is_file_dir"),
\	'is_visible': function("magit#state#is_file_visible"),
\	'set_visible': function("magit#state#set_file_visible"),
\	'init_visible': function("magit#state#init_file_visible"),
\	'toggle_visible': function("magit#state#toggle_file_visible"),
\	'must_be_added': function("magit#state#must_be_added"),
\	'get_header': function("magit#state#file_get_header"),
\	'get_hunks'      : function("magit#state#file_get_hunks"),
\	'get_flat_hunks' : function("magit#state#file_get_flat_hunks"),
\	'get_filename_header' : function("magit#state#file_get_filename_header"),
\}

" magit#state#get_file: function accessor for file
" param[in] mode: can be staged or unstaged
" param[in] filename: filename to access
" param[in] create: boolean. If 1, non existing file in Dict will be created.
" if 0, 'file_doesnt_exists' exception will be thrown
" return: Dict of file
function! magit#state#get_file(mode, filename, ...) dict
	let file_exists = has_key(self.dict[a:mode], a:filename)
	let create = ( a:0 == 1 ) ? a:1 : 0
	if ( file_exists == 0 && create == 1 )
		let self.dict[a:mode][a:filename] = deepcopy(s:file_template)
		let self.dict[a:mode][a:filename].filename = a:filename
	elseif ( file_exists == 0 && create == 0 )
		throw 'file_doesnt_exists'
	endif
	return self.dict[a:mode][a:filename]
endfunction

" magit#state#file_get_header: function accessor for diff header
" param[in] mode: can be staged or unstaged
" param[in] filename: header of filename to access
" return: List of diff header lines
function! magit#state#file_get_header() dict
	return self.diff.header
endfunction

function! magit#state#file_get_filename_header() dict
	if ( self.status == 'L' )
		return g:magit_git_status_code.L . ': ' . self.filename . ' -> ' . self.symlink
	else
		return g:magit_git_status_code[self.status] . ': ' . self.filename
	endif
endfunction

function! magit#state#check_max_lines(file) dict
	let total_lines = self.nb_diff_lines + a:file.diff.len
	if ( total_lines > g:magit_warning_max_lines && b:magit_warning_max_lines_answered == 0 )
		echohl WarningMsg
		let ret = input("There are " . total_lines . " diff lines to display. Do you want to display all diffs? y(es) / N(o) : ", "")
		echohl None
		let b:magit_warning_max_lines_answered = 1
		if ( ret !~? '^y\%(e\%(s\)\?\)\?$' )
			call a:file.set_visible(0)
			let a:file.diff.len = 0
			let b:magit_default_show_all_files = 0
			return 1
		endif
	endif
	return 0
endfunction

" magit#state#add_file: method to add a file with all its
" properties (filename, exists, status, header and hunks)
" param[in] mode: can be staged or unstaged
" param[in] status: one character status code of the file (AMDRCU?)
" param[in] filename: filename
function! magit#state#add_file(mode, status, filename, depth) dict
	let file = self.get_file(a:mode, a:filename, 1)
	let file.exists = 1

	let file.status = a:status
	let file.depth = a:depth

	" discard previous diff
	let file.diff = deepcopy(s:diff_template)

	if ( a:status == '?' && getftype(a:filename) == 'link' )
		let file.status = 'L'
		let file.symlink = resolve(a:filename)
		let file.diff.hunks[0].header = 'New symbolic link file'
	elseif ( magit#utils#is_submodule(a:filename))
		let file.status = 'S'
		let file.submodule = 1
		if ( !file.is_visible() )
			return
		endif
		let diff_list=magit#git#git_sub_summary(magit#utils#add_quotes(a:filename),
					\ a:mode)
		let file.diff.len = len(diff_list)

		if ( self.check_max_lines(file) != 0 )
			return
		endif

		let file.diff.hunks[0].header = ''
		let file.diff.hunks[0].lines = diff_list
		let self.nb_diff_lines += file.diff.len
	elseif ( a:status == '?' && isdirectory(a:filename) == 1 )
		let file.status = 'N'
		let file.dir = 1
		if ( !file.is_visible() )
			return
		endif
		for subfile in magit#utils#ls_all(a:filename)
			call self.add_file(a:mode, a:status, subfile, a:depth + 1)
		endfor
	elseif ( a:status == '?' && getfsize(a:filename) == 0 )
		let file.status = 'E'
		let file.empty = 1
		let file.diff.hunks[0].header = 'New empty file'
	else
		if ( !file.init_visible() )
			return
		endif
		let line = 0
		" match(
		let [ is_bin, diff_list ] =
					\ magit#git#git_diff(magit#utils#add_quotes(a:filename),
					\ a:status, a:mode)

		if ( is_bin )
			let file.binary = 1
			let file.diff.hunks[0].header = 'Binary file'
			if ( file.new )
				call file.set_visible(0)
			endif
			return
		endif

		let file.diff.len = len(diff_list)

		if ( self.check_max_lines(file) != 0 )
			return
		endif

		while ( line < file.diff.len && diff_list[line] !~ "^@.*" )
			call add(file.diff.header, diff_list[line])
			let line += 1
		endwhile

		if ( line < file.diff.len )
			let hunk = file.diff.hunks[0]
			let hunk.header = diff_list[line]

			for diff_line in diff_list[line+1 : -1]
				if ( diff_line =~ "^@.*" )
					let hunk = deepcopy(s:hunk_template)
					call add(file.diff.hunks, hunk)
					let hunk.header = diff_line
					continue
				endif
				call add(hunk.lines, diff_line)
			endfor
		endif
		let self.nb_diff_lines += file.diff.len
	endif

endfunction

" magit#state#update: update self.dict
" if a file does not exists anymore (because all its changes have been
" committed, deleted, discarded), it is removed from g:mg_diff_dict
" else, its diff is discarded and regenrated
" what is resilient is its 'visible' parameter
function! magit#state#update() dict
	let self.nb_diff_lines = 0
	for diff_dict_mode in values(self.dict)
		for file in values(diff_dict_mode)
			let file.exists = 0
			let file.new = 0
			" always discard previous diff
			let file.diff = deepcopy(s:diff_template)
		endfor
	endfor

	let dir = getcwd()
	try
		call magit#utils#chdir(magit#git#top_dir())
		call magit#utils#refresh_submodule_list()
		let status_list = magit#git#get_status()
		for [mode, diff_dict_mode] in items(self.dict)
			for file_status in status_list
				let status=file_status[mode]

				" untracked code apperas in staged column, we skip it
				if ( status == ' ' || ( ( mode == 'staged' ) && status == '?' ) )
					continue
				endif
				call self.add_file(mode, status, file_status.filename, 0)
			endfor
		endfor
	finally
		call magit#utils#chdir(dir)
	endtry

	" remove files that have changed their mode or been committed/deleted/discarded...
	for diff_dict_mode in values(self.dict)
		for [key, file] in items(diff_dict_mode)
			if ( file.exists == 0 )
				unlet diff_dict_mode[key]
			endif
		endfor
	endfor
endfunction

" magit#state#set_files_visible: global dict setter function
" update all files visible state
" param[in] is_visible: boolean value to set to files
function! magit#state#set_files_visible(is_visible) dict
	for diff_dict_mode in values(self.dict)
		for file in values(diff_dict_mode)
			call file.set_visible(a:is_visible)
		endfor
	endfor
endfunction

" magit#state#get_files: global dict file objects getter function
" param[in] mode: mode to select, can be 'staged' or 'unstaged'
" return list of file objects belonging to mode
function! magit#state#get_files(mode) dict
	return self.dict[a:mode]
endfunction

" magit#state#get_files_nb: returns the number of files in a given section
" param[in] mode: mode to select, can be 'staged' or 'unstaged'
" return number of files of this section
function! magit#state#get_files_nb(mode) dict
	return len(self.dict[a:mode])
endfunction

" magit#state#get_files: global dict file objects (copy) getter function
" param[in] mode: mode to select, can be 'staged' or 'unstaged'
" return ordered list of file objects belonging to mode
function! magit#state#get_files_ordered(mode) dict
	let modified = []
	let others = []
	for filename in sort(keys(self.dict[a:mode]))
		let file = self.get_file(a:mode, filename)
		if ( file.status == 'M' )
			call add(modified, file)
		else
			call add(others, file)
		endif
	endfor
	return modified + others
endfunction

" magit#state#get_filenames: global dict filenames getter function
" param[in] mode: mode to select, can be 'staged' or 'unstaged'
" return ordered list of filename strings belonging to mode, modified files
" first
function! magit#state#get_filenames(mode) dict
	let files = self.get_files_ordered(a:mode)
	return map(copy(files), 'v:val.filename')
endfunction


" dict: structure containing all diffs
" It is formatted as follow
" {
"   'staged': {
"       'filename': s:file_template,
"       'filename': s:file_template,
"       ...
"   },
"   'unstaged': {
"       'filename': s:file_template,
"       'filename': s:file_template,
"       ...
"   },
" }
let magit#state#state = {
			\ 'nb_diff_lines': 0,
			\ 'get_file': function("magit#state#get_file"),
			\ 'get_files': function("magit#state#get_files"),
			\ 'get_files_nb': function("magit#state#get_files_nb"),
			\ 'get_files_ordered': function("magit#state#get_files_ordered"),
			\ 'get_filenames': function("magit#state#get_filenames"),
			\ 'add_file': function("magit#state#add_file"),
			\ 'set_files_visible': function("magit#state#set_files_visible"),
			\ 'check_max_lines': function("magit#state#check_max_lines"),
			\ 'update': function("magit#state#update"),
			\ 'dict': { 'staged': {}, 'unstaged': {}},
			\ }

