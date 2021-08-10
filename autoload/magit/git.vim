function! magit#git#get_version()
	if ( !exists("s:git_version") )
		let s:git_version = matchlist(system(g:magit_git_cmd . " --version"),
		\ 'git version \(\d\+\)\.\(\d\+\)\.\(\d\+\)\.\(\d\+\)\.\(g\x\+\)')[1:5]
	endif
	return s:git_version
endfunction

function! magit#git#is_version_sup_equal(major, minor, rev)
	let git_ver = magit#git#get_version()
	return ( ( a:major > git_ver[0] ) ||
			\ (a:major >= git_ver[0] && a:minor > git_ver[1] ) ||
			\ (a:major >= git_ver[0] && a:minor >= git_ver[1] && a:rev >= git_ver[2] )
			\ )
endfunction

" magit#git#get_status: this function returns the git status output formated
" into a List of Dict as
" [ {staged', 'unstaged', 'filename'}, ... ]
function! magit#git#get_status()
	let file_list = []

	" systemlist v7.4.248 problem again
	" we can't use git status -z here, because system doesn't make the
	" difference between NUL and NL. -status z terminate entries with NUL,
	" instead of NF
	let status_list=magit#sys#systemlist(g:magit_git_cmd . " status --porcelain")
	for file_status_line in status_list
		let line_match = matchlist(file_status_line, '\(.\)\(.\) \%(.\{-\} -> \)\?"\?\(.\{-\}\)"\?$')
		let filename = line_match[3]
		call add(file_list, { 'staged': line_match[1], 'unstaged': line_match[2], 'filename': filename })
	endfor
	return file_list
endfunction

function! magit#git#get_config(conf_name, default)
	try
		silent! let git_result=magit#utils#strip(
				\ magit#sys#system(g:magit_git_cmd . " config --get " . a:conf_name))
	catch 'shell_error'
		return a:default
	endtry
	return git_result
endfunction

" magit#git#is_work_tree: this function check that path passed as parameter is
" inside a git work tree
" param[in] path: path to check
" return: top work tree path if in a work tree, empty string otherwise
function! magit#git#is_work_tree(path)
	let dir = getcwd()
	try
		call magit#utils#chdir(a:path)
		let top_dir=system(g:magit_git_cmd . " rev-parse --show-toplevel")
		if ( executable("cygpath") )
			let top_dir = magit#utils#strip(system("cygpath " . top_dir))
		endif
		if ( v:shell_error != 0 )
			return ''
		endif
		return magit#utils#strip(top_dir) . "/"
	finally
		call magit#utils#chdir(dir)
	endtry
endfunction

" magit#git#set_top_dir: this function set b:magit_top_dir and b:magit_git_dir 
" according to a path
" param[in] path: path to set. This path must be in a git repository work tree
function! magit#git#set_top_dir(path)
	let dir = getcwd()
	try
		call magit#utils#chdir(a:path)
		try
			let top_dir=magit#utils#strip(
						\ system(g:magit_git_cmd . " rev-parse --show-toplevel")) . "/"
			let git_dir=magit#utils#strip(system(g:magit_git_cmd . " rev-parse --git-dir")) . "/"
			if ( executable("cygpath") )
				let top_dir = magit#utils#strip(system("cygpath " . top_dir))
				let git_dir = magit#utils#strip(system("cygpath " . git_dir))
			endif
		catch 'shell_error'
			call magit#sys#print_shell_error()
			throw 'set_top_dir_error'
		endtry
		let b:magit_top_dir=top_dir
		let b:magit_git_dir=git_dir
	finally
		call magit#utils#chdir(dir)
	endtry
endfunction

" magit#git#top_dir: return the absolute path of current git worktree for the
" current magit buffer
" return top directory
function! magit#git#top_dir()
	if ( !exists("b:magit_top_dir") )
		throw 'top_dir_not_set'
	endif
	return b:magit_top_dir
endfunction

" magit#git#git_dir: return the absolute path of current git worktree
" return git directory
function! magit#git#git_dir()
	if ( !exists("b:magit_git_dir") )
		throw 'git_dir_not_set'
	endif
	return b:magit_git_dir
