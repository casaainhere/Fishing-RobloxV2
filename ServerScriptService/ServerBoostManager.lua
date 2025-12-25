-- ServerBoostManager - Control Global Luck Multiplier & GUI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local GlobalLuckMultiplier = FishingSystem:WaitForChild("GlobalLuckMultiplier")

-- ===================================================================
-- ?? CONFIGURATION - ATUR BOOST DI SINI!
-- ===================================================================
local DEFAULT_MULTIPLIER = 1.0  -- Default (no boost)
local SERVER_BOOST = 8.0        -- ?? GANTI ANGKA INI! (contoh: 8 = x8 boost)
local BOOST_ENABLED = false     -- ?? false = GUI HIDDEN, true = GUI MUNCUL

-- ===================================================================
-- CREATE REMOTE EVENT
-- ===================================================================
local UpdateBoostEvent = FishingSystem:FindFirstChild("UpdateServerBoost")
if not UpdateBoostEvent then
	UpdateBoostEvent = Instance.new("RemoteEvent")
	UpdateBoostEvent.Name = "UpdateServerBoost"
	UpdateBoostEvent.Parent = FishingSystem
end

print("=" .. string.rep("=", 60))
print("?? [ServerBoost] System Starting...")
print("?? [ServerBoost] Config:")
print("   Default Multiplier:", DEFAULT_MULTIPLIER)
print("   Server Boost:", SERVER_BOOST)
print("   Boost Enabled:", BOOST_ENABLED)
print("=" .. string.rep("=", 60))

-- ===================================================================
-- FUNCTION: UPDATE SERVER BOOST
-- ===================================================================
local function updateServerBoost()
	local multiplier = BOOST_ENABLED and SERVER_BOOST or DEFAULT_MULTIPLIER
	GlobalLuckMultiplier.Value = multiplier

	print(string.format("?? [ServerBoost] Luck multiplier: x%.1f", multiplier))
	print(string.format("???  [ServerBoost] GUI visible: %s", tostring(BOOST_ENABLED)))

	-- Broadcast ke semua player
	for _, player in pairs(Players:GetPlayers()) do
		UpdateBoostEvent:FireClient(player, BOOST_ENABLED, multiplier)
	end
end

-- ===================================================================
-- FUNCTION: ENABLE BOOST (MANUAL TRIGGER)
-- ===================================================================
local function enableBoost(multiplier)
	SERVER_BOOST = multiplier or SERVER_BOOST
	BOOST_ENABLED = true
	updateServerBoost()
	print("? [ServerBoost] Boost ENABLED!")
end

-- ===================================================================
-- FUNCTION: DISABLE BOOST
-- ===================================================================
local function disableBoost()
	BOOST_ENABLED = false
	updateServerBoost()
	print("? [ServerBoost] Boost DISABLED!")
end

-- ===================================================================
-- PLAYER JOINED - SEND CURRENT STATE
-- ===================================================================
Players.PlayerAdded:Connect(function(player)
	task.wait(2) -- Wait for GUI to load

	local multiplier = BOOST_ENABLED and SERVER_BOOST or DEFAULT_MULTIPLIER
	UpdateBoostEvent:FireClient(player, BOOST_ENABLED, multiplier)

	print(string.format("?? [ServerBoost] Sent to %s - Enabled: %s, x%.1f", player.Name, tostring(BOOST_ENABLED), multiplier))
end)

-- ===================================================================
-- INITIALIZE
-- ===================================================================
updateServerBoost()

-- Send to existing players
for _, player in pairs(Players:GetPlayers()) do
	local multiplier = BOOST_ENABLED and SERVER_BOOST or DEFAULT_MULTIPLIER
	UpdateBoostEvent:FireClient(player, BOOST_ENABLED, multiplier)
end

print("? [ServerBoost] System Ready!")
print("?? [ServerBoost] To enable boost, set BOOST_ENABLED = true")

-- ===================================================================
-- ?? MANUAL CONTROLS (Untuk testing via command bar)
-- ===================================================================
-- Expose functions globally untuk command bar
_G.EnableBoost = enableBoost
_G.DisableBoost = disableBoost

print("?? [ServerBoost] Manual controls available:")
print("   _G.EnableBoost(8)  -- Enable x8 boost")
print("   _G.DisableBoost()  -- Disable boost")