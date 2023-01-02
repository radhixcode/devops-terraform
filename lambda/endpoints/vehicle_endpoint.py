from endpoints.endpoint import Endpoint
from exceptions.bad_request_exception import BadRequestException
from exceptions.not_found_exception import NotFoundException
from controller.vehicle_controller import least_cost
from models.vehicle import Vehicle as models_Vehicle
from helpers.json_helpers import as_json

from helpers.log_utils import log_config
log = log_config("VehicleEndpoint")

class VehicleEndpoint(Endpoint):
    def __init__(self):
        super().__init__("vehicle", "/","{people}/{distance}")

    def get_single(self, event):
        try:
            number_of_people = int(event["pathParameters"]["people"])
        except:
            raise BadRequestException("No parameter {people} found in URL path")
        
        try:
            distance_to_travel = int(event["pathParameters"]["distance"])
        except:
            raise BadRequestException("No parameter {distance} found in URL path")

        log.debug("Finding vehicle with least cost...")
        try:
            vehicle_data = models_Vehicle.get_all()
            if not vehicle_data:
                raise NotFoundException("No vehicle found in the database")
            least_cost_vehicle = {}
            least_cost_vehicle = least_cost(vehicle_data, number_of_people, distance_to_travel)
            least_cost_vehicle['number_of_people'] = number_of_people
            least_cost_vehicle['distance'] = distance_to_travel
        except Exception as e:
            raise BadRequestException("Something's gone wrong calculating cost ", e)
        
        return 200, least_cost_vehicle
