#
# basic redis interface
#


# direct interface to redis-cli with long-flags for authentication arguments
use redis/cli


# silently checks whether redis is configured and connection is valid
use redis/enabled


# works just like curl, but caches if redis is available
use redis/curl
