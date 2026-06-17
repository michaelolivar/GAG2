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
Main.Size = UDim2.new(0, 520, 0, 580)
Main.Position = UDim2.new(0.5, -260, 0.5, -290)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", Main).Color = Color3.fromRGB(0, 255, 140); Instance.new("UIStroke", Main).Thickness = 2

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 70)
TitleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 16)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0.7, 0, 1, 0)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 HARVEST ELITE • v2.1.0"
Title.TextColor3 = Color3.fromRGB(0, 255, 140)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.25, 0, 0.5, 0)
Status.Position = UDim2.new(0.72, 0, 0.25, 0)
Status.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
Status.Text = "ACTIVE"
Status.TextColor3 = Color3.new(1,1,1)
Status.TextScaled = true
Status.Font = Enum.Font.GothamBold
Status.Parent = TitleBar
Instance.new("UICorner", Status).CornerRadius = UDim.new(0, 8)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 50, 0, 50)
CloseBtn.Position = UDim2.new(1, -55, 0, 10)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextScaled = true
CloseBtn.Parent = TitleBar
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Tabs
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, -40, 0, 50)
TabFrame.Position = UDim2.new(0, 20, 0, 80)
TabFrame.BackgroundTransparency = 1
TabFrame.Parent = Main

local tabs = {"Main", "Events", "Farm", "Inventory", "Logs"}
local currentTab = "Main"

for i, tabName in ipairs(tabs) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1/#tabs - 0.02, 0, 1, 0)
    tabBtn.Position = UDim2.new((i-1)/#tabs, 0, 0, 0)
    tabBtn.BackgroundColor3 = tabName == "Main" and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(30, 30, 40)
    tabBtn.Text = tabName
    tabBtn.TextColor3 = Color3.new(1,1,1)
    tabBtn.TextScaled = true
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.Parent = TabFrame
    Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 10)
end

-- Main Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -40, 1, -160)
Content.Position = UDim2.new(0, 20, 0, 150)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- System Status
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, 0, 0, 30)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "SYSTEM STATUS"
StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
StatusLabel.TextScaled = true
StatusLabel.Font = Enum.Font.GothamBold
StatusLabel.Parent = Content

-- Quick Actions
local QuickFrame = Instance.new("Frame")
QuickFrame.Size = UDim2.new(1, 0, 0, 70)
QuickFrame.Position = UDim2.new(0, 0, 0, 40)
QuickFrame.BackgroundTransparency = 1
QuickFrame.Parent = Content

local StartBtn = Instance.new("TextButton")
StartBtn.Size = UDim2.new(0.32, 0, 1, 0)
StartBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
StartBtn.Text = "▶ Start All"
StartBtn.TextColor3 = Color3.new(1,1,1)
StartBtn.TextScaled = true
StartBtn.Parent = QuickFrame
Instance.new("UICorner", StartBtn).CornerRadius = UDim.new(0, 12)

local StopBtn = Instance.new("TextButton")
StopBtn.Size = UDim2.new(0.32, 0, 1, 0)
StopBtn.Position = UDim2.new(0.34, 0, 0, 0)
StopBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
StopBtn.Text = "⏹ Stop All"
StopBtn.TextColor3 = Color3.new(1,1,1)
StopBtn.TextScaled = true
StopBtn.Parent = QuickFrame
Instance.new("UICorner", StopBtn).CornerRadius = UDim.new(0, 12)

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.32, 0, 1, 0)
RefreshBtn.Position = UDim2.new(0.68, 0, 0, 0)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(255, 160, 50)
RefreshBtn.Text = "⟳ Refresh"
RefreshBtn.TextColor3 = Color3.new(1,1,1)
RefreshBtn.TextScaled = true
RefreshBtn.Parent = QuickFrame
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 12)

-- Auto Collect Controls
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, 0, 0, 65)
ToggleBtn.Position = UDim2.new(0, 0, 0, 130)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ToggleBtn.Text = "🔄 Auto Collect Event Seeds\nOFF"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Content
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

ToggleBtn.MouseButton1Click:Connect(function()
    local new = not Config.AutoCollect
    ToggleAutoCollect(new)
    ToggleBtn.Text = "🔄 Auto Collect Event Seeds\n" .. (new and "✅ ON ("..Config.SelectedMode..")" or "⛔ OFF")
    ToggleBtn.BackgroundColor3 = new and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(40, 40, 55)
end)

StartBtn.MouseButton1Click:Connect(function() ToggleAutoCollect(true) end)
StopBtn.MouseButton1Click:Connect(function() ToggleAutoCollect(false) end)

-- WalkSpeed
local WSBtn = Instance.new("TextButton")
WSBtn.Size = UDim2.new(1, 0, 0, 60)
WSBtn.Position = UDim2.new(0, 0, 0, 210)
WSBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
WSBtn.Text = "⚡ WalkSpeed 70\nOFF"
WSBtn.TextColor3 = Color3.new(1,1,1)
WSBtn.TextScaled = true
WSBtn.Parent = Content
Instance.new("UICorner", WSBtn).CornerRadius = UDim.new(0, 12)

WSBtn.MouseButton1Click:Connect(function()
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = hum.WalkSpeed > 20 and 16 or Config.WalkSpeed
        WSBtn.Text = "⚡ WalkSpeed 70\n" .. (hum.WalkSpeed > 20 and "✅ ON" or "OFF")
    end
end)

-- Hide to Bubble
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 85, 0, 85)
Bubble.Position = UDim2.new(1, -120, 1, -180)
Bubble.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
Bubble.Text = "🌱\nHarvest"
Bubble.TextScaled = true
Bubble.Visible = false
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", Bubble)

Bubble.MouseButton1Click:Connect(function()
    Main.Visible = true
    Bubble.Visible = false
end)

-- Hide Button
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 50, 0, 50)
HideBtn.Position = UDim2.new(1, -110, 0, 10)
HideBtn.BackgroundTransparency = 1
HideBtn.Text = "↓"
HideBtn.TextColor3 = Color3.fromRGB(0, 255, 140)
HideBtn.TextScaled = true
HideBtn.Parent = TitleBar
HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Bubble.Visible = true
end)

Notify("✅ Harvest Elite UI Loaded", "Redesigned to match your mockup!")