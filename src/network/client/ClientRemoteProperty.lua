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

    A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired, whenever the value 
    of the serverside remote property (to which this client remote property is connected) is updated.
    
    Incase the client has a specific value set for them in the serverside remote property, then this signal
    will only fire if *that* value has been updated.
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

export type ClientRemoteProperty = typeof(setmetatable(
	{} :: {
		_remoteEvent: RemoteEvent,
		_signal: any,
		_janitor: any,
	},
	ClientRemoteProperty
))

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

    Returns the value of the client stored in the serverside remote property (to which the client remote property is connected to).
    If there is no value stored specifically for the client, then the serverside remote property's current value will be returned
    instead.
]=]

function ClientRemoteProperty.__index:get(): any
	return self._property:get()
end

--[=[
	@tag ClientRemoteProperty instance
	
	Invokes the serverside remote property (to which this client remote propert is connected to), to set the value for the client to `value`.

	:::note
	The serverside remote property might have a specific middleware (`clientSet`) which may alter this process, so there is no guarantee
	that the value set by the client will actually be respected by the server. 
	:::
]=]

function ClientRemoteProperty.__index:set(value: any)
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

	-- In case a new value was set while we were retrieving the initial value, don't
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

return table.freeze(ClientRemoteProperty)
