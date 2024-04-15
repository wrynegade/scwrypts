from random import choice
from re import search
from string import ascii_letters, digits
from types import SimpleNamespace
from unittest.mock import patch

from pytest import fixture, raises

from scwrypts.test import get_generator

from .exceptions import MissingScwryptsExecutableError, BadScwryptsLookupError, MissingScwryptsGroupOrTypeError
from .scwrypts import scwrypts

#####################################################################

def test_scwrypts(sample, _scwrypts):
    assert validate_scwrypts_output(sample, _scwrypts)

def test_scwrypts_finds_system_executable(sample, _scwrypts, mock_which):
    mock_which.assert_called_once_with(sample.env['SCWRYPTS_EXECUTABLE'])

def test_scwrypts_uses_configured_executable_path(_scwrypts, mock_getenv):
    mock_getenv.assert_any_call('SCWRYPTS_EXECUTABLE', 'scwrypts')

def test_scwrypts_uses_correct_depth(_scwrypts, mock_getenv):
    mock_getenv.assert_any_call('SUBSCWRYPT', '')

def test_scwrypts_runs_subprocess(_scwrypts, mock_run):
    mock_run.assert_called_once()

##########################################

def test_scwrypts_omit_optionals(sample, _scwrypts_omit_optionals):
    assert validate_scwrypts_output(sample, _scwrypts_omit_optionals)

def test_scwrypts_omit_optionals_finds_system_executable(sample, _scwrypts_omit_optionals, mock_which):
    mock_which.assert_called_once_with('scwrypts')

def test_scwrypts_omit_optionals_uses_configured_executable_path(_scwrypts_omit_optionals, mock_getenv):
    mock_getenv.assert_any_call('SCWRYPTS_EXECUTABLE', 'scwrypts')

def test_scwrypts_omit_optionals_uses_correct_depth(_scwrypts_omit_optionals, mock_getenv):
    mock_getenv.assert_any_call('SUBSCWRYPT', '')

def test_scwrypts_omit_optionals_runs_subprocess(_scwrypts_omit_optionals, mock_run):
    mock_run.assert_called_once()

##########################################

def test_invalid_lookup_missing_patterns_and_name(sample):
    sample.patterns = None
    sample.name = None
    with raises(BadScwryptsLookupError):
        scwrypts(**get_scwrypts_args(sample))

def test_invalid_name_lookup_missing_group(sample):
    sample.group = None
    with raises(MissingScwryptsGroupOrTypeError):
        scwrypts(**get_scwrypts_args(sample))

def test_invalid_name_lookup_missing_type(sample):
    sample._type = None  # pylint: disable=protected-access
    with raises(MissingScwryptsGroupOrTypeError):
        scwrypts(**get_scwrypts_args(sample))

def test_invalid_scwrypts_installation(sample, mock_which):
    mock_which.return_value = None
    with raises(MissingScwryptsExecutableError):
        scwrypts(**get_scwrypts_args(sample))

#####################################################################

generate = get_generator({
    'str_length_minimum':   8,
    'str_length_maximum': 128,
    'character_set': ascii_letters + digits + '/-_'
    })

def _generate_str_or_list_arg():
    random_arg = generate(list, {'data_types': {str}})
    return random_arg if choice([str, list]) == list else ' '.join(random_arg)

@fixture(name='sample')
def fixture_sample():
    sample = SimpleNamespace(
            patterns        = _generate_str_or_list_arg(),
            args            = _generate_str_or_list_arg(),
            executable_args = _generate_str_or_list_arg(),

            name  = generate(str),
            group = generate(str),
            _type = generate(str),

            executable = generate(str),

            env = {
                'SCWRYPTS_EXECUTABLE': generate(str),
                'SUBSCWRYPT': str(generate(int, {'minimum': 1, 'maximum': 99})),
                },

            returncode = generate(int),
            stdout = generate(str),
            stderr = generate(str),
            )

    return sample

def get_scwrypts_args(sample):
    return {
            key: getattr(sample, key)
            for key in [
                'patterns',
                'args',
                'executable_args',
                'name',
                'group',
                '_type',
                ]
            }


#####################################################################

@fixture(name='mock_which', autouse=True)
def fixture_mock_which(sample):
    with patch('scwrypts.scwrypts.scwrypts.which') as mock:
        mock.return_value = sample.executable
        yield mock

@fixture(name='mock_getenv', autouse=True)
def fixture_mock_getenv(sample):
    with patch('scwrypts.scwrypts.scwrypts.getenv') as mock:
        mock.side_effect = sample.env.get
        yield mock

@fixture(name='mock_run', autouse=True)
def fixture_mock_run(sample):
    with patch('scwrypts.scwrypts.scwrypts.run') as mock:
        mock.side_effect = lambda *args, **_kwargs: SimpleNamespace(
                args = args,
                returncode = sample.returncode,
                stdout = sample.stdout,
                stderr = sample.stderr,
                )
        yield mock

#####################################################################

@fixture(name='_scwrypts')
def fixture_scwrypts(sample):
    return scwrypts(**get_scwrypts_args(sample))

@fixture(name='_scwrypts_omit_optionals')
def fixture_scwrypts_omit_optionals(sample):
    sample.args = None
    sample.executable_args = None

    del sample.env['SCWRYPTS_EXECUTABLE']
    del sample.env['SUBSCWRYPT']

    return scwrypts(**get_scwrypts_args(sample))

def validate_scwrypts_output(sample, output):
    #
    # I would love to use 'assert _scwrypts == SimpleNamespace(...expected...)'
    # but the output.args is difficult to recreate without copying all the
    # processing logic over from the scwrypts function
    #
    # opting for a bit of a strange equality test here, checking the args
    # as closely as possible without copying parsing logic
    #
    run_args_reduced_to_a_single_string = len(output.args) == 1
    run_args_follow_expected_form = search(
            fr'^SUBSCWRYPT=.* {sample.executable} .*-- .*$',
            output.args[0],
            )

    return all([
        run_args_reduced_to_a_single_string,
        run_args_follow_expected_form,
        output.returncode == sample.returncode,
        output.stdout     == sample.stdout,
        output.stderr     == sample.stderr,
        ])
