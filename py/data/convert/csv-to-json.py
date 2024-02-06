#!/usr/bin/env python
from scwrypts import execute
#####################################################################
from scwrypts.data import convert


description = 'convert csv into json'
parse_args = []

def main(_args, stream):
    return convert(
            input_stream = stream.input,
            input_type   = 'csv',
            output_stream = stream.output,
            output_type   = 'json',
            )

#####################################################################
if __name__ == '__main__':
    execute(main, description, parse_args)
