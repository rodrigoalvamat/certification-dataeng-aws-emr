"""Defines a utility function to read the EMR configuration from emr.cfg file.

Check the emr.cfg.template file configuration sections and options.
"""
# sys libs
import os
# config libs
import configparser

# Sets emr.cfg file path
DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(DIR, '../../', 'emr.cfg')

# Initializes config parser
PARSER = configparser.ConfigParser()
PARSER.read_file(open(CONFIG_PATH, encoding='utf-8'))


def get(section, option):
    """Reads a config option value from a section.

    Retrieves an option value pertaining to the given section
    from the dwh.cfg file.

    Args:
        section: The emr.cfg file section name.
          E.g. REDSHIFT
        option: The section config option name.
          E.g. PORT

    Returns:
        A value to the given section and option.
        For example:

        value = config.get('REDSHIFT', 'PORT')
    """
    return PARSER.get(section, option)
