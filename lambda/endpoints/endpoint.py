from exceptions.not_implemented_exception import NotImplementedException
from functools import reduce

def remove_empties(elements, element):
    if element is None or element == "":
        return elements
    return elements + [element]

class Endpoint(object):
    def __init__(self, resource, prefix="/", param="{id}"):
        self.param = param
        self.resource = resource
        self.prefix = prefix
        self.parent_resources = reduce(remove_empties, prefix.split("/"), [])
        self.global_endpoint = prefix + resource
        self.single_endpoint = self.global_endpoint + "/" + param

    def handle(self, event):
        http_method = event['httpMethod']
        if http_method == "GET":
            return self.get(event)
        elif http_method == "POST":
            return self.post(event)
        elif http_method == "PUT":
            return self.put(event)
        elif http_method == "DELETE":
            return self.delete(event)
        else:
            raise NotImplementedException()

    # Get ####
    def get_global(self, event):
        raise NotImplementedException()
    def get_single(self, event):
        raise NotImplementedException()
    def get(self, event):
        if event.get('resource') == self.single_endpoint:
            return self.get_single(event)
        else:
            return self.get_global(event)

    # Post ####
    def post_global(self, event):
        raise NotImplementedException()
    def post_single(self, event):
        raise NotImplementedException()
    def post(self, event):
        if event.get('resource') == self.single_endpoint:
            return self.post_single(event)
        else:
            return self.post_global(event)

    # Put ####
    def put_global(self, event):
        raise NotImplementedException()
    def put_single(self, event):
        raise NotImplementedException()
    def put(self, event):
        if event.get('resource') == self.single_endpoint:
            return self.put_single(event)
        else:
            return self.put_global(event)


    # Delete ####
    def delete_global(self, event):
        raise NotImplementedException()
    def delete_single(self, event):
        raise NotImplementedException()
    def delete(self, event):
        if event.get('resource') == self.single_endpoint:
            return self.delete_single(event)
        else:
            return self.delete_global(event)