#####################################################################

DEPENDENCIES+=(
	notify-send
)

REQUIRED_ENV+=()

#####################################################################

NOTIFY() {
	local D=$DISPLAY
	[ ! $D ] && D=:0

	DISPLAY=$D notify-send "SCWRYPTS $SCWRYPT_NAME" $@
}
