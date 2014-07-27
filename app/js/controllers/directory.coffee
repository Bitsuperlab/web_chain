angular.module("app").controller "DirectoryController", ($scope, $location, $filter, $modal, Blockchain, Utils) ->
    $scope.reg = []
    $scope.genesis_date = ""
    $scope.p =
        currentPage: 0
        pageSize: 20
        numberOfPages: 0
    $scope.q =
        name: ""
    $scope.delegate_active_hash_map = Blockchain.delegate_active_hash_map
    $scope.delegate_inactive_hash_map = Blockchain.delegate_inactive_hash_map

    $scope.$watch ()->
        $scope.q.name
    , ()->
        $scope.p.numberOfPages = Math.ceil(($filter("filter") $scope.reg, $scope.q).length / $scope.p.pageSize)
        $scope.p.currentPage = 0

    Blockchain.get_config().then (config) ->
        $scope.genesis_date = config.genesis_timestamp

    Blockchain.list_accounts().then (reg) ->
        $scope.reg = reg
        $scope.p.numberOfPages = Math.ceil($scope.reg.length / $scope.p.pageSize)

    $scope.formatRegDate = (d) ->
        if d == $scope.genesis_date
            "Genesis"
        else
            $filter("prettyDate")(d)
