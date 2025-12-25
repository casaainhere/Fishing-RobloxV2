-- ForcedFishHandler - Auto-inject Forced Fish Check
-- LOKASI: ReplicatedStorage/FishingSystem/FishingModules/ForcedFishHandler
-- TYPE: ModuleScript

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))

local ForcedFishHandler = {}

-- ===================================================================
-- ?? GET FORCED FISH FROM SERVER
-- ===================================================================
local function getForcedFish()
	local GetForcedFishFunction = FishingSystem:FindFirstChild("GetForcedFish")

	if not GetForcedFishFunction then
		return nil
	end

	local success, result = pcall(function()
		return GetForcedFishFunction:InvokeServer()
	end)

	if success and result then
		return result -- {fishName = "...", fishWeight = ...}
	end

	return nil
end

-- ===================================================================
-- ?? WRAPPER: RollFish WITH FORCED CHECK
-- ===================================================================
function ForcedFishHandler.RollFish(pityData, rodName, totalLuck)
	-- 1. CHECK FORCED FISH FIRST
	local forcedData = getForcedFish()

	if forcedData then
		-- Find fish from FishTable
		for _, fish in ipairs(FishingConfig.FishTable) do
			if fish.name == forcedData.fishName then
				print(string.format("?? [FORCED] Using forced fish: %s (%.1fkg, %s)", 
					fish.name, forcedData.fishWeight, fish.rarity))

				-- Return fish with forced weight stored
				local forcedFish = {}
				for k, v in pairs(fish) do
					forcedFish[k] = v
				end
				forcedFish._forcedWeight = forcedData.fishWeight

				return forcedFish
			end
		end

		warn("?? [ForcedFish] Fish not found in FishTable, using normal roll")
	end

	-- 2. NORMAL ROLL (if no forced fish)
	return FishingConfig.RollFish(pityData, rodName, totalLuck)
end

-- ===================================================================
-- ?? WRAPPER: GenerateFishWeight WITH FORCED CHECK
-- ===================================================================
function ForcedFishHandler.GenerateFishWeight(selectedFish, totalLuck, maxWeight)
	-- Check if fish has forced weight
	if selectedFish._forcedWeight then
		local forcedWeight = selectedFish._forcedWeight
		print(string.format("?? [FORCED] Using forced weight: %.1fkg", forcedWeight))
		return forcedWeight
	end

	-- Normal weight generation
	return FishingConfig.GenerateFishWeight(selectedFish, totalLuck, maxWeight)
end

-- ===================================================================
-- ?? PASS-THROUGH ALL OTHER FUNCTIONS
-- ===================================================================
setmetatable(ForcedFishHandler, {
	__index = function(t, k)
		return FishingConfig[k]
	end
})

return ForcedFishHandler