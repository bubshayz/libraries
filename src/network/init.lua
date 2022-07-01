--[=[
	@class network

	An advanced network module for easy server-client communication. The module consists of 
	[NetworkServer] and a [NetworkClient] module.

	```lua
	-- Server
	local TestNetwork = Network.Server.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	TestNetwork:dispatch(workspace)

	-- Client
	local testNetwork = network.client.fromParent("Test", workspace)
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
