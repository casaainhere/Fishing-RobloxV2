local SoundManager = {}
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")
local Debris = game:GetService("Debris")

-- Cache sounds
local soundsFolder = RepStorage:WaitForChild("Assets"):WaitForChild("Sound")
local sounds = {}

function SoundManager:Initialize()
	for _, soundName in {"Cast", "Success", "Reeling", "HookHit", "Tap"} do
		local sound = soundsFolder:FindFirstChild(soundName)
		if sound then
			sounds[soundName] = sound
		end
	end
end

function SoundManager:Play(soundName, volume)
	local sound = sounds[soundName]
	if not sound then return end

	local clone = sound:Clone()
	clone.Volume = volume or 0.5
	clone.Parent = workspace
	clone:Play()

	clone.Ended:Connect(function()
		clone:Destroy()
	end)

	Debris:AddItem(clone, 10)
end

return SoundManager
