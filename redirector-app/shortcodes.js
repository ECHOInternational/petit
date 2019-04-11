var config = require("./config");
var AWS = require("aws-sdk");
var docClient = new AWS.DynamoDB.DocumentClient();
module.exports = {
    cleanShortcode: function(shortcode) {
        return shortcode.replace(/^\//, '').replace(/\/$/, '').toLowerCase();
    },
    getLocation: function(returnedData) {
        let location = "";
        let item = returnedData.Item;
        if(item.ssl === true) {
            location += "https://";
        }else{
            location += "http://";
        }
        return location += item.destination;
    },
    has_response: function(returnedData) {
        return typeof(returnedData.Item) === 'object';
    },
    process_get_response: function(response){
        if(!this.has_response(response)){ return false; }
        return this.getLocation(response);
    },
    get_shortcode: function(shortcode, callback) {
        let params = {
            'TableName': config.properties.table_name,
            'Key':{ "shortcode": shortcode }
        };
        docClient.get(params, callback);
    },
    hit_shortcode: function(shortcode, callback) {
        let params = {
            'TableName': config.properties.table_name,
            'Key': { 'shortcode': shortcode },
            'ReturnValues': 'ALL_NEW',
            'ReturnConsumedCapacity': 'NONE',
            'UpdateExpression': 'SET access_count = access_count + :one',
            'ExpressionAttributeValues': { ':one': 1 }
        };
        docClient.update(params, callback);
    }
};