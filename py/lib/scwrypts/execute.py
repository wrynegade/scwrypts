from argparse import ArgumentParser, ArgumentDefaultsHelpFormatter

from py.lib.scwrypts.io import get_combined_stream, add_io_arguments


def execute(main, description=None, parse_args=None, toggle_input=True, toggle_output=True):
    if parse_args is None:
        parse_args = []

    parser = ArgumentParser(
            description = description,
            formatter_class = ArgumentDefaultsHelpFormatter,
            )

    add_io_arguments(parser, toggle_input, toggle_output)

    for a in parse_args:
        parser.add_argument(*a[0], **a[1])

    args = parser.parse_args()

    with get_combined_stream(args.input_file, args.output_file) as stream:
        return main(args, stream)
