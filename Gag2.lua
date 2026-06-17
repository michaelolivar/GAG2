-- Grow a Garden 2 - Harvest Elite Premium v7
-- Redesigned like your Mockup | by Grok

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Config
local Config = {
    AutoCollect = false,
    CollectDelay = 0.5,
    WalkSpeed = 70,
    SelectedMode = "All",
}

local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = title, Text = text, Duration = 4})
end

-- ==================== COLLECTOR LOGIC ====================
local function GetEventSeeds()
    local seeds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) then
            local n = obj.Name:lower()
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                if Config.SelectedMode == "All" or
                   (Config.SelectedMode == "Gold" and n:find("gold")) or
                   (Config.SelectedMode == "Rainbow" and n:find("rainbow")) or
                   (Config.SelectedMode == "Event" and (n:find("event") or n:find("pack"))) then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

local function CollectSeed(seed)
    if not seed or not seed.Parent then return end
    local prompt = seed:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = seed:GetPivot()}):Play():Wait()
            fireproximityprompt(prompt)
            task.wait(Config.CollectDelay)
        end
    end
end

local connection
local function ToggleAutoCollect(state)
    Config.AutoCollect = state
    if state then
        Notify("Harvest Elite", "✅ Auto Collect Started ("..Config.SelectedMode..")")
        connection = RunService.Heartbeat:Connect(function()
            if not Config.AutoCollect then return end
            for _, seed in ipairs(GetEventSeeds()) do pcall(CollectSeed, seed) end
        end)
    else
        if connection then connection:Disconnect() end
        Notify("Harvest Elite", "⛔ Auto Collect Stopped")
    end
end

-- ==================== HARVEST ELITE UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "HarvestElite_GAG2"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 480, 0, 520)
Main.Position = UDim2.new(0.5, -240, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(40, 160, 100)
MainStroke.Thickness = 2

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundTransparency = 1
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.6, 0, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 HARVEST ELITE • v2.1.0"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local StatusBadge = Instance.new("TextLabel")
StatusBadge.Size = UDim2.new(0, 55, 0, 20)
StatusBadge.Position = UDim2.new(0, 260, 0, 15)
StatusBadge.BackgroundColor3 = Color3.fromRGB(20, 60, 40)
StatusBadge.Text = "ACTIVE"
StatusBadge.TextColor3 = Color3.fromRGB(50, 200, 100)
StatusBadge.TextSize = 11
StatusBadge.Font = Enum.Font.GothamBold
StatusBadge.Parent = TitleBar
Instance.new("UICorner", StatusBadge).CornerRadius = UDim.new(0, 4)
local BadgeStroke = Instance.new("UIStroke", StatusBadge)
BadgeStroke.Color = Color3.fromRGB(50, 200, 100)
BadgeStroke.Thickness = 1

local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 30, 0, 30)
HideBtn.Position = UDim2.new(1, -70, 0, 10)
HideBtn.BackgroundTransparency = 1
HideBtn.Text = "—"
HideBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
HideBtn.TextSize = 16
HideBtn.Parent = TitleBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
CloseBtn.TextSize = 16
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local TopLine = Instance.new("Frame")
TopLine.Size = UDim2.new(1, 0, 0, 1)
TopLine.Position = UDim2.new(0, 0, 1, 0)
TopLine.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
TopLine.BorderSizePixel = 0
TopLine.Parent = TitleBar

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, -30, 0, 40)
TabFrame.Position = UDim2.new(0, 15, 0, 55)
TabFrame.BackgroundTransparency = 1
TabFrame.Parent = Main

local tabs = {
    {name = "Main", icon = "🏠"},
    {name = "Events", icon = "🎯"},
    {name = "Farm", icon = "🌱"},
    {name = "Inventory", icon = "📦"},
    {name = "Logs", icon = "📋"}
}

