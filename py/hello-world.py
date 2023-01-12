#!/usr/bin/env python
from argparse import ArgumentParser

if __name__ != '__main__':
    raise Exception('executable only; must run through scwrypts')


parser = ArgumentParser(description = 'a simple "Hello, World!" program')
parser.add_argument(
        '-m', '--message',
        dest     = 'message',
        default  = 'HELLO WORLD',
        help     = 'message to print to stdout',
        required = False,
        )

args = parser.parse_args()

print(args.message)
