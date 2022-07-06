local networkUtil = { _players = {} }

local function runCallbackNoYield(callback, ...)
	local callbackResponse
	local args = { ... }

	local thread = task.spawn(function()
		callbackResponse = callback(table.unpack(args))
	end)

	local didRunSafely = coroutine.status(thread) == "dead"

	if not didRunSafely then
		coroutine.close(thread)
	end

	return didRunSafely, callbackResponse
end

function networkUtil.safeInvokeClient(remoteFunction: RemoteFunction, player: Player, value: any)
	task.spawn(function()
		pcall(remoteFunction.InvokeClient, remoteFunction, player, value)
	end)
end

function networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(callbacks: { () -> any }, ...: any): { any }
	local accumulatedResponses = {}

	for _, callback in callbacks do
		local didRunSafely, callbackResponse = runCallbackNoYield(callback, ...)
		assert(didRunSafely, "middleware callback yielded! Middleware callbacks must never yield.")

		table.insert(accumulatedResponses, callbackResponse)
	end

	return accumulatedResponses
end

function networkUtil.truncateAccumulatedResponses(accumulatedResponses: { any }): any
	return if #accumulatedResponses > 1 then accumulatedResponses else accumulatedResponses[1]
end

return networkUtil
