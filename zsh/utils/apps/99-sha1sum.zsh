utils.sha1sum() {
	# only output the sha1 hash (normally output includes filename too)
	sha1sum | awk '{print $1}'
}

utils.sha1sum.filelist() {
	# provides a single sha1 hash for a list of input files
	sort | xargs sha1sum | utils.sha1sum
}
