local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService('RunService')

local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local PlayerGui = player.PlayerGui
local DialogueGui = PlayerGui:WaitForChild("DialogueGui")

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)

local EyebrowTheme = game.SoundService.Countdown
local LobbyTheme = game.SoundService["Lobby Theme"]

local Yap = Dialogue.new(DialogueGui)

local GiveCoins = game.ReplicatedStorage.GiveCoin

local ToYap = {
	{"Great job! You kept the eye dry.", 1};
	{"That’s what your eyebrows do every day.", 1};
	{"they stop sweat and rain from running into your eyes.", 1.25};
	{"Eyebrows are tiny shields for your vision!", 1};
}

local Eyelashes = require(script.Parent.Eyelashes)
local EyelashGui = PlayerGui:WaitForChild("EyelashGui")
local EyelashFrame = EyelashGui:WaitForChild("Frame")

local EmitParticle = require(game.ReplicatedStorage.EmitParticles)

local Obby = workspace:WaitForChild("Obby")
local SpawnPart = Obby:WaitForChild("SpawnPart")

local StartObby = game.ReplicatedStorage.Events.StartObby

local RainDrop = game.ReplicatedStorage.RainDrop

local Blur = game.Lighting.Blur

local bool = false
local Running = true

local ReceivedPrize = {}

local Eyebrow = {}
Eyebrow.__index = Eyebrow

type EyebrowChallenge = typeof(Eyebrow) & {
	Obby: Instance;
	EyeGui: ScreenGui;
	Prompt: ProximityPrompt;

	Frame: Frame;
	HealthBar: Frame;
	EyebrowInfo: Frame;
	Wheel: ImageLabel;
	
	Frame2: Frame;

	Info: TweenInfo;
	UIInfo: TweenInfo;
	ExitButton: TextButton;

	Barriers: Folder;
	Safezones: Folder;
	EyebrowMesh: BasePart;
	RainDamages: Folder;
	CheckPoint: BasePart;
	SpawnPart: BasePart;
	RainEffect: ParticleEmitter;

	Eyeball: BasePart;
	
	LabelCount: TextLabel;

	Raining: boolean;
	SafeZone: boolean;
	FloatEnabled: boolean;

	Health: number;
	MaxHealth: number;
	CurrentBlurNumber: number;
	MaxBlur: number;
	MinSpeed: number;
	MaxSpeed: number;
	
	HitAmount: number;

	Binds: {Enum.KeyCode};
	Connections: {RBXScriptConnection};
	RainDrops: {any};
	Rates: {number};
}

function Eyebrow.new(...)
	local self: EyebrowChallenge = setmetatable({}, Eyebrow)
	local Params = {...}

	self.Obby = Params[1]
	self.EyeGui = Params[2]
	self.Prompt = Params[3]
	
	self.Barriers = self.Obby:WaitForChild("Barriers")

	self.SpawnPart = self.Obby:WaitForChild("SpawnPart")
	self.EyebrowMesh = self.Obby:WaitForChild("Eyebrow")
	self.RainDamages = self.Obby:WaitForChild("RainDamage")
	self.CheckPoint = self.Obby:WaitForChild("Checkpoint")
	self.EyeBall = self.Obby:WaitForChild("Eyeball")

	self.Frame = self.EyeGui:WaitForChild("Frame")
	self.HealthBar = self.Frame:WaitForChild("Frame"):WaitForChild("HealthBar")

	self.EyebrowInfo = self.EyeGui:WaitForChild("EyebrowInfo")
	self.Wheel = self.EyebrowInfo:WaitForChild("Wheel")
	self.ExitButton = self.EyebrowInfo:WaitForChild("ExitButton")
	
	self.Frame2 = self.EyeGui:WaitForChild("Frame2")
	
	self.LabelCount = self.Frame2:WaitForChild("Count")

	self.FloatEnabled = true

	self.Health = 100
	self.MaxHealth = 100
	self.CurrentBlurNumber = 0
	self.MaxBlur = 80
	
	self.HitAmount = 0
	
	self.MinSpeed = 3
	self.MaxSpeed = 2

	self.Info = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	self.UIInfo = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	self.Connections = {}
	self.RainDrops = {}
	self.Rates = {}

	return self
end

function Eyebrow.SetupChildren(self: EyebrowChallenge)
	for _, v in self.Obby:GetChildren() do
		if v:IsA("BasePart") then
			self[v.Name] = v
		end
	end
end

