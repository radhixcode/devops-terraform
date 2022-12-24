from endpoints.airport_endpoint import AirportEndpoint
from endpoints.journey_endpoint import JourneyEndpoint
from exceptions.not_implemented_exception import NotImplementedException
from exceptions.not_found_exception import NotFoundException
from exceptions.bad_request_exception import BadRequestException
from helpers.response_helpers import *
import traceback
from http.server import *
import logging

MAPPINGS = {
    "/airport": AirportEndpoint,
    "/airport/{id}": AirportEndpoint,
    "/airport/{id}/to/{toId}": JourneyEndpoint
}


def lambda_handler(event, context=None):
    print(event)
    resource = event.get('resource')
    try:
        if resource not in MAPPINGS:
            raise NotImplementedException(traceback.format_exc())
        print("doing " + resource)
        endpoint = MAPPINGS[resource]()
        return respond(*endpoint.handle(event))
    except BadRequestException as e:
        return err(400, e, traceback.format_exc())
    except NotFoundException as e:
        return err(404, e, traceback.format_exc())
    except NotImplementedException as e:
        return err(501, e, traceback.format_exc())
    except Exception as e:
        exception = traceback.format_exc()
        logger.error(exception, exc_info=True)
        return err(500, "An unexpected error has occurred", exception)


def to_multi_value_params(path):
    try:
        d = {}
        tuples = map(lambda x: tuple(x.split("=")), path.split("?")[1].split("&"))
        for pair in tuples:
            if pair[0] not in d:
                d[pair[0]] = []
            d[pair[0]] = d[pair[0]] + [pair[1]]
        return d
    except:
        return {}


def to_single_value_params(path):
    try:
        return dict(map(lambda x: tuple(x.split("=")), path.split("?")[1].split("&")))
    except:
        return {}


def path_to_path_info(path):
    if "/bulk/" in path:
        return {
        "resource": path,
        "params": {},
        "path": path
    }
    splitPaths = path.split("?")[0].strip("/").split("/")
    resource = []
    params = {}
    for i, path in enumerate(splitPaths):
        if i % 2 != 0:
            param_name = "id"
            if i != 1:
                param_name = resource[-1] + "Id"
            resource.append("{" + param_name + "}")
            params[param_name] = path
        else:
            resource.append(path)
    return {
        "resource": "/" + "/".join(resource),
        "params": params,
        "path": path
    }

def to_api_gateway_request(path, method, body=None):
    path_info = path_to_path_info(path)
    return {
        "resource": path_info["resource"],
        "path": path,
        "httpMethod": method,
        "queryStringParameters": to_single_value_params(path),
        "multiValueQueryStringParameters": to_multi_value_params(path),
        "pathParameters": path_info["params"],
        "stageVariables": None,
        "body": body,
        "isBase64Encoded": False
    }


class HandlerClass(BaseHTTPRequestHandler):
    def _set_response(self, response):
        self.send_response(response["statusCode"])
        self.send_header('Content-type', 'application/json')
        for header in response["headers"]:
            self.send_header(header, response["headers"][header])
        self.end_headers()

    def aws(self, method, body=None):
        event = to_api_gateway_request(str(self.path), method, body)
        print("-----------")
        print(event)
        print("-----------")
        resp = lambda_handler(event)
        self._set_response(resp)
        self.wfile.write(resp["body"].encode(encoding='utf_8'))

    def process_with_body(self, method):
        content_length = int(self.headers['Content-Length'])  # <--- Gets the size of data
        data = self.rfile.read(content_length)  # <--- Gets the data itself
        logging.info(method + " request,\nPath: %s\nHeaders:\n%s\n\nBody:\n%s\n",
                     str(self.path), str(self.headers), data.decode('utf-8'))
        self.aws(method, data.decode('utf-8'))

    def do_GET(self):
        logging.info("\n  GET request\n  Path: %s \n", str(self.path))
        self.aws("GET")

    def do_POST(self):
        self.process_with_body("POST")
    
    def do_PUT(self):
        self.process_with_body("PUT")
    
    def do_DELETE(self):
        self.process_with_body("DELETE")


def run(server_class=HTTPServer, handler_class=HandlerClass):
    server_address = ('', 8080)
    httpd = server_class(server_address, handler_class)
    print("Listening on http://localhost:8080/")
    httpd.serve_forever()

run()