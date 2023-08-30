SCWRYPTS_GROUPS+=(kubectl)

export SCWRYPTS_TYPE__kubectl=zsh
export SCWRYPTS_ROOT__kubectl="$SCWRYPTS_ROOT__scwrypts/plugins/kubectl"
export SCWRYPTS_COLOR__kubectl='\033[0;31m'

SCWRYPTS_STATIC_CONFIG__kubectl+=(
	"$SCWRYPTS_ROOT__kubectl/.config/static/redis.zsh"
)

source "$SCWRYPTS_ROOT__kubectl/driver/kubectl.driver.zsh"
