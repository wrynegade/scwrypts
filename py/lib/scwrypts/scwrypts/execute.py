from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

from scwrypts.io import get_combined_stream, add_io_arguments


def execute(main, description=None, parse_args=None, allow_input=True, allow_output=True):
    '''
    API to initiate a python-based scwrypt
    '''
    if parse_args is None:
        parse_args = []

    parser = ArgumentParser(
            description = description,
            formatter_class = ArgumentDefaultsHelpFormatter,
            )

    add_io_arguments(parser, allow_input, allow_output)

    for a in parse_args:
        parser.add_argument(*a[0], **a[1])

    args = parser.parse_args()

    with get_combined_stream(args.input_file, args.output_file) as stream:
        return main(args, stream)
