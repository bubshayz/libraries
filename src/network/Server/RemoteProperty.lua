--[=[
	@class RemoteProperty

	A remote property in layman's terms is simply an  object which can store in some value for 
	all players as well as store in values specific to players. 
]=]

--[=[ 
	@prop updated Signal <newValue: any>
	@within RemoteProperty
	@readonly
	@tag Signal
	@tag RemoteProperty Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value 
	of the remote property is set to a new one. The signal is only passed the new value as the only argument.
]=]

--[=[ 
	@prop clientValueUpdated Signal <client: Player, newValue: any>
	@within RemoteProperty
	@readonly
	@tag Signal
	@tag RemoteProperty Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value 
	of `player` specifically in the remote property is set to a new one. The signal is passed the player 
	as the first argument, and the new specific value of `player` set in the remote property, as the second argument. 
]=]

--[=[ 
	@prop RemoteProperty Type 
	@within RemoteProperty
	@readonly

	An exported Luau type of a remote property.
]=]

--[=[
	@interface Middleware
	@within RemoteProperty
	.clientGet { (client: Player) -> any }?,
	.clientSet { (client: Player, value: any) -> any }?,

	Both `clientGet` and `clientSet` must be array of callbacks (if specified).

	### `clientGet` 

	Callbacks in `clientGet` are called whenever the client tries to retrieve the value of the remote property
	(or the value stored for them specifically in the remote property).

	The first and *only* argument passed to each callback is just the client. 

	```lua
	local clientGetCallbacks = {
		function (client)
			print(client:IsA("Player")) --> true 
		end
	}
	---
	```

	:::tip
	A callback can return a non-nil value, which will then be returned back to the client instead of the value
	of the remote property (or the value stored for the client specifically in the remote property). This is useful
	in cases where you want to have more control over the networking layer of remote properties. 
	
	For e.g:

	```lua
	-- Server
	local Network = require(...)

	local TestRemoteProperty = Network.RemoteProperty.new(50, {
		clientGet = {function() return "rickrolled" end}
	})

	local TestNetwork = Network.new("Test")
	TestNetwork:append("property", TestRemoteProperty)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...)

	local TestNetwork = network.fromParent("Test", workspace):expect()
	print(TestNetwork.property:get()) --> "rickrolled" (This ought to return 50, but the middleware returned a custom value!)
	```

	Additionaly, if more than 1 callback returns a value, then all those returned values will be packed into an array and *then* sent
	back to the client. This is by design - as it isn't really ideal to disregard all returned values for just 1. 
	
	For e.g:

	```lua
	-- Server
	local Network = require(...)

	local TestRemoteProperty = Network.RemoteProperty.new(50, {
		clientGet = {
			function() return "rickrolled" end,
			function() return "oof" end,
			function() return "hello" end
		}
	})

	local TestNetwork = Network.new("Test")
	TestNetwork:append("property", TestRemoteProperty)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...)

	local TestNetwork = network.fromParent("Test", workspace):expect()
	print(TestNetwork.property:get()) --> {"oofed", "rickrolled", "hello"}
	```
	:::

	### clientSet

	Callbacks in `clientSet` are called whenever the client tries to set the value of the remote property
	*for them selves specifically*.

	The first and *only* argument passed to each callback is just the client. 

	```lua
	local clientSetCallbacks = {
		function (client)
			print(client:IsA("Player")) --> true 
		end
	}
	---
	```

	:::tip
	A callback can return a non-nil value, which will then be set as the value for the client in the remote property.
	This is useful in cases where you want to have more control over what values the client can set for them in the remote
	property.
	
	For e.g:

	```lua
	-- Server
	local Network = require(...)

	local TestRemoteProperty = Network.RemoteProperty.new(50, {
		clientSet = {function() return "set lol" end}
	})

	local TestNetwork = Network.new("Test")
	TestNetwork:append("property", TestRemoteProperty)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...)

	local TestNetwork = network.fromParent("Test", workspace):expect()
	print(TestNetwork.property:get()) --> "rickrolled" (this ought to return 50, but the middleware returned a custom value!)
	```

	Additionaly, if more than 1 callback returns a value, then all those returned values will be packed into an array and *then* sent
	back to the client. This is by design - as it isn't really ideal to disregard all returned values for just 1. 
	
	For e.g:

	```lua
	-- Server
	local Network = require(...)

	local TestRemoteProperty = Network.RemoteProperty.new(50, {
		clientGet = {
			function() return "rickrolled" end,
			function() return "oof" end,
			function() return "hello" end
		}
	})

	local TestNetwork = Network.new("Test")
	TestNetwork:append("property", TestRemoteProperty)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...)

	local TestNetwork = network.fromParent("Test", workspace):expect()
	print(TestNetwork.property:get()) --> {"oofed", "rickrolled", "hello"}
	```
	:::
]=]

