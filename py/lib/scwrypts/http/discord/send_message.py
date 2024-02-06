from scwrypts.env import getenv
from .client import request

def send_message(content, channel_id=None, webhook=None, username=None, avatar_url=None, **kwargs):
    if username is None:
        username = getenv('DISCORD__DEFAULT_USERNAME', required=False)

    if avatar_url is None:
        avatar_url = getenv('DISCORD__DEFAULT_AVATAR_URL', required=False)

    endpoint = None

    if webhook is not None:
        endpoint = f'webhooks/{webhook}'

    elif channel_id is not None:
        endpoint = f'channels/{channel_id}/messages'

    elif (webhook := getenv('DISCORD__DEFAULT_WEBHOOK', required=False)) is not None:
        endpoint = f'webhooks/{webhook}'

    elif (channel_id := getenv('DISCORD__DEFAULT_CHANNEL_ID', required=False)) is not None:
        endpoint = f'channels/{channel_id}/messages'

    else:
        raise ValueError('must provide target channel_id or webhook')

    if (header := getenv('DISCORD__CONTENT_HEADER', required=False)) is not None:
        content = f'{header}{content}'

    if (footer := getenv('DISCORD__CONTENT_FOOTER', required=False)) is not None:
        content = f'{content}{footer}'


    return request(
            method = 'POST',
            endpoint = endpoint,
            json = {
                key: value
                for key, value in {
                    'content': content,
                    'username': username,
                    'avatar_url': avatar_url,
                    **kwargs,
                    }.items()
                if value is not None
                },
            )
