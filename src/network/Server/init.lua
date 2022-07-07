--[=[
    @class NetworkServer
    @server

    The server counterpart of the [network] module.
]=]

--[=[ 
    @prop RemoteProperty RemoteProperty
    @within NetworkServer
    @readonly
]=]

--[=[ 
    @prop RemoteProperty RemoteSignal
    @within NetworkServer
    @readonly
]=]

--[=[ 
    @prop NetworkServer Type 
    @within NetworkServer
    @readonly

    An exported Luau type of network.
]=]

--[=[
    @interface Middleware
    @within NetworkServer
    .methodCallInbound { (methodName: string, args: {any}) -> boolean}?
    .methodCallOutbound {(methodName: string, args: {any}, methodResponse: any) -> any}?

    Both `methodCallInbound` and `methodCallOutbound` must be an array of callbacks if specified. 

    ### `methodCallInbound` 

    Callbacks in `methodCallInbound` are called whenever a client tries to call any of the appended methods of the network. 

    The first argument passed to each callback is the name of the method (the client called), and the second argument, i.e 
    the arguments sent by the client, which are packed into an array. 
    
    ```lua
    local methodCallInboundCallbacks = {
        function (methodName, arguments)
            print(arguments[1]:IsA("Player")) --> true (the first argument is always the client)
            print(typeof(arguments)) --> "table"
        end
    }
    ---
    ```

    :::warning Yielding is not allowed
    Middleware callbacks aren't allowed to yield. If they do so, their thread will be closed and an error will be outputted, but
    other callbacks will not be affected.
    :::

    :::tip More control
    - If any of the callbacks return an **explicit** false value, then the method which the client tried to call, will *not* be
    called. This is useful as you can implement for e.g, implementing rate limits!

    - Additionally, you can modify the `arguments` table which will be reflected in the method, for e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local testNetwork = Network.Server.new("TestNetwork", {methodCallInbound = {
        function(_, arguments) 
            arguments[2] = "test"
        end
    }})
    testNetwork:append("method", function(player, a)
        print(a) --> "test" (a ought to be 1, but the middleware modified it!)
    end)
    testNetwork:dispatch(Workspace)

    -- Client
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.client.fromParent("TestNetwork", Workspace):expect()
    estNetwork.method(1) 
    ```
    :::

    ### `methodCallOutbound` 

    Callbacks in `methodCallOutbound` are called whenever a method (appended to the network) is called by the client, and 
    has **finished** running.  

    The first argument passed to each callback is the name of the method (client called), and the second argument, i.e 
    the arguments sent by the client, which are packed into an array. 

    ```lua
    local methodCallOutboundCallbacks = {
        function (methodName, arguments)
            print(arguments[1]:IsA("Player")) --> true (the first argument is always the client)
            print(typeof(arguments)) --> "table"
        end
    }
    ---
    ```

    :::warning Yielding is not allowed
    Middleware callbacks aren't allowed to yield. If they do so, their thread will be closed and an error will be outputted, but
    other callbacks will not be affected.
    :::
    
    :::tip Additional `methodResponse` argument
    A third argument i.e `methodResponse` is passed to each callback as well, which is just the response of the method called. For e.g:

    ```lua
    -- Server:
    local Workspace = game:GetService("Workspace")

    local middleware = {
        methodCallOutbound = {
            {
                function (methodName, arguments, methodResponse)
                    print(methodResponse) --> "this"
                    return "oops modified"
                end
            }
        }
    }

    local testNetwork = network.Server.new("TestNetwork", middleware)
    testNetwork:append("someMethod", function()
        return "this"
    end)
    testNetwork:dispatch(Workspace)

    -- Client:
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.client.fromParent("testNetwork", Workspace):expect()
    print(testNetwork.someMethod()) --> "oops modified" (ought to be "this" instead but modified by a middleware!)
    ```

    Additionally, these callbacks can return a value that overrides the actual result of the method (which will be sent
    back to the client). For e.g:

    ```lua
    -- Server:
    local Workspace = game:GetService("Workspace")

    local middleware = {
        {
            function (methodName, arguments, methodResponse)
                print(methodResponse) --> "this"
                return 50
            end
        }
    }

    local testNetwork = network.Server.new("TestNetwork", middleware)
    testNetwork:append("someMethod", function()
        return "this"
    end)
    testNetwork:dispatch(Workspace)

    -- Client:
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.fromParent("TestNetwork", Workspace):expect()
    print(testNetwork.someMethod()) --> 50 
    ```

    Additionally, if more than 1 callback returns a value, then all those returned values will be packed into an array and *then* sent
    back to the client. This is by design, as it isn't ideal to disregard all returned values for just 1.
    
    For e.g: 
    
    ```lua
    -- Server:
    local Workspace = game:GetService("Workspace")

    local middleware = {
        {
            function (methodName, arguments, response)
                return 1
            end,

            function (methodName, arguments, response)
                return 2
            end,

            function (methodName, arguments, response)
                return 3
            end
        }
    }

    local testNetwork = network.server.new("TestNetwork", middleware)
    testNetwork:append("someMethod", function()
        return "this"
    end)
    testNetwork:dispatch(Workspace)

    -- Client:
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.client.fromParent("TestNetwork", Workspace):expect()
    print(testNetwork.someMethod()) --> {1, 2, 3} 
    ```
    :::
]=]

local packages = script.Parent.Parent
local utilities = script.Parent.utilities

local SharedConstants = require(script.Parent.SharedConstants)
local RemoteSignal = require(script.RemoteSignal)
local RemoteProperty = require(script.RemoteProperty)
local tableUtil = require(utilities.tableUtil)
local networkUtil = require(utilities.networkUtil)
local Janitor = require(packages.Janitor)
local t = require(packages.t)

local DEFAULT_MIDDLEWARE = {
	methodCallOutbound = {},
	methodCallInbound = {},
}

local MiddlewareInterface = t.optional(t.strictInterface({
	methodCallInbound = t.optional(t.array(t.optional(t.callback))),
	methodCallOutbound = t.optional(t.array(t.optional(t.callback))),
}))

local NetworkServer = {
	RemoteProperty = require(script.RemoteProperty),
	RemoteSignal = require(script.RemoteSignal),
	__index = {},
}

type Middleware = {
	methodCallOutbound: { (methodName: string, args: { any }, methodResponse: any) -> any }?,
	methodCallInbound: { (methodName: string, args: { any }) -> boolean }?,
}

export type NetworkServer = typeof(setmetatable(
	{} :: {
		_name: string,
		_janitor: any,
		_middleware: Middleware,
	},
	NetworkServer
))

local function getDefaultMiddleware()
	return tableUtil.deepCopy(DEFAULT_MIDDLEWARE)
end

--[=[
    @param middleware Middleware?
    @return NetworkServer

    Creates and returns a new network object of the name i.e `name`. 
    
    :::note Precaution!
    The network object will initially not be accessible to the client. You need to call [NetworkServer:dispatch] 
    to render the network object accessible to the client!
    :::
]=]

function NetworkServer.new(name: string, middleware: Middleware?): NetworkServer
	assert(t.string(name))
	assert(t.optional(t.table)(middleware))

	if middleware then
		assert(MiddlewareInterface(middleware))
	end

	middleware = tableUtil.reconcileDeep(middleware or getDefaultMiddleware(), DEFAULT_MIDDLEWARE)

	local self = setmetatable({
		_name = name,
		_janitor = Janitor.new(),
		_middleware = middleware,
	}, NetworkServer)

	self:_init()
	return self
end

--[=[
    Returns a boolean indicating if `self` is a network object or not.
]=]

function NetworkServer.is(self: any): boolean
	return getmetatable(self) == NetworkServer
end

--[=[
    Returns a boolean indicating if the network object is dispatched to the 
    client or not. 

    :::note Precaution!
    This method will always return false if the network object is destroyed.
    :::
]=]

function NetworkServer.__index:isDispatched(): boolean
	return self._networkFolder.Parent ~= nil
end

--[=[
    @param value any

    Appends a key-value pair, `key` and `value`, to the network object, so that
    it is available to the client once the network object is dispatched. 

    For e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local testNetwork = Network.Server.new("TestNetwork")
    testNetwork:append("key", "the value!")
    testNetwork:dispatch(Workspace)

    -- Client
    local testNetwork = Network.client.fromParent("TestNetwork", Workspace):expect()
    print(testNetwork.key) --> "the value!"
    ```

    :::tip More support
    You can also append a [RemoteSignal] and a [RemoteProperty] as well, they'll be represented as a [ClientRemoteSignal] and a [ClientRemoteProperty]
    to the client respectively!
    ::: 

    :::note Precaution!
    [Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
    apply, as remote functions are internally used the key-value pairs accessible to the clients.
    :::

    :::warning
    This method will error if the network object is dispatched to the client. 
    Always make sure to append keys and values *before* you dispatch the 
    network object. You can check if a network object is dispatched to the 
    client or not through [NetworkServer:dispatched].
    :::
]=]

function NetworkServer.__index:append(key: string, value: any)
	assert(not self:isDispatched(), "Cannot append key value pair as network object is dispatched to the client!")
	assert(t.string(key))

	self:_setup(key, value)
end

--[=[
    Dispatches the network folder of the network object to `parent`, rendering
    the network object accessible to the client now.

    :::warning
    If another network object of the same name as this network object is already
    dispatched to `parent`, then this method will error - you can't have more than 
    1 network object of the same name dispatched to the same instance!
    :::
]=]

function NetworkServer.__index:dispatch(parent: Instance)
	assert(t.Instance(parent))
	assert(t.children({ [self._name] = t.none })(parent))

	self._networkFolder.Parent = parent
end

--[=[
    Destroys the network object and all appended remote properties &
    remote signals within the network object, and renders the network 
    object useless. 
]=]

function NetworkServer.__index:destroy()
	self._janitor:Destroy()
end

function NetworkServer.__index:_setupRemoteObject(
	key: string,
	value: RemoteProperty.RemoteProperty | RemoteSignal.RemoteSignal
)
	value:dispatch(key, self._networkFolder)

	self._janitor:Add(function()
		-- Destroy the remote property or remote signal if it already isn't
		-- destroyed yet, to avoid memory leaks:
		if not RemoteProperty.is(value) or not RemoteSignal.is(value) then
			return
		end

		value:destroy()
	end)
end

function NetworkServer.__index:_setup(key: string, value: any)
	if RemoteSignal.is(value) or RemoteProperty.is(value) then
		self:_setupRemoteObject(key, value)
		return
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = key
	remoteFunction:SetAttribute("valueType", typeof(value))
	remoteFunction.Parent = self._networkFolder

	function remoteFunction.OnServerInvoke(...)
		local args = { ... }

		if typeof(value) == "function" then
			local methodCallInboundMiddlewareAccumulatedResponses =
				networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(self._middleware.methodCallInbound, key, args)

			-- If there is an explicit false value included in the accumulated
			-- the response of all inbound method callbacks, then that means we should
			-- avoid this client's request to call the method!
			if
				methodCallInboundMiddlewareAccumulatedResponses
				and table.find(methodCallInboundMiddlewareAccumulatedResponses, false)
			then
				return
			end

			local methodResponse = value(table.unpack(args))
			local methodCallOutboundMiddlewareAccumulatedResponses = networkUtil.truncateAccumulatedResponses(
				networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(
					self._middleware.methodCallOutbound,
					key,
					args,
					methodResponse
				)
			)

			return if methodCallOutboundMiddlewareAccumulatedResponses ~= nil
				then methodCallOutboundMiddlewareAccumulatedResponses
				else methodResponse
		else
			return value
		end
	end

	self._janitor:Add(function()
		remoteFunction.OnServerInvoke = nil
		remoteFunction:Destroy()
	end)
end

function NetworkServer.__index:_init()
	self:_setupNetworkFolder()

	self._janitor:Add(function()
		setmetatable(self, nil)
	end)
end

function NetworkServer.__index:_setupNetworkFolder()
	local networkFolder = self._janitor:Add(Instance.new("Folder"))
	networkFolder.Name = self._name
	networkFolder:SetAttribute(SharedConstants.attribute.networkFolder, true)
	self._networkFolder = networkFolder
end

return table.freeze(NetworkServer)
