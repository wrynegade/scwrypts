export SCWRYPTS_ROOT__scwrypts="$SCWRYPTS_ROOT"
export SCWRYPTS_LIBRARY_ROOT__scwrypts="$SCWRYPTS_ROOT/zsh/lib"
export SCWRYPTS_COLOR__scwrypts='\033[0;32m'


export SCWRYPTS_VIRTUALENV_PATH__scwrypts="$SCWRYPTS_DATA_PATH/virtualenv"
[ ! -d "$SCWRYPTS_VIRTUALENV_PATH__scwrypts" ] && mkdir -p "$SCWRYPTS_VIRTUALENV_PATH__scwrypts"

export SCWRYPTS_PREFERRED_PYTHON_VERSIONS__scwrypts=(3.11 3.10 3.9)
export SCWRYPTS_NODE_VERSION__scwrypts=18.0.0
