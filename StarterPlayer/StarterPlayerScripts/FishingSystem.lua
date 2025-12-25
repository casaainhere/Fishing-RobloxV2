-- System by @thehandofvoid
-- Modified by @jay_peaceee
-- StarterPlayer/StarterPlayerScripts/FishingSystem
-- ? WITH GLOBAL CHAT NOTIFICATIONS + RARE FISH CUTSCENE

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ===== MODULES =====
local modulesFolder = RepStorage:WaitForChild("FishingModules")
local FishingConfig = require(RepStorage:WaitForChild("FishingConfig"))
local SoundManager = require(modulesFolder:WaitForChild("SoundManager"))
local GUIManager = require(modulesFolder:WaitForChild("GUIManager"))
local AnimationController = require(modulesFolder:WaitForChild("AnimationController"))
local PowerBarSystem = require(modulesFolder:WaitForChild("PowerBarSystem"))
local MinigameSystem = require(modulesFolder:WaitForChild("MinigameSystem"))
local CastingSystem = require(modulesFolder:WaitForChild("CastingSystem"))

-- ?? NEW: Rare Fish Cutscene Module
local RareFishCutscene = require(modulesFolder:WaitForChild("RareFishCutscene"))

-- ===== REMOTE EVENTS =====
local fishGiverEvent = RepStorage:WaitForChild("FishGiver")
local castReplicationEvent = RepStorage:WaitForChild("CastReplication")
local cleanupCastEvent = RepStorage:WaitForChild("CleanupCast")
local showNotificationEvent = RepStorage:FindFirstChild("ShowNotification")

-- ?? NEW: Global chat notification event
local publishFishCatch = RepStorage:WaitForChild("PublishFishCatch")

-- ===== STATE =====
local gameState = {
	casted = false, sinker = nil, splash = nil, savedHookPosition = nil,
	waitTime = math.random(3, 6), fishingCaught = false, hasLanded = false,
	fishingInProgress = false, canCast = true, castingCooldown = false,
	cooldownTime = 0.3, activeFishingTask = nil,
	isAutoFishing = false
}
local playerPityData = FishingConfig.CreatePityTracker()

local speedState = {
	originalWalkSpeed = 16, fishingWalkSpeed = 8, speedModified = false
}

local connections = {}
local otherPlayersHooks = {}
local character = player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local playerGui = player:WaitForChild("PlayerGui")

-- ===== FORWARD DECLARATIONS =====
local updateMobileButtonText, onRodEquipped, onRodUnequipped, performCast

-- ===== ROD MANAGER =====
local RodManager = {currentRod = nil, isEquipped = false}

function RodManager:IsValidRod()
	return self.currentRod and self.currentRod.Parent and self.isEquipped
		and player.Character and self.currentRod:IsDescendantOf(player.Character)
		and self.currentRod:FindFirstChild("Part")
end

function RodManager:CleanupFishing()
	if not (gameState.casted or gameState.fishingInProgress) then return end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.castingCooldown = true, false
	gameState.activeFishingTask = nil

	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if MinigameSystem and MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end

	cleanupCastEvent:FireServer()
	if GUIManager and GUIManager.SlideFishingFrameOut then
		GUIManager:SlideFishingFrameOut(nil)
	end
	updateMobileButtonText()
end

function RodManager:OnRodEquipped(rod)
	if not rod or not rod.Parent then return end
	if self.currentRod and self.currentRod ~= rod then self:OnRodUnequipped() end

	self.currentRod, self.isEquipped = rod, true
	onRodEquipped(rod)
end

function RodManager:OnRodUnequipped()
	if not self.currentRod then return end
	self:CleanupFishing()
	self.currentRod, self.isEquipped = nil, false
	onRodUnequipped()
end

function RodManager:CheckEquippedRod(char)
	if not char then return end

	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and CS:HasTag(tool, "Rod") then
			if self.currentRod ~= tool then self:OnRodEquipped(tool) end
			return
		end
	end

	if self.isEquipped then self:OnRodUnequipped() end
end

