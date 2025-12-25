-- System by @thehandofvoid
-- Modified by @jay_peaceee
--CastingSystem module

local CastingSystem = {}
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local FishingConfig = require(RepStorage:WaitForChild("FishingConfig"))

local hooksFolder = RepStorage:WaitForChild("Assets"):WaitForChild("Hook")

function CastingSystem:IsPositionInWater(position)
	local rayOrigin = position + Vector3.new(0, 5, 0)
	local rayDirection = Vector3.new(0, -10, 0)

	local raycastParams = RaycastParams.new()
	raycastParams.IgnoreWater = false 
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult then
		return raycastResult.Material == Enum.Material.Water
	end

	return false
end

function CastingSystem:IsWaterPart(part)
	if not part then return false end

	if CS:HasTag(part, "Water") then return true end
	if part.Parent and CS:HasTag(part.Parent, "Water") then return true end

	if part:IsA("Terrain") then
		return true 
	end

	local ancestor = part.Parent
	for _ = 1, 3 do
		if not ancestor then break end
		if CS:HasTag(ancestor, "Water") then return true end
		ancestor = ancestor.Parent
	end

	return false
end

function CastingSystem:GetWaterSurfaceY(xPosition, zPosition)
	local rayOrigin = Vector3.new(xPosition, 500, zPosition) 
	local rayDirection = Vector3.new(0, -1000, 0) 

	local raycastParams = RaycastParams.new()
	raycastParams.IgnoreWater = false
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = {workspace.Terrain}

	local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if raycastResult and raycastResult.Material == Enum.Material.Water then
		return raycastResult.Position.Y
	end

	return nil
end

function CastingSystem:CreateHook(position, rodName)
	local config = FishingConfig.GetRodConfig(rodName)
	local hookTemplate = hooksFolder:FindFirstChild(config.hookName) or hooksFolder:FindFirstChild("BasicHook")

	local customHook

	if hookTemplate then
		customHook = hookTemplate:Clone()
		customHook.Position = position
		customHook.Name = "FishingHook"
		customHook.CanCollide = false
		customHook.CanTouch = true
		customHook.Anchored = false
		customHook.Parent = workspace
	else
		customHook = Instance.new("Part")
		customHook.Name = "FishingHook"
		customHook.Size = Vector3.new(0.3, 0.3, 0.3)
		customHook.Shape = Enum.PartType.Ball
		customHook.Position = position
		customHook.BrickColor = BrickColor.new("Dark red")
		customHook.CanCollide = false
		customHook.CanTouch = true
		customHook.Material = Enum.Material.Metal
		customHook.Anchored = false
		customHook.Parent = workspace
	end

	return customHook
end

function CastingSystem:CreateBeam(rodPart, attachment1, attachment2, rodName)
	local config = FishingConfig.GetRodConfig(rodName)

	local beam = Instance.new("Beam")
	beam.Attachment0 = attachment1
	beam.Attachment1 = attachment2
	beam.FaceCamera = true
	beam.Width0 = config.beamWidth
	beam.Width1 = config.beamWidth
	beam.Name = "Line"
	beam.Color = ColorSequence.new(config.beamColor)
	beam.Transparency = NumberSequence.new(0.1)
	beam.Parent = rodPart

	return beam
end

function CastingSystem:CalculateVelocity(startPosition, playerDirection, power, maxPower)
	local maxRange = 30
	local actualDistance = math.clamp((power / maxPower) * maxRange, 8, maxRange)

	local timeOfFlight = math.max(actualDistance / 25, 0.5)
	local horizontalVelocity = actualDistance / timeOfFlight
	local verticalVelocity = 5

	return Vector3.new(
		playerDirection.X * horizontalVelocity,
		verticalVelocity,
		playerDirection.Z * horizontalVelocity
	)
end

return CastingSystem