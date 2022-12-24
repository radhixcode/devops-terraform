from .holiday_agency_exception import HolidayAgencyException

class BadRequestException(HolidayAgencyException):
    def __init__(self, exception):
        super().__init__("Bad request", exception)
