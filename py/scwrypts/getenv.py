from os import getenv as os_getenv
from pathlib import Path
from subprocess import run

from py.scwrypts.exceptions import MissingVariableError


def getenv(name, required=True):
    value = os_getenv(name, None)

    if value == None:
        ZSH_COMMAND = Path(__file__).parents[2] / 'zsh/scwrypts/environment/stage-variables'

        run(
            f'{ZSH_COMMAND} {name}',
            shell=True,
            executable='/bin/zsh',
            )

        if required:
            raise MissingVariableError(name)

    return value