function RodManager:SetupCharacterMonitoring(char)
	if not char then return end
	self:CheckEquippedRod(char)

	char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and CS:HasTag(child, "Rod") then
			self:OnRodEquipped(child)
		end
	end)

	char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and CS:HasTag(child, "Rod") and self.currentRod == child then
			self:OnRodUnequipped()
		end
	end)

	local conn; conn = RunService.Heartbeat:Connect(function()
		if not char or not char.Parent then conn:Disconnect(); return end
		if self.isEquipped and not self:IsValidRod() then self:OnRodUnequipped() end
		self:CheckEquippedRod(char)
	end)
end

-- ===== HELPERS =====
local function getCurrentRodName()
	return RodManager.currentRod and RodManager.currentRod.Name
end

local function setSpeed(isFishing)
	if isFishing and not speedState.speedModified then
		humanoid.WalkSpeed = speedState.fishingWalkSpeed
		speedState.speedModified = true
	elseif not isFishing and speedState.speedModified then
		humanoid.WalkSpeed = speedState.originalWalkSpeed
		speedState.speedModified = false
	end
end

local function startSpeedMonitoring()
	if connections.speedCheck then connections.speedCheck:Disconnect() end
	connections.speedCheck = RunService.Heartbeat:Connect(function()
		local isFishing = gameState.casted or gameState.fishingInProgress
			or MinigameSystem:IsActive() or PowerBarSystem:IsCharging()
		setSpeed(isFishing and RodManager.isEquipped)
	end)
end

local function stopSpeedMonitoring()
	if connections.speedCheck then
		connections.speedCheck:Disconnect()
		connections.speedCheck = nil
	end
	setSpeed(false)
end

local function startCastingCooldown()
	gameState.castingCooldown, gameState.canCast = true, false
	updateMobileButtonText()
	task.delay(gameState.cooldownTime, function()
		gameState.castingCooldown, gameState.canCast = false, true
		updateMobileButtonText()
	end)
end

function updateMobileButtonText()
	if not GUIManager then return end
	local text = "CAST"
	if MinigameSystem:IsActive() then text = "TAP!"
	elseif PowerBarSystem:IsCharging() then text = "CAST!"
	elseif gameState.casted or gameState.fishingInProgress then text = "FISHING..."
	elseif gameState.castingCooldown then text = "WAIT..." end

	if gameState.isAutoFishing then
		if MinigameSystem:IsActive() or gameState.casted or gameState.fishingInProgress then
			text = "AUTO..."
		else
			text = "AUTO"
		end
	end

	GUIManager:UpdateMobileButtonText(text)
end

local function selectFish()
	local rodName = getCurrentRodName()
	if not rodName then 
		warn("?? No rod equipped!")
		return nil 
	end

	local config = FishingConfig.GetRodConfig(rodName)
	local powerPercent = PowerBarSystem:GetCurrentPower() / 100

	if gameState.isAutoFishing then
		powerPercent = 1.0
	end

	local totalLuck = FishingConfig.CalculateTotalLuck(config.baseLuck, powerPercent)
	local selectedFish = FishingConfig.RollFish(playerPityData, rodName, totalLuck)

	if not selectedFish then
		warn("?? RollFish returned nil! Using fallback Common fish")
		for _, fish in ipairs(FishingConfig.FishTable) do
			if fish.rarity == "Common" then
				selectedFish = fish
				break
			end
		end

		if not selectedFish then
			return nil
		end
	end

	local fishWeight = FishingConfig.GenerateFishWeight(selectedFish, totalLuck, config.maxWeight)

	return selectedFish, fishWeight
end

-- ===== AUTO-FISHING LOOP =====
local autoFishConnection = nil

local function autoCast()
	if not RodManager:IsValidRod() or gameState.casted or not character or not gameState.canCast or gameState.castingCooldown then return end

	gameState.canCast = false

	local power = math.random(90, 100)

	AnimationController:Play("WaitingAnimation", 0.1)
	SoundManager:Play("Cast", 0.5)

	task.wait(0.4)

	performCast(power)
end

local function startAutoFishLoop()
	if autoFishConnection then autoFishConnection:Disconnect() end

	autoFishConnection = RunService.Heartbeat:Connect(function()
		if gameState.isAutoFishing and RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
			autoCast()
		end
	end)
end

local function stopAutoFishLoop()
	if autoFishConnection then
		autoFishConnection:Disconnect()
		autoFishConnection = nil
	end
end

