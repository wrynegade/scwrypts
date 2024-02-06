from csv import writer, QUOTE_NONNUMERIC
from io import StringIO
from json import dumps, loads
from random import randint, uniform, choice
from re import sub
from string import printable
from typing import Hashable, Callable
from uuid import uuid4

from requests import Response, status_codes
from yaml import safe_dump

from .exceptions import NoDataTypeError, BadGeneratorTypeError


DEFAULT_OPTIONS = {
        'data_types': None,
        'minimum':  0,
        'maximum': 64,
        'depth': 1,
        'character_set': None,
        'bool_nullable': False,
        'str_length': None,
        'str_length_minimum': 0,
        'str_length_maximum': 64,
        'uuid_output_type': 'uuid',  # str or 'uuid'
        'list_length': 8,
        'set_length': 8,
        'dict_length': 8,
        'csv_bool_nullable': True,
        'csv_columns': None,
        'csv_columns_minimum': 1,
        'csv_columns_maximum': 16,
        'csv_rows': None,
        'csv_rows_minimum': 2,
        'csv_rows_maximum': 16,
        'csv_output_type': 'stringio',  # str or 'stringio'
        'json_initial_type': dict,  # typically dict or list
        'json_bool_nullable': True,
        'json_output_type': 'stringio',  # str or 'stringio'
        'yaml_initial_type': dict,  # typically dict or list
        'yaml_bool_nullable': True,
        'yaml_use_default_flow_style': False,
        'yaml_output_type': 'stringio',  # str or 'stringio'
        'requests_response_status_code': status_codes.codes[200],
        }

def generate(data_type=None, options=None):
    '''
    generate random data with the call of a function
        use data_type to generate a single value

        use options to set generation options (key = type, value = kwargs)

        use options.data_types and omit data_type to generate a random type
    '''
    if options is None:
        options = {}

    options = DEFAULT_OPTIONS | options

    if data_type is None:
        if options['data_types'] is None or len(options['data_types']) == 0:
            raise NoDataTypeError()

        return generate(
                data_type=choice(list(options['data_types'])),
                options=options,
                )

    if not isinstance(data_type, str):
        data_type = data_type.__name__

    if data_type not in Generator.get_supported_data_types():
        raise BadGeneratorTypeError(data_type)

    return getattr(Generator, f'_{data_type}')(options)

#####################################################################

SUPPORTED_DATA_TYPES = None

