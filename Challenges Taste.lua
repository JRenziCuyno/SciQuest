local TweenService = game:GetService('TweenService')
local RunService = game:GetService("RunService")

local FoodTools = game.ReplicatedStorage:WaitForChild("Foods")

local player = game.Players.LocalPlayer
local Characater = player.Character or player.CharacterAdded:Wait()

local DialogueGui = player.PlayerGui:WaitForChild("DialogueGui")

local Dialogue = require(game.ReplicatedStorage.DialogueEnd)
local GiveCoins = game.ReplicatedStorage.GiveCoin

local TasteTheme = game.SoundService["Taste Theme"]
local LobbyTheme = game.SoundService["Lobby Theme"]

local Yap = Dialogue.new(DialogueGui)

local AlreadyYapped = false

local ToYap = {
	{"Excellent job!", 0.5};
	{"You reached 100% on the right taste.", 1};
	{"Just like in real life, your tongue helps you tell sweet, sour, salty, bitter, and umami apart.", 1.5};
	{"And remember", 0.25};
	{"spicy isn’t a basic taste, but it can confuse your tongue and make flavors harder to find.", 2};
	{"Well done, Flavor Explorer!", 1};
}

local FailYap = {
	{"Nice try!", 0.5};
	{"You didn’t reach 100% on the right taste this time.", 1};
	{"But just like in real life, your tongue sometimes gets tricked by strong or unexpected flavors.", 1.5};
	{"But Don’t worry", 0.5};
	{"even expert chefs miss the right taste is a journey, not a destination.", 2};
	{"Keep exploring, Flavor Adventurer!", 1};

}

local Taste = {}
Taste.__index = Taste

type TasteChallenge = typeof(Taste) & {
	ShopStands: Folder;
	TasteGui: ScreenGui;
	Prompt: ProximityPrompt;

	TastyMeter: Frame;
	BarFrame: Frame;
	Bar: Frame;
	TargetLabel: TextLabel;

	TasteMeter: Frame;
	ToungeImage: ImageLabel;

	TimerLabel: TextLabel;
	FlavorLabel: TextLabel;
	AmountLabel: TextLabel;

	SweetLine: Frame;
	SourLine: Frame;
	BitterLine: Frame;
	SaltyLine: Frame;
	UmamiLine: Frame;
	RedLine: Frame;

	Sweet: Frame;
	Umami: Frame;
	Bitter: Frame;
	Salty: Frame;
	Sour: Frame;
	Spicy: Frame;

	Counting: boolean;

	TargetTaste: string;

	TimeLeft: number;
	Amount: number;

	FoodConsumed: {string};

	Foods: {
		Bacon: Folder;
		Cheese: Folder;
		Egg: Folder;
		BeefJerky: Folder;
		Pretzels: Folder;

		Lemon: Folder;
		Lime: Folder;
		Orange: Folder;
		Yogurt: Folder;

		Candy: Folder;
		Cookie: Folder;
		DarkChocolate: Folder;
		Honey: Folder;
		IceCream: Folder;

		Broccoli: Folder; 
		Cabbage: Folder; 
		Coffee: Folder;

		Corn: Folder;
		Mushroom: Folder;
		Potato: Folder;
	};

	Colors: {
		[string]: Color3
	};

	Anchored: {[Instance]: boolean};
	Prompts: {ProximityPrompt};
	Connections: {[string]: RBXScriptConnection};
	Taste: {any};
	StandsPositions: {[Instance]: CFrame}
}
function Taste.new(...)
	local self: TasteChallenge =  setmetatable({}, Taste)
	local Params = {...}

	self.ShopStands = Params[1]
	self.TasteGui = Params[2]
	self.Prompt = Params[3]

	self.TastyMeter = self.TasteGui:WaitForChild("TastyMeter")
	self.TimerLabel = self.TastyMeter:WaitForChild("TimerLabel")
	self.AmountLabel = self.TastyMeter:WaitForChild("Percentage")
	self.TargetLabel = self.TastyMeter:WaitForChild("TargetTaste")

	self.BarFrame = self.TastyMeter:WaitForChild("BarFrame")
	self.Bar = self.BarFrame:WaitForChild("Bar")

	self.FlavorLabel = self.TasteGui:WaitForChild("FlavorLabel")

	self.ToungeImage = self.TasteGui:WaitForChild("ImageLabel")
	self.Sweet = self.ToungeImage:WaitForChild("Sweet")
	self.Sour = self.ToungeImage:WaitForChild("Sour")
	self.Salty = self.TasteGui:WaitForChild("Salty")
	self.Bitter = self.ToungeImage:WaitForChild("Bitter")
	self.Umami = self.ToungeImage:WaitForChild("Umami")
	self.Spicy = self.ToungeImage:WaitForChild("Spicy")

	self.Foods = {}
	self.Anchored = {}
	self.Taste = {"Sweet", "Sour", "Bitter", "Salty", "Umami"}

	self.Colors = {
		["Sweet"] = `rgb(83, 42, 0)`,
		["Sour"] = `rgb(255, 255, 127)`,
		["Bitter"] = `rgb(85, 170, 127)`,
		["Salty"] = `rgb(255, 255, 255)`,
		["Umami"] = `rgb(85, 0, 0)`,
		["Spicy"] = `rgb(255,0,0)`
	}

	self.TimeLeft = 60
	self.Amount = 0
	self.Counting = false

	self.Prompts = {}
	self.Connections = {}

	self.FoodConsumed = {}
	self.StandsPositions = {}

	return self
