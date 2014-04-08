'use strict';

angular.module('app').config([
  '$routeProvider',
  function($routeProvider) {
    $routeProvider.when('/p/:hashKey', {
      templateUrl:'/views/preview.html',
      controller: 'PreviewCtrl',
    });
  },
]);

angular.module('app').controller('PreviewCtrl', [
  '$scope',
  '$routeParams',
  'history',
  function ($scope, $routeParams, history) {
    console.log('PreviewCtrl init');

    history.getPreview($routeParams.hashKey).then(function(tweets) {
      $scope.tweets = tweets;
    });
  },
]);




