from endpoints.endpoint import Endpoint
from models.airport import Airport as models_Airport
from exceptions.not_found_exception import NotFoundException
from helpers.json_helpers import as_json
import json

from helpers.log_utils import log_config
log = log_config("AirportEndpoint")

class AirportEndpoint(Endpoint):
    def __init__(self):
        super().__init__("airport")

    def get_global(self, event):
        log.debug("Getting all airports")
        return 200, as_json(models_Airport.get_all())

    def get_single(self, event):
        try:
            airport_id = event["pathParameters"]["id"]
        except Exception as e:
            try:
                raise NotFoundException("Unable to find an airport with id " + event["pathParameters"]["id"]) from e
            except:
                raise NotFoundException("Unable to find an airport with those parameters:" + str(event["pathParameters"])) from e
        log.debug(f"Getting single airport: {airport_id}")
        return 200, as_json(models_Airport.get(airport_id))

