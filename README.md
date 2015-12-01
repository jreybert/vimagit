# vimagit

This is a new (and hopefully very efficient) way to use git from vim.

From a very single vim buffer, you can perform all basic git operations. To name a few:
* Visualize all diffs in your git repository.
* Stage files/hunks/parts of hunks with single key S.
* Write or amend your commit message and commit.

See a usage example on asciicast:
[![asciicast](https://asciinema.org/a/28761.png)](https://asciinema.org/a/28761)

And a [commented video presenting vimagit](https://youtu.be/_3wMmmVi6bU) (thank you [Mike Hartington](https://github.com/mhartington)!)

This workflow is 100% inspired from magnificent emacs [Magit](https://github.com/magit/magit) plugin.

Take a look at [TL;DR](#tldr) to start using it immediatly.

## Outstanding features

* [x] See all your changes, staged changes, untracked/removed/renamed files in one unique buffer.
* [x] Staged/unstaged/discard changes with one key press, moving the cursor around. Stage at hunk or file level. Line and partial line staging are ongoing.
* [x] Stage part of hunks, by visual select, lines or selecting bunch of lines with marks.
* [x] Start to write the commit message in one key press, commit also in one key press.
* [x] Modify in line the content just before staging it.
* [x] Move easily through hunks.
* [x] Handle multiple git repositories within one vim instance.
* [x] Add file to .gitignore file.
* [ ] Chase all corner cases. Please remember that vimagit is at an early development stage. If you try vimagit and nothing is working, please don't throw it, fill an [issue](https://github.com/jreybert/vimagit/issues/new) on github :heart: !

More to come:
* Make vimagit more efficient for huge repositories, with a lot of diffs.
* Add a push function, taking care if needed about the remote repository and branch.
* Handle commit fixup! and squash!, with a smart git log popup.
* Handle multiple git repositories within one vim session.
* Stage multiple hunks or file by visually selecting them.
* Go through history, cherry-pick changes.
* Handle stash: add, pop, apply, drop...
* Vizualize and checkout branches.
* Something is missing? Open an [issue](https://github.com/jreybert/vimagit/issues/new)!

> Why should I use vimagit, there are already plethora git plugins for vim?

* fugitive is a very complete plugin, with a lot of functions. I use it for years, and it is a fundamental tool in my workflow. But visualize your changes and staged them in broad number of files is really a pain.
* vim-gitgutter is very well integrated into vim, but without the ability to commit stages, it stays an informational plugin.

## Integration

Branches [master](https://github.com/jreybert/vimagit/) and [next](https://github.com/jreybert/vimagit/tree/next) are continuously tested on [travis](https://travis-ci.org/jreybert/vimagit) when published on github.

vimagit is tested with various versions of vim on linux: vim 7.3.249, vim 7.4.273, and latest neovim version. It is also tested for macos X: vim, macvim and neovim. Anyway, if you feel that vimagit behaves oddly (slow refresh, weird display order...) please fill an [issue](https://github.com/jreybert/vimagit/issues/new).

For the most enthusiastic, you can try the branch [next](https://github.com/jreybert/vimagit/tree/next). It is quite stable, just check its travis status before fetching it.

Travis status:
* **[master status](https://travis-ci.org/jreybert/vimagit/branches)**: [![Master build status](https://travis-ci.org/jreybert/vimagit.svg?branch=master)](https://travis-ci.org/jreybert/vimagit/branches)
* **[next status](https://travis-ci.org/jreybert/vimagit/branches)**: [![next build status](https://travis-ci.org/jreybert/vimagit.svg?branch=next)](https://travis-ci.org/jreybert/vimagit/branches)

## TL;DR

This is the minimal required set of command you must know to start playing with vimagit. See [Mapping](#mapping) for a complete description.

To simply test vimagit, modify/add/delete/rename some files in a git repository and open vim.

#### :Magit

Open magit buffer with [:Magit](#magitshow_magit) command.

#### N

* Jump to next hunk with **N**. The cursor should be on the header of a hunk.

#### S

* If the hunk is in "Unstage changes" section, press **S** in Normal mode: the hunk is now staged, and appears in "Staged changes" section. The opposite is also possible, i.e. unstage a hunk from "Staged section".
* If you move the cursor to the file header and press **S**, the whole file is staged.

#### CC

Once you have stage all the required changes, press **CC**. A new section "Commit message" appears and cursor move to it. Type your commit message, in Insert mode this time. Once it's done, go back in Normal mode, and press **CC**: you created your first commit with vimagit!

## Usage

### Sections

IMPORTANT: mappings can have different meanings regarding the cursor position.

There are 5 sections:
* Info: this section display some information about the git repository, like the current branch and the HEAD commit.
* Commit message: this section appears in commit mode (see below). It contains the message to be commited.
* Staged changes: this sections contains all staged files/hunks, ready to commit.
* Unstaged changes: this section contains all unstaged and untracked files/hunks.
* Stash list: this section contains all stahes.

### Inline modifications
* It is possible to modify the content to be staged or unstaged in magit buffer, with some limitations:
  * only lines starting with a + sign can be modified
  * no line can be deleted

### Visual selection

It is possible to stage part of hunk, by different ways:
* By visually selecting some lines, then staging the selection with **S**.
* By marking some lines "to be staged" with **M**, then staging these selected lines with **S**.
* Staging individual lines with **L**.

Visual selection and marked lines have some limitations for the moment:
* It only work for "staging", not for "unstaging".
* Selection/marks must be within a single hunk.
* Marks not within the hunk currently staged are lost during stage process magit buffer refresh.

### Commands

#### magit#show_magit()

Function to open magit buffer. This buffer will handle the git repository including focused file.
It is possible to handle multiple git repositories within one vim instance.

It takes 3 parameters:
  * orientation (mandatory): it can be
      - 'v', curent window is split vertically, and magit is displayed in new
        buffer
      - 'h', curent window is split horizontally, and magit is displayed in
        new buffer
      - 'c', magit is displayed in current buffer
  * show_all_files: define how file diffs are shown by default for this session
    (see [g:magit_default_show_all_files](#gmagit_default_show_all_files))
  * foldlevel: set default magit buffer foldlevel for this session
    (see [g:magit_default_fold_level](#gmagit_default_fold_level))

#### :Magit
Open magit buffer in a vertical split (see [details](magitshow_magit)).

#### :MagitOnly
Open magit buffer in current window (see [details](magitshow_magit)).

You can create a bash alias like magit="vim -c MagitOnly"

### Mappings

For each mapping, user can redefine the behavior with its own mapping. Each variable is described in vimagit help like *vimagit-g:magit_nameofmapping_mapping*

#### Global mappings

Following mappings are broadly set, and are applied in all vim buffers.

##### \<Leader>M
Open Magit buffer

#### Local mappings

Following mappings are set locally, for magit buffer only, in normal mode.

##### Enter,\<CR\>
 * All files are folded by default. To see the changes in a file, move cursor to the filename line, and press Enter. You can close the changes display retyping Enter.

##### zo,zO
 * Typing zo on a file will unhide its diffs.

##### zc,zC
 * Typing zc on a file will hide its diffs.

##### S
 * If cursor is in a hunk, stage/unstage hunk at cursor position.
 * If cursor is in diff header, stage/unstage whole file at cursor position.
 * If some lines in the hunk are selected (using **v**), stage only visual selected lines (only works for staging).
 * If some lines in the hunk are marked (using **M**), stage only marked lines (only works for staging).
 * When cursor is in "Unstaged changes" section, it will stage the hunk/file.
 * On the other side, when cursor is in "Staged changes" section, it will unstage hunk/file.

##### F
 * Stage/unstage the whole file at cursor position.
 * When cursor is in "Unstaged changes" section, it will stage the file.
 * On the other side, when cursor is in "Staged changes" section, it will unstage file.

##### L
 * Stage the line under the cursor.

##### M
 * Mark the line under the cursor "to be staged".
 * If some lines in the hunk are selected (using **v**), mark selected lines "to be staged".
 * To staged marked lines in a hunk, move cursor to this hunk and press **S**.

##### DDD
 * If cursor is in a hunk, discard hunk at cursor position.
 * If cursor is in diff header, discard whole file at cursor position.
 * Only works in "Unstaged changes" section.

##### N,P
 * Move to **N**ext or **P**revious hunk.

##### CC
 * If not in commit section, set commit mode to "New commit" and show "Commit message" section with brand new commit message.
 * If in commit section, commit the all staged changes in commit mode previously set.

##### CA
 * If not in commit section, set commit mode to "Amend commit" and show "Commit message" section with previous commit message.
 * If in commit section, commit the staged changes in commit mode previously set.

##### CF
 * Amend the staged changes into the previous commit, without modifying previous commit message.

##### I
 * Add the file under the cursor in .gitgnore

##### R
 * Refresh magit buffer

##### q
 * Close the magit buffer

##### h
 * Toggle help showing in magit buffer

### Options

User can define in its prefered |vimrc| some options.

#### g:magit_enabled

To enable or disable vimagit plugin.
Default value is 1.
> let g:magit_enabled=[01]

#### g:magit_show_help

To disable chatty inline help in magit buffer (default 1)
> let g:magit_show_help=[01]

#### g:magit_default_show_all_files

When this variable is set to 0, all diff files are hidden by default.
When this variable is set to 1, all diff for modified files are shown by default.
When this variable is set to 2, all diff for all files are shown by default.
Default value is 1.
NB: for repository with large number of differences, display may be slow.
> let g:magit_default_show_all_files=[012]

#### g:magit_default_fold_level

Default foldlevel for magit buffer.
When set to 0, both filenames and hunks are folded.
When set to 1, filenames are unfolded and hunks are folded.
When set to 2, filenames and hunks are unfolded.
Default value is 1.
> let g:magit_default_fold_level=[012]

#### g:magit_default_sections

With this variable, the user is able to choose which sections are displayed in magit
buffer, and in which order.
Default value:
> let g:magit_default_sections = ['info', 'global_help', 'commit', 'staged', 'unstaged']

#### g:magit_warning_max_lines

This variable is the maximum number of diff lines that vimagit will display
without warning the user. If the number of diff lines to display is greater than
this variable, vimagit will ask a confirmation to the user before refreshing the
buffer. If user answer is 'yes', vimagit will display diff lines as expected.
If user answer is 'no', vimagit will close all file diffs before refreshing.
Default value is 10000.
> let g:magit_warning_max_lines=val

## Installation

The plugin hierarchy tree respects the vim plugin standard. It is compatible
with pathogen (and most probably vundle).

To install:

    cd ~/.vim/bundle
    git clone https://github.com/jreybert/vimagit

## Requirements

This part must be refined, I don't see any minimal version for git and vim, but for sure there should be one.

At least, it is tested with vim 7.3.249 and git 1.8.5.6 (see [Integration](#integration)).

## License

Copyright (c) Jerome Reybert. Distributed under the same terms as Vim itself. See :help license.
