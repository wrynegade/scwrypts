#!/usr/bin/env python

from py.redis.client import Client
from py.scwrypts import interactive, getenv


@interactive
def main():
    r = Client

    print(f'''
>>> r = StrictRedis({getenv("REDIS_HOST")}:{getenv("REDIS_PORT")})
    ''')

    return locals()


if __name__ == '__main__':
    main()
