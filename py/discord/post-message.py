#!/usr/bin/env python
from json import dumps
from sys import stderr

from py.lib.http import discord
from py.lib.scwrypts import execute

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################

def main(args, stream):
    if args.body is None:
        print(f'reading input from {stream.input.name}', file=stderr)
        args.body = ''.join(stream.readlines()).strip()

    if len(args.body) == 0:
        args.body = 'PING'

    response = discord.send_message(
            content = args.body,
            channel_id = args.channel_id,
            webhook = args.webhook,
            avatar_url = args.avatar_url,
            )

    stream.writeline(dumps({
        **(response.json() if response.text != '' else {'message': 'OK'}),
        'scwrypts_metadata': {},
        }))


#####################################################################
execute(main,
        description = 'post a message to the indicated discord channel',
        parse_args = [
            ( ['-b', '--body'], {
                'dest'     : 'body',
                'help'     : 'message body',
                'required' : False,
                }),
            ( ['-c', '--channel-id'], {
                'dest'     : 'channel_id',
                'help'     : 'target channel id',
                'required' : False,
                }),
            ( ['-w', '--webhook'], {
                'dest'     : 'webhook',
                'help'     : 'target webhook (takes precedence over -c)',
                'required' : False,
                }),
            ( ['--avatar-url'], {
                'dest'     : 'avatar_url',
                'help'     : 'replace default avatar_url',
                'required' : False,
                }),
            ]
        )
