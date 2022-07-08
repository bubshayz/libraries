--[=[
    @class RemoteSignal

    A remote signal in layman's terms is simply an object which dispatches data
    to a client (who can listen to this data through a client remote signal) and 
    listens to data dispatched to itself by a client (through a client remote signal).
]=]

--[=[ 
    @prop RemoteSignal Type 
    @within RemoteSignal
    @readonly

    An exported Luau type of remote signal.
]=]

--[=[
    @interface Middleware
    @within RemoteSignal
    .serverEvent { (client: Player, args: {any}) -> any }?,

    `serverEvent` must be array of callbacks, if specified.

    ### `serverEvent` 

    Callbacks in `serverEvent` are called whenever the client fires off the remote signal.

    The first and *only* argument passed to each callback is just an array of arguments sent by the client. 

    ```lua
    local serverEventCallbacks = {
        function (arguments)
            print(client:IsA("Player")) --> true (First argument is always the client!)
        end
    }
    ---
    ```

    :::warning Yielding is not allowed
    Middleware callbacks aren't allowed to yield. If they do so, their thread will be closed and an error will be outputted, but
    other callbacks will not be affected.
    :::

    :::tip More control
    - If any of the callbacks return an **explicit** false value, then the remote signal
    will not be fired. For e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.Server.new("TestNetwork")
    local testRemoteSignal = network.Server.RemoteSignal.new({
        clientServer = {function() return false end}
    })

    testRemoteSignal:connect(function()
        print("Fired") --> never prints
    end)

    testNetwork:append("signal", testRemoteSignal)
    testNetwork:dispatch(Workspace)

    -- Client
    local Workspace = game:GetService("Workspace")
    
    local testNetwork = network.client.fromParent("TestNetwork", Workspace)
    print(testNetwork.signal:fireServer()) 
    ```

    - Additionally, you can modify the `arguments` table, for e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.Server.new("TestNetwork")
    local testRemoteSignal = network.Server.RemoteSignal.new({
        clientServer = {
            function(arguments) 
                arguments[2] = 1 
                arguments[3] = "test"
            end
        }
    })

    testRemoteSignal:connect(function(client, a, b)
        print(a, b) --> 1, "test" (a and b ought to be 24, but they were modified through the middleware)
    end)

    testNetwork:append("signal", testRemoteSignal)
    testNetwork:dispatch(Workspace)

    -- Client
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.client.fromParent("Test", Workspace):expect()
    print(testNetwork.signal:fireServer(24, 24)) 
    ```
    :::
]=]

local networkFolder = script.Parent.Parent
local packages = networkFolder.Parent
local utilities = networkFolder.utilities

local sharedEnums = require(networkFolder.sharedEnums)
local Janitor = require(packages.Janitor)
local t = require(packages.t)
local tableUtil = require(utilities.tableUtil)
local networkUtil = require(utilities.networkUtil)
local tracker = require(utilities.tracker)

local MIDDLEWARE_TEMPLATE = { serverEvent = {} }

local MiddlewareInterface = t.optional(t.strictInterface({ serverEvent = t.optional(t.array(t.callback)) }))

local function getDefaultMiddleware()
	return tableUtil.deepCopy(MIDDLEWARE_TEMPLATE)
end

local RemoteSignal = { __index = {} }

type Middleware = { serverEvent: { serverEvent: { () -> boolean } } }
export type RemoteSignal = typeof(setmetatable(
	{} :: {
		_janitor: any,
		_remoteEvent: RemoteEvent,
		_middleware: Middleware,
	},
	RemoteSignal
))

--[=[
    @param middleware Middleware?
    @return RemoteSignal

    Creates and returns a new remote signal.
]=]

function RemoteSignal.new(middleware: Middleware?)
	assert(t.optional(t.table)(middleware))

	if middleware ~= nil then
		assert(MiddlewareInterface(middleware))
	end

	middleware = tableUtil.reconcileDeep(middleware or getDefaultMiddleware(), MIDDLEWARE_TEMPLATE)

	local self = setmetatable({
		_janitor = Janitor.new(),
		_middleware = middleware,
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

    Connects `callback` to the remote signal so that it is called whenever the client
    fires the remote signal. Additionally, `callback` will be passed all the arguments sent 
    by the client.

    ```lua
    -- Server
    remoteSignal:connect(function(client, a, b)
        print(a + b) --> 3
    end)

    -- Client
    clientRemoteSignal:fireServer(1, 2)
    ```
]=]

