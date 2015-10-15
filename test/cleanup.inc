Execute (cleanup):
  call Git_verbose_log(system("git status --porcelain"))
  call system("git reset --hard " . $TEST_HEAD_SHA1)
  call Cd_vimagit()
