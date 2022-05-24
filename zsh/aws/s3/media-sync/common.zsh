_DEPENDENCIES+=()
_REQUIRED_ENV+=(
	AWS__S3__MEDIA_TARGETS
	AWS__S3__MEDIA_BUCKET
)
source ${0:a:h}/../common.zsh
#####################################################################

AWS__S3__MEDIA_TARGETS=($(echo $AWS__S3__MEDIA_TARGETS | sed 's/,/\n/g'))

__SYNC_MEDIA() {
	local ACTION="$1"
	local REMOTE_TARGET="s3://$AWS__S3__MEDIA_BUCKET/$2"
	local LOCAL_TARGET="$HOME/$2"

	local A B
	case $ACTION in
		push ) A="$LOCAL_TARGET";  B="$REMOTE_TARGET" ;;
		pull ) A="$REMOTE_TARGET"; B="$LOCAL_TARGET"  ;;

		* ) __ERROR "unknown action '$1'"; return 1 ;;
	esac

	local FLAGS=(${@:3})

	__STATUS "${ACTION}ing $2"
	_AWS s3 sync $REMOTE_TARGET $LOCAL_TARGET $FLAGS \
		&& __SUCCESS "$2 up-to-date" \
		|| { __ERROR "unable to sync $2 (see above)"; return 1; }
}
