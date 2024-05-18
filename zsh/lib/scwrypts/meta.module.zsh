#####################################################################

SCWRYPTS__RUN() {  # context wrapper to run scwrypts within scwrypts
	local EXIT_CODE=0
	((SUBSCWRYPT+=1))

	SCWRYPTS_LOG_LEVEL=$SCWRYPTS_LOG_LEVEL \
	SUBSCWRYPT=$SUBSCWRYPT \
		$SCWRYPTS_ROOT__scwrypts/scwrypts $@

	EXIT_CODE=$?

	((SUBSCWRYPT-=1))
	return $EXIT_CODE
}
