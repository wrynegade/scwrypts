scwrypts.config() {
	[ $1 ] || return 1

	case $1 in
		( python.versions ) echo "3.12\n3.11\n3.10" ;;
		( nodejs.version  ) echo "18.0.0" ;;
		( * ) return 1 ;;
	esac
}
