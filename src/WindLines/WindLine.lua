local Workspace = game:GetService("Workspace")

local Types = require(script.Parent.Types)

local WIND_POSITION_OFFSET = Vector3.new(0, 0.1, 0)
local TRAIL_TRANSPARENCY = NumberSequence.new(0.7)
local TRAIL_WIDTH_SCALE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(0.2, 1),
	NumberSequenceKeypoint.new(0.8, 1),
	NumberSequenceKeypoint.new(1, 0.3),
})

local terrain = Workspace.Terrain
local camera = Workspace.CurrentCamera

local WindLine = { __index = {} }

function WindLine.new(currentConfig: Types.WindLinesConfig, updateQueue: { any }): WindLine
	local self = setmetatable({
		lifetime = currentConfig.lifetime + (math.random(-10, 10) * 0.1),
		speed = currentConfig.speed + (math.random(-10, 10) * 0.1),
		startClock = os.clock(),
		seed = math.random(1, 1000) * 0.1,
		_updateQueue = updateQueue,
		_currentConfig = currentConfig,
	}, WindLine)

	self:_init()
	return self
end

function WindLine.is(self: any): boolean
	return getmetatable(self) == WindLine
end

function WindLine.__index:destroy()
	table.remove(self._updateQueue, table.find(self._updateQueue, self))

	self.attachment0:Destroy()
	self.trail:Destroy()
	self.attachment1:Destroy()
end

function WindLine.__index:_init()
	local position = self._currentConfig.Position
		or (camera.CFrame * CFrame.Angles(math.rad(math.random(-30, 70)), math.rad(math.random(-80, 80)), 0))
			* CFrame.new(0, 0, math.random(200, 600) * -0.1).Position

	local attachment0 = Instance.new("Attachment")
	local attachment1 = Instance.new("Attachment")

	local trail = Instance.new("Trail")
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.WidthScale = TRAIL_WIDTH_SCALE
	trail.Transparency = TRAIL_TRANSPARENCY
	trail.FaceCamera = true
	trail.Parent = attachment0
	attachment0.WorldPosition = position
	attachment1.WorldPosition = position + WIND_POSITION_OFFSET
	attachment0.Parent = terrain
	attachment1.Parent = terrain

	self.attachment0 = attachment0
	self.attachment1 = attachment1
	self.trail = trail
	self.position = position
	self.direction = position

	table.insert(self._updateQueue, self)
end

export type WindLine = typeof(setmetatable(
	{} :: {
		lifetime: string,
		speed: number,
		startClock: number,
		seed: number,
		_updateQueue: { WindLine },
		_currentConfig: Types.WindLinesConfig,
	},
	WindLine
))

return WindLine
