#####################################################################

DEPENDENCIES+=()

REQUIRED_ENV+=(
	MEDIA_SYNC__TARGETS
	MEDIA_SYNC__S3_BUCKET
)

use cloud/aws/cli

#####################################################################

MEDIA_SYNC__PUSH() {
	local FLAGS=($@)
	local FAILED_COUNT=0

	STATUS 'starting media upload to s3'

	local TARGET
	for TARGET in ${MEDIA_SYNC__TARGETS[@]}
	do
		_MEDIA_SYNC push $TARGET $FLAGS || ((FAILED_COUNT+=1))
	done

	[[ $FAILED_COUNT -eq 0 ]] \
		&& SUCCESS 's3 media files now up-to-date' \
		|| FAIL $FAILED_COUNT 'unable to upload one or more targets' \
		;
}

MEDIA_SYNC__PULL() {
	local FLAGS=($@)
	local FAILED_COUNT=0

	STATUS 'starting media download from s3'

	local TARGET
	for TARGET in ${MEDIA_SYNC__TARGETS[@]}
	do
		_MEDIA_SYNC pull $TARGET $FLAGS || ((FAILED_COUNT+=1))
	done

	[[ $FAILED_COUNT -eq 0 ]] \
		&& SUCCESS 'local media files now up-to-date' \
		|| FAIL $FAILED_COUNT 'unable to download one or more targets' \
		;
}

_MEDIA_SYNC() {
	local ACTION="$1"
	local REMOTE_TARGET="s3://$MEDIA_SYNC__S3_BUCKET/$2"
	local LOCAL_TARGET="$HOME/$2"

	local A B
	case $ACTION in
		push ) A="$LOCAL_TARGET";  B="$REMOTE_TARGET" ;;
		pull ) A="$REMOTE_TARGET"; B="$LOCAL_TARGET"  ;;

		* ) ERROR "unknown action '$1'"; return 1 ;;
	esac

	local FLAGS=(${@:3})

	STATUS "${ACTION}ing $2"
	AWS s3 sync $A $B $FLAGS \
		&& SUCCESS "$2 up-to-date" \
		|| { ERROR "unable to sync $2 (see above)"; return 1; }
}
