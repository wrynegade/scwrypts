from os import getenv
from pprint import pprint
from random import randint

from .generate import generate, Generator

ITERATIONS = int(
        getenv(
            'PYTEST_ITERATIONS__scwrypts__test__generator',
            getenv('PYTEST_ITERATIONS', '99'),  # CI should use at least 999
            )
        )

FILE_LIKE_DATA_TYPES = { 'csv', 'json', 'yaml' }

def test_generate():  # generators should be quick and "just work" (no Exceptions)
    print()
    for data_type in Generator.get_supported_data_types():
        print(f'------- {data_type} -------')
        sample = generate(data_type)
        pprint(sample.getvalue() if data_type in {'csv', 'json', 'yaml'} else sample)
        for _ in range(ITERATIONS):
            generate(data_type)


def test_generate_depth_deep():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'depth': 4})

def test_generate_depth_shallow():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'depth': randint(-999, 0)})


def test_generate_range_all():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'minimum': -99, 'maximum': 99})

def test_generate_range_positive():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'minimum':   1, 'maximum': 99})

def test_generate_range_zero():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'minimum':   3, 'maximum':  3})

def test_generate_range_negative():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'minimum': -99, 'maximum': -1})


def test_generate_bool_nullable():
    for data_type in Generator.get_supported_data_types():
        generate(data_type, {'bool_nullable': True})
