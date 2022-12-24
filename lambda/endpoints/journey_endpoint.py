from endpoints.endpoint import Endpoint
from models.airport import Airport as models_Airport
from exceptions.not_found_exception import NotFoundException
from exceptions.bad_request_exception import BadRequestException
from exceptions.holiday_agency_exception import HolidayAgencyException
from helpers.json_helpers import as_json
from graph.djikstra import makeGraph, shortest_distance
import json

from helpers.log_utils import log_config
log = log_config("JourneyEndpoint")

class JourneyEndpoint(Endpoint):
    def __init__(self):
        super().__init__("to", "/airport/{id}/", "{toId}")

    def get_single(self, event):
        try:
            origin_airport = event["pathParameters"]["id"]
        except:
            raise BadRequestException("No parameter {id} found in URL path")
        
        try:
            destination_airport = event["pathParameters"]["toId"]
        except:
            raise BadRequestException("No parameter {toId} found in URL path")

        log.debug("Creating a graph with all airports...")
        try:
            graph = makeGraph(models_Airport.get_all())
        except Exception as e:
            raise HolidayAgencyException("Something's gone wrong generating the graph :(", e) from e

        if origin_airport not in graph:
            raise NotFoundException(f"Origin airport '{origin_airport}' cannot be found")
        if destination_airport not in graph:
            raise NotFoundException(f"Destination airport '{destination_airport}' cannot be found")

        log.debug(f"Getting route from {origin_airport} to {destination_airport}")
        try:
            journey_info = shortest_distance(graph, origin_airport, destination_airport)
        except Exception as e:
            raise HolidayAgencyException("Something's gone wrong while calculating the journey :(", e) from e

        log.debug("Found a route!")
        return 200, {
            "journey": journey_info.nodes,
            "miles": journey_info.costs
        }

