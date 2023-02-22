#!/usr/bin/env python
from sys import stderr

from py.lib.scwrypts import execute, getenv
from py.lib.twilio import send_sms

from py.lib.scwrypts.exceptions import ImportedExecutableError, MissingFlagAndEnvironmentVariableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################

def main(args, stream):
    if args.body is None:
        print(f'reading input from {stream.input.name}', file=stderr)
        args.body = ''.join(stream.readlines()).strip()

    if len(args.body) == 0:
        args.body = 'PING'

    if args.from_ is None:
        raise MissingFlagAndEnvironmentVariableError(['-f', '--from'], 'TWILIO__DEFAULT_PHONE_FROM')

    if args.to is None:
        raise MissingFlagAndEnvironmentVariableError(['-t', '--to'], 'TWILIO__DEFAULT_PHONE_TO')

    send_sms(
            to = args.to,
            from_ = args.from_,
            body = args.body,
            max_char_count = args.max_char_count,
            stream = stream,
            )


#####################################################################
execute(main,
        description = 'send a simple SMS through twilio',
        parse_args = [
            ( ['-t', '--to'], {
                'dest'     : 'to',
                'help'     : 'phone number of the receipient',
                'required' : False,
                'default'  : getenv('TWILIO__DEFAULT_PHONE_TO', required=False),
                }),
            ( ['-f', '--from'], {
                'dest'     : 'from_',
                'help'     : 'phone number of the receipient',
                'required' : False,
                'default'  : getenv('TWILIO__DEFAULT_PHONE_FROM', required=False),
                }),
            ( ['-b', '--body'], {
                'dest'     : 'body',
                'help'     : 'message body',
                'required' : False,
                }),
            ( ['--max-char-count'], {
                'dest'     : 'max_char_count',
                'help'     : 'separate message into parts by character count (1 < N <= 1500)',
                'required' : False,
                'default'  : 300,
                }),
            ]
        )
