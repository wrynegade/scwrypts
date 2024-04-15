from types import SimpleNamespace

from pytest import fixture

from scwrypts.test import get_generator
from scwrypts.test.character_set import uri

generate = get_generator({
        'str_length_minimum':   8,
        'str_length_maximum': 128,
        'uuid_output_type':   str,
        })

def get_request_client_sample_data():
    return {
            'base_url' : generate(str, {'character_set': uri}),
            'endpoint' : generate(str, {'character_set': uri}),
            'method'   : generate(str),
            'response' : generate('requests_Response', {'depth': 4}),
            'payload'  : generate(dict, {
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),
            }

@fixture(name='sample')
def fixture_sample():
    return SimpleNamespace(
            **get_request_client_sample_data(),

            headers = generate(dict, {
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),

            payload_headers = generate(dict, {
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),
            )
