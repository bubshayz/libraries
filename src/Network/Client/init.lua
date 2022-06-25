--[=[
	@class networkClient

	The client counterpart of the Network module.
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
	Returns an array of *all* network objects dispatched to `parent`.

	```lua
	-- Server
	local Network = require(...) 

	local networkObject1 = Network.new("Test1", workspace)
	networkObject:append("status", "not good mate")
	networkObject:dispatch()

	local networkObject2 = Network.new("Test2", workspace)
	networkObject:append("status", "good mate!")
	networkObject:dispatch()

	-- Client
	local Network = require(...) 

	for _, networkObject in Network.allFromParent(workspace) do
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
	@return Promise<DispatchedNetworkObject: {[string]: any}>

	Returns a [promise](https://eryn.io/roblox-lua-promise/) which is resolved 
	(with the network object)  once a network object of name i.e `name`, is 
	found in `parent`.
]=]

function networkClient.fromParent(name: string, parent: Instance): any
	return Promise.new(function(resolve)
		resolve(getAbstractOfNetworkFolder(parent:WaitForChild(name)))
	end)
end

return table.freeze(networkClient)
