local Players = game:GetService("Players")

local tableUtil = require(script.Parent.tableUtil)

local networkUtil = {}

local function runCallbackNoYield(callback, ...)
	local callbackResponse
	local args = { ... }

	local thread = task.spawn(function()
		callbackResponse = callback(table.unpack(args))
	end)

	local didRunSafely = coroutine.status(thread) == "dead"
	return didRunSafely, callbackResponse
end

function networkUtil.safeInvokeClient(remoteFunction: RemoteFunction, player: Player, value: any)
	task.spawn(function()
		pcall(remoteFunction.InvokeClient, remoteFunction, player, value)
	end)
end

function networkUtil.getAccumulatedResponseFromMiddlewareCallbacks(callbacks, ...)
	local accumulatedResponses = {}

	for _, callback in callbacks do
		local didRunSafely, callbackResponse = runCallbackNoYield(callback, ...)
		assert(didRunSafely, "middleware callback yielded! Middleware callbacks must never yield.")

		table.insert(accumulatedResponses, callbackResponse)
	end

	return accumulatedResponses
end

function networkUtil.trackPlayers()
	local players = Players:GetPlayers()
	table.insert(tableUtil._playerTrackQueue, players)
	return players
end

Players.PlayerAdded:Connect(function(player)
	for _, players in tableUtil._playerTrackQueue do
		table.insert(players, player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for _, players in tableUtil._playerTrackQueue do
		table.insert(players, table.find(players, player))
	end
end)

return networkUtil
