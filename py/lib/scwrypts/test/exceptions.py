class GeneratorError(Exception):
    pass

class NoDataTypeError(GeneratorError, ValueError):
    def __init__(self):
        super().__init__('must provide at least one data type (either "data_type" or "data_types")')

class BadGeneratorTypeError(GeneratorError, ValueError):
    def __init__(self, data_type):
        super().__init__(f'no generator exists for data type "{data_type}"')
