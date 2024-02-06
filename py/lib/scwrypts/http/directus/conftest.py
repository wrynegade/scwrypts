from types import SimpleNamespace

from pytest import fixture

from scwrypts.test import generate
from scwrypts.test.character_set import uri
from ..conftest import options, get_request_client_sample_data


@fixture(name='sample')
def fixture_sample():
    return SimpleNamespace(
            **get_request_client_sample_data(),
            api_token = generate(str, options | {'character_set': uri}),
            query     = generate(str, options),
            )
