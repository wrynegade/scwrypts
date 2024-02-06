from scwrypts.env import getenv

from .. import get_request_client


def request(method, endpoint, **kwargs):
    return get_request_client(
            base_url = getenv("DIRECTUS__BASE_URL"),
            headers = {
                'Authorization': f'bearer {getenv("DIRECTUS__API_TOKEN")}',
                }
            )(method, endpoint, **kwargs)
