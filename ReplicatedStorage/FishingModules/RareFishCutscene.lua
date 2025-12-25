-- RareFishCutscene Module - FIXED VERSION WITH DEBUGGING
-- LOKASI: ReplicatedStorage/FishingSystem/FishingModules/RareFishCutscene
-- TYPE: ModuleScript

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local RareFishCutscene = {}

-- ===================================================================
-- ?? CUTSCENE CONFIGURATION (10 SECOND EPIC CUTSCENE)
-- ===================================================================
local CONFIG = {
	-- VFX Settings
	VFX_ASSET_PATH = "ReplicatedStorage.FishingSystem.Assets.VFX.ultimate", -- ? CORRECT PATH!
	VFX_DURATION = 8.0, -- Berapa lama VFX muncul (detik)
	VFX_LAUNCH_HEIGHT = 20, -- Ketinggian plasma menyembur (studs)
	VFX_LAUNCH_DURATION = 2.0, -- Durasi plasma terbang ke atas (detik)
	VFX_LAUNCH_DELAY = 0.3, -- Delay sebelum launch (detik)
	VFX_SIZE = 4, -- Ukuran holder VFX (studs)

	-- Camera Settings
	ZOOM_OUT_AMOUNT = 25, -- Zoom keluar berapa unit (FOV 70 ? 45)
	ZOOM_DURATION = 2.5, -- Durasi zoom out (detik)
	ZOOM_DELAY = 1.5, -- Delay sebelum zoom (detik)

	-- Shake Settings
	SHAKE_INTENSITY = 0.8, -- Intensitas shake (0.1 = ringan, 1.0 = kuat)
	SHAKE_DURATION = 2.0, -- Durasi shake (detik)
	SHAKE_DELAY = 2.5, -- Delay sebelum shake (detik)

	-- Timing
	TOTAL_DURATION = 10.0, -- Total durasi cutscene (detik) - 10 SECONDS!

	-- Player Control
	LOCK_PLAYER = true -- Lock player movement saat cutscene
}

-- ===================================================================
-- ?? HELPER: FIND VFX ASSET WITH DEBUGGING
-- ===================================================================
local function findVFXAsset()
	print("?? [Cutscene] Searching for VFX asset 'ultimate'...")

	-- Try multiple possible locations (FIXED: FishingSystem first!)
	local searchPaths = {
		"ReplicatedStorage.FishingSystem.Assets.VFX.ultimate",  -- ? CORRECT PATH!
		"ReplicatedStorage.Assets.VFX.ultimate",
		"ReplicatedStorage.VFX.ultimate",
		"ReplicatedStorage.FishingSystem.VFX.ultimate",
		"ReplicatedStorage.Assets.ultimate"
	}

	for _, path in ipairs(searchPaths) do
		print(string.format("?? [Cutscene] Trying path: %s", path))

		local parts = string.split(path, ".")
		local current = game
		local success = true

		for i, part in ipairs(parts) do
			local next = current:FindFirstChild(part)
			if next then
				current = next
				print(string.format("  ? Found: %s", part))
			else
				print(string.format("  ? Not found: %s", part))
				success = false
				break
			end
		end

		if success then
			print(string.format("? [Cutscene] VFX asset found at: %s", path))
			return current
		end
	end

	warn("? [Cutscene] VFX asset 'ultimate' NOT FOUND in any location!")
	warn("? [Cutscene] Please verify asset exists in one of these locations:")
	for _, path in ipairs(searchPaths) do
		warn("  - " .. path)
	end

	return nil
end

