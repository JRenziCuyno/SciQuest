local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local ProfileStore = require(script.ProfileStore)
local Template = require(script.Template)
local DataManager = require(script.DataManager)
local Players = game:GetService("Players")

local CurrentSpawnLocation = {}
local Loaded = {}
local CoinEvent = game.ReplicatedStorage.GiveCoin
local LocationEvent = game.ReplicatedStorage.UpdateLocation
local UpdateCoin = game.ReplicatedStorage.UpdateCoin
local PurchaseEvent = game.ReplicatedStorage.Events.Purchase
local Purchased = {}

PhysicsService:RegisterCollisionGroup("BodyPart")
PhysicsService:RegisterCollisionGroup("Barrier")
PhysicsService:CollisionGroupSetCollidable("BodyPart", "BodyPart", false)
PhysicsService:CollisionGroupSetCollidable("BodyPart", "Barrier", true)

local function GetStoreName()
	return RunService:IsStudio() and "Test" or "Live"
end

local PlayerProfile = ProfileStore.New(GetStoreName(), Template)

local function PlayerJoined(player: Player, profile: typeof(PlayerProfile:StartSessionAsync()))
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local Cash = Instance.new("IntValue")
	Cash.Name = "Cash"
	Cash.Value = profile.Data.Cash
	Cash.Parent = leaderstats
	
	CurrentSpawnLocation[player] = profile.Data.Location
end

local function LoadProfile(player: Player)
	local Profile = PlayerProfile:StartSessionAsync("Player_l" .. player.UserId, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if Profile then

		Profile:AddUserId(player.UserId)
		Profile:Reconcile()

		if not Profile:IsActive() then
			player:Kick("Profile not active. Please rejoin.")
			return
		end

		if RunService:IsStudio() then
			PlayerProfile.Mock = true
		end

		Profile.OnSessionEnd:Connect(function()
			DataManager.Profiles[player] = nil
			player:Kick("Data error occured, from onsession end")
		end)

		if player.Parent == Players then

			DataManager.Profiles[player] = Profile
			PlayerJoined(player, Profile)
		else
			Profile:EndSession()
		end
	else
		player:Kick("Data error occured, Please rejoin")
	end
	
	return Profile
end

local function PlayerAdded(player: Player)
	local profile
	
	player.CharacterAdded:Connect(function(Character)
		if not Loaded[player] then
			profile = LoadProfile(player)
			Loaded[player] = true
		end
		
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
		local SpawnLocations = workspace:WaitForChild("SpawnLocations")

		if profile then
			local ClothesStore = workspace:WaitForChild("ClothesStore")
			local Character = player.Character or player.CharacterAdded:Wait()

			local ClassName = {
				["Pants"] = true;
				["Shirt"] = true;
				["Accessory"] = true;
			}

			for _, v in Character:GetDescendants() do
				if v:IsA("BasePart") then
					v.CollisionGroup = "BodyPart"
				end
				
				if not profile.Data[v.ClassName] or profile.Data[v.ClassName] == "" then
					continue
				end

				v:Destroy()
			end

			for _, v in ClothesStore:GetDescendants() do
				if ClassName[v.ClassName] then
					if v.Name ~= profile.Data[v.ClassName] then
						continue
					end

					local NewThing = v:Clone()
					NewThing.Parent = Character
				end
			end
		end
		
		if CurrentSpawnLocation[player] and CurrentSpawnLocation[player] ~= "" then
			task.wait(1)
			local LocationToSpawn = SpawnLocations[CurrentSpawnLocation[player]]
			HumanoidRootPart:PivotTo(LocationToSpawn.CFrame)
		end
		
		local UnlockArea = game.ReplicatedStorage.UnlockArea
		
		UpdateCoin:FireClient(player)
		UnlockArea:FireClient(player, profile.Data.UnlockedArea)
	end)
	
	task.wait(2)
end

local function PlayerRemoving(player: Player)
	local profile = DataManager.Profiles[player]
	
	if Purchased[player] then
		for _, v in Purchased[player] do
			if v then
				DataManager.AddGold(player, 100)
			end
		end
		table.clear(Purchased[player])
	end
	
	if not profile then
		return
	end

	profile:EndSession()
	DataManager.Profiles[player] = nil
end

game.Players.PlayerAdded:Connect(PlayerAdded)

game.Players.PlayerRemoving:Connect(PlayerRemoving)

CoinEvent.OnServerEvent:Connect(function(player: Player, Str: string?)
	DataManager.AddGold(player, 50)
	UpdateCoin:FireClient(player)
	
	if Str then
		DataManager.UpdateLocation(player, Str)
	end
end)

LocationEvent.OnServerEvent:Connect(function(player, Location: string)
	local profile = DataManager.Profiles[player]
	if profile then
		profile.Data.Location = Location
	end
end)

PurchaseEvent.OnServerInvoke = function(player: Player, v: Instance)
	local Character = player.Character or player.CharacterAdded:Wait()
	local Cash = player.leaderstats.Cash
	local rig = v.Parent.Parent.Rig
	
	if not Purchased[player] then
		Purchased[player] = {}
	end
	
	if Cash.Value >= 100 then
		if not Purchased[player][v] then
			Purchased[player][v] = true
			DataManager.SubtractGold(player, 100)
			UpdateCoin:FireClient(player)
		end
		
		if v.Parent.Name == "HAT_SIGN" then
			local Hat = rig:FindFirstChildOfClass("Accessory")

			for _, v in Character:GetDescendants() do
				if v:IsA("Accessory") then
					v:Destroy()
				end
			end

			local NewHat = Hat:Clone()
			NewHat.Parent = Character

			DataManager.UpdateAccessory(player, Hat)
		elseif v.Parent.Name == "OUTFIT_SIGN" then
			for _, v in Character:GetDescendants() do
				if v:IsA("Pants") or v:IsA("Shirt") then
					v:Destroy()
				end
			end

			local Shirt = rig:FindFirstChildOfClass("Shirt")
			local Pants = rig:FindFirstChildOfClass("Pants")

			local NewShirt = Shirt:Clone()
			local NewPants = Pants:Clone()

			NewShirt.Parent = Character
			NewPants.Parent = Character

			DataManager.UpdateAccessory(player, NewShirt)
			DataManager.UpdateAccessory(player, NewPants)
		end
		
		return true
	end
end
