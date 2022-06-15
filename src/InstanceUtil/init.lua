--[=[ 
	@class InstanceUtil

	A utility module for working with instances.
 
	```lua
	local InstanceUtil = require(...)

	InstanceUtil.SetInstanceAttributes(workspace.Baseplate, {IsCool = true})
	print(workspace.Baseplate:GetAttributes()) --> {IsCool = true}
	```
]=]

local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

local DEFAULT_PHYSICS_COLLISION_GROUP = "Default"
local DEFAULT_INSTANCE_PHYSICAL_PROPERTIES = PhysicalProperties.new(1)
local VOXEL_GRID_RESOLUTION = 4
local DEFAULT_DEPTH = 0.01

local InstanceUtil = {}

--[=[
	Sets the properties of `instance` from the `properties` table.

	```lua
	local InstanceUtil = require(...)

	InstanceUtil.SetInstanceProperties(workspace.Baseplate, {Transparency = 1})
	print(workspace.Baseplate.Transparency) --> 1
	```
]=]

function InstanceUtil.SetInstanceProperties(instance: Instance, properties: { [string]: any })
	for property, value in properties do
		instance[property] = value
	end
end

--[=[
	Sets the attributes of `instance` from the `attributes` table.

	```lua
	local InstanceUtil = require(...)

	InstanceUtil.SetInstanceAttributes(workspace.Baseplate, {IsMayoSauce = true})
	print(workspace.Baseplate:GetAttribute("IsMayoSauce")) --> true
	```
]=]

function InstanceUtil.SetInstanceAttributes(instance: Instance, attributes: { [string]: any })
	for attribute, value in attributes do
		instance:SetAttribute(attribute, value)
	end
end

