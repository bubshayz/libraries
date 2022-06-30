local RunService = game:GetService("RunService")

--[=[
	@class network

	An advanced network module for easy server-client communication. Upon requiring
	the network module, either the [NetworkServer] or [NetworkClient] module is respectively
	returned (based off of the enviroment, i.e server / client). 
	
	For e.g:

	```lua
	-- Server
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Network = require(ReplicatedStorage.Packages.network) -- [NetworkServer] is returned

	local TestNetwork = Network.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	TestNetwork:dispatch(workspace)

	-- Client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Network = require(ReplicatedStorage.Packages.network) -- [NetworkClient] is returned

	local testNetwork = network.fromParent("Test", workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

if RunService:IsServer() then
	return require(script.Server)
else
	return require(script.client)
end
