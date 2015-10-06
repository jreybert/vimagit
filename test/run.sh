
if [[ $# -ne 3 ]]; then
	echo "Usage $0 VIMAGIT_PATH VADER_PATH TEST_PATH"
	exit 1
fi

export VIMAGIT_PATH=$(readlink -f $1)
export VADER_PATH=$(readlink -f $2)
export TEST_PATH=$(readlink -f $3)

if [[ ! ( -d $VIMAGIT_PATH && -d $VADER_PATH && -d $TEST_PATH ) ]]; then
	echo "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH'"
	exit 1
fi

export TEST_HEAD_SHA1='6efcd49'

vim -Nu <(cat << EOF
filetype off
set rtp-=~/.vim
set rtp-=~/.vim/after
set rtp+=$VIMAGIT_PATH
set rtp+=$VADER_PATH
filetype plugin indent on
syntax enable
EOF) -c "Vader! $VIMAGIT_PATH/test/*"
