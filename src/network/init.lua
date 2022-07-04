--[=[
	@class network

	An advanced network module for easy server-client communication. The module consists of 
	[NetworkServer] and a [NetworkClient] module.

	```lua
	local Workspace = game:GetService("Workspace")

	-- Server
	local testNetwork = Network.Server.new("Test")
	testNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	testNetwork:dispatch(Workspace)

	-- Client
	local Workspace = game:GetService("Workspace")

	local testNetwork = network.client.fromParent("Test", Workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

--[=[ 
	@prop Server NetworkServer
	@within network
	@readonly

	A reference to the [NetworkServer] module.
]=]

--[=[ 
	@prop client networkClient
	@within network
	@readonly

	A reference to the [networkClient] module.
]=]

return {
	Server = require(script.Server),
	client = require(script.client),
}
