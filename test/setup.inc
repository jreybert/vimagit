Execute (setup):
  source $VIMAGIT_PATH/test/utils.vim
  call Cd_test()
  call system("git reset " . $TEST_RESET_TAG )
  call Git_verbose_log(system("git status --porcelain"))
  call Cd_test_sub()
