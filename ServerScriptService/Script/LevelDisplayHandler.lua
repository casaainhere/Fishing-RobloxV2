-- LevelDisplayHandler - Update Level di Overhead GUI
-- Location: ServerScriptService/Script/LevelDisplayHandler
-- Type: Script (Server)
-- Purpose: Display player level in overhead BillboardGui

local Players = game:GetService("Players")

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local CONFIG = {
	LEVEL_TEXT_FORMAT = "?? Level %d", -- Format display (contoh: "?? Level 5")
	CHECK_INTERVAL = 0.5, -- Check interval untuk wait BillboardGui (seconds)
	MAX_CHECKS = 20, -- Max checks sebelum timeout (20 * 0.5 = 10 seconds)
	LEVEL_STAT_NAME = "Level", -- Nama stat di leaderstats (HARUS SAMA dengan FishData!)
}

-- ===================================================================
-- FUNCTION: FIND LEVEL TEXTLABEL DI BILLBOARDGUI
-- ===================================================================
local function findLevelLabel(character)
	-- Cari BillboardGui di character
	local billboardGui = character:FindFirstChild("BillboardGui")
	if not billboardGui then
		return nil
	end

	-- Cari Canvas frame
	local canvas = billboardGui:FindFirstChild("Canvas")
	if not canvas then
		return nil
	end

	-- Cari Level TextLabel
	local levelLabel = canvas:FindFirstChild("Level")
	if not levelLabel or not levelLabel:IsA("TextLabel") then
		return nil
	end

	return levelLabel
end

-- ===================================================================
-- FUNCTION: WAIT FOR BILLBOARDGUI & LEVEL STAT
-- ===================================================================
local function waitForComponents(player, character)
	local checks = 0

	-- Wait for BillboardGui (created by UltimateOverheadGui)
	while not findLevelLabel(character) and checks < CONFIG.MAX_CHECKS do
		task.wait(CONFIG.CHECK_INTERVAL)
		checks += 1
	end

	if not findLevelLabel(character) then
		warn("[LevelDisplay] ?? Could not find Level TextLabel for " .. player.Name)
		return nil, nil
	end

	local levelLabel = findLevelLabel(character)

	-- Wait for leaderstats.Level (created by FishData)
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if not leaderstats then
		warn("[LevelDisplay] ?? No leaderstats found for " .. player.Name)
		return nil, nil
	end

	local levelStat = leaderstats:WaitForChild(CONFIG.LEVEL_STAT_NAME, 10)
	if not levelStat then
		warn("[LevelDisplay] ?? No Level stat found for " .. player.Name)
		return nil, nil
	end

	return levelLabel, levelStat
end

-- ===================================================================
-- FUNCTION: UPDATE LEVEL DISPLAY
-- ===================================================================
local function updateLevelDisplay(levelLabel, levelValue)
	if not levelLabel or not levelLabel:IsA("TextLabel") then
		return
	end

	levelLabel.Text = string.format(CONFIG.LEVEL_TEXT_FORMAT, levelValue)
end

-- ===================================================================
-- FUNCTION: INITIALIZE LEVEL DISPLAY FOR PLAYER
-- ===================================================================
local function initializeLevelDisplay(player, character)
	-- Wait for components
	local levelLabel, levelStat = waitForComponents(player, character)

	if not levelLabel or not levelStat then
		return -- Failed to initialize
	end

	-- Initial update
	updateLevelDisplay(levelLabel, levelStat.Value)
	print("[LevelDisplay] ? " .. player.Name .. " - Level " .. levelStat.Value .. " display initialized")

	-- Listen for Level changes
	local connection = levelStat:GetPropertyChangedSignal("Value"):Connect(function()
		updateLevelDisplay(levelLabel, levelStat.Value)
		print("[LevelDisplay] ?? " .. player.Name .. " - Level updated to " .. levelStat.Value)
	end)

	-- Cleanup on character removing
	character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			connection:Disconnect()
		end
	end)
end

-- ===================================================================
-- PLAYER ADDED - SETUP LEVEL DISPLAY
-- ===================================================================
Players.PlayerAdded:Connect(function(player)
	-- Handle current character (if already loaded)
	if player.Character then
		task.spawn(function()
			initializeLevelDisplay(player, player.Character)
		end)
	end

	-- Handle future characters (respawn)
	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			initializeLevelDisplay(player, character)
		end)
	end)
end)

-- ===================================================================
-- HANDLE EXISTING PLAYERS (if script loads after players join)
-- ===================================================================
for _, player in pairs(Players:GetPlayers()) do
	if player.Character then
		task.spawn(function()
			initializeLevelDisplay(player, player.Character)
		end)
	end

	player.CharacterAdded:Connect(function(character)
		task.spawn(function()
			initializeLevelDisplay(player, character)
		end)
	end)
end

-- ===================================================================
-- INITIALIZATION LOG
-- ===================================================================
print("=================================================================")
print("?? LevelDisplayHandler - Initialized!")
print("=================================================================")
print("?? Configuration:")
print("   Format: " .. CONFIG.LEVEL_TEXT_FORMAT)
print("   Check Interval: " .. CONFIG.CHECK_INTERVAL .. "s")
print("   Max Checks: " .. CONFIG.MAX_CHECKS)
print("=================================================================")
print("? Listening for BillboardGui and Level changes!")
print("=================================================================")