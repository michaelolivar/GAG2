-- Grow a Garden 2 - Premium Auto Event Seed Collector v6
-- WalkSpeed Fixed + Dropdown for Events | Messenger Bubble | by Grok

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
    SelectedMode = "All",  -- All, Gold, Rainbow, Event
}

local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 4,
    })
end

-- ==================== COLLECTOR LOGIC ====================
local function GetEventSeeds()
    local seeds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local n = obj.Name:lower()
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                if Config.SelectedMode == "All" then
                    if n:find("gold") or n:find("rainbow") or n:find("event") or n:find("seed") or n:find("pack") then
                        table.insert(seeds, obj)
                    end
                elseif Config.SelectedMode == "Gold" and n:find("gold") then
                    table.insert(seeds, obj)
                elseif Config.SelectedMode == "Rainbow" and n:find("rainbow") then
                    table.insert(seeds, obj)
                elseif Config.SelectedMode == "Event" and (n:find("event") or n:find("pack")) then
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
    if not prompt then return end

    local root = character:FindFirstChild("HumanoidRootPart")
    if root then
        local tween = TweenService:Create(root, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {CFrame = seed:GetPivot()})
        tween:Play()
        tween.Completed:Wait()
        fireproximityprompt(prompt)
        task.wait(Config.CollectDelay)
    end
end

local connection
local function ToggleAutoCollect(state)
    Config.AutoCollect = state
    if state then
        Notify("Auto Collect", "✅ Started (" .. Config.SelectedMode .. " Mode)")
        connection = RunService.Heartbeat:Connect(function()
            if not Config.AutoCollect then return end
            for _, seed in ipairs(GetEventSeeds()) do
                pcall(CollectSeed, seed)
            end
        end)
    else
        if connection then connection:Disconnect() end
        Notify("Auto Collect", "⛔ Stopped")
    end
end

-- ==================== UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GAG2_Premium_v6"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 550)
Main.Position = UDim2.new(0.5, -230, 0.5, -275)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -170, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 Grow a Garden 2 Premium"
Title.TextColor3 = Color3.fromRGB(80, 255, 140)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

-- Hide Button
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 55, 0, 50)
HideBtn.Position = UDim2.new(1, -165, 0, 5)
HideBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 100)
HideBtn.Text = "↓ Hide"
HideBtn.TextColor3 = Color3.new(1,1,1)
HideBtn.TextScaled = true
HideBtn.Parent = TitleBar
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 10)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 50, 0, 50)
CloseBtn.Position = UDim2.new(1, -60, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextScaled = true
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

-- Scrolling
local Scrolling = Instance.new("ScrollingFrame")
Scrolling.Size = UDim2.new(1, -20, 1, -80)
Scrolling.Position = UDim2.new(0, 10, 0, 70)
Scrolling.BackgroundTransparency = 1
Scrolling.ScrollBarThickness = 6
Scrolling.Parent = Main

local UIList = Instance.new("UIListLayout")
UIList.Padding = UDim.new(0, 12)
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Parent = Scrolling

-- Auto Collect Toggle + Dropdown
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 70)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ToggleBtn.Text = "🔄 Auto Collect\nOFF"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Scrolling
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

ToggleBtn.MouseButton1Click:Connect(function()
    local newState = not Config.AutoCollect
    ToggleAutoCollect(newState)
    ToggleBtn.Text = "🔄 Auto Collect\n" .. (newState and "✅ ON ("..Config.SelectedMode..")" or "⛔ OFF")
    ToggleBtn.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(40, 40, 55)
end)

-- Dropdown for Mode
local ModeLabel = Instance.new("TextLabel")
ModeLabel.Size = UDim2.new(1, -20, 0, 35)
ModeLabel.BackgroundTransparency = 1
ModeLabel.Text = "Collect Mode:"
ModeLabel.TextColor3 = Color3.fromRGB(200,200,210)
ModeLabel.TextScaled = true
ModeLabel.Parent = Scrolling

local ModeButton = Instance.new("TextButton")
ModeButton.Size = UDim2.new(1, -20, 0, 50)
ModeButton.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
ModeButton.Text = "All Events"
ModeButton.TextColor3 = Color3.new(1,1,1)
ModeButton.TextScaled = true
ModeButton.Parent = Scrolling
Instance.new("UICorner", ModeButton).CornerRadius = UDim.new(0, 10)

-- Simple Dropdown Options
local modes = {"All", "Gold", "Rainbow", "Event"}
local currentIndex = 1

ModeButton.MouseButton1Click:Connect(function()
    currentIndex = currentIndex % #modes + 1
    Config.SelectedMode = modes[currentIndex]
    ModeButton.Text = Config.SelectedMode .. " Events"
    
    if Config.AutoCollect then
        ToggleAutoCollect(false)
        task.wait(0.2)
        ToggleAutoCollect(true)
    end
end)

-- WalkSpeed Boost (Fixed)
local WSBtn = Instance.new("TextButton")
WSBtn.Size = UDim2.new(1, -20, 0, 65)
WSBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
WSBtn.Text = "⚡ WalkSpeed " .. Config.WalkSpeed .. "\nOFF"
WSBtn.TextColor3 = Color3.new(1,1,1)
WSBtn.TextScaled = true
WSBtn.Parent = Scrolling
Instance.new("UICorner", WSBtn).CornerRadius = UDim.new(0, 12)

WSBtn.MouseButton1Click:Connect(function()
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed > 20 then
            hum.WalkSpeed = 16
            WSBtn.Text = "⚡ WalkSpeed " .. Config.WalkSpeed .. "\nOFF"
        else
            hum.WalkSpeed = Config.WalkSpeed
            WSBtn.Text = "⚡ WalkSpeed " .. Config.WalkSpeed .. "\n✅ ON"
        end
    end
end)

Scrolling.CanvasSize = UDim2.new(0,0,0, UIList.AbsoluteContentSize.Y + 50)

-- ==================== MESSENGER BUBBLE ====================
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 80, 0, 80)
Bubble.Position = UDim2.new(1, -110, 1, -160)
Bubble.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
Bubble.Text = "🌱\nGAG2"
Bubble.TextColor3 = Color3.new(1,1,1)
Bubble.TextScaled = true
Bubble.Font = Enum.Font.GothamBold
Bubble.Visible = false
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", Bubble).Thickness = 3

Bubble.MouseButton1Click:Connect(function()
    Main.Visible = true
    Bubble.Visible = false
end)

-- Bubble Draggable
local bubbleDrag
Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bubbleDrag = true
        local startPos = Bubble.Position
        local startMouse = UserInputService:GetMouseLocation()
        local conn = RunService.RenderStepped:Connect(function()
            if not bubbleDrag then conn:Disconnect() return end
            local delta = UserInputService:GetMouseLocation() - startMouse
            Bubble.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)
    end
end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then bubbleDrag = false end end)

-- Hide / Show
HideBtn.MouseButton1Click:Connect(function()
    Main.Visible = false
    Bubble.Visible = true
end)

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- RightShift Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if Main.Visible then
            Main.Visible = false
            Bubble.Visible = true
        else
            Main.Visible = true
            Bubble.Visible = false
        end
    end
end)

-- Draggable Main UI
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

Notify("✅ v6 Loaded beb", "WalkSpeed at Dropdown na available!")