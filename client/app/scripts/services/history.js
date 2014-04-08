'use strict';

angular.module('app').factory('history', [
  '$window',
  '$location',
  '$http',
  '$q',
  function($window, $location, $http, $q) {

    var history = {
      tweets: [],
      lastSyncTime: 0,
      getPreview: function(hash_key) {
        return $http.get(
          '/api/preview?h=' + hash_key)
        .then(function(data){
          console.log(data.data);
          return [data.data.tweet];
        });
      },

      getTweets: function() {
        return $http.post(
          '/api/data_sync',
          { 'last_sync_time':history.lastSyncTime })
        .then(function(data){
          console.log(data.data);
          if (data.data.tweets) {
            history.tweets = history.tweets.concat(data.data.tweets.reverse());
            history.tweets.sort(
              function(a,b) {
                if( a.updated_at > b.updated_at ) return -1;
                if( a.updated_at < b.updated_at ) return 1;
                return 0;
              }
            );
          }
          if (data.data.last_sync_time > history.lastSyncTime) {
            history.lastSyncTime = data.data.last_sync_time;
          }
          return history.tweets;
        });
      },

      sendMessage: function(tweet) {
        console.log(tweet);
        return $http.post(
          '/api/tweet/message',
          { 'tweet_id':tweet.tweet_id,
            'content' :tweet.reply })
        .then(function(response){
          console.log(response.data);
          if (tweet.messages) {
            tweet.messages.push(response.data.message);
            tweet.message_num = tweet.messages.lenght;
          }
          return response.data.message;
        });
      },

      sendThanks: function(tweet) {
        console.log(tweet);
        return $http.post(
          '/api/tweet/thanks',
          { 'tweet_id':tweet.tweet_id})
        .then(function(response){
          console.log(response.data);
          if (tweet.messages) {
            tweet.messages.push(response.data.message);
          } else {
            tweet.messages = [response.data.message];
          }
          tweet.message_num = tweet.messages.lenght;
          return response.data.message;
        });
      },
    };

    return history;
  },
]);

