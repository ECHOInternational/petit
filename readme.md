Petit:Lambda - Url Shortening Service Based on AWS Lambda and API Gateway
===========================================

Petit:lambda is a serverless URL shortening service based on Ruby, Node.js and AWS.

This is a port of the original Petit URL shortener (which is arguably faster) but is not serverless. https://github.com/ECHOInternational/petit

This app and accompanying Cloudformation Template will create nearly everything you need to run a URL shortener on AWS Lambda. The user-facing portions run behind an Application Load Balancer and the API behind AWS API Gateway. 

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

- **ApiBaseUrl**: The url to your API. The generic one assigned by API Gateway will be in the outputs of your cloudformation stack. if you're using a custom domain name for your API you should specify the custom domain and any path variables here. If this is not set, or is inaccurate, the "self" links returned in the payload will be incorrect.

	Defaults to "https://REPLACEME.execute-api.${AWS::Region}.amazonaws.com/${Stage}/"

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
     ServiceBaseUrl={ your-base-url } \
     ApiBaseUrl={ your-api-base-url }
    ```
    The SAM equivalent:
    ```Bash
     $ sam deploy \
     --template-file serverless-output.yaml \
     --stack-name { your-stack-name } \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides NotFoundDestination={ your-not-found-destination } \
     ArtifactsBucket={ your-bucket-name } \
     ServiceBaseUrl={ your-base-url } \
     ApiBaseUrl={ your-api-base-url }
    ```

8. Once the stack has deployed successfully you will have just a few additional steps to
   complete to have your service running properly.
	
	+ [Enable CORS](#enable-cors) (Optional)
	+ [Set up a custom domain for your API](#set-up-a-custom-domain-name-for-your-api) (Optional)

9. Set the API_BASE_URL

	Whether or not you customize your API Url you should still set the Environment Variable on the PetitApiFunction so that the json responses contain the correct URL. 

	Set the `API_BASE_URL` to either the API Gateway address for the stage you're using or the custom domain that you have configured. (Remember that you may need to add the base path mapping and/or the stage name to the end of the custom domain name).

	**NOTE:** you can get the API Gateway Address needed here from the outputs section of the Cloudformation Stack. It is labeled `API Endpoint URL`. (If anyone can figure out how to set this automatically without causing a circular dependency I would accept your pull request with great joy.)

	The AWS Documentation is helpful if you don't know how to change environment variables on Lambda functions.
	https://docs.aws.amazon.com/lambda/latest/dg/env_variables.html

10. Connect your Application Load Balancer to your PetitRedirector function

	You will need an API load balancer with a domain pointed at it through dns. For instance you want a very short domain name like goto.link (but of course you already know this or you wouldn't be creating a url shortener).

	Creating an Application Load Balancer is beyond the scope of this document. For instructions see the AWS documentation: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/application-load-balancer-getting-started.html
	
	Once your load balancer is is place you should point traffic coming in from your domain on port 80 to your `PetitRedirectorFunction` lambda function.

	Your URL shortener should be ready for use!

### Enable CORS
If you do not enable cors your URL shortener will still work, but the API will only be able to be called from sites on the same domain from javascript in a browser.

This is easiest to implement directly through the AWS console:
https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-cors.html#how-to-cors-console

### Set up a custom domain name for your API
A custom domain name for your API is not required, but can make your urls shorter, and more maintainable (for instance if you ever want to leave API gateway and still need your API to work).

Setting up security certificates, DNS, and the custom domain name are beyond the scope of this document but the AWS documentation is quite clear:
https://docs.aws.amazon.com/apigateway/latest/developerguide/how-to-custom-domains.html






## About The Author(s)

![ECHO Inc.](http://static.squarespace.com/static/516da119e4b00686219e2473/t/51e95357e4b0db0cdaadcb4d/1407936664333/?format=1500w)

This is an open-source project built by ECHO, an international nonprofit working to help those who are teaching farmers around the world know how to be more effective in producing enough to meet the needs of their families and their communities. ECHO is an information hub for international development practitioners specifically focused on sustainable, small-scale, agriculture. Through educational programs, publications, and networking ECHO is sharing solutions from around the world that are solving hunger problems.

Charity Navigator ranks ECHO as the #1 International Charity in the state of Florida (where their US operations are based) and among the top 100 in the US.

Thanks to grants and donations from people like you, ECHO is able to connect trainers and farmers with valuable (and often hard-to-find) resources. One of ECHO's greatest resources is the network of development practitioners, around the globe, that share help and specialized knowledge with each other. ECHO participates in the greater open-source community in order to provide the services necessary to facilitate these connections.

To find out more about ECHO, or to help with the work that is being done worldwide please visit http://www.echonet.org