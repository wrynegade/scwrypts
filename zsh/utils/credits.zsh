__CREDITS() {
	local COMMAND="$1"
	cd $SCWRYPTS_ROOT
	cat ./**/README.md \
		| grep 'Generic Badge' \
		| sed -n "s/.*Generic Badge.*-$COMMAND-.*(/(/p"
}
