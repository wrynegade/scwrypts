export ${scwryptsgroup}__type=zsh
export ${scwryptsgroup}__color=$(utils.colors.red)

#####################################################################

SCWRYPTS_STATIC_CONFIG__kubectl+=(
	"${scwryptsgrouproot}/.config/static/redis.zsh"
)

source "${scwryptsgrouproot}/driver/kubectl.driver.zsh"
