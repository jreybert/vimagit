Execute (cleanup):
  call system("git reset --hard " . $TEST_HEAD_SHA1)
  call Cd_vimagit()
