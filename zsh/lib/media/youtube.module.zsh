#####################################################################

DEPENDENCIES+=(
	ffmpeg
	youtube-dl
)

REQUIRED_ENV+=()

#####################################################################

YT__GLOBAL_ARGS=(
	--no-call-home
	--restrict-filenames
	)

YT__OUTPUT_DIR="$SCWRYPTS_DATA_PATH/youtube"

YT__GET_INFO() {
	youtube-dl --dump-json ${YT__GLOBAL_ARGS[@]} $@
}

YT__GET_FILENAME() {
	YT__GET_INFO $@ \
		| jq -r '._filename' \
		| sed 's/\.[^.]*$/\.mp4/' \
		;
}

YT__DOWNLOAD() {
	local OUTPUT_DIR="$SCWRYPTS_DATA_PATH/youtube"
	[ ! -d $YT__OUTPUT_DIR ] && mkdir -p $YT__OUTPUT_DIR
	cd "$YT__OUTPUT_DIR"
	youtube-dl ${YT__GLOBAL_ARGS[@]} $@ \
		--format 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4' \
		;
}

GET_VIDEO_LENGTH() {
	local FILENAME="$1"

	ffprobe \
		-v quiet \
		-show_entries format=duration \
		-of default=noprint_wrappers=1:nokey=1 \
		-i $FILENAME \
		;
}
