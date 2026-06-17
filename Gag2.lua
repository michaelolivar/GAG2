-- Grow a Garden 2 - Premium Auto Event Seed Collector
-- Professional UI | Safe & Efficient | Custom by Grok

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Config
local Config = {
    AutoCollectEventSeeds = false,
    CollectDelay = 0.5,
    WalkSpeed = 50,
    AntiAFK = true,
    NotifyEnabled = true,
}

-- Simple Notification System
local function Notify(title, text, duration)
    if not Config.NotifyEnabled then return end
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title or "GAG2 Premium",
        Text = text or "",
        Duration = duration or 3,
    })
end

-- Find Event Seeds / Drops
local function GetEventSeeds()
    local seeds = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Part") then
            local name = obj.Name:lower()
            if name:find("gold") or name:find("rainbow") or name:find("event") or name:find("seed") then
                if obj:FindFirstChild("ProximityPrompt") or obj:FindFirstChildWhichIsA("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

-- Collect Single Seed
local function CollectSeed(seed)
    if not seed or not seed.Parent then return false end
    local prompt = seed:FindFirstChild("ProximityPrompt") or seed:FindFirstChildWhichIsA("ProximityPrompt")
    if prompt then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            -- Smooth teleport approach
            local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad)
            local tween = TweenService:Create(root, tweenInfo, {CFrame = seed:GetPivot()})
            tween:Play()
            tween.Completed:Wait()
            fireproximityprompt(prompt)
            wait(Config.CollectDelay)
            return true
        end
    end
    return false
end

-- Main Auto Collect Loop
local collectConnection
local function StartAutoCollect()
    if collectConnection then return end
    Notify("Auto Collect", "Event Seed Collector Started!", 4)
    collectConnection = RunService.Heartbeat:Connect(function()
        if not Config.AutoCollectEventSeeds then return end
        local seeds = GetEventSeeds()
        for _, seed in ipairs(seeds) do
            if Config.AutoCollectEventSeeds and seed.Parent then
                pcall(function()
                    CollectSeed(seed)
                end)
            end
        end
    end)
end

local function StopAutoCollect()
    if collectConnection then
        collectConnection:Disconnect()
        collectConnection = nil
        Notify("Auto Collect", "Event Seed Collector Stopped.", 3)
    end
end

-- Premium UI (Fluent-inspired simple implementation)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GAG2_Premium_UI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 420, 0, 500)
MainFrame.Position = UDim2.new(0.5, -210, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "🌱 Grow a Garden 2 - Premium Collector"
Title.TextColor3 = Color3.fromRGB(100, 255, 150)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

-- Draggable
local dragging, dragInput, dragStart
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset + delta.X, MainFrame.Position.Y.Scale, MainFrame.Position.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Tabs Container
local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, -20, 1, -70)
TabFrame.Position = UDim2.new(0, 10, 0, 60)
TabFrame.BackgroundTransparency = 1
TabFrame.Parent = MainFrame

-- Auto Collect Section
local ToggleCollect = Instance.new("TextButton")
ToggleCollect.Size = UDim2.new(0.9, 0, 0, 50)
ToggleCollect.Position = UDim2.new(0.05, 0, 0, 20)
ToggleCollect.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ToggleCollect.Text = "Auto Collect Event Seeds: OFF"
ToggleCollect.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleCollect.TextScaled = true
ToggleCollect.Parent = TabFrame

local collectCorner = Instance.new("UICorner")
collectCorner.CornerRadius = UDim.new(0, 8)
collectCorner.Parent = ToggleCollect

ToggleCollect.MouseButton1Click:Connect(function()
    Config.AutoCollectEventSeeds = not Config.AutoCollectEventSeeds
    ToggleCollect.Text = "Auto Collect Event Seeds: " .. (Config.AutoCollectEventSeeds and "ON" or "OFF")
    ToggleCollect.BackgroundColor3 = Config.AutoCollectEventSeeds and Color3.fromRGB(0, 170, 100) or Color3.fromRGB(40, 40, 50)
    
    if Config.AutoCollectEventSeeds then
        StartAutoCollect()
    else
        StopAutoCollect()
    end
end)

-- Sliders & Other Toggles
local DelaySlider = Instance.new("TextLabel")
DelaySlider.Size = UDim2.new(0.9, 0, 0, 40)
DelaySlider.Position = UDim2.new(0.05, 0, 0, 90)
DelaySlider.BackgroundTransparency = 1
DelaySlider.Text = "Collect Delay: " .. Config.CollectDelay .. "s"
DelaySlider.TextColor3 = Color3.fromRGB(200, 200, 200)
DelaySlider.Parent = TabFrame

-- Simple delay adjust buttons
local BtnMinus = Instance.new("TextButton")
BtnMinus.Size = UDim2.new(0.2, 0, 0, 30)
BtnMinus.Position = UDim2.new(0.05, 0, 0, 140)
BtnMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BtnMinus.Text = "-0.1s"
BtnMinus.Parent = TabFrame
BtnMinus.MouseButton1Click:Connect(function()
    Config.CollectDelay = math.max(0.1, Config.CollectDelay - 0.1)
    DelaySlider.Text = "Collect Delay: " .. string.format("%.1f", Config.CollectDelay) .. "s"
end)

local BtnPlus = Instance.new("TextButton")
BtnPlus.Size = UDim2.new(0.2, 0, 0, 30)
BtnPlus.Position = UDim2.new(0.3, 0, 0, 140)
BtnPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
BtnPlus.Text = "+0.1s"
BtnPlus.Parent = TabFrame
BtnPlus.MouseButton1Click:Connect(function()
    Config.CollectDelay = Config.CollectDelay + 0.1
    DelaySlider.Text = "Collect Delay: " .. string.format("%.1f", Config.CollectDelay) .. "s"
end)

-- WalkSpeed Toggle
local ToggleWS = Instance.new("TextButton")
ToggleWS.Size = UDim2.new(0.9, 0, 0, 50)
ToggleWS.Position = UDim2.new(0.05, 0, 0, 190)
ToggleWS.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
ToggleWS.Text = "WalkSpeed Boost: OFF"
ToggleWS.Parent = TabFrame
ToggleWS.MouseButton1Click:Connect(function()
    local enabled = character:FindFirstChild("Humanoid")
    if enabled then
        enabled.WalkSpeed = (enabled.WalkSpeed > 16 and 16 or Config.WalkSpeed)
        ToggleWS.Text = "WalkSpeed Boost: " .. (enabled.WalkSpeed > 16 and "ON" or "OFF")
    end
end)

-- Anti-AFK
local AntiAFKConn
local function EnableAntiAFK()
    if AntiAFKConn then return end
    AntiAFKConn = RunService.RenderStepped:Connect(function()
        if Config.AntiAFK then
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton2(Vector2.new())
            end)
        end
    end)
end
EnableAntiAFK()

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -45, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    StopAutoCollect()
end)

Notify("Premium Script Loaded", "Auto Event Seed Collector Ready! Toggle in GUI.", 5)

-- Cleanup on leave
player.CharacterRemoving:Connect(function()
    StopAutoCollect()
end)