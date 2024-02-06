from requests import request


CLIENTS = {}

def get_request_client(base_url, headers=None):
    if CLIENTS.get(base_url, None) is None:
        if headers is None:
            headers = {}

        CLIENTS[base_url] = lambda method, endpoint, **kwargs: request(
                method = method,
                url = f'{base_url}/{endpoint}',
                headers = {
                    **headers,
                    **kwargs.get('headers', {}),
                    },
                **{
                    key: value
                    for key, value in kwargs.items()
                    if key != 'headers'
                    },
                )

    return CLIENTS[base_url]
