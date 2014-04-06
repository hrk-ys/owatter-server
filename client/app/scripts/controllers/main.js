'use strict';

angular.module('app').config(['$routeProvider', function($routeProvider) {
  console.log('main config');
	$routeProvider.when('/', {
		templateUrl:'views/main.html',
		controller: 'MainCtrl',
	});
}]);

angular.module('app').controller('MainCtrl', [
  '$scope',
  '$location',
  '$window',
  'contents',
  function ($scope, $location, $window, contents) {
  $scope.createMessage = function(type) {
    console.log('click owatter: ' + type);
    contents.reset(type);
    $location.path('/create/message');
  };

}]);
