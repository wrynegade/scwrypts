#!/usr/bin/env python
from scwrypts import execute
#####################################################################
from json import dumps
from sys import stderr

from scwrypts.http import discord


description = 'post a message to the indicated discord channel'
parse_args = [
        ( ['-b', '--body'], {
            'dest'     : 'content',
            'help'     : 'message body',
            'required' : False,
            }),
        ( ['-c', '--channel-id'], {
            'dest'     : 'channel_id',
            'help'     : 'override default target channel id',
            'required' : False,
            }),
        ( ['-w', '--webhook'], {
            'dest'     : 'webhook',
            'help'     : 'override default target webhook (takes precedence over -c)',
            'required' : False,
            }),
        ( ['--avatar-url'], {
            'dest'     : 'avatar_url',
            'help'     : 'override default avatar_url',
            'required' : False,
            }),
        ( ['--username'], {
            'dest'     : 'username',
            'help'     : 'override default username',
            'required' : False,
            }),
        ]

def main(args, stream):
    if args.content is None:
        print(f'reading input from {stream.input.name}', file=stderr)
        args.content = ''.join(stream.readlines()).strip()

    if len(args.content) == 0:
        args.content = 'PING'

    response = discord.send_message(**vars(args))

    stream.writeline(dumps({
        **(response.json() if response.text != '' else {'message': 'OK'}),
        'scwrypts_metadata': {},
        }))


#####################################################################
if __name__ == '__main__':
    execute(main, description, parse_args)
