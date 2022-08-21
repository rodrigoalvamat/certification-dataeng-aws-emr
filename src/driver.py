"""At run time, this script looks for a given module, loads it,
and executes a 'main' function with given parameters.

Example: spark-submit --py-files package.whl \
         driver.py main_module [ARGS]
"""

# system libs
import sys
import argparse
import importlib


def run(main, local):
    """Executes the main module loaded."""
    module = importlib.import_module(main)
    sys.exit(module.run(local))


if __name__ == "__main__":
    """Sets the argument parser for the main.py script."""

    if len(sys.argv) == 1:
        raise SyntaxError("Please provide a module to load.")

    # create the command line parser
    parser = argparse.ArgumentParser(description='AWS EMR Spark Pipeline')

    main_message = 'The module where the run method to start the pipeline is declared.'
    local_message = 'Loads data from the local file system and sets Spark session to localhost - default: ASW EMR'

    # set the command line arguments
    parser.add_argument('main', help=main_message, default='main')
    parser.add_argument('-l', '--local', action='store_true',
                        help=local_message,
                        default=False)

    # parse the command line arguments
    args = parser.parse_args()

    # run the pipeline
    run(args.main, args.local)