end

function Taste.Start(self: TasteChallenge)
	if player:GetAttribute("InChallenge") then
		return
	end

	for i, v in player:GetAttributes() do
		if type(v) == "number" then
			player:SetAttribute(i, 0)
		end
	end
	
	LobbyTheme:Pause()
	TasteTheme:Play()

	TweenService:Create(self.Bar, TweenInfo.new(0.25), {Size = UDim2.fromScale(0,1)}):Play()

	player:SetAttribute("InChallenge", true)

	self.Amount = 0

	for _, v in self.Prompts do
		v.Enabled = true
	end

	self:SetupShop()
	self:ShuffleStands()

	if not self.TargetTaste then
		self.TargetTaste = self.Taste[Random.new():NextInteger(1,#self.Taste)]
	end

	self.TargetLabel.Text = `Flavor Goal: <font color="rgb(255,100,0)">{self.TargetTaste}</font>`

	self.TasteGui.Enabled = true

	self.AmountLabel.Text = `{player:GetAttribute(self.TargetTaste)}%`

	self:TimerStart()
end

function Taste.TimerStart(self: TasteChallenge)
	local function TimerEffect()
		local NewLabel = self.TimerLabel:Clone()
		NewLabel:FindFirstChild("UIStroke"):Destroy()
		NewLabel.Parent = self.TimerLabel.Parent
		TweenService:Create(NewLabel, TweenInfo.new(0.4), {Position = UDim2.fromScale(self.TimerLabel.Position.X.Scale,0.3), TextTransparency = 1}):Play()

		task.delay(0.35, function()
			NewLabel:Destroy()
		end)
	end
	local Rng = Random.new()

	local Seconds = 0
	self.Connections["Timer"] = RunService.PreRender:Connect(function(dt)
		Seconds += dt

		if Seconds >= 1 then
			Seconds = 0

			TimerEffect()

			self.TimeLeft -= 1
			self.TimerLabel.Text = `Time Left:  <font color="rgb(255,19,74)">{self.TimeLeft}s</font>`

			if self.TimeLeft <= 0 then
				self:Disconnect()
				for _, v in player.Backpack:GetChildren() do
					if v:IsA("Tool") and v:HasTag("Food") then
						v:Destroy()
					end
				end
				
				for _, v in player.Character:GetChildren() do
					if v:IsA("Tool") and v:HasTag("Food") then
						v.Parent = player.Backpack
						v:Destroy()
					end
				end
				
				Yap:ClickContinue(FailYap)
				
				
				task.delay(3, function()
					self.TasteGui.Enabled = false
				end)
			end
		end
	end)
end

function Taste.ShuffleStands(self: TasteChallenge)
	local function CheckMatchedLocation(Pos1, Pos2, tolerance)
		tolerance = tolerance or 0.001

		return (Pos1.Position - Pos2.Position).Magnitude <= tolerance
	end


	local OriginPos = {}
	for _, v in self.ShopStands:GetChildren() do
		OriginPos[v] = v:GetPivot()
	end

	local success

	repeat
		success = true
		local TakenPos = {}

		for _, v in self.ShopStands:GetChildren() do
			local rng = Random.new()
			local RandomPos

			repeat
				RandomPos = self.StandsPositions[rng:NextInteger(1,#self.StandsPositions)]
			until not TakenPos[RandomPos]

			TakenPos[RandomPos] = true

			local YOffset = (v.Name == "Salty") and -40.762 or -43.046
			local NewCFrame = CFrame.new(RandomPos.Position.X, YOffset, RandomPos.Position.Z) * RandomPos - RandomPos.Position

			if (NewCFrame.Position - OriginPos[v].Position).Magnitude <= 1 then
				warn("new position is close in origin in shuffle, retrying..")
				success = false
				break
			end

			v:PivotTo(NewCFrame)
		end
	until success
end

function Taste.Gui(self: TasteChallenge)
	if self.Connections["Gui"] then
		self.Connections["Gui"]:Disconnect()
	end

	if self.FoodConsumed then
		self.FlavorLabel.Visible = true
		self.ToungeImage.Visible = true

		for _, v in self.FoodConsumed do
			self[v].Visible = true
		end

		local t = 0

		self.Connections["Gui"] = RunService.PreRender:Connect(function(dt)
			t += dt

			if t >= 3 then
				t = 0
				self.Connections["Gui"]:Disconnect()
				self.Connections["Gui"] = nil

				for _, v in self.FoodConsumed do
					self[v].Visible = false
					self.FlavorLabel.Visible = false
					self.ToungeImage.Visible = false
				end

				table.clear(self.FoodConsumed)
			end
		end)
	end
end

function Taste.SetupShop(self: TasteChallenge)
	local function DecrementFood(NewTool: Tool)
		local StartAmount = player:GetAttribute(self.TargetTaste)
		self.Counting = false
		local rng = Random.new()
		local RandomNum = rng:NextInteger(12.5,20)

		for _, v in self.FoodConsumed do
			self[v].Visible = false
			self.FlavorLabel.Visible = false
			self.ToungeImage.Visible = false
		end
		table.clear(self.FoodConsumed)

		for i, v in NewTool:GetAttributes() do
			if v == true then
				table.insert(self.FoodConsumed, i)
				local FoodColor = self.Colors[self.FoodConsumed[1]]

				if #self.FoodConsumed > 1 then
					local FoodColor2 = self.Colors[self.FoodConsumed[2]]
					self.FlavorLabel.Text = `<font color="{FoodColor}">{self.FoodConsumed[1]}</font> and <font color="{FoodColor2}">{self.FoodConsumed[2]}</font>`
				else
					self.FlavorLabel.Text = `<font color="{FoodColor}">{self.FoodConsumed[1]}</font>`
				end
			end
		end

		self:Gui()

		player:SetAttribute("Eating", false)

		if NewTool:GetAttribute(self.TargetTaste) == true then
			player:SetAttribute(self.TargetTaste, player:GetAttribute(self.TargetTaste) + RandomNum)

			if player:GetAttribute(self.TargetTaste) >= 100 then
				self:Disconnect()

				GiveCoins:FireServer()
				
				if not AlreadyYapped then
					AlreadyYapped = true
					Yap:ClickContinue(ToYap)
				end

				task.delay(3, function()
					self.TasteGui.Enabled = false
					
					for _, v in player.Backpack:GetChildren() do
						if v:IsA("Tool") and v:HasTag("Food") then
							v:Destroy()
						end
					end
					
					for _, v in player.Character:GetChildren() do
						if v:IsA("Tool") and v:HasTag("Food") then
							v.Parent = player.Backpack
							v:Destroy()
						end
					end
				end)
			end

			task.spawn(function()
				self.Amount = 0
				if not self.Counting then
					self.Counting = true
				end

				for i = 1, RandomNum do
					if not self.Counting then
						self.AmountLabel.Text = `{StartAmount + RandomNum}%`
						break
					end

					self.Amount += 1

					if StartAmount + self.Amount >= 100 then
						self.AmountLabel.Text = `100%`
					else
						self.AmountLabel.Text = `{StartAmount + self.Amount}%`
					end

					task.wait(0.015)
				end
				self.Counting = false
			end)
		else
			if NewTool:GetAttribute("Spicy") then
				RandomNum = 10
				player:SetAttribute(self.TargetTaste, player:GetAttribute(self.TargetTaste) - RandomNum)
				
				if player:GetAttribute(self.TargetTaste) <= 0 then
					player:SetAttribute(self.TargetTaste, 0)
				end

				task.spawn(function()
					self.Amount = 0
					if not self.Counting then
						self.Counting = true
					end

					for i = 1, RandomNum do
						if not self.Counting then
							self.AmountLabel.Text = `{StartAmount - RandomNum}%`
							break
						end

						self.Amount += 1

						if StartAmount - self.Amount <= 0 then
							self.AmountLabel.Text = `0%`
						else
							self.AmountLabel.Text = `{StartAmount - self.Amount}%`
						end

						task.wait(0.015)
					end
					self.Counting = false
				end)
			end
		end

		local ClampedSize = math.clamp(player:GetAttribute(self.TargetTaste) / 100, 0 ,1)

		TweenService:Create(self.Bar, TweenInfo.new(0.25), {Size = UDim2.fromScale(ClampedSize,1)}):Play()

		NewTool:Destroy()
	end

	for _, v in self.ShopStands:GetChildren() do
		table.insert(self.StandsPositions, v:GetPivot())
		for _, attachment in v:WaitForChild("Prompts"):GetChildren() do
			for _, prompt: ProximityPrompt in attachment:GetChildren() do
				prompt.Enabled = true
				table.insert(self.Prompts, prompt)
				self.Connections[prompt] = prompt.Triggered:Connect(function(player)
					if prompt:GetAttribute("Amount") <= 0 then
						return
					end

					if not self.Foods[prompt.Parent.Name] then
						return
					end

					local Food = self.Foods[prompt.Parent.Name]
					self:RemoveFood(Food)

					local Tool = FoodTools:FindFirstChild(Food.Name)

					if Tool then
						local NewTool: Tool = Tool:Clone()
						NewTool.Parent = player.Backpack

						for _,v in player.Character:GetChildren() do
							if v:IsA("Tool") then
								v.Parent = player.Backpack
							end
						end

						NewTool.Parent = player.Character

						self.Connections[NewTool] = NewTool.Activated:Connect(function()
							if player:GetAttribute("Eating") then
								return
							end
							player:SetAttribute("Eating", true)

							local Humanoid = Characater:WaitForChild("Humanoid")
							local Animator: Animator = Humanoid:WaitForChild("Animator")
							local EatAnim = Animator:LoadAnimation(script.Animation)

							EatAnim:GetMarkerReachedSignal("Eat"):Once(function()
								self.Connections[NewTool]:Disconnect()
								self.Connections[NewTool] = nil

								DecrementFood(NewTool)
							end)

							EatAnim:Play()
						end)
					end

					prompt:SetAttribute("Amount", prompt:GetAttribute("Amount") - 1)
					if prompt:GetAttribute("Amount") <= 0 then
						prompt.Enabled = false
					end
				end)
			end
		end

		for _, food in v.Shop:GetChildren() do
			self.Foods[food.Name] = food
		end
	end
end

function Taste.RemoveFood(self: TasteChallenge, Food: Folder)
	for _, v in Food:GetChildren() do
		if self.Anchored[v] then
			continue
		end

		self.Anchored[v] = true

		if v:IsA("BasePart") then
			v.Transparency = 1
			v.CanCollide = false
		else 
			for _, part in v:GetChildren() do
				if part:IsA("BasePart") then
					part.Transparency = 1
					part.CanCollide = false
				end
			end
		end
		break
	end
end

function Taste.Disconnect(self: TasteChallenge)
	self.Prompt.Enabled = true
	
	TasteTheme:Stop()
	LobbyTheme:Play()
	
	if self.Connections then
		for i, v in self.Connections do

			v:Disconnect()
		end
		table.clear(self.Connections)
	end

	for _, folder in self.Foods do
		for _, part in folder:GetChildren() do
			if part:IsA("BasePart") then
				part.Transparency = 0
				part.CanCollide = true
			end
		end
	end

	for _, v in self.Prompts do
		v:SetAttribute("Amount", v:GetAttribute("MaxAmount"))
		v.Enabled = false
	end

	for _, v in self.FoodConsumed do
		self[v].Visible = false
		self.FlavorLabel.Visible = false
		self.ToungeImage.Visible = false
	end

	table.clear(self.StandsPositions)
	table.clear(self.FoodConsumed)

	player:SetAttribute("InChallenge", false)
	player:SetAttribute("Eating", false)
	self.TimeLeft = 60

	table.clear(self.Anchored)
	table.clear(self.Foods)
end

return Taste