local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService('RunService')

local player = game.Players.LocalPlayer

local Camera = workspace.CurrentCamera

local Impulse = require(script.Spring)

local DialogueGui = player.PlayerGui:WaitForChild("DialogueGui")

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)

local LobbyTheme = game.SoundService["Lobby Theme"]

local Yap = Dialogue.new(DialogueGui)

local GiveCoins = game.ReplicatedStorage.GiveCoin

local ToYap = {
	{"Great job!", 0.25};
	{"Your ear flaps helped you find where the sound was coming from.", 1.5};
	{"That’s how your ears work.", 0.5};
	{"they collect sounds and tell your brain which direction they come from!", 2}
}

local bool = false

local Earflap = {}
Earflap.__index = Earflap

type EarflapChallenge = typeof(Earflap) & {
	ItemsToFind: Folder;
	Prompt: ProximityPrompt;
	EarflapGui: ScreenGui;
	LabelCount: TextLabel;
	
	ChosenObject: Instance;

	CurrentSound: Sound;

	Found: number;

	DogActive: boolean;
	BushActive: boolean;
	BellActive: boolean;
	CowActive: boolean;
	FrogActive: boolean;
	
	ChosenNumber: number;

	Target: Instance;

	Connections: {[Instance|string]: RBXScriptConnection};
	Chosen: {[Instance]: boolean};
	Hovered: {[Instance]: Highlight};
}

function Earflap.new(...)
	local self: EarflapChallenge = setmetatable({}, Earflap)
	local Params = {...}

	self.ItemsToFind = Params[1]
	self.Prompt = Params[2]
	self.EarflapGui = Params[3]
	
	self.LabelCount = self.EarflapGui:WaitForChild("Frame"):WaitForChild("Count")
	
	self.Found = 0
	self.ChosenNumber = 0
	
	self.BellActive = false
	self.BushActive = false
	self.FrogActive = false
	self.CowActive = false
	self.DogActive = false

	self.Connections = {}
	self.Chosen = {}
	self.Hovered = {}

	return self
end

function Earflap.Start(self: EarflapChallenge)
	if self.Connections then
		self:Disconnect()
	end
	
	self.EarflapGui.Enabled = true

	local rate = 0
	self.Found = 0
	self.ChosenNumber = 0
	
	LobbyTheme:Stop()
	
	for _, v in self.ItemsToFind:GetChildren() do
		for _, obj in v:GetChildren() do
			obj:SetAttribute("Found", false)
		end
	end
	
	player:SetAttribute("InChallenge", true)

	self:GetRandomObject()

	self.Connections["HoverEffect"] = RunService.PreRender:Connect(function(dt)
		rate += dt

		if rate <= (1/15) then
			return
		end

		rate = 0

		self:Hover()
	end)

	self.Connections["Click"] = UserInputService.InputBegan:Connect(function(inp, gpe)
		if gpe then
			return
		end

		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			self:OnClick()
			self.LabelCount.Text = `Sounds Collected {self.Found}/5`
		end
	end)
end

