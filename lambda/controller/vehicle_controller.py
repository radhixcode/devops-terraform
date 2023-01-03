import math

def least_cost(vehicles, number_of_people, distance_to_travel):
    vehicle_cost = []
    for vehicle in vehicles:
        num_transport = math.ceil(number_of_people/vehicle.people_count)
        transport_cost = num_transport * \
            ((distance_to_travel * vehicle.rate_per_mile) + vehicle.parking_fee)
        vehicle_cost.append({
            "vehicle": vehicle.vehicle_type,
            "cost": transport_cost,
            "vehicle_count": num_transport if vehicle.vehicle_type != 'flight' else 1
        })

    print(">>> vehicles and cost <<< ")
    print(vehicle_cost)
    print("__________________________")

    return min(vehicle_cost, key=lambda x: x['cost'])
