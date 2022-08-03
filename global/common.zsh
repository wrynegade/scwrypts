#####################################################################

[ ! $SCWRYPTS_ROOT ] && SCWRYPTS_ROOT="$(dirname ${0:a:h})"

source "${0:a:h}/config.zsh"

#####################################################################

__SCWRYPT=1 # arbitrary; indicates scwrypts exists

__PREFERRED_PYTHON_VERSIONS=(3.10 3.9)
__NODE_VERSION=18.0.0

__ENV_TEMPLATE=$SCWRYPTS_ROOT/.env.template

#####################################################################

__RUN_SCWRYPT() {
	((SUBSCWRYPT+=1))
	printf ' '; printf '--%.0s' {1..$SUBSCWRYPT}; printf " ($SUBSCWRYPT) "
	echo "  BEGIN SUBSCWRYPT : $(basename $1)"

	SUBSCWRYPT=$SUBSCWRYPT SCWRYPTS_ENV=$ENV_NAME \
		"$SCWRYPTS_ROOT/scwrypts" $@
	EXIT_CODE=$?

	printf ' '; printf '--%.0s' {1..$SUBSCWRYPT}; printf " ($SUBSCWRYPT) "
	echo "  END SUBSCWRYPT   : $(basename $1)"
	((SUBSCWRYPT-=1))

	return $EXIT_CODE
}
