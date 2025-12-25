-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- RodShopGuiManager (UPDATED: Uses Manual ProximityPrompt inside NPC)

local NPC_SHOP_NAME = "RodShop"

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local GlobalLuckVal = FishingSystem:WaitForChild("GlobalLuckMultiplier")

local ShopEvents = FishingSystem:WaitForChild("RodShopEvents")
local rfGetShopData = ShopEvents:WaitForChild("GetShopData")
local reRequestPurchase = ShopEvents:WaitForChild("RequestPurchase")
local rePurchaseSuccess = ShopEvents:WaitForChild("PurchaseSuccess")

local playerCoins = 0
local ownedRods = {}
local allRodData = {}
local shopDataLoaded = false

local gui = {}
local isGuiVisible = false

-- NPC Prompt references
local npcConnection = nil

-- Close button connection
local closeButtonConnection = nil

-- ===================================================================
-- ?? SOUND SETTINGS
-- ===================================================================
local SOUNDS = {
	Click = "rbxassetid://340910329",
	Hover = "rbxassetid://5852311399",
	Purchase = "rbxassetid://4525871712",
	Error = "rbxassetid://550209561",
	Open = "rbxassetid://4943184703",
	Close = "rbxassetid://4943184703",
}

local function playSound(soundId, volume)
	volume = volume or 0.3
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- ===================================================================
-- TIER & COLOR SYSTEM
-- ===================================================================
local TierSystem = {
	Tiers = {
		{name = "Unknown", minLuck = 10.0, color = Color3.fromRGB(95, 87, 141), glow = Color3.fromRGB(150, 140, 220)},
		{name = "Legendary", minLuck = 1.9, color = Color3.fromRGB(255, 128, 0), glow = Color3.fromRGB(255, 200, 100)},
		{name = "Epic", minLuck = 1.5, color = Color3.fromRGB(160, 30, 255), glow = Color3.fromRGB(200, 100, 255)},
		{name = "Rare", minLuck = 1.2, color = Color3.fromRGB(30, 100, 255), glow = Color3.fromRGB(100, 150, 255)},
		{name = "Uncommon", minLuck = 1.1, color = Color3.fromRGB(30, 255, 30), glow = Color3.fromRGB(100, 255, 100)},
		{name = "Common", minLuck = 0, color = Color3.fromRGB(200, 200, 200), glow = Color3.fromRGB(220, 220, 220)},
	}
}

