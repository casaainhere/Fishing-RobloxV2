-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- FishingConfig - FIXED VERSION (Luck + NextCatch Integration)

local FishingConfig = {}
-- ===================================================================
FishingConfig.DatabaseSettings = {enabled = true, warnOnDisabled = true}
FishingConfig.LeaderboardSettings = {enabled = true, showCoins = true, showFishCaught = true, CoinsName = "Coins", fishCaughtName = "FishCaught"}
FishingConfig.InventoryLimitSettings = {enabled = true, maxFishInventory = 500, fullInventoryMessage = "Your fish inventory is full! (500/500) Sell some fish first.", autoSellOldestFish = false}

FishingConfig.SellingSettings = {
	enabled = true, basePricePerKg = 2,
	rarityMultiplier = {Common = 1.0, Uncommon = 2.0, Rare = 4.0, Epic = 8.0, Legendary = 15.0, Unknown = 30.0},
	enableSizeBonus = true,
	sizeBonus = {
		small = {min = 0, max = 10, multiplier = 0.7},
		medium = {min = 10, max = 50, multiplier = 1.0},
		large = {min = 50, max = 150, multiplier = 1.3},
		huge = {min = 150, max = 999, multiplier = 1.6}
	}
}

FishingConfig.ProjectileSettings = {
	enabled = true, behindPlayerDistance = 5, landingHeightOffset = 1, flightTime = 0.8,
	rotationAngle = 45, landingSpeedThreshold = 5, landingVelocityY = 2,
	landingRayDistance = 5, landingGroundDistance = 3, detectionDelay = 0.5,
	fadeInDuration = 0.2, fadeOutDuration = 0.6, safetyTimeout = 3,
	randomLanding = false, randomBehindRange = {min = 4, max = 7}, randomSideRange = {min = -2, max = 2}
}

-- ?? EASY TAP COUNT ADJUSTMENT
FishingConfig.MinigameSettings = {
	progressMin = 8, progressMax = 12, decayMin = 3, decayMax = 7,
	startingProgress = 0.4, fishingTime = 25, decayMultiplier = 25, clickFeedbackDuration = 0.15,

	rodTapCount = {
		["Owner Rod"] = 5, ["Admin Rod"] = 6, ["Developer Rod"] = 7,
		["Umbrella"] = 8, ["Katanaa"] = 8, ["Purple Saber"] = 8, ["Megalofriend"] = 9, ["Manifest"] = 10, ["Earthly"] = 11,
		["Pirate Octopus"] = 11, ["LightingPunk Rod"] = 11, ["Frozen Rod"] = 12, ["GhostRod"] = 12,
		["Gold Rod"] = 12, ["Lucky Rod"] = 13, ["Angelic Rod"] = 13,
		["Aqua Prism"] = 11, ["Crystalized"] = 11, ["Forsaken"] = 11, ["ZombieRod"] = 11, ["Loving"] = 11, ["Flery"] = 11,
		["Fluorescent Rod"] = 13, ["Polarized"] = 14, ["Lightning"] = 14,
		["Basic Rod"] = 15, default = 15
	},
	autoModeExtraTaps = 2
}

FishingConfig.TransferSettings = {Enabled = true, RequiredLevel = 1, MaxDistance = 15}

