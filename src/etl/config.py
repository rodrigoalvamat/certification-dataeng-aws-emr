"""Defines a Config class to read the AWS EMR configuration from etl.cfg file."""

# sys libs
import os
# config libs
import configparser

# dwh.cfg file path
DIR = os.path.dirname(os.path.abspath(__file__))
INI_PATH = os.path.join(DIR, 'etl.cfg')


class Config:
    """This class defines a wrapper for ConfigParser.

    Use the etl.cfg file as a reference to configure
    the application according to your AWS account settings.

    Usage example:

    config = Config()
    config.get('S3', 'LANDING')
    """

    def __init__(self, local=False):
        """Creates a Config object from etl.cfg file.

        Config values will be UTF-8 encoded.

        Args:
            local: Defines if the data will be loaded and stored locally.
        """
        self.local = local
        self.parser = configparser.ConfigParser()
        self.parser.read_file(open(INI_PATH, encoding='utf-8'))

    def get(self, section, option):
        """Reads a config option value from a section.

        Retrieves an option value pertaining to the given section
        from the etl.cfg file.

        Args:
            section: The etl.cfg file section name.
              E.g. EMR
            option: The section config option name.
              E.g. CLUSTER_ID

        Returns:
            A value to the given section and option.
            For example:

            value = config.get('EMR', 'CLUSTER_ID')
        """
        if section == 'S3' and self.local:
            return os.path.join(DIR, self.parser.get('S3_LOCAL', option))
        return self.parser.get(section, option)
