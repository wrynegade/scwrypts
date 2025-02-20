#####################################################################
command -v compdef >/dev/null 2>&1 || return 0
#####################################################################

for CLI in kubectl helm flux
do
	eval "_${CLI[1]}() {
		local SUBSESSION=0
		local SUBSESSION_OFFSET=2
		echo \${words[2]} | grep -q '^[0-9]\\+$' && SUBSESSION=\${words[2]} && SUBSESSION_OFFSET=3

		local PASSTHROUGH_WORDS=($CLI)
		[[ \$CURRENT -gt \${SUBSESSION_OFFSET} ]] && echo \${words[\${SUBSESSION_OFFSET}]} | grep -qv '^[0-9]\\+$' && {
			local KUBECONTEXT=\$(k \$SUBSESSION meta get context)
			local NAMESPACE=\$(k \$SUBSESSION meta get namespace)

			[ \$KUBECONTEXT ] \
				&& PASSTHROUGH_WORDS+=($([[ $CLI =~ ^helm$ ]] && echo '--kube-context' || echo '--context') \$KUBECONTEXT) \
				;
			[ \$NAMESPACE   ] \
				&& PASSTHROUGH_WORDS+=(--namespace \$NAMESPACE) \
				;
		}

		local DELIMIT_COUNT=0
		local WORD
		for WORD in \${words[@]:1}
		do
			case \$WORD in
				( [0-9]* ) continue ;;
				( -- )
					echo \$words | grep -q 'exec' && ((DELIMIT_COUNT+=1))
					[[ \$DELIMIT_COUNT -eq 0 ]] && ((DELIMIT_COUNT+=1)) && continue
					;;
			esac
			PASSTHROUGH_WORDS+=(\"\$WORD\")
		done

		echo \"\$words\" | grep -q '\\s\\+$' && PASSTHROUGH_WORDS+=(' ')

		words=\"\${PASSTHROUGH_WORDS[@]}\"
		_$CLI
	}
	"

	compdef _${CLI[1]} ${CLI[1]}
done