class Generator:

    @classmethod
    def get_supported_data_types(cls):
        global SUPPORTED_DATA_TYPES  # pylint: disable=global-statement

        if SUPPORTED_DATA_TYPES is None:
            SUPPORTED_DATA_TYPES = {
                    sub('^_', '', data_type)
                    for data_type, method in Generator.__dict__.items()
                    if isinstance(method, staticmethod)
                    }

        return SUPPORTED_DATA_TYPES

    #####################################################################

    @classmethod
    def filter_data_types(cls, options, filters=None):
        '''
        returns an options dict with appropriately filtered data_types

        if data_types are not yet defined, starts with all supported data_types
        '''
        if options['data_types'] is None:
            options['data_types'] = Generator.get_supported_data_types()

        if filters is None or len(filters) == 0:
            return options

        return {
                **options,
                'data_types': set(filter(
                    lambda data_type: all(( f(data_type, options) for f in filters )),
                    options['data_types'],
                    )),
                }

    class Filters:
        @staticmethod
        def hashable(data_type, _options):
            if isinstance(data_type, Callable):
                return isinstance(data_type(), Hashable)
            if not isinstance(data_type, str):
                data_type = data_type.__name__
            return data_type in { 'bool', 'int', 'float', 'chr', 'str', 'uuid' }

        @staticmethod
        def filelike(data_type, _options):
            return data_type in { 'csv', 'json', 'yaml' }

        @staticmethod
        def complex(data_type, _options):
            return data_type in { 'requests_Response' }

        @staticmethod
        def basic(data_type, options):
            return all([
                not Generator.Filters.filelike(data_type, options),
                not Generator.Filters.complex(data_type, options),
                ])

        @staticmethod
        def pythonset(data_type, _options):
            if not isinstance(data_type, str):
                data_type = data_type.__name__
            return data_type == 'set'

        @staticmethod
        def csvsafe(data_type, options):
            options['depth'] = max(1, options['depth'])
            return all([
                Generator.Filters.basic(data_type, options),
                not Generator.Filters.pythonset(data_type, options),
                ])

        @staticmethod
        def jsonsafe(data_type, options):
            return all([
                Generator.Filters.basic(data_type, options),
                not Generator.Filters.pythonset(data_type, options),
                ])

        @staticmethod
        def yamlsafe(data_type, options):
            return all([
                Generator.Filters.basic(data_type, options),
                not Generator.Filters.pythonset(data_type, options),
                ])

    #####################################################################

    @classmethod
    def get_option_with_range(cls, options, option_key, data_type=int):
        '''
        typically an integer range, allows both:
            - setting a fixed configuration (e.g. 'str_length')
            - allowing a configuration range (e.g. 'str_length_minimum' and 'str_length_maximum')
        '''
        fixed = options.get(option_key, None)
        if fixed is not None:
            return fixed

        return generate(data_type, {
            'minimum': options[f'{option_key}_minimum'],
            'maximum': options[f'{option_key}_maximum'],
            })

    #####################################################################


    @staticmethod
    def _bool(options):
        return choice([True, False, None]) if options['bool_nullable'] else choice([True, False])


    @staticmethod
    def _int(options):
        return randint(options['minimum'], options['maximum'])


    @staticmethod
    def _float(options):
        return uniform(options['minimum'], options['maximum'])


    @staticmethod
    def _chr(options):
        character_set = options['character_set']
        return choice(character_set) if character_set is not None else chr(randint(0,65536))


    @staticmethod
    def _str(options):
        return ''.join((
            generate(chr, options)
            for _ in range(Generator.get_option_with_range(options, 'str_length'))
            ))


    @staticmethod
    def _uuid(options):
        '''
        creates a UUID object or a str containing a uuid (v4)
        '''
        uuid = uuid4()
        return str(uuid) if options['uuid_output_type'] == str else uuid


    @staticmethod
    def _list(options):
        if options['depth'] <= 0:
            return []

        options['depth'] -= 1
        options = Generator.filter_data_types(options, [
            Generator.Filters.basic,
            ])

        return [ generate(None, {**options}) for _ in range(options['list_length']) ]


    @staticmethod
    def _set(options):
        if options['depth'] <= 0:
            return set()

        options['depth'] -= 1
        options = Generator.filter_data_types(options, [
            Generator.Filters.hashable,
            ])

        return { generate(None, options) for _ in range(options['set_length']) }


    @staticmethod
    def _dict(options):
        if options['depth'] <= 0:
            return {}

        options['depth'] -= 1
        options = Generator.filter_data_types(options, [
            Generator.Filters.basic,
            ])

        key_options = Generator.filter_data_types(options, [
            Generator.Filters.hashable,
            ])

        if len(options['data_types']) == 0 or len(key_options['data_types']) == 0:
            return {}

        return {
                generate(None, key_options): generate(None, options)
                for _ in range(options['dict_length'])
                }


    @staticmethod
    def _csv(options):
        '''
        creates a StringIO object containing csv data
        '''
        if options['character_set'] is None:
            options['character_set'] = printable

        options['bool_nullable'] = options['csv_bool_nullable']
        options = Generator.filter_data_types(options, [
            Generator.Filters.csvsafe,
            ])

        columns = Generator.get_option_with_range(options, 'csv_columns')
        rows    = Generator.get_option_with_range(options, 'csv_rows')


        csv = StringIO()
        csv_writer = writer(csv, quoting=QUOTE_NONNUMERIC)

        options['list_length'] = columns

        [  # pylint: disable=expression-not-assigned
                csv_writer.writerow(generate(list, options))
                for _ in range(rows)
                ]

        csv.seek(0)
        return csv.getvalue() if options['csv_output_type'] == str else csv


    @staticmethod
    def _json(options):
        '''
        creates a StringIO object or str containing json data
        '''

        if options['character_set'] is None:
            options['character_set'] = printable

        options['bool_nullable'] = options['json_bool_nullable']
        options['uuid_output_type'] = str
        options = Generator.filter_data_types(options, [
            Generator.Filters.jsonsafe,
            ])

        json = dumps(generate(
            options['json_initial_type'],
            {**options},
            ))

        return json if options['json_output_type'] == str else StringIO(json)


    @staticmethod
    def _yaml(options):
        '''
        creates a StringIO object or str containing yaml data
        '''
        if options['character_set'] is None:
            options['character_set'] = printable

        options['bool_nullable'] = options['yaml_bool_nullable']
        options['uuid_output_type'] = str
        options = Generator.filter_data_types(options, [
            Generator.Filters.yamlsafe,
            ])

        yaml = StringIO()
        safe_dump(
                generate(options['yaml_initial_type'], {**options}),
                yaml,
                default_flow_style=options['yaml_use_default_flow_style'],
                )
        yaml.seek(0)

        return yaml.getvalue() if options['yaml_output_type'] == str else yaml

    @staticmethod
    def _requests_Response(options):
        '''
        creates a requests.Response-like object containing json data
        '''

        options['json_output_type'] = str

        response = Response()
        response.status_code = options['requests_response_status_code']
        json = loads(generate('json', options))
        response.json = lambda: json

        return response
