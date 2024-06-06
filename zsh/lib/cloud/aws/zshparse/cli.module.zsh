ARGS_PARSER__AWS() {
	# local ARGS=()

	local PARSED=0

	case $1 in
		-h | --help ) ;;  # filter to default parser
		* )
			((POSITIONAL_ARGS+=1))
			case $POSITIONAL_ARGS in
				* ) ARGS+=($1)  # assume everything else belongs to the aws-cli
					;;
			esac
			((PARSED+=1))
			;;
	esac

	return $PARSED
}

ARGS_PARSER__AWS__usage() {
	USAGE__usage+=' [...aws-args...]'
	USAGE__args+='
		aws-args   arguments forwarded to the AWS CLI
	'
}

