--[=[
	@class ClientRemoteSignal

	The clientside counterpart of [RemoteSignal]. A client remote signal in 
	layman's terms is just an object connected to a serverside remote signal.
]=]

--[=[ 
	@prop ClientRemoteSignal Type 
	@within ClientRemoteSignal
	
	@readonly

	An exported Luau type of a client remote signal object.
]=]

local packages = script.Parent.Parent.Parent

local Janitor = require(packages.Janitor)

local ClientRemoteSignal = { __index = {} }

export type ClientRemoteSignal = typeof(setmetatable(
	{} :: {
		_remoteEvent: RemoteEvent,
		_janitor: any,
	},
	ClientRemoteSignal
))

--[=[
	@private
]=]

function ClientRemoteSignal.new(remoteEvent: RemoteEvent)
	local self = setmetatable({
		_remoteEvent = remoteEvent,
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
	@tag ClientRemoteSignal instance

	Connects `callback` to the client remote signal so that it is called whenever 
	the serverside remote signal (to which the client remote signal is connected to) 
	dispatches some data to the client. Additionally, `callback` will be passed all the arguments 
	sent by the server.
]=]

function ClientRemoteSignal.__index:connect(callback: (...any) -> ()): RBXScriptConnection
	local onClientEventConnection
	onClientEventConnection = self._janitor:Add(self._remoteEvent.OnClientEvent:Connect(function(...)
		-- https://devforum.roblox.com/t/beta-deferred-lua-event-handling/1240569
		if onClientEventConnection and not onClientEventConnection.Connected then
			return
		end

		callback(...)
	end))

	return onClientEventConnection
end

--[=[
	@tag ClientRemoteSignal instance

	Fires `...` arguments to the serverside remote signal (to which the client
	remote signal is connected to).
]=]

function ClientRemoteSignal.__index:fireServer(...: any)
	self._remoteEvent:FireServer(...)
end

--[=[
	@tag ClientRemoteSignal instance
	@tag yields

	Yields the current thread until the serverside remote signal (to which the client 
	remote signal is connected to) dispatches some data to the client. The yielded thread 
	is resumed once the server fires some data to the client, with the arguments sent by the 
	server.

	```lua
	-- Server
	remoteSignal:fireAllClients("Hi")

	-- Client
	print(clientRemoteSignal:wait()) --> "Hi"
	```
]=]

function ClientRemoteSignal.__index:wait(): ...any
	return self._remoteEvent.OnClientEvent:Wait()
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
end

function ClientRemoteSignal:__tostring()
	return ("[ClientRemoteSignal]: (%s)"):format(self._remoteEvent.Name)
end

return table.freeze(ClientRemoteSignal)
