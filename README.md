# vimagit

vimagit is an attempt to reproduce the magnificent emacs Magit plugin to vim. The main idea is to manage all git operations in one single buffer, as efficiently as possible.

## Outstanding features

* [x] See all your changes, staged changes, untracked/removed/renamed files in one unique buffer.
* [x] Staged/unstaged/discard changes with one key press, moving the cursor around. Stage at hunk or file level. Line and partial line staging are ongoing.
* [x] Start to write the commit message in one key press, commit also in one key press.
* [x] Visualize stashes. Apply, pop, drop are on going.
* [x] Add file to .gitignore file.
* [ ] Chase all corner cases. Please remember that vimagit is at an early development stage. If you try vimagit and nothing is working, please don't throw it, fill an issue on github :heart: !

More to come:
* Accelerate magit buffer refreshing.
* Line and partial line staging.
* Vizualize and checkout branches.
* Go through history, cherry-pick changes.

> Why should I use vimagit, there are already plethora git plugins for vim?

* fugitive is a very complete plugin, with a lot of functions. I use it for years, and it is a fundamental tool in my workflow. But visualize your changes and staged them in broad number of files is really a pain.
* vim-gitgutter is very well integrated into vim, but without the ability to commit stages, it stays an informational plugin.

## Usage

IMPORTANT: mappings can have different meanings regarding the cursor position.

### Sections:

There are 3 sections:
* Commit message: this section appears in commit mode (see below). It
  contains the message to be commited.
* Staged changes: this sections contains all staged files/hunks, ready to
  commit.
* Unstaged changes: this section contains all unstaged and untracked
  files/hunks.
* Stash list: this section contains all stahes.

### Mapping

These mappings work in normal mode. They can be redefined.

        S             if cursor is in a hunk, stage/unstage hunk at
                      cursor position
                      if cursor is in diff header, stage/unstage whole file
                      at cursor position
                      When cursor is in "Unstaged changes" section, it will
                      stage the hunk/file.
                      On the other side, when cursor is in "Staged changes"
                      section, it will unstage hunk/file.
        F             stage/unstage the whole file at cursor position
                      When cursor is in "Unstaged changes" section, it will
                      stage the file.
                      On the other side, when cursor is in "Staged changes"
                      section, it will unstage file.
        DDD           if cursor is in a hunk, discard hunk at cursor position
                      if cursor is in diff header, discard whole file at
                      cursor position
                      When cursor is in "Unstaged changes" section, it will
                      discard the hunk/file.
        R             refresh vimagit buffer
        C,CC,:w<cr>   if not in commit section, set commit mode to "New
                      commit" and show "Commit message" section with brand new
                      commit message
                      if in commit section, commit the all staged changes in
                      commit mode previously set
        CA            if not in commit section, set commit mode to "Amend
                      commit" and show "Commit message" section with previous
                      commit message
                      if in commit section, commit the staged changes in
                      commit mode previously set
        CF            amend the staged changes into the previous commit,
                      without modifying previous commit message
        I             add the file under the cursor in .gitgnore
                
## Installation

The plugin hierarchy tree respects the vim plugin standard. It is compatible
with pathogen (and most probably vundle).

To install:

    cd ~/.vim/bundle
    git clone https://github.com/jreybert/vimagit

## Requirements

This part must be refined, I don't see any minimal version for git and vim, but for sure there should be one.

## License

Copyright (c) Jerome Reybert. Distributed under the same terms as Vim itself. See :help license.
