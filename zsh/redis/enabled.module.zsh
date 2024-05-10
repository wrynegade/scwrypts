#####################################################################

use redis/cli

#####################################################################

${scwryptsmodule}() {  # silent; returns true if connection succeeds
	SUPPRESS_USAGE_OUTPUT=true redis.cli $@ ping 2>&1 | grep -qi pong
}
