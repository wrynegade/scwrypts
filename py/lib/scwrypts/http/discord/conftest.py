from string import ascii_letters, digits
from types import SimpleNamespace

from pytest import fixture

from scwrypts.test.character_set import uri
from ..conftest import generate, get_request_client_sample_data

@fixture(name='sample')
def fixture_sample():
    return SimpleNamespace(
            **{
                **get_request_client_sample_data(),
                'base_url': 'https://discord.com/api',
                },
            bot_token  = generate(str, {'character_set': uri}),
            username   = generate(str, {'character_set': ascii_letters + digits}),
            avatar_url = generate(str, {'character_set': uri}),
            webhook    = generate(str, {'character_set': uri}),
            channel_id = generate(str, {'character_set': uri}),
            content_header = generate(str),
            content_footer = generate(str),
            content = generate(str),
        )
