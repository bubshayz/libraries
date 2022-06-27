local tracker = { _players = {} }

function tracker.getTrackingPlayers(): { Player }
	return tracker._players
end

tracker.PlayerAdded:Connect(function(player)
	table.insert(tracker._players, player)
end)

tracker.PlayerRemoving:Connect(function(player)
	table.remove(tracker._players, table.find(tracker._players, player))
end)

return tracker
