--[=[
	@class network

	An advanced network module for easy server-client communication. The network
	module it self consists of a [NetworkServer] and a [NetworkClient] module which
	you can use, for e.g:


	```lua
	-- Server
	local NetworkServer = require(...).Server

	local networkObject = NetworkServer.new("Test")
	networkObject:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)
	networkObject:dispatch(workspace)

	-- Client
	local NetworkClient = require(...).Client

	local networkObject = NetworkClient.fromParent("Test", workspace)
	print(networkObject.method()) --> "hi, bubshayz!"
	```
]=]

return {
	Server = require(script.Server),
	client = require(script.client),
}
