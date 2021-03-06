angular.module("app").controller "AccountController", ($scope, $filter, $location, $stateParams, $q, Growl, Wallet, Utils, WalletAPI, $modal, Blockchain, RpcService, Info) ->

    Info.refresh_info()
    $scope.refresh_addresses=Wallet.refresh_accounts
    name = $stateParams.name
    $scope.account_name = name
    $scope.utils = Utils
    $scope.account = Wallet.accounts[name]
    $scope.balances = Wallet.balances[name]
    $scope.formatAsset = Utils.formatAsset
    $scope.symbol = Info.symbol
    $scope.model = {}
    $scope.model.rescan = true
    $scope.magic_unicorn = magic_unicorn?
    $scope.gravatar_account_name = 'email'

    $scope.trust_level = false
    $scope.wallet_info = {file: "", password: "", type: 'Bitcoin'}
    $scope.transfer_info =
        amount : 0
        symbol : "Symbol not set"
        payto : ""
        memo : ""
        vote : 'vote_random'

    $scope.vote_options =
        vote_none: "None"
        vote_all: "All"
        vote_random: "Random subset"

    console.log('tinfo', $scope.transfer_info)
    $scope.memo_size_max = 0
    $scope.private_key = {value : ""}
    $scope.p = { pendingRegistration: Wallet.pendingRegistrations[name] }

    # TODO: mixing the wallet account with blockchain account is not a good thing.
    Wallet.get_account(name).then (acct)->
        $scope.account = acct
        $scope.account_name = acct.name
        Wallet.current_account = acct
        if $scope.account.delegate_info
            Blockchain.get_asset(0).then (asset_type) ->
                $scope.account.delegate_info.pay_balance_asset = Utils.asset($scope.account.delegate_info.pay_balance, asset_type)
        
    Wallet.refresh_account(name).then ->
        $scope.trust_level = Wallet.approved_delegates[name]

    Blockchain.get_asset(0).then (asset_type) =>
        $scope.current_xts_supply = asset_type.current_share_supply

    $scope.$watch ->
        Wallet.accounts[name]
    , ->
        if Wallet.accounts[name]
            $scope.account = Wallet.accounts[name]

    $scope.$watch ->
        Wallet.balances[name]
    , ->
        if Wallet.balances[name]
            $scope.balances = Wallet.balances[name]
            $scope.transfer_info.symbol=Object.keys(Wallet.balances[name])[0]

    $scope.$watchCollection ->
        Wallet.transactions
    , () ->
        Wallet.refresh_account(name)

    $scope.$watch ->
        $scope.transfer_info.payto
    , ->
        $scope.gravatar_account_name = $scope.transfer_info.payto

    Blockchain.get_config().then (config) ->
        $scope.memo_size_max = config.memo_size_max
        $scope.addr_symbol = config.symbol

    $scope.import_key = ->
        form = @import_key_form
        form.key.$invalid = false
        WalletAPI.import_private_key($scope.private_key.value, $scope.account.name, false, $scope.model.rescan).then (response) ->
            $scope.private_key.value = ""
            if response == name
                Growl.notice "", "Your private key was successfully imported."
            else
                Growl.notice "", "Private key already belongs to another account: \"" + response + "\"."
            Wallet.refresh_transactions_on_update()
        , (response) ->
            form.key.$invalid = true

    $scope.select_file = ->
        $scope.wallet_info.file = magic_unicorn.prompt_user_to_open_file('Please open your wallet')

    $scope.import_wallet = ->
        form = @import_wallet_form
        form.path.$invalid = false
        form.pass.$invalid = false
        promise = null
        switch $scope.wallet_info.type
            when 'Bitcoin' then promise = WalletAPI.import_bitcoin($scope.wallet_info.file,$scope.wallet_info.password,$scope.account.name)
            when 'Multibit' then promise = WalletAPI.import_multibit($scope.wallet_info.file,$scope.wallet_info.password,$scope.account.name)
            when 'Electrum' then promise = WalletAPI.import_electrum($scope.wallet_info.file,$scope.wallet_info.password,$scope.account.name)
            when 'Armory' then promise = WalletAPI.import_armory($scope.wallet_info.file,$scope.wallet_info.password,$scope.account.name)
        promise?.then (response) ->
            $scope.wallet_info.type = 'Bitcoin'
            $scope.wallet_info.file = ""
            $scope.wallet_info.password = ""
            Growl.notice "","The wallet was successfully imported."
            Wallet.refresh_transactions_on_update()
        , (response) ->
            if response.data.error.code == 13
                form.path.error_message = "No such file or directory"
                form.path.$invalid = true
            else if response.data.error.code == 0 and response.data.error.message.match(/decrypt/)
                form.pass.error_message = "Unable to decrypt wallet"
                form.pass.$invalid = true

    yesSend = ->
        WalletAPI.transfer($scope.transfer_info.amount, $scope.transfer_info.symbol, $scope.account.name, $scope.transfer_info.payto, $scope.transfer_info.memo, $scope.transfer_info.vote).then (response) ->
            $scope.transfer_info.payto = ""
            $scope.transfer_info.amount = ""
            $scope.transfer_info.memo = ""
            console.log response
            Growl.notice "", "Transfer transaction broadcasted"
            Wallet.refresh_transactions_on_update()
            $scope.t_active=true
        ,
        (error) ->
            if (error.data.error.code==20005)
                Growl.error "Unknown receive account",""
            if (error.data.error.code==20010)
                Growl.error "Insufficient funds",""

    $scope.send = ->
        $modal.open
            templateUrl: "dialog-confirmation.html"
            controller: "DialogConfirmationController"
            resolve:
                title: -> "Are you sure?"
                message: -> "This will send " + $scope.transfer_info.amount + " " + $scope.transfer_info.symbol + " to " + $scope.transfer_info.payto + ". It will charge a fee of " + Info.info.priority_fee + "."
                action: -> yesSend

    $scope.newContactModal = ->
      $modal.open
        templateUrl: "newcontact.html"
        controller: "NewContactController"
        resolve:
            addr: ->
                ""
            action: ->
                (contact)->
                    $scope.transfer_info.payto = contact

    $scope.addContactFromTo = ->
      if payto and payto.value and $scope.addr_symbol and (payto.value.indexOf $scope.addr_symbol) == 0 and payto.value.length == $scope.addr_symbol.length + 50
          $modal.open
            templateUrl: "newcontact.html"
            controller: "NewContactController"
            resolve:
                addr: ->
                    payto.value
                action: ->
                    (contact)->
                        $scope.transfer_info.payto = contact
                    

    $scope.toggleVoteUp = ->
        approve = !Wallet.approved_delegates[name]
        Wallet.approve_delegate(name, approve).then ->
            $scope.trust_level = approve

    $scope.toggleFavorite = ->
        address = $scope.account.owner_key
        Wallet.wallet_add_contact_account(name, address).then ()->
            WalletAPI.account_set_favorite(name, !Wallet.accounts[name].is_favorite).then ()->
                Wallet.refresh_accounts()
            
    $scope.regDial = ->
        if Wallet.asset_balances[0]
          $modal.open
            templateUrl: "registration.html"
            controller: "RegistrationController"
            scope: $scope
        else
          Growl.error '','Account registration requires funds.  Please fund one of your accounts.'

    $scope.accountSuggestions = (input) ->
        deferred = $q.defer()
        deferred.resolve(Object.keys(Wallet.accounts))
        return deferred.promise
