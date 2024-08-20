#####################################################################

use scwrypts/environment/common

use scwrypts/environment/user
use scwrypts/environment/get-full-template
use scwrypts/environment/select-env

#####################################################################

[ $SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE ] \
	|| export SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE=basic

scwrypts.environment.update() {
	local EDIT_MODE=$SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE
	local ENVIRONMENT_NAME="$SCWRYPTS_ENV"
	local FROM_EXISTING

	local USAGE="
		usage: scwrypts.environment.update [...options...]

		options:
			--mode <string>   update execution mode (default: $SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE)
			   modes:
			      basic     : create or edit environment with all tooltips and metadata
			      quiet     : create or edit a compact environment with minimal metadata
			      init      : create a new environment with no edit prompt
			      delete    : delete target environment
			      recursive : (advanced) edit all inherited environments, starting from deepest parent
			      copy      : (see --create-from-existing; most likely you don't need to set this flag)

			--environment-name <string>       name of the target environment (default is current: $SCWRYPTS_ENV)
			--create-from-existing <string>   name of the environment to copy

			-h, --help   print this dialogue and exit
	"

	local _S ERRORS=0
	while [[ $# -gt 0 ]]
	do
		_S=1
		case $1 in
			-h | --help ) utils.io.usage; return 0 ;;

			--environment-name )
				[ $2 ] && ((_S+=1)) || echo.error "missing environment name" || break
				ENVIRONMENT_NAME="$2"
				;;

			--create-from-existing )
				[ $2 ] && ((_S+=1)) || echo.error "must provide environment name to copy" || break
				EDIT_MODE=copy
				FROM_EXISTING="$2"
				;;

			--mode )
				[ $2 ] && ((_S+=1)) || echo.error "missing mode" || break
				EDIT_MODE="$2"
				command -v scwrypts.environment.update.edit.$EDIT_MODE &>/dev/null \
					|| echo.error "invalid mode '$EDIT_MODE'"

				;;

			* ) echo.error "unknown argument '$1'" ;;
		esac
		shift $_S
	done

	case $EDIT_MODE in
		copy )
			[ $FROM_EXISTING ] || FROM_EXISTING=$(scwrypts.environment.select-env)
			[ $FROM_EXISTING ] || echo.error "cannot work in '$EDIT_MODE' without existing target"

			[[ $(scwrypts.environment.common.find-env-files-by-name "$FROM_EXISTING" | wc -l) -gt 0 ]] \
				|| echo.error "no such environment '$FROM_EXISTING' exists"
			;;

		* )
			[ ! $FROM_EXISTING ] || echo.error "cannot work in '$EDIT_MODE' with --create-from-existing"
			;;
	esac

	utils.check-errors --no-fail || return $?

	local TEMP_CONFIG_FILE="$SCWRYPTS_TEMP_PATH/environment.temp.yaml"

	[ -f "$TEMP_CONFIG_FILE" ] && {
		echo.error "temp config file already exists at '$TEMP_CONFIG_FILE'\nis another environment update in-progress?"
		echo.reminder "if you are certain no other environment update is in progress, you can resolve with\n  rm -- '$TEMP_CONFIG_FILE'"
		return 1
	}

	scwrypts.environment.update.edit.${EDIT_MODE}
	local EXIT_CODE=$?

	rm "$TEMP_CONFIG_FILE" 2>/dev/null

	return $EXIT_CODE
}

#####################################################################

${scwryptsmodule}.edit.basic() {
	scwrypts.environment.user.get \
		--environment-name $ENVIRONMENT_NAME \
		> "$TEMP_CONFIG_FILE"

	utils.io.edit "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "$(cat "$TEMP_CONFIG_FILE")" "$ENVIRONMENT_NAME"
}

${scwryptsmodule}.edit.quiet() {
	echo "---  # $ENVIRONMENT_NAME" > "$TEMP_CONFIG_FILE"
	scwrypts.environment.user.get \
			--environment-name $ENVIRONMENT_NAME \
		| utils.yq '.
			| del(.. | select(has(".ENVIRONMENT")).".ENVIRONMENT")
			| del(.. | select(has(".GROUP")).".GROUP")
			| del(.. | select(has(".DESCRIPTION")).".DESCRIPTION")
			| del(.. | select(has("selection") and (.selection == null or (.selection | length) == 0)).selection)
			| del(.. | select(has("selection") and has("value") and .value == null).value)
			| del(.. | select(has(".PARENTVALUE") and has("value") and .value == null).value)
			' \
		>> "$TEMP_CONFIG_FILE"

	utils.io.edit "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "$(cat "$TEMP_CONFIG_FILE")" "$ENVIRONMENT_NAME"
}

