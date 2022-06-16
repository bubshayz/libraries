--[=[
	@class RemoteProperty

	A remote property in layman's terms is simply an  object which can store in some value for 
	all players as well as store in values specific to players. 
	
	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	do apply since remote functions are internally used by remote properties to store in values and replicate them to clients
	(which they can access through client remote properties)  respectively.
	:::
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
	@prop clientValueUpdated Signal <player: Player, newValue: any>
	@within RemoteProperty
	@readonly
	@tag Signal
	@tag RemoteProperty Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value 
	of `player` specifically in the remote property is set to a new one. The signal is passed the player 
	as the first argument, and the new specific value of `player` set in the remote property as the second argument. 
]=]

--[=[ 
	@prop RemoteProperty Type 
	@within RemoteProperty
	@tag Luau Type
	@readonly

	An exported Luau type of a remote property object.
]=]

local Players = game:GetService("Players")

local Packages = script.Parent.Parent.Parent
local Network = script.Parent.Parent

local SharedConstants = require(Network.SharedConstants)
local Janitor = require(Packages.Janitor)
local Signal = require(Packages.Signal)
local Property = require(Packages.Property)

local RemoteProperty = { __index = {} }

local function isPlayer(player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

local function safeInvokeClient(remoteFunction: RemoteFunction, player: Player, value: any)
	task.spawn(function()
		pcall(remoteFunction.InvokeClient, remoteFunction, player, value)
	end)
end

--[=[
	@return RemoteProperty

	Creates and returns a new remote property of the value `initialValue`.
]=]

function RemoteProperty.new(initialValue: any)
	local property = Property.new(initialValue)
	local self = setmetatable({
		updated = property.updated,
		clientValueUpdated = Signal.new(),
		_property = property,
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
	assert(
		typeof(clients) == "table",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:setForClients",
			"table",
			typeof(clients)
		)
	)

	for _, client in clients do
		self:setForClient(client, value)
	end
end

--[=[
	@tag RemoteProperty instance

	Sets a value of the remote property for `client` *specifically*, to `value`. 
]=]

function RemoteProperty.__index:setForClient(client: Player, value: any)
	assert(
		isPlayer(client),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:setForClient",
			"Player",
			typeof(client)
		)
	)

	local clientProperty = self:_getClientProperty(client)
	clientProperty:set(value)
end

--[=[
	@tag RemoteProperty instance

	Removes the value stored for `client` *specifically* in the the remote property.
]=]

function RemoteProperty.__index:removeForClient(client: Player)
	assert(
		isPlayer(client),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:removeForClient",
			"Player",
			typeof(client)
		)
	)

	if not self._clientProperties[client] then
		return
	end

	self._clientProperties[client]:Destroy()
	self._clientProperties[client] = nil

	-- Send the current value of the remote property back to the client so that
	-- the client can recieve the update of their new value:
	safeInvokeClient(self._valueDispatcherRemoteFunction, client, self:get())
end

--[=[
	@tag RemoteProperty instance

	Removes the value of the remote property stored *specifically* for every client in `clients` table.
]=]

function RemoteProperty.__index:removeForClients(clients: { Player })
	assert(
		typeof(clients) == "table",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:removeForClients",
			"table",
			typeof(clients)
		)
	)

	for _, client in clients do
		self:removeForClient(client)
	end
end

--[=[
	@tag RemoteProperty instance

	Returns a boolean indicating if there is a specific value stored for `client` 
	in the remote property.
]=]

function RemoteProperty.__index:hasClientSet(client: Player): boolean
	assert(
		isPlayer(client),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:hasClientSet",
			"Player",
			typeof(client)
		)
	)

	return self._clientProperties[client] ~= nil
end

--[=[
	@tag RemoteProperty instance

	Returns the value stored *specifically* for `client` in the remote property. 
]=]

function RemoteProperty.__index:getForClient(client: Player): any
	assert(
		isPlayer(client),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:getForClient",
			"Player",
			typeof(client)
		)
	)

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
	valueDispatcherRemoteFunction:SetAttribute(SharedConstants.Attribute.BoundToRemoteProperty, true)
	valueDispatcherRemoteFunction.Parent = parent

	function valueDispatcherRemoteFunction.OnServerInvoke(client)
		return if self:hasClientSet(client) then self:getForClient(client) else self:get()
	end

	-- Send off the new value to the current players in game:
	self._property.updated:Connect(function(newValue)
		for _, client in RemoteProperty._clients do
			if self:hasClientSet(client) then
				-- We must not send this new value to this player as it is not needed.
				continue
			end

			safeInvokeClient(self._valueDispatcherRemoteFunction, client, newValue)
		end
	end)

	self._janitor:Add(function()
		valueDispatcherRemoteFunction.OnServerInvoke = nil
		valueDispatcherRemoteFunction:Destroy()
	end)

	self._valueDispatcherRemoteFunction = valueDispatcherRemoteFunction
end

function RemoteProperty.__index:_getClientProperty(client: Player): Property.Property
	if self._clientProperties[client] then
		return self._clientProperties[client]
	end

	local property = Property.new()

	property.updated:Connect(function(newValue)
		self.clientValueUpdated:Fire(client, newValue)

		if not client:IsDescendantOf(Players) then
			return
		end

		safeInvokeClient(self._valueDispatcherRemoteFunction, client, newValue)
	end)

	self._clientProperties[client] = property
	return property
end

function RemoteProperty.__index:_init()
	self._janitor:Add(self.clientValueUpdated)
	self._janitor:Add(self._property, "destroy")
	self._janitor:Add(function()
		for _, property in self._clientProperties do
			property:Destroy()
		end

		setmetatable(self, nil)
	end)
end

function RemoteProperty:__tostring()
	return ("[RemoteProperty]: (%s)"):format(self._valueDispatcherRemoteFunction.Name)
end

function RemoteProperty._startTrackingPlayers()
	RemoteProperty._clients = Players:GetPlayers()

	Players.PlayerAdded:Connect(function(client)
		table.insert(RemoteProperty._clients, client)
	end)

	Players.PlayerRemoving:Connect(function(client)
		table.remove(RemoteProperty._clients, table.find(RemoteProperty._clients, client))
	end)
end

RemoteProperty._startTrackingPlayers()

export type RemoteProperty = typeof(setmetatable(
	{} :: {
		updated: any,
		clientValueUpdated: any,
		_property: Property.Property,
		_valueDispatcherRemoteFunction: RemoteFunction?,
		_clientProperties: {},
		_janitor: any,
	},
	RemoteProperty
))

return table.freeze(RemoteProperty)
