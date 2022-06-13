--[=[ 
	@class Queue

	A class for creating queues. A queue in layman's term, is simply an to which you can append callbacks to, which
	will run based on when they're added, i.e they **follow** the *FIFO (First In, First Out) pattern* .
 
	```lua
	local Queue = require(...)

	local queue = Queue.new()

	for i = 1, 3 do 
		queue:Append(function(deltaTime)
			warn(("completed task (%d) in %s seconds."):format(task.wait(i), deltaTime))
		end)
	end

	--> "completed task (1)" 
	--> "completed task (2)"
	--> "completed task (3)"
	```
]=]

--[=[ 
	@prop Progressed Signal <callbackProgressed: () -> (), deltaTime: number>
	@within Queue
	@tag Signal
	@tag Queue Instance

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the queue is progressed, i.e an appended callback is called. The callback called
	is passed as the first argument, and a second argument, `deltaTime` is also passed (which is basically how long (in seconds) it was before `callbackProgressed` was called
	ever since it was appended).
]=]

--[=[ 
	@prop Queue Type 
	@within Queue
	@tag Luau Type
	@readonly

	An exported Luau type of a queue object.

	```lua
	local Queue = require(...)

	local queue: Queue.Queue = Queue.new(...) 
	```
]=]

local Promise = require(script.Parent.Promise)
local Signal = require(script.Parent.Signal)

local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."

local Queue = { __index = {} }

--[=[
	@return Queue
	
	A constructor method which creates a new queue object.
]=]

function Queue.new(): Queue
	return setmetatable({
		Progressed = Signal.new(),
		_promises = {},
	}, Queue)
end

--[=[
	A method which returns a boolean indicating if `self` is a queue or not.
]=]

function Queue.IsA(self: any): boolean
	return getmetatable(self) == Queue
end

--[=[
	@tag Queue Instance
	
	Empties the queue, i.e all appended callbacks that are waiting to be resumed will never be resumed

	```lua
	local Queue = require(...)

	local queue = Queue.new()

	local promise1 = queue:Append(function()
		task.wait(1)
		warn("called") --> this never works, because the promise is cancelled as the queue is emptied! 
	end)

	print(promise1:getStatus()) --> "Running" (the promise is running)
	queue:EmptyQueue() 
	print(promise1:getStatus()) --> "Cancelled"  (the promise has been cancelled now)
	```
]=]

function Queue.__index:EmptyQueue()
	for _, promise in self._promises do
		promise:cancel()
	end

	table.clear(self._promises)
end

--[=[
	@tag Queue Instance
	@return Promise <deltaTime: number>
	
	Appends `callback` to the queue so that it'll be called once the previous callbacks appended to the queue
	have *finished* running (or the promises associated to them have been cancelled). `callback` upon being called is passed 
	a number as the only argument (the time it took for it to be called ever since it was appended). 
	
	The method also returns a promise, which too resolves with a number (the time it took for `callback` 
	to run ever since it was appended), once `callback` is called.

	```lua
	local Queue = require(...)

	local queue = Queue.new()

	local promise1 = queue:Append(function(deltaTime)
		print(deltaTime) --> 5.00003807246685e-07 
		task.wait(5)
	end)

	local promise2 = queue:Append(function(deltaTime) 
		print(deltaTime) --> 5.0113310999877285
		task.wait(1)
	end)

	local promise2 = queue:Append(function(deltaTime) 
		print(deltaTime) --> 6.012134199991124 
	end)
	```

	:::tip
	The promise returned will be cancelled if [Queue:EmptyQueue] is called, but you can also manually 
	just cancel the promise to effectively remove the added callback from the queue, e.g:

	```lua
	local Queue = require(...)

	local queue = Queue.new()

	local promise = queue:Append(function(deltaTime) 
		print(deltaTime) --> never prints!
	end)

	promise:cancel() --> Cancel the promise!
	```
	:::
]=]

function Queue.__index:Append(callback: (deltaTime: number) -> ())
	assert(typeof(callback) == "function", INVALID_ARGUMENT_TYPE:format(1, "Queue:Append", "function", typeof(callback)))

	local promise
	promise = Promise.defer(function(resolve, _, onCancel)
		onCancel(function()
			table.remove(self._promises, table.find(self._promises, promise))
		end)

		local clockTimestampBefore = os.clock()

		while self._promises[1] ~= promise do
			self.Progressed:Wait()
		end

		local deltaTime = os.clock() - clockTimestampBefore

		callback(deltaTime)
		table.remove(self._promises, table.find(self._promises, promise))
		self.Progressed:Fire(callback, deltaTime)
		resolve(deltaTime)
	end)

	table.insert(self._promises, promise)
	return promise
end

--[=[
	@tag Queue Instance

	Calls [Queue:EmptyQueue] and renders the queue unusable.
]=]

function Queue.__index:Destroy()
	self:EmptyQueue()
	self.Progressed:Destroy()
	setmetatable(self, nil)
end

export type Queue = typeof(setmetatable({} :: {
	_promises: { any },
	Progressed: any,
}, Queue))

return Queue
