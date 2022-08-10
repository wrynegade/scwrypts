_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

set +o noglob
MEMO__FILETYPE=md
MEMO__DIR="$SCWRYPTS_DATA_PATH/memo"
[ ! -d $MEMO__DIR ] && mkdir -p $MEMO__DIR

LIST_MEMOS() { ls $MEMO__DIR | sed "s/\.$MEMO__FILETYPE$//" | sort; }

# TODO : remove deprecated migration
[ -d $HOME/.memos ] && {
	__Yn 'detected legacy memos folder; upgrade now?' && {
		mv $HOME/.memos/* $MEMO__DIR
		rmdir "$HOME/.memos"
	}
}
