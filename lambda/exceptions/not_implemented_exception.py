from .holiday_agency_exception import HolidayAgencyException

class NotImplementedException(HolidayAgencyException):
    def __init__(self, exception):
        super().__init__("Not implemented", exception)
