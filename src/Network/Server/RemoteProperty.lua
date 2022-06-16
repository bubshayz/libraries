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
	@prop Updated Signal <newValue: any>
	@within RemoteProperty
	@readonly
	@tag Signal
	@tag RemoteProperty Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value 
	of the remote property is set to a new one. The signal is only passed the new value as the only argument.
]=]

--[=[ 
	@prop PlayerValueUpdated Signal <player: Player, newValue: any>
	@within RemoteProperty
	@readonly
	@tag Signal
	@tag RemoteProperty Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the value 
	of `player` specifically in the remote property is set to a new one. The signal is passed the player 
	as the first argument, and the new specific value of `player` set in the remote property as the second argument. 
]=]

local Players = game:GetService("Players")

local packages = script.Parent.Parent.Parent
local ancestor = script.Parent.Parent

local SharedConstants = require(ancestor.SharedConstants)
local Janitor = require(packages.Janitor)
local Signal = require(packages.Signal)
local Property = require(packages.Property)

local RemoteProperty = { __index = {} }

local function SafeInvokeClient(remoteFunction: RemoteFunction, player: Player, value: any)
	--[[
		From the Developer Hub:
		
		If a client disconnects or leaves the game while it is being invoked from the server, the InvokeClient function will error. 
		It is therefore recommended to wrap this function in a pcall so it doesn’t stop the execution of other code.
	]]

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
		updated = property.Updated,
		playerValueUpdated = Signal.new(),
		_property = property,
		_playerProperties = {},
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
	return self._property:Get()
end

--[=[
	@tag RemoteProperty instance

	Sets a value of the remote property for `player` **specifically**, to `value`. 
]=]

function RemoteProperty.__index:setForPlayer(player: Player, value: any)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "RemoteProperty:SetForPlayer", "Player", typeof(player))
	)

	local playerProperty = self:_getPlayerProperty(player)
	playerProperty:Set(value)
end

--[=[
	@tag RemoteProperty instance

	Removes the value stored for `player` **specifically** in the the remote property.
]=]

function RemoteProperty.__index:removeForPlayer(player: Player)
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "RemoteProperty:RemoveForPlayer", "Player", typeof(player))
	)

	if not self._playerProperties[player] then
		return
	end

	self._playerProperties[player]:Destroy()
	self._playerProperties[player] = nil

	-- Send the current value of the remote property back to the client so that
	-- the client can recieve the update of their new value:
	SafeInvokeClient(self._valueDispatcherRemoteFunction, player, self:Get())
end

--[=[
	@tag RemoteProperty instance

	Returns a boolean indicating if there is a specific value stored for `player` 
	in the remote property.
]=]

function RemoteProperty.__index:hasPlayerSpecificValueSet(player: Player): boolean
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(
			1,
			"RemoteProperty:HasPlayerSpecificValueSet",
			"Player",
			typeof(player)
		)
	)

	return self._playerProperties[player] ~= nil
end

--[=[
	@tag RemoteProperty instance

	Returns the value stored *specifically* for `player` in the remote property. 
]=]

function RemoteProperty.__index:GetForPlayer(player: Player): any
	assert(
		typeof(player) == "Instance" and player:IsA("Player"),
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "RemoteProperty:GetForPlayer", "Player", typeof(player))
	)

	local playerProperty = self._playerProperties[player]
	return if playerProperty then playerProperty:Get() else nil
end

--[=[
	@tag RemoteProperty instance

	Sets the value of the remote property to `value`, and so for all other 
	clients (who can access this value through a  client remote property), 
	who don't have a specific value for them stored in the remote property.
]=]

function RemoteProperty.__index:Set(value: any)
	self._property:Set(value)
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

	function valueDispatcherRemoteFunction.OnServerInvoke(player)
		return if self:HasPlayerSpecificValueSet(player) then self:GetForPlayer(player) else self._property:Get()
	end

	-- Send off the new value to the current players in game:
	self._property.updated:Connect(function(newValue)
		for _, player in RemoteProperty._players do
			if self:HasPlayerSpecificValueSet(player) then
				-- We must not send this new value to this player as it is not needed.
				continue
			end

			SafeInvokeClient(self._valueDispatcherRemoteFunction, player, newValue)
		end
	end)

	self._janitor:Add(function()
		valueDispatcherRemoteFunction.OnServerInvoke = nil
		valueDispatcherRemoteFunction:Destroy()
	end)

	self._valueDispatcherRemoteFunction = valueDispatcherRemoteFunction
end

function RemoteProperty.__index:_getPlayerProperty(player: Player): Property.Property
	if self._playerProperties[player] then
		return self._playerProperties[player]
	end

	local property = Property.new()

	property.updated:Connect(function(newValue)
		self.playerValueUpdated:Fire(player, newValue)

		if not player:IsDescendantOf(Players) then
			return
		end

		SafeInvokeClient(self._valueDispatcherRemoteFunction, player, newValue)
	end)

	self._playerProperties[player] = property
	return property
end

function RemoteProperty.__index:_init()
	self._janitor:Add(self.PlayerValueUpdated)
	self._janitor:Add(self._property)
	self._janitor:Add(function()
		for _, property in self._playerProperties do
			property:Destroy()
		end

		setmetatable(self, nil)
	end)
end

function RemoteProperty._startTrackingPlayers()
	RemoteProperty._players = Players:GetPlayers()

	Players.PlayerAdded:Connect(function(player)
		table.insert(RemoteProperty._players, player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		table.remove(RemoteProperty._players, table.find(RemoteProperty._players, player))
	end)
end

RemoteProperty._startTrackingPlayers()

export type RemoteProperty = typeof(setmetatable(
	{} :: {
		updated: any,
		playerValueUpdated: any,
		_property: Property.Property,
		_valueDispatcherRemoteFunction: RemoteFunction?,
		_playerProperties: {},
		_janitor: any,
	},
	RemoteProperty
))

return table.freeze(RemoteProperty)
