local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local Maze = workspace:WaitForChild("Maze")

local ReceivedItem = game.ReplicatedStorage.Events.ReceiveItem
local EmitParticles = require(game.ReplicatedStorage.EmitParticles)
local TumbleWeed = require(script.TumbleWeed)

local FallPart = workspace:WaitForChild("Fallpart")

local GiveCoins = game.ReplicatedStorage.GiveCoin

local EyelashesTheme = game.SoundService.Countdown
local LobbyTheme = game.SoundService["Lobby Theme"]

local bool = false

local Blur = game.Lighting.Blur

local DialogueGui = player.PlayerGui:WaitForChild("DialogueGui")

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)

local Yap = Dialogue.new(DialogueGui)

local ToYap = {
	{"You made it to the end!", 0.5};
	{"Just like the eyelash walls keep the dust away, your own eyelashes stop dirt and bugs from going into your eyes.", 2};
	{"Eyelashes are tiny protectors for your vision!", 0.75};
}

local Eyelash = {}
Eyelash.__index = Eyelash

type EyelashSystem = typeof(Eyelash) & {
	Obby: Instance;
	StartObby: RemoteEvent;
	EyelashFrame: Frame;
	Prompt: ProximityPrompt;
	
	MovingWalls: Folder;
	SpinningWalls: Folder;
	Info: TweenInfo;
	Trigger: BasePart;
	
	Checkpoint: BasePart;
	SpawnWall: BasePart;
	Eyelashes: BasePart;
	MaxBlur: number;
	Started: boolean;
	Spawnpart: BasePart;
	
	ExitButton: TextButton;
	
	Wind: Instance;
	Particle: ParticleEmitter;
	
	Image: ImageLabel;
	Wheel: ImageLabel;
	
	CurrentBlurNumber: number;
	
	Running: boolean;
	FloatEnabled: boolean;
	
	Binds: {any};
	Connections: {RBXScriptConnection};
	
	Walls: {[Instance]: Tween};
}

function Eyelash.new(...) : EyelashSystem
	local self: EyelashSystem = setmetatable({}, Eyelash)
	local Params = {...}
	
	self.Obby = Params[1]
	self.StartObby = Params[2]
	self.EyelashFrame = Params[3]
	self.Prompt = Params[4]
	
	for _, v in self.Obby:GetChildren() do
		self[v.Name] = v
	end
	
	self.Particle = self.Wind:FindFirstChildOfClass("ParticleEmitter")
	self.Image = self.EyelashFrame:WaitForChild("ImageLabel")
	self.Wheel = self.EyelashFrame:WaitForChild("Wheel")
	self.ExitButton = self.EyelashFrame:WaitForChild("ExitButton")
	
	self.Trigger = self.Obby.Parent:WaitForChild("Trigger")
	self.MovingWalls = self.Obby.Parent:WaitForChild("MovingWalls")
	self.SpinningWalls = self.Obby.Parent:WaitForChild("SpinningWalls")
	
	self.Checkpoint = self.Obby.Parent:WaitForChild("Checkpoint")
	
	self.FloatEnabled = false
	
	self.Info = TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
	
	self.MaxBlur = 100
	self.CurrentBlurNumber = 0
	
	self.Binds = {
		[Enum.KeyCode.A] = true;
		[Enum.KeyCode.D] = true;
	}
	
	self.Running = false
	
	self.Connections = {}
	self.Walls = {}
	
	return self
end

function Eyelash.Start(self: EyelashSystem)
	if self.Running then
		return
	end
	player:SetAttribute("Stage", 1)
	self.Spawnpart = self.Obby.Parent:WaitForChild("SpawnPart")
	
	self.Running = true
	
	LobbyTheme:Pause()
	EyelashesTheme:Play()
	
	self.Eyelashes.Transparency = 0
	player:SetAttribute("CanSprint", false)
	player:SetAttribute("InChallenge", true)
	
	TumbleWeed(true)
	
	if not self.Started then
		self.Started = true
		self.Particle.Enabled = true
		
		self.Connections[self.Connections] = self.Checkpoint.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Character) then
				self:Received()
			end
		end)
		
		self.Connections["FallPart"] = FallPart.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Character) then
				Character:PivotTo(self.Spawnpart.CFrame)
			end
		end)

		self:FloatEffect()

		self:ConfigureObby()
	end
