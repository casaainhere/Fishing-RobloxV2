-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ServerScriptService/FishTransferServer
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

-- == MODULES & CONFIGURATION ==
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local DataManager = require(FishingSystem:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local TransferSettings = FishingConfig.TransferSettings

local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")

-- == REMOTE EVENTS ==
local TransferRequest = FishingSystem:WaitForChild("TransferRequest")
local TransferResponse = FishingSystem:WaitForChild("TransferResponse")
local TransferPrompt = FishingSystem:WaitForChild("TransferPrompt")
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")

-- == SERVER STATUS ==
local activeTransfers = {} -- {transferId = {sender, receiver, fishData}}

local TRANSFER_TIMEOUT = 10 -- Seconds (must match client timer)

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

-- Send notification to player
local function notify(player, message, duration, color)
	ShowNotification:FireClient(player, message, duration, color or Color3.fromRGB(255, 255, 255))
end

-- Remove fish tool from sender's inventory (FIXED VERSION)
local function removeFishTool(player, fishId)
	local character = player.Character
	local backpack = player:WaitForChild("Backpack")
	local humanoid = character and character:FindFirstChild("Humanoid")

	-- Check in character (currently equipped)
	if character then
		local tool = character:FindFirstChildOfClass("Tool")
		if tool and tool:FindFirstChild("FishId") and tool.FishId.Value == fishId then
			-- CRITICAL FIX: Unequip the tool first to clear animation
			if humanoid then
				humanoid:UnequipTools()
				task.wait(0.1) -- Give time for animation to clear
			end
			tool:Destroy()
			return true
		end
	end

	-- Check in backpack
	for _, tool in pairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool.FishId.Value == fishId then
			tool:Destroy()
			return true
		end
	end

	return false -- Should not happen if validation is correct
end

-- Give new fish tool to receiver's inventory
-- NOTE: This only creates the physical tool, NOT the data entry
-- The data entry is added separately via DataManager:AddExistingFish()
local function giveFishTool(player, fishData)
	local fishTemplate = fishFolder:FindFirstChild(fishData.name)
	if not fishTemplate then
		warn("[TransferServer] Cannot find fish template: " .. fishData.name)
		return false
	end

	local backpack = player:WaitForChild("Backpack")
	local clonedFish = fishTemplate:Clone()
	clonedFish.ToolTip = " " -- Disable tooltip

	local idValue = Instance.new("StringValue")
	idValue.Name = "FishId"
	idValue.Value = fishData.uniqueId
	idValue.Parent = clonedFish

	local weightValue = Instance.new("NumberValue")
	weightValue.Name = "Weight"
	weightValue.Value = fishData.weight
	weightValue.Parent = clonedFish

	local rarityValue = Instance.new("StringValue")
	rarityValue.Name = "Rarity"
	rarityValue.Value = fishData.rarity
	rarityValue.Parent = clonedFish

	local favoritedValue = Instance.new("BoolValue")
	favoritedValue.Name = "isFavorited"
	favoritedValue.Value = false -- Transfer resets favorite status
	favoritedValue.Parent = clonedFish

	clonedFish.Parent = backpack
	return true
end

-- ===================================================================
-- EVENT CONNECTIONS
-- ===================================================================

-- Step 1: Sender sends request
TransferRequest.OnServerEvent:Connect(function(senderPlayer, targetPlayer, fishId)

	if not TransferSettings.Enabled then
		notify(senderPlayer, "Transfer system is currently disabled.", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- Validation 1: Check Level
	--[[
	local senderLevel = DataManager:GetLevel(senderPlayer)
	if senderLevel < TransferSettings.RequiredLevel then
		notify(senderPlayer, string.format("You must be Level %d to transfer fish.", TransferSettings.RequiredLevel), 3, Color3.fromRGB(255, 100, 100))
		return
	end

	local receiverLevel = DataManager:GetLevel(targetPlayer)
	if receiverLevel < TransferSettings.RequiredLevel then
		notify(senderPlayer, string.format("%s must be Level %d to receive fish.", targetPlayer.Name, TransferSettings.RequiredLevel), 3, Color3.fromRGB(255, 100, 100))
		return
	end
	--]]

	-- Validation 2: Check Distance (additional security)
	local senderChar = senderPlayer.Character
	local receiverChar = targetPlayer.Character
	if not senderChar or not receiverChar or not senderChar:FindFirstChild("HumanoidRootPart") or not receiverChar:FindFirstChild("HumanoidRootPart") then
		return -- One of the players is invalid
	end

	local distance = (senderChar.HumanoidRootPart.Position - receiverChar.HumanoidRootPart.Position).Magnitude
	if distance > TransferSettings.MaxDistance + 5 then -- Give slight tolerance
		notify(senderPlayer, targetPlayer.Name .. " is too far away.", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- Validation 3: Check if sender actually has the fish
	local fishData = nil
	local allFish = DataManager:GetSavedFish(senderPlayer)
	for _, fish in pairs(allFish) do
		if fish.uniqueId == fishId then
			fishData = fish
			break
		end
	end

	if not fishData then
		notify(senderPlayer, "Fish not found in your inventory.", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- INITIAL VALIDATION SUCCESS --

	-- Create unique transfer ID
	local transferId = HttpService:GenerateGUID(false)
	activeTransfers[transferId] = {
		sender = senderPlayer,
		receiver = targetPlayer,
		fishData = fishData
	}

	-- Step 2: Send prompt to receiver
	TransferPrompt:FireClient(targetPlayer, senderPlayer, fishData.name, fishData.weight, transferId)

	-- Remove transfer if timeout
	task.delay(TRANSFER_TIMEOUT, function()
		if activeTransfers[transferId] then
			-- If still exists, receiver did not respond
			notify(senderPlayer, targetPlayer.Name .. " did not respond.", 3, Color3.fromRGB(255, 200, 100))
			activeTransfers[transferId] = nil
		end
	end)
end)


-- Step 3: Receiver responds (Yes/No)
TransferResponse.OnServerEvent:Connect(function(receiverPlayer, transferId, didAccept)

	-- Validation 1: Check if transfer exists
	local transferData = activeTransfers[transferId]
	if not transferData then
		return -- Transfer already expired or invalid
	end

	-- Validation 2: Check if this player is the legitimate receiver
	if transferData.receiver ~= receiverPlayer then
		return -- This player is trying to respond to someone else's transfer
	end

	local senderPlayer = transferData.sender
	local fishData = transferData.fishData

	-- Remove transfer from active list, regardless of response
	activeTransfers[transferId] = nil

	-- CASE 1: RECEIVER DECLINED
	if not didAccept then
		notify(senderPlayer, receiverPlayer.Name .. " declined the transfer.", 3, Color3.fromRGB(255, 200, 100))
		notify(receiverPlayer, "Transfer cancelled.", 3)
		return
	end

	-- CASE 2: RECEIVER ACCEPTED

	-- Validation 3: Check if receiver's inventory is full
	if DataManager:IsInventoryFull(receiverPlayer) then
		notify(senderPlayer, string.format("%s's inventory is full!", receiverPlayer.Name), 3, Color3.fromRGB(255, 100, 100))
		notify(receiverPlayer, "Transfer failed, your inventory is full!", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- Validation 4: Double-check if sender STILL has the fish (important!)
	local success, removedFishData = DataManager:RemoveFish(senderPlayer, fishData.uniqueId)

	if not success or not removedFishData then
		-- Sender may have already sold/transferred this fish
		notify(senderPlayer, "Transfer failed, fish no longer in your inventory.", 3, Color3.fromRGB(255, 100, 100))
		notify(receiverPlayer, "Transfer failed, sender no longer has the fish.", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- Validation 5: Remove fish tool from sender (WITH ANIMATION FIX)
	local toolRemoved = removeFishTool(senderPlayer, fishData.uniqueId)
	if not toolRemoved then
		-- This is weird, data exists but tool doesn't. Return data to sender
		DataManager:AddExistingFish(senderPlayer, removedFishData)
		warn(string.format("[TransferServer] Failed to remove tool %s from %s. Transfer cancelled.", fishData.name, senderPlayer.Name))
		notify(senderPlayer, "Transfer error. Try unequipping and re-equipping the fish.", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- == ALL VALIDATIONS PASSED, PERFORM TRANSFER ==

	-- 1. Add fish data to receiver
	local addedToData = DataManager:AddExistingFish(receiverPlayer, removedFishData)

	if not addedToData then
		-- This should already be checked by IsInventoryFull, but for safety
		-- Return fish to sender
		DataManager:AddExistingFish(senderPlayer, removedFishData)
		giveFishTool(senderPlayer, removedFishData) -- Give tool back

		notify(senderPlayer, string.format("%s's inventory is full! Transfer cancelled.", receiverPlayer.Name), 3, Color3.fromRGB(255, 100, 100))
		notify(receiverPlayer, "Transfer failed, your inventory is full!", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	-- 2. Give new fish tool to receiver
	giveFishTool(receiverPlayer, removedFishData)

	-- 3. Send success notifications to both players
	local successMsg = string.format("Successfully gave %s (%.1fkg) to %s.", fishData.name, fishData.weight, receiverPlayer.Name)
	notify(senderPlayer, successMsg, 3, Color3.fromRGB(100, 255, 100))

	local receivedMsg = string.format("Successfully received %s (%.1fkg) from %s.", fishData.name, fishData.weight, senderPlayer.Name)
	notify(receiverPlayer, receivedMsg, 3, Color3.fromRGB(100, 255, 100))
end)