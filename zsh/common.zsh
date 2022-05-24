#####################################################################

[ ! $SCWRYPTS_ROOT ] && SCWRYPTS_ROOT="$(dirname ${0:a:h})"

source $SCWRYPTS_ROOT/.config
[ -f $SCWRYPTS_CONFIG_PATH/config ] && source $SCWRYPTS_CONFIG_PATH/config

[ ! -d $SCWRYPTS_CONFIG_PATH ] && mkdir -p $SCWRYPTS_CONFIG_PATH
[ ! -d $SCWRYPTS_ENV_PATH    ] && mkdir -p $SCWRYPTS_ENV_PATH
[ ! -d $SCWRYPTS_LOG_PATH    ] && mkdir -p $SCWRYPTS_LOG_PATH

__PREFERRED_PYTHON_VERSIONS=(3.10 3.9)
__NODE_VERSION=18.0.0

#####################################################################

source ${0:a:h}/utils/utils.zsh

#####################################################################

__ENV_TEMPLATE=$SCWRYPTS_ROOT/.template.env

__GET_ENV_FILES() { find $SCWRYPTS_CONFIG_PATH/env -maxdepth 1 -type f; }
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
