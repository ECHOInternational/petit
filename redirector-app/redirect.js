var config = require("./config");
module.exports = {
    not_found: {
        "statusCode": 303,
        "headers": {
            "Location": config.properties.not_found_destination
        }
    },
    permanent: function(target){
        return {
            "statusCode": 301,
            "headers": {
                "Location": target
            }
        };
    }
};