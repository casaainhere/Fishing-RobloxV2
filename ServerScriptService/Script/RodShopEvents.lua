--[[
	System by @thehandofvoid
	Modified by @jay_peaceee
	RodShopEvents - ServerScript
	Skrip ini hanya berjalan sekali untuk membuat RemoteEvents/Functions
	yang dibutuhkan oleh sistem GUI Shop yang baru.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local fishingSystemFolder = ReplicatedStorage:WaitForChild("FishingSystem")

-- Folder untuk menampung event-event GUI Shop
local shopEventsFolder = Instance.new("Folder")
shopEventsFolder.Name = "RodShopEvents"
shopEventsFolder.Parent = fishingSystemFolder

-- (Client) -> (Server) -> (Client)
-- Klien meminta data toko (semua joran, harga, stats, joran yang dimiliki)
local rfGetShopData = Instance.new("RemoteFunction")
rfGetShopData.Name = "GetShopData"
rfGetShopData.Parent = shopEventsFolder

-- (Client) -> (Server)
-- Klien mengirim permintaan untuk membeli joran
local reRequestPurchase = Instance.new("RemoteEvent")
reRequestPurchase.Name = "RequestPurchase"
reRequestPurchase.Parent = shopEventsFolder

-- (Server) -> (Client)
-- Server memberi tahu klien bahwa pembelian berhasil & data harus di-refresh
local rePurchaseSuccess = Instance.new("RemoteEvent")
rePurchaseSuccess.Name = "PurchaseSuccess"
rePurchaseSuccess.Parent = shopEventsFolder

-- Hancurkan skrip ini setelah selesai
script:Destroy()