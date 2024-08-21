utils.yq() {
	yq --version | grep -q mikefarah || {
		yq $@  # this is a different version from the preferred but throwing this in for compatibility
		return $?
	}

	yq eval '... comments=""' | yq $@
}
