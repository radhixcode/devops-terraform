import numbers
from decimal import Decimal

def as_json(arg):
    return decimal_to_number(_as_json(arg))

def _as_json(arg):
    if isinstance(arg, list):
        return list(map(_as_json, arg))
    if arg is not None:
        try:
            return arg.as_json()
        except Exception as e:
            return str(arg)
    return None



def decimal_to_number(number):
    if type(number) is dict:
        no_float_dict = {}
        for key in number:
            no_float_dict[key] = decimal_to_number(number[key])
        return no_float_dict
    if type(number) is list:
        no_float_list = []
        for element in number:
            no_float_list.append(decimal_to_number(element))
        return no_float_list
    if type(number) is str:
        return number

    as_float = float(number)
    as_int = int(number)
    if as_float == float(as_int):
        return as_int
    return as_float

def ensure_not_float(number):
    if type(number) is dict:
        no_float_dict = {}
        for key in number:
            no_float_dict[key] = ensure_not_float(number[key])
        return no_float_dict
    if type(number) is list:
        no_float_list = []
        for element in number:
            no_float_list.append(ensure_not_float(element))
        return no_float_list
    if type(number) is str:
        return number

    try:
        float(number)
    except:
        return number # in case it's some other type

    as_decimal = Decimal(str(number))
    as_int = int(number)
    if as_decimal == Decimal(str(as_int)):
        return as_int
    return as_decimal