for i, tabInfo in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1/#tabs, 0, 1, 0)
    tabBtn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = tabInfo.icon .. " " .. tabInfo.name
    tabBtn.TextColor3 = tabInfo.name == "Main" and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(150, 150, 160)
    tabBtn.TextSize = 14
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Parent = TabFrame
    
    if tabInfo.name == "Main" then
        local indicator = Instance.new("Frame")
        indicator.Size = UDim2.new(0.6, 0, 0, 2)
        indicator.Position = UDim2.new(0.2, 0, 1, -2)
        indicator.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        indicator.BorderSizePixel = 0
        indicator.Parent = tabBtn
    end
end

-- Main Content Area
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -30, 1, -110)
Content.Position = UDim2.new(0, 15, 0, 100)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 0
Content.Parent = Main

local UIListLayout = Instance.new("UIListLayout", Content)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 20)

local function CreateSectionLabel(text, icon)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 20)
    lbl.BackgroundTransparency = 1
    lbl.Text = icon .. " " .. text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 160)
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Font = Enum.Font.GothamBold
    return lbl
end

local function CreatePanel(parent, size, pos)
    local panel = Instance.new("Frame")
    panel.Size = size
    panel.Position = pos
    panel.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
    panel.Parent = parent
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(35, 40, 55)
    stroke.Thickness = 1
    return panel, stroke
end

-- 1. SYSTEM STATUS
local StatusSection = Instance.new("Frame")
StatusSection.Size = UDim2.new(1, 0, 0, 125)
StatusSection.BackgroundTransparency = 1
StatusSection.Parent = Content

CreateSectionLabel("SYSTEM STATUS", "📊").Parent = StatusSection

local p1 = CreatePanel(StatusSection, UDim2.new(0.48, 0, 0, 45), UDim2.new(0, 0, 0, 30))
local l1 = Instance.new("TextLabel", p1)
l1.Size = UDim2.new(1, -20, 1, 0); l1.Position = UDim2.new(0, 10, 0, 0)
l1.BackgroundTransparency = 1; l1.TextXAlignment = Enum.TextXAlignment.Left
l1.Text = "⚡ Script Status: <font color=\"#32c864\">Running</font>"
l1.RichText = true; l1.TextColor3 = Color3.fromRGB(220, 220, 220); l1.TextSize = 14; l1.Font = Enum.Font.GothamMedium

local p2, p2Stroke = CreatePanel(StatusSection, UDim2.new(0.48, 0, 0, 45), UDim2.new(0.52, 0, 0, 30))
p2.BackgroundColor3 = Color3.fromRGB(35, 35, 30)
p2Stroke.Color = Color3.fromRGB(180, 140, 50)
local l2 = Instance.new("TextLabel", p2)
l2.Size = UDim2.new(1, -20, 1, 0); l2.Position = UDim2.new(0, 10, 0, 0)
l2.BackgroundTransparency = 1; l2.TextXAlignment = Enum.TextXAlignment.Left
l2.Text = "💰 Balance: <font color=\"#dcb432\">₿1,000</font>"
l2.RichText = true; l2.TextColor3 = Color3.fromRGB(220, 220, 220); l2.TextSize = 14; l2.Font = Enum.Font.GothamMedium

local p3 = CreatePanel(StatusSection, UDim2.new(0.48, 0, 0, 45), UDim2.new(0, 0, 0, 85))
local l3 = Instance.new("TextLabel", p3)
l3.Size = UDim2.new(1, -20, 1, 0); l3.Position = UDim2.new(0, 10, 0, 0)
l3.BackgroundTransparency = 1; l3.TextXAlignment = Enum.TextXAlignment.Left
l3.Text = "🌱 Plants Active: 0"
l3.TextColor3 = Color3.fromRGB(220, 220, 220); l3.TextSize = 14; l3.Font = Enum.Font.GothamMedium

