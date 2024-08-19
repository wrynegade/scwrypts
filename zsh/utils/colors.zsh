utils.colors.black()          { printf '\033[0;30m'; }
utils.colors.dark-gray()      { printf '\033[1;30m'; }
utils.colors.red()            { printf '\033[0;31m'; }
utils.colors.bright-red()     { printf '\033[1;31m'; }
utils.colors.green()          { printf '\033[0;32m'; }
utils.colors.bright-green()   { printf '\033[1;32m'; }
utils.colors.yellow()         { printf '\033[0;33m'; }
utils.colors.bright-yellow()  { printf '\033[1;33m'; }
utils.colors.blue()           { printf '\033[0;34m'; }
utils.colors.bright-blue()    { printf '\033[1;34m'; }
utils.colors.magenta()        { printf '\033[0;35m'; }
utils.colors.bright-magenta() { printf '\033[1;35m'; }
utils.colors.cyan()           { printf '\033[0;36m'; }
utils.colors.bright-cyan()    { printf '\033[1;36m'; }
utils.colors.white()          { printf '\033[0;37m'; }
utils.colors.light-gray()     { printf '\033[1;37m'; }

utils.colors.reset()          { printf '\033[0m'; }


__RED='\033[0;31m'
__BRIGHT_RED='\033[1;31m'

__GREEN='\033[0;32m'
__BRIGHT_GREEN='\033[1;32m'

__YELLOW='\033[0;33m'
__BRIGHT_YELLOW='\033[1;33m'

__BLUE='\033[0;34m'
__BRIGHT_BLUE='\033[1;34m'

__MAGENTA='\033[0;35m'
__BRIGHT_MAGENTA='\033[1;35m'

__CYAN='\033[0;36m'
__BRIGHT_CYAN='\033[1;36m'

__WHITE='\033[1;37m'
__LIGHT_GRAY='\033[0;37m'

__COLOR_RESET='\033[0m'

__GET_RANDOM_COLOR() {
	local COLORS=(
		$__RED
		$__BRIGHT_RED
		$__GREEN
		$__BRIGHT_GREEN
		$__YELLOW
		$__BRIGHT_YELLOW
		$__BLUE
		$__BRIGHT_BLUE
		$__MAGENTA
		$__BRIGHT_MAGENTA
		$__CYAN
		$__BRIGHT_CYAN
		$__WHITE
	)
	print "$__COLOR_RESET${COLORS[$(shuf -i 1-${#COLORS[@]} -n 1)]}"
}
