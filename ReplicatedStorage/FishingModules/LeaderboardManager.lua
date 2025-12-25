-- LeaderboardManager.lua
-- Location: ReplicatedStorage/FishingSystem/FishingModules/LeaderboardManager
-- Purpose: Manage leaderboard data fetching and caching for fishing system V2

local LeaderboardManager = {}

-- ===================================================================
-- CONFIGURATION
-- ===================================================================
local CONFIG = {
	LEADERBOARD_TYPE = "TotalFishCaught", -- Type of leaderboard
	MAX_PLAYERS = 15, -- Top 15 players
	MIN_VALUE = 1, -- Minimum fish caught to appear
	CACHE_DURATION = 5, -- Cache data for 5 seconds to reduce DataStore calls
}

-- ===================================================================
-- COLORS
-- ===================================================================
local COLORS = {
	Default = Color3.fromRGB(255, 255, 255),
	Gold = Color3.fromRGB(255, 215, 0),
	Silver = Color3.fromRGB(192, 192, 192),
	Bronze = Color3.fromRGB(205, 127, 50)
}

-- ===================================================================
-- CACHE SYSTEM
-- ===================================================================
local cachedData = nil
local lastCacheTime = 0

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

-- Format number with commas (e.g., 1000 -> 1,000)
local function formatWithCommas(num)
	local formatted = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formatted:sub(1, 1) == "," and formatted:sub(2) or formatted
end

-- Get color based on position
local function getColorForPosition(position)
	if position == 1 then
		return COLORS.Gold
	elseif position == 2 then
		return COLORS.Silver
	elseif position == 3 then
		return COLORS.Bronze
	else
		return COLORS.Default
	end
end

-- Get username from UserId (with error handling)
local function getUsernameFromId(userId)
	local Players = game:GetService("Players")
	local success, username = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success then
		return username
	else
		return "[Unknown]"
	end
end

-- ===================================================================
-- PUBLIC FUNCTIONS
-- ===================================================================

-- Get leaderboard data (with caching)
function LeaderboardManager:GetLeaderboardData()
	local currentTime = tick()

	-- Return cached data if still valid
	if cachedData and (currentTime - lastCacheTime) < CONFIG.CACHE_DURATION then
		return cachedData
	end

	-- Fetch new data (this will be called by server with DataStore access)
	return nil -- Server will handle DataStore fetching
end

-- Format leaderboard entry for display
function LeaderboardManager:FormatEntry(position, userId, value)
	local username = getUsernameFromId(userId)
	local color = getColorForPosition(position)
	local formattedValue = formatWithCommas(value)

	return {
		Position = position,
		UserId = userId,
		Username = username,
		Value = value,
		FormattedValue = formattedValue,
		Color = color,
		ProfilePictureUrl = "https://www.roblox.com/bust-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
	}
end

-- Update cache (called by server)
function LeaderboardManager:UpdateCache(data)
	cachedData = data
	lastCacheTime = tick()
end

-- Get configuration
function LeaderboardManager:GetConfig()
	return CONFIG
end

-- Get color by position (for GUI)
function LeaderboardManager:GetColorForPosition(position)
	return getColorForPosition(position)
end

-- Format value with commas (for GUI)
function LeaderboardManager:FormatNumber(num)
	return formatWithCommas(num)
end

-- ===================================================================

return LeaderboardManager