local p4 = CreatePanel(StatusSection, UDim2.new(0.48, 0, 0, 45), UDim2.new(0.52, 0, 0, 85))
local l4 = Instance.new("TextLabel", p4)
l4.Size = UDim2.new(1, -20, 1, 0); l4.Position = UDim2.new(0, 10, 0, 0)
l4.BackgroundTransparency = 1; l4.TextXAlignment = Enum.TextXAlignment.Left
l4.Text = "📦 Seeds Owned: 5"
l4.TextColor3 = Color3.fromRGB(220, 220, 220); l4.TextSize = 14; l4.Font = Enum.Font.GothamMedium

-- 2. QUICK ACTIONS
local QuickSection = Instance.new("Frame")
QuickSection.Size = UDim2.new(1, 0, 0, 80)
QuickSection.BackgroundTransparency = 1
QuickSection.Parent = Content

CreateSectionLabel("QUICK ACTIONS", "⚡").Parent = QuickSection

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.32, 0, 0, 45)
StartBtn.Position = UDim2.new(0, 0, 0, 30)
StartBtn.BackgroundColor3 = Color3.fromRGB(35, 150, 75)
StartBtn.Text = "▶ Start All"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.TextSize = 15
StartBtn.Font = Enum.Font.GothamBold
StartBtn.Parent = QuickSection
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 8)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.32, 0, 0, 45)
StopBtn.Position = UDim2.new(0.34, 0, 0, 30)
StopBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
StopBtn.Text = "⏹ Stop All"
StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StopBtn.TextSize = 15
StopBtn.Font = Enum.Font.GothamBold
StopBtn.Parent = QuickSection
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 8)

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.32, 0, 0, 45)
RefreshBtn.Position = UDim2.new(0.68, 0, 0, 30)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(220, 140, 30)
RefreshBtn.Text = "🔄 Refresh"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.TextSize = 15
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.Parent = QuickSection
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 8)

-- 3. SESSION STATISTICS
local StatsSection = Instance.new("Frame")
StatsSection.Size = UDim2.new(1, 0, 0, 145)
StatsSection.BackgroundTransparency = 1
StatsSection.Parent = Content

CreateSectionLabel("SESSION STATISTICS", "📈").Parent = StatsSection

local s1 = CreatePanel(StatsSection, UDim2.new(0.48, 0, 0, 52), UDim2.new(0, 0, 0, 30))
local sl1 = Instance.new("TextLabel", s1)
sl1.Size = UDim2.new(1, -20, 1, 0); sl1.Position = UDim2.new(0, 10, 0, 0)
sl1.BackgroundTransparency = 1; sl1.TextXAlignment = Enum.TextXAlignment.Left
sl1.Text = "📈 Farm Score:\n<b>0.260</b>"
sl1.RichText = true; sl1.TextColor3 = Color3.fromRGB(220, 220, 220); sl1.TextSize = 14; sl1.Font = Enum.Font.GothamMedium

local s2 = CreatePanel(StatsSection, UDim2.new(0.48, 0, 0, 52), UDim2.new(0.52, 0, 0, 30))
local sl2 = Instance.new("TextLabel", s2)
sl2.Size = UDim2.new(1, -20, 1, 0); sl2.Position = UDim2.new(0, 10, 0, 0)
sl2.BackgroundTransparency = 1; sl2.TextXAlignment = Enum.TextXAlignment.Left
sl2.Text = "🌱 Plantt Plants:\n<b>0</b>"
sl2.RichText = true; sl2.TextColor3 = Color3.fromRGB(220, 220, 220); sl2.TextSize = 14; sl2.Font = Enum.Font.GothamMedium

local s3 = CreatePanel(StatsSection, UDim2.new(0.48, 0, 0, 52), UDim2.new(0, 0, 0, 92))
local sl3 = Instance.new("TextLabel", s3)
sl3.Size = UDim2.new(1, -20, 1, 0); sl3.Position = UDim2.new(0, 10, 0, 0)
sl3.BackgroundTransparency = 1; sl3.TextXAlignment = Enum.TextXAlignment.Left
sl3.Text = "🛠 Farminite Active:\n<b>0.15</b>"
sl3.RichText = true; sl3.TextColor3 = Color3.fromRGB(220, 220, 220); sl3.TextSize = 14; sl3.Font = Enum.Font.GothamMedium

