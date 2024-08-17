scwrypts.config() {
	[ $1 ] || return 1

	local VALUE
	case $1 in
		( python.versions ) CONFIG_VALUE="3.12\n3.11\n3.10" ;;
		( nodejs.version  ) CONFIG_VALUE="18.0.0" ;;
		( * ) return 1 ;;
	esac

	echo $VALUE
}
