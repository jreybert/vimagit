# Contributions

Contributions and pull requests are welcome.  Please take note of the following guidelines:

* **Work and push on [next](https://github.com/jreybert/vimagit/tree/next) branch**. `git remote update; git checkout origin/next` before hacking. Exceptions for bugs in `master` branch and simple typo fix.
* Always rebase your work before push: `git pull --rebase origin next`
* Adhere to the existing style as much as possible; notably, tabulation indents and long-form keywords. Try to add comments for important changes/addings.
* Make targeted pull request: propose one feature/bugfix, and push only commit(s) related to this feature/bugfix.
* Any push to your pull request will trigger a regression job on [travis](https://travis-ci.org/jreybert/vimagit).

# Bugs

* To make it easier to reproduce, please supply the following:
  * the version of `vim` or `nvim`
  * the version of `git`
  * the SHA1 of vimagit you're using
  * the OS that you're using, including terminal emulator, GUI vs non-GUI
  * a step by step command to reproduce the bug

