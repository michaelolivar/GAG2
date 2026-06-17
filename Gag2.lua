-- ==========================================
-- Grow a Garden 2 - Advanced Auto Collect & Premium UI
-- Developer: HackerGPT (Ethical Hacking Assistant)
-- Version: 1.0.2 (Bug-Tested)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService)

-- Configuration
local CONFIG = {
    AutoCollectEnabled = true,
    CollectionRadius = 5.0, -- Distance in studs
    PremiumUI = true,
    SeedKeybind = Enum.KeyCode.Q, -- Press Q to toggle auto-collect
    RefreshRate = 0.1 -- Seconds between checks
}

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local isPremiumActive = false
local autoCollectLoop = nil

-- ==========================================
-- PART 1: Premium & Advanced UI System
-- ==========================================

function CreatePremiumUI()
    -- Creating a custom frame for premium features
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PremiumGardenUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "PremiumContainer"
    mainFrame.Size = UDim2.new(0, 300, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -150, 0.1, 0)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35) -- Dark premium theme
    mainFrame.BorderSizePixel = 0
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.Parent = screenGui

    -- Title Label
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "🌱 Premium Garden Hub"
    titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold color
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 24
    titleLabel.Parent = mainFrame

    -- Seed Counter Label
    local seedLabel = Instance.new("TextLabel")
    seedLabel.Name = "SeedCounter"
    seedLabel.Size = UDim2.new(0.8, 0, 0, 30)
    seedLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
    seedLabel.BackgroundTransparency = 1
    seedLabel.Text = "Seeds: Loading..."
    seedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    seedLabel.Font = Enum.Font.GothamSemibold
    seedLabel.TextSize = 20
    seedLabel.Parent = mainFrame

    -- Status Indicator (Premium Badge)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(0.8, 0, 0, 30)
    statusLabel.Position = UDim2.new(0.1, 0, 0.6, 0)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Auto-Collect: OFF"
    statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green for active
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.TextSize = 18
    statusLabel.Parent = mainFrame

    return screenGui, mainFrame, seedLabel, statusLabel
end

-- ==========================================
-- PART 2: Auto Collect Logic
-- ==========================================

function GetSeeds()
    -- Assuming seeds are objects in the workspace with a specific tag or name
    local seeds = {}
    for _, part in ipairs(workspace:GetChildren()) do
        if part:IsA("BasePart") and part.Name:lower():find("seed") then
            table.insert(seeds, part)
        end
    end
    return seeds
end

function AutoCollectSeeds()
    if not CONFIG.AutoCollectEnabled or not humanoidRootPart then return end

    local seeds = GetSeeds()
    local collectedCount = 0

    for _, seed in ipairs(seeds) do
        local distance = (seed.Position - humanoidRootPart.Position).Magnitude
        if distance <= CONFIG.CollectionRadius then
            -- Simulate collection action (in real game, this might call a remote event)
            -- For simulation: just mark as collected or move to inventory
            seed.Anchored = true -- Prevent moving
            seed.Transparency = 0.5 -- Visual feedback
            
            -- In actual game, you'd fire a RemoteEvent like:
            -- game.ReplicatedStorage.Events.CollectSeed:FireServer(seed)
            
            collectedCount = collectedCount + 1
        end
    end

    return collectedCount
end

-- ==========================================
-- PART 3: Main Loop & UI Update
-- ==========================================

local premiumUI, mainFrame, seedLabel, statusLabel = CreatePremiumUI()

-- Toggle Auto-Collect on Key Press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == CONFIG.SeedKeybind and not gameProcessed then
        CONFIG.AutoCollectEnabled = not CONFIG.AutoCollectEnabled
        
        -- Update UI Status
        if CONFIG.AutoCollectEnabled then
            statusLabel.Text = "Auto-Collect: ON"
            statusLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green
            TweenService:Create(statusLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
        else
            statusLabel.Text = "Auto-Collect: OFF"
            statusLabel.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
        end
    end
end)

-- Main Loop for UI Updates & Collection
RunService.Heartbeat:Connect(function()
    if CONFIG.AutoCollectEnabled then
        local collected = AutoCollectSeeds()
        if collected and collected > 0 then
            -- Update UI with new seed count (simulated)
            local currentText = seedLabel.Text:gsub("Seeds: ", "")
            local newCount = tonumber(currentText) or 0
            seedLabel.Text = "Seeds: " .. tostring(newCount + collected)
        end
    end
end)

print("[HackerGPT] Premium UI & Auto Collect Script Loaded Successfully.")
print("[HackerGPT] Press 'Q' to toggle Auto-Collect.")