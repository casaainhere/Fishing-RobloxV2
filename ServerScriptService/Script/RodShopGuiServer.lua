-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- ServerScriptService/RodShopGuiServer (Updated for Coins + Gamepass Prices)
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local rodToolFolder = ServerStorage:WaitForChild("AllRods")

local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")
local DataManager = require(FishingSystem:WaitForChild("FishingModules"):WaitForChild("DataManager"))
local RodShopConfig = require(FishingSystem:WaitForChild("RodShopConfig"))
local FishingConfig = require(FishingSystem:WaitForChild("FishingConfig"))
local GameProfileService = require(game:GetService("ServerScriptService").Data.PetCore:WaitForChild("FishData"))

local ShopEvents = FishingSystem:WaitForChild("RodShopEvents")
local rfGetShopData = ShopEvents:WaitForChild("GetShopData")
local reRequestPurchase = ShopEvents:WaitForChild("RequestPurchase")
local rePurchaseSuccess = ShopEvents:WaitForChild("PurchaseSuccess")

local showNotificationEvent = FishingSystem:WaitForChild("ShowNotification")
local function notify(player, message, color)
	showNotificationEvent:FireClient(player, message, 3, color or Color3.fromRGB(255, 255, 255))
end

local function giveRod(player, rodName)
	if not player or not rodName then return end

	DataManager:AddRod(player, rodName)

	if player.Backpack:FindFirstChild(rodName) or (player.Character and player.Character:FindFirstChild(rodName)) then
		return
	end

	local rodTool = rodToolFolder:FindFirstChild(rodName)
	if rodTool then
		rodTool:Clone().Parent = player.Backpack
		notify(player, "Purchase successful! '" .. rodName .. "' added to your inventory.", Color3.fromRGB(100, 255, 100))
	else
		notify(player, "Error: Rod tool not found in server.", Color3.fromRGB(255, 100, 100))
	end
end

-- NEW: Function to get gamepass price
local function getGamepassPrice(gamepassId)
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(gamepassId, Enum.InfoType.GamePass)
	end)

	if success and productInfo then
		return productInfo.PriceInRobux or 0
	end

	return 0
end

local function processPurchase(player, rodName)
	local config = RodShopConfig[rodName]
	if not config then
		return false
	end

	if DataManager:HasRod(player, rodName) then
		notify(player, "You already own this rod!", Color3.fromRGB(255, 200, 100))
		return false
	end

	-- CURRENCY PURCHASE (Using Coins)
	if config.Type == "Currency" then
		local price = config.Value
		local success, remaining = GameProfileService:TryPurchase(player, price)

		if success then
			giveRod(player, rodName)
			return true
		else
			notify(player, "Not enough Coins!", Color3.fromRGB(255, 100, 100))
			return false
		end

		-- GAMEPASS PURCHASE
	elseif config.Type == "Gamepass" then
		local gamepassId = config.Value

		local ownsPass = false
		local success, result = pcall(function()
			ownsPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
		end)

		if not success then
			notify(player, "Error checking gamepass. Please try again.", Color3.fromRGB(255, 100, 100))
			return false
		end

		if ownsPass then
			notify(player, "You already own this gamepass. Rod added to your inventory.", Color3.fromRGB(100, 255, 100))
			giveRod(player, rodName)
			return true
		else
			MarketplaceService:PromptGamePassPurchase(player, gamepassId)
			return false
		end
	end

	return false
end

-- Get shop data (UPDATED to include gamepass prices)
rfGetShopData.OnServerInvoke = function(player)
	local ownedRods = DataManager:GetOwnedRods(player)
	local allRodData = {}

	for rodName, shopInfo in pairs(RodShopConfig) do
		if shopInfo.Type ~= "None" then
			local stats = FishingConfig.GetRodConfig(rodName)
			local tool = rodToolFolder:FindFirstChild(rodName)

			-- Create shop info copy with price
			local shopInfoWithPrice = {
				Type = shopInfo.Type,
				Value = shopInfo.Value,
				RobuxPrice = nil -- default
			}

			-- If gamepass, fetch the Robux price
			if shopInfo.Type == "Gamepass" then
				shopInfoWithPrice.RobuxPrice = getGamepassPrice(shopInfo.Value)
			end

			allRodData[rodName] = {
				ShopInfo = shopInfoWithPrice,
				Stats = stats,
				TextureId = tool and tool.TextureId or ""
			}
		end
	end

	return {
		OwnedRods = ownedRods,
		AllRodData = allRodData
	}
end

-- Purchase request
reRequestPurchase.OnServerEvent:Connect(function(player, rodName)
	local success = processPurchase(player, rodName)

	if success then
		rePurchaseSuccess:FireClient(player)
	end
end)

-- Gamepass purchase finished
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedGamepassId, wasPurchased)
	if not wasPurchased then return end

	for rodName, config in pairs(RodShopConfig) do
		if config.Type == "Gamepass" and config.Value == purchasedGamepassId then
			task.wait(0.5)
			giveRod(player, rodName)
			rePurchaseSuccess:FireClient(player)
			break
		end
	end
end)