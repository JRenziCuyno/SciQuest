local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = game.Players.LocalPlayer
local Character = player.Character or player.CharacterAdded:Wait()

local DialogueGui = player.PlayerGui:WaitForChild("DialogueGui")

local GiveCoins = game.ReplicatedStorage.GiveCoin
local EmitParticle = require(game.ReplicatedStorage.EmitParticles)

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)

local Maze = game.SoundService.Maze
local LobbyTheme = game.SoundService["Lobby Theme"]

local Yap = Dialogue.new(DialogueGui)

local ToYap = {
	{"Great job! You escaped the maze!", 0.5};
	{"Just like in the game, your pupil and iris work together every day to balance light so you can see clearly.", 1.5};
}

local Camera = workspace.CurrentCamera

local Lighting = game.Lighting

local bool = false

local Touched = {}

local Pupils = {}
Pupils.__index = Pupils

type PupilChallenge = typeof(Pupils) & {
	ScreenGui: ScreenGui;
	PupilGui: ScreenGui;
	Maze: Model;
	Prompt: ProximityPrompt;

	PupilInfo: Frame;
	ExitButton: TextButton;
	Wheel: ImageLabel;

	PupilTrigger: Folder;
	GoalTrigger: BasePart;
	
	Lefteye: Folder;
	Righteye: Folder;
	
	LeftIris: Frame;
	RightIris: Frame;
	
	EyeFrame: Frame;
	BalanceFrame: Frame;
	RedLine: Frame;
	TargetZone: Frame;
	BarWidth: any;
	LineWidth: any;
	TargetWidth: any;

	CurrentTween: any;
	Direction: number;
	Speed: number;

	Running: boolean;
	LeftIrisTween: any;
	RightIrisTween: any;

	Result: TextLabel;
	Tip: TextLabel;

	Connections: {[Instance | string]: RBXScriptConnection};
}

function Pupils.new(...)
	local self: PupilChallenge = setmetatable({}, Pupils)
	local Params = {...}

	self.ScreenGui = Params[1]
	self.PupilGui = Params[2]
	self.Maze = Params[3]
	self.Prompt = Params[4]
	
	self.PupilInfo = self.PupilGui:WaitForChild("Frame")
	self.ExitButton = self.PupilInfo:WaitForChild("ExitButton")
	self.Wheel = self.PupilInfo:WaitForChild("Wheel")

	self.BalanceFrame = self.ScreenGui:WaitForChild("BalanceBar")
	self.Result = self.ScreenGui:WaitForChild("ResultLabel")
	self.Tip = self.ScreenGui:WaitForChild("TipLabel")
	
	self.EyeFrame = self.ScreenGui:WaitForChild("EyeFrame")
	self.LeftIris = self.EyeFrame:WaitForChild("Left"):WaitForChild("Iris")
	self.RightIris = self.EyeFrame:WaitForChild("Right"):WaitForChild("Iris")
	
	self.GoalTrigger = self.Maze:WaitForChild("GoalTrigger")

	self.RedLine = self.BalanceFrame:WaitForChild("BalanceLine")
	self.TargetZone = self.BalanceFrame:WaitForChild("TargetZone")

	self.PupilTrigger = self.Maze:WaitForChild("Trigger")

	self.BarWidth = self.BalanceFrame.AbsoluteSize.X
	self.LineWidth = self.RedLine.Size.X.Offset
	self.TargetWidth = self.TargetZone.Size.X.Offset

	self.Direction = 1

	self.Running = false

	self.Connections = {}

	return self
end

function Pupils.Start(self: PupilChallenge)
	player:SetAttribute("InChallenge", true)
	player:SetAttribute("CanSprint", false)
	
	LobbyTheme:Pause()
	Maze:Play()
	
	for _, v in self.PupilTrigger:GetChildren() do
		self.Connections[v] = v.Touched:Connect(function(hit)
			if hit:IsDescendantOf(Character) then
				if not self.Running then
					self.Connections[v]:Disconnect()
					self.Connections[v] = nil

					self:Trigger()
				else
					return
				end
			end
		end)
	end
	
	self.Connections["GoalTrigger"] = self.GoalTrigger.Touched:Connect(function(hit)
		if hit:IsDescendantOf(Character) then
			self:Disconnect()
			
			self.PupilGui.Enabled = true
			self.PupilInfo.Visible = true

			GiveCoins:FireServer("PupilIris")
			EmitParticle()

			self.Connections["Wheel"] = RunService.PreRender:Connect(function()
				self.Wheel.Rotation += 0.1
			end)

			TweenService:Create(self.PupilInfo, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = self.PupilInfo:GetAttribute("GoalIn")}):Play()

			local secondsleft = 5

			for i = 1,5 do
				secondsleft -= 1
				self.ExitButton.Text = secondsleft
				task.wait(1)
			end

			self.ExitButton.Text = "X"

			self.ExitButton.MouseButton1Click:Once(function()
				TweenService:Create(self.PupilInfo, TweenInfo.new(0.5, Enum.EasingStyle.Bounce, Enum.EasingDirection.In), {Size = self.PupilInfo:GetAttribute("GoalOut")}):Play()
				Yap:ClickContinue(ToYap)
				
				task.delay(0.5, function()
					self.Connections["Wheel"]:Disconnect()
					self.Connections["Wheel"] = nil
					self.PupilInfo.Visible = false
					self.PupilGui.Enabled = false
				end)
			end)
		end
	end)
