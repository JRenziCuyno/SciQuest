local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local Monster = game.ReplicatedStorage.Monster

local DialogueGui = player.PlayerGui:WaitForChild("DialogueGui")

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)

local EarCanalTheme = game.SoundService.EarCanal
local LobbyTheme = game.SoundService["Lobby Theme"]

local GiveCoins = game.ReplicatedStorage.GiveCoin

local Blink = require(game.ReplicatedStorage.BlinkTransition)

local Yap = Dialogue.new(DialogueGui)

local ToYap = {
	{"Awesome work!", 0.25};
	{"You guided the sound safely through the tunnel.", 1};
	{"That’s what your ear canal does.", 1};
	{"it carries sound to the eardrum and keeps it safe from dirt!", 1}
}

local Touched = {}
local Complete = false

local Canal = {}
Canal.__index = Canal

type CanalChallenge = typeof(Canal) & {
	Cavern: Instance | Folder;
	Prompt: ProximityPrompt;

	MonsterTrigger: Folder;
	MonsterSpawn: Folder;
	GoalFolder: Folder;
	EarflapGui: ScreenGui;
	
	Goal1: BasePart;
	Goal2: BasePart;
	
	EndTrigger: BasePart;
	Orb: BasePart;
	
	PreviousBillboard: BillboardGui;
	
	Running: boolean;
	
	MonstersLeft: number;
	Connections: {[any]: RBXScriptConnection};
}

function Canal.new(...)
	local self: CanalChallenge = setmetatable({}, Canal)
	local Params = {...}

	self.Cavern = Params[1]
	self.MonsterTrigger = Params[2]
	self.Prompt = Params[3]

	self.MonsterSpawn = self.Cavern:WaitForChild("MonsterSpawn")
	self.Orb = self.Cavern:WaitForChild("GlowingOrb")
	self.EndTrigger = self.Cavern:WaitForChild("Trigger")
	self.GoalFolder = self.Cavern:WaitForChild("GoalFolder")
	
	self.Goal1 = self.GoalFolder:WaitForChild("Goal1")
	self.Goal2 = self.GoalFolder:WaitForChild("Goal2")
	
	self.Running = false
	
	self.MonstersLeft = 0

	self.Connections = {}

	return self
end

function Canal.Start(self: CanalChallenge)
	if player:GetAttribute("InChallenge") then
		return
	end
	
	LobbyTheme:Pause()
	EarCanalTheme:Play()
	
	player:SetAttribute("Clear", true)
	player:SetAttribute("InChallenge", true)
	Complete = false
	
	self:OrbFollow()

	self:SetupTrigger()	
end

function Canal.SetupTrigger(self: CanalChallenge)	
	for _, v in self.MonsterTrigger:GetChildren() do
		self.Connections[v] = v.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Character) then
				if player:GetAttribute("Clear") then
					player:SetAttribute("Clear", false)

					self:SpawnMonster(v)

					self.Connections[v]:Disconnect()
					self.Connections[v] = nil
				end
			end
		end)
	end
	
	self.Connections[self.EndTrigger] = self.EndTrigger.Touched:Connect(function(hit)
		if hit:IsDescendantOf(Character) then
			local MonsterFolder = workspace.Monsters:GetChildren()
			
			if #MonsterFolder > 0 then
				return
			end
			
			if not Touched[Character] then
				Touched[Character] = true
				
				self.Connections[self.EndTrigger]:Disconnect()
				self.Connections[self.Orb]:Disconnect()
				self.Running = false

				self.Connections["Goal"] = RunService.PreRender:Connect(function()
					local Magnitude = (self.Goal1.Position - self.Orb.Position).Magnitude

					if Magnitude >= 1 then
						self.Orb.CFrame = self.Orb.CFrame:Lerp(self.Goal1.CFrame,0.075)
					else
						self.Connections["Goal"]:Disconnect()

						self.Connections["Goal"] = RunService.PreRender:Connect(function()
							local Magnitude = (self.Goal2.Position - self.Orb.Position).Magnitude

							if Magnitude >= 1 then
								self.Orb.CFrame = self.Orb.CFrame:Lerp(self.Goal2.CFrame,0.075)
							else
								if not Complete then
									Complete = true
									GiveCoins:FireServer()
									self:Disconnect()
									self:Emit()
									game.SoundService.GoalSound:Play()
								end
							end
						end)
					end
				end)
			end
		end
	end)
