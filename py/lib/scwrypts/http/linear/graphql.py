from .client import request


def graphql(query):
    return request('POST', 'graphql', json={'query': query})
