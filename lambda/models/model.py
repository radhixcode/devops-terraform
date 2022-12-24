from botocore.exceptions import ClientError
import boto3
from boto3.dynamodb.conditions import Key
import os
import re
import numbers
from helpers.json_helpers import decimal_to_number, ensure_not_float


from helpers.log_utils import log_config
log = log_config("Model")

try:
    DYNAMO_ENDPOINT = os.environ['DYNAMODB_ENDPOINT']
except:
    DYNAMO_ENDPOINT = None

dynamodb = None
if DYNAMO_ENDPOINT is None or DYNAMO_ENDPOINT == "":
    dynamodb = boto3.resource('dynamodb')
else:
    dynamodb = boto3.resource('dynamodb', endpoint_url=DYNAMO_ENDPOINT)


def find_all_attributes(cls):
    items = set(vars(cls).keys())
    for base in cls.__bases__:
        items = items.union(set(vars(base).keys()))
        items = items.union(find_all_attributes(base))
    return list(filter(lambda x: '__' not in x and not callable(getattr(cls, x)), items))

def camelCase_to_snake_case(text):
    return re.sub('([A-Z]+)', r'_\1', text[0].lower()+text[1:]).lower()

class Model(object):
    uuid = ""

    def __init__(self, obj):
        class_attributes = find_all_attributes(self.__class__)
        for key in obj:
            attribute = camelCase_to_snake_case(key)
            if attribute in class_attributes:
                if isinstance(obj[key], numbers.Number):
                    setattr(self, attribute, decimal_to_number(obj[key]))
                else:
                    setattr(self, attribute, obj[key])

    def as_json(self):
        return vars(self)

    def as_dynamo_doc(self):
        json = self.as_json()
        dynamo = {}
        for key in json:
            dynamo[key] = ensure_not_float(json[key])
        return dynamo

    @classmethod
    def get_table_name(cls):
        return camelCase_to_snake_case(cls.__name__)

    def save(self):
        table = dynamodb.Table(self.get_table_name())
        return table.put_item(Item=self.as_dynamo_doc())

    @classmethod
    def get(cls, key_value, key_name='id'):
        table = dynamodb.Table(cls.get_table_name())
        try:
            response = table.get_item(Key={key_name: key_value})
        except ClientError as e:
            log.exception(e)
            raise e
        else:
            return cls(response['Item'])

    @classmethod
    def get_all(cls):
        table = dynamodb.Table(cls.get_table_name())
        try:
            response = table.scan() # this only works up to 1mb but should be all right
        except ClientError as e:
            print(e.response['Error']['Message'])
            raise e
        else:
            return list(map(lambda x: cls(x), response['Items']))

    @classmethod
    def find_by(cls, key, value):
        table = dynamodb.Table(cls.get_table_name())
        try:
            response = table.query(
                KeyConditionExpression=Key(key).eq(value)
            )
        except ClientError as e:
            print(e.response['Error']['Message'])
            raise e
        else:
            return list(map(lambda x: cls(x), response['Items']))
