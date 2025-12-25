-- NextCatchCommand - Force Next Fish Catch
-- ServerScriptService/Script/NextCatchCommand
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")

print("?? [NextCatch] Command System Loading...")

-- ===================================================================
-- ?? ADMIN LIST - GANTI USER ID ANDA!
-- ===================================================================
local ADMIN_IDS = {
	-- ?? GANTI dengan UserID Owner/Admin Anda!
	8840108591, -- Contoh UserID
	-- Tambah admin lain di bawah:
	-- 987654321,
}

local function isAdmin(userId)
	for _, id in ipairs(ADMIN_IDS) do
		if userId == id then return true end
	end
	return false
end

-- ===================================================================
-- ?? FUNCTION: FIND FISH BY NAME (CASE INSENSITIVE)
-- ===================================================================
local function findFishByName(fishName)
	fishName = string.lower(fishName)

	-- Exact match first
	for _, fish in ipairs(FishingConfig.FishTable) do
		if string.lower(fish.name) == fishName then
			return fish
		end
	end

	-- Try partial match
	for _, fish in ipairs(FishingConfig.FishTable) do
		if string.find(string.lower(fish.name), fishName) then
			return fish
		end
	end

	return nil
end

-- ===================================================================
-- ?? FUNCTION: PROCESS !nextcatch COMMAND
-- ===================================================================
local function processNextCatchCommand(admin, text)
	text = string.gsub(text, "^%s*(.-)%s*$", "%1") -- Trim whitespace

	local prefix = string.sub(text, 1, 1)
	if prefix ~= "/" and prefix ~= ":" and prefix ~= "!" then return end

	local commandBody = string.sub(text, 2)
	local args = string.split(commandBody, " ")
	local cmd = string.lower(args[1] or "")

	if cmd ~= "nextcatch" then return end

	-- Security check
	if not isAdmin(admin.UserId) then
		warn("? [NextCatch] Unauthorized access attempt by " .. admin.Name)
		ShowNotification:FireClient(admin, "? You are not authorized!", 3, Color3.fromRGB(255, 50, 50))
		return
	end

	-- Parse arguments
	local targetUsername = args[2]
	local fishId = args[3]
	local fishWeight = tonumber(args[4])

	-- Validation
	if not targetUsername or not fishId or not fishWeight then
		ShowNotification:FireClient(
			admin,
			"? Format: !nextcatch [username] [fishname] [kg]\nContoh: !nextcatch Player1 whale 50",
			5,
			Color3.fromRGB(255, 100, 100)
		)
		return
	end

	-- Find target player
	local targetPlayer = nil
	for _, player in pairs(Players:GetPlayers()) do
		if string.lower(player.Name) == string.lower(targetUsername) or 
			string.find(string.lower(player.Name), string.lower(targetUsername)) then
			targetPlayer = player
			break
		end
	end

	if not targetPlayer then
		ShowNotification:FireClient(
			admin,
			string.format("? Player '%s' tidak ditemukan!", targetUsername),
			4,
			Color3.fromRGB(255, 100, 100)
		)
		return
	end

	-- Find fish by name
	local fish = findFishByName(fishId)

	if not fish then
		ShowNotification:FireClient(
			admin,
			string.format("? Fish '%s' tidak ditemukan!\nContoh fish: whale, shark, dolphin", fishId),
			5,
			Color3.fromRGB(255, 100, 100)
		)
		return
	end

	-- Validate weight range
	if fishWeight < fish.minKg or fishWeight > fish.maxKg then
		ShowNotification:FireClient(
			admin,
			string.format("?? Warning: %s normal range: %.1f-%.1fkg\nForcing anyway...", 
				fish.name, fish.minKg, fish.maxKg),
			4,
			Color3.fromRGB(255, 200, 0)
		)
	end

	-- ?? SET FORCED FISH VIA GLOBAL FUNCTION
	if _G.SetNextCatchData then
		_G.SetNextCatchData(targetPlayer.UserId, fish.name, fishWeight)

		-- Success notification (ADMIN ONLY)
		ShowNotification:FireClient(
			admin,
			string.format("? Next catch for %s:\n%s (%.1fkg, %s)", 
				targetPlayer.Name, fish.name, fishWeight, fish.rarity),
			6,
			Color3.fromRGB(100, 255, 100)
		)

		print(string.format("? [NextCatch] Set by %s: %s will catch %s (%.1fkg)", 
			admin.Name, targetPlayer.Name, fish.name, fishWeight))
	else
		warn("?? [NextCatch] _G.SetNextCatchData not found! Make sure FishingServer loaded first.")
		ShowNotification:FireClient(
			admin,
			"? NextCatch system not initialized!\nCheck server console.",
			4,
			Color3.fromRGB(255, 100, 100)
		)
	end
end

-- ===================================================================
-- ?? CHAT LISTENER (Legacy Chat)
-- ===================================================================
Players.PlayerAdded:Connect(function(player)
	print("?? [NextCatch] Player joined: " .. player.Name .. " | ID: " .. player.UserId)

	player.Chatted:Connect(function(msg)
		processNextCatchCommand(player, msg)
	end)
end)

-- ===================================================================
-- ?? CHAT LISTENER (TextChatService - New Chat)
-- ===================================================================
if TextChatService:FindFirstChild("TextChannels") then
	local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	if general then
		general.ShouldDeliverCallback = function(message, source)
			local player = Players:GetPlayerByUserId(source.UserId)
			if player then
				processNextCatchCommand(player, message.Text)
			end
			return true
		end
		print("? [NextCatch] TextChatService listener active")
	end
end

print("? [NextCatch] Command system ready!")
print("?? Usage: !nextcatch [username] [fishname] [kg]")
print("?? Example: !nextcatch Player1 whale 500")