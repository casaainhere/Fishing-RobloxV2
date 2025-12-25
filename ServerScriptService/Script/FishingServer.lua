-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ServerScriptService/FishingServer (WITH !nextcatch FORCED FISH SUPPORT)
local ReplicatedStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local DataManager = require(ReplicatedStorage:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local FishingConfig = require(ReplicatedStorage:WaitForChild("FishingConfig"))
local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))

local fishGiverEvent = ReplicatedStorage:FindFirstChild("FishGiver")
local castReplicationEvent = ReplicatedStorage:FindFirstChild("CastReplication")
local cleanupCastEvent = ReplicatedStorage:FindFirstChild("CleanupCast")
local showNotificationEvent = ReplicatedStorage:FindFirstChild("ShowNotification")
local sellFishEvent = ReplicatedStorage:FindFirstChild("SellFish")

local fishFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Fish")
local fishModelFolder = ReplicatedStorage:WaitForChild("Assets"):FindFirstChild("FishModel")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")

local FISH_COOLDOWN = 0.5
local lastFishTime = {}
local fishPool = {}
local MAX_POOL_SIZE = 5
local originalTransparencies = {}

-- ===================================================================
-- ?? NEXTCATCH: STORAGE FOR FORCED FISH DATA
-- ===================================================================
local NextCatchData = {} -- Format: [UserId] = {fishName = "...", fishWeight = ...}

-- ===================================================================
-- ?? NEXTCATCH: CREATE REMOTEFUNCTION FOR CLIENT ACCESS
-- ===================================================================
local GetForcedFishFunction = ReplicatedStorage:FindFirstChild("GetForcedFish")
if not GetForcedFishFunction then
	GetForcedFishFunction = Instance.new("RemoteFunction")
	GetForcedFishFunction.Name = "GetForcedFish"
	GetForcedFishFunction.Parent = ReplicatedStorage
	print("? [FishingServer] Created GetForcedFish RemoteFunction")
end

-- ===================================================================
-- ?? NEXTCATCH: FUNCTION TO GET & CONSUME FORCED FISH
-- ===================================================================
GetForcedFishFunction.OnServerInvoke = function(player)
	local userId = player.UserId

	if NextCatchData[userId] then
		local data = NextCatchData[userId]
		NextCatchData[userId] = nil -- Consume (hapus setelah dipakai sekali)

		print(string.format("?? [NextCatch] Forced fish consumed by %s: %s (%.1fkg)", 
			player.Name, data.fishName, data.fishWeight))

		return {
			fishName = data.fishName,
			fishWeight = data.fishWeight
		}
	end

	return nil -- No forced fish
end

-- ===================================================================
-- ?? NEXTCATCH: GLOBAL FUNCTION TO SET FORCED FISH (Called by NextCatchCommand)
-- ===================================================================
_G.SetNextCatchData = function(userId, fishName, fishWeight)
	NextCatchData[userId] = {
		fishName = fishName,
		fishWeight = fishWeight
	}
	print(string.format("?? [NextCatch] Set forced fish for UserID %d: %s (%.1fkg)", 
		userId, fishName, fishWeight))
end

-- ===================================================================
-- HELPER: TAG ALL RODS IN FOLDER (Run once at startup)
-- ===================================================================
local function tagAllRodsInFolder()
	local tagged = 0
	for _, rod in ipairs(rodToolFolder:GetChildren()) do
		if rod:IsA("Tool") and not CollectionService:HasTag(rod, "Rod") then
			CollectionService:AddTag(rod, "Rod")
			tagged = tagged + 1
		end
	end
	if tagged > 0 then

	end
end

-- Run at startup
task.spawn(tagAllRodsInFolder)

-- ===================================================================
-- COLLISION SETUP
-- ===================================================================
local function setupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("FishEffect")
		PhysicsService:RegisterCollisionGroup("Players")
		PhysicsService:CollisionGroupSetCollidable("FishEffect", "Players", false)
	end)
end
setupCollisionGroups()

local function saveOriginalTransparency(model)
	local key = model:GetFullName()
	if originalTransparencies[key] then return end
	originalTransparencies[key] = {}
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then originalTransparencies[key][part] = part.Transparency end
	end
end

local function restoreOriginalTransparency(model)
	local key = model:GetFullName()
	if not originalTransparencies[key] then return end
	for part, transparency in pairs(originalTransparencies[key]) do
		if part and part.Parent then part.Transparency = transparency end
	end
	originalTransparencies[key] = nil
end

local function getPooledFish(fishName, fishModelFolderRef)
	if not fishPool[fishName] then fishPool[fishName] = {pool = {}, active = {}} end
	local poolData = fishPool[fishName]
	if #poolData.pool > 0 then
		local fish = table.remove(poolData.pool)
		table.insert(poolData.active, fish)
		return fish
	end
	local fishModel = fishModelFolderRef:FindFirstChild(fishName)
	if not fishModel then return nil end
	local newFish = fishModel:Clone()
	table.insert(poolData.active, newFish)
	return newFish