-- ===== INITIALIZATION =====
local function initializeSystems()
	SoundManager:Initialize()
	GUIManager:Initialize(player)

	local autoButton = GUIManager:GetElement("autoButton")
	if autoButton then
		autoButton.MouseButton1Click:Connect(function()
			gameState.isAutoFishing = not gameState.isAutoFishing
			GUIManager:UpdateAutoButton(gameState.isAutoFishing)

			if gameState.isAutoFishing then
				startAutoFishLoop()
				GUIManager:ShowNotification("Auto-Fishing: ON", 3, Color3.fromRGB(100, 255, 100))
				if RodManager.isEquipped and gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
					autoCast()
				end
			else
				stopAutoFishLoop()
				GUIManager:ShowNotification("Auto-Fishing: OFF", 3, Color3.fromRGB(255, 100, 100))
			end
		end)
	end

	AnimationController:Initialize(humanoid)
	PowerBarSystem:Initialize({
		barFrame = GUIManager:GetElement("barFrame"),
		fillFrame = GUIManager:GetElement("fillFrame"),
		luckMultiText = GUIManager:GetElement("luckMultiText")
	})
	MinigameSystem:Initialize({
		fishingFillFrame = GUIManager:GetElement("fishingFillFrame"),
		infoText = GUIManager:GetElement("infoText")
	}, nil)

	speedState.originalWalkSpeed = humanoid.WalkSpeed
end

initializeSystems()

-- ===================================================================
-- ?? MINIGAME CALLBACKS - WITH CUTSCENE INTEGRATION
-- ===================================================================
MinigameSystem:SetCallbacks(
	function() -- ? SUCCESS CALLBACK
		gameState.fishingCaught = true
		updateMobileButtonText()
		if RodManager.isEquipped and RodManager.currentRod then
			AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end

		task.delay(0.3, function()
			local selectedFish, fishWeight = selectFish()
			if selectedFish then
				print(string.format("?? [Fishing] Caught: %s (%.1fkg, %s)", 
					selectedFish.name, fishWeight, selectedFish.rarity))

				-- ?? CHECK IF RARE FISH NEEDS CUTSCENE
				if RareFishCutscene.ShouldPlayCutscene(selectedFish.rarity) then
					print(string.format("?? [Fishing] RARE FISH! Playing cutscene for %s", selectedFish.name))

					-- Play cutscene (this will WAIT/yield until complete)
					RareFishCutscene.PlayCutscene(gameState.savedHookPosition, selectedFish.name)

					print("?? [Fishing] Cutscene complete! Now giving fish to player")
				end

				-- AFTER cutscene (or instant if no cutscene), give fish
				SoundManager:Play("Success", 0.6)
				GUIManager:ShowNotification(
					string.format("Caught %s %.1fkg %s", selectedFish.rarity, fishWeight, selectedFish.name),
					4, FishingConfig.GetRarityColor(selectedFish.rarity)
				)

				-- Send fish to server
				fishGiverEvent:FireServer({
					name = selectedFish.name,
					weight = fishWeight,
					rarity = selectedFish.rarity,
					hookPosition = gameState.savedHookPosition
				})

				-- ?? Publish rare fish catches to global chat
				-- Only publish Epic, Legendary, and Unknown rarity
				if selectedFish.rarity == "Epic" or selectedFish.rarity == "Legendary" or selectedFish.rarity == "Unknown" then
					publishFishCatch:FireServer(selectedFish.name, fishWeight, selectedFish.rarity)
				end

				gameState.savedHookPosition = nil
			end
			startCastingCooldown()
		end)
	end,
	function() -- ? FAIL CALLBACK
		gameState.savedHookPosition = nil
		if RodManager.isEquipped and RodManager.currentRod then
			AnimationController:TransitionTo("EquippedAnimation", 0.3)
		end
		GUIManager:ShowNotification("Fish got away!", 2, Color3.fromRGB(255, 100, 100))
		MinigameSystem:Stop()
		startCastingCooldown()
	end
)

-- ===== HOTKEY BLOCKER =====
UIS.InputBegan:Connect(function(input, processed)
	if processed or not MinigameSystem:IsActive() then return end
	local blocked = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
		Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Backspace}
	for _, key in blocked do if input.KeyCode == key then return end end
end)

