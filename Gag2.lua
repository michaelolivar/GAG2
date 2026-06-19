--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - ADVANCED SCRIPT              ║
║                   Red Team Edition v1.0                     ║
╚══════════════════════════════════════════════════════════════╝
Features:
  1. Event Seeds Auto Collect (Golden Seed, Rainbow Seed)
  2. Weather Prediction
  3. Seed Shop Prediction
  4. Auto Stay Base at Night
  5. Auto Defense (Shovel, Crowbar, Freeze Ray, Power Hose)
--]]

-- Configuration
local Config = {
    AutoCollectSeeds = true,
    AutoDefense = true,
    AutoStayBase = true,
    NotifyWeather = true,
    NotifyShop = true,
    
    -- Defense weapons priority (1=highest)
    DefenseWeapons = {
        "Freeze Ray",   -- Freezes thieves
        "Power Hose",   -- Blasts thieves away
        "Crowbar",      -- Melee weapon
        "Shovel"        -- Default melee
    },
    
    DefenseRange = 30,  -- Studs to detect thieves
    WeaponCooldown = 2, -- Seconds between weapon uses
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- UI Library - FIXED para sa Delta Executor
local Library = Instance.new("ScreenGui")
Library.Name = "GAG2RedTeam"
Library.ResetOnSpawn = false
Library.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library.DisplayOrder = 999999

-- Try multiple parent options para sa Delta compatibility
local parentOptions = {
    CoreGui,
    LocalPlayer:FindFirstChild("PlayerGui"),
    LocalPlayer.PlayerGui,
    game:GetService("Players").LocalPlayer.PlayerGui
}

local parented = false
for _, parent in ipairs(parentOptions) do
    if parent then
        local success = pcall(function()
            Library.Parent = parent
        end)
        if success then
            parented = true
            break
        end
    end
end

-- If all else fails, use Instance.new with direct parent
if not parented then
    pcall(function()
        local plrGui = Instance.new("ScreenGui")
        plrGui.Name = "GAG2_Container"
        plrGui.ResetOnSpawn = false
        plrGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui", 5)
        Library.Parent = plrGui.Parent
    end)
end

local function MakeDraggable(frame)
    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Build UI
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = Library

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -10, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌱 GAG2 Red Team"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleBtn.Position = UDim2.new(1, -35, 0, 5)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "X"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TitleBar

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 6)
ToggleCorner.Parent = ToggleBtn

MakeDraggable(TitleBar)

-- Tab system
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 0, 35)
TabContainer.Position = UDim2.new(0, 0, 0, 40)
TabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -20, 1, -95)
ContentFrame.Position = UDim2.new(0, 10, 0, 80)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 6
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(40, 180, 80)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.Parent = MainFrame

-- Create tabs
local Tabs = {}
local TabNames = {"Main", "Defense", "Shop", "Weather", "Info"}
local TabIcons = {"🌱", "🛡️", "🏪", "🌤️", "ℹ️"}

local function SwitchTab(tabName)
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = false
        end
    end
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == tabName then
            child.Visible = true
        end
    end
    for _, btn in pairs(TabContainer:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
        end
    end
    local tabBtn = TabContainer:FindFirstChild(tabName)
    if tabBtn then
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    end
end

for i, tabName in ipairs(TabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName
    tabBtn.Size = UDim2.new(0, 80, 1, 0)
    tabBtn.Position = UDim2.new(0, (i-1) * 80, 0, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    tabBtn.Text = TabIcons[i] .. " " .. tabName
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.TextSize = 12
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabContainer
    
    if i == 1 then
        tabBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    end
    
    tabBtn.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

-- Helper: Create toggle row
local function CreateToggle(tab, name, desc, default)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -5, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, -5, 0, 16)
    descLabel.Position = UDim2.new(0, 0, 0, 22)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = row
    
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(1, -55, 0, 10)
    toggle.BackgroundColor3 = default and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(60, 60, 70)
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 12)
    toggleCorner.Parent = toggle
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.Parent = toggle
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 20, 0, 20)
    circle.Position = default and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    circle.BorderSizePixel = 0
    circle.Parent = toggle
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 10)
    circleCorner.Parent = circle
    
    local toggled = default
    
    toggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        toggle.BackgroundColor3 = toggled and Color3.fromRGB(40, 180, 80) or Color3.fromRGB(60, 60, 70)
        circle:TweenPosition(UDim2.new(toggled and 1 or 0, toggled and -22 or 2, 0, 2), "Out", "Quad", 0.15, true)
    end)
    
    return toggleBtn, function() return toggled end
