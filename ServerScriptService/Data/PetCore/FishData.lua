-- FishData - WITH LEVEL SYSTEM + TOGGLEABLE STATS
-- Location: ServerScriptService/Data/PetCore/FishData
-- REPLACE: Full script replacement with Level system added
-- Changes:
-- 1. ? ADDED: Level & XP system (exponential progression)
-- 2. ? ADDED: Level stat in leaderstats (toggleable)
-- 3. ? ADDED: Auto level-up when XP threshold reached
-- 4. ? NOT CHANGED: Coins, FishCaught, Fish, Rod systems (all intact!)

local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ProfileService = require(SSS.Data.DataModule:WaitForChild("ProfileService"))
local dataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local CONFIG = {
	-- ? TOGGLE COINS STAT IN LEADERSTATS
	ENABLE_COINS_STAT = true,
	COINS_STAT_NAME = "Coins",

	-- ? TOGGLE FISHCAUGHT STAT IN LEADERSTATS
	ENABLE_FISHCAUGHT_STAT = true,
	FISHCAUGHT_STAT_NAME = "FishCaught",

	-- ?? TOGGLE LEVEL STAT IN LEADERSTATS
	ENABLE_LEVEL_STAT = true, -- SET TRUE to show Level in leaderstats
	LEVEL_STAT_NAME = "Level",

	-- ?? LEVEL SYSTEM SETTINGS
	XP_PER_FISH = 1, -- XP gained per fish caught
	BASE_XP_REQUIRED = 100, -- XP needed for Level 1 ? 2
	LEVEL_MULTIPLIER = 1.5, -- XP scaling (exponential: 100, 150, 225, 338...)

	-- Other settings
	SYNC_TO_LEADERBOARD = true,
}

-- ===================================================================
-- THROTTLE PROTECTION
-- ===================================================================
local LEADERBOARD_UPDATE_COOLDOWN = 60
local lastLeaderboardUpdate = {}

local function updateLeaderboardThrottled(store, userId, statValue)
	local lastUpdate = lastLeaderboardUpdate[userId] or 0
	local now = os.time()

	if now - lastUpdate >= LEADERBOARD_UPDATE_COOLDOWN then
		lastLeaderboardUpdate[userId] = now
		task.spawn(function()
			pcall(function()
				store:SetAsync(userId, statValue)
			end)
		end)
	end
end

-- ===================================================================
-- SCRIPT SIGNAL
-- ===================================================================
local function NewScriptSignal()
	local ScriptConnection = {}
	ScriptConnection.__index = ScriptConnection

	function ScriptConnection:Disconnect()
		if self._is_connected == false then return end
		self._is_connected = false
		self._script_signal._listener_count -= 1
		if self._script_signal._head == self then
			self._script_signal._head = self._next
		else
			local prev = self._script_signal._head
			while prev ~= nil and prev._next ~= self do prev = prev._next end
			if prev ~= nil then prev._next = self._next end
		end
	end

	local ScriptSignal = {}
	ScriptSignal.__index = ScriptSignal

	function ScriptSignal:Connect(listener)
		local script_connection = {
			_listener = listener,
			_script_signal = self,
			_next = self._head,
			_is_connected = true,
		}
		setmetatable(script_connection, ScriptConnection)
		self._head = script_connection
		self._listener_count += 1
		return script_connection
	end

	function ScriptSignal:Fire(...)
		local item = self._head
		while item ~= nil do
			if item._is_connected == true then
				task.spawn(item._listener, ...)
			end
			item = item._next
		end
	end

	return setmetatable({_head = nil, _listener_count = 0}, ScriptSignal)
end

local GAME_DATA_STORE_KEY = "PlayerGameData_V1"

