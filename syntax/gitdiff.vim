" Vim syntax file
" Language:	generic git output
" Maintainer:	Tim Pope <vimNOSPAM@tpope.org>
" Last Change:	2010 May 21

if exists("b:current_syntax")
  finish
endif

syn case match
syn sync minlines=50

syn include @diff syntax/diff.vim

syn match titleEntry "^&@\%([^@&]\|\s\)\+@&$" contains=titleSign
if has("conceal")
	syn match titleSign contained "\%(&@\|@&\)" conceal
else
	syn match titleSign contained "\%(&@\|@&\)"
endif
hi def link titleEntry String
hi def link titleSign  Ignore

syn match stashEntry "stash@{\d\+}:.*$"
hi def link stashEntry String


syn region gitTitle start=/^$\n^&@\%([^#]\|\s\)\+@&$/ end=/^$/ contains=titleEntry

syn region gitStash start=/^stash@{\d\+}:/ end=/^\%(stash@{\d\+}:\)\@=/ contains=gitDiff,stashEntry fold
syn region gitDiff start=/^diff --git / end=/^\%(diff --\|stash@{\d\+}\|&@\%([^@&]\|\s\)\+@&$\)\@=/ contains=@diff,gitHunk fold
syn region gitHunk start=/^@@ -/ end=/^\%(diff --\|stash@{\d\+}\|@@ -\|&@\%([^@&]\|\s\)\+@&$\)\@=/ contains=@diff fold contained

let b:current_syntax = "gitdiff"
