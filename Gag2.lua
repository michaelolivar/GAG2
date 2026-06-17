local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HarvestElite"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 760, 0, 650)
Main.Position = UDim2.new(0.5, -380, 0.5, -325)
Main.BackgroundColor3 = Color3.fromRGB(8,12,25)
Main.Parent = ScreenGui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0,16)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(0,255,150)
Stroke.Thickness = 2
Stroke.Parent = Main

-- HEADER

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,70)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(0,400,1,0)
Title.Position = UDim2.new(0,20,0,0)
Title.Font = Enum.Font.GothamBold
Title.Text = "🌱 HARVEST ELITE • v2.1.0"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 28
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Active = Instance.new("TextLabel")
Active.Size = UDim2.new(0,90,0,35)
Active.Position = UDim2.new(0,430,0.5,-17)
Active.BackgroundColor3 = Color3.fromRGB(20,120,70)
Active.Text = "ACTIVE"
Active.Font = Enum.Font.GothamBold
Active.TextColor3 = Color3.new(1,1,1)
Active.TextSize = 18
Active.Parent = Header

Instance.new("UICorner",Active)

-- TABS

local Tabs = Instance.new("Frame")
Tabs.Size = UDim2.new(1,-20,0,50)
Tabs.Position = UDim2.new(0,10,0,75)
Tabs.BackgroundTransparency = 1
Tabs.Parent = Main

local TabNames = {"Main","Events","Farm","Inventory","Logs"}

for i,v in ipairs(TabNames) do
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(0,130,1,0)
	Btn.Position = UDim2.new(0,(i-1)*145,0,0)
	Btn.BackgroundTransparency = 1
	Btn.Text = v
	Btn.Font = Enum.Font.Gotham
	Btn.TextSize = 20

	if i == 1 then
		Btn.TextColor3 = Color3.fromRGB(0,255,150)
	else
		Btn.TextColor3 = Color3.fromRGB(180,180,180)
	end

	Btn.Parent = Tabs
end

-- SECTION TITLE

local StatusTitle = Instance.new("TextLabel")
StatusTitle.BackgroundTransparency = 1
StatusTitle.Position = UDim2.new(0,25,0,145)
StatusTitle.Size = UDim2.new(0,250,0,40)
StatusTitle.Text = "📊 SYSTEM STATUS"
StatusTitle.Font = Enum.Font.GothamBold
StatusTitle.TextSize = 24
StatusTitle.TextColor3 = Color3.new(1,1,1)
StatusTitle.TextXAlignment = Enum.TextXAlignment.Left
StatusTitle.Parent = Main

local function CreateCard(x,y,title,value,color)
	local Card = Instance.new("Frame")
	Card.Size = UDim2.new(0,320,0,80)
	Card.Position = UDim2.new(0,x,0,y)
	Card.BackgroundColor3 = Color3.fromRGB(18,28,48)
	Card.Parent = Main

	Instance.new("UICorner",Card)

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(50,70,110)
	Stroke.Parent = Card

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.new(0,15,0,10)
	Label.Size = UDim2.new(1,-20,0,25)
	Label.Text = title
	Label.Font = Enum.Font.Gotham
	Label.TextColor3 = Color3.new(1,1,1)
	Label.TextSize = 18
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.Parent = Card

	local Value = Instance.new("TextLabel")
	Value.BackgroundTransparency = 1
	Value.Position = UDim2.new(0,15,0,35)
	Value.Size = UDim2.new(1,-20,0,30)
	Value.Text = value
	Value.Font = Enum.Font.GothamBold
	Value.TextColor3 = color
	Value.TextSize = 22
	Value.TextXAlignment = Enum.TextXAlignment.Left
	Value.Parent = Card

	return Value
end

local ScriptStatus = CreateCard(25,190,"⚡ Script Status","Running",Color3.fromRGB(0,255,150))
local Balance = CreateCard(390,190,"💰 Balance","₿1,000",Color3.fromRGB(255,200,0))
local Plants = CreateCard(25,285,"🌱 Plants Active","0",Color3.fromRGB(255,255,255))
local Seeds = CreateCard(390,285,"📦 Seeds Owned","5",Color3.fromRGB(255,255,255))

-- BUTTONS

local function CreateButton(text,color,x)
	local Btn = Instance.new("TextButton")
	Btn.Size = UDim2.new(0,200,0,60)
	Btn.Position = UDim2.new(0,x,0,410)
	Btn.BackgroundColor3 = color
	Btn.Text = text
	Btn.Font = Enum.Font.GothamBold
	Btn.TextSize = 22
	Btn.TextColor3 = Color3.new(1,1,1)
	Btn.Parent = Main

	Instance.new("UICorner",Btn)

	local Original = color

	Btn.MouseEnter:Connect(function()
		TweenService:Create(
			Btn,
			TweenInfo.new(.15),
			{BackgroundColor3 = Original:Lerp(Color3.new(1,1,1),0.15)}
		):Play()
	end)

	Btn.MouseLeave:Connect(function()
		TweenService:Create(
			Btn,
			TweenInfo.new(.15),
			{BackgroundColor3 = Original}
		):Play()
	end)

	return Btn
end

local StartBtn = CreateButton("▶ Start All",Color3.fromRGB(20,180,100),25)
local StopBtn = CreateButton("■ Stop All",Color3.fromRGB(200,60,60),280)
local RefreshBtn = CreateButton("↻ Refresh",Color3.fromRGB(220,150,20),535)

StartBtn.MouseButton1Click:Connect(function()
	ScriptStatus.Text = "Running"
	ScriptStatus.TextColor3 = Color3.fromRGB(0,255,150)
end)

StopBtn.MouseButton1Click:Connect(function()
	ScriptStatus.Text = "Stopped"
	ScriptStatus.TextColor3 = Color3.fromRGB(255,80,80)
end)

RefreshBtn.MouseButton1Click:Connect(function()
	print("Refresh Clicked")
end)