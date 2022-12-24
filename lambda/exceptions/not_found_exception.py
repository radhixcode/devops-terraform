from .holiday_agency_exception import HolidayAgencyException

class NotFoundException(HolidayAgencyException):
    def __init__(self, message="Resource not found", exception=None):
        super().__init__(message, exception)
