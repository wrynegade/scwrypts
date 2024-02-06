from scwrypts.env import getenv

from .. import get_request_client


def request(method, endpoint, **kwargs):
    return get_request_client(
            base_url = 'https://api.linear.app',
            headers = {
                'Authorization': f'bearer {getenv("LINEAR__API_TOKEN")}',
                },
            )(method, endpoint, **kwargs)
