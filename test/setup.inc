Execute (setup):
  source $VIMAGIT_PATH/test/utils.vim
  call Cd_test()
  call Git_verbose_log("git reset --hard " . $TEST_HEAD_SHA1)
  call system("git reset --hard " . $TEST_HEAD_SHA1)
  call Git_verbose_log("git clean -xffd")
  call system("git clean -xffd")
  call Git_verbose_log("git reset " . $TEST_RESET_TAG)
  call system("git reset " . $TEST_RESET_TAG)
  call Git_verbose_log("git status --porcelain")
  call Git_verbose_log(system("git status --porcelain"))
  call Cd_test_sub()