function Earflap.GetRandomObject(self:EarflapChallenge)
	local rng = Random.new()
	
	if self.ChosenNumber >= 5 then
		self.ChosenNumber = 0
		table.clear(self.Chosen)
	end
	
	repeat
		self.ChosenObject = self.ItemsToFind[rng:NextInteger(1, #self.ItemsToFind:GetChildren())]
	until not self.Chosen[self.ChosenObject] and not self.ChosenObject[rng:NextInteger(1, #self.ChosenObject:GetChildren())]:GetAttribute("Found")
	
	self.Chosen[self.ChosenObject] = true
	self.ChosenNumber += 1
	
	self.ChosenObject = self.ChosenObject[rng:NextInteger(1, #self.ChosenObject:GetChildren())]
	
	self[self.ChosenObject:GetAttribute("Type")](self)
end

function Earflap.Visible(self:EarflapChallenge, bool: boolean)
	if self.ChosenObject:IsA("Model") then
		for _, v in self.ChosenObject:GetDescendants() do
			if v:IsA("BasePart") then
				v.CanCollide = true
				v.Transparency = bool and 0 or 1
			end
		end
	else
		self.ChosenObject.CanCollide = true
		self.ChosenObject.Transparency = bool and 0 or 1
	end
end

function Earflap.Bell(self: EarflapChallenge)
	self.BellActive = true
	self.ChosenObject = self.ChosenObject:Clone()
	self.ChosenObject.Parent = self.ItemsToFind
	self.ChosenObject:SetAttribute("Active", true)

	self.Target = self.ChosenObject

	self:Visible(true)

	self:BellEffect()
end

function Earflap.Bush(self: EarflapChallenge)
	self.BushActive = true

	self.Target = self.ChosenObject
	self.ChosenObject:SetAttribute("Active", true)

	self:Visible(true)

	local Rate = 0

	self.Connections[self.ChosenObject] = RunService.PreRender:Connect(function(dt)
		Rate += dt

		if Rate >= 6.15 then
			print("call")
			Rate = 0
			self:DogEffect()
		end
	end)
end

function Earflap.Dog(self: EarflapChallenge)
	self.DogActive = true
	self:Visible(true)

	self.ChosenObject:SetAttribute("Active", true)
	self.Target = self.ChosenObject

	local Rate = 0

	self.Connections[self.ChosenObject] = RunService.PreRender:Connect(function(dt)
		Rate += dt

		if Rate >= 1 then
			Rate = 0
			self:DogEffect()
		end
	end)
end

function Earflap.Cow(self: EarflapChallenge)
	self.CowActive = true
	self:Visible(true)
	
	self.ChosenObject:SetAttribute("Active", true)
	self.Target = self.ChosenObject
	
	local Rate = 0
	
	self:DogEffect()
	
	self.Connections[self.ChosenObject] = RunService.PreRender:Connect(function(dt)
		Rate += dt
		
		if Rate >= self.ChosenObject:GetAttribute("Cooldown") then
			Rate = 0
			self:DogEffect()
		end
	end)
end

function Earflap.Frog(self:EarflapChallenge)
	self.FrogActive = true
	self:Visible(true)

	self.ChosenObject:SetAttribute("Active", true)
	self.Target = self.ChosenObject

	local Rate = 0

	self:DogEffect()

	self.Connections[self.ChosenObject] = RunService.PreRender:Connect(function(dt)
		Rate += dt

		if Rate >= self.ChosenObject:GetAttribute("Cooldown") then
			Rate = 0
			self:DogEffect()
		end
	end)
end

function Earflap.Hover(self: EarflapChallenge)
	local function CreateHighlight(Parent: Instance): Highlight
		local Highlight = Instance.new("Highlight")
		Highlight.FillTransparency = 1
		Highlight.OutlineTransparency = 0
		Highlight.OutlineColor = Color3.new(1,1,1)
		Highlight.Parent = Parent
		return Highlight
	end

	local Result = self:CastRay()

	if not Result then
		if self.Hovered then
			for _, v in self.Hovered do
				v:Destroy()
			end
			table.clear(self.Hovered)
		end
		return
	end

	local RayInstance = self:GetParent(Result.Instance)

	if RayInstance:IsDescendantOf(self.ItemsToFind) and RayInstance:GetAttribute("Active") then
		if not self.Hovered[RayInstance] then
			self.Hovered[RayInstance] = CreateHighlight(RayInstance)
		end
	else
		if self.Hovered then
			for _, v in self.Hovered do
				v:Destroy()
			end
			table.clear(self.Hovered)
		end
	end
end

function Earflap.CastRay(self: EarflapChallenge): RaycastResult
	local mouse = UserInputService:GetMouseLocation()
	local ray = Camera:ViewportPointToRay(mouse.X ,mouse.Y)
	local Result = workspace:Raycast(ray.Origin, ray.Direction * 50)

	return Result
end

function Earflap.GetParent(self: EarflapChallenge, Obj: Instance): Instance
	if Obj.Parent:IsA("Model") or Obj.Parent:IsA("BasePart") then
		return Obj.Parent
	else
		return Obj
	end
end

function Earflap.OnClick(self: EarflapChallenge)
	local Result = self:CastRay()

	if not Result then
		return
	end

	local RayInstance = self:GetParent(Result.Instance)

	if RayInstance:IsDescendantOf(self.ItemsToFind) and RayInstance:GetAttribute("Active") then
		if RayInstance:GetAttribute("Type") == "Bell" then
			if RayInstance == self.Target then
				self.BellActive = false
				self.Found += 1
				RayInstance:Destroy()
			end
		else
			if RayInstance == self.Target then
				self.Connections[self.ChosenObject]:Disconnect()
				self.Connections[self.ChosenObject] = nil
				self.DogActive = false
				self.BushActive = false

				if RayInstance:IsA("Model") then
					for _, v in RayInstance:GetChildren() do
						if v:IsA("BasePart") then
							v.Transparency = 1
							v.CanCollide = false
						end
					end
				else
					RayInstance.Transparency = 1
					RayInstance.CanCollide = false
				end

				self.Found += 1
				self.CurrentSound:Stop()
			end
		end
		
		if self.Found < 5 then
			self:GetRandomObject()
		else
			self.Prompt.Enabled = true
			self:Disconnect()
			GiveCoins:FireServer()
			Yap:ClickContinue(ToYap)
		end
	end
end

function Earflap.BellEffect(self: EarflapChallenge)
	local Bell = self.ChosenObject:WaitForChild("Union")
	local Bellsound = Bell:WaitForChild("Bell")

	local BodyVelocity = Instance.new("BodyVelocity")
	BodyVelocity.MaxForce = Vector3.one * math.huge
	BodyVelocity.Velocity = Bell.CFrame.LookVector * 5
	BodyVelocity.Parent = Bell

	Bellsound:Play()

	task.wait(0.15)

	BodyVelocity:Destroy()

	task.delay(5,function()
		if self.BellActive then
			self:BellEffect()
		end
	end)
end

function Earflap.BushEffect(self: EarflapChallenge)
	Impulse(self.ChosenObject, self.ChosenObject:GetAttribute("Impulse"), "Position")

	self.CurrentSound:Play()
end

function Earflap.DogEffect(self: EarflapChallenge)
	print("call 2")
	self.CurrentSound = self.ChosenObject:FindFirstChildOfClass("Sound")

	Impulse(self.ChosenObject, self.ChosenObject:GetAttribute("Impulse"), "Position")

	self.CurrentSound:Play()
end

function Earflap.Disconnect(self: EarflapChallenge)
	if self.Connections then
		for _, v in self.Connections do
			v:Disconnect()
		end
		table.clear(self.Connections)
	end
	
	LobbyTheme:Play()

	if self.Hovered then
		for _, v in self.Hovered do
			v:Destroy()
		end
		table.clear(self.Hovered)
	end

	if self.Chosen then
		table.clear(self.Chosen)
	end

	player:SetAttribute("InChallenge", false)
	self.EarflapGui.Enabled = false
end

return Earflap
