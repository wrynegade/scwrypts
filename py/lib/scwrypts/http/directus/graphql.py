from .client import request


def graphql(query, system=False):
    return request(
            'POST',
            'graphql' if system is False else 'graphql/system',
            json={'query': query},
            )
