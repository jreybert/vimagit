vimagit is an attempt to reproduce the magnificient Magit to vim.

In a first step, vimagit will only mimic the interactive staging mode of magit, which is the main feature lack of both fugitive and gitgutter.
I don't know for the moment if it will be an independant addon, or if I will try to integrate it in fugitive or gitgutter.

TODO:
* obviously, write a first version of interactive staging
* fill the TODO list
* hook git-wip
* add a stage-by-line feature (see git-gui source code)
* on buffer output, rewrite file/commit context (4 lines) to a simple [modified/new/deleted] path/to/file (that may need
  to not be based on pure git, but play with internal variable to store hunks)
* handle new file with
  git ls-files --others --exclude-standard | while read -r i; do git diff --no-color -- /dev/null "$i"; done
