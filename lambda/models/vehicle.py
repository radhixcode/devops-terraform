from .model import Model

class Vehicle(Model):
    """
    Vehicle information
    """
    id = ""
    vehicle_type = ""
    rate_per_mile = ""
    people_count = ""
    parking_fee = ""

    def as_json(self):
        """
        Converts this class to json
        """
        return {
            "id": self.id,
            "vehicle_type": self.vehicle_type,
            "rate_per_mile": self.rate_per_mile,
            "people_count": self.people_count,
            "parking_fee": self.parking_fee
        }
