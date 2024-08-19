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

export __SCWRYPTS_UTILS_COLORS=(
		$(utils.colors.red)
		$(utils.colors.bright-red)
		$(utils.colors.green)
		$(utils.colors.bright-green)
		$(utils.colors.yellow)
		$(utils.colors.bright-yellow)
		$(utils.colors.blue)
		$(utils.colors.bright-blue)
		$(utils.colors.magenta)
		$(utils.colors.bright-magenta)
		$(utils.colors.cyan)
		$(utils.colors.bright-cyan)
		$(utils.colors.white)
	)

utils.colors.random() {
	printf "$(utils.colors.reset)${__SCWRYPTS_UTILS_COLORS[$(shuf -i 1-${#__SCWRYPTS_UTILS_COLORS[@]} -n 1)]}"
}