function TierSystem:GetTier(baseLuck)
	for _, tier in ipairs(self.Tiers) do
		if baseLuck >= tier.minLuck then
			return tier
		end
	end
	return self.Tiers[#self.Tiers]
end

-- ===================================================================
-- HELPER FUNCTIONS
-- ===================================================================
local function formatNumberWithCommas(number)
	local numberString = tostring(math.floor(number))
	local reversed = string.reverse(numberString)
	local formatted = reversed:gsub("(%d%d%d)", "%1,")
	return string.reverse(formatted):gsub("^,", "")
end

-- ===================================================================
-- SORT RODS BY POWER (HIGH ? LOW)
-- ===================================================================
local function sortRodsByPower(rodDataTable)
	local sortedList = {}

	for rodName, data in pairs(rodDataTable) do
		table.insert(sortedList, {
			name = rodName,
			data = data,
			baseLuck = data.Stats.baseLuck or 0,
			maxWeight = data.Stats.maxWeight or 0
		})
	end

	table.sort(sortedList, function(a, b)
		if a.baseLuck ~= b.baseLuck then
			return a.baseLuck > b.baseLuck
		else
			return a.maxWeight > b.maxWeight
		end
	end)

	return sortedList
end

-- ===================================================================
-- FIND/REFRESH GUI REFERENCES
-- ===================================================================
local function findPreMadeGui()
	if closeButtonConnection then
		closeButtonConnection:Disconnect()
		closeButtonConnection = nil
	end

	local screenGui = playerGui:WaitForChild("RodShopGui", 10)
	if not screenGui then return false end

	local mainFrame = screenGui:FindFirstChild("MainFrame")
	local overlay = screenGui:FindFirstChild("Overlay")
	if not mainFrame then return false end

	local header = mainFrame:FindFirstChild("Header")
	local scrollFrame = mainFrame:FindFirstChild("ScrollFrame")
	local template = mainFrame:FindFirstChild("Template")

	if not header or not scrollFrame or not template then return false end

	local title = header:FindFirstChild("Title")
	local coinsDisplay = header:FindFirstChild("CoinsDisplay")
	local closeButton = header:FindFirstChild("CloseButton")

	gui = {
		ScreenGui = screenGui,
		MainFrame = mainFrame,
		Overlay = overlay,
		Header = header,
		Title = title,
		CoinsDisplay = coinsDisplay,
		CloseButton = closeButton,
		ScrollFrame = scrollFrame,
		Template = template
	}

	if mainFrame then mainFrame.Visible = false end
	if overlay then overlay.Visible = false end

	if closeButton then
		closeButtonConnection = closeButton.MouseButton1Click:Connect(function()
			playSound(SOUNDS.Close, 0.3)
			setGuiVisible(false)
		end)
		closeButton.MouseEnter:Connect(function() playSound(SOUNDS.Hover, 0.2) end)
	end

	return true
end

-- ===================================================================
-- CREATE ROD CARD
-- ===================================================================
local function createRodCard(rodName, data, layoutOrder)
	local card = gui.Template:Clone()
	card.Name = rodName
	card.Visible = true
	card.LayoutOrder = layoutOrder

	local shopInfo = data.ShopInfo
	local stats = data.Stats

	-- HITUNG LUCK AKTIF (Base Luck x Server Boost)
	local currentMultiplier = GlobalLuckVal.Value or 1
	local finalLuck = (stats.baseLuck or 1.0) * currentMultiplier

	local tier = TierSystem:GetTier(stats.baseLuck) -- Tier tetap berdasarkan base luck agar warna tidak berubah jadi aneh

	local uiStroke = card:FindFirstChild("UIStroke")
	if not uiStroke then
		uiStroke = Instance.new("UIStroke")
		uiStroke.Parent = card
	end
	uiStroke.Color = tier.glow
	uiStroke.Thickness = 3
	uiStroke.Transparency = 0.3

	if tier.name == "Legendary" or tier.name == "Unknown" then
		uiStroke.Transparency = 0
		local glowTween = TweenService:Create(uiStroke, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency = 0.5})
		glowTween:Play()
	end

	local rodNameLabel = card:FindFirstChild("RodName")
	if rodNameLabel then
		rodNameLabel.Text = string.format("[%s] %s", tier.name:upper(), rodName)
		rodNameLabel.TextColor3 = tier.color
	end

	local rodImage = card:FindFirstChild("RodImage")
	if rodImage then
		local textureIdString = tostring(data.TextureId)
		if textureIdString:sub(1, 13) == "rbxassetid://" then
			rodImage.Image = textureIdString
		else
			rodImage.Image = "rbxassetid://" .. textureIdString
		end
	end

	local statsLabel = card:FindFirstChild("StatsLabel")
	if statsLabel then
		-- TAMPILKAN ANGKA LUCK YANG SUDAH DIKALIKAN
		-- Jika sedang boost, warnai angkanya jadi hijau!
		local luckText = ""
		if currentMultiplier > 1 then
			luckText = string.format("Luck: <font color='#00FF00'><b>%.1fx</b></font>", finalLuck) -- RichText Hijau
		else
			luckText = string.format("Luck: %.1fx", finalLuck)
		end

		statsLabel.RichText = true -- Aktifkan RichText
		statsLabel.Text = string.format("%s\nWeight: %dkg\nMax Rarity: %s", luckText, stats.maxWeight or 0, stats.maxRarity or "Unknown")
		statsLabel.TextColor3 = tier.color
	end

	local priceLabel = card:FindFirstChild("PriceLabel")
	local buyButton = card:FindFirstChild("BuyButton")
	local ownedLabel = card:FindFirstChild("OwnedLabel")

	if table.find(ownedRods, rodName) then
		if buyButton then buyButton.Visible = false end
		if ownedLabel then ownedLabel.Visible = true end
		if priceLabel then
			priceLabel.Text = "? OWNED"
			priceLabel.TextColor3 = Color3.fromRGB(80, 170, 80)
		end
	else
		if buyButton then buyButton.Visible = true end
		if ownedLabel then ownedLabel.Visible = false end

		if shopInfo.Type == "Currency" then
			if priceLabel then
				priceLabel.Text = "?? " .. formatNumberWithCommas(shopInfo.Value)
				priceLabel.TextColor3 = Color3.fromRGB(255, 223, 85)
			end
			if buyButton then
				buyButton.MouseEnter:Connect(function() playSound(SOUNDS.Hover, 0.2) end)
				buyButton.MouseButton1Click:Connect(function()
					playSound(SOUNDS.Click, 0.3)
					if playerCoins < shopInfo.Value then
						playSound(SOUNDS.Error, 0.4)
						return
					end
					reRequestPurchase:FireServer(rodName)
				end)
			end
		elseif shopInfo.Type == "Gamepass" then
			if priceLabel then
				priceLabel.Text = (shopInfo.RobuxPrice and shopInfo.RobuxPrice > 0) and string.format("?? %d Robux", shopInfo.RobuxPrice) or "?? GAMEPASS"
				priceLabel.TextColor3 = Color3.fromRGB(85, 170, 255)
			end
			if buyButton then
				buyButton.BackgroundColor3 = Color3.fromRGB(85, 170, 255)
				buyButton.MouseEnter:Connect(function() playSound(SOUNDS.Hover, 0.2) end)
				buyButton.MouseButton1Click:Connect(function()
					playSound(SOUNDS.Click, 0.3)
					reRequestPurchase:FireServer(rodName)
				end)
			end
		end
	end
	return card
end

