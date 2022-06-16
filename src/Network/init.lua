local RunService = game:GetService("RunService")

--[=[
	@class Network

	An advanced network module for easy server-client communication. The network
	module it self consists of a [NetworkServer] and  a [NetworkClient] module, 
	so whenever you require the Network module it self, in return one of these 2 
	modules are required  and returned, based off of the environment 
	(server / client).

	```lua
	-- Server
	local Network = require(...) 

	local networkObject = Network.new("Test")
	networkObject:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	networkObject:dispatch(workspace)

	-- Client
	local Network = require(...) 

	local networkObject = Network.fromParent("Test", workspace)
	print(networkObject.Method()) --> "hi, bubshayz!"
	```
]=]

return if RunService:IsServer() then require(script.Server) else require(script.Client)
