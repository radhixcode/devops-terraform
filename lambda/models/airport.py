from .model import Model

class Airport(Model):
    """
    Airport information
    """
    id = ""
    name = ""
    latitude = ""
    longitude = ""
    connections = []

    def as_json(self):
        """
        Converts this class to json
        """
        return {
            "id": self.id,
            "name": self.name,
            "latitude": self.latitude,
            "longitude": self.longitude,
            "connections": self.connections
        }
