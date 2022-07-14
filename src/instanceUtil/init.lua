local PhysicsService = game:GetService("PhysicsService")
local Workspace = game:GetService("Workspace")

local DEFAULT_PHYSICS_COLLISION_GROUP = "Default"
local DEFAULT_INSTANCE_PHYSICAL_PROPERTIES = PhysicalProperties.new(Enum.Material.Plastic)
local VOXEL_GRID_RESOLUTION = 4
local DEFAULT_DEPTH = 0.01

--[=[ 
    @class instanceUtil

    A utility module for working with instances.
 
    ```lua
    instanceUtil.setInstanceAttributes(workspace.Baseplate, {IsCool = true})
    print(workspace.Baseplate:GetAttributes()) --> {IsCool = true}
    ```
]=]

local instanceUtil = {}

--[=[
    Sets the properties of `instance` from the `properties` table.

    ```lua
    instanceUtil.setInstanceProperties(workspace.Baseplate, {Transparency = 1})
    print(workspace.Baseplate.Transparency) --> 1
    ```
]=]

function instanceUtil.setInstanceProperties(instance: Instance, properties: { [string]: any })
	for property, value in properties do
		instance[property] = value
	end
end

--[=[
    Sets the attributes of `instance` from the `attributes` table.

    ```lua
    instanceUtil.setInstanceAttributes(workspace.Baseplate, {IsMayoSauce = true})
    print(workspace.Baseplate:GetAttribute("IsMayoSauce")) --> true
    ```
]=]

function instanceUtil.setInstanceAttributes(instance: Instance, attributes: { [string]: any })
	for attribute, value in attributes do
		instance:SetAttribute(attribute, value)
	end
end

--[=[
    Sets the collision group of `instance` to `collisionGroup`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
    (BaseParts only) will have their collision group set to `collisionGroup`.

    ```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PhysicsService = game:GetService("PhysicsService")
    local Workspace = game:GetService("Workspace")

    PhysicsService:CreateCollisionGroup("Test")

    instanceUtil.setInstancePhysicsCollisionGroup(Workspace.Baseplate, "Test")
    instanceUtil.setInstancePhysicsCollisionGroup(Workspace.SomeModel, "Test")
    ```
]=]

function instanceUtil.setInstancePhysicsCollisionGroup(instance: Instance, collisionGroup: string)
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
    Sets the collision group of `instance` to `Default`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
    (BaseParts only) will have their collision group set to `"Default"`.

    ```lua
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local PhysicsService = game:GetService("PhysicsService")
    local Workspace = game:GetService("Workspace")

    PhysicsService:CreateCollisionGroup("Test")

    instanceUtil.setInstancePhysicsCollisionGroup(Workspace.Baseplate, "Test")
    instanceUtil.setInstancePhysicsCollisionGroup(Workspace.SomeModel, "Test")

    -- Okay on second thought, let's actually remove the collision group from these
    -- instances:
    instanceUtil.resetInstancePhysicsCollisionGroup(Workspace.Baseplate)
    instanceUtil.resetInstancePhysicsCollisionGroup(Workspace.SomeModel)
    ```
]=]

function instanceUtil.resetInstancePhysicsCollisionGroup(instance: Instance)
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
    Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to `physicalProperties`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
    (BaseParts only) will have their physical properties set to `physicalProperties`.

    ```lua
    local Workspace = game:GetService("Workspace")

    instanceUtil.setInstancePhysicalProperties(Workspace.Baseplate, PhysicalProperties.new(5, 2, 3))

    print(Workspace.Baseplate.Density) --> 5
    print(Workspace.Baseplate.Elasticity) --> 2
    print(Workspace.Baseplate.ElasticityWeight) --> 3
    ```
]=]

function instanceUtil.setInstancePhysicalProperties(instance: Instance, physicalProperties: PhysicalProperties)
	if instance:IsA("BasePart") then
		instance.CustomPhysicalProperties = physicalProperties
	else
		for _, descendant in instance:GetDescendants() do
			if not descendant:IsA("BasePart") then
				continue
			end

			descendant.CustomPhysicalProperties = physicalProperties
		end
	end
end