local s4 = CreatePanel(StatsSection, UDim2.new(0.48, 0, 0, 52), UDim2.new(0.52, 0, 0, 92))
local sl4 = Instance.new("TextLabel", s4)
sl4.Size = UDim2.new(1, -20, 1, 0); sl4.Position = UDim2.new(0, 10, 0, 0)
sl4.BackgroundTransparency = 1; sl4.TextXAlignment = Enum.TextXAlignment.Left
sl4.Text = "📦 Seeds Seeds Rate:\n<b>0</b>"
sl4.RichText = true; sl4.TextColor3 = Color3.fromRGB(220, 220, 220); sl4.TextSize = 14; sl4.Font = Enum.Font.GothamMedium

-- Auto Collect Controls
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 50)
ToggleBtn.Position = UDim2.new(0, 0, 0, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
ToggleBtn.Text = "🔄 Auto Collect Event Seeds\nOFF"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Content
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
local ToggleBtnStroke = Instance.new("UIStroke", ToggleBtn)
ToggleBtnStroke.Color = Color3.fromRGB(35, 40, 55)
ToggleBtnStroke.Thickness = 1

ToggleBtn.MouseButton1Click:Connect(function()
    local new = not Config.AutoCollect
    ToggleAutoCollect(new)
    ToggleBtn.Text = "🔄 Auto Collect Event Seeds\n" .. (new and "✅ ON ("..Config.SelectedMode..")" or "⛔ OFF")
    ToggleBtn.BackgroundColor3 = new and Color3.fromRGB(35, 150, 75) or Color3.fromRGB(25, 30, 42)
end)

-- WalkSpeed
local WSBtn = Instance.new("TextButton")
WSBtn.Size = UDim2.new(1, 0, 0, 50)
WSBtn.Position = UDim2.new(0, 0, 0, 0)
WSBtn.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
WSBtn.Text = "⚡ WalkSpeed 70\nOFF"
WSBtn.TextColor3 = Color3.new(1,1,1)
WSBtn.TextScaled = true
WSBtn.Font = Enum.Font.GothamSemibold
WSBtn.Parent = Content
Instance.new("UICorner", WSBtn).CornerRadius = UDim.new(0, 8)
local WSBtnStroke = Instance.new("UIStroke", WSBtn)
WSBtnStroke.Color = Color3.fromRGB(35, 40, 55)
WSBtnStroke.Thickness = 1

WSBtn.MouseButton1Click:Connect(function()
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = hum.WalkSpeed > 20 and 16 or Config.WalkSpeed
        WSBtn.Text = "⚡ WalkSpeed 70\n" .. (hum.WalkSpeed > 20 and "✅ ON" or "OFF")
        WSBtn.BackgroundColor3 = (hum.WalkSpeed > 20) and Color3.fromRGB(35, 150, 75) or Color3.fromRGB(25, 30, 42)
    end
end)

-- Logic mapping
StartBtn.MouseButton1Click:Connect(function() ToggleAutoCollect(true) end)
StopBtn.MouseButton1Click:Connect(function() ToggleAutoCollect(false) end)
RefreshBtn.MouseButton1Click:Connect(function() Notify("Harvest Elite", "UI Refreshed") end)

-- Bubble (Minimize)
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 60, 0, 60)
Bubble.Position = UDim2.new(1, -80, 1, -80)
Bubble.BackgroundColor3 = Color3.fromRGB(25, 30, 42)
Bubble.Text = "🌱"
Bubble.TextSize = 24
Bubble.Visible = false
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1,0)
local BubbleStroke = Instance.new("UIStroke", Bubble)
BubbleStroke.Color = Color3.fromRGB(40, 160, 100)
BubbleStroke.Thickness = 2

Bubble.MouseButton1Click:Connect(function()
    Main.Visible = true
    Bubble.Visible = false
end)

HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Bubble.Visible = true
end)

Notify("✅ Harvest beb", "Redesigned to match the dark mockup!")