-- ===================================================================
-- ?? FUNCTION: PLAY CUTSCENE
-- ===================================================================
function RareFishCutscene.PlayCutscene(bobberPosition, fishName)
	print("=================================================================")
	print(string.format("?? [Cutscene] STARTING for %s at position %s", fishName, tostring(bobberPosition)))
	print("=================================================================")

	local player = game.Players.LocalPlayer
	local character = player.Character
	if not character then 
		warn("?? [Cutscene] No character found, skipping cutscene")
		return 
	end

	local humanoid = character:FindFirstChild("Humanoid")
	local camera = workspace.CurrentCamera

	-- ===================================================================
	-- STEP 1: LOCK PLAYER (if enabled)
	-- ===================================================================
	local originalWalkSpeed = nil
	local originalJumpPower = nil

	if CONFIG.LOCK_PLAYER and humanoid then
		originalWalkSpeed = humanoid.WalkSpeed
		originalJumpPower = humanoid.JumpPower
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		print("?? [Cutscene] Player locked")
	end

	-- ===================================================================
	-- STEP 2: SPAWN VFX AT BOBBER + LAUNCH UPWARDS (PLASMA PROJECTILE)
	-- ===================================================================
	local vfxHolder = nil
	local vfxSuccess, vfxError = pcall(function()
		-- Find VFX asset
		local vfxAsset = findVFXAsset()

		if not vfxAsset then
			warn("?? [Cutscene] VFX asset not found - cutscene will continue without VFX")
			return
		end

		print("? [Cutscene] Cloning VFX asset...")
		local vfxClone = vfxAsset:Clone()
		print("? [Cutscene] VFX cloned successfully")

		-- ===================================================================
		-- CREATE HOLDER PART (ALWAYS USE THIS FOR RELIABILITY)
		-- ===================================================================
		vfxHolder = Instance.new("Part")
		vfxHolder.Name = "PlasmaVFXHolder"
		vfxHolder.Size = Vector3.new(CONFIG.VFX_SIZE, CONFIG.VFX_SIZE, CONFIG.VFX_SIZE)
		vfxHolder.Transparency = 1
		vfxHolder.Anchored = true
		vfxHolder.CanCollide = false
		vfxHolder.CFrame = CFrame.new(bobberPosition)
		vfxHolder.Parent = workspace

		print(string.format("? [Cutscene] Holder created at position: %s", tostring(bobberPosition)))

		-- ===================================================================
		-- PARENT VFX TO HOLDER (OPTIMIZED FOR PART WITH EMITTERS)
		-- ===================================================================
		if vfxClone:IsA("BasePart") then
			print("?? [Cutscene] VFX is a Part - PERFECT!")

			-- Set Part properties for visibility
			vfxClone.Anchored = true
			vfxClone.CanCollide = false
			vfxClone.CFrame = vfxHolder.CFrame

			-- Make Part visible if needed (optional glow)
			if vfxClone.Transparency >= 0.9 then
				print("   Making Part slightly visible for debugging...")
				vfxClone.Transparency = 0.5
				vfxClone.Material = Enum.Material.Neon
				vfxClone.Color = Color3.fromRGB(100, 200, 255)
			end

			vfxClone.Parent = vfxHolder

			print(string.format("   Part positioned at: %s", tostring(vfxClone.Position)))

		elseif vfxClone:IsA("Model") then
			print("?? [Cutscene] VFX is a Model")
			vfxClone.Parent = vfxHolder
			if vfxClone.PrimaryPart then
				vfxClone:SetPrimaryPartCFrame(vfxHolder.CFrame)
			end
		elseif vfxClone:IsA("Folder") or vfxClone:IsA("Configuration") then
			print("?? [Cutscene] VFX is a Folder/Configuration")
			vfxClone.Parent = vfxHolder
		else
			print(string.format("?? [Cutscene] VFX is a %s", vfxClone.ClassName))
			vfxClone.Parent = vfxHolder
		end

		-- ===================================================================
		-- ENABLE ALL PARTICLE EMITTERS (CRITICAL!)
		-- ===================================================================
		print("?? [Cutscene] Enabling ParticleEmitters...")
		local emitterCount = 0
		local emittersList = {}

		-- Check VFX clone descendants (Part and its children)
		for _, descendant in ipairs(vfxClone:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				-- Store original enabled state
				local wasEnabled = descendant.Enabled

				-- Enable emitter
				descendant.Enabled = true
				emitterCount = emitterCount + 1

				print(string.format("  ? Enabled: %s", descendant.Name))
				print(string.format("     Parent: %s (%s)", descendant.Parent.Name, descendant.Parent.ClassName))
				print(string.format("     Was Enabled: %s ? Now: true", tostring(wasEnabled)))
				print(string.format("     Rate: %d", descendant.Rate))
				print(string.format("     Lifetime: %.1f", descendant.Lifetime.Min))

				if descendant.Texture == "" then
					warn("     ?? WARNING: No texture set! Particles might be invisible!")
				else
					print(string.format("     Texture: %s", descendant.Texture))
				end

				table.insert(emittersList, descendant)
			end
		end

		-- Also check vfxClone itself if it's a Part
		if vfxClone:IsA("BasePart") then
			for _, child in ipairs(vfxClone:GetChildren()) do
				if child:IsA("ParticleEmitter") and not table.find(emittersList, child) then
					child.Enabled = true
					emitterCount = emitterCount + 1
					print(string.format("  ? Enabled: %s (direct child of Part)", child.Name))
					table.insert(emittersList, child)
				end
			end
		end

		print(string.format("?? [Cutscene] Total ParticleEmitters enabled: %d", emitterCount))

		if emitterCount == 0 then
			warn("?? [Cutscene] NO PARTICLE EMITTERS FOUND!")
			warn("?? [Cutscene] VFX asset might not contain any ParticleEmitters!")
			warn("?? [Cutscene] Plasma will be invisible!")

			-- List all descendants for debugging
			print("?? [Cutscene] VFX descendants:")
			for _, desc in ipairs(vfxClone:GetDescendants()) do
				print(string.format("  - %s (%s)", desc.Name, desc.ClassName))
			end
		else
			print(string.format("? [Cutscene] Found %d ParticleEmitter(s) - Plasma should be visible!", emitterCount))
		end

		-- ===================================================================
		-- MAKE VFX VISIBLE (ADD GLOW PART IF NO EMITTERS)
		-- ===================================================================
		if emitterCount == 0 then
			warn("?? [Cutscene] Adding visual fallback (glowing part)")

			local glowPart = Instance.new("Part")
			glowPart.Name = "FallbackGlow"
			glowPart.Size = Vector3.new(3, 3, 3)
			glowPart.Shape = Enum.PartType.Ball
			glowPart.Material = Enum.Material.Neon
			glowPart.Color = Color3.fromRGB(100, 200, 255)
			glowPart.Transparency = 0.3
			glowPart.Anchored = true
			glowPart.CanCollide = false
			glowPart.CFrame = vfxHolder.CFrame
			glowPart.Parent = vfxHolder

			-- Pulse effect
			local pulseTween = TweenService:Create(
				glowPart,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{Transparency = 0.7, Size = Vector3.new(5, 5, 5)}
			)
			pulseTween:Play()
		end

		print("? [Cutscene] VFX spawned successfully!")

		-- Store emittersList for cleanup
		vfxHolder:SetAttribute("EmitterCount", emitterCount)

		-- ===================================================================
		-- ?? LAUNCH PLASMA UPWARDS (PROJECTILE EFFECT)
		-- ===================================================================
		task.delay(CONFIG.VFX_LAUNCH_DELAY, function()
			if not vfxHolder or not vfxHolder.Parent then return end

			print("=================================================================")
			print("?? [Cutscene] LAUNCHING PLASMA UPWARDS!")
			print("=================================================================")

			local startPosition = bobberPosition
			local targetPosition = bobberPosition + Vector3.new(0, CONFIG.VFX_LAUNCH_HEIGHT, 0)

			print(string.format("?? [Cutscene] Launch trajectory:"))
			print(string.format("   Start: %s", tostring(startPosition)))
			print(string.format("   Target: %s", tostring(targetPosition)))
			print(string.format("   Height: %d studs", CONFIG.VFX_LAUNCH_HEIGHT))
			print(string.format("   Duration: %.1f seconds", CONFIG.VFX_LAUNCH_DURATION))

			-- Create launch tween (plasma menyembur ke atas)
			local launchTween = TweenService:Create(
				vfxHolder,
				TweenInfo.new(
					CONFIG.VFX_LAUNCH_DURATION, 
					Enum.EasingStyle.Quad, 
					Enum.EasingDirection.Out
				),
				{CFrame = CFrame.new(targetPosition)}
			)

			launchTween:Play()

			launchTween.Completed:Connect(function()
				print("? [Cutscene] Plasma reached peak height!")
			end)

			-- Add rotation for more dramatic effect
			local spinTween = TweenService:Create(
				vfxHolder,
				TweenInfo.new(
					2.0,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.InOut,
					-1 -- Infinite repeat
				),
				{CFrame = vfxHolder.CFrame * CFrame.Angles(0, math.rad(360), 0)}
			)
			spinTween:Play()

			print("?? [Cutscene] Plasma launched successfully!")
		end)
	end)

	if not vfxSuccess then
		warn("? [Cutscene] VFX spawn failed with error:")
		warn(tostring(vfxError))
		warn("? [Cutscene] Continuing without VFX...")
	end

	-- ===================================================================
	-- STEP 3: CAMERA ZOOM OUT (after delay)
	-- ===================================================================
	task.delay(CONFIG.ZOOM_DELAY, function()
		if camera.CameraType == Enum.CameraType.Custom then
			local originalFOV = camera.FieldOfView
			local targetFOV = originalFOV - CONFIG.ZOOM_OUT_AMOUNT

			print("=================================================================")
			print("?? [Cutscene] CAMERA ZOOM OUT")
			print(string.format("   Original FOV: %.1f", originalFOV))
			print(string.format("   Target FOV: %.1f", targetFOV))
			print(string.format("   Duration: %.1f seconds", CONFIG.ZOOM_DURATION))
			print("=================================================================")

			local zoomTween = TweenService:Create(
				camera,
				TweenInfo.new(CONFIG.ZOOM_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{FieldOfView = targetFOV}
			)

			zoomTween:Play()

			-- Zoom back in after cutscene
			task.delay(CONFIG.TOTAL_DURATION - CONFIG.ZOOM_DELAY - CONFIG.ZOOM_DURATION, function()
				print("?? [Cutscene] Zooming back in...")

				local zoomInTween = TweenService:Create(
					camera,
					TweenInfo.new(CONFIG.ZOOM_DURATION * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{FieldOfView = originalFOV}
				)
				zoomInTween:Play()
			end)
		end
	end)

	-- ===================================================================
	-- STEP 4: CAMERA SHAKE (after delay)
	-- ===================================================================
	task.delay(CONFIG.SHAKE_DELAY, function()
		print("=================================================================")
		print("?? [Cutscene] CAMERA SHAKE")
		print(string.format("   Intensity: %.2f", CONFIG.SHAKE_INTENSITY))
		print(string.format("   Duration: %.1f seconds", CONFIG.SHAKE_DURATION))
		print("=================================================================")

		local shakeStart = tick()
		local shakeConnection

		shakeConnection = RunService.RenderStepped:Connect(function()
			local elapsed = tick() - shakeStart

			if elapsed >= CONFIG.SHAKE_DURATION then
				shakeConnection:Disconnect()
				camera.CFrame = camera.CFrame -- Reset
				print("? [Cutscene] Shake complete")
				return
			end

			-- Shake effect with fade out
			local intensity = CONFIG.SHAKE_INTENSITY * (1 - (elapsed / CONFIG.SHAKE_DURATION))
			local offsetX = (math.random() - 0.5) * intensity * 2
			local offsetY = (math.random() - 0.5) * intensity * 2
			local offsetZ = (math.random() - 0.5) * intensity * 2

			camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
		end)
	end)

	-- ===================================================================
	-- STEP 5: CLEANUP VFX (after duration)
	-- ===================================================================
	if vfxHolder then
		task.delay(CONFIG.VFX_DURATION, function()
			print("?? [Cutscene] Starting VFX cleanup...")

			-- Disable emitters first
			for _, descendant in ipairs(vfxHolder:GetDescendants()) do
				if descendant:IsA("ParticleEmitter") then
					descendant.Enabled = false
				end
			end

			-- Fade out holder
			if vfxHolder:FindFirstChild("FallbackGlow") then
				local fadeTween = TweenService:Create(
					vfxHolder.FallbackGlow,
					TweenInfo.new(1.0),
					{Transparency = 1}
				)
				fadeTween:Play()
			end

			-- Destroy after particles fade
			task.wait(2)
			if vfxHolder and vfxHolder.Parent then
				vfxHolder:Destroy()
				print("? [Cutscene] VFX cleaned up")
			end
		end)
	end

	-- ===================================================================
	-- STEP 6: WAIT FOR CUTSCENE TO COMPLETE
	-- ===================================================================
	print(string.format("?? [Cutscene] Waiting %.1f seconds for cutscene to complete...", CONFIG.TOTAL_DURATION))
	task.wait(CONFIG.TOTAL_DURATION)

	-- ===================================================================
	-- STEP 7: UNLOCK PLAYER
	-- ===================================================================
	if CONFIG.LOCK_PLAYER and humanoid then
		humanoid.WalkSpeed = originalWalkSpeed or 16
		humanoid.JumpPower = originalJumpPower or 50
		print("?? [Cutscene] Player unlocked")
	end

	print("=================================================================")
	print(string.format("? [Cutscene] COMPLETE for %s", fishName))
	print("=================================================================")
end

-- ===================================================================
-- ?? FUNCTION: CHECK IF FISH SHOULD TRIGGER CUTSCENE
-- ===================================================================
function RareFishCutscene.ShouldPlayCutscene(fishRarity)
	-- Only play for Unknown rarity fish
	return fishRarity == "Unknown"
end

-- ===================================================================
-- ?? FUNCTION: UPDATE CONFIG (Optional - for customization)
-- ===================================================================
function RareFishCutscene.SetConfig(newConfig)
	for key, value in pairs(newConfig) do
		if CONFIG[key] ~= nil then
			CONFIG[key] = value
			print(string.format("?? [Cutscene] Config updated: %s = %s", key, tostring(value)))
		end
	end
end

function RareFishCutscene.GetConfig()
	return CONFIG
end

print("? [RareFishCutscene] Module loaded successfully!")

return RareFishCutscene