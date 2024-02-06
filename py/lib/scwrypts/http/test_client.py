from unittest.mock import patch

from pytest import fixture

from .client import get_request_client


def test_request_client(sample, _response_basic):
    assert _response_basic == sample.response

def test_request_client_forwards_default_headers(sample, mock_request, _response_basic):
    mock_request.assert_called_once_with(
            method = sample.method,
            url = f'{sample.base_url}/{sample.endpoint}',
            headers = sample.headers,
            )

def test_get_request_client_payload(sample, _response_payload):
    assert _response_payload == sample.response

def test_request_client_forwards_payload_headers(sample, mock_request, _response_payload):
    assert mock_request.call_args.kwargs['headers'] == sample.headers | sample.payload_headers


#####################################################################

@fixture(name='mock_request', autouse=True)
def fixture_mock_request(sample):
    with patch('scwrypts.http.client.request') as mock:
        mock.return_value = sample.response
        yield mock

@fixture(name='request_client', autouse=True)
def fixture_request_client(sample):
    return get_request_client(sample.base_url, sample.headers)

#####################################################################

@fixture(name='_response_basic')
def fixture_response_basic(sample, request_client):
    return request_client(
            method   = sample.method,
            endpoint = sample.endpoint,
            )

@fixture(name='_response_payload')
def fixture_response_payload(sample, request_client):
    return request_client(
            method   = sample.method,
            endpoint = sample.endpoint,
            **{
                **sample.payload,
                'headers': sample.payload_headers,
                },
            )
