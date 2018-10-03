set -e

if [[ "$VIMGAGIT_TEST_VERBOSE" == "1" ]]; then
	set -x
fi

if [[ $# -ne 4 ]]; then
	echo "Usage $0 VIMAGIT_PATH VADER_PATH TEST_PATH VIM_VERSION"
	exit 1
fi

function prealpath() {
python -c "import os,sys; print(os.path.realpath(os.path.expanduser(sys.argv[1])))" "${1}"
}

export VIMAGIT_PATH=$(prealpath $1)
export VADER_PATH=$(prealpath $2)
export TEST_PATH=$(prealpath "$3")
export VIM_VERSION=$4

if [[ ! ( -d $VIMAGIT_PATH && -d $VADER_PATH && -d $TEST_PATH ) ]]; then
	echo "can't access to one of them '$VIMAGIT_PATH' '$VADER_PATH' '$TEST_PATH'"
	exit 1
fi

pushd "$TEST_PATH"
git config --local user.email 'tester@vimagit.org'
git config --local user.name 'vimagit tester'
export TEST_HEAD_SHA1='origin/vimagit_test-1.7.3'
export TEST_RESET_TAG='reset-here'
git submodule update
git show $TEST_HEAD_SHA1 --stat
git reset $TEST_RESET_TAG && git status --porcelain && git reset --hard $TEST_HEAD_SHA1
popd

if [ "$VIM_VERSION" = 'neovim' ]; then
	VIM=nvim
elif [ "$VIM_VERSION" = 'macvim' ]; then
	VIM=mvim
else
	VIM=vim
fi

echo 'Git version'
git --version

echo 'Vim version'
$VIM --version

source $VIMAGIT_PATH/test/test.config

if [[ "$TRAVIS" == "true" ]]; then
	EOL_TEST="0 1"
	_TEST_PATHS=${test_paths[@]}
else
	EOL_TEST="0"
	_TEST_PATHS=${test_paths[0]}
fi

for script in ${!test_scripts[@]}; do

	IFS=';' read -a filename_array <<< "${test_scripts[$script]}"
	for filename in "${filename_array[@]}"; do
		echo ${_TEST_PATHS[@]}
		for test_path in ${_TEST_PATHS[@]}; do
			export TEST_SUB_PATH=$(prealpath "$TEST_PATH"/$test_path)
			export VIMAGIT_TEST_FILENAME="$filename"

			for i in $EOL_TEST; do
				export VIMAGIT_TEST_FROM_EOL=$i

				echo "Test $script with $filename from path $TEST_SUB_PATH and from $([ $i -eq 1 ] && echo "end" || echo "start") of line"

				$VIM -Nu <(cat << EOF
				filetype off
				set rtp-=~/.vim
				set rtp-=~/.vim/after
				set rtp+=$VIMAGIT_PATH
				set rtp+=$VADER_PATH
				let g:vader_show_version=0
				filetype plugin indent on
				syntax enable
EOF) -c "Vader! $VIMAGIT_PATH/test/$script 2> >(sed -n '/^Starting Vader/,$p')"

			done
		done
	done
done
