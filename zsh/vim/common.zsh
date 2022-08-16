_DEPENDENCIES+=(
	vim
)
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

_VIM() { vim $@ </dev/tty >/dev/tty; }
