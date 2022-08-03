#####################################################################

source ${0:a:h}/../global/common.zsh
source ${0:a:h}/utils/utils.module.zsh \
	|| { [ $DONT_EXIT ] && return 1 || exit 1; }

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
__SELECT_ENV()           { __GET_ENV_NAMES | __FZF      'select an environment'; }

#####################################################################

__GET_AVAILABLE_SCRIPTS() {
	cd $SCWRYPTS_ROOT;
	find . -mindepth 2 -type f -executable \
		| grep -v '\.git' \
		| grep -v 'node_modules' \
		| sed 's/^\.\///; s/\.[^.]*$//' \
		;
}
