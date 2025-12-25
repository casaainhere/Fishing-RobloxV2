-- AdminRodGiver - SIMPLE USER ID SYSTEM
-- Auto-give rod berdasarkan User ID
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingModules = FishingSystem:WaitForChild("FishingModules")
local DataManagerModule = require(FishingModules:WaitForChild("DataManager"))

-- ===================================================================
-- ?? CONFIGURATION - GANTI USER ID ANDA DI SINI!
-- ===================================================================
local ADMIN_RODS = {
	-- FORMAT: [UserID] = "Nama Rod"

	-- ?? GANTI USER ID DI BAWAH INI!
	[8840108591] = "Owner Rod",      -- ?? GANTI 0000000000 dengan UserID Anda!

	-- Tambahkan teman/admin lain di sini (opsional):
	-- [111111111] = "Admin Rod",
	-- [222222222] = "Developer Rod",
}

-- ===================================================================
-- DEBUG OUTPUT
-- ===================================================================
print("=" .. string.rep("=", 70))
print("?? [AdminRod] AUTO-GIVE SYSTEM STARTING...")
print("?? [AdminRod] Admin List:")
for userId, rodName in pairs(ADMIN_RODS) do
	print(string.format("   UserID: %d ? %s", userId, rodName))
end
print("=" .. string.rep("=", 70))

-- ===================================================================
-- FUNCTION: GIVE ADMIN ROD
-- ===================================================================
local function giveAdminRod(player)
	print("=" .. string.rep("=", 70))
	print("?? [AdminRod] Player joined:", player.Name)
	print("?? [AdminRod] Player UserID:", player.UserId)

	-- Check if player is in admin list
	local rodName = ADMIN_RODS[player.UserId]

	if not rodName then
		print("?? [AdminRod] Player is not an admin")
		print("=" .. string.rep("=", 70))
		return
	end

	print("? [AdminRod] Player IS admin! Should get:", rodName)

	-- Wait for profile to load
	task.wait(3)
	print("? [AdminRod] Waited 3 seconds for profile...")

	-- Check if already owns
	local hasRod = DataManagerModule:HasRod(player, rodName)
	print("?? [AdminRod] HasRod check:", hasRod)

	if hasRod then
		print("?? [AdminRod] Player already owns:", rodName)
		print("=" .. string.rep("=", 70))
		return
	end

	-- Give rod
	print("?? [AdminRod] Attempting to give rod...")
	local success = DataManagerModule:AddRod(player, rodName)
	print("?? [AdminRod] AddRod result:", success)

	if success then
		print("? [AdminRod] Successfully gave", rodName, "to", player.Name)

		-- Auto-equip
		DataManagerModule:SetLastEquippedRod(player, rodName)
		print("? [AdminRod] Auto-equipped rod")

		-- Notification
		local ShowNotification = FishingSystem:FindFirstChild("ShowNotification")
		if ShowNotification then
			ShowNotification:FireClient(
				player, 
				"?? Admin Rod: " .. rodName .. " equipped!", 
				5, 
				Color3.fromRGB(255, 215, 0)
			)
			print("? [AdminRod] Notification sent")
		end
	else
		warn("? [AdminRod] FAILED to give rod! Check DataManager/FishData!")
	end

	print("=" .. string.rep("=", 70))
end

-- ===================================================================
-- PLAYER JOINED EVENT
-- ===================================================================
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		giveAdminRod(player)
	end)
end)

-- Give to existing players (for testing in Studio)
for _, player in pairs(Players:GetPlayers()) do
	task.spawn(function()
		giveAdminRod(player)
	end)
end

print("? [AdminRod] Script loaded and ready!")