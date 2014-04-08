'use strict';

angular.module('app').config(['$routeProvider', function($routeProvider) {
  console.log('login config');
  $routeProvider.when('/login', {
    templateUrl:'views/login.html',
    controller: 'LoginCtrl',
  });
}]);


angular.module('app').controller('LoginCtrl',  [
  '$log', '$scope', '$location', '$window', 'account',
  function($log, $scope, $location, $window, account) {
    $log.log('LoginCtrl');

    $scope.showLoginForm = true;
    function setError(error) {
      $scope.showLoginForm = true;
      $scope.error = error.error;
    }

    $scope.login = function() {
      account.twitterLogin();
    }

    $window.fbAsyncInit = function() {
      var FB = $window.FB;
      console.log(FB);
      FB.init({
        appId      : '433825450082314',
        status     : true,
        coockie    : true,
        xfbml      : true
      });

      FB.Event.subscribe('auth.authResponseChange', function(response) {
        if (response.status === 'connected') {
          var accessToken = response.authResponse.accessToken;
          console.log(accessToken);

          account.login(accessToken).then(function(error){
            if (error !== null) {
              setError(error);
            }
            if (account.isAuthenticated()) {
              $location.path('/');
            } else {
              $scope.showLoginForm = true;
            }
          }, function(error) {
            setError(error);
          });
          
        } else {
          FB.login();
          console.log('FB.login()');
          $scope.showLoginForm = true;
        }
      });
    };
  }
]);
