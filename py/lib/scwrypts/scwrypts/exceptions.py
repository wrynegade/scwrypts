from argparse import ArgumentError


class MissingVariableError(EnvironmentError):
    def init(self, name):
        super().__init__(f'Missing required environment variable "{name}"')


class MissingFlagAndEnvironmentVariableError(EnvironmentError, ArgumentError):
    def __init__(self, flags, env_var):
        super().__init__(f'must provide at least one of : {{ flags: {flags} OR {env_var} }}')


class MissingScwryptsExecutableError(EnvironmentError):
    def __init__(self):
        super().__init__(f'scwrypts must be installed and available on your PATH')


class BadScwryptsLookupError(ValueError):
    def __init__(self):
        super().__init__('must provide name/group/type or scwrypt lookup patterns')


class MissingScwryptsGroupOrTypeError(ValueError):
    def __init__(self, group, _type):
        super().__init__(f'missing required group or type (group={group} | type={_type}')
