#!/usr/bin/env python
from py.lib.http.linear import graphql
from py.lib.scwrypts import execute

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################


def get_query(args):
    body = f'"""from wrobot:\n```\n{args.message}\n```\n"""'
    return f'''
        mutation CommentCreate {{
            commentCreate(
                input: {{
                    issueId: "{args.issue_id}"
                    body:    {body}
                }}
            ) {{ success }}
        }}'''

def main(args, stream):
    response = graphql(get_query(args))
    stream.writeline(response)


#####################################################################
execute(main,
        description = 'comment on an inssue in linear.app',
        parse_args = [
            ( ['-d', '--issue-id'], {
                'dest'     : 'issue_id',
                'help'     : 'issue short-code (e.g. CLOUD-319)',
                'required' : True,
                }),
            ( ['-m', '--message'], {
                'dest'     : 'message',
                'help'     : 'comment to post to the target issue',
                'required' : True,
                }),
            ]
        )
