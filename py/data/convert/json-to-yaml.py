#!/usr/bin/env python
from py.lib.data.converter import convert
from py.lib.scwrypts import execute

from py.lib.scwrypts.exceptions import ImportedExecutableError

if __name__ != '__main__':
    raise ImportedExecutableError()

#####################################################################

def main(_args, stream):
    return convert(
            input_stream = stream.input,
            input_type   = 'json',
            output_stream = stream.output,
            output_type   = 'yaml',
            )

#####################################################################
execute(main,
        description = 'convert json into yaml',
        parse_args = [],
        )
