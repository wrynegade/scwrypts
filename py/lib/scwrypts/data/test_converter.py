from io import StringIO

from pytest import raises

from scwrypts.test import generate

from .converter import convert

GENERATE_OPTIONS = {
        'depth': 1,
        'minimum': -999999,
        'maximum':  999999,
        'dict_key_types': {str, int},
        'csv_columns_minimum': 10,
        'csv_columns_maximum': 64,
        'csv_rows_minimum': 10,
        'csv_rows_maximum': 64,
        }

INPUT_TYPES  = {'csv', 'json', 'yaml'}
OUTPUT_TYPES = {'csv', 'json', 'yaml'}


def test_convert_to_csv():
    for input_type in INPUT_TYPES:
        input_stream = generate(input_type, {
            **GENERATE_OPTIONS,
            'data_types': {bool,int,float,str},
            })

        if isinstance(input_stream, str):
            input_stream = StringIO(input_stream)


        convert(input_stream, input_type, StringIO(), 'csv')

def test_convert_to_json():
    for input_type in INPUT_TYPES:
        input_stream = generate(input_type, GENERATE_OPTIONS)

        if isinstance(input_stream, str):
            input_stream = StringIO(input_stream)

        convert(input_stream, input_type, StringIO(), 'json')

def test_convert_to_yaml():
    for input_type in INPUT_TYPES:
        input_stream = generate(input_type, GENERATE_OPTIONS)

        if isinstance(input_stream, str):
            input_stream = StringIO(input_stream)

        convert(input_stream, input_type, StringIO(), 'yaml')


def test_convert_deep_json_to_yaml():
    input_stream = generate('json', {**GENERATE_OPTIONS, 'depth': 4})
    convert(input_stream, 'json', StringIO(), 'yaml')

def test_convert_deep_yaml_to_json():
    input_stream = generate('yaml', {**GENERATE_OPTIONS, 'depth': 4})
    convert(input_stream, 'yaml', StringIO(), 'json')


def test_convert_output_unsupported():
    for input_type in list(INPUT_TYPES):
        with raises(ValueError):
            convert(StringIO(), input_type, StringIO(), generate(str))

def test_convert_input_unsupported():
    for output_type in list(OUTPUT_TYPES):
        with raises(ValueError):
            convert(StringIO(), generate(str), StringIO(), output_type)
