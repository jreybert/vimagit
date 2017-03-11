# vimagit

[![Join the chat at https://gitter.im/jreybert/vimagit](https://badges.gitter.im/jreybert/vimagit.svg)][4]
[![Master build status](https://travis-ci.org/jreybert/vimagit.svg?branch=master)][13]

Ease your git workflow within vim.

From a very single vim buffer, you can perform main git operations in few key press. To name a few:
* Visualize all diffs in your git repository.
* Stage file, hunks or even just parts of a hunk using a single key press.
* Write or amend your commit message and commit in the same buffer.

Take a look at [TL;DR](#tldr) to start using it immediately.

![Example of vimagit 1.5.1](../gh-pages/images/vimagit_screenshot_1.5.1.png?raw=true "Example of vimagit 1.5.1")

Some screencasts:
* A simple [asciicast][5]
* A [commented video presenting vimagit][6] (thank you [Mike Hartington][7]!)

This workflow is 100% inspired from magnificent emacs [Magit][1] plugin.

## Outstanding features

* [x] Preview all your git changes in one unique buffer, folded at hunk level.
* [x] Interactively stage/unstage/discard changes with one key press.
* [x] Stage/unstage at file/hunk/line level.
* [x] Write the commit message in the same buffer.
* [x] From a hunk in magit buffer, jump to the file at the diff position.
* [x] 100% VimL plugin, no external dependency (except git of course).
* [x] Enhanced by external plugins: [vim-gitgutter][2] [vim-airline][8]
* [x] Stable. All features are tested in continuous integration.

More to come:
* [ ] Add a push function, taking care if needed about the remote repository and branch #24 .
* [ ] Handle commit fixup! and squash!, with a smart git log popup #23 .
* [ ] Handle stash: add, pop, apply, drop #26 .
* [ ] Stage multiple hunks or file by visually selecting them #83 .
* [ ] Go through history, cherry-pick changes.
* [ ] Make vimagit more efficient for huge repositories, with a lot of diffs.
* [ ] Something is missing? Open an [issue][9]!

> Why should I use vimagit, there are already plethora git plugins for vim?

* fugitive is a very complete plugin, with a lot of functions. I use it for years, and it is a fundamental tool in my workflow. But visualize your changes and staged them in broad number of files is really a pain.
* [vim-gitgutter][2] is very well integrated into vim, but without the ability to commit stages, it stays an informational plugin.

## TL;DR

This is the minimal required set of command you must know to start playing with vimagit. See [Mappings](#mappings) for a complete description.

To simply test vimagit, modify/add/delete/rename some files in a git repository and open vim.

- `:Magit`  
  Open magit buffer with [:Magit](#magitshow_magit) command.
- `<C-n>`  
  Jump to next hunk with `<C-n>`, or move the cursor as you like. The cursor is on a hunk.
- `S`  
  While the cursor is on an unstaged hunk, press `S` in Normal mode: the hunk is now staged, and appears in "Staged changes" section (you can also unstage a hunk from "Staged section" with `S`).
- `CC`  
  Once you have stage all the required changes, press `CC`.
  - Section "Commit message" is shown.
  - Type your commit message in this section.
  - To commit, go back in Normal mode, and press `CC` (or `:w` if you prefer).
  
You just created your first commit with vimagit!

## Installation

This plugin follows the standard runtime path structure, and as such it can be installed with a variety of plugin managers:

- Pathogen  
  `git clone https://github.com/jreybert/vimagit ~/.vim/bundle/vimagit`  
  Remember to run :Helptags to generate help tags
- NeoBundle  
  `NeoBundle 'jreybert/vimagit'`
- Vundle  
  `Plugin 'jreybert/vimagit'`
- Plug  
  `Plug 'jreybert/vimagit'`
- VAM  
  `call vam#ActivateAddons([ 'jreybert/vimagit' ])`
- manual  
  copy all of the files into your ~/.vim directory

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

##### \<C-n>,\<C-p>
 * Move to **N**ext or **P**revious hunk.

##### CC
 * If not in commit section, set commit mode to "New commit" and show "Commit message" section with brand new commit message.
 * If in commit section, create the commit with the commit message and all staged changes.

##### :w :x :wq ZZ
 * If in commit section, create the commit with the commit message and all staged changes.

##### CA
 * If not in commit section, set commit mode to "Amend commit" and show "Commit message" section with previous commit message.

##### CF
 * Amend the staged changes into the previous commit, without modifying previous commit message.

##### CU
 * Close a commit section (If you need soon after open or editing commit message, pressing 'u' is good enough).

##### I
 * Add the file under the cursor in .gitgnore

##### R
 * Refresh magit buffer

##### -,+,0
 * Shrink,enlarge,reset diff context

##### q
 * Close the magit buffer

##### ?
 * Toggle help showing in magit buffer

#### Mapping update

Since vimagit 1.7, jump mappings have changed:
 *  Jump next hunk : **N** -> **\<C-n>**
 *  Jump prev hunk : **P** -> **\<C-p>**

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

#### g:magit_commit_title_limit

Text is grayed if first line of commit message exceed this number of character (default 50)

> let g:magit_commit_title_limit=[0..300]

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

#### g:magit_auto_foldopen

When stage/unstage a hunk, cursor goes to the closest hunk in the same section.
This option automatically opens the fold of the hunk cursor has jump to.
Default value is 1.
> let g:magit_auto_foldopen=[01]

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

When set to 1, and if [vim-gitgutter][2] plugin is installed, gitgutter signs will
be updated each time magit update the git status of a file (i.e. when a file
or a hunk is staged/unstaged).
Default value is 1.
> let g:magit_refresh_gitgutter=[01]

## Requirements

This part must be refined, I don't see any minimal version for git and vim, but for sure there should be one.

At least, it is tested with vim 7.3.249 and git 1.8.5.6 (see [Integration](#integration)).

## Integration

Branches [master][10] and [next][11] are continuously tested on [travis][12] when published on github.

vimagit is tested with various versions of vim on linux: vim 7.3.249, vim 7.4.273, and latest neovim version. It is also tested for macos X: vim, macvim and neovim. Anyway, if you feel that vimagit behaves oddly (slow refresh, weird display order...) please fill an [issue][9].

For the most enthusiastic, you can try the branch [next](https://github.com/jreybert/vimagit/tree/next). It is quite stable, just check its travis status before fetching it.

Travis status:
* **[master status][13]**: [![Master build status](https://travis-ci.org/jreybert/vimagit.svg?branch=master)][13]
* **[next status][13]**: [![next build status](https://travis-ci.org/jreybert/vimagit.svg?branch=next)][13]

A lot a features are developed in dev/feature_name branches. While it may be asked to users to test these branches (during a bug fix for example), one is warned that these branches may be heavily rebased/deleted.

## Contribution guideline

Pull requests are very welcomed. Some good practice:
- Make your pull request upon `next` branch
- In case changes are asked in your PR, prefer a rebase instead of a new commit

## Credits

* Obviously, big credit to [Magit][1]. For the moment, I am only copying their stage workflow, but I won't stop there! They have a lot of other good ideas.
* Sign handling is based on [vim-gitgutter][2] work.
* Command line completion is based on [hypergit][3] work.

## License

Copyright (c) Jerome Reybert. Distributed under the same terms as Vim itself. See :help license.

[1]: https://github.com/magit/magit
[2]: https://github.com/airblade/vim-gitgutter
[3]: https://github.com/c9s/hypergit.vim
[4]: https://gitter.im/jreybert/vimagit?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge
[5]: https://asciinema.org/a/28761
[6]: https://youtu.be/_3wMmmVi6bU
[7]: https://github.com/mhartington
[8]: https://github.com/vim-airline/vim-airline
[9]: https://github.com/jreybert/vimagit/issues/new
[10]: https://github.com/jreybert/vimagit/
[11]: https://github.com/jreybert/vimagit/tree/next
[12]: https://travis-ci.org/jreybert/vimagit
[13]: https://travis-ci.org/jreybert/vimagit/branches
