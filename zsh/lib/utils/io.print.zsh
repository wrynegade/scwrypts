PRINT() {
	local MESSAGE
	local LAST_LINE_END='\n'
	local STDERR=1
	local STDOUT=0

	local LTRIM=1
	local FORMAT=$SCWRYPTS_OUTPUT_FORMAT
	local _S
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			-n | --no-trim-tabs ) LTRIM=0 ;;
			-x | --no-line-end  ) LAST_LINE_END='' ;;
			-o | --use-stdout   ) STDOUT=1; STDERR=0 ;;

			-f | --format ) ((_S+=1)); FORMAT=$2 ;;

			* ) MESSAGE+="$(echo $1) " ;;
		esac
		shift $_S
	done

	[ $FORMAT ] || FORMAT=pretty
	local STYLED_MESSAGE
	case $FORMAT in
		pretty )
			STYLED_MESSAGE="$(echo "$MESSAGE" | sed 's/%/%%/g')"
			STYLED_MESSAGE="$({
				printf "${COLOR}"
				while IFS='' read line
				do
					[[ $PREFIX =~ ^[[:space:]]\+$ ]] && printf '\n'

					printf "${PREFIX} : $(echo "$line" | sed 's/^	\+//; s/ \+$//')"

					PREFIX=$(echo $PREFIX | sed 's/./ /g')
				done <<< $MESSAGE
			})"
			STYLED_MESSAGE="${COLOR}$(echo "$STYLED_MESSAGE" | sed 's/%/%%/g')${__COLOR_RESET}${LAST_LINE_END}"
			;;
		json )
			STYLED_MESSAGE="$(
				echo '{}' | jq -c ".
					| .timestamp = \"$(date +%s)\"
					| .runtime   = \"$SCWRYPTS_RUNTIME_ID\"
					| .status    = \"$(echo "$PREFIX" | sed 's/ .*//')\"
					| .message   = $(echo $MESSAGE | sed 's/^\t\+//' | jq -Rs)
					" | sed 's/\\/\\\\/g'
			)\n"
			;;
		* )
			echo "ERROR : unsupported format '$FORMAT'" >&2
			return 1
			;;
	esac



	[[ $STDERR -eq 1 ]] && printf -- "$STYLED_MESSAGE" >&2
	[[ $STDOUT -eq 1 ]] && printf -- "$STYLED_MESSAGE"

	return 0
}
