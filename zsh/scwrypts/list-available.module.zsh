${scwryptsmodule}() {
	local TYPE_COLOR=$(utils.colors.light-gray)
	local GROUP GROUP_ROOT GROUP_COLOR LOOKUP_PIDS=()
	{
	echo 'NAME^TYPE^GROUP'
	for GROUP in ${SCWRYPTS_GROUPS}
	do
		GROUP_ROOT="$(scwrypts.config.group ${GROUP} root)"
		GROUP_COLOR="$(scwrypts.config.group ${GROUP} color)"
		[ "${GROUP_COLOR}" ] || GROUP_COLOR=$(utils.colors.reset)

		GROUP_TYPE=$(scwrypts.config.group ${GROUP} type)
		[ ${GROUP_TYPE} ] && MINDEPTH=1 && GROUP_TYPE="${GROUP_TYPE}\\/" || MINDEPTH=2

		command -v SCWRYPTS_GROUP_CONFIGURATION__${GROUP}.list-available >/dev/null 2>&1 \
			&& LOOKUP=SCWRYPTS_GROUP_CONFIGURATION__${GROUP}.list-available \
			|| LOOKUP=scwrypts.list-available.default \
			;

		{
		${LOOKUP} \
			| sed "s|\\([^/]*\\)/\(.*\)$|$(utils.colors.reset)\\2^$(printf ${TYPE_COLOR})\\1^$(printf ${GROUP_COLOR})${GROUP}$(utils.colors.reset)|" \
		} &
		LOOKUP_PIDS+=($!)
	done
	for p in ${LOOKUP_PIDS[@]}; do wait $p; done
	} | column -t -s '^'
}

#####################################################################

${scwryptsmodule}.default() {
	cd ${GROUP_ROOT}
	find . -mindepth ${MINDEPTH} \
			\( \
				   -type d -name .git \
				-o -type d -name node_modules \
				-o -type d -name __pycache__ \
				-o -type d -path ./plugins \
				-o -type d -path ./.config \
				-o -type d -path ./.github \
				-o -type d -path ./docs \
				\) -prune \
			-o -type f -executable \
			-print \
		| sed "s/^\\.\\///; s/\\.[^.]*$//; s/^/${GROUP_TYPE}/" \
		;
}
