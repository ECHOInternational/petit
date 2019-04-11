Petit:Lambda - Url Shortening Service Based on AWS Lambda and API Gateway
===========================================

Put full description here. Lorem ipsum dolor sit amet, consectetur adipisicing elit. Consequatur ex quis, architecto placeat officiis sit ea esse laborum enim quibusdam cum modi saepe in alias deserunt explicabo eos dolore iste.

## Stack
### Lambda Functions

- **PetitRedirector** is a simple javascript function that recieves http requests from a load balancer and returns redirects based on entries in a DynamoDB table shared by both functions.

- **PetitAPIFunction** is a Ruby application backed by Sinatra which provides the CRUD operations for the url shortener through Amazon API Gateway.

### Tables

### Event Sources



#### These variables set the configuration for the Petit API app.
- DB_TABLE_NAME (Name of the database to create/use)
- API_BASE_URL (Ususally a HTTPS address with some security applied)
- SERVICE_BASE_URL (Public base URL like 'http://bit.ly' )

## About The Author(s)

![ECHO Inc.](http://static.squarespace.com/static/516da119e4b00686219e2473/t/51e95357e4b0db0cdaadcb4d/1407936664333/?format=1500w)

This is an open-source project built by ECHO, an international nonprofit working to help those who are teaching farmers around the world know how to be more effective in producing enough to meet the needs of their families and their communities. ECHO is an information hub for international development practitioners specifically focused on sustainable, small-scale, agriculture. Through educational programs, publications, and networking ECHO is sharing solutions from around the world that are solving hunger problems.

Charity Navigator ranks ECHO as the #1 International Charity in the state of Florida (where their US operations are based) and among the top 100 in the US.

Thanks to grants and donations from people like you, ECHO is able to connect trainers and farmers with valuable (and often hard-to-find) resources. One of ECHO's greatest resources is the network of development practitioners, around the globe, that share help and specialized knowledge with each other. ECHO uses the YourMembership product to help facilitate these connections.

To find out more about ECHO, or to help with the work that is being done worldwide please visit http://www.echonet.org