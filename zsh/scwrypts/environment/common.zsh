_DEPENDENCIES+=()
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh
#####################################################################

_SORT_ENV() {
	local ENV_FILE="$1"

	sed -i "/^# /d; /^$/d" "$ENV_FILE"
	sed -i "s/^[A-Z]/export &/; s/^[^#=]\\+$/&=/" "$ENV_FILE"
	LC_COLLATE=C sort -uo "$ENV_FILE" "$ENV_FILE"
}