endfunction

" magit#git#git_diff: helper function to get diff of a file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" WARNING: diff is generated without prefix. To apply this diff, git apply
" must use the option -p0.
" param[in] filemane: it must be quoted if it contains spaces
" param[in] status: status of the file (see g:magit_git_status_code)
" param[in] mode: can be staged or unstaged
" return: two values
"        [0]: boolean, if true current file is binary
"        [1]: string array containing diff output
function! magit#git#git_diff(filename, status, mode)
	let dev_null = ( a:status == '?' ) ? "/dev/null " : ""
	let staged_flag = ( a:mode == 'staged' ) ? "--staged" : ""
	let git_cmd=g:magit_git_cmd . " diff --no-ext-diff " . staged_flag .
				\ " --no-prefix --no-color -p -U" . b:magit_diff_context .
				\ " -- " . dev_null . " " . a:filename

	if ( a:status != '?' )
		try
			silent let diff_list=magit#sys#systemlist(git_cmd)
		catch 'shell_error'
			call magit#sys#print_shell_error()
			throw 'diff error'
		endtry
	else
		silent let diff_list=magit#sys#systemlist_noraise(git_cmd)
	endif

	if ( empty(diff_list) )
		echohl WarningMsg
		echom "diff command \"" . git_cmd . "\" returned nothing"
		echohl None
		throw 'diff error'
	endif
	return [
		\ ( diff_list[-1] =~ "^Binary files .* differ$" && len(diff_list) <= 4 )
		\, diff_list ]
endfunction

