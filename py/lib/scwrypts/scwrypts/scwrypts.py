from os import getenv
from shutil import which
from subprocess import run

from .exceptions import MissingScwryptsExecutableError, BadScwryptsLookupError, MissingScwryptsGroupOrTypeError


def scwrypts(*args, patterns=None, name=None, group=None, _type=None, log_level=None):
    '''
    top-level scwrypts invoker from python

    - patterns allows for pattern-based scwrypt lookup
    - name/group/type allos for precise-match lookup

    *args should be a list of strings and is forwarded to the
    invoked scwrypt

    see 'scwrypts --help' for more information
    '''
    executable = which('scwrypts')
    if executable is None:
        raise MissingScwryptsExecutableError()

    if patterns is None and name is None:
        raise BadScwryptsLookupError()

    pre_args = []

    if name is None:
        pre_args += patterns
    else:
        pre_args += ['--name', name, '--group', group, '--type', _type]
        if group is None or _type is None:
            raise MissingScwryptsGroupOrTypeError(group, _type)

    if log_level is not None:
        pre_args += ['--log-level', log_level]

    depth = getenv('SUBSCWRYPT', '')
    if depth != '':
        depth = int(depth) + 1

    return run(
        f'SUBSCWRYPT={depth} {executable} {" ".join(pre_args)} -- {" ".join(args)}',
        shell=True,
        executable='/bin/zsh',
        check=False,
        )
