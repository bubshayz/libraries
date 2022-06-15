--[=[
	@interface WindLinesConfig  
	@within WindLines	
	.Lifetime number -- The life time of wind lines.
	.Direction number -- The direction of wind lines.
	.Speed number -- The speed at which wind lines move.
	.SpawnRate number -- The rate at which wind lines are created.
	.RaycastParams RaycastParams -- A `RaycastParams` object, to be used in determining if the player is under a roof or not.

	This is a config template, none of these members are required in the config table when configuring WindLines through [WindLines.SetConfig], however
	the config table must not be empty!
]=]

--[=[
	@interface DefaultWindLinesConfig 
	@within WindLines	

	.Lifetime 3 
	.Direction Vector3.xAxis 
	.Speed 6 
	.SpawnRate 25
	.RaycastParams nil
	
	This is the **default** config template that WindLines initially uses. You can configure WindLines through [WindLines.SetConfig].
]=]

--[=[ 
	@class WindLines

	WindLines is a fork of boatbomber's wind lines module, however it is heavily refactored and has a few slight changes 
	in behavior. Overall, it is a module for creating wind line effects.
]=]

--[=[ 
	@prop EffectStarted Signal <>
	@within WindLines
	@tag Signal
	@readonly

	A [signal](https://sleitnick.github.io/RbxUtil/api/Signal/) which is fired whenever the wind lines effect starts.
]=]

--[=[ 
	@prop EffectStopped Signal <>
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
local Types = require(script.Types)

local INVALID_ARGUMENT_TYPE = "Invalid argument#%d to %s. Expected %s, but got %s instead."
local WIND_POSITION_OFFSET = Vector3.new(0, 0.1, 0)
local CAMERA_CEILING_Y_VECTOR = Vector3.new(0, 1000, 0)
local CONFIG_TEMPLATE = {
	Lifetime = "number",
	Direction = "Vector3",
	Speed = "number",
	SpawnRate = "number",
	RaycastParams = "RaycastParams",
}

local camera = Workspace.CurrentCamera

local WindLines = {
	EffectStarted = Signal.new(),
	EffectStopped = Signal.new(),
	_janitor = Janitor.new(),
	_config = {
		Lifetime = 3,
		Direction = Vector3.xAxis,
		Speed = 6,
		SpawnRate = 25,
		RaycastParams = nil,
	},
	_updateQueue = table.create(30),
	_updateQueueFinished = Signal.new(),
	_isStarted = false,
	_isWindLinesEffectStarted = false,
}

--[=[
	Returns a boolean indicating if the wind lines effect has started.
]=]

function WindLines.IsEffectStarted(): boolean
	return WindLines._isWindLinesEffectStarted
end

--[=[
	Returns a boolean indicating if WindLines, the module it self, is started through [WindLines.Start].
]=]

function WindLines.IsStarted(): boolean
	return WindLines._isStarted
end

--[=[
	@param newConfig WindLinesConfig

	Sets the current config of WindLines to `newConfig`, which means that this new config will be used for wind line effects.

	:::warning
	You cannot configure WindLines once it is started, so always make sure to call this method **before** you start WindLines!
	:::
]=]

function WindLines.SetConfig(newConfig: Types.WindLinesConfig)
	assert(not WindLines._isStarted, "Cannot configure WindLines now as WindLines is started!")
	assert(typeof(newConfig) == "table", INVALID_ARGUMENT_TYPE:format(1, "WindLines.SetConfig", "table", typeof(newConfig)))
	assert(next(newConfig), "Config table must not be empty!")

	local currentConfig = WindLines._config

	for key, value in newConfig do
		local expectedType = CONFIG_TEMPLATE[key]
		assert(expectedType, ('Config member "%s" is invalid.'):format(tostring(key)))
		assert(
			typeof(value) == expectedType,
			('Config must have member "%s" of type %s. Instead is of type %s.'):format(key, expectedType, typeof(value))
		)

		currentConfig[key] = value
	end
end

--[=[
	Starts up the wind lines effect.

	:::note
	If the player is standing under a roof, then the wind lines effect will be stopped for realism purposes and this
	behavior cannot be toggled. However, you can adjust this behavior through [WindLines:SetConfig] through the [RaycastParams](https://create.roblox.com/docs/reference/engine/datatypes/RaycastParams)
	member, since ray casting is used in determining if the player is standing under a roof. 

	E.g, the following config does not consider descendants in the `badParts` folder as roofs, so if a player stands under them, the wind
	lines effect will not be stopped:

	```lua
	local WindLines = require(...)

	local filteredPartsFolder = workspace.SomeFolder

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {filteredPartsFolder} 

	WindLines.SetConfig({RaycastParams = raycastParams})
	WindLines.Start()
	```
	:::
]=]

function WindLines.Start()
	assert(not WindLines._isStarted, "Cannot start wind lines effect again as it is already started!")

	WindLines._isStarted = true
	WindLines._startHeartbeatUpdate()

	WindLines._janitor:Add(function()
		WindLines._isStarted = false
		WindLines._isWindLinesEffectStarted = false
	end)

	WindLines._janitor:Add(function()
		local function UpdateQueueFinished()
			WindLines._heartbeatUpdateConnection:Disconnect()
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

function WindLines.Stop()
	assert(WindLines._isStarted, "Cannot stop wind lines effect as it is not started!")

	WindLines._janitor:Cleanup()
end

function WindLines._startHeartbeatUpdate()
	local config = WindLines._config
	local lastClockSinceWindLineSpawned = os.clock()
	local spawnRate = 1 / config.SpawnRate

	WindLines._heartbeatUpdateConnection = RunService.Heartbeat:Connect(function()
		local clockNow = os.clock()
		local isCameraUnderPart = Workspace:Raycast(camera.CFrame.Position, CAMERA_CEILING_Y_VECTOR, config.RaycastParams) ~= nil

		if (clockNow - lastClockSinceWindLineSpawned) > spawnRate and WindLines._isStarted then
			if not isCameraUnderPart then
				if not WindLines._isWindLinesEffectStarted then
					WindLines._isWindLinesEffectStarted = true
					WindLines.EffectStarted:Fire()
				end

				WindLine.new(WindLines._config, WindLines._updateQueue)
				lastClockSinceWindLineSpawned = clockNow
			elseif WindLines._isWindLinesEffectStarted then
				WindLines._isWindLinesEffectStarted = false
				WindLines.EffectStopped:Fire()
			end
		end

		for _, windLine in WindLines._updateQueue do
			local aliveTime = clockNow - windLine.StartClock

			if aliveTime >= windLine.Lifetime then
				windLine:Destroy()
				continue
			end

			windLine.Trail.MaxLength = 20 - (20 * (aliveTime / windLine.Lifetime))

			local seededClock = (clockNow + windLine.Seed) * (windLine.Speed * 0.2)
			local startPosition = windLine.Position

			windLine.Attachment0.WorldPosition = (CFrame.new(startPosition, startPosition + windLine.Direction) * CFrame.new(
				0,
				0,
				windLine.Speed * -aliveTime
			)).Position + Vector3.new(math.sin(seededClock) * 0.5, math.sin(seededClock) * 0.8, math.sin(seededClock) * 0.5)

			windLine.Attachment1.WorldPosition = windLine.Attachment0.WorldPosition + WIND_POSITION_OFFSET
		end

		if #WindLines._updateQueue == 0 and not WindLines._isStarted then
			WindLines._updateQueueFinished:Fire()
		end
	end)
end

return table.freeze(WindLines)
