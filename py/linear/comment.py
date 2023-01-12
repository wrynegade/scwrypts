#!/usr/bin/env python
from argparse import ArgumentParser

from py.lib.data.io import get_stream, add_io_arguments
from py.lib.linear import graphql

if __name__ != '__main__':
    raise Exception('executable only; must run through scwrypts')


parser = ArgumentParser(description = 'comment on an issue in linear.app')

parser.add_argument(
        '-i', '--issue',
        dest     = 'issue_id',
        help     = 'issue short-code (e.g. CLOUD-319)',
        required = True,
        )

parser.add_argument(
        '-m', '--message',
        dest     = 'message',
        help     = 'comment to post to the target issue',
        required = True,
        )

add_io_arguments(parser, toggle_input=False)

args = parser.parse_args()

query = f'''
mutation CommentCreate {{
    commentCreate(
        input: {{
            issueId: "{args.issue_id}"
            body:    """from wrobot:
```
{args.message.strip()}
```"""
        }}
    ) {{ success }}
}}
'''

response = graphql(query)
with get_stream(args.output_file, 'w+') as output:
    output.write(response.text)
