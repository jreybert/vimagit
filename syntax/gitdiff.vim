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

syn region gitHunk start=/^@@ -/ end=/^\%(diff --\|@@ -\|$\)\@=/ contains=@diff fold contained
syn region gitDiff start=/^diff --git / end=/^\%(diff --\|$\)\@=/ contains=gitHunk,@diff fold transparent

let b:current_syntax = "gitdiff"
