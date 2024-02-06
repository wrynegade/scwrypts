from scwrypts.env import getenv

from .. import get_request_client


def request(method, endpoint, **kwargs):
    headers = {}

    if (token := getenv("DISCORD__BOT_TOKEN", required = False)) is not None:
        headers['Authorization'] = f'Bot {token}'

    return get_request_client(
            base_url = 'https://discord.com/api',
            headers = headers,
            )(method, endpoint, **kwargs)
