--[=[
	@class networkClient

	The client counterpart of the Network module.
]=]

--[=[ 
	@prop ClientRemoteProperty ClientRemoteProperty
	@within networkClient
	@readonly

	A reference to the [ClientRemoteProperty] module.
]=]

--[=[ 
	@prop ClientRemoteSignal ClientRemoteSignal
	@within networkClient
	@readonly

	A reference to the [ClientRemoteSignal] module.
]=]

local packages = script.Parent.Parent

local Promise = require(packages.Promise)
local SharedConstants = require(script.Parent.SharedConstants)

local networkClient = {
	ClientRemoteProperty = require(script.ClientRemoteProperty),
	ClientRemoteSignal = require(script.ClientRemoteSignal),
}

local function getAbstractOfNetworkFolder(networkFolder): { [string]: any }
	local abstract = {}

	for _, descendant in networkFolder:GetChildren() do
		if descendant:GetAttribute(SharedConstants.attribute.boundToRemoteSignal) then
			abstract[descendant.Name] = networkClient.ClientRemoteSignal.new(descendant)
			continue
		elseif descendant:GetAttribute(SharedConstants.attribute.boundToRemoteProperty) then
			abstract[descendant.Name] = networkClient.ClientRemoteProperty.new(descendant)
			continue
		end

		if descendant:GetAttribute("ValueType") == "function" then
			abstract[descendant.Name] = function(...)
				local args = { ... }
				local index = table.find(args, abstract)

				if index then
					table.remove(args, index)
				end

				return descendant:InvokeServer(table.unpack(args))
			end
		else
			abstract[descendant.Name] = descendant:InvokeServer()
		end
	end

	return table.freeze(abstract)
end

local function getNetworkFoldersFromParent(parent: Instance): { Folder }
	local networkFolders = {}

	for _, networkFolder in parent:GetChildren() do
		if not networkFolder:GetAttribute(SharedConstants.attribute.networkFolder) then
			continue
		end

		table.insert(networkFolders, networkFolder)
	end

	return networkFolders
end
--[=[
	Returns an array of *all* networks dispatched to `parent`.

	```lua
	-- Server
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local network = require(ReplicatedStorage.Packages.network) 

	local Network1 = network.Server.new("Test1", workspace)
	Network1:append("status", "not good mate")
	Network1:dispatch(Workspace)

	local Network2 = network.Server.new("Test2", workspace)
	Network2:append("status", "good mate!")
	Network2:dispatch(Workspace)

	-- Client
	local Workspace = game:GetService("Workspace")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local network = require(ReplicatedStorage.Packages.network) 

	for _, networkObject in Network.client.allFromParent(Workspace) do
		print(networkObject.status) 
	end

	--> "not good mate"
	--> "good mate!"
	```
]=]

function networkClient.allFromParent(parent: Instance): { [string]: { [string]: any } }
	local networks = {}

	for _, networkFolder in getNetworkFoldersFromParent(parent) do
		networks[networkFolder.Name] = getAbstractOfNetworkFolder(networkFolder)
	end

	return table.freeze(networks)
end

--[=[
	@return Promise<DispatchedNetwork: {[string]: any}>

	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved once a network with the 
	name of `name`, is dispatched to `parent`. If a network with the name of `name` is already dispatched to
	`parent`, the promise will immediately resolve.

	For e.g:

	```lua
	-- Server
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local network = require(ReplicatedStorage.Packages.network) 

	local TestNetwork = Network.Server.new("Test")
	TestNetwork:append("method", function(player)
		return ("hi, %s!"):format(player.Name)
	end)

	-- Dispatch the network to workspace:
	TestNetwork:dispatch(workspace) 

	-- Client
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local network = require(ReplicatedStorage.Packages.network) 

	-- Get the network of name "Test", dispatched to workspace
	local testNetwork = network.client.fromParent("Test", workspace)
	print(testNetwork.method()) --> "hi, bubshayz!"
	```
]=]

function networkClient.fromParent(name: string, parent: Instance): any
	return Promise.new(function(resolve)
		resolve(getAbstractOfNetworkFolder(parent:WaitForChild(name)))
	end)
end

return table.freeze(networkClient)
