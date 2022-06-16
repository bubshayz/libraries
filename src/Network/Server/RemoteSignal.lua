--[=[
	@class RemoteSignal

	A remote signal in layman's terms is simply an object which dispatches data
	to a client (who can listen to this data through a client remote signal) and 
	listens to data dispatched to it self by a client (through a client remote signal).
	
	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	do apply since remote events are internally used by remote signals to dispatch data to clients.
	:::
]=]

--[=[ 
	@prop RemoteSignal Type 
	@within RemoteSignal
	@tag Luau Type
	@readonly

	An exported Luau type of a remote signal object.
]=]

--[=[
	@interface SignalConnection 
	@within RemoteSignal	

	.Disconnect () -> () 
	.Connected boolean
]=]

local Packages = script.Parent.Parent.Parent
local Network = script.Parent.Parent

local SharedConstants = require(Network.SharedConstants)
local Signal = require(Packages.Signal)
local Janitor = require(Packages.Janitor)

local RemoteSignal = { __index = {} }

--[=[
	@return RemoteSignal

	Creates and returns a new remote signal.
]=]

function RemoteSignal.new()
	local self = setmetatable({
		_signal = Signal.new(),
		_janitor = Janitor.new(),
	}, RemoteSignal)

	self:_init()
	return self
end

--[=[
	Returns a boolean indicating if `self` is a remote signal or not.
]=]

function RemoteSignal.is(self: any): boolean
	return getmetatable(self) == RemoteSignal
end

--[=[
	@tag RemoteSignal instance
	@return SignalConnection

	Works almost exactly the same as [RemoteSignal:connectOnce], except the connection returned 
	is disconnected automaticaly once `callback` is called.
]=]

function RemoteSignal.__index:connectOnce(callback: (...any) -> ())
	return self._signal:ConnectOnce(callback)
end

--[=[
	@tag RemoteSignal instance
	@return SignalConnection

	Connects `callback` to the remote signal so that it is called whenever the client
	fires the remote signal, and `callback` will be passed arguments sent by the client.
]=]

function RemoteSignal.__index:connect(callback: (...any) -> ())
	return self._signal:Connect(callback)
end

--[=[
	@tag RemoteSignal instance

	Fires the arguments `...` to every client in the `clients` table only.
]=]

function RemoteSignal.__index:fireForClients(clients: { Player }, ...: any)
	for _, client in clients do
		self._remoteEvent:FireClient(client, ...)
	end
end

--[=[
	@tag RemoteSignal instance

	Fires the arguments `...` to `client`.
]=]

function RemoteSignal.__index:fireClient(client: Player, ...: any)
	self._remoteEvent:FireClient(client, ...)
end

--[=[
	@tag RemoteSignal instance

	Fires the arguments `...` to every client in the game.
]=]

function RemoteSignal.__index:fireAllClients(...: any)
	self._remoteEvent:FireAllClients(...)
end

--[=[
	@tag RemoteSignal instance

	Disconnects all connections connected via [RemoteSignal:connect] or [RemoteSignal:connectOnce].
]=]

function RemoteSignal.__index:disconnectAll()
	self._signal:DisconnectAll()
end

--[=[
	@tag RemoteSignal instance
	
	Destroys the remote signal and renders it unusable.
]=]

function RemoteSignal.__index:destroy()
	self._janitor:Destroy()
end

--[=[
	@private
]=]

function RemoteSignal.__index:dispatch(name: string, parent: Instance)
	local remoteEvent = self._janitor:Add(Instance.new("RemoteEvent"))
	remoteEvent.Name = name
	remoteEvent:SetAttribute(SharedConstants.Attribute.BoundToRemoteSignal, true)
	remoteEvent.Parent = parent

	remoteEvent.OnServerEvent:Connect(function(...)
		self._signal:Fire(...)
	end)

	self._remoteEvent = remoteEvent
end

function RemoteSignal.__index:_init()
	self._janitor:Add(self._signal)
	self._janitor:Add(function()
		setmetatable(self, nil)
	end)
end

export type remoteSignal = typeof(setmetatable(
	{} :: {
		_signal: any,
		_janitor: any,
		_remoteEvent: RemoteEvent?,
	},
	RemoteSignal
))

return table.freeze(RemoteSignal)