" magit#git#sub_check: this function checks if given submodule has modified or
" untracked content
" param[in] submodule: submodule path
" param[in] check_level: can be modified or untracked
function! magit#git#sub_check(submodule, check_level)
	let ignore_flag = ( a:check_level == 'modified' ) ?
				\ '--ignore-submodules=untracked' : ''
	let git_cmd=g:magit_git_cmd . " status --porcelain " . ignore_flag . " " . a:submodule
	return ( !empty(magit#sys#systemlist(git_cmd)) )
endfunction

" magit#git#git_sub_summary: helper function to get diff of a submodule
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
" param[in] mode: can be staged or unstaged
function! magit#git#git_sub_summary(filename, mode)
	let staged_flag = ( a:mode == 'staged' ) ? " --cached " : " --files "
	let git_cmd=g:magit_git_cmd . " submodule summary " . staged_flag . " HEAD "
				\ .a:filename
	silent let diff_list=magit#sys#systemlist(git_cmd)
	if ( empty(diff_list) )
		if ( a:mode == 'unstaged' )
			if ( magit#git#sub_check(a:filename, 'modified') )
				return "modified content"
			endif
			if ( magit#git#sub_check(a:filename, 'untracked') )
				return "untracked content"
			endif
		endif
		echohl WarningMsg
		echom "diff command \"" . git_cmd . "\" returned nothing"
		echohl None
		throw 'diff error'
	endif
	return diff_list
endfunction

" magit#git#git_add: helper function to add a whole file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
function! magit#git#git_add(filename)
	let git_cmd=g:magit_git_cmd . " add --no-ignore-removal -- " . a:filename
	try
		silent let git_result=magit#sys#system(git_cmd)
	catch 'shell_error'
		call magit#sys#print_shell_error()
		throw 'add error'
	endtry
endfunction

" magit#git#git_checkout: helper function to add a whole file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
function! magit#git#git_checkout(filename)
	let git_cmd=g:magit_git_cmd . " checkout -- " . a:filename
	try
		silent let git_result=magit#sys#system(git_cmd)
	catch 'shell_error'
		call magit#sys#print_shell_error()
		throw 'checkout error'
	endtry
endfunction

" magit#git#git_reset: helper function to add a whole file
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] filemane: it must be quoted if it contains spaces
function! magit#git#git_reset(filename)
	let git_cmd=g:magit_git_cmd . " reset HEAD -- " . a:filename
	try
		silent let git_result=magit#sys#system(git_cmd)
	catch 'shell_error'
		call magit#sys#print_shell_error()
		throw 'reset error'
	endtry
endfunction

" magit#git#git_apply: helper function to stage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git#git_apply(header, selection)
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	let git_cmd=g:magit_git_cmd . " apply --recount --no-index --cached -p0 -"
	try
		silent let git_result=magit#sys#system(git_cmd, selection)
	catch 'shell_error'
		call magit#sys#print_shell_error()
		echom "Tried to aply this"
		echom string(selection)
		throw 'apply error'
	endtry
endfunction

" magit#git#git_unapply: helper function to unstage a selection
" nota: when git fail (due to misformated patch for example), an error
" message is raised.
" param[in] selection: the text to stage. It must be a patch, i.e. a diff 
" header plus one or more hunks
" return: no
function! magit#git#git_unapply(header, selection, mode)
	let cached_flag=''
	if ( a:mode == 'staged' )
		let cached_flag=' --cached '
	endif
	let selection = magit#utils#flatten(a:header + a:selection)
	if ( selection[-1] !~ '^$' )
		let selection += [ '' ]
	endif
	try
		silent let git_result=magit#sys#system(
			\ g:magit_git_cmd . " apply --recount --no-index -p0 --reverse " .
			\ cached_flag . " - ", selection)
	catch 'shell_error'
		call magit#sys#print_shell_error()
		echom "Tried to unaply this"
		echom string(selection)
		throw 'unapply error'
	endtry
endfunction

" magit#git#submodule_list: helper function to return the submodule list
" return array of submodule names
function! magit#git#submodule_list()
	return map(split(magit#sys#system(
				\ g:magit_git_cmd . " ls-files --stage | \grep 160000 || true"),
				\ "\n"), 'split(v:val)[3]')
endfunction

" magit#git#get_branch_name: get the branch name given a reference
" WARNING does not seem to work with SHA1
" param[in] ref can be HEAD or a branch name
" return branch name
function! magit#git#get_branch_name(ref)
	return magit#utils#strip(magit#sys#system(g:magit_git_cmd . " rev-parse --abbrev-ref " . a:ref))
endfunction

" magit#git#count_object: this function returns the output of git
" count-objects, in a dict object
" It contains the following information: count, size, in-pack, packs,
" size-pack, prune-packable, garbage, size-garbage
function! magit#git#count_object()
	let count_object=magit#sys#systemlist(g:magit_git_cmd . " count-objects -v")
	let refs={}
	for line in count_object
		let ref=split(line, ":")
		let refs[ref[0]] = ref[1]
	endfor
	return refs
endfunction

" magit#git#check_repo: check the health of the repo
" return 0 if everything is fine, 1 otherwise
function! magit#git#check_repo()
	try
		let head_br=magit#git#get_branch_name("HEAD")
	catch 'shell_error'
		let object_count = magit#git#count_object()['count']
		if ( object_count != 0 )
			return 1
		endif
	endtry
	return 0
endfunction

" magit#git#get_commit_subject: get the subject of a commit (first line)
" param[in] ref: reference, can be SHA1, brnach name or HEAD
" return commit subject
function! magit#git#get_commit_subject(ref)
	try
		return magit#utils#strip(magit#sys#system(g:magit_git_cmd . " show " .
					\" --no-prefix --no-patch --format=\"%s\" " . a:ref))
	catch 'shell_error'
		return ""
	endtry
endfunction

" magit#git#get_remote_branch: get the branch name of the default remote, for
" upstream and push
" WARNING does not work with SHA1
" param[in] ref: reference, can be HEAD or branch name
" param[in] type: type of default remote: upstream or push
" return the remote branch name, 'none' if it has not
function! magit#git#get_remote_branch(ref, type)
	try
		return magit#utils#strip(magit#sys#system(
			\ g:magit_git_cmd . " rev-parse --abbrev-ref=loose " . a:ref . "@{" . a:type . "}"))
	catch 'shell_error'
		return "none"
	endtry
endfunction
