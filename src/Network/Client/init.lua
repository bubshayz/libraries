--[=[
	@class NetworkClient

	The client counterpart of the Network module.
]=]

local packages = script.Parent.Parent
local ancestor = script.Parent

local SharedConstants = require(ancestor.SharedConstants)
local Promise = require(packages.Promise)
local ClientRemoteSignal = require(script.ClientRemoteSignal)
local ClientRemoteProperty = require(script.ClientRemoteProperty)

local NetworkClient = {}

local function GetNetworkFoldersFromParent(parent: Instance): { Folder }
	local networkFolders = {}

	for _, networkFolder in parent:GetChildren() do
		if not networkFolder:GetAttribute(SharedConstants.Attribute.NetworkFolder) then
			continue
		end

		table.insert(networkFolders, networkFolder)
	end

	return networkFolders
end

--[=[
	Returns an array of *all* network objects dispatched to `parent`.

	```lua
	-- Server
	local Network = require(...) 

	local networkObject1 = Network.new("Test1", workspace)
	networkObject:Append("status", "not good mate")
	networkObject:Dispatch()

	local networkObject2 = Network.new("Test2", workspace)
	networkObject:Append("status", "good mate!")
	networkObject:Dispatch()

	-- Client
	local Network = require(...) 

	for _, networkObject in Network.AllFromParent(workspace) do
		print(networkObject.status) 
	end

	--> "not good mate"
	--> "good mate!"
	```
]=]

function NetworkClient.AllFromParent(parent: Instance): { [string]: { [string]: any } }
	assert(
		typeof(parent) == "Instance",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "Network.AllFromParent", "Instance", typeof(parent))
	)

	local networks = {}

	for _, networkFolder in GetNetworkFoldersFromParent(parent) do
		networks[networkFolder.Name] = NetworkClient._getAbstractOfNetworkFolder(networkFolder)
	end

	return networks
end

--[=[
	@return Promise<DispatchedNetworkObject: {[string]: any}>

	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved (with the network object) 
	once a network object of name i.e `name`, is found in `parent`.
]=]

function NetworkClient.FromName(name: string, parent: Instance): any
	assert(
		typeof(name) == "string",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(1, "Network.FromName", "string", typeof(name))
	)
	assert(
		typeof(parent) == "Instance",
		SharedConstants.ErrorMessage.InvalidArgumentType:format(2, "Network.FromName", "Instance", typeof(parent))
	)

	return Promise.new(function(resolve)
		resolve(NetworkClient._getAbstractOfNetworkFolder(parent:WaitForChild(name)))
	end)
end

function NetworkClient._getAbstractOfNetworkFolder(networkFolder: Folder): { any }
	local abstract = {}

	for _, descendant in networkFolder:GetChildren() do
		if descendant:GetAttribute(SharedConstants.Attribute.BoundToRemoteSignal) then
			abstract[descendant.Name] = ClientRemoteSignal.new(descendant)
			continue
		elseif descendant:GetAttribute(SharedConstants.Attribute.BoundToRemoteProperty) then
			abstract[descendant.Name] = ClientRemoteProperty.new(descendant)
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

function NetworkClient._init()
	for _, module in script:GetChildren() do
		NetworkClient[module.Name] = require(module)
	end
end

NetworkClient._init()

return table.freeze(NetworkClient)