function Eyebrow.Start(self: EyebrowChallenge)
	if self.Connections then
		self:Disconnect()
	end
	
	EyebrowTheme:Play()
	LobbyTheme:Pause()
	
	for _, v in self.Barriers:GetChildren() do
		v.CanCollide = true
		v.Transparency = 0.5
	end
	
	self.HitAmount = 0
	self.LabelCount.Text = `Raindrop Blocked: 0/20`
	
	self.EyebrowMesh.Transparency = 0

	player:SetAttribute("CanSprint", false)
	player:SetAttribute("InChallenge", true)

	self.EyeGui.Enabled = true

	self.FloatEnabled = true

	Running = true
	self:VisibleCharacters(true)

	self:FloatEffect()

	self:SpawnRainDrop()
	
	self:GetShield()
end

function Eyebrow.GetShield(self: EyebrowChallenge)
	local Shield = game.ReplicatedStorage.EyebrowShield:Clone()
	Shield.Parent = player.Backpack
end

function Eyebrow.VisibleCharacters(self: EyebrowChallenge, boolean: boolean)
	for _, v in game.Players:GetChildren() do
		if v.Character and v.Character ~= Character then
			for _, parts in v.Character:GetChildren() do
				if parts.Parent:IsA("Tool") or v.Name == "HumanoidRootPart" then
					continue
				end
				
				if parts:IsA("BasePart") then
					if boolean then
						parts.Transparency = 0.75
					else
						parts.Transparency = 0
					end
				end
			end
		end
	end
end

function Eyebrow.HitEffect(self: EyebrowChallenge, Eyeball)
	local Highlight = Instance.new("Highlight")
	Highlight.FillColor = Color3.new(1,0,0)
	Highlight.FillTransparency = 0
	Highlight.OutlineTransparency = 1
	Highlight.Adornee = Eyeball
	Highlight.Parent = Eyeball

	TweenService:Create(Highlight, TweenInfo.new(0.5), {FillTransparency = 1}):Play()
	task.delay(0.5, function()
		Highlight:Destroy()
	end)
end

function Eyebrow.UpdateUI(self: EyebrowChallenge)
	local ClampedHealth = math.clamp(self.Health / self.MaxHealth, 0 ,1)
	local ClampedBlurSize = math.clamp(self.CurrentBlurNumber / self.MaxBlur, 0 , 24)

	TweenService:Create(self.HealthBar, self.UIInfo, {Size = UDim2.fromScale(ClampedHealth,1)}):Play()
	TweenService:Create(Blur, self.UIInfo, {Size = ClampedBlurSize}):Play()
end

function Eyebrow.Checkpoint(self: EyebrowChallenge)
	self:RemoveItem()
	
	self.Connections["Checkpoint"] = self.CheckPoint.Touched:Connect(function(hit)
		if hit:IsDescendantOf(Character) then
			if not ReceivedPrize[player] then
				ReceivedPrize[player] = true
				self.EyeGui.Enabled = true
				self.EyebrowInfo.Visible = true
				self.Prompt.Enabled = true
				
				self.EyebrowMesh.Transparency = 1
				self.FloatEnabled = false
				
				GiveCoins:FireServer("Eyebrow")
				Eyelashes.new(Obby, StartObby, EyelashFrame)
				EmitParticle()
				
				self.Connections["Wheel"] = RunService.PreRender:Connect(function()
					self.Wheel.Rotation += 0.1
				end)
				
				TweenService:Create(self.EyebrowInfo, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = self.EyebrowInfo:GetAttribute("GoalIn")}):Play()

				local secondsleft = 5
				
				for i = 1,5 do
					secondsleft -= 1
					self.ExitButton.Text = secondsleft
					task.wait(1)
				end
				
				self.ExitButton.Text = "X"
				
				self.ExitButton.MouseButton1Click:Once(function()
					TweenService:Create(self.EyebrowInfo, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.In), {Size = self.EyebrowInfo:GetAttribute("GoalOut")}):Play()
					Yap:ClickContinue(ToYap)
					task.delay(0.5, function()
						self.Connections["Wheel"]:Disconnect()
						self.Connections["Wheel"] = nil
						self.EyeGui.Enabled = false
					end)
				end)
				
			end
		end
	end)
end

function Eyebrow.FloatEffect(self: EyebrowChallenge)
	if self.FloatEnabled then
		bool = not bool

		if bool then
			TweenService:Create(self.EyebrowMesh, self.Info, {Position = self.EyebrowMesh:GetAttribute("GoalIn")}):Play()
		else
			TweenService:Create(self.EyebrowMesh, self.Info, {Position = self.EyebrowMesh:GetAttribute("GoalOut")}):Play()
		end

		task.delay(1, function()
			self:FloatEffect()
		end)
	end
end

