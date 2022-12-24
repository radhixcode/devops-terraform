from endpoints.{{RESOURCE_FILE}}_endpoint import {{RESOURCE}}Endpoint
from exceptions.not_implemented_exception import NotImplementedException
from exceptions.not_found_exception import NotFoundException
from exceptions.bad_request_exception import BadRequestException
from helpers.response_helpers import *
import traceback

logger = logging.getLogger()
logger.setLevel(logging.ERROR)

def lambda_handler(event, context):
    endpoint = {{RESOURCE}}Endpoint()
    try:
        return respond(*endpoint.handle(event))
    except BadRequestException as e:
        return err(400, e)
    except NotFoundException as e:
        return err(404, e)
    except NotImplementedException as e:
        return err(501, e)
    except Exception as e:
        exception = traceback.format_exc()
        logger.error(exception, exc_info=True)
        return err(500, "An unexpected error has occurred", exception)
