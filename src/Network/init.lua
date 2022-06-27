local RunService = game:GetService("RunService")

--[=[
	@class network

	An advanced network module for easy server-client communication. Upon requiring
	the network module, the [NetworkServer] or [NetworkClient] counterpart is respectively
	returned (based off of the enviroment, i.e server / client). 
	
	For e.g:

	```lua
	-- Server
	local network = require(...) -- [NetworkServer] is returned

	local TestNetwork = network.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	TestNetwork:dispatch(workspace)

	-- Client
	local network = require(...) -- [NetworkClient] is returned

	local testNetwork = network.fromParent("Test", workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```

	:::note
	[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)
	apply for the **entirety** of the network module, as remote events and remote fucntions are internally used.
	:::
]=]

if RunService:IsServer() then
	return require(script.Server)
else
	return require(script.client)
end
