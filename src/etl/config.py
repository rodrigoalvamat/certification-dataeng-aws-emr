"""Defines a Config class to read the AWS EMR configuration from etl.cfg file."""

# sys libs
import os
# config libs
import configparser
import zipfile

SCRIPT_NAME = os.path.basename(__file__)
"""The python script file name."""
SCRIPT_PATH = os.path.abspath(__file__)
"""The python script absolute file path."""
SCRIPT_DIR = SCRIPT_PATH.replace(f'/{SCRIPT_NAME}', '')
"""The python script directory path."""

PACKAGE_DIR = 'etl'
"""The python package name."""
PACKAGE_PATH = SCRIPT_PATH.replace(f'/{PACKAGE_DIR}/{SCRIPT_NAME}', '')
"""The python package path."""

CONFIG_NAME = 'etl.cfg'
"""The config file name."""
CONFIG_EMR_PATH = SCRIPT_PATH.replace(SCRIPT_NAME, CONFIG_NAME)
"""The config file absolute path in the AWS EMR environment."""
CONFIG_LOCAL_PATH = os.path.join(SCRIPT_DIR, CONFIG_NAME)
"""The config file absolute path in the local environment."""


class Config:
    """This class defines a wrapper for ConfigParser.

    Use the etl.cfg file as a reference to configure
    the application according to your AWS account settings.

    Usage example:

    config = Config()
    config.get('S3', 'LANDING')
    """

    def __init__(self, local=False):
        """Creates a Config object from pipeline.cfg file.

        Config values will be UTF-8 encoded.

        Args:
            local: Defines if the data will be loaded and stored locally.
        """
        self.local = local
        self._init_parser()

    def _init_parser(self):
        """Initializes the config parser from a cfg file."""
        self.parser = configparser.ConfigParser()

        if self.local:
            self.parser.read_file(open(CONFIG_LOCAL_PATH, encoding='utf-8'))
        else:
            self.parser.read_string(self._unzip_config())

    @staticmethod
    def _unzip_config():
        """Reads the config cfg file from the archive package."""
        with zipfile.ZipFile(PACKAGE_PATH, 'r') as zip_ref:
            config = zip_ref.read(f'{PACKAGE_DIR}/{CONFIG_NAME}')
            return config.decode('UTF-8')

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
            return os.path.join(SCRIPT_DIR, self.parser.get('S3_LOCAL', option))
        return self.parser.get(section, option)
