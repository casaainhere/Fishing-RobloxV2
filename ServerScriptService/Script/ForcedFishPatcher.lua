-- AUTO-PATCHER: Replace FishingConfig with ForcedFishHandler
-- LOKASI: ServerScriptService/Script/ForcedFishPatcher
-- TYPE: Script
-- RUN ONCE: Script ini akan auto-patch semua LocalScript yang pakai FishingConfig

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

print("?? [ForcedFishPatcher] Starting auto-patch...")

-- ===================================================================
-- ?? FIND ALL LOCALSCRIPTS THAT USE FishingConfig
-- ===================================================================
local function findAndPatchScripts()
	local patchedCount = 0
	local scriptsToPatch = {}

	-- Search in common locations
	local searchLocations = {
		ServerStorage:FindFirstChild("AllRods"),
		ReplicatedStorage:FindFirstChild("FishingSystem"),
		game:GetService("StarterPlayer"):FindFirstChild("StarterCharacterScripts"),
		game:GetService("StarterPlayer"):FindFirstChild("StarterPlayerScripts"),
		game:GetService("StarterPack")
	}

	for _, location in ipairs(searchLocations) do
		if location then
			for _, descendant in ipairs(location:GetDescendants()) do
				if descendant:IsA("LocalScript") or descendant:IsA("Script") then
					local source = descendant.Source

					-- Check if script uses FishingConfig
					if string.find(source, "require.*FishingConfig") or 
						string.find(source, "FishingConfig%.RollFish") or
						string.find(source, "FishingConfig%.GenerateFishWeight") then
						table.insert(scriptsToPatch, descendant)
					end
				end
			end
		end
	end

	-- Patch each script
	for _, script in ipairs(scriptsToPatch) do
		local success, err = pcall(function()
			local source = script.Source
			local originalSource = source

			-- Replace require FishingConfig with ForcedFishHandler
			source = string.gsub(source, 
				"require%((.-)FishingConfig%)", 
				"require(%1FishingModules.ForcedFishHandler)")

			source = string.gsub(source,
				'require%("(.-)FishingConfig"%)',
				'require("%1FishingModules.ForcedFishHandler")')

			-- Only update if changed
			if source ~= originalSource then
				script.Source = source
				patchedCount = patchedCount + 1
				print(string.format("? [Patcher] Patched: %s", script:GetFullName()))
			end
		end)

		if not success then
			warn(string.format("?? [Patcher] Failed to patch %s: %s", script:GetFullName(), tostring(err)))
		end
	end

	return patchedCount
end

-- ===================================================================
-- ?? RUN PATCHER
-- ===================================================================
task.wait(2) -- Wait for game to load

local patched = findAndPatchScripts()

if patched > 0 then
	print(string.format("? [ForcedFishPatcher] Successfully patched %d script(s)!", patched))
	print("?? [ForcedFishPatcher] Forced fish system is now active!")
else
	warn("?? [ForcedFishPatcher] No scripts found to patch.")
	warn("?? [ForcedFishPatcher] Manual integration required - see guide below:")
	print([[
	
	MANUAL INTEGRATION:
	
	1. Find your fishing client script (LocalScript in Rod)
	2. Find this line:
	   local FishingConfig = require(...)
	
	3. Replace with:
	   local FishingConfig = require(ReplicatedStorage.FishingSystem.FishingModules.ForcedFishHandler)
	
	That's it! No other changes needed.
	]])
end

-- ===================================================================
-- ?? CLEANUP: Disable this script after first run
-- ===================================================================
script.Disabled = true