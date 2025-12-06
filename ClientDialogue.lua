-- services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--modules
local DialogModule = require(ReplicatedStorage.DialogModule)

local EarflapChallenge

--references
local player = game.Players.LocalPlayer
local npc = script.Parent -- Reference to the NPC model
local npcGui = npc:WaitForChild("Head"):WaitForChild("gui")
local prompt = npc:WaitForChild("ProximityPrompt")
local Character = player.Character or player.CharacterAdded:Wait()

local Interacted = false

local dialogObject = DialogModule.new("Showcase NPC", npc, prompt)
dialogObject:addDialog("Do you want to know how your ears work?", {})
dialogObject:addDialog("They catch sounds and help you hear everything around you!", {})
dialogObject:addDialog("Go to the forest and find the Sound Keeper to start your first hearing adventure!", {})

--

-- what happens when triggered
prompt.Triggered:Connect(function(player)
	pcall(function()
		local UnlockArea = game.ReplicatedStorage:WaitForChild("UnlockArea")
		UnlockArea:FireServer("EarsLobby")
		local EarsPart = workspace:WaitForChild("LockedAreas"):FindFirstChild("EarsLobby")
		EarsPart:Destroy()
	end)
	Character.PrimaryPart.Anchored = true
	
	dialogObject:triggerDialog(player, 1, 2)
	dialogObject:triggerDialog(player, 2, 2.5)
	dialogObject:triggerDialog(player, 3, 3)
	Character.PrimaryPart.Anchored = false
end)