${scwryptsmodule}.edit.recursive() {
	local RECURSIVE_EDIT_MODE="$SCWRYPTS_ENVIRONMENT__PREFERRED_EDIT_MODE"
	[[ $RECURSIVE_EDIT_MODE =~ ^recursive$ ]] \
		&& RECURSIVE_EDIT_MODE=quiet

	local PARENT_ENVIRONMENT_NAME
	for PARENT_ENVIRONMENT_NAME in \
		$(scwrypts.environment.common.get-parent-env-names "$ENVIRONMENT_NAME") \
		$ENVIRONMENT_NAME
		;
	do
		echo.status "editing environment '$PARENT_ENVIRONMENT_NAME'"
		scwrypts.environment.update \
			--environment-name $PARENT_ENVIRONMENT_NAME \
			--mode $RECURSIVE_EDIT_MODE \
			;
	done
}

${scwryptsmodule}.edit.init() {
	[ -f "$(scwrypts.environment.common.get-env-filename)" ]

	scwrypts.environment.user.get \
		--environment-name $ENVIRONMENT_NAME \
		> "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "$(cat "$TEMP_CONFIG_FILE")"
}

${scwryptsmodule}.edit.copy() {
	local GROUP_CONFIG_FILENAME SOURCE_CONFIG_FILENAME
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		cp \
			"$(scwrypts.environment.common.get-env-filename "$FROM_EXISTING" "$GROUP")" \
			"$(scwrypts.environment.common.get-env-filename "$ENVIRONMENT_NAME" "$GROUP")" \
			2>/dev/null \
			;
	done

	scwrypts.environment.user.get \
		--environment-name $ENVIRONMENT_NAME \
		> "$TEMP_CONFIG_FILE"

	scwrypts.environment.update.update-user-configs "$(cat "$TEMP_CONFIG_FILE")"
}

${scwryptsmodule}.edit.delete() {
	touch "$TEMP_CONFIG_FILE"

	local ERRORS=0 GROUP GROUP_CONFIG_FILENAME
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		local GROUP_CONFIG_FILENAME="$(scwrypts.environment.common.get-env-filename "$ENVIRONMENT_NAME" "$GROUP")"
		[ -f "$GROUP_CONFIG_FILENAME" ] || {
			echo.status "nothing to cleanup for $ENVIRONMENT_NAME/$GROUP"
			continue
		}

		rm -- "$GROUP_CONFIG_FILENAME" \
			&& echo.success "deleted '$GROUP_CONFIG_FILENAME'" \
			|| echo.error "unable to delete '$GROUP_CONFIG_FILENAME'" \
			;
	done

	return $ERRORS
}

#####################################################################
#####################################################################
#####################################################################

export __SCWRYPTS_ENVIRONMENT__WORKFLOW_IS_CHANGE_SAFE=false
${scwryptsmodule}.update-user-configs() {
	local NEW_CONFIGURATION="$1"
	[ $NEW_CONFIGURATION ] || return 1

	local ENVIRONMENT_NAME="$2"
	[ $ENVIRONMENT_NAME ] || return 2

	# reinject all metadata, since the update function is allowed to strip it
	NEW_CONFIGURATION="$(
		{
			scwrypts.environment.user.get-full-template-with-value-keys --environment "$ENVIRONMENT_NAME"
			echo ---
			echo "$NEW_CONFIGURATION"
		} | scwrypts.environment.common.combine-template-files
	)"

	local METADATA_DELETE_QUERY="$(
		echo "$NEW_CONFIGURATION" \
			| sed -n 's/^\s\+\(\.[-A-Za-z_:]\+\):.*$/ | del(.. | select(has("\1"))."\1")/p' \
			| sort --unique \
			)"

	local GROUP GROUP_CONFIG_FILENAME GROUP_CONFIG
	for GROUP in ${SCWRYPTS_GROUPS[@]}
	do
		local GROUP_CONFIG="$(echo "$NEW_CONFIGURATION" \
			| utils.yq ".
					| del(.. | select(has(\".PARENTVALUE\") and has(\"value\") and .\".PARENTVALUE\" == .value))
					| del(.. | select(has(\".PARENTSELECTION\") and has(\"selection\") and .\".PARENTSELECTION\" == .selection))
					| del(.. | select(has(\".GROUP\") and .\".GROUP\" != \"$GROUP\"))
					| del(.. | select(has(\"selection\") and (.selection == null or (.selection | length) == 0)).selection)
					| del(.. | select(has(\"value\") and .value == null).value)
					$METADATA_DELETE_QUERY
				" \
		)"

		while echo "$GROUP_CONFIG" | grep -q '{}'
		do
			GROUP_CONFIG="$(echo "$GROUP_CONFIG" | utils.yq 'del(.. | select(tag == "!!map" and length == 0))')"
		done

		[ "$GROUP_CONFIG" ] || GROUP_CONFIG='# no configuration set'

		echo "---  # $ENVIRONMENT_NAME > $GROUP\n$GROUP_CONFIG" > "$(scwrypts.environment.common.get-env-filename "$ENVIRONMENT_NAME" "$GROUP")"
	done

	[[ $ENVIRONMENT_NAME =~ ^$SCWRYPTS_ENV$ ]] && [[ $__SCWRYPTS_ENVIRONMENT__WORKFLOW_IS_CHANGE_SAFE =~ false ]] && {
		echo.warning "current scwrypts environment has changed"
		export __SCWRYPTS_ENVIRONMENT__USER_ENVIRONMENT=
	}

	return 0
}
