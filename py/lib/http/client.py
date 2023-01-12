from requests import request


def get_request_client(base_url, headers=None):
    if headers is None:
        headers = {}

    return lambda method, endpoint, **kwargs: request(
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
