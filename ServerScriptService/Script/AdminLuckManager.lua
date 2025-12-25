-- ServerScriptService/AdminLuckSystem (UPDATED WITH GUI SUPPORT)
local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")

print("?? [AdminLuck] Security System Active.")

-- ==============================================================================
-- ?? KONFIGURASI ADMIN (WAJIB ISI ID!)
-- ==============================================================================
local ADMIN_IDS = {
	8840108591, -- ?? GANTI INI DENGAN ID ASLI KAMU!
	-- 87654321, -- ID Teman 1
	-- 11223344, -- ID Teman 2
}

local GLOBAL_TOPIC = "GlobalLuckEvent"

-- ==============================================================================
-- ??? AUTO-SETUP
-- ==============================================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem", 10)
local LuckValue = FishingSystem and FishingSystem:FindFirstChild("GlobalLuckMultiplier")

if not LuckValue and FishingSystem then
	LuckValue = Instance.new("NumberValue")
	LuckValue.Name = "GlobalLuckMultiplier"
	LuckValue.Value = 1
	LuckValue.Parent = FishingSystem
end

local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local SendChatMessage = FishingSystem:WaitForChild("SendChatMessage")
local currentBoostTask = nil

-- ?? CREATE GUI UPDATE EVENT
local UpdateBoostEvent = FishingSystem:FindFirstChild("UpdateServerBoost")
if not UpdateBoostEvent then
	UpdateBoostEvent = Instance.new("RemoteEvent")
	UpdateBoostEvent.Name = "UpdateServerBoost"
	UpdateBoostEvent.Parent = FishingSystem
	print("? [AdminLuck] Created UpdateServerBoost event")
end

-- ==============================================================================
-- ?? LOGIKA KEAMANAN
-- ==============================================================================

local function isAdmin(userId)
	for _, id in ipairs(ADMIN_IDS) do
		if userId == id then 
			return true 
		end
	end
	return false
end

local function formatTime(seconds)
	if seconds >= 60 then
		return string.format("%d menit", math.floor(seconds/60))
	else
		return string.format("%d detik", seconds)
	end
end

-- ?? FUNCTION: UPDATE GUI FOR ALL PLAYERS
local function updateBoostGUI(isEnabled, multiplier)
	print(string.format("???  [AdminLuck] Updating GUI - Enabled: %s, Multiplier: x%.0f", tostring(isEnabled), multiplier))

	for _, player in pairs(Players:GetPlayers()) do
		UpdateBoostEvent:FireClient(player, isEnabled, multiplier)
	end
end

local function executeLuckBoost(multiplier, duration, isGlobal, adminName)
	if currentBoostTask then task.cancel(currentBoostTask) end

	currentBoostTask = task.spawn(function()
		-- Set luck value
		if LuckValue then LuckValue.Value = multiplier end

		-- ?? SHOW GUI
		updateBoostGUI(true, multiplier)

		local scopeText = isGlobal and "GLOBAL" or "SERVER"
		local msg = string.format("?? %s EVENT! Luck x%d oleh %s (%s)!", scopeText, multiplier, adminName, formatTime(duration))

		print("?? [AdminLuck] BOOST AKTIF: " .. msg)

		-- Broadcast Notifikasi
		ShowNotification:FireAllClients(msg, 8, Color3.fromRGB(0, 255, 0))
		SendChatMessage:FireAllClients("General", "[SYSTEM]", msg, 0, "Legendary")

		-- Timer
		local timeLeft = duration
		while timeLeft > 0 do
			task.wait(1)
			timeLeft = timeLeft - 1
		end

		-- Reset luck
		if LuckValue then LuckValue.Value = 1 end

		-- ?? HIDE GUI
		updateBoostGUI(false, 1)

		ShowNotification:FireAllClients("Event Luck Berakhir.", 5, Color3.fromRGB(200, 200, 200))
		print("?? [AdminLuck] Boost Selesai.")
	end)
end

-- ==============================================================================
-- ?? PROCESSOR COMMAND
-- ==============================================================================
local function processCommand(player, text)
	text = string.gsub(text, "^%s*(.-)%s*$", "%1")

	local prefix = string.sub(text, 1, 1)
	local commandBody = string.sub(text, 2)
	local args = string.split(commandBody, " ")
	local cmd = string.lower(args[1] or "")

	if prefix ~= "/" and prefix ~= ":" and prefix ~= "!" then return end

	if cmd == "luck" then
		-- CEK KEAMANAN DULU
		if not isAdmin(player.UserId) then
			warn("? SECURITY ALERT: " .. player.Name .. " mencoba pakai command admin!")
			ShowNotification:FireClient(player, "? Anda bukan Admin!", 3, Color3.fromRGB(255, 50, 50))
			return
		end

		print("?? [AdminLuck] Akses Diterima: " .. player.Name)

		local scope = string.lower(args[2] or "")
		local mult = tonumber(args[3])
		local minutes = tonumber(args[4])

		if (scope ~= "server" and scope ~= "global") or not mult or not minutes then
			ShowNotification:FireClient(player, "Format: !luck [server/global] [angka] [menit]", 5, Color3.fromRGB(255, 255, 0))
			return
		end

		local duration = minutes * 60

		if scope == "server" then
			executeLuckBoost(mult, duration, false, player.Name)
		elseif scope == "global" then
			pcall(function()
				MessagingService:PublishAsync(GLOBAL_TOPIC, {m=mult, d=duration, a=player.Name})
			end)
			executeLuckBoost(mult, duration, true, player.Name)
		end

	elseif cmd == "unluck" then
		if isAdmin(player.UserId) then
			if currentBoostTask then task.cancel(currentBoostTask) end
			if LuckValue then LuckValue.Value = 1 end

			-- ?? HIDE GUI
			updateBoostGUI(false, 1)

			ShowNotification:FireAllClients("?? Boost dibatalkan Admin.", 4, Color3.fromRGB(255, 100, 100))
		end
	end
end

-- ==============================================================================
-- ?? LISTENER
-- ==============================================================================

Players.PlayerAdded:Connect(function(player)
	print("?? LOGIN: " .. player.Name .. " | ID: " .. player.UserId)

	-- ?? SEND CURRENT BOOST STATE TO NEW PLAYER
	task.wait(2) -- Wait for GUI to load
	local currentMultiplier = LuckValue and LuckValue.Value or 1
	local isBoostActive = currentMultiplier > 1
	UpdateBoostEvent:FireClient(player, isBoostActive, currentMultiplier)
	print(string.format("?? [AdminLuck] Sent boost state to %s: %s (x%.0f)", player.Name, tostring(isBoostActive), currentMultiplier))

	player.Chatted:Connect(function(msg)
		processCommand(player, msg)
	end)
end)

if TextChatService:FindFirstChild("TextChannels") then
	local general = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
	if general then
		general.ShouldDeliverCallback = function(message, source)
			processCommand(Players:GetPlayerByUserId(source.UserId), message.Text)
			return true
		end
	end
end

pcall(function()
	MessagingService:SubscribeAsync(GLOBAL_TOPIC, function(msg)
		local d = msg.Data
		if d then executeLuckBoost(d.m, d.d, true, d.a) end
	end)
end)

print("? [AdminLuck] System fully loaded with GUI support!")