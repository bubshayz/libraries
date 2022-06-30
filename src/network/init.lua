--[=[
	@class network

	An advanced network module for easy server-client communication. The module consists of 
	[NetworkServer] and a [NetworkClient] module.

	```lua
	-- Server
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local network = require(ReplicatedStorage.Packages.network)

	local TestNetwork = Network.Server.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	TestNetwork:dispatch(workspace)

	-- Client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local network = require(ReplicatedStorage.Packages.network)

	local testNetwork = network.client.fromParent("Test", workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

return {
	Server = require(script.Server),
	client = require(script.client),
}
