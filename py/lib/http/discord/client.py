from py.lib.http import get_request_client
from py.lib.scwrypts import getenv

REQUEST = None

def request(method, endpoint, **kwargs):
    global REQUEST # pylint: disable=global-statement

    if REQUEST is None:
        headers = {}

        if (token := getenv("DISCORD__BOT_TOKEN", required = False)) is not None:
            headers['Authorization'] = f'Bot {token}'

        REQUEST = get_request_client(
                base_url = 'https://discord.com/api',
                headers = headers,
                )

    return REQUEST(method, endpoint, **kwargs)
