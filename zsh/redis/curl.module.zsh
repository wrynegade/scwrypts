#####################################################################

use redis/cli
use redis/enabled

#####################################################################

${scwryptsmodule}() {
	eval "$(usage.reset)"
	local \
		URL TTL KEY CURL_ARGS=() \
		PARSERS=()

	eval "$ZSHPARSEARGS"

	##########################################

	redis.enabled || {
		echo.debug "redis not available; performing curl without cache\ncurl -s ${CURL_ARGS[@]} '${URL}'"
		curl -s ${CURL_ARGS[@]} "${URL}"
		return $?
	}

	local OUTPUT=$(REDIS get "${KEY}" 2>&1)

	[ "${OUTPUT}" ] && {
		echo ${OUTPUT}
		return 0
	}

	local OUTPUT=$(curl -s ${CURL_ARGS[@]} "${URL}")
	[ "${OUTPUT}" ] || return 1

	{
		redis.cli set    "${KEY}" "${OUTPUT}"
		redis.cli expire "${KEY}" "${TTL}"
	} &>/dev/null

	echo ${OUTPUT}
}

#####################################################################

${scwryptsmodule}.parse() {
	# local URL TTL KEY CURL_ARGS=()
	local PARSED=0

	case $1 in
		( --ttl ) TTL=$2 ;;

		( --   ) PARSED=1 ;;
		( --*= ) PARSED=1 ; CURL_ARGS+=($1)    ;;
		( --*  ) PARSED=2 ; CURL_ARGS+=($1 $2) ;;
		( -*   ) PARSED=1 ; CURL_ARGS+=($1)    ;;

		( * )
			PARSED=$#
			URL=$1
			CURL_ARGS+=(${@:2})
			;;
	esac

	return ${PARSED}
}

${scwryptsmodule}.parse.usage() {
	USAGE__options+="
		--ttl <seconds>   indicated number of seconds before the request should expire

		all additional arguments are passed on to curl
		$(utils.colors.print light-gray "$(curl --help)")
	"

	[ "${USAGE__description}" ] || USAGE__description="
		cache curl requests with the indicated ttl

		each request is cached by scwrypts env (currently ${SCWRYPTS_ENV})
	"
}

${scwryptsmodule}.parse.validate() {
	[ "${URL}" ] \
		|| echo.error "no url provided"

	[ "${TTL}" ] \
		|| TTL=10

	KEY="scwrypts:${SCWRYPTS_ENV}:curl:$(echo "${URL}" | sed 's/\s\+/+/g')"
}
