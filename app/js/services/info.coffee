class Info
    info : {}

    symbol : ""

    is_refreshing : false

    get : () ->
        if Object.keys(@info).length > 0
            deferred = @q.defer()
            deferred.resolve(@info)
            return deferred.promise
        else
            @refresh_info().then ()=>
                @info

    refresh_info : () ->
        @is_refreshing = true
        @common_api.get_info().then (data) =>
                @is_refreshing = false
                #console.log "watch_for_updates get_info:>", data
                if data.blockchain_head_block_num > 0
                    @info.network_connections = data.network_num_connections
                    @info.wallet_open = data.wallet_open
                    @info.wallet_unlocked = data.wallet_unlocked
                    @info.last_block_time = data.blockchain_head_block_timestamp
                    @info.last_block_num = data.blockchain_head_block_num
                    @info.blockchain_head_block_age = data.blockchain_head_block_age
                    @info.income_per_block = data.blockchain_delegate_pay_rate
                    @info.share_supply = data.blockchain_share_supply
                    @info.blockchain_delegate_pay_rate = data.blockchain_delegate_pay_rate
                else
                    @info.wallet_unlocked = data.wallet_unlocked

                @blockchain_api.get_security_state().then (data) =>
                    @info.alert_level = data.alert_level

                @common_api.get_config().then (data) =>
                    @info.delegate_reg_fee = data.delegate_reg_fee
                    @info.asset_reg_fee = data.asset_reg_fee
                    @info.priority_fee = data.priority_fee
            , =>
                @is_refreshing = false
                @info.network_connections = 0
                @info.wallet_open = false
                @info.wallet_unlocked = false
                @info.last_block_num = 0

    watch_for_updates: =>
        @interval (=>
            if !@is_refreshing
                @refresh_info()
        ), 5000

    constructor: (@q, @log, @location, @growl, @common_api, @blockchain, @blockchain_api, @interval) ->
        @watch_for_updates()
        @blockchain.get_config().then (config)->
            # TODO: using this have the risk of defferred object not init yet, need to make sure it is inited
            @symbol = config.symbol

angular.module("app").service("Info", ["$q", "$log", "$location", "Growl", "CommonAPI", "Blockchain", "BlockchainAPI", "$interval", Info])
