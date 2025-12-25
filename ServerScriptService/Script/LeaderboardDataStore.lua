-- LeaderboardDataStore_StudioSafe.lua
-- Location: ServerScriptService/Script/LeaderboardDataStore
-- Purpose: Sync player fishing data to OrderedDataStore (STUDIO-SAFE VERSION)
-- REPLACE: Full script replacement with Studio mode compatibility

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for FishingSystem
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
if not FishingSystem then
	warn("[LeaderboardSync] ? FishingSystem not found in ReplicatedStorage!")
	return
end

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local CONFIG = {
	DATASTORE_NAME = "FishLeaderboard_TotalCaught_V2",
	UPDATE_INTERVAL = 60,
	MAX_RETRIES = 3,
	RETRY_DELAY = 5,
	STUDIO_MODE = RunService:IsStudio(),
}

-- ===================================================================
-- DATASTORE SETUP
-- ===================================================================
local LeaderboardDataStore = nil
local dataStoreAvailable = false

-- Try to initialize DataStore
local function initializeDataStore()
	local success, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(CONFIG.DATASTORE_NAME)
	end)

	if success then
		LeaderboardDataStore = result
		dataStoreAvailable = true
		print("[LeaderboardSync] ? DataStore connected: " .. CONFIG.DATASTORE_NAME)
		return true
	else
		warn("[LeaderboardSync] ?? DataStore not available: " .. tostring(result))
		if CONFIG.STUDIO_MODE then
			warn("[LeaderboardSync] ?? Studio Mode - DataStore disabled")
			warn("[LeaderboardSync] ?? To enable: Game Settings ? Security ? Enable API Services")
			warn("[LeaderboardSync] ?? Or publish game to Roblox")
			warn("[LeaderboardSync] ?? Leaderboard will use FALLBACK mode (live players only)")
		end
		dataStoreAvailable = false
		return false
	end
end

-- ===================================================================
-- PLAYER DATA TRACKING
-- ===================================================================
local playerData = {}

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

local function getPlayerFishCaught(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return 0 end

	local fishCaught = leaderstats:FindFirstChild("FishCaught")
	if not fishCaught then return 0 end

	return fishCaught.Value or 0
end

local function updatePlayerDataStore(userId, value, retryCount)
	if not dataStoreAvailable then
		-- Skip DataStore updates in Studio mode
		return
	end

	retryCount = retryCount or 0

	local success, err = pcall(function()
		LeaderboardDataStore:UpdateAsync(tostring(userId), function(oldValue)
			if oldValue ~= value then
				return value
			end
			return oldValue
		end)
	end)

	if not success then
		if retryCount < CONFIG.MAX_RETRIES then
			warn("[LeaderboardSync] Failed to update UserId " .. userId .. ", retrying... (" .. (retryCount + 1) .. "/" .. CONFIG.MAX_RETRIES .. ")")
			task.wait(CONFIG.RETRY_DELAY)
			updatePlayerDataStore(userId, value, retryCount + 1)
		else
			warn("[LeaderboardSync] Failed to update UserId " .. userId .. " after " .. CONFIG.MAX_RETRIES .. " retries: " .. tostring(err))
		end
	else
		print("[LeaderboardSync] ? Updated UserId " .. userId .. ": " .. value .. " fish caught")
	end
end

-- ===================================================================
-- PLAYER TRACKING
-- ===================================================================

Players.PlayerAdded:Connect(function(player)
	task.wait(2)

	local fishCaught = getPlayerFishCaught(player)
	playerData[player.UserId] = fishCaught

	print("[LeaderboardSync] ?? Tracking player: " .. player.Name .. " (UserId: " .. player.UserId .. ") - Fish Caught: " .. fishCaught)
end)

Players.PlayerRemoving:Connect(function(player)
	local fishCaught = getPlayerFishCaught(player)

	if fishCaught >= 1 and dataStoreAvailable then
		print("[LeaderboardSync] ?? Saving player data on leave: " .. player.Name .. " - " .. fishCaught .. " fish")
		updatePlayerDataStore(player.UserId, fishCaught)
	end

	playerData[player.UserId] = nil
end)

-- Track existing players
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		task.wait(2)
		local fishCaught = getPlayerFishCaught(player)
		playerData[player.UserId] = fishCaught
		print("[LeaderboardSync] ?? Tracking existing player: " .. player.Name .. " - Fish Caught: " .. fishCaught)
	end)
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

print("=================================================================")
print("?? [LeaderboardSync] Leaderboard Data Sync - Initializing...")
print("=================================================================")
print("?? Configuration:")
print("   DataStore: " .. CONFIG.DATASTORE_NAME)
print("   Update Interval: " .. CONFIG.UPDATE_INTERVAL .. " seconds")
print("   Max Retries: " .. CONFIG.MAX_RETRIES)
print("   Studio Mode: " .. tostring(CONFIG.STUDIO_MODE))
print("=================================================================")

-- Initialize DataStore
initializeDataStore()

print("=================================================================")
if dataStoreAvailable then
	print("? [LeaderboardSync] DataStore sync ENABLED")
else
	print("?? [LeaderboardSync] DataStore sync DISABLED (Studio/API Services)")
	print("?? [LeaderboardSync] Leaderboard will show live players only")
end
print("=================================================================")

-- ===================================================================
-- PERIODIC UPDATE LOOP
-- ===================================================================

task.spawn(function()
	while true do
		task.wait(CONFIG.UPDATE_INTERVAL)

		if not dataStoreAvailable then
			-- Skip DataStore updates in Studio mode
			continue
		end

		print("=================================================================")
		print("?? [LeaderboardSync] Starting periodic update cycle...")
		print("=================================================================")

		local updateCount = 0

		for _, player in pairs(Players:GetPlayers()) do
			local fishCaught = getPlayerFishCaught(player)
			local previousValue = playerData[player.UserId] or 0

			if fishCaught >= 1 and fishCaught ~= previousValue then
				updatePlayerDataStore(player.UserId, fishCaught)
				playerData[player.UserId] = fishCaught
				updateCount = updateCount + 1
			end
		end

		print("=================================================================")
		print("? [LeaderboardSync] Update cycle complete!")
		print("   Players Updated: " .. updateCount)
		print("   Next update in: " .. CONFIG.UPDATE_INTERVAL .. " seconds")
		print("=================================================================")
	end
end)

-- ===================================================================
-- MANUAL UPDATE TRIGGER
-- ===================================================================

local UpdateLeaderboardEvent = Instance.new("RemoteEvent")
UpdateLeaderboardEvent.Name = "UpdateLeaderboard"
UpdateLeaderboardEvent.Parent = FishingSystem

UpdateLeaderboardEvent.OnServerEvent:Connect(function(player)
	local fishCaught = getPlayerFishCaught(player)

	if fishCaught >= 1 and dataStoreAvailable then
		print("[LeaderboardSync] ?? Manual update triggered by: " .. player.Name .. " - " .. fishCaught .. " fish")
		updatePlayerDataStore(player.UserId, fishCaught)
		playerData[player.UserId] = fishCaught
	end
end)

print("? [LeaderboardSync] Manual update event created: UpdateLeaderboard")
print("=================================================================")

-- ===================================================================