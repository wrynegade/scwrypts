zsh.is-in-array() {
	# works like the terse "${a[(re)v]}" syntax;
	# checks the array returns either
	#   '' (blank) when no match is found
	#   ${value}   when an exact match is found
	local array_variable="${1}"
	local value="${2}"

	[[ "${(Pt)array_variable}" =~ array ]] \
		|| echo.error "${array_variable} is not an array" \
		|| return 1

	local zsh_output="${${(P@)array_variable}[(re)${value}]}"

	echo "${zsh_output}"
	[[ "${zsh_output}" ]]
}
