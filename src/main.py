"""Defines the ETLPipeline main entry point."""

# config libs
from etl.config import Config
# pipeline libs
from etl.pipeline import ETLPipeline


def run(local):
    """The main.py script entry point to run the ETLPipeline.

    Args:
        local: If True uses the AWS EMR and S3 configurations,
            otherwise uses the local file system and the localhost
            Spark session.
    """
    # sets the session host
    config = Config(local=local)

    # run the pipeline
    pipeline = ETLPipeline(config)
    pipeline.start()
    pipeline.stop()
