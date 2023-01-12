from contextlib import contextmanager
from pathlib import Path
from sys import stdin, stdout, stderr

from py.lib.scwrypts.getenv import getenv


@contextmanager
def get_stream(filename=None, mode='r', encoding='utf-8', verbose=False, **kwargs):
    allowed_modes = {'r', 'w', 'w+'}

    if mode not in allowed_modes:
        raise ValueError(f'mode "{mode}" not supported modes (must be one of {allowed_modes})')

    is_read = mode == 'r'

    if filename is not None:

        if verbose:
            print(f'opening file {filename} for {"read" if is_read else "write"}', file=stderr)

        if filename[0] not in {'/', '~'}:
            filename = Path(f'{getenv("EXECUTION_DIR")}/{filename}').resolve()
        with open(filename, mode=mode, encoding=encoding, **kwargs) as stream:
            yield stream

    else:
        if verbose:
            print('using stdin for read' if is_read else 'using stdout for write', file=stderr)

        yield stdin if is_read else stdout


def add_io_arguments(parser, toggle_input=True, toggle_output=True):
    if toggle_input:
        parser.add_argument(
                '-i', '--input-file',
                dest     = 'input_file',
                default  = None,
                help     = 'path to input file; omit for stdin',
                required = False,
                )

    if toggle_output:
        parser.add_argument(
                '-o', '--output-file',
                dest     = 'output_file',
                default  = None,
                help     = 'path to output file; omit for stdout',
                required = False,
                )
