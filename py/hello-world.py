#!/usr/bin/env python
from py.lib.scwrypts import execute

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################


def main(args, stream):
    stream.writeline(args.message)


#####################################################################
execute(main,
        description = 'a simple "Hello, World!" program',
        parse_args = [
            ( ['-m', '--message'], {
                'dest'     : 'message',
                'default'  : 'HELLO WORLD',
                'help'     : 'message to print',
                'required' : False,
                }),
            ],
        )
