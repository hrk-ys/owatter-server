'use strict';

angular.module('app').config([
  '$routeProvider',
  function($routeProvider) {
    $routeProvider.when('/history/', {
      templateUrl:'/views/history.html',
      controller: 'HistoryCtrl',
      resolve: {
        tweets: ['history', function(history) {
          return history.getTweets();
        }],
      },
    });
  },
]);

angular.module('app').controller('HistoryCtrl', [
  '$window',
  '$scope',
  'account',
  'history',
  function ($window, $scope, account, history) {
    console.log('HistoryCtrl init');

    $window.scrollTo(0,0);
    $scope.currentUserId = account.currentUser.user_id;
    $scope.tweets = history.tweets;

    $scope.canMessage = function(tweet) {
      if (tweet.message_num === '2' &&
          tweet.user_id !== account.currentUser.user_id) {
        return true;
      }

      if (tweet.message_num === '3' &&
          tweet.user_id === account.currentUser.user_id) {
        return true;
      }
      return false;
    };
    $scope.messageSend = function(tweet) {
      return history.sendMessage(tweet);
    };
    $scope.thankSend = function(tweet) {
      return history.sendThanks(tweet);
    };
  },
]);


