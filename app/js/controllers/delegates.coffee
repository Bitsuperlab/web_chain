angular.module("app").controller "DelegatesController", ($scope, $location, $state, $q, Growl, Blockchain, RpcService, Info) ->
    $scope.active_delegates = Blockchain.active_delegates
    $scope.inactive_delegates = Blockchain.inactive_delegates
    $scope.avg_act_del_pay_rate = Blockchain.avg_act_del_pay_rate
    $scope.blockchain_delegate_pay_rate = Info.info.blockchain_delegate_pay_rate
    $scope.p =
        currentPage: 0
        pageSize: 100
        numberOfPages: 0
    $scope.p.numberOfPages = Math.ceil($scope.inactive_delegates.length / $scope.p.pageSize)

    $q.all([Blockchain.refresh_delegates()]).then ->
        $scope.active_delegates = Blockchain.active_delegates
        $scope.inactive_delegates = Blockchain.inactive_delegates
        $scope.avg_act_del_pay_rate = Blockchain.avg_act_del_pay_rate
        $scope.blockchain_delegate_pay_rate = Info.info.blockchain_delegate_pay_rate
        $scope.p.numberOfPages = Math.ceil($scope.inactive_delegates.length / $scope.p.pageSize)

    $scope.$watch ()->
        Info.info
    , ()->
        $scope.blockchain_delegate_pay_rate = Info.info.blockchain_delegate_pay_rate
    ,true

    Blockchain.get_asset(0).then (asset_type) =>
        $scope.current_xts_supply = asset_type.current_share_supply
