-- Global Fish Chat Client Handler
-- LOKASI: StarterPlayerScripts/GlobalFishChatHandler
-- TYPE: LocalScript
-- PURPOSE: Display fish catch messages in chat (General + Global channels)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local SendChatMessage = FishingSystem:WaitForChild("SendChatMessage")

local player = Players.LocalPlayer

print("? [FishChatClient] Initializing...")

-- ===================================================================
-- ?? CONFIGURATION
-- ===================================================================
local CONFIG = {
	USE_NEW_CHAT = true, -- TextChatService (recommended)
	SHOW_EMOJIS = true,
	SHOW_WEIGHT = true,

	-- Sound on notification (DISABLED - no spam!)
	PLAY_SOUND_ON_GLOBAL = false
}

-- ===================================================================
-- ?? FORMATTING
-- ===================================================================
local CHANNEL_PREFIXES = {
	General = "??",
	Global = "??"
}

local RARITY_EMOJIS = {
	Epic = "?",
	Legendary = "??",
	Unknown = "??"
}

-- ===================================================================
-- ?? MESSAGE TEMPLATES
-- ===================================================================
local function formatMessage(channel, playerName, fishName, weight, rarity)
	local channelEmoji = CHANNEL_PREFIXES[channel] or "??"
	local rarityEmoji = RARITY_EMOJIS[rarity] or "??"

	local prefix = string.format("[%s %s]", channelEmoji, channel)
	local message = ""

	if rarity == "Unknown" then
		-- Mythical fish - special format
		message = string.format("%s %s %s caught MYTHICAL %s! (%.1fkg) %s", 
			prefix, rarityEmoji, playerName, fishName, weight, rarityEmoji)
	elseif rarity == "Legendary" then
		-- Legendary fish
		message = string.format("%s %s %s caught legendary %s! (%.1fkg)", 
			prefix, rarityEmoji, playerName, fishName, weight)
	elseif rarity == "Epic" then
		-- Epic fish
		message = string.format("%s %s %s caught rare %s! (%.1fkg)", 
			prefix, rarityEmoji, playerName, fishName, weight)
	else
		-- Generic format
		message = string.format("%s %s caught %s (%.1fkg)", 
			prefix, playerName, fishName, weight)
	end

	return message
end

-- ===================================================================
-- ?? DISPLAY MESSAGE (NEW CHAT)
-- ===================================================================
local function displayMessageNewChat(message, channel)
	local success, err = pcall(function()
		local generalChannel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXGeneral")

		if generalChannel then
			-- Create TextChannel message
			generalChannel:DisplaySystemMessage(message)

			print(string.format("?? [FishChatClient] Displayed in chat: %s", message))
		else
			warn("?? [FishChatClient] RBXGeneral channel not found!")
		end
	end)

	if not success then
		warn(string.format("? [FishChatClient] Failed to display: %s", tostring(err)))
	end
end

-- ===================================================================
-- ?? DISPLAY MESSAGE (LEGACY CHAT)
-- ===================================================================
local function displayMessageLegacyChat(message, channel)
	local success, err = pcall(function()
		-- Use SetCore for legacy chat
		local color = Color3.fromRGB(255, 255, 100) -- Yellow

		if channel == "Global" then
			color = Color3.fromRGB(100, 200, 255) -- Blue for global
		end

		StarterGui:SetCore("ChatMakeSystemMessage", {
			Text = message,
			Color = color,
			Font = Enum.Font.SourceSansBold,
			FontSize = Enum.FontSize.Size18
		})

		print(string.format("?? [FishChatClient] Displayed (legacy): %s", message))
	end)

	if not success then
		warn(string.format("? [FishChatClient] Failed to display legacy: %s", tostring(err)))
	end
end

-- ===================================================================
-- ?? HANDLE MESSAGE FROM SERVER
-- ===================================================================
local function onMessageReceived(channel, playerName, fishName, weight, rarity)
	print("=================================================================")
	print(string.format("?? [FishChatClient] Received message:"))
	print(string.format("   Channel: %s", channel))
	print(string.format("   Player: %s", playerName))
	print(string.format("   Fish: %s", fishName))
	print(string.format("   Weight: %.1fkg", weight))
	print(string.format("   Rarity: %s", rarity))
	print("=================================================================")

	-- Format message
	local message = formatMessage(channel, playerName, fishName, weight, rarity)

	-- Display in chat
	if CONFIG.USE_NEW_CHAT then
		displayMessageNewChat(message, channel)
	else
		displayMessageLegacyChat(message, channel)
	end
end

-- ===================================================================
-- ?? CONNECT TO SERVER EVENT
-- ===================================================================
SendChatMessage.OnClientEvent:Connect(function(channel, playerName, fishName, weight, rarity)
	onMessageReceived(channel, playerName, fishName, weight, rarity)
end)

print("? [FishChatClient] Ready! Listening for fish catch messages...")
print("   Chat System: " .. (CONFIG.USE_NEW_CHAT and "TextChatService (New)" or "Legacy"))
print("   Channels: General, Global")
print("   Sound: Disabled (no spam)")
print("=================================================================")