local Players = game:GetService("Players")

local network = script.Parent.Parent
local packages = network.Parent

local SharedConstants = require(network.SharedConstants)
local Janitor = require(packages.Janitor)
local Signal = require(packages.Signal)
local Property = require(packages.Property)
local t = require(packages.t)
local tableUtil = require(network.utilities.tableUtil)
local networkUtil = require(network.utilities.networkUtil)
local trackerUtil = require(network.utilities.trackerUtil)

local MIDDLEWARE_TEMPLATE = {
	clientGet = {},
	clientSet = {},
}

local MiddlewareInterface = t.optional(t.strictInterface({
	clientGet = t.optional(t.array(t.callback)),
	clientSet = t.optional(t.array(t.callback)),
}))

local RemoteProperty = {
	__index = {},
	_clients = trackerUtil.getTrackingPlayers(),
}

type Middleware = {
	clientGet: { (client: Player) -> any }?,
	clientSet: { (client: Player, value: any) -> any }?,
}
export type RemoteProperty = typeof(setmetatable(
	{} :: {
		updated: any,
		clientValueUpdated: any,
		_property: Property.Property,
		_valueDispatcherRemoteFunction: RemoteFunction,
		_clientProperties: { [Player]: Property.Property },
		_janitor: any,
		_middeware: Middleware,
	},
	RemoteProperty
))

local function getDefaultMiddleware()
	return tableUtil.deepCopy(MIDDLEWARE_TEMPLATE)
end

--[=[
	@return RemoteProperty
	@param middleware Middleware?

	Creates and returns a new remote property with the value of `initialValue`.
]=]

function RemoteProperty.new(initialValue: any, middleware: Middleware?)
	assert(t.optional(t.table)(middleware))

	if middleware then
		assert(MiddlewareInterface(middleware))
	end

	middleware = tableUtil.reconcileDeep(middleware or getDefaultMiddleware(), MIDDLEWARE_TEMPLATE)

	local property = Property.new(initialValue)
	local self = setmetatable({
		updated = property.updated,
		clientValueUpdated = Signal.new(),
		_property = property,
		_middleware = middleware,
		_clientProperties = {},
		_janitor = Janitor.new(),
	}, RemoteProperty)

	self:_init()
	return self
end

--[=[
	Returns a boolean indicating if `self` is a remote property or not.
]=]

function RemoteProperty.is(self: any): boolean
	return getmetatable(self) == RemoteProperty
end

--[=[
	@tag RemoteProperty instance

	Returns the current value set for the remote property.
]=]

function RemoteProperty.__index:get(): any
	return self._property:get()
end

--[=[
	@tag RemoteProperty instance

	Calls [RemoteProperty:setForClient] for all clients in `clients`.
]=]

function RemoteProperty.__index:setForClients(clients: { Player }, value: any)
	for _, client in clients do
		self:setForClient(client, value)
	end
end

--[=[
	@tag RemoteProperty instance

	Sets a value of the remote property for `client` *specifically*, to `value`. 
		
	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	apply, as remote functions are internally used to render `value` accessible to the respective clients.
	:::
]=]

function RemoteProperty.__index:setForClient(client: Player, value: any)
	assert(t.instanceOf("Player")(client))

	local clientProperty = self:_getClientProperty(client)
	clientProperty:set(value)
end

--[=[
	@tag RemoteProperty instance

	Removes the value stored for `client` *specifically* in the the remote property.
]=]

function RemoteProperty.__index:removeForClient(client: Player)
	assert(t.instanceOf("Player")(client))

	if not self._clientProperties[client] then
		return
	end

	self._clientProperties[client]:destroy()
	self._clientProperties[client] = nil

	-- Send the current value of the remote property back to the client so that
	-- the client can recieve the update of their new value:
	networkUtil.safeInvokeClient(self._valueDispatcherRemoteFunction, client, self:get())
end

--[=[
	@tag RemoteProperty instance

	Calls [RemoteProperty:removeForClient] for all clients in the `clients` table.
]=]

function RemoteProperty.__index:removeForClients(clients: { Player })
	for _, client in clients do
		self:removeForClient(client)
	end
end

