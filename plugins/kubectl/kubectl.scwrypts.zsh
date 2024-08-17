export ${scwryptsgroup}__type=zsh
export ${scwryptsgroup}__color='\033[0;31m'

#####################################################################

SCWRYPTS_STATIC_CONFIG__kubectl+=(
	"${scwryptsgrouproot}/.config/static/redis.zsh"
)

source "${scwryptsgrouproot}/driver/kubectl.driver.zsh"