-- ===================================================================
-- POPULATE SHOP
-- ===================================================================
local function populateShop()
	if not gui.ScrollFrame or not gui.Template then return end
	for _, child in ipairs(gui.ScrollFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "Template" then child:Destroy() end
	end

	if gui.CoinsDisplay then
		local coinsStat = player:WaitForChild("leaderstats"):FindFirstChild("Coins")
		if coinsStat then
			playerCoins = coinsStat.Value
			gui.CoinsDisplay.Text = string.format("?? Coins: %s", formatNumberWithCommas(playerCoins))
		end
	end

	local sortedRods = sortRodsByPower(allRodData)
	for i, rodInfo in ipairs(sortedRods) do
		local card = createRodCard(rodInfo.name, rodInfo.data, i)
		card.Parent = gui.ScrollFrame
	end
end

-- ===================================================================
-- PRE-LOAD SHOP DATA
-- ===================================================================
local function preloadShopData()
	local success, data = pcall(function() return rfGetShopData:InvokeServer() end)
	if success and data then
		ownedRods = data.OwnedRods
		allRodData = data.AllRodData
		shopDataLoaded = true
	end
end

local function refreshShopData()
	if gui.CoinsDisplay then gui.CoinsDisplay.Text = "?? Loading..." end
	local success, data = pcall(function() return rfGetShopData:InvokeServer() end)
	if success and data then
		ownedRods = data.OwnedRods
		allRodData = data.AllRodData
		populateShop()
	end
end

-- ===================================================================
-- SHOW/HIDE GUI
-- ===================================================================
function setGuiVisible(visible)
	if not gui or not gui.MainFrame then return end
	if visible == isGuiVisible then return end

	isGuiVisible = visible

	if visible then
		playSound(SOUNDS.Open, 0.3)
		if shopDataLoaded then populateShop() else refreshShopData() end
		if gui.MainFrame then gui.MainFrame.Visible = true end
		if gui.Overlay then gui.Overlay.Visible = true end
	else
		playSound(SOUNDS.Close, 0.3)
		if gui.MainFrame then gui.MainFrame.Visible = false end
		if gui.Overlay then gui.Overlay.Visible = false end
	end
end

-- ===================================================================
-- SETUP NPC PROMPT (EXISTING IN MODEL)
-- ===================================================================
local function connectToExistingPrompt()
	-- Clean up old connection if it exists
	if npcConnection then
		npcConnection:Disconnect()
		npcConnection = nil
	end

	-- 1. Find the RodShop Model
	local npc = workspace:WaitForChild(NPC_SHOP_NAME, 30)
	if not npc then
		warn("[RodShop] NPC Model '".. NPC_SHOP_NAME .. "' not found in Workspace!")
		return
	end

	-- 2. Find ProximityPrompt anywhere inside the NPC (Recursively)
	local prompt = npc:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		-- If not found directly, check inside RootPart/Torso
		local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
		if root then
			prompt = root:FindFirstChildOfClass("ProximityPrompt")
		end
	end

	if not prompt then
		-- Try recursive search as fallback
		for _, desc in ipairs(npc:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				prompt = desc
				break
			end
		end
	end

	if not prompt then
		warn("[RodShop] ProximityPrompt not found inside " .. NPC_SHOP_NAME .. "! Please create it manually.")
		return
	end

	-- 3. Connect Triggered Event
	npcConnection = prompt.Triggered:Connect(function(playerWhoTriggered)
		if playerWhoTriggered == player then
			setGuiVisible(true)
		end
	end)
end

-- ===================================================================
-- CHARACTER RESPAWN HANDLER
-- ===================================================================
local function onCharacterAdded(character)
	setGuiVisible(false)
	task.wait(0.5)
	findPreMadeGui()
	connectToExistingPrompt() -- ?? RE-CONNECT TO THE EXISTING PROMPT

	local humanoid = character:WaitForChild("Humanoid", 5)
	if humanoid then
		humanoid.Died:Connect(function() setGuiVisible(false) end)
	end
end

-- ===================================================================
-- EVENT CONNECTIONS
-- ===================================================================
rePurchaseSuccess.OnClientEvent:Connect(function()
	playSound(SOUNDS.Purchase, 0.5)
	if isGuiVisible then task.wait(0.2); refreshShopData() end
end)

player:WaitForChild("leaderstats"):WaitForChild("Coins").Changed:Connect(function(newCoins)
	playerCoins = newCoins
	if isGuiVisible and gui and gui.CoinsDisplay then
		gui.CoinsDisplay.Text = string.format("?? Coins: %s", formatNumberWithCommas(playerCoins))
	end
end)

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local function initialize()
	findPreMadeGui()
	task.spawn(preloadShopData)
	if player.Character then onCharacterAdded(player.Character) end
	player.CharacterAdded:Connect(onCharacterAdded)
end

GlobalLuckVal:GetPropertyChangedSignal("Value"):Connect(function()
	if isGuiVisible then
		refreshShopData() -- Refresh tampilan agar angka berubah
	end
end)

initialize()