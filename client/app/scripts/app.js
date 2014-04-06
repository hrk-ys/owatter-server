'use strict';

angular
  .module('app', [
    'ngCookies',
    'ngResource',
    'ngSanitize',
    'ngRoute',
    'angularLocalStorage',
    'ui.bootstrap',
  ])
  .config(['$locationProvider', '$routeProvider', function ($locationProvider, $routeProvider) {
    $locationProvider.html5Mode(true);
    $routeProvider.otherwise({ redirectTo: '/' });
  }])

  .constant('INIT_TWEET', {
    '1':[
      '学校終わったー',
      '学校終わったー（≧∇≦）',
      '終わったよおおお☻♡  ',
    ],
    '2':[
      'バイトわったー',
      'バイトわったー……ZZZ',
      'バイトわったよ！！',
    ],
    '3':[
      '仕事わったー',
      '仕事DONE',
      '仕事？(ᐛ👐)ﾊﾟｧ',
    ],
    '4':[''],
  })
  .config(['$httpProvider', function ($httpProvider) {
    $httpProvider.defaults.headers.post['Content-Type'] = 'application/x-www-form-urlencoded';
    $httpProvider.defaults.transformRequest = function(data){
      if (data === undefined) {
        return data;
      }
      return $.param(data);
    };
  }])

  .run(['$log', '$rootScope', '$location', '$route', 'account',
        function($log, $rootScope, $location, $route, account) {

    $log.log('run');

    $rootScope.$on('$routeChangeStart', function(ev, next, current){
      $log.log(ev, next, current);

      if (next.controller === 'LoginCtrl')
      {
        if (account.isAuthenticated())
        {
          $location.path('/');
        }
      }
      else
      {
        if (account.isAuthenticated() === false)
        {
          $location.path('/login');
        }
      }
    });
  }]);

