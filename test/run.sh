set -xe

if [[ $# -ne 3 ]]; then
	echo "Usage $0 VIMAGIT_PATH VADER_PATH TEST_PATH"
	exit 1
fi

function prealpath() {
python -c "import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))" "${1}"
}

export VIMAGIT_PATH=$(prealpath $1)
export VADER_PATH=$(prealpath $2)
export TEST_PATH=$(prealpath $3)
export TEST_SUB_PATH=$(prealpath $TEST_PATH/$TEST_SUB_PATH)

if [[ ! ( -d $VIMAGIT_PATH && -d $VADER_PATH && -d $TEST_PATH && -d $TEST_SUB_PATH) ]]; then
	echo "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH' '$TEST_SUB_PATH'"
	exit 1
fi

pushd $TEST_PATH
git config --local user.email 'tester@vimagit.org'
git config --local user.name 'vimagit tester'
export TEST_HEAD_SHA1='6efcd49'
popd

for i in 1 0; do
export VIMAGIT_TEST_FROM_EOL=$i

echo "Test commands from $([ $i -eq 1 ] && echo "end" || echo "start") of line"

vim -Nu <(cat << EOF
filetype off
set rtp-=~/.vim
set rtp-=~/.vim/after
set rtp+=$VIMAGIT_PATH
set rtp+=$VADER_PATH
filetype plugin indent on
syntax enable
EOF) -c "Vader! $VIMAGIT_PATH/test/*"

done
