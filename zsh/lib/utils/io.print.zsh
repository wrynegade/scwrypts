PRINT() {
	local MESSAGE
	local LAST_LINE_END='\n'
	local STDERR=1
	local STDOUT=0

	local LTRIM=1
	while [[ $# -gt 0 ]]
	do
		case $1 in
			-n | --no-trim-tabs ) LTRIM=0 ;;
			-x | --no-line-end  ) LAST_LINE_END='' ;;
			-o | --use-stdout   ) STDOUT=1; STDERR=0 ;;
			* ) MESSAGE+="$(echo $1) " ;;
		esac
		shift 1
	done

	MESSAGE="$(echo "$MESSAGE" | sed 's/%/%%/g')"

	local STYLED_MESSAGE="$({
		printf "${COLOR}"
		while IFS='' read line
		do
			[[ $PREFIX =~ ^[[:space:]]\+$ ]] && printf '\n'

			printf "${PREFIX} : $(echo "$line" | sed 's/^	\+//; s/ \+$//')"

			PREFIX=$(echo $PREFIX | sed 's/./ /g')
		done <<< $MESSAGE
	})"
	STYLED_MESSAGE="${COLOR}$(echo "$STYLED_MESSAGE" | sed 's/%/%%/g')${__COLOR_RESET}${LAST_LINE_END}"

	[[ $STDERR -eq 1 ]] && printf $STYLED_MESSAGE >&2
	[[ $STDOUT -eq 1 ]] && printf $STYLED_MESSAGE

	return 0
}