end

-- Helper: Create label row
local function CreateLabel(tab, text, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(180, 180, 180)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.Parent = row
    
    return label
end

-- ==========================================
-- TAB: MAIN
-- ==========================================
local MainTab = Instance.new("Frame")
MainTab.Name = "Main"
MainTab.Size = UDim2.new(1, 0, 0, 400)
MainTab.BackgroundTransparency = 1
MainTab.Parent = ContentFrame

CreateLabel(MainTab, "=== AUTOMATION CONTROLS ===", Color3.fromRGB(40, 180, 80))

local _, getAutoCollect = CreateToggle(MainTab, "Auto-Collect Event Seeds", "Auto-collect Golden & Rainbow seeds", true)
local _, getWeatherNotif = CreateToggle(MainTab, "Weather Notifications", "Alert on weather changes", true)
local _, getShopNotif = CreateToggle(MainTab, "Shop Predictions", "Track seed shop rotations", true)

CreateLabel(MainTab, "=== DEFENSE CONTROLS ===", Color3.fromRGB(200, 80, 80))

local _, getAutoDefense = CreateToggle(MainTab, "Auto Defense", "Auto-attack thieves in your base", true)
local _, getAutoStay = CreateToggle(MainTab, "Auto Stay at Base", "Return to base at night", true)

CreateLabel(MainTab, "=== STATUS ===", Color3.fromRGB(80, 180, 255))

local StatusLabel = CreateLabel(MainTab, "Script Active | Waiting...", Color3.fromRGB(180, 180, 180))

-- Spacer
local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 20)
spacer.BackgroundTransparency = 1
spacer.Parent = MainTab

-- Reset canvas size
local function UpdateCanvas()
    local totalH = 0
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Visible then
            for _, row in pairs(child:GetChildren()) do
                if row:IsA("Frame") then
                    totalH = totalH + row.Size.Y.Offset + 5
                end
            end
        end
    end
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
end

-- ==========================================
-- TAB: DEFENSE
-- ==========================================
local DefenseTab = Instance.new("Frame")
DefenseTab.Name = "Defense"
DefenseTab.Size = UDim2.new(1, 0, 0, 400)
DefenseTab.BackgroundTransparency = 1
DefenseTab.Visible = false
DefenseTab.Parent = ContentFrame

CreateLabel(DefenseTab, "=== WEAPON SETTINGS ===", Color3.fromRGB(200, 80, 80))
CreateLabel(DefenseTab, "✓ Shovel (Default - Free)", Color3.fromRGB(150, 255, 150))
CreateLabel(DefenseTab, "✓ Crowbar (Rare - Gear Shop)", Color3.fromRGB(150, 255, 150))
CreateLabel(DefenseTab, "✓ Freeze Ray (Premium - 749 Robux)", Color3.fromRGB(150, 255, 150))
CreateLabel(DefenseTab, "✓ Power Hose (Premium - 299 Robux)", Color3.fromRGB(150, 255, 150))

CreateLabel(DefenseTab, "", Color3.fromRGB(255,255,255))
CreateLabel(DefenseTab, "Auto-detects thieves in your garden area", Color3.fromRGB(200, 200, 150))
CreateLabel(DefenseTab, "and equips best available weapon to", Color3.fromRGB(200, 200, 150))
CreateLabel(DefenseTab, "attack intruders automatically.", Color3.fromRGB(200, 200, 150))

-- ==========================================
-- TAB: SHOP
-- ==========================================
local ShopTab = Instance.new("Frame")
ShopTab.Name = "Shop"
ShopTab.Size = UDim2.new(1, 0, 0, 400)
ShopTab.BackgroundTransparency = 1
ShopTab.Visible = false
ShopTab.Parent = ContentFrame

