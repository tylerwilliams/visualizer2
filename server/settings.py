import os
import logging
import ConfigParser

DEFAULT_CONFIG_FILE_PATH = "/etc/visualizer.conf"
CONFIG_FILE_SECTION_NAME = "visualizer"

logger = logging.getLogger("visualizer")

"""
These settings can be overridden with a config file at
CONFIG_FILE_PATH. Here's an example of a config file:

file: /etc/visualizer.conf
############################################################
[visualizer]
memcache_hosts = cache0.sandpit.us:11211,cache1.sandpit.us:11211,cache2.sandpit.us:11211
logging_level = debug # one of: DEBUG, INFO, WARNING, ERROR, CRITICAL, case does not matter
############################################################
"""

def load_config(config_path):
    logger.info("using config from %s", config_path)
    config = ConfigParser.SafeConfigParser()
    config.read(config_path)
    return dict(config.items(CONFIG_FILE_SECTION_NAME))

def get_settings(config_path):
    if not config_path:
        config_path = DEFAULT_CONFIG_FILE_PATH
    if not os.path.exists(config_path):
        raise Exception("no settings files found!")
    return load_config(config_path)
