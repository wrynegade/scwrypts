#####################################################################

[ ! $SCWRYPTS_ROOT ] && SCWRYPTS_ROOT="$(dirname ${0:a:h})"

__PREFERRED_PYTHON_VERSIONS=(3.10 3.9)
__NODE_VERSION=18.0.0
__ENV_TEMPLATE=$SCWRYPTS_ROOT/.env.template

__SCWRYPT=1

source $SCWRYPTS_ROOT/.config
source ${0:a:h}/utils/utils.module.zsh || {
	[ $DONT_EXIT ] && return 1 || exit 1
}

#####################################################################

__GET_ENV_FILES() { find $SCWRYPTS_CONFIG_PATH/env -maxdepth 1 -type f | sort -r }
[ ! "$(__GET_ENV_FILES)" ] && {
	cp $__ENV_TEMPLATE "$SCWRYPTS_CONFIG_PATH/env/dev"
	cp $__ENV_TEMPLATE "$SCWRYPTS_CONFIG_PATH/env/local"
	cp $__ENV_TEMPLATE "$SCWRYPTS_CONFIG_PATH/env/prod"
}

__GET_ENV_NAMES() { __GET_ENV_FILES | sed 's/.*\///'; }
__GET_ENV_FILE()  { echo "$SCWRYPTS_CONFIG_PATH/env/$1"; }

__SELECT_OR_CREATE_ENV() { __GET_ENV_NAMES | __FZF_TAIL 'select/create an environment'; }
__SELECT_ENV()           { __GET_ENV_NAMES | __FZF 'select an environment'; }

__GET_AVAILABLE_SCRIPTS() {
	cd $SCWRYPTS_ROOT;
	find . -mindepth 2 -type f -executable \
		| grep -v '\.git' \
		| grep -v '\.env' \
		| grep -v 'node_modules' \
		| sed 's/^\.\///; s/\.[^.]*$//' \
		;
}

#####################################################################

__RUN_SCWRYPT() {
	# run a scwrypt inside a scwrypt w/stack-depth indicators
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
