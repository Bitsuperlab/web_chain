servicesModule = angular.module("app.services", [])

servicesModule.config ($httpProvider) ->
    $httpProvider.interceptors.push('myHttpInterceptor')

servicesModule.factory "myHttpInterceptor", ($q, $rootScope, $location, Growl, Shared) ->
    dont_report_methods = ["wallet_open", "wallet_unlock", "walletpassphrase", "get_info", "blockchain_get_block",
                           "wallet_get_account"]

    #  request: (config) ->
    #    config
    #
    #  response: (response) ->
    #    response

    responseError: (response) ->
        promise = null
        method = null

        error_msg = if response.data?.error?.message? then response.data.error.message else response.data

        if response.config? and response.config.url.match(/\/rpc$/)
            if response.status == 404
                location.href = "/404.html"
            else if error_msg.match(/No such wallet exists/)
                $location.path("/createwallet")
            else if response.data.error.code == 0
                console.log('wallet not open')
            method = response.config.data?.method
            error_msg = if method then "In method '#{method}': #{error_msg}" else error_msg

        else if response.message
            error_msg = response.message

        console.log "RPC Server Error: #{error_msg.substring(0, 512)} (#{response.status})", response
        method_in_dont_report_list = method and (dont_report_methods.filter (x) ->
            x == method).length > 0
        #response.data.error.code!=0 is handled externally
        if !promise and !method_in_dont_report_list and response.data.error?.code != 0
            Shared.message = "RPC Server Error: " + error_msg.split("\n")[0]
        #Growl.error "RPC Server Error", "#{error_msg.substring(0,512)} (#{response.status})"
        return (if promise then promise else $q.reject(response))
