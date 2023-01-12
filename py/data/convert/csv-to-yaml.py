#!/usr/bin/env python
from argparse import ArgumentParser

from py.lib.data.io import add_io_arguments
from py.lib.data.converter import convert

if __name__ != '__main__':
    raise Exception('executable only; must run through scwrypts')


parser = ArgumentParser(description = 'converts csv into yaml')
add_io_arguments(parser)

args = parser.parse_args()

convert(
        input_file  = args.input_file,
        input_type  = 'csv',
        output_file = args.output_file,
        output_type = 'yaml',
        )