-- ===================================================================
-- ROD STATS - STAFF RODS HAVE HUGE LUCK
-- ===================================================================
FishingConfig.RodConfig = {
	default = {hookName = "BasicHook", beamColor = Color3.fromRGB(106, 106, 106), beamWidth = 0.05, baseLuck = 0.5, maxWeight = 5.0, maxRarity = "Common"},
	["Basic Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(139, 69, 19), beamWidth = 0.04, baseLuck = 1.0, maxWeight = 100.0, maxRarity = "Epic"},
	["Angelic Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 255, 255), beamWidth = 0.04, baseLuck = 1.15, maxWeight = 120.0, maxRarity = "Epic"},
	["Gold Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 215, 0), beamWidth = 0.04, baseLuck = 1.20, maxWeight = 120.0, maxRarity = "Epic"},
	["Lucky Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 255, 0), beamWidth = 0.04, baseLuck = 1.25, maxWeight = 150.0, maxRarity = "Epic"},
	["Lightning"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 255, 0), beamWidth = 0.04, baseLuck = 1.50, maxWeight = 180.0, maxRarity = "Legendary"},
	["Polarized"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 200, 255), beamWidth = 0.04, baseLuck = 1.60, maxWeight = 200.0, maxRarity = "Legendary"},
	["Fluorescent Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 255, 200), beamWidth = 0.04, baseLuck = 1.70, maxWeight = 220.0, maxRarity = "Legendary"},
	["GhostRod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(200, 200, 255), beamWidth = 0.04, baseLuck = 1.85, maxWeight = 250.0, maxRarity = "Legendary"},
	["Frozen Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(150, 200, 255), beamWidth = 0.04, baseLuck = 1.90, maxWeight = 250.0, maxRarity = "Legendary"},
	["LightingPunk Rod"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(255, 0, 255), beamWidth = 0.04, baseLuck = 2.00, maxWeight = 280.0, maxRarity = "Legendary"},
	["Pirate Octopus"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.04, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary"},
	["Aqua Prism"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.04, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary"},
	["Flery"] = {hookName = "FleryHook", beamColor = Color3.fromRGB(255, 81, 0), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Loving"] = {hookName = "LovingHook", beamColor = Color3.fromRGB(255, 23, 236), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["ZombieRod"] = {hookName = "ZombieHook", beamColor = Color3.fromRGB(76, 255, 121), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Forsaken"] = {hookName = "ForsakenHook", beamColor = Color3.fromRGB(100, 50, 150), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Crystalized"] = {hookName = "CrystalizedHook", beamColor = Color3.fromRGB(175, 221, 255), beamWidth = 0.05, baseLuck = 2.10, maxWeight = 300.0, maxRarity = "Legendary", isGamepass = true},
	["Earthly"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(139, 69, 19), beamWidth = 0.04, baseLuck = 2.50, maxWeight = 350.0, maxRarity = "Unknown"},
	["Manifest"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(180, 100, 255), beamWidth = 0.04, baseLuck = 3.00, maxWeight = 400.0, maxRarity = "Unknown"},
	["Megalofriend"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(0, 150, 255), beamWidth = 0.04, baseLuck = 3.50, maxWeight = 450.0, maxRarity = "Unknown"},
	["Purple Saber"] = {hookName = "BasicHook", beamColor = Color3.fromRGB(160, 30, 255), beamWidth = 0.04, baseLuck = 4.00, maxWeight = 500.0, maxRarity = "Unknown"},
	["Katanaa"] = {hookName = "KatanaaHook", beamColor = Color3.fromRGB(0, 0, 0), beamWidth = 0.04, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Unknown", isGamepass = true},
	["Umbrella"] = {hookName = "UmbrellaHook", beamColor = Color3.fromRGB(255, 70, 215), beamWidth = 0.04, baseLuck = 5.00, maxWeight = 650.0, maxRarity = "Unknown", isGamepass = true},

	-- STAFF RODS - MASSIVE LUCK
	["Developer Rod"] = {hookName = "DeveloperHook", beamColor = Color3.fromRGB(117, 0, 140), beamWidth = 0.04, baseLuck = 10.0, maxWeight = 1000.0, maxRarity = "Unknown"},
	["Admin Rod"] = {hookName = "AdminHook", beamColor = Color3.fromRGB(255, 180, 180), beamWidth = 0.04, baseLuck = 20.0, maxWeight = 2000.0, maxRarity = "Unknown"},
	["Owner Rod"] = {hookName = "OwnerHook", beamColor = Color3.fromRGB(255, 213, 0), beamWidth = 0.04, baseLuck = 9999999.0, maxWeight = 10000.0, maxRarity = "Unknown"}
}

FishingConfig.Pity = {
	Rare = {maxPity = 250, baseBoost = 0.10, maxMultiplier = 1.25},
	Epic = {maxPity = 500, baseBoost = 0.15, maxMultiplier = 1.30},
	Legendary = {maxPity = 1000, baseBoost = 0.20, maxMultiplier = 1.40},
	Unknown = {maxPity = 2000, baseBoost = 0.30, maxMultiplier = 1.60}
}

FishingConfig.RarityWeights = {Common = 70, Uncommon = 20, Rare = 7, Epic = 2.5, Legendary = 0.45, Unknown = 0.2}

FishingConfig.FishTable = {
	{name = "Boar Fish", probability = 30, minKg = 0.5, maxKg = 50.0, rarity = "Common"},
	{name = "Blackcap Basslet", probability = 28, minKg = 0.5, maxKg = 45.0, rarity = "Common"},
	{name = "Pumpkin Carved Shark", probability = 25, minKg = 1.0, maxKg = 60.0, rarity = "Common"},
	{name = "Freshwater Piranha", probability = 25, minKg = 1.0, maxKg = 60.0, rarity = "Common"},
	{name = "Hermit Crab", probability = 22, minKg = 0.8, maxKg = 40.0, rarity = "Common"},
	{name = "Goliath Tiger", probability = 20, minKg = 2.0, maxKg = 70.0, rarity = "Common"},
	{name = "Fangtooth", probability = 18, minKg = 1.5, maxKg = 55.0, rarity = "Common"},
	{name = "Dead Spooky Koi Fish", probability = 12, minKg = 5.0, maxKg = 80.0, rarity = "Uncommon"},
	{name = "Dead Scary Clownfish", probability = 10, minKg = 4.0, maxKg = 75.0, rarity = "Uncommon"},
	{name = "Jellyfish", probability = 8, minKg = 3.0, maxKg = 65.0, rarity = "Uncommon"},
	{name = "Lion Fish", probability = 5, minKg = 10.0, maxKg = 120.0, rarity = "Rare"},
	{name = "Luminous Fish", probability = 4, minKg = 12.0, maxKg = 130.0, rarity = "Rare"},
	{name = "Zombie Shark", probability = 3.5, minKg = 20.0, maxKg = 150.0, rarity = "Rare"},
	{name = "Wraithfin Abyssal", probability = 3, minKg = 15.0, maxKg = 140.0, rarity = "Rare"},
	{name = "Loving Shark", probability = 1.5, minKg = 30.0, maxKg = 250.0, rarity = "Epic"},
	{name = "Monster Shark", probability = 1.2, minKg = 35.0, maxKg = 280.0, rarity = "Epic"},
	{name = "Queen Crab", probability = 1.0, minKg = 25.0, maxKg = 220.0, rarity = "Epic"},
	{name = "Pink Dolphin", probability = 0.8, minKg = 40.0, maxKg = 300.0, rarity = "Epic"},
	{name = "Plasma Shark", probability = 0.4, minKg = 80.0, maxKg = 400.0, rarity = "Legendary"},
	{name = "Ancient Relic Crocodile", probability = 0.08, minKg = 150.0, maxKg = 600.0, rarity = "Unknown"},
	{name = "Ancient Whale", probability = 0.05, minKg = 200.0, maxKg = 800.0, rarity = "Unknown"}
}

FishingConfig.RarityColors = {
	Common = Color3.fromRGB(200, 200, 200), Uncommon = Color3.fromRGB(30, 255, 30),
	Rare = Color3.fromRGB(30, 100, 255), Epic = Color3.fromRGB(160, 30, 255),
	Legendary = Color3.fromRGB(255, 128, 0), Unknown = Color3.fromRGB(190, 0, 3)
}

FishingConfig.rarityOrder = {Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Unknown = 6}

FishingConfig.RoleSettings = {
	Enabled = true, GroupID = 8840108591,
	RoleRodMapping = {
		["Owner"] = {RankID = 254, RodName = "Owner Rod"},
		["Admin"] = {RankID = 254, RodName = "Admin Rod"},
		["Developer"] = {RankID = 253, RodName = "Developer Rod"}
	}
}

FishingConfig.GamepassEffects = {enabled = false}

-- ===================================================================
-- FUNCTIONS
-- ===================================================================

function FishingConfig.CreatePityTracker()
	return {Rare = 0, Epic = 0, Legendary = 0, Unknown = 0}
end

-- ? FIXED: PROPER LUCK SCALING!
function FishingConfig.GetRarityWithPity(pityData, rodName, luckBonus)
	local base = FishingConfig.RarityWeights
	local rodConfig = FishingConfig.GetRodConfig(rodName)
	local maxRarity = rodConfig.maxRarity or "Unknown"
	local maxRarityLevel = FishingConfig.rarityOrder[maxRarity] or 6

	luckBonus = luckBonus or rodConfig.baseLuck or 1.0
	local final = {}

	-- ?? FIXED LUCK FORMULA - NO MORE SQRT NERF!
	for rarity, weight in pairs(base) do
		local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
		local rarityMultiplier = (rarityLevel - 1) / 5  -- 0.0 to 1.0 scale

		local luckEffect

		if luckBonus <= 5 then
			-- Normal rods (1-5x luck): Linear scaling
			luckEffect = 1 + ((luckBonus - 1) * rarityMultiplier * 5)
		elseif luckBonus <= 50 then
			-- Medium luck (5-50x): Strong exponential
			-- For luck 10x on Legendary (rarityMultiplier=1.0): effect = 1 + (9 * 1.0 * 20) = 181x weight
			-- For luck 50x on Legendary: effect = 1 + (49 * 1.0 * 20) = 981x weight
			luckEffect = 1 + ((luckBonus - 1) * rarityMultiplier * 20)
		else
			-- High luck (50x+): VERY strong but capped to prevent overflow
			-- For luck 100x on Legendary: effect = 1 + (99 * 1.0 * 50) = 4951x weight
			-- This ensures x100 luck DOMINATES rare fish chances!
			local cappedLuck = math.min(luckBonus, 200) -- Cap at 200x to prevent infinity
			luckEffect = 1 + ((cappedLuck - 1) * rarityMultiplier * 50)
		end

		final[rarity] = weight * luckEffect
	end

	-- Enforce rod limits
	for rarity, level in pairs(FishingConfig.rarityOrder) do
		if level > maxRarityLevel then
			final[rarity] = 0
		end
	end

	-- Apply pity
	for rarity, cfg in pairs(FishingConfig.Pity) do
		local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
		if rarityLevel <= maxRarityLevel and final[rarity] and final[rarity] > 0 then
			local count = pityData[rarity] or 0
			local progress = math.clamp(count / cfg.maxPity, 0, 1)
			local boost = cfg.baseBoost * progress
			local boostedWeight = final[rarity] * (1 + boost)
			final[rarity] = math.min(boostedWeight, final[rarity] * cfg.maxMultiplier)
		end
	end

	-- Weighted random
	local total = 0
	for _, w in pairs(final) do total = total + w end
	if total == 0 then return "Common" end

	local roll = math.random() * total
	for rarity, w in pairs(final) do
		if roll < w then return rarity end
		roll = roll - w
	end
	return "Common"
end

function FishingConfig.PickFishFromRarity(rarity)
	local list = {}
	for _, fish in ipairs(FishingConfig.FishTable) do
		if fish.rarity == rarity then table.insert(list, fish) end
	end
	if #list == 0 then
		for _, fish in ipairs(FishingConfig.FishTable) do
			if fish.rarity == "Common" then table.insert(list, fish) end
		end
	end
	if #list == 0 then return nil end

	local totalProb = 0
	for _, f in ipairs(list) do totalProb = totalProb + f.probability end
	local roll = math.random() * totalProb
	for _, f in ipairs(list) do
		if roll < f.probability then return f end
		roll = roll - f.probability
	end
	return list[1]
end

-- ?? HELPER: FIND FISH BY NAME (FOR NEXTCATCH)
function FishingConfig.FindFishByName(fishName)
	fishName = string.lower(fishName)

	-- Exact match first
	for _, fish in ipairs(FishingConfig.FishTable) do
		if string.lower(fish.name) == fishName then
			return fish
		end
	end

	-- Partial match
	for _, fish in ipairs(FishingConfig.FishTable) do
		if string.find(string.lower(fish.name), fishName) then
			return fish
		end
	end

	return nil
end

-- ? FIXED: ROLLFISH WITH NEXTCATCH INTEGRATION!
function FishingConfig.RollFish(pityData, rodName, luckBonus)
	pityData = pityData or FishingConfig.CreatePityTracker()

	-- ?? CHECK FOR FORCED FISH (NEXTCATCH SYSTEM)
	-- This is set server-side by !nextcatch command
	if game:GetService("RunService"):IsClient() then
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local GetForcedFishFunction = ReplicatedStorage:FindFirstChild("FishingSystem"):FindFirstChild("GetForcedFish")

		if GetForcedFishFunction then
			local success, forcedData = pcall(function()
				return GetForcedFishFunction:InvokeServer()
			end)

			if success and forcedData then
				-- Find fish from table
				local forcedFish = FishingConfig.FindFishByName(forcedData.fishName)

				if forcedFish then
					print(string.format("?? [FORCED] Using nextcatch fish: %s (%.1fkg)", 
						forcedData.fishName, forcedData.fishWeight))

					-- Create a copy with forced weight marker
					local fishCopy = {}
					for k, v in pairs(forcedFish) do
						fishCopy[k] = v
					end
					fishCopy._forcedWeight = forcedData.fishWeight

					-- Reset pity since we caught something (even if forced)
					local rarityLevel = FishingConfig.rarityOrder[fishCopy.rarity] or 1
					for r, level in pairs(FishingConfig.rarityOrder) do
						if level >= rarityLevel and pityData[r] then
							pityData[r] = 0
						end
					end

					return fishCopy
				else
					warn("?? [NextCatch] Forced fish not found in FishTable: " .. forcedData.fishName)
				end
			end
		end
	end

	-- NORMAL ROLL (if no forced fish or forced fish failed)
	for rarity in pairs(pityData) do pityData[rarity] = pityData[rarity] + 1 end

	local rarity = FishingConfig.GetRarityWithPity(pityData, rodName, luckBonus)

	local rarityLevel = FishingConfig.rarityOrder[rarity] or 1
	for r, level in pairs(FishingConfig.rarityOrder) do
		if level >= rarityLevel and pityData[r] then pityData[r] = 0 end
	end

	return FishingConfig.PickFishFromRarity(rarity)
end

function FishingConfig.GetRodConfig(rodName)
	return FishingConfig.RodConfig[rodName] or FishingConfig.RodConfig.default
end

function FishingConfig.GetRarityColor(rarity)
	return FishingConfig.RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

-- ?? THIS IS THE CRITICAL FUNCTION - LUCK CALCULATION
function FishingConfig.CalculateTotalLuck(baseLuck, powerPercent)
	-- 1. Ambil nilai Boost dari ReplicatedStorage
	local repStorage = game:GetService("ReplicatedStorage")
	local luckValObj = repStorage:WaitForChild("FishingSystem"):FindFirstChild("GlobalLuckMultiplier")
	local serverMultiplier = luckValObj and luckValObj.Value or 1.0

	-- 2. Hitung Luck dasar (Rod + Power Bar)
	local powerBonus = baseLuck * (powerPercent * 0.2)
	local rodLuck = baseLuck + powerBonus

	-- 3. Kalikan dengan Server Boost
	local total = rodLuck * serverMultiplier

	-- Log untuk debugging
	if serverMultiplier > 1 then
		print(string.format("?? [Luck] Rod: %.1f | Power: %.1f%% (+%.2f) | Boost: x%.1f | TOTAL: %.1f", 
			baseLuck, powerPercent * 100, powerBonus, serverMultiplier, total))
	end

	return total, baseLuck, powerBonus
end

function FishingConfig.CanCatchRarity(rodName, fishRarity)
	local rodConfig = FishingConfig.GetRodConfig(rodName)
	local maxRarity = rodConfig.maxRarity or "Unknown"
	local rodMaxLevel = FishingConfig.rarityOrder[maxRarity] or 6
	local fishLevel = FishingConfig.rarityOrder[fishRarity] or 1
	return fishLevel <= rodMaxLevel
end

-- ? FIXED: GENERATE FISH WEIGHT WITH NEXTCATCH SUPPORT!
function FishingConfig.GenerateFishWeight(fish, totalLuck, maxRodWeight)
	-- ?? CHECK FOR FORCED WEIGHT (NEXTCATCH)
	if fish._forcedWeight then
		local forcedWeight = fish._forcedWeight
		print(string.format("?? [FORCED] Using nextcatch weight: %.1fkg", forcedWeight))
		return forcedWeight
	end

	-- NORMAL WEIGHT GENERATION
	local minKg = fish.minKg
	local maxKg = math.min(fish.maxKg, maxRodWeight)
	if maxKg < minKg then return minKg end

	local luckFactor = math.clamp(totalLuck / 10.0, 0, 1)
	local randomFactor = math.random()
	local biasedRandom = randomFactor * (1 - luckFactor * 0.3) + (luckFactor * 0.3)
	local fishWeight = minKg + (biasedRandom * (maxKg - minKg))
	return math.floor(fishWeight * 10 + 0.5) / 10
end

function FishingConfig.CalculateFishPrice(weight, rarity)
	local basePricePerKg = FishingConfig.SellingSettings.basePricePerKg
	local rarityMult = FishingConfig.SellingSettings.rarityMultiplier[rarity] or 1.0
	local basePrice = weight * basePricePerKg * rarityMult
	local finalPrice = basePrice

	if FishingConfig.SellingSettings.enableSizeBonus then
		for bonusType, bonusData in pairs(FishingConfig.SellingSettings.sizeBonus) do
			if weight >= bonusData.min and weight < bonusData.max then
				finalPrice = basePrice * bonusData.multiplier
				break
			end
		end
	end
	return math.floor(finalPrice + 0.5)
end

function FishingConfig.HasGamepassEffects(rodName)
	return false
end

function FishingConfig.GetGamepassEffects(rodName)
	return nil
end

function FishingConfig.GetRequiredTaps(rodName, isAutoMode)
	local settings = FishingConfig.MinigameSettings
	local baseTaps = settings.rodTapCount[rodName] or settings.rodTapCount.default
	if isAutoMode then return baseTaps + settings.autoModeExtraTaps end
	return baseTaps
end

return FishingConfig