-- ===== FISHING LOOP =====
local function runFishingSequence(taskId, splash)
	local checks = {
		function() return gameState.activeFishingTask == taskId end,
		function() return RodManager.isEquipped and RodManager.currentRod end,
		function() return RodManager:IsValidRod() end,
		function() return gameState.casted and gameState.sinker end
	}

	local function validate()
		for _, check in checks do if not check() then return false end end
		return true
	end

	local function cleanup()
		if splash then splash:Destroy() end
		gameState.splash = nil
	end

	if not validate() then cleanup(); return false end

	task.wait(gameState.waitTime)
	if not validate() then cleanup(); gameState.fishingInProgress = false; return false end

	for i = 1, 3 do
		if not validate() then cleanup(); return false end
		if gameState.sinker and gameState.casted then
			local bubble = RepStorage.Splash:Clone()
			bubble.Caster.Value = player.Name
			bubble.Parent = workspace
			bubble.Position = gameState.sinker.Position
			Debris:AddItem(bubble, 1)
		end
		task.wait(0.1)
	end

	if not validate() then cleanup(); gameState.fishingInProgress = false; return false end

	AnimationController:Play("PullingAnimation", 0.1)
	SoundManager:Play("Reeling", 0.4)
	GUIManager:SlideFishingFrameIn()

	if gameState.sinker and gameState.sinker.Parent then
		gameState.savedHookPosition = gameState.sinker.Position
	end

	MinigameSystem:Start(gameState.isAutoFishing, getCurrentRodName())

	while MinigameSystem:IsActive() do
		if not validate() then MinigameSystem:Stop(); break end
		task.wait(0.1)
	end

	gameState.fishingInProgress, gameState.casted = false, false
	gameState.activeFishingTask = nil
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
		local line = RodManager.currentRod.Part:FindFirstChild("Line")
		if line then line:Destroy() end
	end

	cleanupCastEvent:FireServer()

	GUIManager:SlideFishingFrameOut(function()
		updateMobileButtonText()
	end)

	return true
end

-- ===== CASTING =====
function performCast(power)
	if not RodManager:IsValidRod() or gameState.casted or not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	gameState.hasLanded, gameState.fishingInProgress = false, false
	gameState.canCast = false
	updateMobileButtonText()

	if not gameState.isAutoFishing then
		AnimationController:Play("WaitingAnimation", 0.1)
		SoundManager:Play("Cast", 0.5)
		task.wait(0.4)
	end

	if not RodManager.currentRod or not RodManager.currentRod:FindFirstChild("Part") then return end

	local rodPos = RodManager.currentRod.Part.Position + RodManager.currentRod.Part.CFrame.LookVector * 1.5
	local velocity = CastingSystem:CalculateVelocity(rodPos, hrp.CFrame.LookVector, power, 100)

	castReplicationEvent:FireServer(rodPos, velocity, getCurrentRodName(), power)

	gameState.sinker = CastingSystem:CreateHook(rodPos, getCurrentRodName())
	gameState.sinker.AssemblyLinearVelocity = velocity

	local att1 = Instance.new("Attachment", RodManager.currentRod.Part)
	local att2 = Instance.new("Attachment", gameState.sinker)
	CastingSystem:CreateBeam(RodManager.currentRod.Part, att1, att2, getCurrentRodName())
	gameState.casted = true

	local landingConn; landingConn = gameState.sinker.Touched:Connect(function(hit)
		if gameState.hasLanded or not gameState.casted or gameState.fishingInProgress then return end
		if hit:IsDescendantOf(RodManager.currentRod) or hit:IsDescendantOf(character) then return end
		if CS:HasTag(hit, "Fish") or (hit.Parent and CS:HasTag(hit.Parent, "Fish")) then return end

		gameState.hasLanded = true
		gameState.sinker.AssemblyLinearVelocity = Vector3.zero
		gameState.sinker.Anchored = true
		if landingConn then landingConn:Disconnect() end

		local isWater = hit:IsA("Terrain") and CastingSystem:IsPositionInWater(gameState.sinker.Position)

		if isWater then
			SoundManager:Play("HookHit", 0.4)
			local waterY = CastingSystem:GetWaterSurfaceY(gameState.sinker.Position.X, gameState.sinker.Position.Z)
			if waterY then
				gameState.sinker.Position = Vector3.new(gameState.sinker.Position.X, waterY + 0.15, gameState.sinker.Position.Z)
			end

			gameState.activeFishingTask = tick()
			gameState.fishingInProgress, gameState.canCast = true, false
			updateMobileButtonText()

			local splash = RepStorage.Splash:Clone()
			splash.Caster.Value = player.Name
			splash.Parent = workspace
			splash.Position = gameState.sinker.Position
			gameState.splash = splash

			task.spawn(runFishingSequence, gameState.activeFishingTask, splash)
		else
			GUIManager:ShowNotification("Cast into water!", 3, Color3.fromRGB(255, 200, 100))
			task.wait(2)
			if not RodManager.isEquipped or not RodManager.currentRod then return end

			gameState.casted = false
			if gameState.sinker then gameState.sinker:Destroy() end
			if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
				local line = RodManager.currentRod.Part:FindFirstChild("Line")
				if line then line:Destroy() end
			end
			cleanupCastEvent:FireServer()
			startCastingCooldown()
			task.delay(0.6, function()
				if RodManager.isEquipped and RodManager.currentRod then
					AnimationController:Play("EquippedAnimation", 0.3)
				end
			end)
		end
	end)
