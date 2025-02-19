#####################################################################

#
# include 'use' imports here
# use your/zsh/module --group your-group (would include your-group.your.zsh.module)
#
#use

#
# DEPENDENCIES are commands which must be executable
#              (either on \$PATH or fully-qualified executable)
#
# REQUIRED_ENV are environment variables which must be present
#              (loaded from \$SCWRYPTS_ENV)
#
#DEPENDENCIES+=()
#REQUIRED_ENV+=()

#####################################################################

#
# ${scwryptsmodule} helps you create a globally-unique name for this function
#
# suppose we import this library with:
#    use submodule-a/submodule-b/this-library --group my-group
#
# ${scwryptsmodule} will expand to 'my-group.submodule-a.submodule-b.this-library'
# (the full name MUST be used anywhere this function is referenced!)
#
# although using ${scwryptsmodule} is not required, remember that your function
# name MUST be globally unique or it will overwrite / be overwritten by other modules
#
${scwryptsmodule}() {
	# this is the description that will appear when you pass this command -h or --help
	local DESCRIPTION='
		command description here
	'
	# include non-default parsers here (e.g. you 'use some/zshparse/library' above);
	# the ${scwryptsmodule}.parse below is ALREADY included automatically
	#local PARSERS=()

	# autosetup handles ALL parsing logic below; ${scwryptsmodule}() will
	# return with an error code if ANY argument validation errors occur
	#
	# some defaults are included (like -h | --help which prints usage and exits)
	eval "$(utils.parse.autosetup)"
	##########################################

	# your function body goes HERE
}

#####################################################################

#
# all ${scwryptsmodule}.parse* functions are OPTIONAL (but recommended)
#
${scwryptsmodule}.parse() {
	# represents the total number of arguments successfully parsed by this parser
	local PARSED=0

	# parse arguments one at a time in a case statement
	case $1 in
		#
		# ( -s | --setting-a ) PARSED=1; MY_SETTING_A=true ;;
		#
		# you have access to the entire list of remaining UNPARSED variables
		# ( --setting-b ) PARSED=2; MY_SETTING_B="$2" ;;
		#
		#
		# unless you have a specific reason to, DO NOT PARSE A DEFAULT CASE '( * )'
		# let the zshparser handle:
		#   - unknown / fallthrough arguments
		#   - missing arguments "$2" (you can ASSUME it is there)
		#
		#
		# if you want to capture "all remaining arguments" define ARGS as described
		# in ${scwryptsmodule}.parse.locals() below
		#
	esac

	# return the TOTAL NUMBER OF ARGUMENTS PARSED
	return ${PARSED}
}

${scwryptsmodule}.parse.locals() {
	#
	# local variables here are declared as "local" in ${scwryptsmodule}() above
	# be certain to:
	#   - define each variable ON A SEPARATE LINE "local MY_VARIABLE"
	#   - declare ALL variables used in ${scwryptsmodule}.parse
	#   - declare ALL variables used in ${scwryptsmodule}.parse.validate
	#
	# local MY_SETTING_A
	# local MY_SETTING_B=default-value
	#
	# declaring "local ARGS=()" will accept ALL unrecognized arguments into the
	# ARGS array
	#
	# local ARGS=()
}

${scwryptsmodule}.parse.usage() {
	# add to the existing USAGE__* variables to improve the --help message
	# (e.g. USAGE__options, USAGE__args, USAGE__description)
	USAGE__options+='
	'
	# rather than defining 'local DESCRIPTION' above, you can opt to definie
	# the USAGE__description here which is helpful when providing an executable
	# wrapper for this module
	#
	#USAGE__description=''
	#
}

${scwryptsmodule}.parse.validate() {
	#
	# after all arguments have been parsed, this validation is run
	#
	# although the exit code of this function IS IGNORED, you can indicate
	# validation errors by calling:
	#    echo.error 'error message'
	#
	# you can also 'return' early if you need, but 'return 1' is not considered
	# an error status (you MUST declare errors with echo.error)
	#
	# any data manipulation will be available in ${scwryptsmodule}() SO LONG AS
	# your variables are declared in ${scwryptsmodule}.parse.locals() (above)
	#
}