--[=[
	Sets the collision group of `instance` to `collisionGroup`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
	([BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)'s) will have their collision group set to `collisionGroup`.
]=]

function InstanceUtil.SetInstancePhysicsCollisionGroup(instance: Instance, collisionGroup: string)
	if instance:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(instance, collisionGroup)
	else
		for _, descendant in instance:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			PhysicsService:SetPartCollisionGroup(descendant, collisionGroup)
		end
	end
end

--[=[
	Sets the collision group of `instance` to the default collision group i.e `"Default"`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
	([BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)'s) will have their collision group set to `"Default"`.
]=]

function InstanceUtil.ResetInstancePhysicsCollisionGroup(instance: Instance)
	if instance:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(instance, DEFAULT_PHYSICS_COLLISION_GROUP)
	else
		for _, descendant in instance:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			PhysicsService:SetPartCollisionGroup(descendant, DEFAULT_PHYSICS_COLLISION_GROUP)
		end
	end
end

--[=[
	Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to match the `physicalProperties` table, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
	([BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)'s) will have their [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) set to match the `physicalProperties` table

	```lua
	local physicalProperties = {
		Density = 1
	}

	InstanceUtil.SetInstancePhysicalProperties(workspace.Baseplate, physicalProperties)
	```
]=]

function InstanceUtil.SetInstancePhysicalProperties(
	instance: Instance,
	physicalProperties: {
		Density: number?,
		Friction: number?,
		Elasticity: number?,
		FrictionWeight: number?,
		ElasticityWeight: number?,
	}
)
	local customPhysicalProperties = PhysicalProperties.new(
		physicalProperties.Density or DEFAULT_INSTANCE_PHYSICAL_PROPERTIES.Density,
		physicalProperties.Friction or DEFAULT_INSTANCE_PHYSICAL_PROPERTIES.Friction,
		physicalProperties.Elasticity or DEFAULT_INSTANCE_PHYSICAL_PROPERTIES.Elasticity,
		physicalProperties.FrictionWeight or DEFAULT_INSTANCE_PHYSICAL_PROPERTIES.FrictionWeight,
		physicalProperties.ElasticityWeight or DEFAULT_INSTANCE_PHYSICAL_PROPERTIES.ElasticityWeight
	)

	if instance:IsA("BasePart") then
		instance.CustomPhysicalProperties = customPhysicalProperties
	else
		for _, descendant in instance:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			descendant.CustomPhysicalProperties = customPhysicalProperties
		end
	end
end

--[=[
	Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to the default, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
	([BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart)'s) will have their [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) set to the default.
]=]

function InstanceUtil.ResetInstancePhysicalProperties(instance: Instance)
	if instance:IsA("BasePart") then
		instance.CustomPhysicalProperties = DEFAULT_INSTANCE_PHYSICAL_PROPERTIES
	else
		for _, descendant in instance:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			descendant.CustomPhysicalProperties = DEFAULT_INSTANCE_PHYSICAL_PROPERTIES
		end
	end
end

--[=[
	Returns a read only dictionary of all corners of `instance`, top and bottom.
]=]

function InstanceUtil.GetInstanceCorners(instance: Instance): { Top: { Vector3 }, Bottom: { Vector3 } }
	local size = instance.Size

	local frontFaceCenter = (instance.CFrame + instance.CFrame.LookVector * size.Z / 2)
	local backFaceCenter = (instance.CFrame - instance.CFrame.LookVector * size.Z / 2)
	local topFrontEdgeCenter = frontFaceCenter + frontFaceCenter.UpVector * size.Y / 2
	local bottomFrontEdgeCenter = frontFaceCenter - frontFaceCenter.UpVector * size.Y / 2
	local topBackEdgeCenter = backFaceCenter + backFaceCenter.UpVector * size.Y / 2
	local bottomBackEdgeCenter = backFaceCenter - backFaceCenter.UpVector * size.Y / 2

	return table.freeze({
		Bottom = table.freeze({
			(bottomBackEdgeCenter + bottomBackEdgeCenter.RightVector * size.X / 2).Position,
			(bottomBackEdgeCenter - bottomBackEdgeCenter.RightVector * size.X / 2).Position,
			(bottomFrontEdgeCenter + bottomFrontEdgeCenter.RightVector * size.X / 2).Position,
			(bottomFrontEdgeCenter - bottomFrontEdgeCenter.RightVector * size.X / 2).Position,
		}),

		Top = table.freeze({
			(topBackEdgeCenter + topBackEdgeCenter.RightVector * size.X / 2).Position,
			(topBackEdgeCenter - topBackEdgeCenter.RightVector * size.X / 2).Position,
			(topFrontEdgeCenter + topFrontEdgeCenter.RightVector * size.X / 2).Position,
			(topFrontEdgeCenter - topFrontEdgeCenter.RightVector * size.X / 2).Position,
		}),
	})
end

--[=[
	Returns the material the instance is lying on. 
	
	- The 2nd argument can be passed as a [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) object,
	which will be used in determining the material of `instance` through ray casting.
	     
	- The 3rd argument can be passed as a number (depth)
	which will increase the length of the ray by `depth` studs (on the Y axis). This is only useful
	when you want to add in more leeway in determining the material of `instance` **reliably**, since sometimes
	the instance may be very slightly over the top of some ground due to it's geometr so in those cases, the ray may not
	register properly. If this argument isn't specified, then it will default to `0.01`.
]=]

function InstanceUtil.GetInstanceFloorMaterial(instance: BasePart, raycastParams: RaycastParams?, depth: number?): EnumItem
	depth = depth or DEFAULT_DEPTH

	if InstanceUtil._isInstanceInWater(instance) then
		return Enum.Material.Water
	end

	local groundInstanceMaterial = InstanceUtil._getGroundInstanceMaterial(instance, raycastParams, depth)

	if groundInstanceMaterial then
		return groundInstanceMaterial
	end

	return Enum.Material.Air
end

--[=[
	Sets the network owner of `instance` to `networkOwner` **safely**.

	:::tip
	This method will safely return `nil` instead of erroring, if the network ownership API can't be used on `instance`. Hence this
	method should be preferred over directly setting the network owner of `instance` 
	via [SetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#SetNetworkOwner),
	::: 
]=]

function InstanceUtil.SetInstanceNetworkOwner(instance: BasePart, networkOwner: Player?)
	if not instance:CanSetNetworkOwnership() then
		return
	end

	instance:SetNetworkOwner(networkOwner)
end

--[=[
	Returns the network owner of `instance` **safely**.
	
	:::tip
	This method will safely return `nil` instead of erroring, if the network ownership API can't be used on `instance` . Hence this
	method should be preferred over directly getting the network owner of `instance` 
	via [GetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#GetNetworkOwner).
	::: 
]=]

function InstanceUtil.GetInstanceNetworkOwner(instance: BasePart): Player?
	if instance:IsGrounded() then
		return nil
	end

	return instance:GetNetworkOwner()
end

function InstanceUtil._getGroundInstanceMaterial(instance: Instance, raycastParams: RaycastParams?, depth: number): EnumItem?
	local corners = InstanceUtil.GetInstanceCorners(instance)
	local depthVector = Vector3.new(0, depth, 0)

	for index, cornerPosition in corners.Top do
		local bottomCornerPosition = corners.Bottom[index]
		local ray = Workspace:Raycast(cornerPosition, (bottomCornerPosition - cornerPosition) - depthVector, raycastParams)

		if ray then
			return ray.Material
		end
	end

	return nil
end

function InstanceUtil._isInstanceInWater(instance: BasePart): boolean
	local halfSize = instance.Size / 2

	return Workspace.Terrain:ReadVoxels(
		Region3.new(instance.Position - halfSize, instance.Position + halfSize):ExpandToGrid(VOXEL_GRID_RESOLUTION),
		VOXEL_GRID_RESOLUTION
	)[1][1][1] == Enum.Material.Water
end

return table.freeze(InstanceUtil)
