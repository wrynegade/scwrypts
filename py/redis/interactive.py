#!/usr/bin/env python
from py.lib.redis import get_client
from py.lib.scwrypts import execute, interactive, getenv

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################


@interactive([
        f'r = StrictRedis(\'{getenv("REDIS_HOST")}:{getenv("REDIS_PORT")}\')',
    ])
def main(_args, _stream):
    # pylint: disable=possibly-unused-variable
    r = get_client()
    return locals()


#####################################################################
execute(main,
        description = 'establishes a redis client in an interactive python shell',
        parse_args = [],
        )