function Eyebrow.GetRandomParent(self: EyebrowChallenge): BasePart
	return self.RainDamages[Random.new():NextInteger(1,3)]
end

function Eyebrow.SpawnRainDrop(self: EyebrowChallenge)
	local rng = Random.new()
	task.spawn(function()
		if Running then
			local Parent = self:GetRandomParent()
			local NewRainDrop = RainDrop:Clone()
			NewRainDrop.CFrame = Parent.CFrame
			NewRainDrop.Parent = Parent
			
			self.RainDrops[NewRainDrop] = NewRainDrop

			local Rate = 0

			self.Connections[NewRainDrop] = RunService.PreRender:Connect(function(dt)
				Rate += dt

				if Rate < (1/35) then
					return
				end

				Rate = 0

				NewRainDrop.CFrame = NewRainDrop.CFrame + NewRainDrop.CFrame.LookVector * 1.25

				for _, parts in workspace:GetPartsInPart(NewRainDrop) do
					if parts:IsDescendantOf(Character) and Character:FindFirstChild("EyebrowShield") then
						self.RainDrops[NewRainDrop]:Destroy()
						self.RainDrops[NewRainDrop] = nil
						
						self.Connections[NewRainDrop]:Disconnect()
						self.Connections[NewRainDrop] = nil
						
						self.HitAmount += 1
						self.LabelCount.Text = `Raindrop Blocked: {self.HitAmount}/20`

						for _, v in self.Barriers:GetChildren() do
							if self.HitAmount >= v:GetAttribute("TargetAmount") then
								v.CanCollide = false
								v.Transparency = 1
							end
						end
						
						if self.HitAmount >= 20 then
							self:Disconnect()
							self:Checkpoint()
							self.LabelCount.Text = `Challenge Complete!`
						elseif self.HitAmount >= 12 then
							self.MinSpeed = 2
							self.MaxSpeed = 2.25
						elseif self.HitAmount >= 5 then
							self.MinSpeed = 2
							self.MaxSpeed = 2.5
						else
							self.MinSpeed = 3
							self.MaxSpeed = 2
						end
						
						self:Knockback()
						return
					elseif parts == self.Eyeball or parts.Name == "Eyeball" then
						self.RainDrops[NewRainDrop]:Destroy()
						self.RainDrops[NewRainDrop] = nil
						
						self.Connections[NewRainDrop]:Disconnect()
						self.Connections[NewRainDrop] = nil

						self.Health -= 20
						self:UpdateUI()

						self:HitEffect(parts)

						if self.Health <= 0 then
							self.Health = 100
							
							self.HitAmount = 0
							self.MinSpeed = 3
							self.MaxSpeed = 2
							
							for _, v in self.Barriers:GetChildren() do
								v.CanCollide = true
								v.Transparency = 0.5
							end
							
							self:UpdateUI()
							Character:PivotTo(self.SpawnPart.CFrame)
						end
					end
				end
			end)
		end
	end)

	task.delay(rng:NextInteger(self.MinSpeed,self.MaxSpeed), function()
		if Running then
			self:SpawnRainDrop()
		end
	end)
end

function Eyebrow.Knockback(self: EyebrowChallenge)
	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.new(1,1,1) * math.huge
	--BodyVelocity.P = 10000
	BodyVelocity.Velocity = -Character.PrimaryPart.CFrame.LookVector * 10
	BodyVelocity.Parent = Character.PrimaryPart
	
	task.delay(0.15, function()
		BodyVelocity:Destroy()
	end)
end

function Eyebrow.RemoveItem(self: EyebrowChallenge)
	for _, v in Character:GetChildren() do
		if v:IsA("Tool") and v.Name == "EyebrowShield" then
			v.Parent = player.Backpack
		end
	end
	
	for _, v in player.Backpack:GetChildren() do
		if v.Name == "EyebrowShield" then
			v:Destroy()
		end
	end
end

function Eyebrow.Disconnect(self: EyebrowChallenge)
	Running = false

	LobbyTheme:Play()
	EyebrowTheme:Pause()

	self.CurrentBlurNumber = 0
	self.Health = 100

	self:VisibleCharacters(false)
	self:UpdateUI()

	player:SetAttribute("CanSprint", false)
	player:SetAttribute("InChallenge", false)

	if self.Connections then
		for _, v in self.Connections do
			v:Disconnect()
		end
		table.clear(self.Connections)
	end
	
	if self.RainDrops then
		for _, v in self.RainDrops do
			v:Destroy()
		end
		table.clear(self.RainDrops)
	end
	
	table.clear(ReceivedPrize)
end

return Eyebrow
