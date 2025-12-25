-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- InventoryServer (WITH VIP TOOLS SUPPORT - FINAL)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local CollectionService = game:GetService("CollectionService") -- ?? NEW

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local InventoryEvents = FishingSystem:FindFirstChild("InventoryEvents")
if not InventoryEvents then
	InventoryEvents = Instance.new("Folder")
	InventoryEvents.Name = "InventoryEvents"
	InventoryEvents.Parent = FishingSystem
end

local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local ShowNotification = FishingSystem:WaitForChild("ShowNotification")
local fishFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")
local rodToolFolder = ServerStorage:WaitForChild("AllRods")
local vipToolFolder = ServerStorage:FindFirstChild("VIPtools")

-- ===================================================================
-- VIP CONFIGURATION
-- ===================================================================
local VIP_GAMEPASS_ID = 1590939529 -- ?? REPLACE WITH YOUR ACTUAL VIP GAMEPASS ID

if not vipToolFolder then
	warn("[InventoryServer] VIPtools folder not found in ServerStorage!")
end

local function notify(player, message, duration, color)
	ShowNotification:FireClient(player, message, duration, color or Color3.fromRGB(255, 255, 255))
end

local function formatNumberWithCommas(number)
	local s = tostring(math.floor(number))
	local reversed = string.reverse(s)
	local formatted = reversed:gsub("(%d%d%d)", "%1,")
	return string.reverse(formatted):gsub("^,", "")
end

-- ===================================================================
-- CREATE EVENTS WITH CORRECT TYPES
-- ===================================================================

local reEquipRod = InventoryEvents:FindFirstChild("Inventory_EquipRod")
if not reEquipRod or not reEquipRod:IsA("RemoteEvent") then
	if reEquipRod then reEquipRod:Destroy() end
	reEquipRod = Instance.new("RemoteEvent")
	reEquipRod.Name = "Inventory_EquipRod"
	reEquipRod.Parent = InventoryEvents
end

local reEquipFish = InventoryEvents:FindFirstChild("Inventory_EquipFish")
if not reEquipFish or not reEquipFish:IsA("RemoteEvent") then
	if reEquipFish then reEquipFish:Destroy() end
	reEquipFish = Instance.new("RemoteEvent")
	reEquipFish.Name = "Inventory_EquipFish"
	reEquipFish.Parent = InventoryEvents
end

local reUnequipAll = InventoryEvents:FindFirstChild("Inventory_UnequipAll")
if not reUnequipAll or not reUnequipAll:IsA("RemoteEvent") then
	if reUnequipAll then reUnequipAll:Destroy() end
	reUnequipAll = Instance.new("RemoteEvent")
	reUnequipAll.Name = "Inventory_UnequipAll"
	reUnequipAll.Parent = InventoryEvents
end

local reEquipTool = InventoryEvents:FindFirstChild("Inventory_EquipTool")
if not reEquipTool or not reEquipTool:IsA("RemoteEvent") then
	if reEquipTool then reEquipTool:Destroy() end
	reEquipTool = Instance.new("RemoteEvent")
	reEquipTool.Name = "Inventory_EquipTool"
	reEquipTool.Parent = InventoryEvents
end

local reEquipVIPTool = InventoryEvents:FindFirstChild("Inventory_EquipVIPTool")
if not reEquipVIPTool or not reEquipVIPTool:IsA("RemoteEvent") then
	if reEquipVIPTool then reEquipVIPTool:Destroy() end
	reEquipVIPTool = Instance.new("RemoteEvent")
	reEquipVIPTool.Name = "Inventory_EquipVIPTool"
	reEquipVIPTool.Parent = InventoryEvents
end

local rfGetData = InventoryEvents:FindFirstChild("Inventory_GetData")
if not rfGetData or not rfGetData:IsA("RemoteFunction") then
	if rfGetData then rfGetData:Destroy() end
	rfGetData = Instance.new("RemoteFunction")
	rfGetData.Name = "Inventory_GetData"
	rfGetData.Parent = InventoryEvents
end

local rfToggleFavorite = InventoryEvents:FindFirstChild("Inventory_ToggleFavorite")
if not rfToggleFavorite or not rfToggleFavorite:IsA("RemoteFunction") then
	if rfToggleFavorite then rfToggleFavorite:Destroy() end
	rfToggleFavorite = Instance.new("RemoteFunction")
	rfToggleFavorite.Name = "Inventory_ToggleFavorite"
	rfToggleFavorite.Parent = InventoryEvents
