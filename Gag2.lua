-- Grow a Garden 2 - Premium Auto Event Seed Collector v4
-- Messenger Bubble Hide + Draggable UI | by Grok

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
    CollectDelay = 0.6,
    WalkSpeed = 60,
    NotifyEnabled = true,
}

local function Notify(title, text)
    if not Config.NotifyEnabled then return end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 4,
    })
end

-- ==================== SEED COLLECTOR LOGIC ====================
local function GetEventSeeds()
    local seeds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Part")) then
            local n = obj.Name:lower()
            if n:find("gold") or n:find("rainbow") or n:find("event") or n:find("seed") or n:find("pack") then
                if obj:FindFirstChildWhichIsA("ProximityPrompt") then
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
        local tween = TweenService:Create(root, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {CFrame = seed:GetPivot()})
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
        Notify("Auto Collect", "✅ Started")
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
ScreenGui.Name = "GAG2_Premium_v4"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Main Frame
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 520)
Main.Position = UDim2.new(0.5, -230, 0.5, -260)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.Visible = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 14)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 60)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 14)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -160, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 Grow a Garden 2 - Premium"
Title.TextColor3 = Color3.fromRGB(80, 255, 140)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

-- Hide Button
local HideBtn = Instance.new("TextButton")
HideBtn.Size = UDim2.new(0, 50, 0, 50)
HideBtn.Position = UDim2.new(1, -155, 0, 5)
HideBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
HideBtn.Text = "👁️"
HideBtn.TextScaled = true
HideBtn.Parent = TitleBar
Instance.new("UICorner", HideBtn).CornerRadius = UDim.new(0, 10)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 50, 0, 50)
CloseBtn.Position = UDim2.new(1, -105, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextScaled = true
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 10)

-- Scrolling Content (same as before)
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

-- Toggle, Delay, WalkSpeed (same as v3)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 65)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
ToggleBtn.Text = "🔄 Auto Collect Event Seeds\nOFF"
ToggleBtn.TextColor3 = Color3.new(1,1,1)
ToggleBtn.TextScaled = true
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Scrolling
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 12)

ToggleBtn.MouseButton1Click:Connect(function()
    local new = not Config.AutoCollect
    ToggleAutoCollect(new)
    ToggleBtn.Text = "🔄 Auto Collect Event Seeds\n" .. (new and "✅ ON" or "⛔ OFF")
    ToggleBtn.BackgroundColor3 = new and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(40, 40, 55)
end)

-- Delay controls...
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(1, -20, 0, 40)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Collect Delay: 0.6s"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
DelayLabel.TextScaled = true
DelayLabel.Parent = Scrolling

local DelayFrame = Instance.new("Frame")
DelayFrame.Size = UDim2.new(1, -20, 0, 50)
DelayFrame.BackgroundTransparency = 1
DelayFrame.Parent = Scrolling

local Minus = Instance.new("TextButton")
Minus.Size = UDim2.new(0.45, 0, 1, 0)
Minus.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
Minus.Text = "-0.1s"
Minus.TextScaled = true
Minus.Parent = DelayFrame
Instance.new("UICorner", Minus).CornerRadius = UDim.new(0, 10)
Minus.MouseButton1Click:Connect(function()
    Config.CollectDelay = math.clamp(Config.CollectDelay - 0.1, 0.1, 2)
    DelayLabel.Text = "Collect Delay: " .. string.format("%.1f", Config.CollectDelay) .. "s"
end)

local Plus = Instance.new("TextButton")
Plus.Size = UDim2.new(0.45, 0, 1, 0)
Plus.Position = UDim2.new(0.55, 0, 0, 0)
Plus.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
Plus.Text = "+0.1s"
Plus.TextScaled = true
Plus.Parent = DelayFrame
Instance.new("UICorner", Plus).CornerRadius = UDim.new(0, 10)
Plus.MouseButton1Click:Connect(function()
    Config.CollectDelay = math.clamp(Config.CollectDelay + 0.1, 0.1, 2)
    DelayLabel.Text = "Collect Delay: " .. string.format("%.1f", Config.CollectDelay) .. "s"
end)

local WSBtn = Instance.new("TextButton")
WSBtn.Size = UDim2.new(1, -20, 0, 60)
WSBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
WSBtn.Text = "⚡ WalkSpeed 60\nOFF"
WSBtn.TextColor3 = Color3.new(1,1,1)
WSBtn.TextScaled = true
WSBtn.Parent = Scrolling
Instance.new("UICorner", WSBtn).CornerRadius = UDim.new(0, 12)

WSBtn.MouseButton1Click:Connect(function()
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = hum.WalkSpeed > 20 and 16 or Config.WalkSpeed
        WSBtn.Text = "⚡ WalkSpeed 60\n" .. (hum.WalkSpeed > 20 and "✅ ON" or "OFF")
    end
end)

Scrolling.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 40)

-- ==================== MESSENGER BUBBLE ====================
local Bubble = Instance.new("TextButton")
Bubble.Size = UDim2.new(0, 70, 0, 70)
Bubble.Position = UDim2.new(0.9, -80, 0.8, -80)
Bubble.BackgroundColor3 = Color3.fromRGB(0, 170, 80)
Bubble.Text = "🌱"
Bubble.TextScaled = true
Bubble.TextColor3 = Color3.new(1,1,1)
Bubble.Font = Enum.Font.GothamBold
Bubble.Visible = false
Bubble.Parent = ScreenGui
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)  -- Perfect circle
Instance.new("UIStroke", Bubble) -- Border

-- Bubble Drag
local bubbleDragging
Bubble.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bubbleDragging = true
        local startPos = Bubble.Position
        local startMouse = UserInputService:GetMouseLocation()
        local conn
        conn = RunService.RenderStepped:Connect(function()
            if not bubbleDragging then conn:Disconnect() return end
            local mouse = UserInputService:GetMouseLocation()
            local delta = mouse - startMouse
            Bubble.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        bubbleDragging = false
    end
end)

Bubble.MouseButton1Click:Connect(function()
    Main.Visible = true
    Bubble.Visible = false
end)

-- ==================== HIDE / SHOW LOGIC ====================
local function HideUI()
    Main.Visible = false
    Bubble.Visible = true
end

local function ShowUI()
    Main.Visible = true
    Bubble.Visible = false
end

HideBtn.MouseButton1Click:Connect(HideUI)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Right Shift Toggle
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        if Main.Visible then
            HideUI()
        else
            ShowUI()
        end
    end
end)

-- Draggable Main UI (Title Bar)
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
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Notify("✅ Premium v4 Loaded", "👁️ Hide → Messenger Bubble\nRightShift = Toggle")