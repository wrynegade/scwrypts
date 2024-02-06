from os import getenv as os_getenv

from .scwrypts.exceptions import MissingVariableError


def getenv(name, required=True):
    value = os_getenv(name, None)

    if required and not value:
        raise MissingVariableError(name)

    if value == '':
        value = None

    return value