end

-- ===== ROD EQUIPPED/UNEQUIPPED =====
function onRodEquipped(rod)
	AnimationController:Reload(humanoid)
	AnimationController:Play("EquippedAnimation", 0.3)
	startSpeedMonitoring()

	GUIManager:ShowAutoButton(true)
	if isMobile then
		GUIManager:ShowMobileButton(true)
		updateMobileButtonText()

		if connections.mobileButton then connections.mobileButton:Disconnect() end
		connections.mobileButton = GUIManager:GetElement("tapMobileButton").MouseButton1Click:Connect(function()
			if not RodManager.isEquipped then return end

			if gameState.isAutoFishing then return end

			if MinigameSystem:IsActive() then
				task.spawn(function() MinigameSystem:HandleClick(SoundManager, GUIManager) end)
			elseif PowerBarSystem:IsCharging() then
				local power = PowerBarSystem:StopCharging()
				if power > 10 and not gameState.castingCooldown then
					performCast(power)
				else
					if not gameState.castingCooldown then
						GUIManager:ShowNotification("Not enough power!", 2, Color3.fromRGB(255, 200, 100))
					end
					gameState.canCast = true
					AnimationController:Play("EquippedAnimation", 0.3)
				end
				updateMobileButtonText()
			elseif gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
				PowerBarSystem:StartCharging(getCurrentRodName())
				updateMobileButtonText()
			end
		end)
	else
		if connections.inputBegan then connections.inputBegan:Disconnect() end
		connections.inputBegan = UIS.InputBegan:Connect(function(input, processed)
			if processed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

			if gameState.isAutoFishing then return end

			if gameState.canCast and not gameState.casted and not gameState.fishingInProgress and not gameState.castingCooldown then
				PowerBarSystem:StartCharging(getCurrentRodName())
				updateMobileButtonText()
			end
		end)

		if connections.inputEnded then connections.inputEnded:Disconnect() end
		connections.inputEnded = UIS.InputEnded:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
				and MinigameSystem:IsActive() then
				task.spawn(function() MinigameSystem:HandleClick(SoundManager, GUIManager) end)

			elseif input.UserInputType == Enum.UserInputType.MouseButton1 and PowerBarSystem:IsCharging() then
				if gameState.isAutoFishing then return end

				local power = PowerBarSystem:StopCharging()
				if power > 10 and not gameState.castingCooldown then
					performCast(power)
				else
					if not gameState.castingCooldown then
						GUIManager:ShowNotification("Not enough power!", 2, Color3.fromRGB(255, 200, 100))
					end
					gameState.canCast = true
					AnimationController:Play("EquippedAnimation", 0.3)
				end
				updateMobileButtonText()
			end
		end)
	end
end

