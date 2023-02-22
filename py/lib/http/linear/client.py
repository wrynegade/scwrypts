from py.lib.http import get_request_client
from py.lib.scwrypts import getenv

REQUEST = None

def request(method, endpoint, **kwargs):
    global REQUEST # pylint: disable=global-statement

    if REQUEST is None:
        REQUEST = get_request_client(
                base_url = 'https://api.linear.app',
                headers = {
                    'Authorization': f'bearer {getenv("LINEAR__API_TOKEN")}',
                    }
                )

    return REQUEST(method, endpoint, **kwargs)

def graphql(query):
    return request('POST', 'graphql', json={'query': query})
