-- ReplicatedStorage/FishingModules/AnimationController
local AnimationController = {}
local RepStorage = game:GetService("ReplicatedStorage"):WaitForChild("FishingSystem")

local loadedAnimations = {}
local currentAnimation = nil
local animationsFolder

function AnimationController:Initialize(humanoid)
	animationsFolder = RepStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("Fishing")

	for _, animName in {"EquippedAnimation", "WaitingAnimation", "PullingAnimation"} do
		local anim = animationsFolder:FindFirstChild(animName)
		if anim and humanoid then
			loadedAnimations[animName] = humanoid:LoadAnimation(anim)
		end
	end
end

function AnimationController:Play(animationName, fadeTime)
	fadeTime = fadeTime or 0.1

	if currentAnimation then
		currentAnimation:Stop(fadeTime)
	end

	local anim = loadedAnimations[animationName]
	if anim then
		currentAnimation = anim
		currentAnimation:Play(fadeTime)
		return currentAnimation
	end
end

function AnimationController:Stop(fadeTime)
	fadeTime = fadeTime or 0.1

	if currentAnimation then
		currentAnimation:Stop(fadeTime)
		currentAnimation = nil
	end
end


function AnimationController:TransitionTo(animationName, fadeTime)
	fadeTime = fadeTime or 0.2

	if currentAnimation then
		currentAnimation:Stop(fadeTime)
	end

	task.wait(fadeTime)

	local anim = loadedAnimations[animationName]
	if anim then
		currentAnimation = anim
		currentAnimation:Play(fadeTime)
		return currentAnimation
	end
end

function AnimationController:Reload(humanoid)
	self:Stop()
	loadedAnimations = {}
	self:Initialize(humanoid)
end

return AnimationController