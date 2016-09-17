# vimagit

[![Join the chat at https://gitter.im/jreybert/vimagit](https://badges.gitter.im/jreybert/vimagit.svg)](https://gitter.im/jreybert/vimagit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Ease your git worflow within vim.

From a very single vim buffer, you can perform main git operations in few key press. To name a few:
* Visualize all diffs in your git repository.
* Stage file, hunks or even just parts of a hunk using a single key press.
* Write or amend your commit message and commit in the same buffer.

![Example of vimagit 1.5.1](../gh-pages/images/vimagit_screenshot_1.5.1.png?raw=true "Example of vimagit 1.5.1")

Some screencasts:
* A simple [asciicast](https://asciinema.org/a/28761)
* A [commented video presenting vimagit](https://youtu.be/_3wMmmVi6bU) (thank you [Mike Hartington](https://github.com/mhartington)!)

This workflow is 100% inspired from magnificent emacs [Magit](https://github.com/magit/magit) plugin.

Take a look at [TL;DR](#tldr) to start using it immediately.

## Outstanding features

* [x] Preview all your git changes in one unique buffer, folded at hunk level.
* [x] Interactively stage/unstage/discard changes with one key press.
* [x] Stage/unstage at file/hunk/line level.
* [x] Write the commit message in the same buffer.
* [x] From a hunk in magit buffer, jump to the file at the diff position.
* [x] Update vim-gitgutter signs when git status is updated.
* [x] Stable. All features are tested in continuous integration.

More to come:
* [ ] Add a push function, taking care if needed about the remote repository and branch #24 .
* [ ] Handle commit fixup! and squash!, with a smart git log popup #23 .
* [ ] Handle stash: add, pop, apply, drop #26 .
* [ ] Stage multiple hunks or file by visually selecting them #83 .
* [ ] Go through history, cherry-pick changes.
* [ ] Make vimagit more efficient for huge repositories, with a lot of diffs.
* [ ] Something is missing? Open an [issue](https://github.com/jreybert/vimagit/issues/new)!

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

A lot a features are developed in dev/feature_name branches. While it may be asked to users to test these branches (during a bug fix for example), one is warned that these branches may be heavily rebased/deleted.

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
* Commit message: this section appears in commit mode (see below). It contains the message to be committed.
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

##### E
If cursor is in a hunk, cursor will move in the file containing this hunk, at
 the line of the beginning of the hunk.
 * if the file is already visible in a window, cursor moves to this window at
 the hunk line
 * if there is more than one window open, cursor moves to last accessed window
 and open buffer at the hunk line
 * if there is only magit window opened, split vertically, moves cursor to new
 split and open buffer at the hunk line

E means 'edit'.

:exclamation: this function is extremely powerful, just give it a try!

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

##### CU
 * Close a commit section (If you need soon after open or editing commit message, pressing 'u' is good enough).

##### I
 * Add the file under the cursor in .gitgnore

##### R
 * Refresh magit buffer

##### q
 * Close the magit buffer

##### ?
 * Toggle help showing in magit buffer

#### Autocommand events

Magit will raise some events at some point. User can plug some specific
commands to these events (see [example](autocommand_example).

##### VimagitBufferInit

This event is raised when the magit buffer is initialized (i.e. each time
[magit#show_magit()](magitshow_magit) is called.

#### VimagitRefresh

This event is raised every time the magit buffer is refreshed, event if no
file is updated.

#### VimagitUpdateFile

This event is raised each time a file status is updated in magit buffer
(typically when a file or a hunk is staged or unstaged). The variable
`g:magit_last_updated_buffer` is set to the last updated file, with its
absolute path.

*Note:* `g:magit_last_updated_buffer` will be updated and VimagitUpdateFile event will
be raised only if the buffer is currently opened in vim.

##### VimagitCommitEnter

This event is raised when the commit section opens and the cursor is
placed in this section. For example, the user may want to go straight into
insert mode when committing, defining this autocmd in its vimrc:

```
  autocmd User VimagitEnterCommit startinsert
```

#### Autocmd example

The following example calls the vim-gitgutter refresh function on a specific
buffer each time vimagit update the git status of this file.

```
  autocmd User VimagitUpdateFile
    \ if ( exists("*gitgutter#process_buffer") ) |
    \ 	call gitgutter#process_buffer(bufnr(g:magit_last_updated_buffer), 0) |
    \ endif
```

The following example is already embeded in vimagit plugin (see
[g:magit_refresh_gitgutter](gmagit_refresh_gitgutter)), then you shouldn't add this particular
example to your vimrc.

### Options

User can define in its prefered vimrc some options.

#### g:magit_enabled

To enable or disable vimagit plugin.
Default value is 1.
> let g:magit_enabled=[01]

#### g:magit_git_cmd

Git command, may be simply simply "git" if git is in your path. Defualt is "git"
> let g:magit_git_cmd="git"

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

#### g:magit_discard_untracked_do_delete

When set to 1, discard an untracked file will indeed delete this file.
Default value is 0.
> let g:magit_discard_untracked_do_delete=[01]

#### g:magit_refresh_gitgutter

When set to 1, and if vim-gitgutter plugin is installed, gitgutter signs will
be updated each time magit update the git status of a file (i.e. when a file
or a hunk is staged/unstaged).
Default value is 1.
> let g:magit_refresh_gitgutter=[01]

## Installation

The plugin hierarchy tree respects the vim plugin standard. It is compatible
with pathogen (and most probably vundle).

To install:

    cd ~/.vim/bundle
    git clone https://github.com/jreybert/vimagit

## Requirements

This part must be refined, I don't see any minimal version for git and vim, but for sure there should be one.

At least, it is tested with vim 7.3.249 and git 1.8.5.6 (see [Integration](#integration)).

## Credits

* Obviously, big credit to [magit](https://github.com/magit/magit). For the moment, I am only copying their stage workflow, but I won't stop there! They have a lot of other good ideas.
* Sign handling is based on [gitgutter](https://github.com/airblade/vim-gitgutter) work.
* Command line completion is based on [hypergit](https://github.com/c9s/hypergit.vim) work.

## License

Copyright (c) Jerome Reybert. Distributed under the same terms as Vim itself. See :help license.