end

function Pupils.Trigger(self: PupilChallenge)
	if not self.Running then
		self.Running = true
		
		TweenService:Create(Camera, TweenInfo.new(2), {FieldOfView = 60}):Play()
		TweenService:Create(self.LeftIris.UIScale, TweenInfo.new(2), {Scale = 0.65}):Play()
		TweenService:Create(self.RightIris.UIScale, TweenInfo.new(2), {Scale = 0.65}):Play()
		
		bool = not bool
		
		local TargetColor = bool and Color3.new(1,1,1) or Color3.new(0,0,0)
		TweenService:Create(Lighting, TweenInfo.new(0.25), {FogColor = TargetColor}):Play()

		self:SetTarget()

		self.Connections["KeyBind"] = UserInputService.InputBegan:Connect(function(inp, gpe)
			if gpe then
				return
			end

			if inp.KeyCode == Enum.KeyCode.Space then
				if self.Running then
					self:CheckHit()
				end
			end
		end)
	end
end

function Pupils.FogAppear(self: PupilChallenge)
	local Humanoid = Character:WaitForChild("Humanoid")

	TweenService:Create(Humanoid, TweenInfo.new(2), {WalkSpeed = 0}):Play()
	TweenService:Create(Lighting, TweenInfo.new(2), {FogEnd = 20}):Play()

	task.delay(2, function()
		Character.PrimaryPart.Anchored = true
		self:Visible(true)
	end)
end

function Pupils.SetTarget(self: PupilChallenge)
	if not self.ScreenGui.Enabled then
		self:FogAppear()
	end

	local rng = Random.new()

	local maxX = self.BarWidth - self.TargetWidth
	local randX = math.random(0, maxX)
	self.TargetZone.Position = UDim2.new(0, randX, 0, 0)
	self.RedLine.Position = UDim2.new(0,0,0,0)

	self.Speed = rng:NextNumber(0.5,2.5)

	self:MoveLine()
end

function Pupils.MoveLine(self: PupilChallenge)
	local goalX = self.Direction == 1 and (self.BarWidth - self.LineWidth) or 0 -- if direction is 1 then target is (barwidth - linewidth) if not, 0
	local tweenInfo = TweenInfo.new(self.Speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	self.CurrentTween = TweenService:Create(self.RedLine, tweenInfo, {Position = UDim2.new(0, goalX, 0, 0)})

	self.CurrentTween:Play()
	
	self.CurrentTween.Completed:Once(function()
		if self.Running then
			self.Direction *= -1
			self.CurrentTween:Destroy()
			self:MoveLine()
		end
	end)
end

function Pupils.CheckHit(self: PupilChallenge)
	local lineX = self.RedLine.AbsolutePosition.X
	local targetX = self.TargetZone.AbsolutePosition.X

	local Humanoid = Character:FindFirstChild("Humanoid")

	local function StopTween()
		if self.CurrentTween then
			self.CurrentTween:Pause()
			self.CurrentTween:Destroy()
			self.CurrentTween = nil
		end
	end

	if lineX >= targetX and lineX <= (targetX + self.TargetWidth) then
		self.Result.Text = ""

		StopTween()

		TweenService:Create(Lighting, TweenInfo.new(5), {FogEnd = 10000}):Play()
		TweenService:Create(Camera, TweenInfo.new(1), {FieldOfView = 70}):Play()
		
		local ScaleSize = bool and 0.25 or 1
		
		TweenService:Create(self.LeftIris.UIScale, TweenInfo.new(2), {Scale = ScaleSize}):Play()
		TweenService:Create(self.RightIris.UIScale, TweenInfo.new(2), {Scale = ScaleSize}):Play()
		
		task.delay(2, function()
			self:Visible(false)
			self.Running = false
		end)

		Humanoid.WalkSpeed = 16
		Character.PrimaryPart.Anchored = false
		
		self.Connections["KeyBind"]:Disconnect()
		self.Connections["KeyBind"] = nil
	else
		self.Result.Text = "? Miss!"
		
		bool = not bool

		StopTween()
		
		Humanoid.WalkSpeed = 0

		task.delay(0.5, function()
			self.Result.Text = ""
			self:Visible(false)
			self.Running = false
			
			local TargetColor = bool and Color3.new(1,1,1) or Color3.new(0,0,0)
			TweenService:Create(Lighting, TweenInfo.new(0.25), {FogColor = TargetColor}):Play()
			
			task.wait(1.5)
			self.Running = true
			self:Visible(true)
			self:SetTarget()
		end)
	end

end

function Pupils.Visible(self: PupilChallenge, booleen: boolean)
	self.ScreenGui.Enabled = booleen
end

function Pupils.Disconnect(self: PupilChallenge)
	player:SetAttribute("InChallenge", false)
	player:SetAttribute("CanSprint", true)
	
	local Humanoid = Character:FindFirstChildOfClass("Humanoid")
	
	Humanoid.JumpHeight = 7.2
	
	Maze:Stop()
	LobbyTheme:Play()
	
	self.Prompt.Enabled = true
	
	if self.Connections then
		for _,v in self.Connections do
			v:Disconnect()
		end

		table.clear(self.Connections)
	end
end


return Pupils