function RemoteSignal.__index:connect(callback: (...any) -> ()): RBXScriptConnection
	local onServerEventConnection
	onServerEventConnection = self._remoteEvent.OnServerEvent:Connect(function(...)
		-- https://devforum.roblox.com/t/beta-deferred-lua-event-handling/1240569
		if not onServerEventConnection.Connected then
			return
		end

		if not self:_shouldInvocate(...) then
			return
		end

		callback(...)
	end)

	return onServerEventConnection
end

--[=[
	@tag RemoteSignal instance

	Works almost exactly the same as [RemoteSignal:connect], except the 
	connection returned is  disconnected immediately upon `callback` being called.
]=]

function RemoteSignal.__index:connectOnce(callback: (...any) -> ()): RBXScriptConnection
	return self._remoteEvent.OnServerEvent:ConnectOnce(callback)
end

--[=[
    @tag RemoteSignal instance

    Connects `callback` to the remote signal so that it is called whenever the remote signal
    is fired off by the client *successfully*. Additionally, `callback` will be passed all the arguments sent 
    by the client.

    ```lua
    -- Server
    remoteSignal:connect(function(client, a, b)
        print(a + b) --> 3
    end)

    -- Client
    clientRemoteSignal:fireServer(1, 2)
    ```
]=]

--[=[
    @tag RemoteSignal instance

    Yields the current thread until the remote signal is *successfully* fired off by the client. 
    The yielded thread is resumed once the client fires some data to the server *successfully*, 
    with the arguments sent by the client.

    ```lua
    -- Server
    local client, a, b = remoteSignal:wait()
    print(a + b) --> 3

    -- Client
    clientRemoteSignal:fireServer(1, 2)
    ```
]=]

function RemoteSignal.__index:wait(): ...any
	local yieldedThread = coroutine.running()

	self:connectOnce(function(...)
		task.spawn(yieldedThread, ...)
	end)

	return coroutine.yield()
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

    Calls [RemoteSignal:fireClient] for every player in the game, also 
    passing in the arguments `...`.
]=]

function RemoteSignal.__index:fireAllClients(...: any)
	self._remoteEvent:FireAllClients(...)
end

--[=[
    @tag RemoteSignal instance

    Calls [RemoteSignal:fireClient] for every player in the `clients` table only, also 
    passing in the arguments `...`.
]=]

function RemoteSignal.__index:fireClients(clients: { Player }, ...: any)
	for _, client in clients do
		self._remoteEvent:FireClient(client, ...)
	end
end

--[=[
    @tag RemoteSignal instance

    Calls [RemoteSignal:fireClient] for every player in the game, except for `client`, also 
    passing in the arguments `...`.
]=]

function RemoteSignal.__index:fireAllClientsExcept(client: Player, ...: any)
	for _, player in tracker.getTrackingPlayers() do
		if player == client then
			continue
		end

		self._remoteEvent:FireClient(client, ...)
	end
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
	self._remoteEvent.Name = name
	self._remoteEvent:SetAttribute(sharedEnums.Attribute.boundToRemoteSignal, true)
	self._remoteEvent.Parent = parent
end

function RemoteSignal.__index:_shouldInvocate(...)
	local args = { ... }

	-- If there is an explicit false value included in the accumulated
	-- response of all serverEvent callbacks, then that means we should
	-- avoid this client's request to fire off the remote signal:
	if
		table.find(networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(self._middleware.serverEvent, args), false)
	then
		return false
	end

	return true
end

function RemoteSignal.__index:_init()
	self._remoteEvent = self._janitor:Add(Instance.new("RemoteEvent"))
	self._janitor:Add(function()
		setmetatable(self, nil)
	end)
end

function RemoteSignal:__tostring()
	return ("[RemoteSignal]: (%s)"):format(self._remoteEvent.Name)
end

return table.freeze(RemoteSignal)
