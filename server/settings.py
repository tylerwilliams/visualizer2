import os
import logging
import ConfigParser

LOCAL_CONFIG_FILE_PATH = "visualizer.conf"
CONFIG_FILE_PATH = "/etc/visualizer.conf"
CONFIG_FILE_SECTION_NAME = "visualizer"

logger = logging.getLogger("visualizer")
_settings = {
}

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
    _settings.update(dict(config.items(CONFIG_FILE_SECTION_NAME)))

if os.path.exists(LOCAL_CONFIG_FILE_PATH):
    load_config(LOCAL_CONFIG_FILE_PATH)
elif os.path.exists(CONFIG_FILE_PATH):
    load_config(CONFIG_FILE_PATH)
else:
    logger.warning("no settings files found!")

def get_settings():
    return _settings
