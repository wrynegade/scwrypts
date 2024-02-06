#!/usr/bin/env python
from scwrypts import execute
#####################################################################

description = 'a simple "Hello, World!" program'
parse_args = [
        ( ['-m', '--message'], {
            'dest'     : 'message',
            'default'  : 'HELLO WORLD',
            'help'     : 'message to print',
            'required' : False,
            }),
        ]

def main(args, stream):
    stream.writeline(args.message)


#####################################################################
if __name__ == '__main__':
    execute(main, description, parse_args)
