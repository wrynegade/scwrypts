from unittest.mock import patch

from pytest import fixture

from .client import request


def test_discord_request(sample, _response):
    assert _response == sample.response

def test_discord_request_client_setup(sample, mock_get_request_client, _mock_getenv, _response):
    mock_get_request_client.assert_called_once_with(
            base_url = sample.base_url,
            headers = { 'Authorization': f'Bot {sample.bot_token}' },
            )

def test_discord_request_client_setup_public(sample, mock_get_request_client, _mock_getenv_optional, _response):
    mock_get_request_client.assert_called_once_with(
            base_url = sample.base_url,
            headers = {},
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
    with patch('scwrypts.http.discord.client.get_request_client') as mock:
        mock.return_value = lambda method, endpoint, **kwargs: sample.response
        yield mock

@fixture(name='_mock_getenv')
def fixture_mock_getenv(sample):
    with patch('scwrypts.http.discord.client.getenv',) as mock:
        mock.side_effect = lambda name, **kwargs: {
                'DISCORD__BOT_TOKEN': sample.bot_token,
                }[name]
        yield mock

@fixture(name='_mock_getenv_optional')
def fixture_mock_getenv_optional():
    with patch('scwrypts.http.discord.client.getenv',) as mock:
        mock.side_effect = lambda name, **kwargs: None
        yield mock
