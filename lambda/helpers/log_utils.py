import os
import logging

def log_config(module="generic"):
    log_level = {
        'debug': logging.DEBUG,
        'info': logging.INFO,
        'warn': logging.WARN,
        'error': logging.ERROR,
    }
    logger = logging.getLogger(f'holiday-agency-{module}')
    logging.basicConfig()
    log_level_option = os.environ.get('LOG_LEVEL', 'warn').lower()
    try:
        logger.setLevel(log_level[log_level_option])
    except:
        logger.setLevel(log_level["warn"])
    return logger