end

local function returnFishToPool(fishName, fish)
	if not fish or not fish.Parent then return end
	fish.Parent = nil
	restoreOriginalTransparency(fish)
	if not fishPool[fishName] then fishPool[fishName] = {pool = {}, active = {}} end
	local poolData = fishPool[fishName]
	for i, activeFish in ipairs(poolData.active) do
		if activeFish == fish then table.remove(poolData.active, i) break end
	end
	if #poolData.pool < MAX_POOL_SIZE then table.insert(poolData.pool, fish) else fish:Destroy() end
end

local function createFishPopEffect(fishName, hookPosition, playerCharacter)
	if not fishModelFolder or not playerCharacter then return end
	local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local fishClone = getPooledFish(fishName, fishModelFolder)
	if not fishClone then return end
	saveOriginalTransparency(fishClone)
	local primaryPart = fishClone:IsA("Model") and fishClone.PrimaryPart or fishClone:FindFirstChildOfClass("BasePart") or fishClone
	if not primaryPart then returnFishToPool(fishName, fishClone) return end
	if fishClone:IsA("Model") then fishClone:SetPrimaryPartCFrame(CFrame.new(hookPosition)) else fishClone.CFrame = CFrame.new(hookPosition) end
	fishClone.Parent = workspace
	primaryPart.Anchored = false
	primaryPart.CanCollide = true
	local allParts = {}
	for _, part in ipairs(fishClone:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "FishEffect"
			if part ~= primaryPart then part.CanCollide = false end
			table.insert(allParts, part)
		end
	end
	local settings = FishingConfig.ProjectileSettings
	local playerLookDirection = hrp.CFrame.LookVector
	local behindOffset = settings.behindPlayerDistance
	local sideOffset = 0
	if settings.randomLanding then
		behindOffset = math.random(settings.randomBehindRange.min, settings.randomBehindRange.max)
		sideOffset = math.random(settings.randomSideRange.min, settings.randomSideRange.max)
	end
	local targetPosition = hrp.Position - (playerLookDirection * behindOffset) + (hrp.CFrame.RightVector * sideOffset) + Vector3.new(0, settings.landingHeightOffset, 0)
	local directionToTarget = (targetPosition - hookPosition).Unit
	local distance = (targetPosition - hookPosition).Magnitude
	local timeToReach = settings.flightTime
	local gravity = workspace.Gravity
	local horizontalSpeed = distance / timeToReach
	local verticalSpeed = (targetPosition.Y - hookPosition.Y) / timeToReach + (0.5 * gravity * timeToReach)
	primaryPart.AssemblyLinearVelocity = Vector3.new(directionToTarget.X * horizontalSpeed, verticalSpeed, directionToTarget.Z * horizontalSpeed)
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(400, 400, 400)
	bodyGyro.D = 100; bodyGyro.P = 3000
	bodyGyro.CFrame = primaryPart.CFrame * CFrame.Angles(math.rad(settings.rotationAngle), 0, 0)
	bodyGyro.Parent = primaryPart
	local hasLanded, canDetectLanding = false, false
	local lastCheckTime = tick()
	local CHECK_INTERVAL = 0.15
	task.delay(settings.detectionDelay, function() canDetectLanding = true end)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = {fishClone, playerCharacter}
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	local landingCheckConnection
	landingCheckConnection = RunService.Heartbeat:Connect(function()
		if not primaryPart or not primaryPart.Parent then
			if landingCheckConnection then landingCheckConnection:Disconnect() end
			return
		end
		if not canDetectLanding then return end
		local currentTime = tick()
		if currentTime - lastCheckTime < CHECK_INTERVAL then return end
		lastCheckTime = currentTime
		local velocity = primaryPart.AssemblyLinearVelocity or primaryPart.Velocity
		if velocity.Magnitude < settings.landingSpeedThreshold and velocity.Y < settings.landingVelocityY and not hasLanded then
			local rayResult = workspace:Raycast(primaryPart.Position, Vector3.new(0, -settings.landingRayDistance, 0), raycastParams)
			if rayResult and rayResult.Instance and rayResult.Distance < settings.landingGroundDistance then
				hasLanded = true
				if landingCheckConnection then landingCheckConnection:Disconnect() end
				if bodyGyro then bodyGyro:Destroy() end
				primaryPart.Anchored = true
				primaryPart.AssemblyLinearVelocity = Vector3.zero
				primaryPart.RotVelocity = Vector3.zero
				task.wait(settings.fadeInDuration)
				for _, part in ipairs(allParts) do
					if part and part.Parent then TweenService:Create(part, TweenInfo.new(settings.fadeOutDuration), {Transparency = 1}):Play() end
				end
				task.wait(settings.fadeOutDuration)
				returnFishToPool(fishName, fishClone)
			end
		end
	end)
	task.delay(settings.safetyTimeout, function()
		if not hasLanded and fishClone.Parent then
			hasLanded = true
			if landingCheckConnection then landingCheckConnection:Disconnect() end
			if bodyGyro then bodyGyro:Destroy() end
			returnFishToPool(fishName, fishClone)
		end
	end)
end

-- ===================================================================
-- RESTORE FUNCTIONS (WITH ROD TAGGING)
-- ===================================================================
local function restoreSavedFish(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local savedFish = DataManager:GetSavedFish(player)
	for _, fishData in ipairs(savedFish) do
		local fishClone = fishFolder:FindFirstChild(fishData.name)
		if fishClone then
			local toolClone = fishClone:Clone()
			toolClone.ToolTip = " "
			local idValue = Instance.new("StringValue", toolClone); idValue.Name = "FishId"; idValue.Value = fishData.uniqueId
			local weightValue = Instance.new("NumberValue", toolClone); weightValue.Name = "Weight"; weightValue.Value = fishData.weight
			local rarityValue = Instance.new("StringValue", toolClone); rarityValue.Name = "Rarity"; rarityValue.Value = fishData.rarity
			local favValue = Instance.new("BoolValue", toolClone); favValue.Name = "isFavorited"; favValue.Value = fishData.isFavorited or false
			toolClone.Parent = backpack
		end
	end
end

local function restoreOwnedRods(player)
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end
	local ownedRods = DataManager:GetOwnedRods(player)
	for _, rodName in ipairs(ownedRods) do
		if not backpack:FindFirstChild(rodName) then
			local rodTool = rodToolFolder:FindFirstChild(rodName)
			if rodTool then
				local clonedRod = rodTool:Clone()
				-- CRITICAL: Ensure the cloned rod has the "Rod" tag
				if not CollectionService:HasTag(clonedRod, "Rod") then
					CollectionService:AddTag(clonedRod, "Rod")
				end
				clonedRod.Parent = backpack
			end
		end
	end
end

local function restoreRoleRods(player)
	local config = FishingConfig.RoleSettings
	if not config or not config.Enabled or config.GroupID == 0 then return end
	local backpack = player:FindFirstChild("Backpack")
	local playerRank = 0
	pcall(function() playerRank = player:GetRankInGroup(config.GroupID) end)
	if playerRank == 0 then return end
	for _, data in pairs(config.RoleRodMapping) do
		if playerRank == data.RankID then
			local rodToGive = data.RodName
			if not backpack:FindFirstChild(rodToGive) then
				local rodTool = rodToolFolder:FindFirstChild(rodToGive)
				if rodTool then
					local clonedRod = rodTool:Clone()
					-- CRITICAL: Ensure the cloned rod has the "Rod" tag
					if not CollectionService:HasTag(clonedRod, "Rod") then
						CollectionService:AddTag(clonedRod, "Rod")
					end
					clonedRod.Parent = backpack
					DataManager:AddRod(player, rodToGive)
				end
			end
			break
		end
	end
end

-- ===================================================================
-- EVENT HANDLERS
-- ===================================================================
fishGiverEvent.OnServerEvent:Connect(function(player, fish)
	if not fishGiverEvent then return end
	local targetFish = fishFolder:FindFirstChild(fish.name)
	if not targetFish then return end
	local uniqueFishId = DataManager:AddFishWithLimit(player, {name = fish.name, weight = fish.weight, rarity = fish.rarity})
	if not uniqueFishId then return end
	local clonedFish = targetFish:Clone()
	clonedFish.ToolTip = " "
	local idValue = Instance.new("StringValue", clonedFish); idValue.Name = "FishId"; idValue.Value = uniqueFishId
	local wValue = Instance.new("NumberValue", clonedFish); wValue.Name = "Weight"; wValue.Value = fish.weight
	local rValue = Instance.new("StringValue", clonedFish); rValue.Name = "Rarity"; rValue.Value = fish.rarity
	local fValue = Instance.new("BoolValue", clonedFish); fValue.Name = "isFavorited"; fValue.Value = false
	clonedFish.Parent = player.Backpack
	if FishingConfig.ProjectileSettings.enabled and fish.hookPosition and player.Character then
		task.spawn(function() createFishPopEffect(fish.name, fish.hookPosition, player.Character) end)
	end
end)

local function fireAllClientsExcept(event, excludePlayer, ...)
	for _, p in Players:GetPlayers() do if p ~= excludePlayer then event:FireClient(p, ...) end end
end

castReplicationEvent.OnServerEvent:Connect(function(player, rodPos, vel, rodName, power)
	if player.Character then fireAllClientsExcept(castReplicationEvent, player, player, rodPos, vel, rodName, power) end
end)

cleanupCastEvent.OnServerEvent:Connect(function(player) fireAllClientsExcept(cleanupCastEvent, player, player) end)

-- ===================================================================
-- PLAYER ADDED (FIXED - GIVES BASIC ROD WITH TAG)
-- ===================================================================
Players.PlayerAdded:Connect(function(player)
	-- Wait for FishData to load profile
	local profile = nil
	local attempts = 0
	while attempts < 30 and not profile do
		profile = GameProfileService:GetProfile(player)
		if not profile then
			attempts += 1
			task.wait(0.5)
		end
	end

	if profile then
		-- Add Basic Rod to data
		DataManager:AddRod(player, "Basic Rod")

		-- Function to give Basic Rod with proper tag
		local function giveBasicRodWithTag()
			local backpack = player:FindFirstChild("Backpack")
			if not backpack then return end

			-- Check if player already has Basic Rod
			if backpack:FindFirstChild("Basic Rod") then return end

			local basicRodTemplate = rodToolFolder:FindFirstChild("Basic Rod")
			if basicRodTemplate then
				local clonedRod = basicRodTemplate:Clone()
				-- CRITICAL: Ensure Basic Rod has the "Rod" tag
				if not CollectionService:HasTag(clonedRod, "Rod") then
					CollectionService:AddTag(clonedRod, "Rod")
				end
				clonedRod.Parent = backpack
			else
				warn("?? [FishingServer] Basic Rod not found in ServerStorage.AllRods!")
			end
		end

		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			giveBasicRodWithTag()
			restoreSavedFish(player)
			restoreOwnedRods(player)
			restoreRoleRods(player)
		end)

		if player.Character then
			task.spawn(function()
				task.wait(0.5)
				giveBasicRodWithTag()
				restoreSavedFish(player)
				restoreOwnedRods(player)
				restoreRoleRods(player)
			end)
		end
	else
		player:Kick("Failed to load profile.")
	end
end)

-- ===================================================================
-- SELL FISH EVENT
-- ===================================================================
sellFishEvent.OnServerEvent:Connect(function(player, sellType, fishData)
	local function formatNumberWithCommas(number)
		local s = tostring(math.floor(number))
		local reversed = string.reverse(s)
		local formatted = reversed:gsub("(%d%d%d)", "%1,")
		return string.reverse(formatted):gsub("^,", "")
	end

	if sellType == "SellAllBatch" then
		local totalCoins = 0
		for _, fSell in ipairs(fishData) do
			local removed, removedData = DataManager:RemoveFish(player, fSell.fishId)
			if removed then
				totalCoins = totalCoins + DataManager:CalculateFishPrice(fSell.weight, fSell.rarity)
				local bp = player:FindFirstChild("Backpack")
				if bp then for _, t in ipairs(bp:GetChildren()) do if t:FindFirstChild("FishId") and t.FishId.Value == fSell.fishId then t:Destroy() break end end end
			end
		end
		if totalCoins > 0 then 
			GameProfileService:AddCoins(player, totalCoins)
		end
	elseif sellType == "SellSingle" then
		local fishId = fishData.fishId
		local weight = fishData.weight
		local rarity = fishData.rarity
		local savedFish = DataManager:GetSavedFish(player)
		local fishToSell = nil
		for _, fData in ipairs(savedFish) do
			if fData.uniqueId == fishId then fishToSell = fData; break end
		end
		if not fishToSell then return end
		local sellPrice = DataManager:CalculateFishPrice(weight, rarity)
		local removed, removedData = DataManager:RemoveFish(player, fishId)
		if removed then
			GameProfileService:AddCoins(player, sellPrice)
			local toolDestroyed = false
			if player.Character then
				local equippedTool = player.Character:FindFirstChildOfClass("Tool")
				if equippedTool and equippedTool:FindFirstChild("FishId") and equippedTool.FishId.Value == fishId then
					equippedTool:Destroy()
					toolDestroyed = true
				end
			end
			local backpack = player:FindFirstChild("Backpack")
			if backpack and not toolDestroyed then
				for _, tool in ipairs(backpack:GetChildren()) do
					if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool:FindFirstChild("FishId").Value == fishId then
						tool:Destroy()
						toolDestroyed = true
						break
					end
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	-- Clean up forced fish data
	if NextCatchData[player.UserId] then
		NextCatchData[player.UserId] = nil
		print(string.format("?? [NextCatch] Cleaned up forced fish data for %s", player.Name))
	end

	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player then cleanupCastEvent:FireClient(otherPlayer, player) end
	end
end)

print("? [FishingServer] Initialized with NextCatch support!")