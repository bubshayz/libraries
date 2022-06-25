local RunService = game:GetService("RunService")

--[=[
	@class network

	An advanced network module for easy server-client communication. Upon requiring
	the network module, the [NetworkServer] or [NetworkClient] counterpart is respectively
	returned (based off of the enviroment). For e.g:


	```lua
	-- Server
	local network = require(...)

	local TestNetwork = network.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...)

	local testNetwork = network.fromParent("Test", workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

if RunService:IsServer() then
	return require(script.Server)
else
	return require(script.client)
end
