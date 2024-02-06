from .client import request


FIELDS      = {}

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
