local Replica = game:GetService('ReplicatedStorage')
local UIS = game:GetService('UserInputService')

Replica.GetDevice.OnClientInvoke = function()
	if UIS.TouchEnabled then
		return true
	else
		return false
	end
end