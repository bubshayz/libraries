--[=[
	@class ClientRemoteSignal

	The clientside counterpart of [RemoteSignal]. A client remote signal in layman's terms is just an object 
	connected to a serverside remote signal.
]=]

--[=[
	@interface SignalConnection 
	@within ClientRemoteSignal	

	.Disconnect () -> () 
	.Connected boolean
]=]

local packages = script.Parent.Parent.Parent

local Signal = require(packages.Signal)
local Janitor = require(packages.Janitor)

local ClientRemoteSignal = { __index = {} }

--[=[
	@private
]=]

function ClientRemoteSignal.new(remoteEvent: RemoteEvent): ClientRemoteSignal
	local self = setmetatable({
		_remoteEvent = remoteEvent,
		_signal = Signal.new(),
		_janitor = Janitor.new(),
	}, ClientRemoteSignal)

	self:_init()
	return self
end

--[=[
	Returns a boolean indicating if `self` is a client remote signal or not.
]=]

function ClientRemoteSignal.IsA(self: any): boolean
	return getmetatable(self) == ClientRemoteSignal
end

--[=[
	@return SignalConnection
	@tag ClientRemoteSignal instance

	Connects `callback` to the client remote signal so that it is called whenever the serverside remote signal
	(to which the client remote signal is connected to) dispatches some data to the client remote signal. The
	connected callback is called with the data dispatched to the client remote signal.
]=]

function ClientRemoteSignal.__index:Connect(callback: (...any) -> any)
	return self._signal:Connect(callback)
end

--[=[
	@return SignalConnection
	@tag ClientRemoteSignal instance

	Works almost exactly the same as [ClientRemoteSignal:Connect], except the connection returned is 
	disconnected immediately upon `callback` being called.
]=]

function ClientRemoteSignal.__index:ConnectOnce(callback: (...any) -> any)
	return self._signal:ConnectOnce(callback)
end

--[=[
	@tag ClientRemoteSignal instance

	Disconnects all connections connected via [ClientRemoteSignal:Connect] or [ClientRemoteSignal:ConnectOnce].
]=]

function ClientRemoteSignal.__index:DisconnectAll()
	self._signal:DisconnectAll()
end

--[=[
	@tag ClientRemoteSignal instance

	Fires `...` arguments to the serverside remote signal (to which the client remote signal is connected to).
]=]

function ClientRemoteSignal.__index:Fire(...: any)
	self._remoteEvent:FireServer(...)
end

--[=[
	@tag ClientRemoteSignal instance
	@tag yields

	Yields the thread until the serverside remote signal (to which the client remote signal is connected to) dispatches
	some data to the client remote signal.
]=]

function ClientRemoteSignal.__index:Wait()
	return self._signal:Wait()
end

--[=[
	@tag ClientRemoteSignal instance
	
	Destroys the client remote signal and renders it unusable.
]=]

function ClientRemoteSignal.__index:Destroy()
	self._janitor:Destroy()
end

function ClientRemoteSignal.__index:_init()
	self._janitor:Add(function()
		setmetatable(self, nil)
	end)

	self._janitor:Add(self._signal)
	self._janitor:Add(self._remoteEvent.OnClientEvent:Connect(function(...)
		self._signal:Fire(...)
	end))
end

export type ClientRemoteSignal = typeof(setmetatable(
	{} :: {
		_remoteEvent: RemoteEvent,
		_signal: any,
		_janitor: any,
	},
	ClientRemoteSignal
))

return ClientRemoteSignal
