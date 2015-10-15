# vimagit

<table style="width:100%" border=0>
  <tr>
    <td align="left">
      vimagit is an attempt to reproduce the magnificent emacs Magit plugin to vim. The main idea is to manage all git operations in one single buffer, as efficiently as possible.
    </td>
      <td align="right">
      <b>master</b>
      <br>
      <a href="https://travis-ci.org/jreybert/vimagit/branches">
      <img src="https://travis-ci.org/jreybert/vimagit.svg?branch=master" alt="master status" align="top">
      </a>
      <br>
      <b>next</b>
      <br>
      <a href="https://travis-ci.org/jreybert/vimagit/branches">
      <img src="https://travis-ci.org/jreybert/vimagit.svg?branch=next" alt="next status" align="top">
      </a>
    </td>
  </tr>
</table>

Take a look at [TL;DR](#tldr) to start using it immediatly.

## Outstanding features

* [x] See all your changes, staged changes, untracked/removed/renamed files in one unique buffer.
* [x] Staged/unstaged/discard changes with one key press, moving the cursor around. Stage at hunk or file level. Line and partial line staging are ongoing.
* [x] Start to write the commit message in one key press, commit also in one key press.
* [x] Modify in line the content just before staging it.
* [x] Visualize stashes. Apply, pop, drop are on going.
* [x] Add file to .gitignore file.
* [ ] Chase all corner cases. Please remember that vimagit is at an early development stage. If you try vimagit and nothing is working, please don't throw it, fill an issue on github :heart: !

More to come:
* Partial hunk staging (next release).
* Vizualize and checkout branches.
* Go through history, cherry-pick changes.
* Something is missing? Open an [issue](https://github.com/jreybert/vimagit/issues/new)!

For the most enthusiastic, you can try the branch [next](https://github.com/jreybert/vimagit/tree/next). It is quite stable, just check its travis status before fetching it.

> Why should I use vimagit, there are already plethora git plugins for vim?

* fugitive is a very complete plugin, with a lot of functions. I use it for years, and it is a fundamental tool in my workflow. But visualize your changes and staged them in broad number of files is really a pain.
* vim-gitgutter is very well integrated into vim, but without the ability to commit stages, it stays an informational plugin.

## TL;DR

This is the minimal required set of command you must know to start playing with vimagit. See [Mapping](#mapping) for a complete description.

#### :Magit

Open magit buffer.

#### Enter,\<CR\>

All files diffs are hidden by default. To inspect changes in a file, move cursor to the filename line, and press 'Enter' in Normal mode. Diffs are displayed below the file name.

#### S

* Modify a file, for example foo.c, in your repository.
* Move the cursor the line 'modfied: foo.c' in "Unstage changes" section, press **S** in Normal mode: the file is stage, and appears in "Stage changes" section.
* Move to the line 'modified: foo.c' in "Stage changes" section, press **S** in Normal mode: the file is unstage, and appears in "Unstaged changes" section.

More about **S**:

* It works exactely the same for new/renamed/deleted files.
* Stage/unstage by hunk is easy: display file diffs with [Enter](#entercr). If diffs are composed of multiple hnuks, move the cursor to a hunk, and press **S** to stage/unstage this hunk.

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

### Commands

**:Magit**
 * open magit buffer.

### Mappings

For each mapping, user can redefine the behavior with its own mapping. Each variable is described in vimagit help like *vimagit-g:magit_nameofmapping_mapping*

#### Global mappings

Following mappings are broadly set, and are applied in all vim buffers.

#### Local mappings

Following mappings are set locally, for magit buffer only, in normal mode.

**Enter**,**\<CR\>**
 * All files are folded by default. To see the changes in a file, move cursor to the filename line, and press Enter. You can close the changes display retyping Enter.

**zo,zO**
 * Typing zo on a file will unhide its diffs.

**zc,zC**
 * Typing zc on a file will hide its diffs.

**S**
 * If cursor is in a hunk, stage/unstage hunk at cursor position.
 * If cursor is in diff header, stage/unstage whole file at cursor position.
 * When cursor is in "Unstaged changes" section, it will stage the hunk/file.
 * On the other side, when cursor is in "Staged changes" section, it will unstage hunk/file.

**F**
 * Stage/unstage the whole file at cursor position.
 * When cursor is in "Unstaged changes" section, it will stage the file.
 * On the other side, when cursor is in "Staged changes" section, it will unstage file.

**DDD**
 * If cursor is in a hunk, discard hunk at cursor position.
 * If cursor is in diff header, discard whole file at cursor position.
 * Only works in "Unstaged changes" section.

**CC**
 * If not in commit section, set commit mode to "New commit" and show "Commit message" section with brand new commit message.
 * If in commit section, commit the all staged changes in commit mode previously set.

**:w<cr>**
 * If in commit section, commit the all staged changes in commit mode previously set.

**CA**
 * If not in commit section, set commit mode to "Amend commit" and show "Commit message" section with previous commit message.
 * If in commit section, commit the staged changes in commit mode previously set.

**CF**
 * Amend the staged changes into the previous commit, without modifying previous commit message.

**I**
 * Add the file under the cursor in .gitgnore

**R**
 * Refresh magit buffer

**q**
 * Close the magit buffer

**h**
 * Toggle help showing in magit buffer

### Options

User can define in its prefered |vimrc| some options.

To disable vimagit plugin
> let g:magit_enabled=0

To disable chatty inline help in magit buffer
> let g:magit_show_help=0

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
