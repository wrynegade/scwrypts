from py.lib.http import get_request_client
from py.lib.scwrypts import getenv


REQUEST     = None
COLLECTIONS = None
FIELDS      = {}


def request(method, endpoint, **kwargs):
    global REQUEST # pylint: disable=global-statement

    if REQUEST is None:
        REQUEST = get_request_client(
                base_url = getenv("DIRECTUS__BASE_URL"),
                headers = {
                    'Authorization': f'bearer {getenv("DIRECTUS__API_TOKEN")}',
                    }
                )

    return REQUEST(method, endpoint, **kwargs)

def graphql(query, system=False):
    return request(
            'POST',
            'graphql' if system is True else 'graphql/system',
            json={'query': query},
            )


def get_collections():
    global COLLECTIONS # pylint: disable=global-statement

    if COLLECTIONS is None:
        COLLECTIONS = [
            item['collection']
            for item in request(
                'GET',
                'collections?limit=-1&fields[]=collection',
                ).json()['data']
            ]

    return COLLECTIONS


def get_fields(collection):
    if FIELDS.get(collection) is None:
        FIELDS[collection] = [
                item['field']
                for item in request(
                    'GET',
                    f'fields/{collection}?limit=-1&fields[]=field',
                    ).json()['data']
                ]

    return FIELDS[collection]
