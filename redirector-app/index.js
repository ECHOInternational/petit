var config = require("./config");
var shortcodes = require("./shortcodes");
var redirect = require("./redirect");


exports.handler = function (event, context, callback) {

    let shortcode = shortcodes.cleanShortcode(event.path);
    shortcodes.get_shortcode(shortcode, function(err, data){
       if(err){
            // Something went wrong with the query   
           console.log(err);
           callback(null, redirect.not_found);
       }else{
           let destination = shortcodes.process_get_response(data);
           
           // destination returns false if no result is found.
           if(destination){
               shortcodes.hit_shortcode(shortcode, function(err, data){
                   if(err){
                       console.log(err);
                   }
               });
               callback(null, redirect.permanent(destination));
           }else{
               callback(null, redirect.not_found);
           }
       }
    });
    
};