end

local rfSellAll = InventoryEvents:FindFirstChild("Inventory_SellAll")
if not rfSellAll or not rfSellAll:IsA("RemoteFunction") then
	if rfSellAll then rfSellAll:Destroy() end
	rfSellAll = Instance.new("RemoteFunction")
	rfSellAll.Name = "Inventory_SellAll"
	rfSellAll.Parent = InventoryEvents
end

local rfGetVIPTools = InventoryEvents:FindFirstChild("Inventory_GetVIPTools")
if not rfGetVIPTools or not rfGetVIPTools:IsA("RemoteFunction") then
	if rfGetVIPTools then rfGetVIPTools:Destroy() end
	rfGetVIPTools = Instance.new("RemoteFunction")
	rfGetVIPTools.Name = "Inventory_GetVIPTools"
	rfGetVIPTools.Parent = InventoryEvents
end

-- ===================================================================
-- VIP HELPER FUNCTIONS
-- ===================================================================

local function isPlayerVIP(player)
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
	end)

	if success then
		return result
	else
		warn("[InventoryServer] Failed to check VIP status for", player.Name)
		return false
	end
end

-- ===================================================================
-- INVENTORY FUNCTIONS
-- ===================================================================

local function onEquipRod(player, rodName)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	if not GameProfileService:HasRod(player, rodName) then return end

	humanoid:UnequipTools()

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(rodName)

	if not tool then
		local rodTemplate = rodToolFolder:FindFirstChild(rodName)
		if rodTemplate then
			tool = rodTemplate:Clone()
			tool.Parent = backpack
		else
			return
		end
	end

	humanoid:EquipTool(tool)
	GameProfileService:SetLastEquippedRod(player, rodName)
end

local function onEquipTool(player, toolName)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(toolName)

	if tool and tool:IsA("Tool") then
		humanoid:UnequipTools()
		humanoid:EquipTool(tool)
	end
end

-- ?? FIXED: Tag VIP tools when cloning
local function onEquipVIPTool(player, toolName)
	if not isPlayerVIP(player) then
		notify(player, "You need VIP to use this tool!", 3, Color3.fromRGB(255, 100, 100))
		return
	end

	if not vipToolFolder then
		warn("[InventoryServer] VIPtools folder not found!")
		return
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local backpack = player:WaitForChild("Backpack")
	local tool = backpack:FindFirstChild(toolName)

	if not tool then
		local toolTemplate = vipToolFolder:FindFirstChild(toolName)
		if toolTemplate and toolTemplate:IsA("Tool") then
			tool = toolTemplate:Clone()

			-- ?? NEW: Tag as VIP tool so it doesn't appear in normal Tools tab
			CollectionService:AddTag(tool, "VIPTool")

			tool.Parent = backpack
		else
			warn("[InventoryServer] VIP Tool not found:", toolName)
			return
		end
	end

	humanoid:UnequipTools()
	humanoid:EquipTool(tool)
end

local function onEquipFish(player, fishUniqueId)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	humanoid:UnequipTools()

	local backpack = player:WaitForChild("Backpack")
	local toolToEquip = nil
	for _, tool in ipairs(backpack:GetChildren()) do
		local fishId = tool:FindFirstChild("FishId")
		if tool:IsA("Tool") and fishId and fishId.Value == fishUniqueId then
			toolToEquip = tool
			break
		end
	end

	if not toolToEquip then
		local fishData = nil
		local allFish = GameProfileService:GetSavedFish(player)
		for _, fish in ipairs(allFish) do
			if fish.uniqueId == fishUniqueId then fishData = fish break end
		end

		if not fishData then return end
		local fishTemplate = fishFolder:FindFirstChild(fishData.name)
		if not fishTemplate then return end

		toolToEquip = fishTemplate:Clone()
		toolToEquip.ToolTip = " "
		Instance.new("StringValue", toolToEquip).Name = "FishId"
		toolToEquip.FishId.Value = fishData.uniqueId
		Instance.new("NumberValue", toolToEquip).Name = "Weight"
		toolToEquip.Weight.Value = fishData.weight
		Instance.new("StringValue", toolToEquip).Name = "Rarity"
		toolToEquip.Rarity.Value = fishData.rarity
		Instance.new("BoolValue", toolToEquip).Name = "isFavorited"
		toolToEquip.isFavorited.Value = fishData.isFavorited or false
		toolToEquip.Parent = backpack
	end

	humanoid:EquipTool(toolToEquip)
