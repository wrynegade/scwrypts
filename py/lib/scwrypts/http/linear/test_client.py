from unittest.mock import patch

from pytest import fixture

from .client import request


def test_discord_request(sample, _response):
    assert _response == sample.response

def test_discord_request_client_setup(sample, mock_get_request_client, _response):
    mock_get_request_client.assert_called_once_with(
            base_url = sample.base_url,
            headers = { 'Authorization': f'bearer {sample.api_token}' },
            )


#####################################################################

@fixture(name='_response')
def fixture_response(sample):
    return request(
            method   = sample.method,
            endpoint = sample.endpoint,
            **sample.payload,
            )

#####################################################################

@fixture(name='mock_get_request_client', autouse=True)
def fixture_mock_get_request_client(sample):
    with patch('scwrypts.http.linear.client.get_request_client') as mock:
        mock.return_value = lambda method, endpoint, **kwargs: sample.response
        yield mock

@fixture(name='mock_getenv', autouse=True)
def fixture_mock_getenv(sample):
    with patch('scwrypts.http.linear.client.getenv',) as mock:
        mock.side_effect = lambda name, **kwargs: {
                'LINEAR__API_TOKEN': sample.api_token,
                }[name]
        yield mock
