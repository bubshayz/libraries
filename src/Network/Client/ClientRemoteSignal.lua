--[=[
	@class ClientRemoteSignal

	The clientside counterpart of [RemoteSignal]. A client remote signal in 
	layman's terms is just an object connected to a serverside remote signal.
]=]

--[=[
	@interface SignalConnection 
	@within ClientRemoteSignal	

	.Disconnect () -> () 
	.Connected boolean
]=]

--[=[ 
	@prop ClientRemoteSignal Type 
	@within ClientRemoteSignal
	@tag Luau Type
	@readonly

	An exported Luau type of a client remote signal object.
]=]

local Packages = script.Parent.Parent.Parent

local Signal = require(Packages.Signal)
local Janitor = require(Packages.Janitor)

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

function ClientRemoteSignal.is(self: any): boolean
	return getmetatable(self) == ClientRemoteSignal
end

--[=[
	@return SignalConnection
	@tag ClientRemoteSignal instance

	Connects `callback` to the client remote signal so that it is called whenever 
	the serverside remote signal (to which the client remote signal is connected to) 
	dispatches some data to the client remote signal. The connected callback is called 
	with the data dispatched to the client remote signal.
]=]

function ClientRemoteSignal.__index:connect(callback: (...any) -> any)
	return self._signal:Connect(callback)
end

--[=[
	@return SignalConnection
	@tag ClientRemoteSignal instance

	Works almost exactly the same as [ClientRemoteSignal:connect], except the 
	connection returned is  disconnected immediately upon `callback` being called.
]=]

function ClientRemoteSignal.__index:connectOnce(callback: (...any) -> any)
	return self._signal:ConnectOnce(callback)
end

--[=[
	@tag ClientRemoteSignal instance

	Disconnects all connections connected via [ClientRemoteSignal:connect] 
	or [ClientRemoteSignal:connectOnce].
]=]

function ClientRemoteSignal.__index:disconnectAll()
	self._signal:DisconnectAll()
end

--[=[
	@tag ClientRemoteSignal instance

	Fires `...` arguments to the serverside remote signal (to which the client
	remote signal is connected to).
]=]

function ClientRemoteSignal.__index:fire(...: any)
	self._remoteEvent:FireServer(...)
end

--[=[
	@tag ClientRemoteSignal instance
	@tag yields

	Yields the thread until the serverside remote signal (to which the client 
	remote signal is connected to) dispatches some data to this client 
	remote signal.
]=]

function ClientRemoteSignal.__index:wait()
	return self._signal:Wait()
end

--[=[
	@tag ClientRemoteSignal instance
	
	Destroys the client remote signal and renders it unusable.
]=]

function ClientRemoteSignal.__index:destroy()
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

function ClientRemoteSignal:__tostring()
	return ("[ClientRemoteSignal]: (%s)"):format(self._remoteEvent.Name)
end

export type clientRemoteSignal = typeof(setmetatable(
	{} :: {
		_remoteEvent: RemoteEvent,
		_signal: any,
		_janitor: any,
	},
	ClientRemoteSignal
))

return table.freeze(ClientRemoteSignal)
