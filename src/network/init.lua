--[=[
	@class network

	An advanced network module for easy server-client communication. 

	```lua
	local Workspace = game:GetService("Workspace")

	-- Server
	local testNetwork = Network.Server.new("TestNetwork")
	testNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	testNetwork:dispatch(Workspace)

	-- Client
	local Workspace = game:GetService("Workspace")

	local testNetwork = network.client.fromParent("TestNetwork", Workspace):expect()
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

--[=[ 
	@prop Server NetworkServer
	@within network
	@readonly
]=]

--[=[ 
	@prop client networkClient
	@within network
	@readonly
]=]

return {
	Server = require(script.Server),
	client = require(script.client),
}
