from types import SimpleNamespace

from pytest import fixture

from scwrypts.test import generate
from scwrypts.test.character_set import uri

options = {
        'str_length_minimum':   8,
        'str_length_maximum': 128,
        'uuid_output_type':   str,
        }

def get_request_client_sample_data():
    return {
            'base_url' : generate(str, options | {'character_set': uri}),
            'endpoint' : generate(str, options | {'character_set': uri}),
            'method'   : generate(str, options),
            'response' : generate('requests_Response', options | {'depth': 4}),
            'payload'  : generate(dict, {
                **options,
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),
            }

@fixture(name='sample')
def fixture_sample():
    return SimpleNamespace(
            **get_request_client_sample_data(),

            headers = generate(dict, {
                **options,
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),

            payload_headers = generate(dict, {
                **options,
                'depth': 1,
                'data_types': { str, 'uuid' },
                }),
            )