CreateLabel(ShopTab, "=== SEED SHOP PREDICTIONS ===", Color3.fromRGB(255, 180, 50))
local ShopPredictLabel = CreateLabel(ShopTab, "Monitoring shop rotations...", Color3.fromRGB(180, 180, 180))
CreateLabel(ShopTab, "", Color3.fromRGB(255,255,255))
CreateLabel(ShopTab, "Seed shop restocks every ~5 minutes", Color3.fromRGB(150, 150, 150))
CreateLabel(ShopTab, "Rare seeds: ~30-45 min cycle", Color3.fromRGB(150, 150, 150))
CreateLabel(ShopTab, "Epic seeds: ~45-60 min cycle", Color3.fromRGB(150, 150, 150))
CreateLabel(ShopTab, "Legendary: RNG based, low chance", Color3.fromRGB(150, 150, 150))

-- ==========================================
-- TAB: WEATHER
-- ==========================================
local WeatherTab = Instance.new("Frame")
WeatherTab.Name = "Weather"
WeatherTab.Size = UDim2.new(1, 0, 0, 400)
WeatherTab.BackgroundTransparency = 1
WeatherTab.Visible = false
WeatherTab.Parent = ContentFrame

CreateLabel(WeatherTab, "=== WEATHER TRACKER ===", Color3.fromRGB(80, 180, 255))
local WeatherLabel = CreateLabel(WeatherTab, "Current: ☀️ Day", Color3.fromRGB(255, 255, 150))
local WeatherTimerLabel = CreateLabel(WeatherTab, "Time remaining: --:--", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "", Color3.fromRGB(255,255,255))
CreateLabel(WeatherTab, "Weather types:", Color3.fromRGB(150, 255, 150))
CreateLabel(WeatherTab, "🌧️ Rain (5min) - 2x growth speed", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "⚡ Lightning (5min) - Electric mutation 80x", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌈 Rainbow (2min) - Rainbow mutation boost", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "❄️ Snowfall (2.5min) - Frozen mutation 5x", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "⭐ Starfall (2min) - Starstruck mutation", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "", Color3.fromRGB(255,255,255))
CreateLabel(WeatherTab, "Night events (2min each):", Color3.fromRGB(150, 150, 255))
CreateLabel(WeatherTab, "🌑 Blood Moon - Bloodlit mutation", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌟 Gold Moon - Gold Seed spawns (15x)", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌈 Rainbow Moon - Rainbow seed spawns", Color3.fromRGB(180, 180, 180))

-- ==========================================
-- TAB: INFO
-- ==========================================
local InfoTab = Instance.new("Frame")
InfoTab.Name = "Info"
InfoTab.Size = UDim2.new(1, 0, 0, 400)
InfoTab.BackgroundTransparency = 1
InfoTab.Visible = false
InfoTab.Parent = ContentFrame

CreateLabel(InfoTab, "=== GROW A GARDEN 2 ===", Color3.fromRGB(40, 180, 80))
CreateLabel(InfoTab, "Red Team Edition v1.0", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "HOW TO USE:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "1. Equip weapons in your inventory", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "2. Toggle features on/off", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "3. Script auto-detects events", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "Features:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "✅ Event seed auto-collect", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Weather prediction system", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Seed shop rotation tracker", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto-stay at base during night", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto defense with weapons", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "Tip: Stay in your garden during", Color3.fromRGB(200, 200, 150))
CreateLabel(InfoTab, "night to prevent theft!", Color3.fromRGB(200, 200, 150))

UpdateCanvas()

-- Toggle visibility
local minimized = false
ToggleBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        MainFrame.Size = UDim2.new(0, 200, 0, 40)
        TabContainer.Visible = false
        ContentFrame.Visible = false
        ToggleBtn.Text = "+"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    else
        MainFrame.Size = UDim2.new(0, 400, 0, 500)
        TabContainer.Visible = true
        ContentFrame.Visible = true
        ToggleBtn.Text = "X"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
end)

-- ==========================================
-- CORE FEATURES IMPLEMENTATION
-- ==========================================

-- Track game objects
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Find important objects
local function FindGameObject(path)
    local obj = nil
    local success, result = pcall(function()
        local current = game
        for _, part in ipairs(path) do
            current = current:WaitForChild(part, 5)
        end
        return current
    end)
    if success then
        obj = result
    end
    return obj
end

-- Detect weather by checking Lighting and sky changes
local currentWeather = "Day"
local weatherStartTime = tick()
local weatherDurations = {
    Day = 530,         -- ~8m 50s
    Rain = 300,        -- 5min
    Lightning = 300,   -- 5min
    Rainbow = 120,     -- 2min
    Snowfall = 150,    -- 2m 30s
    Starfall = 120,    -- 2min
    Night = 240,       -- 4min
    Sunset = 40,       -- 40s
    BloodMoon = 120,   -- 2min
    GoldMoon = 120,    -- 2min
    RainbowMoon = 120, -- 2min
}

