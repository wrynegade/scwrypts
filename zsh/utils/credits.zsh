__CREDITS() {
	# scwrypts exclusive ("credits" pulled from README files)
	[ ! $SCWRYPTS_ROOT ] && return 0

	local COMMAND="$1"
	cd $SCWRYPTS_ROOT
	cat ./**/README.md \
		| grep 'Generic Badge' \
		| sed -n "s/.*Generic Badge.*-$COMMAND-.*(/(/p"
}
