#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

use scwrypts/environment-files
use scwrypts/run

#####################################################################

SCWRYPTS__RUN() {
	local EXIT_CODE=0
	((SUBSCWRYPT+=1))

	echo "--- START SUBSCWRYPT=$SUBSCWRYPT $@"
	SUBSCWRYPT=$SUBSCWRYPT $SCWRYPTS_ROOT/run $@
	EXIT_CODE=$?

	((SUBSCWRYPT-=1))
	return $EXIT_CODE
	echo "--- END SUBSCWRYPT=$SUBSCWRYPT $@"
}