local weatherIcons = {
    Day = "☀️",
    Night = "🌙",
    Sunset = "🌅",
    Rain = "🌧️",
    Lightning = "⚡",
    Rainbow = "🌈",
    Snowfall = "❄️",
    Starfall = "⭐",
    BloodMoon = "🌑",
    GoldMoon = "🌟",
    RainbowMoon = "🌈"
}

-- Detect weather by clock time and sky properties
local function DetectWeather()
    local timeOfDay = Lighting:GetMinutesAfterMidnight() or 0
    local clockTime = Lighting.ClockTime or 12
    local brightness = Lighting.Brightness or 1
    local fogColor = Lighting.FogColor or Color3.new(0.5, 0.5, 0.5)
    local fogEnd = Lighting.FogEnd or 1000
    
    -- Night detection (game night is roughly 4 minutes)
    if clockTime < 6 or clockTime > 20 then
        -- Check for special night events by sky color
        if fogColor.R > 0.7 and fogColor.G < 0.3 and fogColor.B < 0.3 then
            return "BloodMoon"
        elseif brightness > 0.5 and fogColor.R > 0.8 and fogColor.G > 0.7 then
            return "GoldMoon"
        elseif fogColor.R > 0.5 and fogColor.G < 0.3 and fogColor.B > 0.6 then
            return "RainbowMoon"
        end
        return "Night"
    end
    
    -- Daytime weather detection
    -- Rain: cloudy, blue-gray fog, lower brightness
    if brightness < 0.4 and fogColor.R < 0.4 and fogColor.G < 0.4 and fogColor.B > 0.4 then
        -- Check if thunder/lightning particles exist
        local hasLightning = false
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name:lower():find("lightning") or v.Name:lower():find("thunder") then
                hasLightning = true
                break
            end
        end
        if hasLightning then
            return "Lightning"
        end
        return "Rain"
    end
    
    -- Rainbow: distinct rainbow sky, high brightness
    if fogColor.R > 0.6 and fogColor.G > 0.3 and fogColor.B > 0.6 then
        return "Rainbow"
    end
    
    -- Snowfall/Blizzard: white fog, cold colors
    if fogColor.R > 0.7 and fogColor.G > 0.7 and fogColor.B > 0.8 and brightness < 0.6 then
        return "Snowfall"
    end
    
    -- Starfall: dark blue-purple sky with stars
    if fogColor.R < 0.3 and fogColor.G < 0.2 and fogColor.B > 0.5 and brightness > 0.3 then
        return "Starfall"
    end
    
    -- Sunset transition
    if clockTime >= 19 and clockTime < 20 then
        return "Sunset"
    end
    
    return "Day"
end

