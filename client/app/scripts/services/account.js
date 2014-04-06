'use strict';

angular.module('app').factory('account', ['$window', '$location', '$log', '$http', 'storage', function($window, $location, $log, $http, storage) {
  console.log('account factory');

  var account = {
    currentUser : null,
    isAuthenticated : function() {
      return !!account.currentUser;
    },
    login : function(accessToken) {
      return $http.post('api/login/', { token : accessToken })
        .then(function(data, status, headers, config){
          $log.log(data, status, headers, config);
          if (data.data.error) {
            storage.clearAll();
            return { error : data.data.error };
          } else {
            console.log('login success');
            account.currentUser = data.data;
            storage.set('accessToken', accessToken);
            storage.set('currentUser', data.data);
            return null;
          }
        },
        function(data, status, headers, config){
          $log.log(data, status, headers, config);
          storage.clearAll();
          console.log('login failure');
          return { error : 'system error' };
        });
    },
    requestCurrentUser: function() {
      console.log('requestCurrentUser');
    }
  };

  account.currentUser = storage.get('currentUser');
  if (account.currentUser) {
    var token = storage.get('accessToken');
    account.login(token).then(function(error){
      if (error) {
        $location.path('/local');
      }
    });
  }
  return account;
}]);

  
