from unittest.mock import patch

from pytest import fixture, raises

from .send_message import send_message


def test_discord_send_message(sample, mock_request, _mock_getenv):
    expected = get_default_called_with(sample)

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_without_username(sample, mock_request, _mock_getenv):
    sample.username = None
    expected = get_default_called_with(sample)
    del expected['json']['username']

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_without_avatar_url(sample, mock_request, _mock_getenv):
    sample.avatar_url = None
    expected = get_default_called_with(sample)
    del expected['json']['avatar_url']

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_to_channel_id(sample, mock_request, _mock_getenv):
    sample.webhook = None
    expected = get_default_called_with(sample)
    expected['endpoint'] = f'channels/{sample.channel_id}/messages'

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_without_content_header(sample, mock_request, _mock_getenv):
    sample.content_header = None
    expected = get_default_called_with(sample)
    expected['json']['content'] = f'{sample.content}{sample.content_footer}'

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_without_content_footer(sample, mock_request, _mock_getenv):
    sample.content_footer = None
    expected = get_default_called_with(sample)
    expected['json']['content'] = f'{sample.content_header}{sample.content}'

    assert send_message(sample.content) == sample.response
    mock_request.assert_called_once_with(**expected)

def test_discord_send_message_error(sample, mock_request, _mock_getenv):
    with raises(ValueError):
        sample.webhook = None
        sample.channel_id = None

        send_message(sample.content)

#####################################################################

def get_default_called_with(sample):
    return {
            'method': 'POST',
            'endpoint': f'webhooks/{sample.webhook}',
            'json': {
                'content': f'{sample.content_header}{sample.content}{sample.content_footer}',
                'username': sample.username,
                'avatar_url': sample.avatar_url,
                },
            }

@fixture(name='mock_request', autouse=True)
def fixture_mock_request(sample):
    with patch('scwrypts.http.discord.send_message.request') as mock:
        mock.return_value = sample.response
        yield mock

@fixture(name='_mock_getenv')
def fixture_mock_getenv(sample):
    with patch('scwrypts.http.discord.send_message.getenv',) as mock:
        mock.side_effect = lambda name, **kwargs: {
                'DISCORD__DEFAULT_USERNAME': sample.username,
                'DISCORD__DEFAULT_AVATAR_URL': sample.avatar_url,
                'DISCORD__DEFAULT_WEBHOOK': sample.webhook,
                'DISCORD__DEFAULT_CHANNEL_ID': sample.channel_id,
                'DISCORD__CONTENT_HEADER': sample.content_header,
                'DISCORD__CONTENT_FOOTER': sample.content_footer,
                }[name]
        yield mock
