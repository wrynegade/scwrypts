from unittest.mock import patch

from pytest import fixture

from .graphql import graphql


def test_directus_graphql(sample, _response, _mock_request):
    assert _response == sample.response

def test_directus_graphql_request_payload(sample, _response, _mock_request):
    _mock_request.assert_called_once_with(
            'POST',
            'graphql',
            json = {'query': sample.query},
            )

def test_directus_graphql_system(sample, _response_system):
    assert _response_system == sample.response

def test_directus_graphql_system_request_payload(sample, _response_system, _mock_request):
    _mock_request.assert_called_once_with(
            'POST',
            'graphql/system',
            json = {'query': sample.query},
            )

#####################################################################

@fixture(name='_response')
def fixture_response(sample, _mock_request):
    return graphql(sample.query)


@fixture(name='_response_system')
def fixture_response_system(sample, _mock_request):
    return graphql(sample.query, system=True)

#####################################################################

@fixture(name='_mock_request')
def fixture_mock_request(sample):
    with patch('scwrypts.http.directus.graphql.request') as mock:
        mock.return_value = sample.response
        yield mock