end

function Canal.SpawnMonster(self: CanalChallenge, Trigger: BasePart)
	if self.PreviousBillboard then
		self.PreviousBillboard.Enabled = false
	end
	
	local level = Trigger:GetAttribute("level")
	local MonsterSpawn = self.MonsterSpawn[level]
	
	self.MonstersLeft = #MonsterSpawn:GetChildren()

	for i = 1,#MonsterSpawn:GetChildren() do
		local NewMonster = Monster:Clone()
		NewMonster.Parent = workspace.Monsters
		NewMonster:PivotTo(MonsterSpawn[i].CFrame)
		
		local MonsterHumanoid = NewMonster:WaitForChild("Humanoid")
		
		local Rate = 0
		
		self.Connections[NewMonster] = RunService.PreRender:Connect(function(dt)
			Rate += dt
			
			if Rate <= (1/15) then
				return
			end

			Rate = 0
			
			MonsterHumanoid:MoveTo(Character.PrimaryPart.Position)
			
			if MonsterHumanoid.Health <= 0 then
				self.Connections[NewMonster]:Disconnect()
				self.MonstersLeft -= 1
				
				if self.MonstersLeft <= 0 then
					local GoalPart = Trigger:WaitForChild("GoalPart")
					self.PreviousBillboard = GoalPart:WaitForChild("Billboard")
					self.PreviousBillboard.Enabled = true
					player:SetAttribute("Clear", true)
				end
			end
		end)
	end
end

function Canal.Emit(self: CanalChallenge)
	for _, v in self.Goal1:WaitForChild("Attachment"):GetChildren() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end

function Canal.PlayRandomSound(self: CanalChallenge)
	if self.Running then
		local Particle = self.Orb:WaitForChild("NoteParticle")
		local Sounds = self.Orb:WaitForChild("Sounds")
		local rng = Random.new()
		local Soundlength = #Sounds:GetChildren()

		Particle:Emit(1)
		Sounds[rng:NextInteger(1,Soundlength)]:Play()

		task.delay(15, function()
			self:PlayRandomSound()
		end)
	end
end

function Canal.OrbFollow(self: CanalChallenge)
	self.Orb.Anchored = false
	self.Running = true

	self.Connections[self.Orb] = RunService.PreRender:Connect(function()
		local PrimaryCFrame = Character.PrimaryPart.CFrame
		local LookVector = PrimaryCFrame.LookVector
		self.Orb.CFrame = self.Orb.CFrame:Lerp(PrimaryCFrame - LookVector * 3, 0.05)
	end)
	
	task.delay(5, function()
		self:PlayRandomSound()
	end)
end

function Canal.Disconnect(self: CanalChallenge)
	if self.PreviousBillboard then
		self.PreviousBillboard.Enabled = false
		self.PreviousBillboard = nil
	end
	
	EarCanalTheme:Stop()
	LobbyTheme:Play()
	
	self.Prompt.Enabled = true
	player:SetAttribute("InChallenge", false)
	
	for _, v in player.Backpack:GetChildren() do
		if not v:IsA("Tool") then continue end
		v:Destroy()
	end
	
	for _, v in Character:GetChildren() do
		if not v:IsA("Tool") then continue end
		v:Destroy()
	end
	
	Yap:ClickContinue(ToYap)
	
	task.delay(3, function()
		Blink(true)
		Character.PrimaryPart:PivotTo(workspace.SpawnPart.CFrame)
		Blink(false)
	end)
	
	if self.Connections then
		for _, v in self.Connections do
			v:Disconnect()
		end
		table.clear(self.Connections)
	end
	
	table.clear(Touched)
end

return Canal