--[=[
	@tag RemoteProperty instance

	Returns a boolean indicating if there is a specific value stored for `client` 
	in the remote property.
]=]

function RemoteProperty.__index:clientHasValueSet(client: Player): boolean
	assert(t.instanceOf("Player")(client))

	return self._clientProperties[client] ~= nil
end

--[=[
	@tag RemoteProperty instance

	Returns the value stored *specifically* for `client` in the remote property. 
]=]

function RemoteProperty.__index:getForClient(client: Player): any
	assert(t.instanceOf("Player")(client))

	local clientProperty = self._clientProperties[client]
	return if clientProperty then clientProperty:get() else nil
end

--[=[
	@tag RemoteProperty instance

	Sets the value of the remote property to `value`, and so for all other 
	clients (who can access this value through a  client remote property), 
	who don't have a specific value for them stored in the remote property.

	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	apply, as remote functions are internally used to render `value` accessible to the respective clients.
	:::
]=]

function RemoteProperty.__index:set(value: any)
	self._property:set(value)
end

--[=[
	@tag RemoteProperty instance
	
	Destroys the remote property and renders it unusable.
]=]

function RemoteProperty.__index:destroy()
	self._janitor:Destroy()
end

--[=[
	@private
]=]

function RemoteProperty.__index:dispatch(name: string, parent: Instance)
	local valueDispatcherRemoteFunction = Instance.new("RemoteFunction")
	valueDispatcherRemoteFunction.Name = name
	valueDispatcherRemoteFunction:SetAttribute(
		SharedConstants.attribute.boundToRemoteProperty,
		true
	)
	valueDispatcherRemoteFunction.Parent = parent
	self._valueDispatcherRemoteFunction = valueDispatcherRemoteFunction

	self._janitor:Add(function()
		valueDispatcherRemoteFunction.OnServerInvoke = nil
		valueDispatcherRemoteFunction:Destroy()
	end)

	function valueDispatcherRemoteFunction.OnServerInvoke(client, setData)
		-- If the client has sent a set data, then that means they want to set
		-- their value specifically in the remote property, so let's do that:
		if typeof(setData) == "table" then
			local clientSetMiddlewareAccumulatedResponses =
				networkUtil.truncateAccumulatedResponses(
					networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(
						self._middleware.clientSet,
						setData.value
					)
				)

			self:setForClient(
				client,
				if clientSetMiddlewareAccumulatedResponses ~= nil
					then clientSetMiddlewareAccumulatedResponses
					else setData.value
			)

			return nil
		end

		-- If there are accumulated responses from the middleware, return those instead. Else
		-- if the client has a specific value set for them, then return that. Lastly, return the current
		-- value of the remote property if the client has no specific value set for them!
		local clientGetMiddlewareAccumulatedResponses = networkUtil.truncateAccumulatedResponses(
			networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(
				self._middleware.clientGet,
				client
			)
		)

		return if clientGetMiddlewareAccumulatedResponses ~= nil
			then clientGetMiddlewareAccumulatedResponses
			elseif self:clientHasValueSet(client) then self:getForClient(client)
			else self:get()
	end

	-- Send off the new value to the current players in game:
	self._property.updated:Connect(function(newValue)
		for _, client in RemoteProperty._clients do
			if self:clientHasValueSet(client) then
				-- If the client already has a value set for them specifically,
				-- then we must not send this new value to them to avoid bugs.
				continue
			end

			networkUtil.safeInvokeClient(self._valueDispatcherRemoteFunction, client, newValue)
		end
	end)
end

function RemoteProperty.__index:_getClientProperty(client: Player): Property.Property
	if self._clientProperties[client] then
		return self._clientProperties[client]
	end

	local property = Property.new()

	property.updated:Connect(function(newValue)
		if not client:IsDescendantOf(Players) then
			return
		end

		self.clientValueUpdated:Fire(client, newValue)
		networkUtil.safeInvokeClient(self._valueDispatcherRemoteFunction, client, newValue)
	end)

	self._clientProperties[client] = property
	return property
end

function RemoteProperty.__index:_init()
	self._janitor:Add(self.clientValueUpdated)
	self._janitor:Add(self._property, "destroy")
	self._janitor:Add(function()
		for _, property in self._clientProperties do
			property:destroy()
		end

		setmetatable(self, nil)
	end)
end

function RemoteProperty:__tostring()
	return ("[RemoteProperty]: (%s)"):format(self._valueDispatcherRemoteFunction.Name)
end

return table.freeze(RemoteProperty)