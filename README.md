# Setup
### Run on local machine
* Install pip3 and install needed dependency packages 
```
pip3 install botocore boto3 dijkstar
```
* Install docker and run docker command to install dynamoDB locally then run the container before running the bash script.
```
docker run -p 8000:8000 amazon/dynamodb-local  
```
* Run bash script `create-local-db.sh` to create the dynamoDB tables `airport` and `vehicle` and populate them
```
./create-local-db.sh
```
* Check dynamoDB tables
```
aws dynamodb list-tables --endpoint-url http://localhost:8000
aws dynamodb describe-table --table-name airport --endpoint-url http://localhost:8000
```
* Inside lambda folder run bash script `run.sh` to run the lambda
```
./run.sh
```
* Example endpoints
    * [http://localhost:8080/airport](http://localhost:8080/airport)
    * [http://localhost:8080/airport/AMS](http://localhost:8080/airport/AMS)
    * [http://localhost:8080/airport/AMS/to/LIS](http://localhost:8080/airport/AMS/to/LIS)
    * [http://localhost:8080/vehicle/2/100](http://localhost:8080/vehicle/2/100)

### Terraform with AWS
* Install openapi-merger for combining OpenAPI specifications (Inside `openapi` folder)
```
npm install openapi-merger -g 
openapi-merger -i main.yaml -o deploy-api.yaml
```
* Install Terraform with brew
```
brew tap hashicorp/tap
brew install hashicorp/tap/terraform
```
* Terraform commands. Run inside `terraform` folder
```
terraform init (initializes the current directory)
terraform init -upgrade (upgrade to latest acceptable provider version)
terraform validate (command validates the configuration files in a directory)
terraform fmt (format your configuration files into a canonical format and style)
terraform plan (dry run to see what Terraform will do)
terraform refresh (refreshes the state file)
terraform output (views Terraform outputs)
terraform apply (applies the Terraform code and builds stuff)
terraform graph (creates a DOT-formatted graph)
terraform destroy --target aws_lambda_function.lambda (destroys indivifual resource)
terraform destroy  (destroys what has been built by Terraform)
```
* Populate AWS DynamoDB after `terraform apply`
```
./update-db.sh
```
* AWS lambda sample test JSON
```
{
  "resource": "/vehicle/{people}/{distance}",
  "path": "/vehicle/2/100",
  "httpMethod": "GET",
  "queryStringParameters": {},
  "multiValueQueryStringParameters": {},
  "pathParameters": {
    "people": "2",
    "distance": "100"
  },
  "stageVariables": "None",
  "body": "None",
  "isBase64Encoded": "FALSE"
}
```

### Github actions
* .github/workflow/terraform.yaml is the workflow file
* Create new IAM user for github actions and get the credentials.
* Add new New repository secrets  (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `BUCKET_TF_STATE`) in Actions secrets of the Github repository.

### Current Shortcomings
* **Github actions:** Can do terraform apply locally for the AWS but github action terrafom apply didn't trigger on merge/push to the main branch.
* **API gateway:** Manual steps involved.<br />
AWS Labmda is working (tested with above sample JSON). But to test API gateway Method execution, Integration Request function name needed to be manually updated for each GET.

![Img 1](https://i.imgur.com/CxsMIZw.png)
![Img 2](https://i.imgur.com/oArVAxI.png)

Execute the 'Deploy API' button for the root resource ('/') from the AWS API gateway console.

![Img 3](https://i.imgur.com/vs1JcJV.png)

* **Public URL:** The public URL throws `Internal server error` or `Endpoint request timed out` for some time and then it works (Need `x-api-key` which we can get this from Amazon API gateway -> API keys)
```
curl --location --request GET 'https://8v5w5mv4ze.execute-api.us-east-1.amazonaws.com/holiday-stage/vehicle/2/100' \
--header 'Content-Type: application/json' \
--header 'x-api-key: <x-api-key here>'
```
![Img 3](https://i.imgur.com/kNcLopl.png)

### Reference
* Github actions
    * [Managing Terraform with GitHub Actions](https://spacelift.io/blog/github-actions-terraform)
    * [How to use GitHub Actions to automate Terraform](https://acloudguru.com/blog/engineering/how-to-use-github-actions-to-automate-terraform)
* Terraform
    * [Openapi tf example](https://github.com/rpstreef/openapi-tf-example/blob/master/services/api/example.yml)
    * [aws api-gateway sample](https://github.com/aws-samples/api-gateway-secure-pet-store/blob/master/src/main/resources/swagger.yaml)
    * [cliffdias/HelloworldAPI](https://github.com/cliffdias/HelloworldAPI)


<div align="center"><img src="./logo.jpg" alt="Logo" width="80" height="80"></div>
<h1 align="center" style="color:tomato;">Holiday Agency</h1>

# Overview
A holiday agency would like to suggest the lowest travel cost for holiday journeys to their customers.  
A return journey consists of the following parts:

1. Journey to the airport:
    * **Taxi**: £0.40/mile - (allows up to 4 people per taxi - e.g. require 2 taxis if 5 people travel together)
    * **Car**: £0.20/mile - (allows up to 4 people per car), additional £3 parking fee

2. An outbound and an inbound flight journey:
    * **Flight**: £0.10/passenger/mile

This flight agency keeps a table with its airports and their connections:

| Airport ID | Airport Name                                | Latitude  | Longitude | Connections and distance                                                                                           |
| ---------- | ------------------------------------------- | --------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| IST        | Istanbul Airport                            | 41.262222 | 28.727778 | ATH: 100mi<br/>AMS: 1200mi<br/>SVO: 800mi<br/>VIE: 750mi                                                           |
| CDG        | Charles de Gaulle Airport                   | 49.009722 | 2.547778  | ORY: 10mi<br/>LHR: 100mi<br/>AMS: 120mi<br/>FRA: 130mi<br/>ZRH: 120mi<br/>FCO: 500mi<br/>LIS: 750mi<br/>MAD: 600mi |
| LHR        | Heathrow Airport                            | 51.4775   | -0.461389 | LGW: 10mi<br/>CDG: 50mi<br/>AMS: 100mi<br/>FRA: 230mi<br/>MAD: 500mi<br/>LIS: 350mi                                |
| AMS        | Schiphol Airport                            | 52.308056 | 4.764167  | LHR: 100mi<br/>FRA: 90mi<br/>CDG: 110mi<br/>OSL: 500mi                                                             |
| SVO        | Sheremetyevo International Airport          | 55.972778 | 37.414722 | VKO: 10mi<br/>DME: 15mi<br/>LED: 200mi<br/>ATH: 1300mi                                                             |
| FRA        | Frankfurt Airport                           | 50.033333 | 8.570556  | VIE: 300mi<br/>MUC: 90mi<br/>ZRH: 100mi<br/>CDG: 105mi<br/>LHR: 120mi<br/>AMS: 100mi<br/>DME: 1500mi               |
| MAD        | Adolfo Suárez Madrid-Barajas Airport        | 40.472222 | -3.560833 | LIS: 145mi<br/>FCO: 220mi<br/>LHR: 500mi<br/>BCN: 120mi                                                            |
| DME        | Moscow Domodedovo Airport                   | 55.408611 | 37.906111 | ATH: 1105mi<br/>OSL: 980mi<br/>VKO: 15mi<br/>SVO: 20mi<br/>LED: 210mi<br/>ATH: 1000mi                              |
| BCN        | Josep Tarradellas Barcelona-El Prat Airport | 41.296944 | 2.078333  | MAD: 50mi<br/>FCO: 140mi                                                                                           |
| VKO        | Vnukovo International Airport               | 55.596111 | 37.2675   | SVO: 5mi<br/>DME: 8mi                                                                                              |
| MUC        | Munich Airport                              | 48.353889 | 11.786111 | VIE: 90mi<br/>ZRH: 80mi<br/>FRA: 100mi<br/>FCO: 200mi                                                              |
| LED        | Pulkovo Airport                             | 59.800278 | 30.2625   | VKO: 190mi<br/>SVO: 170mi<br/>OSL: 300mi<br/>LIS: 2500mi                                                           |
| ORY        | Orly Airport                                | 48.723333 | 2.379444  | CDG: 5mi<br/>AMS: 150mi                                                                                            |
| LGW        | Gatwick Airport                             | 51.148056 | -0.190278 | LHR: 10mi<br/>ORY: 125mi                                                                                           |
| FCO        | Leonardo da Vinci-Fiumicino Airport         | 41.800278 | 12.238889 | ATH: 200mi<br/>BCN: 190mi<br/>IST: 310mi<br/>AMS: 495mi                                                            |
| LIS        | Lisbon Airport                              | 38.774167 | -9.134167 | MAD: 100mi<br/>BCN: 300mi<br/>LHR: 300mi<br/>SVO: 2100mi                                                           |
| OSL        | Oslo Airport - Gardermoen                   | 60.202778 | 11.083889 | LED: 320mi<br/>LHR: 390mi<br/>FRA: 720mi<br/>AMS: 690mi<br/>VKO: 980mi                                             |
| ZRH        | Zurich Airport                              | 47.464722 | 8.549167  | FCO: 150mi<br/>MUC: 85mi<br/>VIE: 190mi<br/>FRA: 100mi<br/>CDG: 180mi<br/>AMS: 310mi                               |
| ATH        | Athens International Airport                | 37.936389 | 23.947222 | IST: 150mi<br/>FCO: 200mi<br/>MAD: 500mi                                                                           |
| VIE        | Vienna International Airport                | 48.110833 | 16.570833 | IST: 350mi<br/>VKO: 890mi<br/>OSL: 880mi<br/>MUC: 95mi<br/>FCO: 200mi                                              |

While the route `A->B` can exist, it doesn't necessarily mean that `B->A` exists. Additionally, the mileage may be different for each direction.

As a side-note, some of the mileages might not be at all accurate but imagine that someone make some fairly large one-way portals in the sky that can shorten the distance between two airports.

The current logic allows for the following endpoints:
* `GET`: `/airports` - returns a list of airports
* `GET`: `/airports/{airportId}` - return details of a single airport
* `GET`: `/airports/{airportId}/to/{airportToId}` - returns the cheapest quote for a journey from `airportId` to `airportToId`
* `GET`: `/vehicle/{numberOfPeople}/{distance}` - returns the cheapest vehicle to use (and the cost) for the given `numberOfPeople` and `distance` in miles
