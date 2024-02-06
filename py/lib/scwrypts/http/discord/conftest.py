from string import ascii_letters, digits
from types import SimpleNamespace

from pytest import fixture

from scwrypts.test import generate
from scwrypts.test.character_set import uri
from ..conftest import options, get_request_client_sample_data

@fixture(name='sample')
def fixture_sample():
    return SimpleNamespace(
            **{
                **get_request_client_sample_data(),
                'base_url': 'https://discord.com/api',
                },
            bot_token  = generate(str, options | {'character_set': uri}),
            username   = generate(str, options | {'character_set': ascii_letters + digits}),
            avatar_url = generate(str, options | {'character_set': uri}),
            webhook    = generate(str, options | {'character_set': uri}),
            channel_id = generate(str, options | {'character_set': uri}),
            content_header = generate(str, options),
            content_footer = generate(str, options),
            content = generate(str, options),
        )
