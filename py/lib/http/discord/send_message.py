from py.lib.scwrypts import getenv
from py.lib.http.discord import request

def send_message(content, channel_id=None, webhook=None, avatar_url=None, **kwargs):
    if channel_id is None:
        channel_id = getenv('DISCORD__DEFAULT_CHANNEL_ID', required=False)

    if avatar_url is None:
        avatar_url = getenv('DISCORD__DEFAULT_AVATAR_URL', required=False)

    endpoint = None

    if webhook is not None:
        endpoint = f'webhooks/{webhook}'
    elif channel_id is not None:
        endpoint = f'channels/{channel_id}/messages'
    else:
        raise ValueError('must provide target channel_id or webhook')


    return request(
            method = 'POST',
            endpoint = endpoint,
            json = {
                key: value
                for key, value in {
                    'content': content,
                    'username': 'wrobot',
                    'avatar_url': avatar_url,
                    **kwargs,
                    }.items()
                if value is not None
                },
            )
