from os import getenv as os_getenv

from py.scwrypts.exceptions import MissingVariableError
from py.scwrypts.run import run


def getenv(name, required=True):
    value = os_getenv(name, None)

    if value == None:
        run('zsh/scwrypts/environment/stage-variables', name)

    if required and not value:
        raise MissingVariableError(name)

    return value
