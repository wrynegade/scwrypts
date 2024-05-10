from json import loads

from .scwrypts import scwrypts

from .scwrypts.exceptions import MissingVariableError

ENV = {}

def getenv(name, required=True, default=None):
    if ENV.get('configuration') is None or ENV.get('environment') is None:
        full_environment = loads(
                scwrypts(
                    name = 'scwrypts/environment/getenv',
                    group = 'scwrypts',
                    _type = 'zsh',
                    executable_args = '-n',
                    args = '--all',
                    ).stdout
                )

        ENV['configuration'] = full_environment['configuration']
        ENV['environment']   = full_environment['environment']

    value = ENV.get('environment', {}).get(name, default)

    if required and not value:
        raise MissingVariableError(name)

    if value == '':
        value = None

    return value
