-- Place in ServerScriptService
-- CustomChatChannels - Global allows chat but only system messages go cross-server

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

task.wait(1)

-- Get or create the default General channel
local generalChannel = TextChatService:WaitForChild("TextChannels"):FindFirstChild("RBXGeneral")
if not generalChannel then
	generalChannel = Instance.new("TextChannel")
	generalChannel.Name = "RBXGeneral"
	generalChannel.Parent = TextChatService.TextChannels
end

-- Create Global Alerts channel
local globalChannel = TextChatService.TextChannels:FindFirstChild("Global")
if not globalChannel then
	globalChannel = Instance.new("TextChannel")
	globalChannel.Name = "Global"
	globalChannel.Parent = TextChatService.TextChannels
end

-- Configure chat window
local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
if not chatWindow then
	chatWindow = Instance.new("ChatWindowConfiguration")
	chatWindow.Parent = TextChatService
end
chatWindow.Enabled = true

-- Configure chat input bar (allow both channels)
local chatInputBar = TextChatService:FindFirstChild("ChatInputBarConfiguration")
if not chatInputBar then
	chatInputBar = Instance.new("ChatInputBarConfiguration")
	chatInputBar.Parent = TextChatService
end
chatInputBar.Enabled = true
chatInputBar.TargetTextChannel = generalChannel -- Default to General

-- Add players to channels
local function addPlayerToChannels(player)
	task.wait(0.5)

	-- Add to General channel
	pcall(function()
		generalChannel:AddUserAsync(player.UserId)
	end)

	-- Add to Global channel (players CAN chat here)
	pcall(function()
		globalChannel:AddUserAsync(player.UserId)
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(addPlayerToChannels, player)
end

Players.PlayerAdded:Connect(addPlayerToChannels)