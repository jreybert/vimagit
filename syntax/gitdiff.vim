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

syn match titleEntry "^##\%([^#]\|\s\)\+##$" contains=titleSign
if has("conceal")
	syn match titleSign contained "##" conceal
else
	syn match titleSign contained "##"
endif
hi def link titleEntry String
hi def link titleSign  Ignore

syn region gitTitle start=/^$\n^##\%([^#]\|\s\)\+##$/ end=/^$/ contains=titleEntry

syn region gitHunk start=/^@@ -/ end=/^\%(diff --\|@@ -\|^##\%([^#]\|\s\)\+##$\|$\)\@=/ contains=@diff fold contained
syn region gitDiff start=/^diff --git / end=/^\%(diff --\|^##\%([^#]\|\s\)\+##$\|$\)\@=/ contains=gitHunk,@diff fold transparent

let b:current_syntax = "gitdiff"
