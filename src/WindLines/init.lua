-- ORIGINAL AUTHOR: boatbomber

--[=[
	@interface WindLinesConfig  
	@within WindLines	
	.lifetime number -- The life time of wind lines.
	.direction number -- The direction of wind lines.
	.speed number -- The speed at which wind lines move.
	.spawnRate number -- The rate at which wind lines are created.
	.raycastParams RaycastParams -- A `RaycastParams` object, to be used in determining if the player is under a roof or not.
	This is a config template, none of these members are required in the config table when configuring WindLines through [WindLines.SetConfig], however
	the config table must not be empty!
]=]

--[=[
	@interface DefaultWindLinesConfig 
	@within WindLines	
	.lifetime 3 
	.direction Vector3.xAxis 
	.speed 6 
	.spawnRate 25
	.raycastParams nil
	
	This is the **default** config template that WindLines initially uses. You can configure WindLines through [WindLines.SetConfig].
]=]

--[=[ 
	@class WindLines
	WindLines is a fork of boatbomber's wind lines module, however it is heavily refactored and has a few slight changes 
	in behavior. Overall, it is a module for creating wind line effects.
]=]

--[=[ 
	@prop effectStarted Signal <>
	@within WindLines
	@tag Signal
	@readonly
	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the wind lines effect starts.
]=]

--[=[ 
	@prop effectStopped Signal <>
	@within WindLines
	@tag Signal
	@readonly
	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the wind lines effect stops.
]=]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Signal = require(script.Parent.Signal)
local WindLine = require(script.WindLine)
local Janitor = require(script.Parent.Janitor)
local t = require(script.Parent.t)
local types = require(script.types)

local WIND_POSITION_OFFSET = Vector3.new(0, 0.1, 0)
local CAMERA_CEILING_Y_VECTOR = Vector3.new(0, 1000, 0)
local DEFAULT_CONFIG = {
	lifetime = 3,
	direction = Vector3.xAxis,
	speed = 6,
	spawnRate = 25,
}

local ConfigInterface = t.strictInterface({
	lifetime = t.integer,
	direction = t.Vector3,
	speed = t.integer,
	spawnRate = t.integer,
	raycastParams = t.RaycastParams,
})

local camera = Workspace.CurrentCamera
local isStarted = false
local isEffectStarted = false
local heartbeatUpdateConnection

local WindLines = {
	effectStarted = Signal.new(),
	effectStopped = Signal.new(),
	_janitor = Janitor.new(),
	_updateQueue = table.create(30),
	_updateQueueFinished = Signal.new(),
	_config = {},
}

--[=[
	Returns a boolean indicating if the wind lines effect is started.
]=]

function WindLines.isEffectStarted(): boolean
	return isEffectStarted
end

--[=[
	Returns a boolean indicating if WindLines (the module it self) is started through [WindLines.start].
]=]

function WindLines.isStarted(): boolean
	return isStarted
end

--[=[
	@param newConfig WindLinesConfig

	Sets the current config of WindLines to `newConfig`, so that this new config will be used for wind line effects.

	:::warning
	You cannot configure WindLines once it is started, so always make sure to call this method **before** you start WindLines!
	:::
]=]

function WindLines.setConfig(newConfig: types.WindLinesConfig)
	assert(not WindLines.isStarted(), "Cannot configure WindLines now as WindLines is started!")
	assert(next(newConfig), "Config table must not be empty!")

	ConfigInterface(newConfig)

	-- Copy over the new config to the current config as directly setting it will
	-- cause an error since WindLines is table.freezed:
	for key, value in newConfig do
		WindLines._config[key] = value
	end
end

--[=[
	Starts up the wind lines effect.

	:::tip
	If the player is standing under a roof, then the wind lines effect will be stopped for realism purposes and this
	behavior cannot be toggled. However, you can adjust this behavior through [WindLines:SetConfig] through the 
	[RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams) member, since ray casting 
	is used in determining if the player is standing under a roof. 

	E.g, the following config does not consider descendants in the `filteredPartsFolder` folder as roofs, 
	so if a player stands under them, the wind lines effect will not be stopped:

	```lua
	local Workspace = game:GetService("Workspace")

	local WindLines = require(...)

	local filteredPartsFolder = Workspace.SomeFolder
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {filteredPartsFolder} 

	WindLines.setConfig({RaycastParams = raycastParams})
	WindLines.start()
	```
	:::
]=]

function WindLines.start()
	assert(not WindLines.isStarted(), "Cannot start wind lines effect again as it is already started!")

	isStarted = true
	WindLines._startHeartbeatUpdate()

	WindLines._janitor:Add(function()
		isStarted = false
		isEffectStarted = false
	end)

	WindLines._janitor:Add(function()
		local function UpdateQueueFinished()
			heartbeatUpdateConnection:Disconnect()
			WindLines._updateQueueFinished:DisconnectAll()
		end

		if #WindLines._updateQueue == 0 then
			UpdateQueueFinished()
		else
			WindLines._updateQueueFinished:Connect(UpdateQueueFinished)
		end
	end)
end

--[=[
	Stops the wind lines effect.
]=]

function WindLines.stop()
	assert(WindLines.isStarted(), "Cannot stop wind lines effect as it is not started!")

	WindLines._janitor:Cleanup()
end

function WindLines._startHeartbeatUpdate()
	local lastClockSinceWindLineSpawned = os.clock()
	local config = WindLines._config
	local spawnRate = 1 / config.spawnRate

	heartbeatUpdateConnection = RunService.Heartbeat:Connect(function()
		local clockNow = os.clock()
		local isCameraUnderPart = Workspace:Raycast(
			camera.CFrame.Position,
			CAMERA_CEILING_Y_VECTOR,
			config.RaycastParams
		) ~= nil

		if (clockNow - lastClockSinceWindLineSpawned) > spawnRate and isStarted then
			if not isCameraUnderPart then
				if not isEffectStarted then
					isEffectStarted = true
					WindLines.effectStarted:Fire()
				end

				WindLine.new(config, WindLines._updateQueue)
				lastClockSinceWindLineSpawned = clockNow
			elseif WindLines.isEffectStarted() then
				isEffectStarted = false
				WindLines.effectStopped:Fire()
			end
		end

		for _, windLine in WindLines._updateQueue do
			local aliveTime = clockNow - windLine.startClock

			if aliveTime >= windLine.lifetime then
				windLine:destroy()
				continue
			end

			windLine.trail.MaxLength = 20 - (20 * (aliveTime / windLine.lifetime))

			local seededClock = (clockNow + windLine.seed) * (windLine.speed * 0.2)
			local startPosition = windLine.position

			windLine.attachment0.WorldPosition = (
				CFrame.new(startPosition, startPosition + windLine.direction)
				* CFrame.new(0, 0, windLine.speed * -aliveTime)
			).Position + Vector3.new(
				math.sin(seededClock) * 0.5,
				math.sin(seededClock) * 0.8,
				math.sin(seededClock) * 0.5
			)

			windLine.attachment1.WorldPosition = windLine.attachment0.WorldPosition + WIND_POSITION_OFFSET
		end

		if #WindLines._updateQueue == 0 and not isStarted then
			WindLines._updateQueueFinished:Fire()
		end
	end)
end

WindLines.setConfig(DEFAULT_CONFIG)

return table.freeze(WindLines)
