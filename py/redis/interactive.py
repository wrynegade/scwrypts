#!/usr/bin/env python
from os import getenv

from py.redis.client import Client
from py.scwrypts import interactive


@interactive
def main():
    r = Client

    print('''
    r = StrictRedis("{getenv("REDIS_HOST")}")
    ''')

    return locals()


if __name__ == '__main__':
    main()
