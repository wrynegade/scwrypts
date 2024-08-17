#####################################################################

DEPENDENCIES+=()
REQUIRED_ENV+=()

#####################################################################

set +o noglob

MEMO__FILETYPE=md
MEMO__DIR="$SCWRYPTS_DATA_PATH/memo"

[ ! -d $MEMO__DIR ] && mkdir -p $MEMO__DIR

MEMO__LIST_ALL() { ls $MEMO__DIR | sed "s/\.$MEMO__FILETYPE$//" | sort; }
