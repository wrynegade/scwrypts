_DEPENDENCIES+=(
	i3
	i3-msg
)
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

[ ! $DISPLAY ] && export DISPLAY=:0

_NOTIFY() {
	__CHECK_DEPENDENCY notify-send || return 0
	notify-send "SCWRYPTS $SCWRYPT_NAME" $@
}
