Petit:Lambda - Url Shortening Service Based on AWS Lambda and API Gateway
===========================================

Put full description here. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Consequatur ex quis, architecto placeat officiis sit ea esse laborum enim quibusdam cum modi saepe in alias deserunt explicabo eos dolore iste.

## Stack
### Lambda Functions

- **PetitRedirector**: a simple javascript function that recieves http requests from a load balancer and returns redirects based on entries in a DynamoDB table shared by both functions.

- **PetitAPIFunction**: a Ruby application backed by Sinatra which provides the CRUD operations for the url shortener through Amazon API Gateway.

Function names are appended with the name of the deployed stage.

### Table

- **Petit**: a DynamoDB table that contains the shortcode, destination, ssl, created_at, updated_at, and access_count records 

The table name is appended with the name of the deployed stage.

### Event Sources

- **Petit-Api**: an API Gateway-based API that provides the front end for the PetitAPI function.
- Application Load Balancer: The PetitRedirector function must be configured to run behind an Application Load Balancer. **You must do this configuration manually after the stack is created. (See: [Installation](#installation))**

## Configuration

#### These variables set the configuration for the Petit API app:
- **Stage**: Can be a version in production (v1, v1.1, v2) or an environment (test, staging, prod)

	Defaults to "test"

- **ServiceBaseUrl**: Public base URL like 'http://bit.ly'
	
	Required.

- **NotFoundDestination**: Url where users will be sent if they request a shortcode that doesn't exist.
	
	Required.

- **ArtifactsBucket**: Bucket name where the artifacts for this application will be stored.
	
	Required.


## Installation

This install guide assumes that you have Ruby version 2.5 and the AWS CLI already installed.

1. Ensure that you are using Ruby 2.5.x and install Bundler (version 1.x)
2. Clone this repository to your local computer
3. Install the ruby dependencies for the API service
	```Bash
	$ bundle install
	```
4. Download the gems locally, as you'll need local copies for your deploy package
	```Bash
	$ bundle install --deployment
	```
5. Upload the Swagger File to S3

	Note: This requires that you have an S3 bucket in which to store both this file, and the package artifacts. If you don't, you'll need to create one in the account that your AWS CLI is set up to use.
	
	```Bash
	$ aws s3 cp ./api-definitions/petit-api.yml s3://{ your-bucket-name }/
	```
	This is necessary because the swagger file requires transformation, and must be present on S3 before the next steps so it can be transformed.

6. Create the deplopyment package.
	```Bash
	 $ aws cloudformation package \
     --template-file template.yaml \
     --output-template-file serverless-output.yaml \
     --s3-bucket { your-bucket-name }
	```
	If you have the SAM CLI installed the equivalent command is:
	```Bash
	 $ sam package \
     --template-file template.yaml \
     --output-template-file serverless-output.yaml \
     --s3-bucket { your-bucket-name }
     ```
     SAM provides the ability to test Lambda functions and APIs locally, if  you are doing any lambda development
     this is a good idea.

7. Deploy the stack to cloudformation
	```Bash
	 $ aws cloudformation deploy \
	 --template-file serverless-output.yaml \
     --stack-name { your-stack-name } \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides NotFoundDestination={ your-not-found-destination } \
     ArtifactsBucket={ your-bucket-name } \
     ServiceBaseUrl={ your-base-url }
    ```
    The SAM equivalent:
    ```Bash
     $ sam deploy \
     --template-file serverless-output.yaml \
     --stack-name { your-stack-name } \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides NotFoundDestination={ your-not-found-destination } \
     ArtifactsBucket={ your-bucket-name } \
     ServiceBaseUrl={ your-base-url }
    ```

#### API Custom Domain
You can use a custom domain name for the API endpoint. This can be configured through API Gateway.
In addition you should also change the API_BASE_URL environment variable on the PetitAPIFunction to match.


## About The Author(s)

![ECHO Inc.](http://static.squarespace.com/static/516da119e4b00686219e2473/t/51e95357e4b0db0cdaadcb4d/1407936664333/?format=1500w)

This is an open-source project built by ECHO, an international nonprofit working to help those who are teaching farmers around the world know how to be more effective in producing enough to meet the needs of their families and their communities. ECHO is an information hub for international development practitioners specifically focused on sustainable, small-scale, agriculture. Through educational programs, publications, and networking ECHO is sharing solutions from around the world that are solving hunger problems.

Charity Navigator ranks ECHO as the #1 International Charity in the state of Florida (where their US operations are based) and among the top 100 in the US.

Thanks to grants and donations from people like you, ECHO is able to connect trainers and farmers with valuable (and often hard-to-find) resources. One of ECHO's greatest resources is the network of development practitioners, around the globe, that share help and specialized knowledge with each other. ECHO participates in the greater open-source community in order to provide the services necessary to facilitate these connections.

To find out more about ECHO, or to help with the work that is being done worldwide please visit http://www.echonet.org