-- ?? PROFILE TEMPLATE - ADDED LEVEL & XP
local PlayerProfileTemplate = {
	Coins = 0,
	OwnedGamepasses = {},
	SavedFish = {},
	TotalFishCaught = 0,
	OwnedRods = {},
	LastEquippedRod = nil,
	LastPosition = nil,
	FishInventoryLimit = 500,

	-- ?? LEVEL SYSTEM
	Level = 1,
	XP = 0,
	XPtoNextLevel = 100, -- Calculated dynamically
}

local PlayerProfileStore = ProfileService.GetProfileStore(
	GAME_DATA_STORE_KEY,
	PlayerProfileTemplate
)

local PlayerProfiles = {}

local GameProfileService = {}
GameProfileService.ProfileLoadedSignal = NewScriptSignal()

local CURRENCY_AMOUNT_PER_INTERVAL = 6
local CURRENCY_INCREASE_INTERVAL_SECONDS = 120

-- ===================================================================
-- CORE PROFILE FUNCTIONS
-- ===================================================================
function GameProfileService:GetProfile(player)
	local profile = PlayerProfiles[player]
	if profile and profile:IsActive() then
		return profile
	end

	local startTime = os.clock()
	local TIMEOUT_SECONDS = 15
	local checkInterval = 0.1

	while not (profile and profile:IsActive()) and (os.clock() - startTime < TIMEOUT_SECONDS) do
		task.wait(checkInterval)
		profile = PlayerProfiles[player]
	end

	if not (profile and profile:IsActive()) then
		warn(string.format("?? Profile for player %s not loaded after %d seconds!", player.Name, TIMEOUT_SECONDS))
		return nil
	end

	return profile
end

-- ===================================================================
-- ?? LEVEL SYSTEM FUNCTIONS
-- ===================================================================

-- Calculate XP required for next level (exponential)
function GameProfileService:CalculateXPRequired(level)
	local baseXP = CONFIG.BASE_XP_REQUIRED
	local multiplier = CONFIG.LEVEL_MULTIPLIER
	return math.floor(baseXP * (multiplier ^ (level - 1)))
end

-- Get player's current level
function GameProfileService:GetLevel(player)
	local profile = self:GetProfile(player)
	if not profile then return 1 end
	return profile.Data.Level or 1
end

-- Get player's current XP
function GameProfileService:GetXP(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.XP or 0
end

-- Increment XP and handle level-up
function GameProfileService:IncrementXP(player, amount)
	amount = amount or CONFIG.XP_PER_FISH

	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	-- Add XP
	profile.Data.XP = (profile.Data.XP or 0) + amount

	-- Check for level up
	local currentLevel = profile.Data.Level or 1
	local xpNeeded = self:CalculateXPRequired(currentLevel)

	local leveledUp = false
	while profile.Data.XP >= xpNeeded do
		-- Level up!
		profile.Data.XP = profile.Data.XP - xpNeeded
		profile.Data.Level = (profile.Data.Level or 1) + 1
		leveledUp = true

		-- Recalculate XP needed for new level
		currentLevel = profile.Data.Level
		xpNeeded = self:CalculateXPRequired(currentLevel)

		print("[FishData] ?? " .. player.Name .. " leveled up to Level " .. currentLevel .. "!")

		-- Fire RemoteEvent for level up notification
		local levelUpEvent = ReplicatedStorage:FindFirstChild("FishingSystem"):FindFirstChild("LevelUp")
		if levelUpEvent then
			levelUpEvent:FireClient(player, currentLevel)
		end
	end

	-- Update XPtoNextLevel
	profile.Data.XPtoNextLevel = xpNeeded

	-- Update leaderstats Level (if enabled)
	if CONFIG.ENABLE_LEVEL_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
			if levelStat then
				levelStat.Value = profile.Data.Level
			end
		end
	end

	-- Always update attribute
	player:SetAttribute(CONFIG.LEVEL_STAT_NAME, profile.Data.Level)
	player:SetAttribute("XP", profile.Data.XP)
	player:SetAttribute("XPtoNextLevel", profile.Data.XPtoNextLevel)

	return leveledUp
end

-- Set player level (for admin commands)
function GameProfileService:SetLevel(player, level)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Level = math.max(1, level)
	profile.Data.XP = 0
	profile.Data.XPtoNextLevel = self:CalculateXPRequired(profile.Data.Level)

	-- Update leaderstats Level (if enabled)
	if CONFIG.ENABLE_LEVEL_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
			if levelStat then
				levelStat.Value = profile.Data.Level
			end
		end
	end

	player:SetAttribute(CONFIG.LEVEL_STAT_NAME, profile.Data.Level)
	player:SetAttribute("XP", profile.Data.XP)
	player:SetAttribute("XPtoNextLevel", profile.Data.XPtoNextLevel)

	return true
end

-- ===================================================================
-- COIN MANAGEMENT (Unchanged)
-- ===================================================================
function GameProfileService:AddCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, (profile.Data.Coins or 0) + amount)

	if CONFIG.ENABLE_COINS_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
			if coins then coins.Value = profile.Data.Coins end
		end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true
