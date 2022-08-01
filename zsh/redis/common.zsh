_DEPENDENCIES+=(
	redis-cli
)
_REQUIRED_ENV+=()
source ${0:a:h}/../common.zsh

[ ! $SCWRYPTS_CACHE_HOST ] && SCWRYPTS_CACHE_HOST=localhost
[ ! $SCWRYPTS_CACHE_PORT ] && SCWRYPTS_CACHE_PORT=6379
#####################################################################

_REDIS() {
	local ARGS=()

	ARGS+=(-h $SCWRYPTS_CACHE_HOST)
	ARGS+=(-p $SCWRYPTS_CACHE_PORT)

	[ $SCWRYPTS_CACHE_AUTH ] && ARGS+=(-a $SCWRYPTS_CACHE_AUTH)

	redis-cli ${ARGS[@]} $@
}

CACHE_ENABLED=$(_REDIS ping 2>&1 | grep -qi pong && echo 1 || echo 0)