function onRodUnequipped()
	if PowerBarSystem and PowerBarSystem:IsCharging() then PowerBarSystem:StopCharging() end
	if MinigameSystem and MinigameSystem:IsActive() then
		MinigameSystem:Stop()
		GUIManager:SlideFishingFrameOut(nil)
	end

	if gameState.isAutoFishing then
		gameState.isAutoFishing = false
		GUIManager:UpdateAutoButton(false)
		stopAutoFishLoop()
	end
	GUIManager:ShowAutoButton(false)

	AnimationController:Stop()
	stopSpeedMonitoring()
	PowerBarSystem:Reset()
	GUIManager:ShowMobileButton(false)

	for k, conn in connections do
		if conn then conn:Disconnect(); connections[k] = nil end
	end

	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if RodManager.currentRod and RodManager.currentRod:FindFirstChild("Part") then
		local line = RodManager.currentRod.Part:FindFirstChild("Line")
		if line then line:Destroy() end
	end
	if gameState.casted or gameState.fishingInProgress then cleanupCastEvent:FireServer() end

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.hasLanded = true, false
	gameState.fishingCaught, gameState.castingCooldown = false, false
end

-- ===== CHARACTER EVENTS =====
player.CharacterAdded:Connect(function(char)
	gameState.activeFishingTask = nil
	if MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	cleanupCastEvent:FireServer()

	gameState.casted, gameState.fishingInProgress = false, false
	gameState.canCast, gameState.hasLanded = true, false
	gameState.fishingCaught, gameState.castingCooldown = false, false

	gameState.isAutoFishing = false

	character, humanoid = char, char:WaitForChild("Humanoid")
	speedState.originalWalkSpeed = humanoid.WalkSpeed
	initializeSystems()
	GUIManager:UpdateAutoButton(false)

	task.wait(1.5)
	RodManager:SetupCharacterMonitoring(character)
end)

player.CharacterRemoving:Connect(function()
	gameState.activeFishingTask = nil
	if MinigameSystem:IsActive() then MinigameSystem:ForceStop() end
	if gameState.sinker then gameState.sinker:Destroy(); gameState.sinker = nil end
	if gameState.splash then gameState.splash:Destroy(); gameState.splash = nil end
	for k, conn in connections do if conn then conn:Disconnect(); connections[k] = nil end end
	cleanupCastEvent:FireServer()
end)

-- ===== CAST REPLICATION =====
castReplicationEvent.OnClientEvent:Connect(function(otherPlayer, rodPos, velocity, rodName)
	if otherPlayer == player then return end

	local data = otherPlayersHooks[otherPlayer]
	if data then
		if data.sinker then data.sinker:Destroy() end
		if data.beam then data.beam:Destroy() end
		if data.connection then data.connection:Disconnect() end
	end

	local sinker = CastingSystem:CreateHook(rodPos, rodName)
	sinker.AssemblyLinearVelocity = velocity

	local char = otherPlayer.Character
	if not char then Debris:AddItem(sinker, 5); return end

	local rod = char:FindFirstChild(rodName)
	if not rod or not rod:FindFirstChild("Part") then Debris:AddItem(sinker, 5); return end

	local att1 = Instance.new("Attachment", rod.Part)
	local att2 = Instance.new("Attachment", sinker)
	local beam = CastingSystem:CreateBeam(rod.Part, att1, att2, rodName)

	local conn; conn = sinker.Touched:Connect(function(hit)
		if hit:IsDescendantOf(char) or CS:HasTag(hit, "Fish") or (hit.Parent and CS:HasTag(hit.Parent, "Fish")) then return end
		sinker.AssemblyLinearVelocity = Vector3.zero
		sinker.Anchored = true
		if conn then conn:Disconnect() end
	end)

	otherPlayersHooks[otherPlayer] = {sinker = sinker, beam = beam, connection = conn}
end)

cleanupCastEvent.OnClientEvent:Connect(function(otherPlayer)
	if otherPlayer == player then return end
	local data = otherPlayersHooks[otherPlayer]
	if data then
		if data.sinker then data.sinker:Destroy() end
		if data.beam then data.beam:Destroy() end
		if data.connection then data.connection:Disconnect() end
		otherPlayersHooks[otherPlayer] = nil
	end
end)

showNotificationEvent.OnClientEvent:Connect(function(message, duration, textColor)
	GUIManager:ShowNotification(message, duration or 3, textColor or Color3.fromRGB(255, 255, 255))
end)

-- ===== INITIAL SETUP =====
task.wait(2)
RodManager:SetupCharacterMonitoring(character)

print("? [FishingSystem] Initialized with Cutscene support!")