import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def respond(http_code, body):
    return {
        'statusCode': http_code,
        'body': json.dumps(body),
        'headers': {"Access-Control-Allow-Origin": "*"},
        "isBase64Encoded": False
    }


def err(http_code, error, exception=""):
    try:
        message = ""
        original_exception = exception
        try:
            message = error.message
        except:
            message = error
        try:
            original_exception = error.original_exception
        except:
            pass
        return respond(http_code, {"error": message, "originalException":  str(original_exception)})
    except Exception as e:
        logger.exception(e)
        return respond(500, {"error": "This error was so bad, I couldn't even generate an error for it.", "originalException": str(e)})