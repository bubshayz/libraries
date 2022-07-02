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
    @interface SignalConnection 
    @within RemoteSignal    

    .Disconnect () -> () 
    .Connected boolean
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
    Middleware callbacks aren't allowed to yield, if they do so, an error will be outputted!
    :::

    :::tip 
    - If any of the callbacks return an **explicit** false value, then the remote signal
    will not be fired. For e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local TestNetwork = network.Server.new("Test")
    local TestRemoteSignal = network.Server.RemoteSignal.new({
        clientServer = {function() return false end}
    })

    TestRemoteSignal:connect(function()
        print("Fired") --> never prints
    end)

    TestNetwork:append("signal", TestRemoteSignal)
    TestNetwork:dispatch(Workspace)

    -- Client
    local Workspace = game:GetService("Workspace")
    
    local testNetwork = network.client.fromParent("Test", Workspace)
    print(testNetwork.signal:fire()) 
    ```

    - Additionally, you can modify the `arguments` table, for e.g:

    ```lua
    -- Server
    local Workspace = game:GetService("Workspace")

    local TestNetwork = network.Server.new("Test")
    local TestRemoteSignal = network.Server.RemoteSignal.new({
        clientServer = {
            function(arguments) 
                arguments[2] = 1 
                arguments[3] = "test"
            end
        }
    })

    TestRemoteSignal:connect(function(client, a, b)
        print(a, b) --> 1, "test" (a and b ought to be 24, but they were modified through the middleware)
    end)

    TestNetwork:append("signal", TestRemoteSignal)
    TestNetwork:dispatch(Workspace)

    -- Client
    local Workspace = game:GetService("Workspace")

    local testNetwork = network.client.fromParent("Test", Workspace)
    print(testNetwork.signal:fire(24, 24)) 
    ```
    :::
]=]

local networkFolder = script.Parent.Parent
local packages = networkFolder.Parent
local utilities = networkFolder.utilities

local SharedConstants = require(networkFolder.SharedConstants)
local Signal = require(packages.Signal)
local Janitor = require(packages.Janitor)
local t = require(packages.t)
local tableUtil = require(utilities.tableUtil)
local networkUtil = require(utilities.networkUtil)

local MIDDLEWARE_TEMPLATE = { serverEvent = {} }

local MiddlewareInterface = t.optional(t.strictInterface({ serverEvent = t.optional(t.array(t.callback)) }))

local function getDefaultMiddleware()
	return tableUtil.deepCopy(MIDDLEWARE_TEMPLATE)
end

local RemoteSignal = { __index = {} }

type Middleware = { serverEvent: { serverEvent: { () -> boolean } } }
export type RemoteSignal = typeof(setmetatable(
	{} :: {
		_signal: any,
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

	if middleware then
		assert(MiddlewareInterface(middleware))
	end

	middleware = tableUtil.reconcileDeep(middleware or getDefaultMiddleware(), MIDDLEWARE_TEMPLATE)

	local self = setmetatable({
		_signal = Signal.new(),
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
    @return SignalConnection

    Works almost the same as [RemoteSignal:connectOnce], except the connection returned 
    is disconnected automatically once `callback` is called.
]=]

function RemoteSignal.__index:connectOnce(callback: (...any) -> ()): any
	return self._signal:ConnectOnce(callback)
end

--[=[
    @tag RemoteSignal instance
    @return SignalConnection

    Connects `callback` to the remote signal so that it is called whenever the client
    fires the remote signal. Additionally, `callback` will be passed to all the arguments sent 
    by the client.
]=]

function RemoteSignal.__index:connect(callback: (...any) -> ()): any
	return self._signal:Connect(callback)
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

    Calls [remoteSignal:fireClient] on every player in the game.
]=]

function RemoteSignal.__index:fireAllClients(...: any)
	self._remoteEvent:FireAllClients(...)
end

--[=[
    @tag RemoteSignal instance

    Calls [remoteSignal:fireClient] on every player in the `clients` table only.
]=]

function RemoteSignal.__index:fireForClients(clients: { Player }, ...: any)
	for _, client in clients do
		self._remoteEvent:FireClient(client, ...)
	end
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
	remoteEvent:SetAttribute(SharedConstants.attribute.boundToRemoteSignal, true)
	remoteEvent.Parent = parent

	remoteEvent.OnServerEvent:Connect(function(...)
		local args = { ... }

		-- If there is an explicit false value included in the accumulated
		-- response of all serverEvent callbacks, then that means we should
		-- avoid this client's request to fire off the remote signal:
		if
			table.find(
				networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(self._middleware.serverEvent, args),
				false
			)
		then
			return
		end

		self._signal:Fire(table.unpack(args))
	end)

	self._remoteEvent = remoteEvent
end

function RemoteSignal.__index:_init()
	self._janitor:Add(self._signal)
	self._janitor:Add(function()
		setmetatable(self, nil)
	end)
end

function RemoteSignal:__tostring()
	return ("[RemoteSignal]: (%s)"):format(self._remoteEvent.Name)
end

return table.freeze(RemoteSignal)