end

function GameProfileService:SetCoins(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.Coins = math.max(0, amount)

	if CONFIG.ENABLE_COINS_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
			if coins then coins.Value = profile.Data.Coins end
		end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true
end

function GameProfileService:TryPurchase(player, cost)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, 0 end

	local currentCoins = profile.Data.Coins or 0
	if currentCoins < cost then return false, currentCoins end

	profile.Data.Coins = currentCoins - cost

	if CONFIG.ENABLE_COINS_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
			if coins then coins.Value = profile.Data.Coins end
		end
	end

	player:SetAttribute("Coins", profile.Data.Coins)
	return true, profile.Data.Coins
end

function GameProfileService:GetCoins(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.Coins or 0
end

function GameProfileService:SavePlayerData(player)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		if CONFIG.ENABLE_COINS_STAT then
			local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
			if coins then profile.Data.Coins = coins.Value end
		end

		if CONFIG.ENABLE_FISHCAUGHT_STAT then
			local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
			if fishCaught then
				profile.Data.TotalFishCaught = fishCaught.Value
			end
		end

		-- ?? Save Level
		if CONFIG.ENABLE_LEVEL_STAT then
			local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
			if levelStat then
				profile.Data.Level = levelStat.Value
			end
		end
	end

	return true
end

-- ===================================================================
-- FISHCAUGHT MANAGEMENT (Unchanged)
-- ===================================================================

function GameProfileService:IncrementFishCaught(player, amount)
	amount = amount or 1

	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.TotalFishCaught = (profile.Data.TotalFishCaught or 0) + amount

	if CONFIG.ENABLE_FISHCAUGHT_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
			if fishCaught then
				fishCaught.Value = profile.Data.TotalFishCaught
			end
		end
	end

	player:SetAttribute(CONFIG.FISHCAUGHT_STAT_NAME, profile.Data.TotalFishCaught)

	print("[FishData] ?? " .. player.Name .. " caught fish! Total: " .. profile.Data.TotalFishCaught)

	return true
end

function GameProfileService:SetFishCaught(player, amount)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.TotalFishCaught = math.max(0, amount)

	if CONFIG.ENABLE_FISHCAUGHT_STAT then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
			if fishCaught then
				fishCaught.Value = profile.Data.TotalFishCaught
			end
		end
	end

	player:SetAttribute(CONFIG.FISHCAUGHT_STAT_NAME, profile.Data.TotalFishCaught)
	return true
end

function GameProfileService:GetFishCaught(player)
	local profile = self:GetProfile(player)
	if not profile then return 0 end
	return profile.Data.TotalFishCaught or 0
end

-- ===================================================================
-- FISHING SYSTEM FUNCTIONS (Unchanged)
-- ===================================================================
function GameProfileService:GetFishInventoryLimit(player)
	local profile = self:GetProfile(player)
	if not profile then return 500 end
	return profile.Data.FishInventoryLimit or 500
end

function GameProfileService:AddFish(player, fishData)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false, nil end

	if not profile.Data.SavedFish then profile.Data.SavedFish = {} end

	local limit = profile.Data.FishInventoryLimit or 500
	if #profile.Data.SavedFish >= limit then
		return false, nil
	end

	local uniqueId = game:GetService("HttpService"):GenerateGUID(false)
	local fishEntry = {
		name = fishData.name,
		weight = fishData.weight,
		rarity = fishData.rarity or "Common",
		uniqueId = uniqueId,
		timestamp = tick(),
		isFavorited = false
	}

	table.insert(profile.Data.SavedFish, fishEntry)

	-- Auto-increment FishCaught
	self:IncrementFishCaught(player, 1)

	-- ?? Auto-increment XP
	self:IncrementXP(player, CONFIG.XP_PER_FISH)

	return true, uniqueId
end

function GameProfileService:RemoveFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return false, nil end

	for i, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			local removed = table.remove(profile.Data.SavedFish, i)
			return true, removed
		end
	end

	return false, nil
end

function GameProfileService:GetSavedFish(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	return profile.Data.SavedFish or {}
end

function GameProfileService:ToggleFavoriteFish(player, fishUniqueId)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.SavedFish then return nil end

	for i, fish in ipairs(profile.Data.SavedFish) do
		if fish.uniqueId == fishUniqueId then
			fish.isFavorited = not fish.isFavorited
			return fish.isFavorited
		end
	end

	return nil
end

-- ===================================================================
-- ROD MANAGEMENT (Unchanged)
-- ===================================================================
function GameProfileService:AddRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	if not profile.Data.OwnedRods then profile.Data.OwnedRods = {} end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	table.insert(profile.Data.OwnedRods, rodName)
	return true
end

function GameProfileService:HasRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile.Data.OwnedRods then return false end

	for _, r in ipairs(profile.Data.OwnedRods) do
		if r == rodName then return true end
	end

	return false
end

function GameProfileService:GetOwnedRods(player)
	local profile = self:GetProfile(player)
	if not profile then return {} end
	return profile.Data.OwnedRods or {}
end

function GameProfileService:SetLastEquippedRod(player, rodName)
	local profile = self:GetProfile(player)
	if not profile or not profile:IsActive() then return false end

	profile.Data.LastEquippedRod = rodName
	return true
end

function GameProfileService:GetLastEquippedRod(player)
	local profile = self:GetProfile(player)
	if not profile then return nil end
	return profile.Data.LastEquippedRod
end

-- ===================================================================
-- PLAYER INITIALIZATION
-- ===================================================================
Players.PlayerAdded:Connect(function(player)

	local success, profile = pcall(function()
		return PlayerProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	end)

	if not success then
		player:Kick("Failed to load player data due to an error. Please try rejoining.")
		return
	end

	if not profile then
		player:Kick("Failed to load player data. Please try rejoining.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()

	if type(profile.Data.Coins) ~= "number" then
		profile.Data.Coins = 0
	end
	if type(profile.Data.SavedFish) ~= "table" then
		profile.Data.SavedFish = {}
	end
	if type(profile.Data.OwnedRods) ~= "table" then
		profile.Data.OwnedRods = {}
	end
	if type(profile.Data.FishInventoryLimit) ~= "number" then
		profile.Data.FishInventoryLimit = 500
	end
	if type(profile.Data.TotalFishCaught) ~= "number" then
		profile.Data.TotalFishCaught = 0
	end

	-- ?? Initialize Level & XP
	if type(profile.Data.Level) ~= "number" then
		profile.Data.Level = 1
	end
	if type(profile.Data.XP) ~= "number" then
		profile.Data.XP = 0
	end
	-- Calculate XPtoNextLevel
	profile.Data.XPtoNextLevel = GameProfileService:CalculateXPRequired(profile.Data.Level)

	PlayerProfiles[player] = profile

	profile:ListenToRelease(function()
		PlayerProfiles[player] = nil
	end)

	if not player:IsDescendantOf(game.Players) then
		profile:Release()
		PlayerProfiles[player] = nil
		return
	end

	GameProfileService.ProfileLoadedSignal:Fire(player)

	-- ? CREATE LEADERSTATS (TOGGLEABLE)
	task.spawn(function()
		local leaderstats = player:FindFirstChild("leaderstats")

		-- Only create leaderstats if at least one stat is enabled
		if CONFIG.ENABLE_COINS_STAT or CONFIG.ENABLE_FISHCAUGHT_STAT or CONFIG.ENABLE_LEVEL_STAT then
			if not leaderstats then
				leaderstats = Instance.new("Folder")
				leaderstats.Name = "leaderstats"
				leaderstats.Parent = player
			end

			-- ? CREATE COINS STAT (if enabled)
			if CONFIG.ENABLE_COINS_STAT then
				local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
				if not coins then
					coins = Instance.new("IntValue")
					coins.Name = CONFIG.COINS_STAT_NAME
					coins.Value = profile.Data.Coins or 0
					coins.Parent = leaderstats
					print("[FishData] ? Created Coins stat for " .. player.Name)
				else
					coins.Value = profile.Data.Coins or 0
				end
			end

			-- ? CREATE FISHCAUGHT STAT (if enabled)
			if CONFIG.ENABLE_FISHCAUGHT_STAT then
				local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
				if not fishCaught then
					fishCaught = Instance.new("IntValue")
					fishCaught.Name = CONFIG.FISHCAUGHT_STAT_NAME
					fishCaught.Value = profile.Data.TotalFishCaught or 0
					fishCaught.Parent = leaderstats
					print("[FishData] ? Created FishCaught stat for " .. player.Name .. ": " .. fishCaught.Value)
				else
					fishCaught.Value = profile.Data.TotalFishCaught or 0
				end
			end

			-- ?? CREATE LEVEL STAT (if enabled)
			if CONFIG.ENABLE_LEVEL_STAT then
				local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
				if not levelStat then
					levelStat = Instance.new("IntValue")
					levelStat.Name = CONFIG.LEVEL_STAT_NAME
					levelStat.Value = profile.Data.Level or 1
					levelStat.Parent = leaderstats
					print("[FishData] ? Created Level stat for " .. player.Name .. ": Level " .. levelStat.Value)
				else
					levelStat.Value = profile.Data.Level or 1
				end
			end
		end

		-- Always set attributes (for scripts to access)
		player:SetAttribute("Coins", profile.Data.Coins or 0)
		player:SetAttribute(CONFIG.FISHCAUGHT_STAT_NAME, profile.Data.TotalFishCaught or 0)
		player:SetAttribute(CONFIG.LEVEL_STAT_NAME, profile.Data.Level or 1)
		player:SetAttribute("XP", profile.Data.XP or 0)
		player:SetAttribute("XPtoNextLevel", profile.Data.XPtoNextLevel or 100)
	end)

	task.spawn(function()
		local backpack = player:WaitForChild("Backpack", 5)
		if not backpack then return end
		task.wait(0.5)

		local wheatInventory = profile.Data.WheatInventory
	end)
end)

-- ===================================================================
-- PLAYER REMOVING
-- ===================================================================
Players.PlayerRemoving:Connect(function(player)
	local profile = PlayerProfiles[player]
	if not profile then return end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		if CONFIG.ENABLE_COINS_STAT then
			local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
			if coins then
				profile.Data.Coins = coins.Value
			end
		end

		if CONFIG.ENABLE_FISHCAUGHT_STAT then
			local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
			if fishCaught then
				profile.Data.TotalFishCaught = fishCaught.Value
				print("[FishData] ?? Saved " .. player.Name .. "'s FishCaught: " .. fishCaught.Value)
			end
		end

		-- ?? Save Level
		if CONFIG.ENABLE_LEVEL_STAT then
			local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
			if levelStat then
				profile.Data.Level = levelStat.Value
				print("[FishData] ?? Saved " .. player.Name .. "'s Level: " .. levelStat.Value)
			end
		end
	end

	local releaseSuccess = false
	for attempt = 1, 3 do
		local success = pcall(function()
			profile:Release()
		end)

		if success then
			releaseSuccess = true
			break
		else
			task.wait(0.5)
		end
	end

	PlayerProfiles[player] = nil
end)

-- ===================================================================
-- AUTO-SAVE LOOP
-- ===================================================================
task.spawn(function()
	while task.wait(600) do 
		for _, player in pairs(Players:GetPlayers()) do
			GameProfileService:SavePlayerData(player)
		end
	end
end)

-- ===================================================================
-- BIND TO CLOSE
-- ===================================================================
game:BindToClose(function()
	local startTime = os.clock()
	local MAX_WAIT_TIME = 25

	local savePromises = {}
	for player, profile in pairs(PlayerProfiles) do
		if profile and profile:IsActive() then
			table.insert(savePromises, task.spawn(function()
				local leaderstats = player:FindFirstChild("leaderstats")
				if leaderstats then
					if CONFIG.ENABLE_COINS_STAT then
						local coins = leaderstats:FindFirstChild(CONFIG.COINS_STAT_NAME)
						if coins then profile.Data.Coins = coins.Value end
					end

					if CONFIG.ENABLE_FISHCAUGHT_STAT then
						local fishCaught = leaderstats:FindFirstChild(CONFIG.FISHCAUGHT_STAT_NAME)
						if fishCaught then
							profile.Data.TotalFishCaught = fishCaught.Value
						end
					end

					-- ?? Save Level
					if CONFIG.ENABLE_LEVEL_STAT then
						local levelStat = leaderstats:FindFirstChild(CONFIG.LEVEL_STAT_NAME)
						if levelStat then
							profile.Data.Level = levelStat.Value
						end
					end
				end

				for attempt = 1, 3 do
					local success = pcall(function()
						profile:Release()
					end)

					if success then break else task.wait(0.3) end
				end
			end))
		end
	end

	while os.clock() - startTime < MAX_WAIT_TIME and #savePromises > 0 do
		task.wait(0.1)
	end

	task.wait(2)
end)

-- ===================================================================
-- INITIALIZATION LOG
-- ===================================================================
print("=================================================================")
print("?? FishData - Initialized with Level System + Toggleable Stats!")
print("=================================================================")
print("?? Configuration:")
print("   Coins Stat: " .. tostring(CONFIG.ENABLE_COINS_STAT))
print("   FishCaught Stat: " .. tostring(CONFIG.ENABLE_FISHCAUGHT_STAT))
print("   Level Stat: " .. tostring(CONFIG.ENABLE_LEVEL_STAT))
print("   XP per Fish: " .. CONFIG.XP_PER_FISH)
print("   Base XP Required: " .. CONFIG.BASE_XP_REQUIRED)
print("   Level Multiplier: " .. CONFIG.LEVEL_MULTIPLIER)
print("=================================================================")
print("? Stats in leaderstats:")
if CONFIG.ENABLE_COINS_STAT then
	print("   - " .. CONFIG.COINS_STAT_NAME .. " (visible)")
else
	print("   - " .. CONFIG.COINS_STAT_NAME .. " (hidden, but still tracked)")
end
if CONFIG.ENABLE_FISHCAUGHT_STAT then
	print("   - " .. CONFIG.FISHCAUGHT_STAT_NAME .. " (visible)")
else
	print("   - " .. CONFIG.FISHCAUGHT_STAT_NAME .. " (hidden, but still tracked)")
end
if CONFIG.ENABLE_LEVEL_STAT then
	print("   - " .. CONFIG.LEVEL_STAT_NAME .. " (visible)")
else
	print("   - " .. CONFIG.LEVEL_STAT_NAME .. " (hidden, but still tracked)")
end
print("=================================================================")
return GameProfileService