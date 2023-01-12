#!/usr/bin/env python
from argparse import ArgumentParser

from py.lib.redis.client import Client
from py.lib.scwrypts import interactive, getenv

if __name__ != '__main__':
    raise Exception('executable only; must run through scwrypts')


parser = ArgumentParser(description = 'establishes a redis client in an interactive python shell')
args = parser.parse_args()

@interactive
def main():
    # pylint: disable=possibly-unused-variable
    r = Client

    print(f'''
>>> r = StrictRedis({getenv("REDIS_HOST")}:{getenv("REDIS_PORT")})
    ''')

    return locals()

main()
