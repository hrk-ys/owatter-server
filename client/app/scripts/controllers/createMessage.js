'use strict';

angular.module('app').config(['$routeProvider', function($routeProvider) {
	$routeProvider.when('/create/message', {
		templateUrl:'/views/createMessage.html',
		controller: 'CreateMessageCtrl',
	});
	$routeProvider.when('/create/message/done', {
		templateUrl:'/views/createMessageDone.html',
	});
}]);

angular.module('app').controller('CreateMessageCtrl', [
  '$scope',
  '$location',
  '$modal',
  '$routeParams',
  'contents',
  function ($scope, $location, $modal, $routeParams, contents) {

    $scope.contents = contents;

    if (!!$routeParams.error_message) {
      $scope.error = { error_message: $routeParams.error_message };
    }

    $scope.confirmMessage = function() {
      console.log('create message confirm');
      var modalInstance = $modal.open({
        templateUrl: 'confirmMessage.html',
        controller: ModalInstanceCtrl,
        resolve: {
          tweet: function () { return $scope.contents.tweet; },
          reply: function () { return $scope.contents.reply; },
        }
      });

      modalInstance.result.then(function () {
        console.log('Modal success at: ' + new Date());
        sendMessage();
      }, function () {
        console.log('Modal dismissed at: ' + new Date());
      });
    };

    var sendMessage = function() {
      contents.sendServer()
        .then(function(error){
          console.log('create message success');

          if (error) {
            if (error.redirect_url) {
              document.location.href = error.redirect_url;
            } else {
              $scope.error = error;
            }
          } else {
            $location.path('/create/message/done');
          }
        },
        function(error) {
          $scope.error = error;
        });
    };


    var ModalInstanceCtrl = [
      '$scope', '$modalInstance', 'tweet', 'reply',
      function ($scope, $modalInstance, tweet, reply) {
        console.log('modal instance');
        $scope.tweet = tweet;
        $scope.reply = reply;
    
        $scope.ok = function () {
          $modalInstance.close();
        };
    
        $scope.cancel = function () {
          $modalInstance.dismiss('cancel');
        };
      }
    ];
  }
]);
