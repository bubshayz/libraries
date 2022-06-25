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
	methodCallInbound = t.optional(t.strictInterface({ t.optional(t.callback) })),
	methodCallOutbound = t.optional(t.strictInterface({ t.optional(t.callback) })),
}))

--[=[
	@interface Middleware
	@within NetworkServer
	.methodCallInbound {(args: {...any}) -> boolean}?
	.methodCallOutbound {(args: {...any}) -> ()}?

	Both `methodCallInbound` and `methodCallOutbound` should be array of callbacks (if specified, none of them are required). 
	Callbacks in `Inbound` are known as "inbound callbacks" and are called whenever a client tries to call 
	a serverside method  (exposed through the network object). The first argument passed to each inbound 
	callback is the name of the method (the client called), and the arguments sent by the client (to that method)
	are packed into an array, which is then passed as the second argument. 
	
	```lua
	local inboundCallbacks = {
		function (methodName, arguments)
			print(arguments[1]:IsA("Player")) --> true (first argument is always the client)
			arguments[2] = "booooo" --> You can modify the arguments !
		end
	}
	---
	```

	:::tip Automatic method call rejection
	If any inbound callback returns an **explicit** false value, then the method (which the client tried to call) will *not* be
	called. This is good, e.g for implementing queues!
	:::

	Callbacks in `Outbound` are known as "outbound callbacks" and are called whenever a serverside method 
	(exposed through the network object) is called by the client, and has **finished**. The first argument passed to 
	each inbound callback is the name of the method (the client called), and the arguments sent by the client (to that method)
	are packed into an array, which is then passed as the second argument. 

	```lua
	local outboundCallbacks = {
		function (methodName, arguments)
			print(arguments[1]:IsA("Player")) --> true (first argument is always the client)
		end
	}
	---
	```

	:::tip 
	For outbound callbacks, an additional member in the arguments array, i.e `response` is injected automatically, which is 
	the response of the serverside method (which the client called). This means you can modify the response of the serverside method
	before it is returned back to the client, e.g:

	```lua
	-- Server:
	local Network = require(...)

	local middleware = {
		{
			function (methodName, arguments)
				arguments.response = "oops modified" 
			end
		}
	}
	local networkObject = Network.new("test", middleware)
	networkObject:append("SomeMethod", function()
		return "this"
	end)
	networkObject:dispatch(workspace)

	-- Client:
	local Network = require(...)

	local networkObject = Network.FromName("test", workspace):expect()
	print(networkObject.SomeMethod()) --> "oops modified" (ought to print "this")
	```
	:::
]=]

--[=[
	@class NetworkServer

	The server counterpart of the Network module.
]=]

local NetworkServer = {
	RemoteProperty = require(script.RemoteProperty),
	RemoteSignal = require(script.RemoteSignal),
	__index = {},
}

local function getDefaultMiddleware()
	return tableUtil.deepCopy(DEFAULT_MIDDLEWARE)
end

--[=[
	@param middleware Middleware?
	@return NetworkServer

	Creates and returns a new network object of the name i.e `name`. 
	
	Internally, a folder is created for each newly created network object, which
	too is named to `name`, but the folder it self is initially parented to `nil` 
	so the network object isn't available to the client - call [NetworkServer:Dispatch] 
	in order to render the network object accessible to the client.
]=]

function NetworkServer.new(
	name: string,
	middleware: {
		methodCallOutbound: { () -> () },
		methodCallInbound: { () -> boolean },
	}?
): NetworkServer
	assert(t.string(name))
	assert(t.optional(t.table)(middleware))

	if middleware then
		assert(MiddlewareInterface(middleware))
		middleware = tableUtil.reconcileDeep(middleware, DEFAULT_MIDDLEWARE)
	else
		middleware = getDefaultMiddleware()
	end

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

	:::note
	This method will always return false if the network object is destroyed.
	:::
]=]

function NetworkServer.__index:dispatched(): boolean
	return self._networkFolder.Parent ~= nil
end

--[=[
	@param value RemoteProperty | RemoteSignal | any

	Appends a key value pair, `key` and `value`, to the network object, so that
	it is available to the client once the network object is dispatched. 
	
	E.g:

	```lua
	-- Server
	local Network = require(...)

	local networkObject = Network.new("test")
	networkObject:append("key", "the value!")
	networkObject:dispatch(workspace)

	-- Client
	local networkObject = Network.fromServer("test", workspace):expect()
	print(networkObject.key) --> "the value!"
	```
		
	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	do apply since remote functions are internally used to replicate the appended
	key value pairs to the client.
	:::

	:::warning
	This method will error if the network object is dispatched to the client. 
	Always make sure to append keys and values *before* you dispatch the 
	network object. You can check if a network object is dispatched to the 
	client or not through [NetworkServer:dispatched].
	:::
]=]

function NetworkServer.__index:append(
	key: string,
	value: RemoteProperty.RemoteProperty | RemoteSignal.RemoteSignal | any
)
	assert(
		not self:dispatched(),
		"Cannot append key value pair as network object is dispatched to the client!"
	)
	assert(t.string(key))

	self:_setup(key, value)
end

--[=[
	Dispatches the network folder of the network object to `parent`, rendering
	the network object accessible to the client now.

	:::warning
	If another network object of the same name as this network object, is already
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
		if not RemoteProperty.is(value) or not RemoteProperty.is(value) then
			return
		end

		value:destroy()
	end)
end

function NetworkServer.__index:_setup(
	key: string,
	value: RemoteProperty.RemoteProperty | RemoteSignal.RemoteSignal | any
)
	if RemoteSignal.is(value) or RemoteProperty.is(value) then
		self:_setupRemoteObject(key, value)
		return
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = key
	remoteFunction:SetAttribute("ValueType", typeof(value))
	remoteFunction.Parent = self._networkFolder

	function remoteFunction.OnServerInvoke(...)
		if typeof(value) == "function" then
			local args = { ... }

			local methodCallOutboundMiddlewareAccumulatedResponses =
				networkUtil.truncateAccumulatedResponses(
					networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(
						self._middleware.methodCallOutbound,
						{ ... }
					)
				)

			-- If there is an explicit false value included in the accumulated
			-- response of all inbound method callbacks, then that means we should
			-- avoid this client's request to call the method!
			if
				methodCallOutboundMiddlewareAccumulatedResponses ~= nil
				and table.find(methodCallOutboundMiddlewareAccumulatedResponses, false)
			then
				return
			end

			local methodResponse = value(table.unpack(args))

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

function NetworkServer.__index:_getInboundMiddlewareResponse(...)
	for _, callback in self._middleware.inbound do
		local didRunSafely, callbackResponse = networkUtil.runCallbackNoYield(callback, ...)

		assert(
			didRunSafely,
			"middleware inbound callback yielded! Middleware inbound callbacks must never yield."
		)

		if callbackResponse == false then
			return false
		end
	end

	return true
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

export type NetworkServer = typeof(setmetatable(
	{} :: {
		_name: string,
		_parent: Instance,
		_janitor: any,
		_remotes: { RemoteSignal.RemoteSignal | RemoteProperty.RemoteProperty },
		_middleware: { Outbound: { () -> any? }, Inbound: { () -> any? } },
	},
	NetworkServer
))

return table.freeze(NetworkServer)
