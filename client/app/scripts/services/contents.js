'use strict';

angular.module('app').factory('contents', [
  '$log',
  '$q',
  '$http',
  'INIT_TWEET',
  function($log, $q, $http, INIT_TWEET) {
    var contents = {
      tweet: '',
      reply: '',
      reset: function(type) {
        var messages = INIT_TWEET[type];
        contents.tweet = messages[ Math.floor(Math.random() * messages.length) ];
        contents.reply = '';
      },
      sendServer: function() {
        console.log('send server');
        return $http.post(
          '/api/tweet/',
          {
            'tweet': contents.tweet,
            'reply': contents.reply,
          })
          .then(function(data, status, headers, config){
            console.log(data + status + headers + config);
            console.log('api tweet success');
            console.log(data.data);

            if (data.data.tweet) {
              return null;
            }
            return data.data;

          }, function(data, status, headers, config){
            console.log(data + status + headers + config);
            console.log('api tweet failure');
            return { error_message: 'system error' };
          });

      },
    };

    return contents;
  }
]);