-- Find event seeds (Golden/Rainbow) by scanning for pickable objects
local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            -- Golden seed check
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
            -- Rainbow seed check
            if (name:find("rainbow") or name:find("rain")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

-- Collect seed (simulate click/interact)
local function CollectSeed(seedObj)
    pcall(function()
        -- Try ClickDetector
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector")
        if detector then
            fireclickdetector(detector)
            return true
        end
        
        -- Try ProximityPrompt
        local prompt = seedObj:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            fireproximityprompt(prompt)
            return true
        end
        
        -- Try TouchInterest
        local touch = seedObj:FindFirstChildWhichIsA("TouchTransmitter")
        if touch then
            -- Move character to touch it
            if RootPart then
                RootPart.CFrame = seedObj.CFrame * CFrame.new(0, 2, 0)
                task.wait(0.1)
            end
            return true
        end
        
        -- Try RemoteEvent
        for _, remote in pairs(seedObj:GetDescendants()) do
            if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
                remote:FireServer(seedObj)
                return true
            end
        end
    end)
    return false
end

-- Teleport to position
local function TeleportTo(pos)
    if RootPart then
        RootPart.CFrame = CFrame.new(pos)
    end
end

-- Find base/garden plot
local function FindMyBase()
    -- Try various common patterns for player plots
    local playerName = LocalPlayer.Name
    
    -- Search workspace for garden areas
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (name:find("garden") or name:find("plot") or name:find("base") or name:find("home")) then
            if name:find(playerName:sub(1, 5):lower()) or name:find("player") then
                return obj
            end
        end
    end
    
    -- Fallback: look for the "Garden" or "Teleport" button UI
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local txt = gui.Text:lower()
            if txt:find("garden") or txt:find("home") or txt:find("base") then
                return gui
            end
        end
    end
    
    return nil
end

-- Find thieves in base area
local function FindThreatsInBase()
    local base = FindMyBase()
    if not base then return {} end
    
    local basePos = base:IsA("BasePart") and base.Position or (base:FindFirstChildWhichIsA("BasePart") and base:FindFirstChildWhichIsA("BasePart").Position or nil)
    if not basePos then return {} end
    
    local threats = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local charPos = player.Character.HumanoidRootPart.Position
            local dist = (charPos - basePos).Magnitude
            if dist < Config.DefenseRange then
                table.insert(threats, player)
            end
        end
    end
    
    return threats
end

-- Equip and use weapon
local function EquipWeapon(weaponName)
    -- Find weapon in backpack
    local backpack = LocalPlayer.Backpack
    if not backpack then return false end
    
    for _, item in pairs(backpack:GetChildren()) do
        local itemName = item.Name:lower()
        local targetName = weaponName:lower()
        if itemName:find(targetName) or targetName:find(itemName) then
            -- Equip it
            LocalPlayer.Character.Humanoid:EquipTool(item)
            task.wait(0.3)
            return item
        end
    end
    
    -- Check if already equipped in character
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local toolName = tool.Name:lower()
                local targetName = weaponName:lower()
                if toolName:find(targetName) or targetName:find(toolName) then
                    return tool
                end
            end
        end
    end
    
    return nil
end

-- Attack a player/thief
local function AttackThief(thief)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    
    local targetRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Face the target
    if RootPart then
        local lookCF = CFrame.lookAt(RootPart.Position, targetRoot.Position)
        RootPart.CFrame = lookCF
    end
    
    -- Try each weapon in priority order
    for _, weaponName in ipairs(Config.DefenseWeapons) do
        local weapon = EquipWeapon(weaponName)
        if weapon then
            -- Activate weapon
            if weapon:FindFirstChild("ClickDetector") then
                fireclickdetector(weapon.ClickDetector)
            elseif weapon:FindFirstChildWhichIsA("RemoteEvent") then
                local remote = weapon:FindFirstChildWhichIsA("RemoteEvent")
                remote:FireServer(thief)
            end
            
            -- Try to use tool on target
            weapon:Activate()
            task.wait(0.1)
            
            -- If shovel/crowbar, try to hit
            local handle = weapon:FindFirstChild("Handle")
            if handle then
                -- Move close to target
                if RootPart then
                    RootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
                end
                weapon:Activate()
            end
            
            StatusLabel.Text = "⚔️ Attacking " .. thief.Name .. " with " .. weaponName
            break
        end
    end
end

-- Parse weather message from chat or UI
local function ParseWeatherFromGame()
    -- Try to read from screen UI
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") or gui:IsA("TextButton") then
            local txt = gui.Text or ""
            if txt:find("Weather") or txt:find("weather") then
                return txt
            end
        end
    end
    
    -- Try game messages
    local success, result = pcall(function()
        return Lighting:GetAttribute("Weather") or Lighting:GetAttribute("weather") or Lighting:GetAttribute("CurrentWeather")
    end)
    if success and result then
        return tostring(result)
    end
    
    return nil
end

-- ==========================================
-- MAIN LOOP
-- ==========================================

local function MainLoop()
    while task.wait(1) do
        pcall(function()
            -- 1. Auto-Collect Event Seeds
            if getAutoCollect() then
                local seeds = FindEventSeeds()
                for _, seed in ipairs(seeds) do
                    local dist = (seed.Position - RootPart.Position).Magnitude
                    if dist < 100 then
                        TeleportTo(seed.CFrame * CFrame.new(0, 2, 0))
                        task.wait(0.1)
                        CollectSeed(seed)
                        StatusLabel.Text = "🎯 Collected " .. seed.Name
                        task.wait(0.5)
                    end
                end
            end
            
            -- 2. Weather Detection & Prediction
            if getWeatherNotif() then
                local detectedWeather = DetectWeather()
                local gameWeather = ParseWeatherFromGame()
                
                if gameWeather then
                    -- Use game's weather text if available
                    for weatherName, _ in pairs(weatherDurations) do
                        if gameWeather:lower():find(weatherName:lower()) then
                            detectedWeather = weatherName
                            break
                        end
                    end
                end
                
                if detectedWeather ~= currentWeather then
                    currentWeather = detectedWeather
                    weatherStartTime = tick()
                    local icon = weatherIcons[currentWeather] or "❓"
                    WeatherLabel.Text = "Current: " .. icon .. " " .. currentWeather
                    
                    -- Log weather change
                    StatusLabel.Text = "🌤️ Weather changed: " .. currentWeather
                    
                    -- Notify player via chat
                    if currentWeather == "Rainbow" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                        -- Special alert for event spawn weathers
                        StatusLabel.Text = "⭐ EVENT WEATHER: " .. currentWeather .. " - Seeds may spawn!"
                    end
                end
                
                -- Update timer
                local duration = weatherDurations[currentWeather] or 300
                local elapsed = tick() - weatherStartTime
                local remaining = math.max(0, duration - elapsed)
                local mins = math.floor(remaining / 60)
                local secs = math.floor(remaining % 60)
                WeatherTimerLabel.Text = string.format("Time remaining: %02d:%02d", mins, secs)
            end
            
            -- 3. Seed Shop Prediction
            if getShopNotif() then
                -- The seed shop restocks every ~5 minutes (300 seconds)
                local shopCycle = tick() % 300
                local nextRestock = 300 - shopCycle
                local restockMins = math.floor(nextRestock / 60)
                local restockSecs = math.floor(nextRestock % 60)
                
                -- Predict rare seed windows
                local rareWindow = tick() % 1800 -- 30 min cycle for rares
                local epicWindow = tick() % 2700 -- 45 min cycle for epics
                
                local prediction = string.format("Next restock: %dm %ds | Rare: %s | Epic: %s",
                    restockMins, restockSecs,
                    (rareWindow < 60) and "SOON!" or (1800 - rareWindow < 120) and "SOON!" or "waiting",
                    (epicWindow < 60) and "SOON!" or (2700 - epicWindow < 120) and "SOON!" or "waiting"
                )
                ShopPredictLabel.Text = prediction
            end
            
            -- 4. Auto Stay Base at Night
            if getAutoStay() and currentWeather:find("Night") or currentWeather == "BloodMoon" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                local base = FindMyBase()
                if base then
                    local basePos = base:IsA("BasePart") and base.Position or 
                        (base:FindFirstChildWhichIsA("BasePart") and base:FindFirstChildWhichIsA("BasePart").Position or nil)
                    
                    if basePos and RootPart then
                        local distFromBase = (RootPart.Position - basePos).Magnitude
                        if distFromBase > 15 then
                            -- Teleport back to base
                            TeleportTo(basePos + Vector3.new(0, 3, 0))
                            StatusLabel.Text = "🌙 Night - Returned to base"
                        end
                    end
                end
            end
            
            -- 5. Auto Defense
            if getAutoDefense() then
                local threats = FindThreatsInBase()
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
            
            -- Update base status label
            if not StatusLabel.Text:find("⚔️") and not StatusLabel.Text:find("🎯") and not StatusLabel.Text:find("🌙") then
                StatusLabel.Text = "✅ Active | " .. currentWeather .. " | Monitoring..."
            end
        end)
    end
end

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    RootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2) -- Wait for game to load
end)

-- Start the script
task.spawn(MainLoop)

-- Initial status
StatusLabel.Text = "✅ Script loaded | Waiting for events..."
WeatherLabel.Text = "Current: ☀️ Day"
WeatherTimerLabel.Text = "Time remaining: --:--"

-- Print status to chat
local StarterGui = game:GetService("StarterGui")
StarterGui:SetCore("ChatMakeSystemMessage", {
    Text = "🌱 GAG2 Red Team Script loaded! Features: Auto-Collect, Weather, Shop, Night Defense",
    Color = Color3.fromRGB(40, 180, 80),
    Font = Enum.Font.GothamBold,
    TextSize = 16
})

print("🌱 GAG2 Red Team Script loaded successfully!")
print("✅ Auto-Collect Event Seeds")
print("✅ Weather Prediction")
print("✅ Seed Shop Prediction")
print("✅ Auto Stay Base at Night")
print("✅ Auto Defense (Shovel/Crowbar/Freeze Ray/Power Hose)")