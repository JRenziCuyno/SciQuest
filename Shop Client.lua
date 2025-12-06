local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BillboardGui = script:WaitForChild("BillboardGui")
local HoverEvent = ReplicatedStorage.Events:WaitForChild("Hover")
local store = workspace:WaitForChild("ClothesStore")

local function Hovered(ClickDetector:ClickDetector, bool: boolean)
	if bool then
		local clone = BillboardGui:Clone()
		clone.Parent = ClickDetector.Parent
		clone.Adornee = ClickDetector.Parent.PrimaryPart
		clone.Enabled = true
		local TextLabel = clone:FindFirstChildOfClass("TextLabel")
		TextLabel.Text = ClickDetector.Parent:GetAttribute("Purchased") and "Equip" or "100 Coins"
	else
		local clone = ClickDetector.Parent:FindFirstChild("BillboardGui")
		if clone then
			clone:Destroy()
		end
	end
end

for _, v in store:GetDescendants() do
	if not v:IsA("ClickDetector") then
		continue
	end

	local HoveredEvent = game.ReplicatedStorage.Events.Hover

	v.MouseHoverEnter:Connect(function()
		Hovered(v, true)
	end)

	v.MouseHoverLeave:Connect(function()
		Hovered(v, false)
	end)

	v.MouseClick:Connect(function(player: Player)
		local Cash = player.leaderstats.Cash
		local Character = player.Character or player.CharacterAdded:Wait()
		local Purchase = ReplicatedStorage.Events.Purchase
		
		local Rig = v.Parent.Parent.Rig
		local Hat = Rig:FindFirstChildOfClass("Accessory")
		local Purchased = Purchase:InvokeServer(v)
		
		if not Purchased then
			task.spawn(function()
				local CashLabel = player.PlayerGui.ScreenGui.Cash
				local bool = false
				for i = 1,4 do
					bool = not bool
					CashLabel.TextColor3 = bool and Color3.new(1,0,0) or Color3.new(1,1,1)
					task.wait(0.15)
				end
			end)
			return
		end
		
		if not v.Parent:GetAttribute("Purchased") then
			v.Parent:SetAttribute("Purchased", true)
			task.spawn(function()
				local CashLabel = player.PlayerGui.ScreenGui.Cash
				local bool = false
				for i = 1,2 do
					bool = not bool
					CashLabel.TextColor3 = bool and Color3.new(0.0784314, 1, 0.509804) or Color3.new(1,1,1)
					task.wait(0.15)
				end
			end)
		end
	end)
end