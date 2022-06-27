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

	An exported Luau type of a remote property object.
]=]

--[=[
	@interface Middleware
	@within RemoteProperty
	.clientGet: { (client: Player) -> any }?,
	.clientSet: { (client: Player, value: any) -> any }?,
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

type Middleware = {
	clientGet: { (client: Player) -> any }?,
	clientSet: { (client: Player, value: any) -> any }?,
}

local RemoteProperty = {
	__index = {},
	_clients = trackerUtil.getTrackingPlayers(),
}

local function getDefaultMiddleware()
	return tableUtil.deepCopy(MIDDLEWARE_TEMPLATE)
end

--[=[
	@return RemoteProperty
	@param middleware Middleware

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

	Sets a value of the remote property for every client in `clients` table, *specifically*, to `value`. 
]=]

function RemoteProperty.__index:setForClients(clients: { Player }, value: any)
	for _, client in clients do
		self:setForClient(client, value)
	end
end

--[=[
	@tag RemoteProperty instance

	Sets a value of the remote property for `client` *specifically*, to `value`. 
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

	Removes the value of the remote property stored *specifically* for every client in `clients` table.
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

return table.freeze(RemoteProperty)
