'use strict';

angular.module('app').factory('account', ['$window', '$location', '$log', '$http', 'storage', function($window, $location, $log, $http, storage) {
  console.log('account factory');

  var account = {
    currentUser : null,
    isAuthenticated : function() {
      return !!account.currentUser || !!storage.get('twitterLogin');
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

    updateSession:function(hashKey){
      return $http.post('/api/login/update_session', { hash_key : hashKey })
        .then(function(data, status, headers, config){
          storage.remove('twitterLogin');
          if (data.data.error) {
            storage.clearAll();
            return { error : data.data.error };
          } else {
            console.log('login success');
            account.currentUser = data.data;
            storage.set('hashKey', data.data.login_hash);
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

    twitterLogin: function() {
      $http.get('/api/twitter/login')
      .then(function(response) {
        if (response.data.redirect_url) {
          storage.set('twitterLogin', '1');
          document.location.href = response.data.redirect_url;
        }
      });
    },
    requestCurrentUser: function() {
      console.log('requestCurrentUser');
    }
  };

  account.currentUser = storage.get('currentUser');
  if (account.currentUser) {
    console.log('has current user');
    var hashKey = storage.get('hashKey');
    account.updateSession(hashKey).then(function(error){
      if (error) {
        $location.path('/login');
      }
    });
  } else if (storage.get('twitterLogin')) {
    console.log('has twitter login');
    account.updateSession(null).then(function(error){
      if (error) {
        $location.path('/login');
      }
    });
  }
  return account;
}]);

  
