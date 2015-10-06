Execute (setup):
  source $VIMAGIT_PATH/test/utils.vim
  cd $TEST_PATH
  call system("git reset " . $TEST_HEAD_SHA1 . "~1")
  cd $TEST_SUB_PATH
