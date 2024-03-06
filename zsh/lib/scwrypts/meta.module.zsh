#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use scwrypts/environment-files
use scwrypts/run

#####################################################################

SCWRYPTS__RUN() {  # context wrapper to run scwrypts within scwrypts
	local EXIT_CODE=0
	((SUBSCWRYPT+=1))

	SUBSCWRYPT=$SUBSCWRYPT $SCWRYPTS_ROOT/scwrypts $@
	EXIT_CODE=$?

	((SUBSCWRYPT-=1))
	return $EXIT_CODE
}
