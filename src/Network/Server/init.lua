--[=[
	@class NetworkServer

	The server counterpart of the Network module.
]=]

--[=[
	@interface Middleware
	@within NetworkServer
	.Inbound {(args: {...any}) -> ()}?
	.Outbound {(args: {...any}) -> ()}?

	Both `Inbound` and `Outbound` should be array of callbacks (if specified). Callbacks in `Inbound` are
	known as "inbound callbacks" and are called whenever a client tries to call a serverside method 
	(exposed through the network object). The arguments sent by the client (to the method which they called)
	are packed into an array, which is then passed to each callback as the only argument. 
	
	```lua
	local inboundCallbacks = {
		function (arguments)
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
	(exposed through the network object) is called by the client, and has **finished**. The arguments sent 
	by the client (to the method which they called) are packed into an array, which is then passed 
	to each callback as the only argument. 

	```lua
	local outboundCallbacks = {
		function (arguments)
			print(arguments[1]:IsA("Player")) --> true (first argument is always the client)
		end
	}
	---
	```

	:::tip Easy modification of the response sent to the client
	For outbound callbacks, an additional member in the arguments array, i.e `MethodResponse` is injected automatically, which is 
	the response of the serverside method. This means you may feel free to modify the response of the serverside method
	before it is returned back to the client, e.g:

	```lua
	-- Server:
	local Network = require(...)

	local middleware = {
		{
			function (arguments)
				arguments.MethodResponse = "oops modified" 
			end
		}
	}
	local networkObject = Network.new("test", middleware)
	networkObject:Dispatch(workspace)

	-- Client:
	local Network = require(...)

	local networkObject = Network.FromName("test", workspace):expect()
	print(networkObject.SomeMethod()) --> "oops modified"
	```
	:::
]=]

local packages = script.Parent.Parent
local ancestor = script.Parent

local Janitor = require(packages.Janitor)
local SharedConstants = require(ancestor.SharedConstants)
local RemoteSignal = require(script.RemoteSignal)
local RemoteProperty = require(script.RemoteProperty)

local NetworkServer = { __index = {} }

local function validateMiddleware(middleware)
	if not middleware then
		return { Inbound = {}, Outbound = {} }
	end

	if middleware.Inbound ~= nil then
		assert(typeof(middleware.Inbound) == "table", '"Inbound" member specified in middleware must be a table.')
	end

	if middleware.Outbound ~= nil then
		assert(typeof(middleware.Outbound) == "table", '"Outbound" member specified in middleware must be a table.')
	end

	for _, callback in middleware.Inbound do
		assert(typeof(callback) == "function", "Inbound table must be an array of functions only.")
	end

	for _, callback in middleware.Outbound do
		assert(typeof(callback) == "function", "Outbound table must be an array of functions only.")
	end
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
	middleware: { Outbound: { () -> any? }, Inbound: { () -> any? } }?
): NetworkServer
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "Network.new", "string", typeof(name))
	)
	assert(
		middleware == nil or typeof(middleware) == "table",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(2, "Network.new", "table or nil", typeof(middleware))
	)

	local self = setmetatable({
		_name = name,
		_janitor = Janitor.new(),
		_middleware = validateMiddleware(middleware),
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

function NetworkServer.__index:isDispatchedToClient(): boolean
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
	client or not through [NetworkServer:IsDispatchedToClient].
	:::
]=]

function NetworkServer.__index:append(
	key: string,
	value: RemoteProperty.RemoteProperty | RemoteSignal.RemoteSignal | any
)
	assert(
		not self:IsDispatchedToClient(),
		"Cannot append key value pair as network object is dispatched to the client!"
	)
	assert(
		typeof(key) == "string",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "Server:append", "string", typeof(key))
	)

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
	assert(
		typeof(parent) == "Instance",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "Network:dispatch", "Instance", typeof(parent))
	)

	for _, child in NetworkServer.parent:GetChildren() do
		assert(
			child.Name ~= self._name,
			('A network object "%s" is already dispatched to parent %s'):format(child.Name, parent:GetFullName())
		)
	end

	self._networkFolder.Parent = parent
end

--[=[
	Destroys the network object and all appended remote properties / 
	remote signals within the network object, and renders the network 
	object useless. 
]=]

function NetworkServer.__index:destroy()
	self._janitor:Destroy()
end

function NetworkServer.__index:_setup(
	key: string,
	value: RemoteProperty.RemoteProperty | RemoteSignal.RemoteSignal | any
)
	if RemoteSignal.IsA(value) or RemoteProperty.IsA(value) then
		value:Dispatch(key, self._networkFolder)

		self._janitor:Add(function()
			-- Destroy the remote property or remote signal if it already
			-- isn't destroyed yet,  to prevent memory leaks:
			if not (RemoteSignal.is(value) or RemoteProperty.is(value)) then
				return
			end

			value:destroy()
		end)

		return
	end

	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = key
	remoteFunction:SetAttribute("ValueType", typeof(value))
	remoteFunction.Parent = self._networkFolder

	function remoteFunction.OnServerInvoke(...)
		if typeof(value) == "function" then
			local args = { ... }

			if self:_getInboundMiddlewareResponse(args) == false then
				return nil
			end

			args.MethodResponse = value(table.unpack(args))
			self:_runOutboundMiddlewareCallbacks(args)
			return args.MethodResponse
		else
			return value
		end
	end

	self._janitor:Add(function()
		remoteFunction.OnServerInvoke = nil
		remoteFunction:Destroy()
	end)
end

function NetworkServer.__index:_runOutboundMiddlewareCallbacks(...)
	for _, outBoundCallback in self._middleware.Outbound do
		outBoundCallback(...)
	end
end

function NetworkServer.__index:_getInboundMiddlewareResponse(...)
	for _, inBoundCallback in self._middleware.Inbound do
		if inBoundCallback(...) == false then
			return false
		end
	end
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
	networkFolder:SetAttribute(SharedConstants.Attribute.NetworkFolder, true)
	self._networkFolder = networkFolder
end

function NetworkServer._init()
	for _, module in script:GetChildren() do
		NetworkServer[module.Name] = require(module)
	end
end

NetworkServer._init()

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
