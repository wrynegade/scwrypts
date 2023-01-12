from py.lib.http import get_request_client
from py.lib.scwrypts import getenv


request = get_request_client(
        base_url = 'https://api.linear.app',
        headers = {
            'Authorization': f'bearer {getenv("LINEAR__API_TOKEN")}',
            }
        )

def graphql(query):
    return request('POST', 'graphql', json={'query': query})
