import traceback

class HolidayAgencyException(Exception):
    def __init__(self, message, original_exception):
        self.message = message
        if original_exception is None:
            self.original_exception = traceback.format_exc()
        else:
            self.original_exception = original_exception
        super().__init__(self.message)
