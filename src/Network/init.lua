local RunService = game:GetService("RunService")

--[=[
	@class Network

	The Network module it self consists of a [NetworkServer] and a [NetworkClient] module, so
	whenever you require the Network module it self, in return one of these 2 modules are required and returned,
	based off of the environment (server / client).

	```lua
	-- Server
	local Network = require(...) 

	local networkObject = Network.new("Test", workspace)
	networkObject:Append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	networkObject:Dispatch()

	-- Client
	local Network = require(...) 

	local networkObject = Network.FromName("Test", workspace)
	print(networkObject.Method()) --> "hi, bubshayz!"
	```
]=]

return if RunService:IsServer() then require(script.Server) else require(script.Client)
