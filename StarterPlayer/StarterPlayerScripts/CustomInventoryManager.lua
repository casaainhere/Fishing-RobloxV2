--[[
	System by @thehandofvoid
	Modified by @jay_peaceee
	CustomInventoryManager (Client) - WITH VIP TOOLS TAB (FINAL FIX)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local StarterPack = game:GetService("StarterPack")


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


-- ===================================================================
-- SOUND SETTINGS
-- ===================================================================
local CLICK_SOUND_ID = "rbxassetid://340910329"
local CLICK_VOLUME = 0.5

local function playClickSound()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = CLICK_VOLUME
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ===================================================================
-- MODULES & EVENTS
-- ===================================================================
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local RarityColors = FishingConfig.RarityColors

local InventoryEvents = FishingSystem:WaitForChild("InventoryEvents")
local rfGetData = InventoryEvents:WaitForChild("Inventory_GetData")
local rfToggleFavorite = InventoryEvents:WaitForChild("Inventory_ToggleFavorite")
local rfSellAll = InventoryEvents:WaitForChild("Inventory_SellAll")
local reEquipRod = InventoryEvents:WaitForChild("Inventory_EquipRod")
local reEquipFish = InventoryEvents:WaitForChild("Inventory_EquipFish")
local reUnequipAll = InventoryEvents:WaitForChild("Inventory_UnequipAll")
local reEquipTool = InventoryEvents:WaitForChild("Inventory_EquipTool")
local reEquipVIPTool = InventoryEvents:WaitForChild("Inventory_EquipVIPTool")
local rfGetVIPTools = InventoryEvents:WaitForChild("Inventory_GetVIPTools")
local GlobalLuckVal = FishingSystem:WaitForChild("GlobalLuckMultiplier")

local fishAssetFolder = FishingSystem:WaitForChild("Assets"):WaitForChild("Fish")

-- ===================================================================
-- VIP CONFIGURATION
-- ===================================================================
local VIP_GAMEPASS_ID = 1590939529 -- ?? REPLACE WITH YOUR ACTUAL VIP GAMEPASS ID
local isVIP = false

-- ===================================================================
-- GUI REFERENCE + ORIGINAL COLORS
-- ===================================================================
local gui = nil
local Hotbar = {}
local Inventory = {}
local Templates = {}

local OriginalColors = {
	RodSlot = {},
	FishSlot = {},
	ToolSlot = {},
	ToolSlot2 = {}
}

local function updateGUIReferences()
	local attempts = 0
	while attempts < 50 do
		gui = playerGui:FindFirstChild("CustomInventoryGui")
		if gui then break end
		attempts = attempts + 1
		task.wait(0.1)
	end

	if not gui then
		warn("[CustomInventory] Failed to find CustomInventoryGui!")
		return false
	end

	Hotbar.Frame = gui:FindFirstChild("HotbarFrame")
	if not Hotbar.Frame then
		warn("[CustomInventory] HotbarFrame not found!")
		return false
	end

	Hotbar.RodSlot = Hotbar.Frame:FindFirstChild("RodSlot")
	Hotbar.RodImage = Hotbar.RodSlot and Hotbar.RodSlot:FindFirstChild("RodImage")
	Hotbar.RodName = Hotbar.RodSlot and Hotbar.RodSlot:FindFirstChild("RodName")
	Hotbar.FishSlot = Hotbar.Frame:FindFirstChild("FishSlot")
	Hotbar.FishImage = Hotbar.FishSlot and Hotbar.FishSlot:FindFirstChild("FishImage")
	Hotbar.FishName = Hotbar.FishSlot and Hotbar.FishSlot:FindFirstChild("FishName")
	Hotbar.ToolSlot = Hotbar.Frame:FindFirstChild("ToolSlot")
	Hotbar.ToolImage = Hotbar.ToolSlot and Hotbar.ToolSlot:FindFirstChild("ToolImage")
	Hotbar.ToolName = Hotbar.ToolSlot and Hotbar.ToolSlot:FindFirstChild("ToolName")
	Hotbar.ToolSlot2 = Hotbar.Frame:FindFirstChild("ToolSlot2")
	Hotbar.ToolImage2 = Hotbar.ToolSlot2 and Hotbar.ToolSlot2:FindFirstChild("ToolImage")
	Hotbar.ToolName2 = Hotbar.ToolSlot2 and Hotbar.ToolSlot2:FindFirstChild("ToolName")
	Hotbar.BagButton = Hotbar.Frame:FindFirstChild("BagButton")

	if Hotbar.RodSlot then
		OriginalColors.RodSlot.Background = Hotbar.RodSlot.BackgroundColor3
		OriginalColors.RodSlot.Transparency = Hotbar.RodSlot.BackgroundTransparency
		OriginalColors.RodSlot.ImageTransparency = Hotbar.RodImage and Hotbar.RodImage.ImageTransparency or 0
		OriginalColors.RodSlot.TextTransparency = Hotbar.RodName and Hotbar.RodName.TextTransparency or 0
		OriginalColors.RodSlot.TextColor = Hotbar.RodName and Hotbar.RodName.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.FishSlot then
		OriginalColors.FishSlot.Background = Hotbar.FishSlot.BackgroundColor3
		OriginalColors.FishSlot.Transparency = Hotbar.FishSlot.BackgroundTransparency
		OriginalColors.FishSlot.ImageTransparency = Hotbar.FishImage and Hotbar.FishImage.ImageTransparency or 0
		OriginalColors.FishSlot.TextTransparency = Hotbar.FishName and Hotbar.FishName.TextTransparency or 0
		OriginalColors.FishSlot.TextColor = Hotbar.FishName and Hotbar.FishName.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.ToolSlot then
		OriginalColors.ToolSlot.Background = Hotbar.ToolSlot.BackgroundColor3
		OriginalColors.ToolSlot.Transparency = Hotbar.ToolSlot.BackgroundTransparency
		OriginalColors.ToolSlot.ImageTransparency = Hotbar.ToolImage and Hotbar.ToolImage.ImageTransparency or 0
		OriginalColors.ToolSlot.TextTransparency = Hotbar.ToolName and Hotbar.ToolName.TextTransparency or 0
		OriginalColors.ToolSlot.TextColor = Hotbar.ToolName and Hotbar.ToolName.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	if Hotbar.ToolSlot2 then
		OriginalColors.ToolSlot2.Background = Hotbar.ToolSlot2.BackgroundColor3
		OriginalColors.ToolSlot2.Transparency = Hotbar.ToolSlot2.BackgroundTransparency
		OriginalColors.ToolSlot2.ImageTransparency = Hotbar.ToolImage2 and Hotbar.ToolImage2.ImageTransparency or 0
		OriginalColors.ToolSlot2.TextTransparency = Hotbar.ToolName2 and Hotbar.ToolName2.TextTransparency or 0
		OriginalColors.ToolSlot2.TextColor = Hotbar.ToolName2 and Hotbar.ToolName2.TextColor3 or Color3.fromRGB(255, 255, 255)
	end

	local mainFrame = gui:FindFirstChild("MainInventoryFrame")
	if not mainFrame then
		warn("[CustomInventory] MainInventoryFrame not found!")
		return false
	end

	Inventory.Frame = mainFrame
	Inventory.CloseButton = mainFrame.Header and mainFrame.Header:FindFirstChild("CloseButton")
	Inventory.FishTabButton = mainFrame.TabsFrame and mainFrame.TabsFrame:FindFirstChild("FishTabButton")
	Inventory.RodTabButton = mainFrame.TabsFrame and mainFrame.TabsFrame:FindFirstChild("RodTabButton")
	Inventory.ToolTabButton = mainFrame.TabsFrame and mainFrame.TabsFrame:FindFirstChild("ToolTabButton")
	Inventory.VIPTabButton = mainFrame.TabsFrame and mainFrame.TabsFrame:FindFirstChild("VIPTabButton")
	Inventory.FishContent = mainFrame.ContentFrame and mainFrame.ContentFrame:FindFirstChild("FishContent")
	Inventory.RodContent = mainFrame.ContentFrame and mainFrame.ContentFrame:FindFirstChild("RodContent")
	Inventory.ToolContent = mainFrame.ContentFrame and mainFrame.ContentFrame:FindFirstChild("ToolContent")
	Inventory.VIPContent = mainFrame.ContentFrame and mainFrame.ContentFrame:FindFirstChild("VIPContent")
	Inventory.SellAllButton = mainFrame.Footer and mainFrame.Footer:FindFirstChild("SellAllButton")
	Inventory.FishCountLabel = mainFrame.Footer and mainFrame.Footer:FindFirstChild("FishCountLabel")

	local templatesFolder = gui:FindFirstChild("Templates")
	if templatesFolder then
		Templates.Fish = templatesFolder:FindFirstChild("FishTemplate")
		Templates.Tool = templatesFolder:FindFirstChild("ToolTemplate")
		Templates.Rod = templatesFolder:FindFirstChild("RodTemplate")
		Templates.VIPTool = templatesFolder:FindFirstChild("VIPToolTemplate")
	end

	Hotbar.Frame.Visible = true
	return true
end

updateGUIReferences()

-- ===================================================================
-- STATE VARIABLES
-- ===================================================================
local isInventoryOpen = false
local currentTab = "Fish"
local lastOpenedTab = "Fish"
local allFishData = {}
local allRodData = {}
local rodToolStats = {}

local lastEquippedRodName = nil
local lastEquippedFishId = nil
local lastEquippedToolName = nil
local lastEquippedToolName2 = nil

local connections = {}

-- ===================================================================
-- HOTBAR STATE PERSISTENCE
-- ===================================================================
local HotbarState = {
	rod = nil,
	fish = nil,
	tool1 = nil,
	tool2 = nil
}

local function saveHotbarState()
	HotbarState.rod = lastEquippedRodName
	HotbarState.fish = lastEquippedFishId
	HotbarState.tool1 = lastEquippedToolName
	HotbarState.tool2 = lastEquippedToolName2
end

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================

local function updateFishCount()
	if Inventory.FishCountLabel then
		local fishCount = #allFishData
		local maxFish = FishingConfig.InventoryLimitSettings.maxFishInventory or 500
		Inventory.FishCountLabel.Text = string.format("Fish: %d/%d", fishCount, maxFish)
	end
end

local function getRarityColor(rarity)
	return RarityColors[rarity] or Color3.fromRGB(255, 255, 255)
end

local function updateRodVisual(rodName)
	if not rodName then
		Hotbar.RodImage.Image = ""
		Hotbar.RodName.Text = "Rod"
		Hotbar.RodName.TextColor3 = OriginalColors.RodSlot.TextColor
		Hotbar.RodSlot.BackgroundColor3 = OriginalColors.RodSlot.Background
		Hotbar.RodSlot.BackgroundTransparency = OriginalColors.RodSlot.Transparency
		Hotbar.RodImage.ImageTransparency = OriginalColors.RodSlot.ImageTransparency
		Hotbar.RodName.TextTransparency = OriginalColors.RodSlot.TextTransparency
		return
	end

	local stats = FishingConfig.GetRodConfig(rodName)
	local textureId = ""

	if rodToolStats[rodName] and rodToolStats[rodName].TextureId then
		textureId = rodToolStats[rodName].TextureId
	else
		local tool = player.Backpack:FindFirstChild(rodName) or (player.Character and player.Character:FindFirstChild(rodName))
		if tool then textureId = tool.TextureId end
	end

	if textureId ~= "" and not textureId:match("rbxassetid") then
		textureId = "rbxassetid://" .. textureId
	end

	Hotbar.RodImage.Image = textureId
	Hotbar.RodName.Text = ""

	local char = player.Character
	local isHolding = char and char:FindFirstChild(rodName)

	if isHolding then
		Hotbar.RodSlot.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
		Hotbar.RodSlot.BackgroundTransparency = 0.7
		Hotbar.RodImage.ImageTransparency = 0
		Hotbar.RodName.TextTransparency = 0
	else
		Hotbar.RodSlot.BackgroundColor3 = OriginalColors.RodSlot.Background
		Hotbar.RodSlot.BackgroundTransparency = OriginalColors.RodSlot.Transparency
		Hotbar.RodImage.ImageTransparency = OriginalColors.RodSlot.ImageTransparency
		Hotbar.RodName.TextTransparency = OriginalColors.RodSlot.TextTransparency
	end
end

local function updateFishVisual(fishId)
	if not fishId then
		Hotbar.FishImage.Image = ""
		Hotbar.FishName.Text = "Fish"
		Hotbar.FishName.TextColor3 = OriginalColors.FishSlot.TextColor
		Hotbar.FishSlot.BackgroundColor3 = OriginalColors.FishSlot.Background
		Hotbar.FishSlot.BackgroundTransparency = OriginalColors.FishSlot.Transparency
		Hotbar.FishImage.ImageTransparency = OriginalColors.FishSlot.ImageTransparency
		Hotbar.FishName.TextTransparency = OriginalColors.FishSlot.TextTransparency
		return
	end

	local fishData = nil
	for _, f in ipairs(allFishData) do
		if f.uniqueId == fishId then 
			fishData = f 
			break 
		end
	end

	if fishData then
		local fishTemplate = fishAssetFolder:FindFirstChild(fishData.name)
		local textureId = ""

		if fishTemplate and fishTemplate.TextureId ~= "" then
			textureId = tostring(fishTemplate.TextureId)
			if textureId:sub(1, 13) ~= "rbxassetid://" then
				textureId = "rbxassetid://" .. textureId
			end
		end

		Hotbar.FishImage.Image = textureId
		Hotbar.FishName.Text = ""
	else
		Hotbar.FishImage.Image = ""
		Hotbar.FishName.Text = ""
	end

	local char = player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisFish = false

	if currentTool and currentTool:FindFirstChild("FishId") and currentTool.FishId.Value == fishId then
		isHoldingThisFish = true
	end

	if isHoldingThisFish then
		Hotbar.FishSlot.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
		Hotbar.FishSlot.BackgroundTransparency = 0.5
		Hotbar.FishImage.ImageTransparency = 0
		Hotbar.FishName.TextTransparency = 0
	else
		Hotbar.FishSlot.BackgroundColor3 = OriginalColors.FishSlot.Background
		Hotbar.FishSlot.BackgroundTransparency = OriginalColors.FishSlot.Transparency
		Hotbar.FishImage.ImageTransparency = OriginalColors.FishSlot.ImageTransparency
		Hotbar.FishName.TextTransparency = OriginalColors.FishSlot.TextTransparency
	end
end

local function updateToolVisual(toolName)
	if not toolName then
		Hotbar.ToolImage.Image = ""
		Hotbar.ToolName.Text = "Tool"
		Hotbar.ToolName.TextColor3 = OriginalColors.ToolSlot.TextColor
		Hotbar.ToolSlot.BackgroundColor3 = OriginalColors.ToolSlot.Background
		Hotbar.ToolSlot.BackgroundTransparency = OriginalColors.ToolSlot.Transparency
		Hotbar.ToolImage.ImageTransparency = OriginalColors.ToolSlot.ImageTransparency
		Hotbar.ToolName.TextTransparency = OriginalColors.ToolSlot.TextTransparency
		return
	end

	local tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
	local textureId = ""
	if tool then
		textureId = tool.TextureId
	end

	Hotbar.ToolImage.Image = textureId
	Hotbar.ToolName.Text = ""

	local char = player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisTool = false

	if currentTool and currentTool.Name == toolName and not currentTool:FindFirstChild("FishId") and not CollectionService:HasTag(currentTool, "Rod") then
		isHoldingThisTool = true
	end

	if isHoldingThisTool then
		Hotbar.ToolSlot.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
		Hotbar.ToolSlot.BackgroundTransparency = 0.7
		Hotbar.ToolImage.ImageTransparency = 0
		Hotbar.ToolName.TextTransparency = 0
	else
		Hotbar.ToolSlot.BackgroundColor3 = OriginalColors.ToolSlot.Background
		Hotbar.ToolSlot.BackgroundTransparency = OriginalColors.ToolSlot.Transparency
		Hotbar.ToolImage.ImageTransparency = OriginalColors.ToolSlot.ImageTransparency
		Hotbar.ToolName.TextTransparency = OriginalColors.ToolSlot.TextTransparency
	end
end

local function updateToolVisual2(toolName)
	if not toolName then
		Hotbar.ToolImage2.Image = ""
		Hotbar.ToolName2.Text = "Tool"
		Hotbar.ToolName2.TextColor3 = OriginalColors.ToolSlot2.TextColor
		Hotbar.ToolSlot2.BackgroundColor3 = OriginalColors.ToolSlot2.Background
		Hotbar.ToolSlot2.BackgroundTransparency = OriginalColors.ToolSlot2.Transparency
		Hotbar.ToolImage2.ImageTransparency = OriginalColors.ToolSlot2.ImageTransparency
		Hotbar.ToolName2.TextTransparency = OriginalColors.ToolSlot2.TextTransparency
		return
	end

	local tool = player.Backpack:FindFirstChild(toolName) or (player.Character and player.Character:FindFirstChild(toolName))
	local textureId = ""
	if tool then
		textureId = tool.TextureId
	end

	Hotbar.ToolImage2.Image = textureId
	Hotbar.ToolName2.Text = ""

	local char = player.Character
	local currentTool = char and char:FindFirstChildOfClass("Tool")
	local isHoldingThisTool = false

	if currentTool and currentTool.Name == toolName and not currentTool:FindFirstChild("FishId") and not CollectionService:HasTag(currentTool, "Rod") then
		isHoldingThisTool = true
	end

	if isHoldingThisTool then
		Hotbar.ToolSlot2.BackgroundColor3 = Color3.fromRGB(118, 118, 118)
		Hotbar.ToolSlot2.BackgroundTransparency = 0.7
		Hotbar.ToolImage2.ImageTransparency = 0
		Hotbar.ToolName2.TextTransparency = 0
	else
		Hotbar.ToolSlot2.BackgroundColor3 = OriginalColors.ToolSlot2.Background
		Hotbar.ToolSlot2.BackgroundTransparency = OriginalColors.ToolSlot2.Transparency
		Hotbar.ToolImage2.ImageTransparency = OriginalColors.ToolSlot2.ImageTransparency
		Hotbar.ToolName2.TextTransparency = OriginalColors.ToolSlot2.TextTransparency
	end
end

-- ===================================================================
-- STATE MANAGEMENT FUNCTIONS
-- ===================================================================

local function restoreHotbarState()
	lastEquippedRodName = HotbarState.rod
	lastEquippedFishId = HotbarState.fish
	lastEquippedToolName = HotbarState.tool1
	lastEquippedToolName2 = HotbarState.tool2

	updateRodVisual(lastEquippedRodName)
	updateFishVisual(lastEquippedFishId)
	updateToolVisual(lastEquippedToolName)
	updateToolVisual2(lastEquippedToolName2)
end

local function validateHotbarItems()
	local backpack = player:FindFirstChild("Backpack")
	if not backpack then return end

	if lastEquippedRodName then
		local rodExists = backpack:FindFirstChild(lastEquippedRodName) or 
			(player.Character and player.Character:FindFirstChild(lastEquippedRodName))
		if not rodExists then
			local hasRod = false
			for _, rodName in ipairs(allRodData) do
				if rodName == lastEquippedRodName then
					hasRod = true
					break
				end
			end
			if not hasRod then
				lastEquippedRodName = nil
				updateRodVisual(nil)
			end
		end
	end

	if lastEquippedFishId then
		local fishExists = false
		for _, fishData in ipairs(allFishData) do
			if fishData.uniqueId == lastEquippedFishId then
				fishExists = true
				break
			end
		end
		if not fishExists then
			lastEquippedFishId = nil
			updateFishVisual(nil)
			saveHotbarState()
		end
	end

	-- ?? FIX: Validate Tool 1 (check if it's VIP tool)
	if lastEquippedToolName then
		local tool1Exists = backpack:FindFirstChild(lastEquippedToolName) or 
			(player.Character and player.Character:FindFirstChild(lastEquippedToolName))

		if not tool1Exists then
			local success, vipToolsList = pcall(function()
				return rfGetVIPTools:InvokeServer()
			end)

			local isVIPTool = false
			if success and vipToolsList then
				for _, toolData in ipairs(vipToolsList) do
					if toolData.Name == lastEquippedToolName then
						isVIPTool = true
						break
					end
				end
			end

			if not isVIPTool then
				lastEquippedToolName = nil
				updateToolVisual(nil)
			end
		end
	end

	-- ?? FIX: Validate Tool 2 (check if it's VIP tool)
	if lastEquippedToolName2 then
		local tool2Exists = backpack:FindFirstChild(lastEquippedToolName2) or 
			(player.Character and player.Character:FindFirstChild(lastEquippedToolName2))

		if not tool2Exists then
			local success, vipToolsList = pcall(function()
				return rfGetVIPTools:InvokeServer()
			end)

			local isVIPTool = false
			if success and vipToolsList then
				for _, toolData in ipairs(vipToolsList) do
					if toolData.Name == lastEquippedToolName2 then
						isVIPTool = true
						break
					end
				end
			end

			if not isVIPTool then
				lastEquippedToolName2 = nil
				updateToolVisual2(nil)
			end
		end
	end
end

local function autoFillHotbarSlots()
	validateHotbarItems()
end

-- ===================================================================
-- VIP STATUS CHECK
-- ===================================================================
local function checkVIPStatus()
	local MarketplaceService = game:GetService("MarketplaceService")

	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
	end)

	if success then
		isVIP = result
	else
		isVIP = false
	end

	if Inventory.VIPTabButton then
		Inventory.VIPTabButton.Visible = isVIP
	end

	return isVIP
end

-- ===================================================================
-- FORWARD DECLARATIONS
-- ===================================================================
local toggleInventory

-- ===================================================================
-- LOGIC FUNCTIONS
-- ===================================================================

local function populateFishGrid()
	for _, child in ipairs(Inventory.FishContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local rarityOrder = {
		Unknown = 7,
		Legendary = 6,
		Mythical = 5,
		Epic = 4,
		Rare = 3,
		Uncommon = 2,
		Common = 1
	}

	table.sort(allFishData, function(a, b)
		if a.isFavorited ~= b.isFavorited then return a.isFavorited end

		local rarityA = rarityOrder[a.rarity] or 0
		local rarityB = rarityOrder[b.rarity] or 0
		if rarityA ~= rarityB then return rarityA > rarityB end

		return a.weight > b.weight
	end)

	for _, fishData in ipairs(allFishData) do
		local card = Templates.Fish:Clone()
		card.Name = fishData.uniqueId
		card.Visible = true

		local fishImage = card:FindFirstChild("FishImage")
		local fishName = card:FindFirstChild("FishName")
		local fishWeight = card:FindFirstChild("FishWeight")
		local fishRarity = card:FindFirstChild("FishRarity")
		local favoriteButton = card:FindFirstChild("FavoriteButton")

		if not fishImage or not fishName or not fishWeight or not fishRarity or not favoriteButton then
			card:Destroy()
			continue
		end

		local fishTemplate = fishAssetFolder:FindFirstChild(fishData.name)
		if fishTemplate and fishTemplate.TextureId ~= "" then
			local textureIdString = tostring(fishTemplate.TextureId)
			if textureIdString:sub(1, 13) == "rbxassetid://" then
				fishImage.Image = textureIdString
			else
				fishImage.Image = "rbxassetid://" .. textureIdString
			end
		else
			fishImage.Image = ""
		end

		fishName.Text = fishData.name
		fishWeight.Text = string.format("%.1fkg", fishData.weight)
		fishRarity.Text = fishData.rarity
		fishRarity.TextColor3 = getRarityColor(fishData.rarity)

		if fishData.isFavorited then
			favoriteButton.Text = "?"
			favoriteButton.TextColor3 = Color3.fromRGB(255, 220, 0)
		else
			favoriteButton.Text = "?"
			favoriteButton.TextColor3 = Color3.fromRGB(150, 150, 150)
		end

		favoriteButton.MouseButton1Click:Connect(function()
			playClickSound()
			local newStatus = rfToggleFavorite:InvokeServer(fishData.uniqueId)
			if newStatus ~= nil then
				fishData.isFavorited = newStatus
				if newStatus then
					favoriteButton.Text = "?"
					favoriteButton.TextColor3 = Color3.fromRGB(255, 220, 0)
				else
					favoriteButton.Text = "?"
					favoriteButton.TextColor3 = Color3.fromRGB(150, 150, 150)
				end
			end
		end)

		fishImage.MouseButton1Click:Connect(function()
			playClickSound()
			lastEquippedFishId = fishData.uniqueId
			saveHotbarState()
			updateFishVisual(fishData.uniqueId)
		end)

		card.Parent = Inventory.FishContent
	end

	updateFishCount()
end

local function populateRodGrid()
	for _, child in ipairs(Inventory.RodContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	-- Ambil Luck Multiplier saat ini
	local currentMultiplier = GlobalLuckVal.Value or 1

	table.sort(allRodData, function(a, b)
		local statsA = rodToolStats[a] and rodToolStats[a].Stats or FishingConfig.GetRodConfig(a)
		local statsB = rodToolStats[b] and rodToolStats[b].Stats or FishingConfig.GetRodConfig(b)
		local luckA = statsA.baseLuck or 0
		local luckB = statsB.baseLuck or 0
		return luckA > luckB
	end)

	for _, rodName in ipairs(allRodData) do
		local card = Templates.Rod:Clone()
		card.Name = rodName
		card.Visible = true

		local rodNameLabel = card:FindFirstChild("RodName")
		local rodImage = card:FindFirstChild("RodImage")
		local statsLabel = card:FindFirstChild("StatsLabel")
		local equipButton = card:FindFirstChild("EquipButton")

		if not rodNameLabel or not rodImage or not statsLabel or not equipButton then
			card:Destroy()
			continue
		end

		local cachedData = rodToolStats[rodName]
		local stats = cachedData and cachedData.Stats or FishingConfig.GetRodConfig(rodName)
		local textureId = cachedData and cachedData.TextureId or ""

		if textureId ~= "" and not textureId:match("rbxassetid") then
			textureId = "rbxassetid://" .. textureId
		end

		rodNameLabel.Text = rodName
		rodImage.Image = textureId

		-- UPDATE LOGIKA LUCK DI SINI
		local baseLuck = stats.baseLuck or 1.0
		local finalLuck = baseLuck * currentMultiplier

		local weight = stats.maxWeight or 0

		-- Format Teks (Jika boost aktif, warnai hijau)
		if currentMultiplier > 1 then
			statsLabel.RichText = true
			statsLabel.Text = string.format("Luck: <font color='#00FF00'><b>%.1fx</b></font>\nWeight: %dkg", finalLuck, weight)
		else
			statsLabel.RichText = false
			statsLabel.Text = string.format("Luck: %.1fx\nWeight: %dkg", finalLuck, weight)
		end

		equipButton.MouseButton1Click:Connect(function()
			playClickSound()
			lastEquippedRodName = rodName
			saveHotbarState()
			updateRodVisual(rodName)
		end)

		card.Parent = Inventory.RodContent
	end
end

local function populateToolGrid()
	for _, child in ipairs(Inventory.ToolContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local genericTools = {}
	local addedTools = {}

	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(tool, "Rod")
		local isVIPTool = CollectionService:HasTag(tool, "VIPTool") -- ?? NEW

		-- ?? FIX: Exclude VIP tools from normal Tools tab
		if not isFish and not isRod and not isVIPTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	for _, tool in ipairs(StarterPack:GetChildren()) do
		if not tool:IsA("Tool") then continue end

		local isFish = tool:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(tool, "Rod")
		local isVIPTool = CollectionService:HasTag(tool, "VIPTool") -- ?? NEW

		-- ?? FIX: Exclude VIP tools from normal Tools tab
		if not isFish and not isRod and not isVIPTool and not addedTools[tool.Name] then
			table.insert(genericTools, tool)
			addedTools[tool.Name] = true
		end
	end

	table.sort(genericTools, function(a, b)
		return a.Name < b.Name
	end)

	for _, tool in ipairs(genericTools) do
		local card = Templates.Tool:Clone()
		card.Name = tool.Name
		card.Visible = true

		local toolImage = card:FindFirstChild("ToolImage")
		local toolNameLabel = card:FindFirstChild("ToolName")

		if not toolImage or not toolNameLabel then
			card:Destroy()
			continue
		end

		toolImage.Image = tool.TextureId
		toolNameLabel.Text = tool.Name

		toolImage.MouseButton1Click:Connect(function()
			playClickSound()

			if not lastEquippedToolName then
				lastEquippedToolName = tool.Name
				updateToolVisual(tool.Name)
			elseif not lastEquippedToolName2 then
				lastEquippedToolName2 = tool.Name
				updateToolVisual2(tool.Name)
			elseif lastEquippedToolName == tool.Name or lastEquippedToolName2 == tool.Name then
				if lastEquippedToolName == tool.Name then
					updateToolVisual(tool.Name)
				else
					updateToolVisual2(tool.Name)
				end
			else
				lastEquippedToolName = tool.Name
				updateToolVisual(tool.Name)
				updateToolVisual2(lastEquippedToolName2)
			end

			saveHotbarState()
		end)

		card.Parent = Inventory.ToolContent
	end
end

-- ===================================================================
-- VIP TOOLS POPULATION (FIXED - SHOW SERVER TOOLS + BACKPACK VIP TOOLS)
-- ===================================================================
local function populateVIPToolGrid()
	if not isVIP then return end
	if not Inventory.VIPContent then return end
	if not Templates.VIPTool then
		warn("[CustomInventory] VIPToolTemplate not found!")
		return
	end

	for _, child in ipairs(Inventory.VIPContent:GetChildren()) do
		if child:IsA("Frame") or child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local vipTools = {}
	local addedTools = {}

	local success, vipToolsList = pcall(function()
		return rfGetVIPTools:InvokeServer()
	end)

	if success and vipToolsList then
		for _, toolData in ipairs(vipToolsList) do
			if not addedTools[toolData.Name] then
				table.insert(vipTools, {
					Name = toolData.Name,
					TextureId = toolData.TextureId
				})
				addedTools[toolData.Name] = true
			end
		end
	end

	-- ?? NEW: Also check backpack for already-cloned VIP tools
	local backpack = player:WaitForChild("Backpack")
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") and CollectionService:HasTag(tool, "VIPTool") then
			if not addedTools[tool.Name] then
				table.insert(vipTools, {
					Name = tool.Name,
					TextureId = tool.TextureId
				})
				addedTools[tool.Name] = true
			end
		end
	end

	table.sort(vipTools, function(a, b)
		return a.Name < b.Name
	end)

	for _, toolData in ipairs(vipTools) do
		local card = Templates.VIPTool:Clone()
		card.Name = toolData.Name
		card.Visible = true

		local toolImage = card:FindFirstChild("ToolImage")
		local toolNameLabel = card:FindFirstChild("ToolName")
		local vipBadge = card:FindFirstChild("VIPBadge")

		if not toolImage or not toolNameLabel then
			card:Destroy()
			continue
		end

		toolImage.Image = toolData.TextureId or ""
		toolNameLabel.Text = toolData.Name

		if vipBadge then
			vipBadge.Text = "? VIP"
			vipBadge.TextColor3 = Color3.fromRGB(255, 215, 0)
		end

		toolImage.MouseButton1Click:Connect(function()
			playClickSound()

			if not lastEquippedToolName then
				lastEquippedToolName = toolData.Name
				updateToolVisual(toolData.Name)
			elseif not lastEquippedToolName2 then
				lastEquippedToolName2 = toolData.Name
				updateToolVisual2(toolData.Name)
			elseif lastEquippedToolName == toolData.Name or lastEquippedToolName2 == toolData.Name then
				if lastEquippedToolName == toolData.Name then
					updateToolVisual(toolData.Name)
				else
					updateToolVisual2(toolData.Name)
				end
			else
				lastEquippedToolName = toolData.Name
				updateToolVisual(toolData.Name)
				updateToolVisual2(lastEquippedToolName2)
			end

			saveHotbarState()
		end)

		card.Parent = Inventory.VIPContent
	end
end

local isRefreshing = false

local function refreshAllData()
	if isRefreshing then return end
	isRefreshing = true

	local success, fullData = pcall(function()
		return rfGetData:InvokeServer()
	end)

	if not success or not fullData then 
		isRefreshing = false
		return 
	end

	allFishData = fullData.Fish or {}
	allRodData = fullData.Rods or {}

	if next(rodToolStats) == nil then
		local rodShopEvents = FishingSystem:FindFirstChild("RodShopEvents")
		if rodShopEvents then
			local rfGetShopData = rodShopEvents:FindFirstChild("GetShopData")
			if rfGetShopData then
				local success2, shopData = pcall(function()
					return rfGetShopData:InvokeServer()
				end)

				if success2 and shopData and shopData.AllRodData then
					for rodName, data in pairs(shopData.AllRodData) do
						rodToolStats[rodName] = {
							Stats = data.Stats, 
							TextureId = data.TextureId
						}
					end
				end
			end
		end
	end

	validateHotbarItems()

	if currentTab == "Fish" then 
		populateFishGrid()
	elseif currentTab == "Rods" then 
		populateRodGrid()
	elseif currentTab == "Tools" then 
		populateToolGrid()
	elseif currentTab == "VIP" and isVIP then
		populateVIPToolGrid()
	end

	updateFishCount()

	isRefreshing = false
end

local function switchTab(tabName)
	lastOpenedTab = tabName
	currentTab = tabName

	Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	if Inventory.VIPTabButton then
		Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
	end

	Inventory.FishContent.Visible = false
	Inventory.RodContent.Visible = false
	Inventory.ToolContent.Visible = false
	if Inventory.VIPContent then
		Inventory.VIPContent.Visible = false
	end
	Inventory.SellAllButton.Visible = false

	if tabName == "Fish" then
		Inventory.FishTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.FishContent.Visible = true
		Inventory.SellAllButton.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = true
		end
		populateFishGrid()
	elseif tabName == "Rods" then
		Inventory.RodTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.RodContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateRodGrid()
	elseif tabName == "Tools" then
		Inventory.ToolTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.ToolContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateToolGrid()
	elseif tabName == "VIP" and isVIP then
		Inventory.VIPTabButton.BackgroundColor3 = Color3.fromRGB(106, 106, 106)
		Inventory.VIPContent.Visible = true
		if Inventory.FishCountLabel then
			Inventory.FishCountLabel.Visible = false
		end
		populateVIPToolGrid()
	end
end

toggleInventory = function(visible)
	if visible == isInventoryOpen then return end

	isInventoryOpen = visible
	Inventory.Frame.Visible = visible

	if visible then
		refreshAllData()
		switchTab(lastOpenedTab)
	end
end

local function onToolChanged(tool)
	if tool and tool:IsA("Tool") and CollectionService:HasTag(tool, "Rod") then
		lastEquippedRodName = tool.Name
		saveHotbarState()
		updateRodVisual(tool.Name)
		updateFishVisual(lastEquippedFishId)
		updateToolVisual(lastEquippedToolName)
		updateToolVisual2(lastEquippedToolName2)

	elseif tool and tool:IsA("Tool") and tool:FindFirstChild("FishId") then
		lastEquippedFishId = tool.FishId.Value
		saveHotbarState()
		updateRodVisual(lastEquippedRodName)
		updateFishVisual(tool.FishId.Value)
		updateToolVisual(lastEquippedToolName)
		updateToolVisual2(lastEquippedToolName2)

	elseif tool and tool:IsA("Tool") then
		updateRodVisual(lastEquippedRodName)
		updateFishVisual(lastEquippedFishId)
		updateToolVisual(lastEquippedToolName)
		updateToolVisual2(lastEquippedToolName2)

	else
		updateRodVisual(lastEquippedRodName)
		updateFishVisual(lastEquippedFishId)
		updateToolVisual(lastEquippedToolName)
		updateToolVisual2(lastEquippedToolName2)
	end
end

local function disableTooltip(tool)
	if tool and tool:IsA("Tool") then 
		tool.ToolTip = " " 
	end
end

-- ===================================================================
-- KEYBOARD SHORTCUTS (1-5 keys for hotbar)
-- ===================================================================
local function handleKeyPress(input, gameProcessed)
	if gameProcessed then return end

	local keyCode = input.KeyCode

	if keyCode == Enum.KeyCode.Three then
		playClickSound()
		toggleInventory(not isInventoryOpen)
		return
	end

	if isInventoryOpen then return end

	if keyCode == Enum.KeyCode.One then
		playClickSound()
		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and CollectionService:HasTag(currentTool, "Rod") then
			reUnequipAll:FireServer()
		else
			if lastEquippedRodName then
				reEquipRod:FireServer(lastEquippedRodName)
			end
		end

	elseif keyCode == Enum.KeyCode.Two then
		playClickSound()
		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and currentTool:FindFirstChild("FishId") then
			reUnequipAll:FireServer()
		else
			if lastEquippedFishId then
				reEquipFish:FireServer(lastEquippedFishId)
			end
		end

	elseif keyCode == Enum.KeyCode.Four then
		playClickSound()
		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		local isHoldingGenericTool = currentTool 
			and not currentTool:FindFirstChild("FishId") 
			and not CollectionService:HasTag(currentTool, "Rod")

		if isHoldingGenericTool and currentTool.Name == lastEquippedToolName then
			reUnequipAll:FireServer()
		else
			if lastEquippedToolName then
				local success, vipToolsList = pcall(function()
					return rfGetVIPTools:InvokeServer()
				end)

				local isVIPTool = false
				if success and vipToolsList then
					for _, toolData in ipairs(vipToolsList) do
						if toolData.Name == lastEquippedToolName then
							isVIPTool = true
							break
						end
					end
				end

				if isVIPTool then
					reEquipVIPTool:FireServer(lastEquippedToolName)
				else
					reEquipTool:FireServer(lastEquippedToolName)
				end
			end
		end

	elseif keyCode == Enum.KeyCode.Five then
		playClickSound()
		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		local isHoldingGenericTool = currentTool 
			and not currentTool:FindFirstChild("FishId") 
			and not CollectionService:HasTag(currentTool, "Rod")

		if isHoldingGenericTool and currentTool.Name == lastEquippedToolName2 then
			reUnequipAll:FireServer()
		else
			if lastEquippedToolName2 then
				local success, vipToolsList = pcall(function()
					return rfGetVIPTools:InvokeServer()
				end)

				local isVIPTool = false
				if success and vipToolsList then
					for _, toolData in ipairs(vipToolsList) do
						if toolData.Name == lastEquippedToolName2 then
							isVIPTool = true
							break
						end
					end
				end

				if isVIPTool then
					reEquipVIPTool:FireServer(lastEquippedToolName2)
				else
					reEquipTool:FireServer(lastEquippedToolName2)
				end
			end
		end
	end
end

-- ===================================================================
-- BUTTON EVENT SETUP
-- ===================================================================

local buttonConnections = {}

local function setupButtonEvents()
	for _, conn in ipairs(buttonConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(buttonConnections)

	table.insert(buttonConnections, Hotbar.BagButton.MouseButton1Click:Connect(function()
		playClickSound()
		toggleInventory(not isInventoryOpen)
	end))

	table.insert(buttonConnections, Hotbar.RodSlot.MouseButton1Click:Connect(function()
		playClickSound()

		if isInventoryOpen then
			if lastEquippedRodName then
				reUnequipAll:FireServer()
				lastEquippedRodName = nil
				updateRodVisual(nil)
				saveHotbarState()
			end
			return
		end

		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and CollectionService:HasTag(currentTool, "Rod") then
			reUnequipAll:FireServer()
		else
			if lastEquippedRodName then
				local hasRod = false
				for _, rodName in ipairs(allRodData) do
					if rodName == lastEquippedRodName then
						hasRod = true
						break
					end
				end

				if hasRod then
					reEquipRod:FireServer(lastEquippedRodName)
				else
					lastEquippedRodName = nil
					updateRodVisual(nil)
					saveHotbarState()
				end
			end
		end
	end))

	table.insert(buttonConnections, Hotbar.FishSlot.MouseButton1Click:Connect(function()
		playClickSound()

		if isInventoryOpen then
			if lastEquippedFishId then
				reUnequipAll:FireServer()
				lastEquippedFishId = nil
				updateFishVisual(nil)
				saveHotbarState()
			end
			return
		end

		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		if currentTool and currentTool:FindFirstChild("FishId") then
			reUnequipAll:FireServer()
		else
			if lastEquippedFishId then
				reEquipFish:FireServer(lastEquippedFishId)
			end
		end
	end))

	table.insert(buttonConnections, Hotbar.ToolSlot.MouseButton1Click:Connect(function()
		playClickSound()

		if isInventoryOpen then
			if lastEquippedToolName then
				reUnequipAll:FireServer()
				lastEquippedToolName = nil
				updateToolVisual(nil)
				saveHotbarState()
			end
			return
		end

		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		local isHoldingGenericTool = currentTool 
			and not currentTool:FindFirstChild("FishId") 
			and not CollectionService:HasTag(currentTool, "Rod")

		if isHoldingGenericTool and currentTool.Name == lastEquippedToolName then
			reUnequipAll:FireServer()
		else
			if lastEquippedToolName then
				local success, vipToolsList = pcall(function()
					return rfGetVIPTools:InvokeServer()
				end)

				local isVIPTool = false
				if success and vipToolsList then
					for _, toolData in ipairs(vipToolsList) do
						if toolData.Name == lastEquippedToolName then
							isVIPTool = true
							break
						end
					end
				end

				if isVIPTool then
					reEquipVIPTool:FireServer(lastEquippedToolName)
				else
					reEquipTool:FireServer(lastEquippedToolName)
				end
			end
		end
	end))

	table.insert(buttonConnections, Hotbar.ToolSlot2.MouseButton1Click:Connect(function()
		playClickSound()

		if isInventoryOpen then
			if lastEquippedToolName2 then
				reUnequipAll:FireServer()
				lastEquippedToolName2 = nil
				updateToolVisual2(nil)
				saveHotbarState()
			end
			return
		end

		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")

		local isHoldingGenericTool = currentTool 
			and not currentTool:FindFirstChild("FishId") 
			and not CollectionService:HasTag(currentTool, "Rod")

		if isHoldingGenericTool and currentTool.Name == lastEquippedToolName2 then
			reUnequipAll:FireServer()
		else
			if lastEquippedToolName2 then
				local success, vipToolsList = pcall(function()
					return rfGetVIPTools:InvokeServer()
				end)

				local isVIPTool = false
				if success and vipToolsList then
					for _, toolData in ipairs(vipToolsList) do
						if toolData.Name == lastEquippedToolName2 then
							isVIPTool = true
							break
						end
					end
				end

				if isVIPTool then
					reEquipVIPTool:FireServer(lastEquippedToolName2)
				else
					reEquipTool:FireServer(lastEquippedToolName2)
				end
			end
		end
	end))

	table.insert(buttonConnections, Inventory.CloseButton.MouseButton1Click:Connect(function()
		playClickSound()
		toggleInventory(false) 
	end))

	table.insert(buttonConnections, Inventory.FishTabButton.MouseButton1Click:Connect(function()
		playClickSound()
		switchTab("Fish") 
	end))

	table.insert(buttonConnections, Inventory.RodTabButton.MouseButton1Click:Connect(function()
		playClickSound()
		switchTab("Rods") 
	end))

	table.insert(buttonConnections, Inventory.ToolTabButton.MouseButton1Click:Connect(function()
		playClickSound()
		switchTab("Tools") 
	end))

	if Inventory.VIPTabButton then
		table.insert(buttonConnections, Inventory.VIPTabButton.MouseButton1Click:Connect(function()
			playClickSound()
			switchTab("VIP")
		end))
	end

	table.insert(buttonConnections, Inventory.SellAllButton.MouseButton1Click:Connect(function()
		playClickSound()

		local char = player.Character
		local currentTool = char and char:FindFirstChildOfClass("Tool")
		local isHoldingFish = currentTool and currentTool:FindFirstChild("FishId")

		if isHoldingFish then
			reUnequipAll:FireServer()
			task.wait(0.2)
		end

		local success = pcall(function()
			rfSellAll:InvokeServer()
		end)

		if success then
			task.wait(0.1)
			refreshAllData()

			if lastEquippedFishId then
				local fishStillExists = false
				for _, fish in ipairs(allFishData) do
					if fish.uniqueId == lastEquippedFishId then
						fishStillExists = true
						break
					end
				end

				if not fishStillExists then
					lastEquippedFishId = nil
					updateFishVisual(nil)
					saveHotbarState()
				end
			end
		end
	end))
end

-- ===================================================================
-- REAL-TIME FISH INVENTORY MONITORING
-- ===================================================================
local lastFishCount = 0

local function monitorFishInventory()
	task.spawn(function()
		while true do
			task.wait(0.5)

			if not isRefreshing then
				local success, fullData = pcall(function()
					return rfGetData:InvokeServer()
				end)

				if success and fullData then
					local newFishData = fullData.Fish or {}
					local newFishCount = #newFishData

					if newFishCount ~= lastFishCount then
						lastFishCount = newFishCount
						allFishData = newFishData

						updateFishCount()

						if isInventoryOpen and currentTab == "Fish" then
							populateFishGrid()
						end
					end
				end
			end
		end
	end)
end

-- ===================================================================
-- CHARACTER SETUP
-- ===================================================================

local function setupCharacter(character)
	local guiSuccess = updateGUIReferences()
	if not guiSuccess then
		task.wait(1)
		guiSuccess = updateGUIReferences()
		if not guiSuccess then
			return
		end
	end

	checkVIPStatus()

	setupButtonEvents()

	for _, conn in ipairs(connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(connections)

	if Hotbar.Frame then
		Hotbar.Frame.Visible = true
	end

	if Hotbar.BagButton then Hotbar.BagButton.Active = true end
	if Hotbar.RodSlot then Hotbar.RodSlot.Active = true end
	if Hotbar.FishSlot then Hotbar.FishSlot.Active = true end
	if Hotbar.ToolSlot then Hotbar.ToolSlot.Active = true end
	if Hotbar.ToolSlot2 then Hotbar.ToolSlot2.Active = true end

	local backpack = player:WaitForChild("Backpack")

	task.wait(0.5)

	task.spawn(function()
		local success, fullData = pcall(function()
			return rfGetData:InvokeServer()
		end)

		if success and fullData then
			allFishData = fullData.Fish or {}
			allRodData = fullData.Rods or {}
			lastFishCount = #allFishData

			local isFirstLoad = not HotbarState.rod and not HotbarState.fish and not HotbarState.tool1 and not HotbarState.tool2

			if not isFirstLoad then
				restoreHotbarState()
			else
				if fullData.LastRod then
					lastEquippedRodName = fullData.LastRod
					HotbarState.rod = fullData.LastRod
				end
			end

			validateHotbarItems()

			updateRodVisual(lastEquippedRodName)
			updateFishVisual(lastEquippedFishId)
			updateToolVisual(lastEquippedToolName)
			updateToolVisual2(lastEquippedToolName2)

			saveHotbarState()

			updateFishCount()
		end
	end)

	table.insert(connections, backpack.ChildAdded:Connect(function(child)
		disableTooltip(child)
	end))

	table.insert(connections, backpack.ChildRemoved:Connect(function(child)
		if not child:IsA("Tool") then return end

		task.wait(0.1)

		local isFish = child:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(child, "Rod")

		local stillExists = player.Backpack:FindFirstChild(child.Name) or 
			(player.Character and player.Character:FindFirstChild(child.Name))

		if stillExists then
			return
		end

		if isRod and child.Name == lastEquippedRodName then
			local rodStillOwned = false
			for _, rodName in ipairs(allRodData) do
				if rodName == lastEquippedRodName then
					rodStillOwned = true
					break
				end
			end
			if not rodStillOwned then
				lastEquippedRodName = nil
				updateRodVisual(nil)
				saveHotbarState()
			end
		elseif isFish and child:FindFirstChild("FishId") and child.FishId.Value == lastEquippedFishId then
			local fishStillExists = false
			for _, fish in ipairs(allFishData) do
				if fish.uniqueId == lastEquippedFishId then
					fishStillExists = true
					break
				end
			end
			if not fishStillExists then
				lastEquippedFishId = nil
				updateFishVisual(nil)
				saveHotbarState()
			end
		elseif not isFish and not isRod then
			if child.Name == lastEquippedToolName then
				lastEquippedToolName = nil
				updateToolVisual(nil)
				saveHotbarState()
			elseif child.Name == lastEquippedToolName2 then
				lastEquippedToolName2 = nil
				updateToolVisual2(nil)
				saveHotbarState()
			end
		end
	end))

	table.insert(connections, character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			disableTooltip(child)
			onToolChanged(child)
		end
	end))

	table.insert(connections, character.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			onToolChanged(nil)
		end
	end))

	local currentTool = character:FindFirstChildOfClass("Tool")
	disableTooltip(currentTool)
	onToolChanged(currentTool)
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

setupButtonEvents()

UserInputService.InputBegan:Connect(handleKeyPress)

monitorFishInventory()

local backpack = player:WaitForChild("Backpack")

backpack.ChildAdded:Connect(function(tool)
	if not tool:IsA("Tool") then return end

	if isInventoryOpen and currentTab == "Tools" then
		task.wait(0.1)
		local isFish = tool:FindFirstChild("FishId")
		local isRod = CollectionService:HasTag(tool, "Rod")
		if not isFish and not isRod then
			populateToolGrid()
		end
	end
end)

backpack.ChildRemoved:Connect(function(tool)
	if not tool:IsA("Tool") then return end

	if isInventoryOpen and currentTab == "Tools" then
		populateToolGrid()
	end
end)
-- AUTO REFRESH INVENTORY SAAT BOOST
GlobalLuckVal:GetPropertyChangedSignal("Value"):Connect(function()
	if isInventoryOpen and currentTab == "Rods" then
		populateRodGrid() -- Refresh kartu rod saja
	end
end)

if player.Character then 
	setupCharacter(player.Character) 
end

-- TAMBAHKAN INI DI BAGIAN BAWAH SCRIPT CustomInventoryManager:

-- Listener Real-time Luck Change
local luckValueObj = ReplicatedStorage:WaitForChild("FishingSystem"):WaitForChild("GlobalLuckMultiplier")

luckValueObj:GetPropertyChangedSignal("Value"):Connect(function()
	-- Jika Tab Rods sedang terbuka, refresh tampilannya
	if isInventoryOpen and currentTab == "Rods" then
		refreshAllData() -- Ini akan memperbarui stats pada kartu Rod
	end
end)

player.CharacterAdded:Connect(setupCharacter)