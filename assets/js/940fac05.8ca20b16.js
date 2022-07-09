"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[278],{90118:e=>{e.exports=JSON.parse('{"functions":[{"name":"setInstanceProperties","desc":"Sets the properties of `instance` from the `properties` table.\\n\\n```lua\\ninstanceUtil.setInstanceProperties(workspace.Baseplate, {Transparency = 1})\\nprint(workspace.Baseplate.Transparency) --\x3e 1\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"},{"name":"properties","desc":"","lua_type":"{ [string]: any }"}],"returns":[],"function_type":"static","source":{"line":30,"path":"src/instanceUtil/init.lua"}},{"name":"setInstanceAttributes","desc":"Sets the attributes of `instance` from the `attributes` table.\\n\\n```lua\\ninstanceUtil.setInstanceAttributes(workspace.Baseplate, {IsMayoSauce = true})\\nprint(workspace.Baseplate:GetAttribute(\\"IsMayoSauce\\")) --\x3e true\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"},{"name":"attributes","desc":"","lua_type":"{ [string]: any }"}],"returns":[],"function_type":"static","source":{"line":45,"path":"src/instanceUtil/init.lua"}},{"name":"setInstancePhysicsCollisionGroup","desc":"Sets the collision group of `instance` to `collisionGroup`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`\\n(BaseParts only) will have their collision group set to `collisionGroup`.\\n\\n```lua\\nlocal ReplicatedStorage = game:GetService(\\"ReplicatedStorage\\")\\nlocal PhysicsService = game:GetService(\\"PhysicsService\\")\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\nPhysicsService:CreateCollisionGroup(\\"Test\\")\\n\\ninstanceUtil.setInstancePhysicsCollisionGroup(Workspace.Baseplate, \\"Test\\")\\ninstanceUtil.setInstancePhysicsCollisionGroup(Workspace.SomeModel, \\"Test\\")\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"},{"name":"collisionGroup","desc":"","lua_type":"string"}],"returns":[],"function_type":"static","source":{"line":67,"path":"src/instanceUtil/init.lua"}},{"name":"resetInstancePhysicsCollisionGroup","desc":"Sets the collision group of `instance` to `Default`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`\\n(BaseParts only) will have their collision group set to `\\"Default\\"`.\\n\\n```lua\\nlocal ReplicatedStorage = game:GetService(\\"ReplicatedStorage\\")\\nlocal PhysicsService = game:GetService(\\"PhysicsService\\")\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\nPhysicsService:CreateCollisionGroup(\\"Test\\")\\n\\ninstanceUtil.setInstancePhysicsCollisionGroup(Workspace.Baseplate, \\"Test\\")\\ninstanceUtil.setInstancePhysicsCollisionGroup(Workspace.SomeModel, \\"Test\\")\\n\\n-- Okay on second thought, let\'s actually remove the collision group from these\\n-- instances:\\ninstanceUtil.resetInstancePhysicsCollisionGroup(Workspace.Baseplate)\\ninstanceUtil.resetInstancePhysicsCollisionGroup(Workspace.SomeModel)\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"}],"returns":[],"function_type":"static","source":{"line":102,"path":"src/instanceUtil/init.lua"}},{"name":"setInstancePhysicalProperties","desc":"Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to `physicalProperties`, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`\\n(BaseParts only) will have their physical properties set to `physicalProperties`.\\n\\n```lua\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\ninstanceUtil.setInstancePhysicalProperties(Workspace.Baseplate, PhysicalProperties.new(5, 2, 3))\\n\\nprint(Workspace.Baseplate.Density) --\x3e 5\\nprint(Workspace.Baseplate.Elasticity) --\x3e 2\\nprint(Workspace.Baseplate.ElasticityWeight) --\x3e 3\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"},{"name":"physicalProperties","desc":"","lua_type":"PhysicalProperties"}],"returns":[],"function_type":"static","source":{"line":131,"path":"src/instanceUtil/init.lua"}},{"name":"resetInstancePhysicalProperties","desc":"Sets the [PhysicalProperties](https://create.roblox.com/docs/reference/engine/datatypes/PhysicalProperties) of `instance` to the default, if it is a [BasePart](https://create.roblox.com/docs/reference/engine/classes/BasePart). Else, all the descendants of `instance`\\n(BaseParts only) will have their physical properties set to the default.\\n\\n```lua\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\ninstanceUtil.setInstancePhysicalProperties(Workspace.Baseplate, PhysicalProperties.new(5, 2, 3))\\n\\nprint(Workspace.Baseplate.Density) --\x3e 5\\nprint(Workspace.Baseplate.Elasticity) --\x3e 2\\nprint(Workspace.Baseplate.ElasticityWeight) --\x3e 3\\n\\n-- Okay on second thought, let\'s remove the physical properties\\n-- we\'ve set on the instance:\\ninstanceUtil.resetInstancePhysicalProperties(Workspace.Baseplate)\\n\\nprint(Workspace.Baseplate.Density) --\x3e 0.7\\nprint(Workspace.Baseplate.Elasticity) --\x3e 0.5\\nprint(Workspace.Baseplate.ElasticityWeight) --\x3e 1\\n```","params":[{"name":"instance","desc":"","lua_type":"Instance"}],"returns":[],"function_type":"static","source":{"line":168,"path":"src/instanceUtil/init.lua"}},{"name":"getInstanceCorners","desc":"Returns a read-only dictionary of all corners of `instance`, top and bottom.","params":[{"name":"instance","desc":"","lua_type":"BasePart"}],"returns":[{"desc":"","lua_type":"{ top: { Vector3 }, bottom: { Vector3 } }\\r\\n"}],"function_type":"static","source":{"line":186,"path":"src/instanceUtil/init.lua"}},{"name":"getInstanceFloorMaterial","desc":"Returns the material the instance is lying on. If `instance` is underwater, then `Enum.Material.Water` will be returned, elseif\\n`instance` is in air, then `Enum.Material.Air` will be returned.\\n\\n- The 2nd argument can be passed as a [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) object,\\nwhich will be used in determining the material of `instance` through ray casting.\\n     \\n- The 3rd argument can be passed as a number (depth) which will increase the length \\nof the ray by `depth` studs (on the Y-axis). This is only useful when you want to add \\nin more leeway in determining the material of `instance` **reliably**, since sometimes\\nthe instance may be very slightly over the top of some ground due to its geometry so in those cases,\\nthe ray may not register properly. If this argument isn\'t specified, then it will default to `0.01`.","params":[{"name":"instance","desc":"","lua_type":"BasePart"},{"name":"raycastParams","desc":"","lua_type":"RaycastParams?"},{"name":"depth","desc":"","lua_type":"number?\\r\\n"}],"returns":[{"desc":"","lua_type":"EnumItem\\r\\n"}],"function_type":"static","source":{"line":227,"path":"src/instanceUtil/init.lua"}},{"name":"setInstanceNetworkOwner","desc":"Sets the network owner of `instance` to `networkOwner` *safely*.\\n\\n:::tip Safe to call\\nThis method should be preferred over directly setting the network owner of `instance` \\nvia [SetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#SetNetworkOwner), as\\nit won\'t error in cases where the network ownership API cannot be used on `instance`.\\n::: ","params":[{"name":"instance","desc":"","lua_type":"BasePart"},{"name":"networkOwner","desc":"","lua_type":"Player?"}],"returns":[],"function_type":"static","source":{"line":257,"path":"src/instanceUtil/init.lua"}},{"name":"getInstanceNetworkOwner","desc":"Returns the network owner of `instance` *safely*.\\n\\n:::tip Safe to call\\nThis method should be preferred over directly getting the network owner of `instance` \\nvia [GetNetworkOwner](https://create.roblox.com/docs/reference/engine/classes/BasePart#GetNetworkOwner), as\\nit will safely return `nil` (instead of erroring) in cases where the network ownership API cannot be used on `instance`!\\n::: ","params":[{"name":"instance","desc":"","lua_type":"BasePart"}],"returns":[{"desc":"","lua_type":"Player?\\r\\n"}],"function_type":"static","source":{"line":275,"path":"src/instanceUtil/init.lua"}}],"properties":[],"types":[],"name":"instanceUtil","desc":" \\n\\nA utility module for working with instances.\\n \\n```lua\\ninstanceUtil.setInstanceAttributes(workspace.Baseplate, {IsCool = true})\\nprint(workspace.Baseplate:GetAttributes()) --\x3e {IsCool = true}\\n```","source":{"line":19,"path":"src/instanceUtil/init.lua"}}')}}]);