-- Grow a Garden 2 - Premium Auto Event Seed Collector v2
-- Fixed UI | Professional Design | by Grok

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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

-- Get Event Seeds
local function GetEventSeeds()
    local seeds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local n = obj.Name:lower()
            if (n:find("gold") or n:find("rainbow") or n:find("event") or n:find("seed") or n:find("pack")) then
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                if prompt then
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

-- Auto Collect Loop
local connection
local function ToggleAutoCollect(state)
    Config.AutoCollect = state
    if state then
        Notify("Auto Collect", "✅ Event Seeds Collector Started")
        connection = RunService.Heartbeat:Connect(function()
            if not Config.AutoCollect then return end
            local seeds = GetEventSeeds()
            for _, seed in ipairs(seeds) do
                pcall(CollectSeed, seed)
            end
        end)
    else
        if connection then connection:Disconnect() end
        Notify("Auto Collect", "⛔ Collector Stopped")
    end
end

-- ==================== PREMIUM UI ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GAG2_Premium"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 460, 0, 520)
Main.Position = UDim2.new(0.5, -230, 0.5, -260)
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
Title.Size = UDim2.new(1, -60, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "🌱 Grow a Garden 2 - Premium"
Title.TextColor3 = Color3.fromRGB(80, 255, 140)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = TitleBar

-- Close Button
local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 50, 0, 50)
Close.Position = UDim2.new(1, -55, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
Close.Text = "✕"
Close.TextColor3 = Color3.new(1,1,1)
Close.TextScaled = true
Close.Font = Enum.Font.GothamBold
Close.Parent = TitleBar
Instance.new("UICorner", Close).CornerRadius = UDim.new(0, 10)
Close.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Scrolling Content
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

-- Toggle Auto Collect
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
    local newState = not Config.AutoCollect
    ToggleAutoCollect(newState)
    ToggleBtn.Text = "🔄 Auto Collect Event Seeds\n" .. (newState and "✅ ON" or "⛔ OFF")
    ToggleBtn.BackgroundColor3 = newState and Color3.fromRGB(0, 170, 80) or Color3.fromRGB(40, 40, 55)
end)

-- Delay Slider (Simple)
local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(1, -20, 0, 40)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Collect Delay: 0.6s"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
DelayLabel.TextScaled = true
DelayLabel.Font = Enum.Font.Gotham
DelayLabel.Parent = Scrolling

local function UpdateDelay(val)
    Config.CollectDelay = math.clamp(val, 0.1, 2)
    DelayLabel.Text = "Collect Delay: " .. string.format("%.1f", Config.CollectDelay) .. "s"
end

-- Buttons for delay
local DelayFrame = Instance.new("Frame")
DelayFrame.Size = UDim2.new(1, -20, 0, 50)
DelayFrame.BackgroundTransparency = 1
DelayFrame.Parent = Scrolling

local Minus = Instance.new("TextButton")
Minus.Size = UDim2.new(0.45, 0, 1, 0)
Minus.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
Minus.Text = "- 0.1s"
Minus.TextScaled = true
Minus.Parent = DelayFrame
Instance.new("UICorner", Minus).CornerRadius = UDim.new(0, 10)
Minus.MouseButton1Click:Connect(function() UpdateDelay(Config.CollectDelay - 0.1) end)

local Plus = Instance.new("TextButton")
Plus.Size = UDim2.new(0.45, 0, 1, 0)
Plus.Position = UDim2.new(0.55, 0, 0, 0)
Plus.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
Plus.Text = "+ 0.1s"
Plus.TextScaled = true
Plus.Parent = DelayFrame
Instance.new("UICorner", Plus).CornerRadius = UDim.new(0, 10)
Plus.MouseButton1Click:Connect(function() UpdateDelay(Config.CollectDelay + 0.1) end)

-- WalkSpeed
local WSBtn = Instance.new("TextButton")
WSBtn.Size = UDim2.new(1, -20, 0, 60)
WSBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
WSBtn.Text = "⚡ WalkSpeed Boost (60)\nOFF"
WSBtn.TextColor3 = Color3.new(1,1,1)
WSBtn.TextScaled = true
WSBtn.Parent = Scrolling
Instance.new("UICorner", WSBtn).CornerRadius = UDim.new(0, 12)

WSBtn.MouseButton1Click:Connect(function()
    local hum = character:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed > 20 then
            hum.WalkSpeed = 16
            WSBtn.Text = "⚡ WalkSpeed Boost (60)\nOFF"
        else
            hum.WalkSpeed = Config.WalkSpeed
            WSBtn.Text = "⚡ WalkSpeed Boost (60)\n✅ ON"
        end
    end
end)

Scrolling.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 50)

-- Draggable
local dragging
Main.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        local mousePos = input.Position
        local framePos = Main.Position
        local conn
        conn = game:GetService("RunService").RenderStepped:Connect(function()
            if not dragging then conn:Disconnect() return end
            local delta = game:GetService("UserInputService"):GetMouseLocation() - mousePos
            Main.Position = UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

Notify("Premium UI Loaded", "UI should now be visible and functional!")