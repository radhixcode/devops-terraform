#!/bin/bash

function put_airport() {
    connections=$(echo "$5" | jq -c '.[] | {"M": {"id":{"S": .id}, "miles":{"N": .miles|tostring}} }' | tr '\n', ',' | rev | cut -c2- | rev )
    json="{\"id\": {\"S\": \"$1\"}, \"name\": {\"S\": \"$2\"}, \"latitude\": {\"S\": \"$3\"}, \"longitude\": {\"S\": \"$4\"}, \"connections\": {\"L\": [$connections]}}"
    echo "${json}"
    aws dynamodb put-item \
        --table-name airport  \
        --item "$json" \
        --endpoint-url http://localhost:8000
}

aws dynamodb delete-table \
    --table-name airport \
    --endpoint-url http://localhost:8000

aws dynamodb create-table \
    --table-name airport \
    --attribute-definitions \
        AttributeName=id,AttributeType=S \
    --key-schema \
        AttributeName=id,KeyType=HASH \
    --provisioned-throughput \
        ReadCapacityUnits=10,WriteCapacityUnits=5 \
    --endpoint-url http://localhost:8000

put_airport "IST" "Istanbul Airport" "41.262222" "28.727778" '[{"id":"ATH", "miles": 100}, {"id":"AMS", "miles": 1200}, {"id":"SVO", "miles": 800}, {"id":"VIE", "miles": 750}]'
put_airport "CDG" "Charles de Gaulle Airport" "49.009722" "2.547778" '[{"id":"ORY", "miles": 10}, {"id":"LHR", "miles": 100}, {"id":"AMS", "miles": 120}, {"id":"FRA", "miles": 130}, {"id":"ZRH", "miles": 120}, {"id":"FCO", "miles": 500}, {"id":"LIS", "miles": 750}, {"id":"MAD", "miles": 600}]'
put_airport "LHR" "Heathrow Airport" "51.4775" "-0.461389" '[{"id":"LGW", "miles": 10}, {"id":"CDG", "miles": 50}, {"id":"AMS", "miles": 100}, {"id":"FRA", "miles": 230}, {"id":"MAD", "miles": 500}, {"id":"LIS", "miles": 350}]'
put_airport "AMS" "Schiphol Airport" "52.308056" "4.764167" '[{"id":"LHR", "miles": 100}, {"id":"FRA", "miles": 90}, {"id":"CDG", "miles": 110}, {"id":"OSL", "miles": 500}]'
put_airport "SVO" "Sheremetyevo International Airport" "55.972778" "37.414722" '[{"id":"VKO", "miles": 10}, {"id":"DME", "miles": 15}, {"id":"LED", "miles": 200}, {"id":"ATH", "miles": 1300}]'
put_airport "FRA" "Frankfurt Airport" "50.033333" "8.570556" '[{"id":"VIE", "miles": 300}, {"id":"MUC", "miles": 90}, {"id":"ZRH", "miles": 100}, {"id":"CDG", "miles": 105}, {"id":"LHR", "miles": 120}, {"id":"AMS", "miles": 100}, {"id":"DME", "miles": 1500}]'
put_airport "MAD" "Adolfo Suárez Madrid-Barajas Airport" "40.472222" "-3.560833" '[{"id":"LIS", "miles": 145}, {"id":"FCO", "miles": 220}, {"id":"LHR", "miles": 500}, {"id":"BCN", "miles": 120}]'
put_airport "DME" "Moscow Domodedovo Airport" "55.408611" "37.906111" '[{"id":"ATH", "miles": 1105}, {"id":"OSL", "miles": 980}, {"id":"VKO", "miles": 15}, {"id":"SVO", "miles": 20}, {"id":"LED", "miles": 210}, {"id":"ATH", "miles": 1000}]'
put_airport "BCN" "Josep Tarradellas Barcelona-El Prat Airport" "41.296944" "2.078333" '[{"id":"MAD", "miles": 50}, {"id":"FCO", "miles": 140}]'
put_airport "VKO" "Vnukovo International Airport" "55.596111" "37.2675" '[{"id":"SVO", "miles": 5}, {"id":"DME", "miles": 8}]'
put_airport "MUC" "Munich Airport" "48.353889" "11.786111" '[{"id":"VIE", "miles": 90}, {"id":"ZRH", "miles": 80}, {"id":"FRA", "miles": 100}, {"id":"FCO", "miles": 200}]'
put_airport "LED" "Pulkovo Airport" "59.800278" "30.2625" '[{"id":"VKO", "miles": 190}, {"id":"SVO", "miles": 170}, {"id":"OSL", "miles": 300}, {"id":"LIS", "miles": 2500}]'
put_airport "ORY" "Orly Airport" "48.723333" "2.379444" '[{"id":"CDG", "miles": 5}, {"id":"AMS", "miles": 150}]'
put_airport "LGW" "Gatwick Airport" "51.148056" "-0.190278" '[{"id":"LHR", "miles": 10}, {"id":"ORY", "miles": 125}]'
put_airport "FCO" "Leonardo da Vinci-Fiumicino Airport" "41.800278" "12.238889" '[{"id":"ATH", "miles": 200}, {"id":"BCN", "miles": 190}, {"id":"IST", "miles": 310}, {"id":"AMS", "miles": 495}]'
put_airport "LIS" "Lisbon Airport" "38.774167" "-9.134167" '[{"id":"MAD", "miles": 100}, {"id":"BCN", "miles": 300}, {"id":"LHR", "miles": 300}, {"id":"SVO", "miles": 2100}]'
put_airport "OSL" "Oslo Airport, Gardermoen" "60.202778" "11.083889" '[{"id":"LED", "miles": 320}, {"id":"LHR", "miles": 390}, {"id":"FRA", "miles": 720}, {"id":"AMS", "miles": 690}, {"id":"VKO", "miles": 980}]'
put_airport "ZRH" "Zurich Airport" "47.464722" "8.549167" '[{"id":"FCO", "miles": 150}, {"id":"MUC", "miles": 85}, {"id":"VIE", "miles": 190}, {"id":"FRA", "miles": 100}, {"id":"CDG", "miles": 180}, {"id":"AMS", "miles": 310}]'
put_airport "ATH" "Athens International Airport" "37.936389" "23.947222" '[{"id":"IST", "miles": 150}, {"id":"FCO", "miles": 200}, {"id":"MAD", "miles": 500}]'
put_airport "VIE" "Vienna International Airport" "48.110833" "16.570833" '[{"id":"IST", "miles": 350}, {"id":"VKO", "miles": 890}, {"id":"OSL", "miles": 880}, {"id":"MUC", "miles": 95}, {"id":"FCO", "miles": 200}]'