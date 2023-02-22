from argparse import ArgumentError


class MissingVariableError(EnvironmentError):
    def init(self, name):
        super().__init__(f'Missing required environment variable "{name}"')


class ImportedExecutableError(ImportError):
    def __init__(self):
        super().__init__('executable only; must run through scwrypts')


class MissingFlagAndEnvironmentVariableError(EnvironmentError, ArgumentError):
    def __init__(self, flags, env_var):
        super().__init__(f'must provide at least one of : {{ flags: {flags} OR {env_var} }}')