end

function Eyelash.FloatEffect(self: EyelashSystem)
	if self.FloatEnabled then
		bool = not bool
		local GoalPos = bool and self.Eyelashes:GetAttribute("GoalIn") or self.Eyelashes:GetAttribute("GoalOut")
		local Info = TweenInfo.new(1, Enum.EasingStyle.Sine)
		TweenService:Create(self.Eyelashes, Info, {Position = GoalPos}):Play()
	end
	
	task.delay(1, function()
		self:FloatEffect()
	end)
end

function Eyelash.ConfigureObby(self: EyelashSystem): boolean
	local function IsHumanoid(hit)
		local Humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			return true
		else
			return false
		end
	end
	
	self.SpawnWall.Touched:Connect(function(hit)
		if IsHumanoid(hit) then
			self.SpawnWall.CanCollide = false
		end
	end)
	
	self.Connections[self.Trigger] = self.Trigger.Touched:Connect(function(hit)
		if hit:IsDescendantOf(Character) then
			self:Stage2()
			self.Connections[self.Trigger]:Disconnect()
			self.Connections[self.Trigger] = nil
		end
	end)
end

function Eyelash.Stage2(self: EyelashSystem)
	player:SetAttribute("Stage", 2)
	self.Spawnpart = self.Obby.Parent:WaitForChild("SpawnPart2")
	
	if self.Connections["FallPart"] then
		self.Connections["FallPart"]:Disconnect()
		self.Connections["FallPart"] = FallPart.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Character) then
				Character:PivotTo(self.Spawnpart.CFrame)
			end
		end)
	end
	
	for _, v in self.MovingWalls:GetChildren() do
		self.Walls[v] = TweenService:Create(v, TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true), {Position = v:GetAttribute("GoalPos")})
		self.Walls[v]:Play()
	end
	
	for _, v in self.SpinningWalls:GetChildren() do
		local t = 0
		self.Connections[v] = RunService.PreRender:Connect(function(dt)
			t += dt
			
			if t <= (1/60) then
				return
			end
			
			t = 0
			
			v.CFrame *= CFrame.Angles(0,math.rad(3), 0)
		end)
	end
end

function Eyelash.RewardPopup(self: EyelashSystem)
	GiveCoins:FireServer("Eyelashes")
	
	self.EyelashFrame.Visible = true
	TweenService:Create(self.EyelashFrame, self.Info, {Size = self.EyelashFrame:GetAttribute("GoalIn")}):Play()
	self.Connections["Wheel"] = RunService.PreRender:Connect(function()
		self.Wheel.Rotation += 0.1
	end)

	local Secondsleft = 5

	for i = 1,5 do
		Secondsleft -= 1
		self.ExitButton.Text = Secondsleft
		task.wait(1)
	end

	self.ExitButton.Text = `X`

	self.ExitButton.Activated:Once(function()
		TweenService:Create(self.EyelashFrame, self.Info, {Size = self.EyelashFrame:GetAttribute("GoalOut")}):Play()
		Yap:ClickContinue(ToYap)
		task.delay(0.5, function()
			self.Connections["Wheel"]:Disconnect()
			table.clear(self.Connections)
			self.EyelashFrame.Visible = false
		end)
	end)
end

function Eyelash.Received(self: EyelashSystem)
	player:SetAttribute("InChallenge", false)
	
	if self.Connections then
		for i, v in self.Connections do
			v:Disconnect()
		end
		table.clear(self.Connections)
	end
	
	if self.Walls then
		for i, v in self.Walls do
			v:Cancel()
			i.Position = i:GetAttribute("OldPos")
		end
		table.clear(self.Walls)
	end
	
	LobbyTheme:Play()
	EyelashesTheme:Stop()
	
	self.Eyelashes.Transparency = 1
	EmitParticles()
	TumbleWeed(false)
	
	self.Running = false
	self.Prompt.Enabled = true

	player:SetAttribute("CanSprint", true)
	self.Particle.Enabled = false
	
	self:RewardPopup()
end

return Eyelash
