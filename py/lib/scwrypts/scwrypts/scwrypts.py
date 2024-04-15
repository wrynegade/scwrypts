from os import getenv
from shutil import which
from subprocess import run

from .exceptions import MissingScwryptsExecutableError, BadScwryptsLookupError, MissingScwryptsGroupOrTypeError


def scwrypts(patterns=None, args=None, executable_args=None, name=None, group=None, _type=None):
    '''
    top-level scwrypts invoker from python

        patterns          str / list   pattern-based scwrypt lookup
        args              str / list   arguments forwarded to the invoked scwrypt
        executable_args   str / list   arguments for the 'scwrypts' executable
          (str above assumes space-delimited values)

        name    str   exact scwrypt lookup name (requires group and _type)
        group   str   exact scwrypt lookup group
        _type   str   exact scwrypt lookup type

        SCWRYPTS_EXECUTABLE   configuration variable which defines the full path to scwrypts executable

    see 'scwrypts --help' for more information
    '''
    if patterns is None and name is None:
        raise BadScwryptsLookupError()

    if name is not None and (group is None or _type is None):
        raise MissingScwryptsGroupOrTypeError(group, _type)

    executable = which(getenv('SCWRYPTS_EXECUTABLE', 'scwrypts'))

    if executable is None:
        raise MissingScwryptsExecutableError()

    lookup = _parse(patterns) if name is None else f'--name {name} --group {group} --type {_type}'

    depth = getenv('SUBSCWRYPT', '')
    if depth != '':
        depth = int(depth) + 1

    return run(
        f'SUBSCWRYPT={depth} {executable} {_parse(executable_args)} {lookup} -- {_parse(args)}',
        shell=True,
        executable='/bin/zsh',
        check=False,
        capture_output=True,
        text=True,
        )

def _parse(string_or_list_args):
    if string_or_list_args is None:
        return ''

    if isinstance(string_or_list_args, list):
        return ' '.join(string_or_list_args)

    return str(string_or_list_args)
