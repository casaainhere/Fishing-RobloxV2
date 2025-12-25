-- RemoteEvent Setup for Global Fish Chat
-- LOKASI: ServerScriptService/Script/SetupChatEvents
-- PURPOSE: Auto-create all required RemoteEvents
-- RUN ONCE: This script creates events then can be disabled

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FishingSystem = ReplicatedStorage:WaitForChild("FishingSystem")

print("=================================================================")
print("?? [ChatSetup] Setting up Global Fish Chat RemoteEvents...")
print("=================================================================")

-- ===================================================================
-- CREATE REMOTE EVENTS
-- ===================================================================
local eventsToCreate = {
	"PublishFishCatch",        -- Client ? Server: Player caught fish
	"SendChatMessage",         -- Server ? Client: Display message
	"ReceiveChatNotification"  -- Server ? Client: Display notification (legacy)
}

for _, eventName in ipairs(eventsToCreate) do
	local existing = FishingSystem:FindFirstChild(eventName)

	if existing then
		print(string.format("? [ChatSetup] %s already exists", eventName))
	else
		local newEvent = Instance.new("RemoteEvent")
		newEvent.Name = eventName
		newEvent.Parent = FishingSystem
		print(string.format("? [ChatSetup] Created %s", eventName))
	end
end

print("=================================================================")
print("? [ChatSetup] Setup complete!")
print("   Created/Verified:")
for _, eventName in ipairs(eventsToCreate) do
	print("   - " .. eventName)
end
print("=================================================================")
print("??  You can now DISABLE this script (it only needs to run once)")
print("=================================================================")