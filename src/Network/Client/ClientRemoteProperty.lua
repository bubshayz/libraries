--[=[
	@class ClientRemoteProperty

	The clientside counterpart of [RemoteProperty]. A client remote property 
	in layman's terms is just an object connected to a serverside remote property.
]=]

--[=[ 
	@prop updated Signal <newValue: any>
	@within ClientRemoteProperty
	@readonly
	@tag Signal
	@tag ClientRemoteProperty instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired 
	whenever the value  of the client in the serverside remote property 
	(to which the client remote property is connected to) is updated. 
	The signal is only passed the new updated value as the only argument.
]=]

--[=[ 
	@prop ClientRemoteProperty Type 
	@within ClientRemoteProperty
	
	@readonly

	An exported Luau type of a client remote property object.
]=]

local packages = script.Parent.Parent.Parent

local Property = require(packages.Property)
local Janitor = require(packages.Janitor)

local ClientRemoteProperty = { __index = {} }

--[=[
	@private
]=]

function ClientRemoteProperty.new(remoteFunction: RemoteFunction): ClientRemoteProperty
	local property = Property.new()
	local self = setmetatable({
		updated = property.updated,
		_property = property,
		_janitor = Janitor.new(),
		_remoteFunction = remoteFunction,
	}, ClientRemoteProperty)

	self:_init()
	return self
end

--[=[
	Returns a boolean indicating if `self` is a client remote property or not.
]=]

function ClientRemoteProperty.is(self: any): boolean
	return getmetatable(self) == ClientRemoteProperty
end

--[=[
	@tag ClientRemoteProperty instance

	Returns the value of the client stored in the serverside remote property (
	to which the client remote property is connected to).
]=]

function ClientRemoteProperty.__index:get(): any
	return self._property:get()
end

function ClientRemoteProperty.__index:set(value)
	task.spawn(self._remoteFunction.InvokeServer, self._remoteFunction, { value = value })
end

--[=[
	@tag ClientRemoteProperty instance

	Destroys the client remote property and renders it unusable.
]=]

function ClientRemoteProperty.__index:destroy()
	self._janitor:Destroy()
end

function ClientRemoteProperty.__index:_init()
	local remoteFunction = self._remoteFunction

	function remoteFunction.OnClientInvoke(newValue)
		self._property:set(newValue)
	end

	local newValue = self._remoteFunction:InvokeServer()

	-- Incase a new value was set while we were retrieving the initial value, don't
	-- update the value of the property to avoid unexpected behavior!
	if self:get() == nil then
		self._property:set(newValue)
	end

	self._janitor:Add(self._property, "destroy")
	self._janitor:Add(function()
		self._remoteFunction.OnClientInvoke = nil
		setmetatable(self, nil)
	end)
end

function ClientRemoteProperty:__tostring()
	return ("[ClientRemoteProperty]: (%s)"):format(self._remoteFunction.Name)
end

export type clientRemoteProperty = typeof(setmetatable(
	{} :: {
		updated: any,
		_property: any,
		_janitor: any,
		_remoteFunction: RemoteFunction,
	},
	ClientRemoteProperty
))

return table.freeze(ClientRemoteProperty)
