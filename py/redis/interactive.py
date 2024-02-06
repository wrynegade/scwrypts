#!/usr/bin/env python
from scwrypts import execute
#####################################################################
from scwrypts import interactive
from scwrypts.env import getenv
from scwrypts.redis import get_client


description = 'establishes a redis client in an interactive python shell'
parse_args = []

@interactive([
        f'r = StrictRedis(\'{getenv("REDIS_HOST")}:{getenv("REDIS_PORT")}\')',
    ])
def main(_args, _stream):
    # pylint: disable=possibly-unused-variable
    r = get_client()
    return locals()


#####################################################################
if __name__ == '__main__':
    execute(main, description, parse_args)
