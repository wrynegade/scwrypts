USAGE() { # formatter for USAGE variable
	[ ! $USAGE ] && return 0
	local USAGE_LINE=$(echo $USAGE | grep -i '^[	]*usage *:' | sed 's/^[		]*//')

	[ "$USAGE__options" ] && [ "$USAGE__usage" ] && {
		[[ $USAGE__usage =~ options ]] || USAGE__usage+=' [...options...]'
	}

	[ $USAGE__usage ] && echo $USAGE_LINE | grep -q 'usage: -' \
		&& USAGE_LINE=$(echo $USAGE_LINE | sed "s/usage: -/usage: $USAGE__usage/")

	[ $__SCWRYPT ] && [[ ! $USAGE_LINE =~ 'usage: [A-Z]' ]] \
		&& USAGE_LINE=$(
			echo $USAGE_LINE \
				| sed "s;^[^:]*:;& scwrypts $SCWRYPT_NAME --;" \
				| sed 's/ \{2,\}/ /g; s/scwrypts -- scwrypts/scwrypts/' \
			)

	local THE_REST=$(echo $USAGE | grep -vi '^[		]*usage *:' )

	local DYNAMIC_USAGE_ELEMENT
	#
	# create dynamic usage elements (like 'args') by defining USAGE__<element>
	# then using the syntax "<element>: -" in your USAGE variable
	#
	# e.g.
	#
	# USAGE__args="
	#	subcommand arg 1   arg 1 description
	#   subcommand arg 2   some other description
	# "
	#
	# USAGE="
	# usage: some-command [...args...]
	#
	# args: -
	#   -h, --help   some arguments are applicable everywhere
	# "
	#
	for DYNAMIC_USAGE_ELEMENT in $(echo $THE_REST | sed -n 's/^\([^:]*\): -$/\1/p')
	do
		DYNAMIC_USAGE_ELEMENT_TEXT=$(eval echo '$USAGE__'$DYNAMIC_USAGE_ELEMENT)
		[ $DYNAMIC_USAGE_ELEMENT_TEXT ] || continue


		case $DYNAMIC_USAGE_ELEMENT in
			description )
				DYNAMIC_USAGE_ELEMENT_TEXT=$(echo "$DYNAMIC_USAGE_ELEMENT_TEXT" | perl -p0e 's/^[\n\s]+//')
			DYNAMIC_USAGE_ELEMENT_TEXT="$__YELLOW\\033[03m$DYNAMIC_USAGE_ELEMENT_TEXT\\033[0m"
				;;
			* )
			DYNAMIC_USAGE_ELEMENT_TEXT=$(echo $DYNAMIC_USAGE_ELEMENT_TEXT | sed 's/[^	]/  &/')
				;;
		esac

		THE_REST=$(echo $THE_REST | perl -pe "s$DYNAMIC_USAGE_ELEMENT: -$DYNAMIC_USAGE_ELEMENT:\n$DYNAMIC_USAGE_ELEMENT_TEXT\n\n")
	done

	# allow for dynamic 'description: -' but delete the 'description:' header line
	THE_REST=$(echo $THE_REST | sed '/^[		]*description:$/d')

	echo "$__BLUE$USAGE_LINE$__COLOR_RESET\n\n$THE_REST" \
		| sed "s/^\t\+//; s/\s\+$//; s/^\\s*$//;" \
		| sed '/./,$!d; :a; /^\n*$/{$d;N;ba;};' \
		| perl -p0e 's/\n{2,}/\n\n/g' \
		| perl -p0e 's/:\n{2,}/:\n/g' \
		| perl -p0e 's/([a-z]+:)\n([a-z]+:)/\2/g' \
		| sed -z 's/\s\n\+$//' \
		>&2
}

USAGE__reset() {
	# eval "$(USAGE__reset)" to setup local usage defaults
	echo "
	local USAGE__usage=${funcstack[2]}
	local USAGE__options
	local USAGE__args
	local USAGE__description
	local USAGE='
		usage: -

		options: -

		args: -

		description: -
		'
	"
}