--[=[
    Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to the default, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`
    (BaseParts only) will have their physical properties set to the default.

    ```lua
    local Workspace = game:GetService("Workspace")

    instanceUtil.setInstancePhysicalProperties(Workspace.Baseplate, PhysicalProperties.new(5, 2, 3))
    
    print(Workspace.Baseplate.Density) --> 5
    print(Workspace.Baseplate.Elasticity) --> 2
    print(Workspace.Baseplate.ElasticityWeight) --> 3

    -- Okay on second thought, let's remove the physical properties
    -- we've set on the instance:
    instanceUtil.resetInstancePhysicalProperties(Workspace.Baseplate)
    
    print(Workspace.Baseplate.Density) --> 0.7
    print(Workspace.Baseplate.Elasticity) --> 0.5
    print(Workspace.Baseplate.ElasticityWeight) --> 1
    ```
]=]

function instanceUtil.resetInstancePhysicalProperties(instance: Instance)
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
    Returns a read-only dictionary of all corners of `instance`, top and bottom.
]=]

function instanceUtil.getInstanceCorners(instance: BasePart): { top: { Vector3 }, bottom: { Vector3 } }
	local size = instance.Size

	local frontFaceCenter = (instance.CFrame + instance.CFrame.LookVector * size.Z / 2)
	local backFaceCenter = (instance.CFrame - instance.CFrame.LookVector * size.Z / 2)
	local topFrontEdgeCenter = frontFaceCenter + frontFaceCenter.UpVector * size.Y / 2
	local bottomFrontEdgeCenter = frontFaceCenter - frontFaceCenter.UpVector * size.Y / 2
	local topBackEdgeCenter = backFaceCenter + backFaceCenter.UpVector * size.Y / 2
	local bottomBackEdgeCenter = backFaceCenter - backFaceCenter.UpVector * size.Y / 2

	return table.freeze({
		bottom = table.freeze({
			(bottomBackEdgeCenter + bottomBackEdgeCenter.RightVector * size.X / 2).Position,
			(bottomBackEdgeCenter - bottomBackEdgeCenter.RightVector * size.X / 2).Position,
			(bottomFrontEdgeCenter + bottomFrontEdgeCenter.RightVector * size.X / 2).Position,
			(bottomFrontEdgeCenter - bottomFrontEdgeCenter.RightVector * size.X / 2).Position,
		}),

		top = table.freeze({
			(topBackEdgeCenter + topBackEdgeCenter.RightVector * size.X / 2).Position,
			(topBackEdgeCenter - topBackEdgeCenter.RightVector * size.X / 2).Position,
			(topFrontEdgeCenter + topFrontEdgeCenter.RightVector * size.X / 2).Position,
			(topFrontEdgeCenter - topFrontEdgeCenter.RightVector * size.X / 2).Position,
		}),
	})
end

--[=[
    Returns the material the instance is lying on. If `instance` is underwater, then `Enum.Material.Water` will be returned, elseif
    `instance` is in air, then `Enum.Material.Air` will be returned.
    
    - The 2nd argument can be passed as a [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) object,
    which will be used in determining the material of `instance` through ray casting.
         
    - The 3rd argument can be passed as a number (depth) which will increase the length 
    of the ray by `depth` studs (on the Y-axis). This is only useful when you want to add 
    in more leeway in determining the material of `instance` **reliably**, since sometimes
    the instance may be very slightly over the top of some ground due to its geometry so in those cases,
    the ray may not register properly. If this argument isn't specified, then it will default to `0.01`.
]=]

function instanceUtil.getInstanceFloorMaterial(
	instance: BasePart,
	raycastParams: RaycastParams?,
	depth: number?
): EnumItem
	depth = depth or DEFAULT_DEPTH

	if instanceUtil._isInstanceInWater(instance) then
		return Enum.Material.Water
	end

	local groundInstanceMaterial = instanceUtil._getGroundInstanceMaterial(instance, raycastParams, depth :: number)

	if groundInstanceMaterial then
		return groundInstanceMaterial
	end

	return Enum.Material.Air
end

--[=[
    Sets the network owner of `instance` to `networkOwner` *safely*.

    :::tip Safe to call
    This method should be preferred over directly setting the network owner of `instance` 
    via [SetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#SetNetworkOwner), as
    it won't error in cases where the network ownership API cannot be used on `instance`.
    ::: 
]=]

function instanceUtil.setInstanceNetworkOwner(instance: BasePart, networkOwner: Player?)
	if not instance:CanSetNetworkOwnership() then
		return
	end

	instance:SetNetworkOwner(networkOwner)
end

--[=[
    Returns the network owner of `instance` *safely*.
    
    :::tip Safe to call
    This method should be preferred over directly getting the network owner of `instance` 
    via [GetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#GetNetworkOwner), as
    it will safely return `nil` (instead of erroring) in cases where the network ownership API cannot be used on `instance`!
    ::: 
]=]

function instanceUtil.getInstanceNetworkOwner(instance: BasePart): Instance?
	if instance:IsGrounded() then
		return nil
	end

	return instance:GetNetworkOwner()
end

function instanceUtil._getGroundInstanceMaterial(
	instance: BasePart,
	raycastParams: RaycastParams?,
	depth: number
): EnumItem?
	local corners = instanceUtil.getInstanceCorners(instance)
	local depthVector = Vector3.new(0, depth, 0)

	for index, cornerPosition in corners.top do
		local bottomCornerPosition = corners.bottom[index]
		local ray =
			Workspace:Raycast(cornerPosition, (bottomCornerPosition - cornerPosition) - depthVector, raycastParams)

		if ray then
			return ray.Material
		end
	end

	return nil
end

function instanceUtil._isInstanceInWater(instance: BasePart): boolean
	local halfSize = instance.Size / 2

	return Workspace.Terrain:ReadVoxels(
		Region3.new(instance.Position - halfSize, instance.Position + halfSize):ExpandToGrid(VOXEL_GRID_RESOLUTION),
		VOXEL_GRID_RESOLUTION
	)[1][1][1] == Enum.Material.Water
end

return table.freeze(instanceUtil)
