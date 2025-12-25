-- GlobalFishCatchPublisher - FINAL (NO DUPLICATES)
-- Location: ServerScriptService/Script/GlobalFishCatchPublisher
-- Purpose: Publish fish catches to global chat
-- Epic/Legendary ? General only
-- Unknown ? Global only

print("=================================================================")
print("?? [GlobalFish] SCRIPT LOADING... (FINAL VERSION)")
print("=================================================================")

local MessagingService = game:GetService("MessagingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("? [GlobalFish] Services loaded")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
print("? [GlobalFish] FishingSystem found")

local PublishFishCatch = FishingSystem:WaitForChild("PublishFishCatch")
print("? [GlobalFish] PublishFishCatch event found")

local SendChatMessage = FishingSystem:WaitForChild("SendChatMessage")
print("? [GlobalFish] SendChatMessage event found")

local TOPIC_NAME = "GlobalFishCatch"

-- Generate unique server ID
local SERVER_ID = game.JobId
if SERVER_ID == "" then
	SERVER_ID = "Studio_" .. tostring(math.random(1000000, 9999999))
end

print("? [GlobalFish] Server ID: " .. SERVER_ID)

-- ===================================================================
-- RELAY: Receive global messages from OTHER servers
-- ===================================================================

-- Define callback function FIRST
local function onGlobalCatchReceived(message)
	print("?? [GlobalFish] Received message from MessagingService")

	local data = message.Data
	if not data or not data.Sender or not data.FishName or not data.Weight or not data.Rarity then
		warn("? [GlobalFish] Incomplete data received")
		return
	end

	print(string.format("?? [GlobalFish] Data: %s caught %s (%s)", data.Sender, data.FishName, data.Rarity))

	-- Skip messages from THIS server (prevents duplicate in Studio)
	if data.ServerId == SERVER_ID then
		print("?? [GlobalFish] Skipping own message (prevent duplicate)")
		return
	end

	-- Only Unknown rarity should appear in Global
	if data.Rarity ~= "Unknown" then
		print("?? [GlobalFish] Not Unknown rarity, skipping Global broadcast")
		return
	end

	print(string.format("? [GlobalFish] Sending to Global channel: %s caught %s", data.Sender, data.FishName))

	-- Send to all clients to display in Global channel
	SendChatMessage:FireAllClients("Global", data.Sender, data.FishName, data.Weight, data.Rarity)
	print("? [GlobalFish] Fired to all clients (Global channel)")
end

print("?? [GlobalFish] Setting up MessagingService subscription...")

-- Make subscription NON-BLOCKING using spawn
task.spawn(function()
	local subscribeSuccess, subscribeErr = pcall(function()
		MessagingService:SubscribeAsync(TOPIC_NAME, onGlobalCatchReceived)
	end)

	if subscribeSuccess then
		print("? [GlobalFish] MessagingService subscription successful")
	else
		warn("? [GlobalFish] MessagingService subscription failed: " .. tostring(subscribeErr))
		warn("?? [GlobalFish] Cross-server will NOT work (but local chat will work!)")
	end
end)

-- Continue script immediately (don't wait for subscription)
print("? [GlobalFish] Subscription started in background")
print("? [GlobalFish] Continuing with event setup...")

-- ===================================================================
-- PUBLISHER: Publish rare fish catches (NO DUPLICATES!)
-- ===================================================================
print("?? [GlobalFish] Setting up PublishFishCatch event listener...")

-- Safeguard: Track if listener already setup
local listenerSetup = false

if not listenerSetup then
	PublishFishCatch.OnServerEvent:Connect(function(player, fishName, weight, rarity)
		print("=================================================================")
		print(string.format("?? [GlobalFish] Event received from %s", player.Name))
		print(string.format("   Fish: %s", fishName))
		print(string.format("   Weight: %.1fkg", weight))
		print(string.format("   Rarity: %s", rarity))
		print("=================================================================")

		-- Check rarity
		local isEpic = rarity == "Epic"
		local isLegendary = rarity == "Legendary"
		local isUnknown = rarity == "Unknown"

		-- Epic and Legendary go to General channel ONLY
		if isEpic or isLegendary then
			print(string.format("?? [GlobalFish] %s rarity ? General channel only", rarity))
			SendChatMessage:FireAllClients("General", player.Name, fishName, weight, rarity)
			print("? [GlobalFish] Sent to General channel (Epic/Legendary)")
			return
		end

		-- Unknown goes to Global ONLY (no General!)
		if isUnknown then
			print("?? [GlobalFish] Unknown fish! Publishing to Global only (no General)")

			-- NO General for Unknown fish (removed!)
			-- SendChatMessage:FireAllClients("General", player.Name, fishName, weight, rarity)

			-- Publish to MessagingService for Global (all servers)
			local messageData = {
				ServerId = SERVER_ID,
				Sender = player.Name,
				FishName = fishName,
				Weight = weight,
				Rarity = rarity
			}

			print("?? [GlobalFish] Publishing to MessagingService for Global channel...")
			local pubSuccess, pubErr = pcall(function()
				MessagingService:PublishAsync(TOPIC_NAME, messageData)
			end)

			if pubSuccess then
				print("? [GlobalFish] Published to MessagingService successfully")

				-- In STUDIO ONLY: Fire Global directly since MessagingService might not relay back
				if RunService:IsStudio() then
					print("?? [GlobalFish] Studio mode: Firing Global directly")
					SendChatMessage:FireAllClients("Global", player.Name, fishName, weight, rarity)
					print("? [GlobalFish] Sent to Global channel (Studio)")
				end
			else
				warn("? [GlobalFish] Failed to publish to MessagingService: " .. tostring(pubErr))

				-- Fallback: Fire Global directly if MessagingService failed
				print("?? [GlobalFish] Fallback: Firing Global directly")
				SendChatMessage:FireAllClients("Global", player.Name, fishName, weight, rarity)
			end
		else
			warn(string.format("?? [GlobalFish] Unknown rarity: %s (not Epic, Legendary, or Unknown)", rarity))
		end
	end)

	listenerSetup = true
	print("? [GlobalFish] Event listener connected")
else
	warn("?? [GlobalFish] Listener already setup! Skipping to prevent duplicates")
end

print("=================================================================")
print("? [GlobalFish] Publisher ready (NO DUPLICATES!)")
print("   Epic ? General only")
print("   Legendary ? General only")
print("   Unknown ? Global only (NO General!)")
print("=================================================================")