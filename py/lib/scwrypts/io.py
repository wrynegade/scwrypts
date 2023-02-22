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

        if not is_read:
            stdout.flush()


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


@contextmanager
def get_combined_stream(input_file=None, output_file=None):
    with get_stream(input_file, 'r') as input_stream, get_stream(output_file, 'w+') as output_stream:
        yield CombinedStream(input_stream, output_stream)


class CombinedStream:
    def __init__(self, input_stream, output_stream):
        self.input = input_stream
        self.output = output_stream

    def read(self, *args, **kwargs):
        return self.input.read(*args, **kwargs)

    def readline(self, *args, **kwargs):
        return self.input.readline(*args, **kwargs)

    def readlines(self, *args, **kwargs):
        return self.input.readlines(*args, **kwargs)

    def write(self, *args, **kwargs):
        return self.output.write(*args, **kwargs)

    def writeline(self, line):
        x = self.output.write(f'{line}\n')
        self.output.flush()
        return x

    def writelines(self, *args, **kwargs):
        return self.output.writelines(*args, **kwargs)
