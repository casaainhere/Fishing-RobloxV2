-- FORCE LEVEL MIGRATION SCRIPT
-- Location: ServerScriptService/ForceLevelMigration
-- Type: Script (Server-side)
-- Purpose: Force migrate old profiles to correct level based on FishCaught
-- 
-- INSTRUCTIONS:
-- 1. Insert this as a NEW script in ServerScriptService
-- 2. Play the game
-- 3. Wait for migration to complete
-- 4. DELETE this script after migration done!

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for game to load
task.wait(3)

print("=================================================================")
print("?? FORCE LEVEL MIGRATION - STARTING")
print("=================================================================")

-- Find FishData module
local function findFishData()
	-- Try common locations
	local paths = {
		ServerScriptService:FindFirstChild("Data"),
		ServerScriptService:FindFirstChild("PetCore"),
		ServerScriptService
	}

	for _, path in pairs(paths) do
		if path then
			local fishData = path:FindFirstChild("PetCore", true)
			if fishData then
				local module = fishData:FindFirstChild("FishData")
				if module then
					return module
				end
			end
		end
	end

	-- Recursive search as last resort
	for _, desc in pairs(ServerScriptService:GetDescendants()) do
		if desc:IsA("ModuleScript") and desc.Name == "FishData" then
			return desc
		end
	end

	return nil
end

local fishDataModule = findFishData()

if not fishDataModule then
	warn("? MIGRATION FAILED: Could not find FishData module!")
	return
end

print("? Found FishData at:", fishDataModule:GetFullName())

local FishData = require(fishDataModule)

-- Migration function
local function migratePlayer(player)
	local profile = FishData:GetProfile(player)

	if not profile then
		warn("? No profile for " .. player.Name)
		return false
	end

	local fishCount = profile.Data.TotalFishCaught or 0
	local currentLevel = profile.Data.Level or 1
	local currentXP = profile.Data.XP or 0

	print("\n?????????????????????????????????")
	print("?? PLAYER: " .. player.Name)
	print("?????????????????????????????????")
	print("?? Current Data:")
	print("   FishCaught: " .. fishCount)
	print("   Level: " .. currentLevel)
	print("   XP: " .. currentXP)

	-- Check if migration needed
	if fishCount == 0 then
		print("? New player (0 fish) - No migration needed")
		return true
	end

	-- Calculate what level SHOULD be based on fish count
	local totalXP = fishCount -- 1 XP per fish
	local calculatedLevel = 1
	local xpForNextLevel = FishData:CalculateXPRequired(calculatedLevel)

	while totalXP >= xpForNextLevel do
		totalXP = totalXP - xpForNextLevel
		calculatedLevel = calculatedLevel + 1
		xpForNextLevel = FishData:CalculateXPRequired(calculatedLevel)
	end

	print("\n?? Calculated Level (from " .. fishCount .. " fish):")
	print("   Should be Level: " .. calculatedLevel)
	print("   Should have XP: " .. totalXP .. "/" .. xpForNextLevel)

	-- Check if needs update
	if currentLevel == calculatedLevel and currentXP == totalXP then
		print("? Already correct - No migration needed")
		return true
	end

	-- FORCE UPDATE
	print("\n?? LEVEL MISMATCH DETECTED!")
	print("?? Migrating...")

	profile.Data.Level = calculatedLevel
	profile.Data.XP = totalXP
	profile.Data.XPtoNextLevel = xpForNextLevel

	-- Update leaderstats
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local levelStat = leaderstats:FindFirstChild("Level")
		if levelStat then
			levelStat.Value = calculatedLevel
		end
	end

	-- Update attributes
	player:SetAttribute("Level", calculatedLevel)
	player:SetAttribute("XP", totalXP)
	player:SetAttribute("XPtoNextLevel", xpForNextLevel)

	print("? MIGRATION COMPLETE!")
	print("   New Level: " .. calculatedLevel)
	print("   New XP: " .. totalXP .. "/" .. xpForNextLevel)

	return true
end

-- Migrate all current players
local migratedCount = 0
local failedCount = 0

for _, player in pairs(Players:GetPlayers()) do
	local success = pcall(function()
		migratePlayer(player)
	end)

	if success then
		migratedCount = migratedCount + 1
	else
		failedCount = failedCount + 1
		warn("? Failed to migrate " .. player.Name)
	end
end

print("\n=================================================================")
print("?? MIGRATION FINISHED!")
print("=================================================================")
print("? Migrated: " .. migratedCount .. " players")
if failedCount > 0 then
	print("? Failed: " .. failedCount .. " players")
end
print("=================================================================")
print("?? DELETE THIS SCRIPT NOW!")
print("=================================================================")

-- Auto-migrate new players that join
Players.PlayerAdded:Connect(function(player)
	-- Wait for profile to load
	task.wait(5)

	local success = pcall(function()
		migratePlayer(player)
	end)

	if not success then
		warn("? Failed to auto-migrate " .. player.Name)
	end
end)