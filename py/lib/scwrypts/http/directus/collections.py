from .client import request


COLLECTIONS = None

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
