Execute (setup):
  source $VIMAGIT_PATH/test/utils.vim
  call Cd_test()
  call system("git reset " . $TEST_HEAD_SHA1 . "~1")
  Log system("git status --porcelain")
  call Cd_test_sub()