end

local function onUnequipAll(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid:UnequipTools() end
end

local function onGetData(player)
	local fishData = GameProfileService:GetSavedFish(player)
	local rodData = GameProfileService:GetOwnedRods(player)
	local lastRod = GameProfileService:GetLastEquippedRod(player)

	return {
		Fish = fishData,
		Rods = rodData,
		LastRod = lastRod
	}
end

local function onGetVIPTools(player)
	if not isPlayerVIP(player) then
		return {}
	end

	if not vipToolFolder then
		return {}
	end

	local toolList = {}
	for _, tool in ipairs(vipToolFolder:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(toolList, {
				Name = tool.Name,
				TextureId = tool.TextureId
			})
		end
	end

	return toolList
end

local function onToggleFavorite(player, fishUniqueId)
	local newStatus = GameProfileService:ToggleFavoriteFish(player, fishUniqueId)
	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and tool:FindFirstChild("FishId") and tool.FishId.Value == fishUniqueId then
			local favValue = tool:FindFirstChild("isFavorited")
			if favValue then favValue.Value = newStatus end
			break
		end
	end
	return newStatus
end

local function onSellAll(player)
	local allFish = GameProfileService:GetSavedFish(player)
	if #allFish == 0 then
		notify(player, "No fish to sell.", 3, Color3.fromRGB(255, 200, 100))
		return 0, 0
	end

	local totalCoins = 0
	local fishSoldCount = 0
	local fishToRemove_Ids = {}
	local fishToRemove_Tools = {}

	for _, fish in ipairs(allFish) do
		if not fish.isFavorited then
			local price = FishingConfig.CalculateFishPrice(fish.weight, fish.rarity)
			totalCoins = totalCoins + price
			fishSoldCount = fishSoldCount + 1
			table.insert(fishToRemove_Ids, fish.uniqueId)
		end
	end

	if fishSoldCount == 0 then
		notify(player, "No non-favorited fish to sell.", 3, Color3.fromRGB(255, 200, 100))
		return 0, 0
	end

	for _, fishId in ipairs(fishToRemove_Ids) do
		GameProfileService:RemoveFish(player, fishId)
	end

	GameProfileService:AddCoins(player, totalCoins)

	local backpack = player:WaitForChild("Backpack")
	local character = player.Character

	for _, tool in ipairs(backpack:GetChildren()) do
		local fishId = tool:FindFirstChild("FishId")
		if tool:IsA("Tool") and fishId then
			if table.find(fishToRemove_Ids, fishId.Value) then table.insert(fishToRemove_Tools, tool) end
		end
	end

	if character then
		local equippedTool = character:FindFirstChildOfClass("Tool")
		local fishId = equippedTool and equippedTool:FindFirstChild("FishId")
		if fishId and table.find(fishToRemove_Ids, fishId.Value) then
			table.insert(fishToRemove_Tools, equippedTool)
		end
	end

	for _, tool in ipairs(fishToRemove_Tools) do tool:Destroy() end

	local coinsString = formatNumberWithCommas(totalCoins)
	notify(player, string.format("Sold %d fish for %s coins!", fishSoldCount, coinsString), 3, Color3.fromRGB(100, 255, 100))

	return totalCoins, fishSoldCount
end

-- ===================================================================
-- CONNECT EVENTS
-- ===================================================================

reEquipRod.OnServerEvent:Connect(onEquipRod)
reEquipFish.OnServerEvent:Connect(onEquipFish)
reUnequipAll.OnServerEvent:Connect(onUnequipAll)
reEquipTool.OnServerEvent:Connect(onEquipTool)
reEquipVIPTool.OnServerEvent:Connect(onEquipVIPTool)

rfGetData.OnServerInvoke = onGetData
rfToggleFavorite.OnServerInvoke = onToggleFavorite
rfSellAll.OnServerInvoke = onSellAll
rfGetVIPTools.OnServerInvoke = onGetVIPTools