Petit:Lambda Ruby Url Shortening Backend Service Based on AWS Lambda and API Gateway
===========================================

## Environment Variables
Petit is designed to be a Twelve Factor app and therefore all configuration
should be done using environment variables.

### Amazon Web Services:

To use the default DynamoDB you'll need all of the AWS credentials.

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

### These variables set the configuration for the Petit app.
- DB_TABLE_NAME (Name of the database to create/use)
- API_BASE_URL (Ususally a HTTPS address with some security applied)
- SERVICE_BASE_URL (Public base URL like 'http://bit.ly' )
- NOT_FOUND_DESTINATION (Optional Address where public requests that result in 404 will be sent.)

## About The Author(s)

![ECHO Inc.](http://static.squarespace.com/static/516da119e4b00686219e2473/t/51e95357e4b0db0cdaadcb4d/1407936664333/?format=1500w)

This is an open-source project built by ECHO, an international nonprofit working to help those who are teaching farmers around the world know how to be more effective in producing enough to meet the needs of their families and their communities. ECHO is an information hub for international development practitioners specifically focused on sustainable, small-scale, agriculture. Through educational programs, publications, and networking ECHO is sharing solutions from around the world that are solving hunger problems.

Charity Navigator ranks ECHO as the #1 International Charity in the state of Florida (where their US operations are based) and among the top 100 in the US.

Thanks to grants and donations from people like you, ECHO is able to connect trainers and farmers with valuable (and often hard-to-find) resources. One of ECHO's greatest resources is the network of development practitioners, around the globe, that share help and specialized knowledge with each other. ECHO uses the YourMembership product to help facilitate these connections.

To find out more about ECHO, or to help with the work that is being done worldwide please visit http://www.echonet.org