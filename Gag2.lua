--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - Devo GAG2                     ║
║         Delta Executor Fix • Accurate Weather               ║
╚══════════════════════════════════════════════════════════════╝
Features:
  1. Event Seeds Auto Collect (Golden Seed, Rainbow Seed)
  2. Weather Prediction - reads game UI
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
    DefenseWeapons = {"Freeze Ray","Power Hose","Crowbar","Shovel"},
    DefenseRange = 30,
    WeaponCooldown = 2,
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Cleanup old
pcall(function()
    if CoreGui:FindFirstChild("GAG2RedTeam") then CoreGui:FindFirstChild("GAG2RedTeam"):Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("GAG2RedTeam") then LocalPlayer.PlayerGui:FindFirstChild("GAG2RedTeam"):Destroy() end
end)

-- ==========================================
-- DELTA-COMPATIBLE UI PARENTING
-- ==========================================
local Library = Instance.new("ScreenGui")
Library.Name = "GAG2RedTeam"
Library.ResetOnSpawn = false
Library.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Library.DisplayOrder = 999999

-- Delta Executor fix: try multiple parents
local parented = false
local parentTargets = {
    game:GetService("CoreGui"),
    LocalPlayer:FindFirstChild("PlayerGui"),
    LocalPlayer.PlayerGui,
    Instance.new("ScreenGui")
}

for _, target in ipairs(parentTargets) do
    if target then
        local ok = pcall(function()
            Library.Parent = target
        end)
        if ok then
            parented = true
            if target.Name == "ScreenGui" then
                target.Name = "GAG2Container"
                target.ResetOnSpawn = false
                target.Parent = CoreGui
            end
            break
        end
    end
end

-- Ultimate fallback
if not parented then
    pcall(function()
        local plrGui = LocalPlayer:WaitForChild("PlayerGui", 10)
        Library.Parent = plrGui
    end)
end

-- ==========================================
-- Weather System - Reads from game UI/Remotes
-- ==========================================
local currentWeather = "Day"
local weatherStartTime = tick()
local weatherEndTime = 0
local weatherDuration = 160
local weatherConnected = false

local WeatherInfo = {
    Day =         {icon="☀️", color=Color3.fromRGB(255,220,80),  desc="Normal growth"},
    Night =       {icon="🌙", color=Color3.fromRGB(140,140,220), desc="Stealing active!"},
    Rain =        {icon="🌧️", color=Color3.fromRGB(100,180,255), desc="2x growth speed"},
    Lightning =   {icon="⚡", color=Color3.fromRGB(255,255,80),  desc="Electric mutation (80x)"},
    Rainbow =     {icon="🌈", color=Color3.fromRGB(255,130,255), desc="Rainbow luck boosted"},
    Snowfall =    {icon="❄️", color=Color3.fromRGB(200,230,255), desc="Frozen mutation (5x)"},
    Starfall =    {icon="⭐", color=Color3.fromRGB(255,230,150), desc="Starstruck mutation"},
    BloodMoon =   {icon="🌑", color=Color3.fromRGB(220,60,60),   desc="Bloodlit mutation"},
    GoldMoon =    {icon="🌟", color=Color3.fromRGB(255,210,60),  desc="✦ GOLD SEEDS SPAWNING ✦"},
    RainbowMoon = {icon="🌈", color=Color3.fromRGB(100,255,200), desc="✦ RAINBOW SEEDS SPAWNING ✦"},
}

local WeatherMap = {}
for k,v in pairs(WeatherInfo) do
    WeatherMap[k:lower():gsub("%s+","")] = k
end
WeatherMap["thunderstorm"] = "Lightning"
WeatherMap["thunder"] = "Lightning"
WeatherMap["blizzard"] = "Snowfall"
WeatherMap["snow"] = "Snowfall"
WeatherMap["midas"] = "GoldMoon"
WeatherMap["goldmoon"] = "GoldMoon"
WeatherMap["gold moon"] = "GoldMoon"
WeatherMap["bloodmoon"] = "BloodMoon"
WeatherMap["blood moon"] = "BloodMoon"
WeatherMap["rainbowmoon"] = "RainbowMoon"
WeatherMap["rainbow moon"] = "RainbowMoon"
WeatherMap["sunny"] = "Day"

-- READ weather from game's WeatherEventStarted remote
local function ConnectWeatherRemote()
    local ok, remote = pcall(function()
        return ReplicatedStorage:WaitForChild("GameEvents", 5):WaitForChild("WeatherEventStarted", 5)
    end)
    
    if ok and remote then
        local conn = remote.OnClientEvent:Connect(function(eventName, lengthSec)
            pcall(function()
                if type(eventName) ~= "string" then return end
                local normalized = WeatherMap[eventName:lower():gsub("%s+","")]
                if not normalized then
                    for k,v in pairs(WeatherMap) do
                        if eventName:lower():find(k) then normalized = v; break end
                    end
                end
                if not normalized then normalized = eventName end
                
                local dur = (type(lengthSec) == "number" and lengthSec > 0) and lengthSec or 120
                currentWeather = normalized
                weatherDuration = dur
                weatherStartTime = tick()
                weatherEndTime = tick() + dur
                weatherConnected = true
                
                -- Update UI
                local info = WeatherInfo[currentWeather] or WeatherInfo.Day
                WeatherLabel.Text = "Current: " .. info.icon .. " " .. currentWeather
                WeatherLabel.TextColor3 = info.color
                
                -- Special alerts
                if currentWeather == "GoldMoon" then
                    StatusLabel.Text = "🌟 GOLD MOON - Golden seeds spawning!"
                elseif currentWeather == "RainbowMoon" then
                    StatusLabel.Text = "🌈 RAINBOW MOON - Rainbow seeds spawning!"
                elseif currentWeather == "Rainbow" then
                    StatusLabel.Text = "🌈 RAINBOW - Rainbow mutation boosted!"
                elseif currentWeather == "Lightning" then
                    StatusLabel.Text = "⚡ LIGHTNING - Electric mutation (80x)!"
                else
                    StatusLabel.Text = "🌤️ Weather: " .. currentWeather
                end
            end)
        end)
        _connections[#_connections+1] = conn
    end
end

-- FALLBACK: Read weather from game UI (weather icon in bottom-right)
local function ReadWeatherFromGameUI()
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return nil end
    
    for _, gui in pairs(playerGui:GetDescendants()) do
        if gui:IsA("ImageLabel") or gui:IsA("TextLabel") then
            local name = gui.Name:lower()
            local text = (gui:IsA("TextLabel") and gui.Text:lower()) or name
            
            if text:find("weather") or text:find("event") or name:find("weathericon") or name:find("weather_icon") then
                -- Check tooltip or nearby text
                local parent = gui.Parent
                if parent then
                    for _, child in pairs(parent:GetDescendants()) do
                        if child:IsA("TextLabel") and child ~= gui then
                            local txt = child.Text
                            for k,v in pairs(WeatherInfo) do
                                if txt:lower():find(k:lower()) then
                                    return k
                                end
                            end
                        end
                    end
                end
                -- Check the image name itself
                local image = gui.Image:lower()
                for k,v in pairs(WeatherInfo) do
                    if image:find(k:lower()) then return k end
                end
            end
            
            -- Check all TextLabels for weather name
            if gui:IsA("TextLabel") then
                local txt = gui.Text
                for k,v in pairs(WeatherInfo) do
                    if txt:lower():find(k:lower()) and not txt:lower():find("next") then
                        return k
                    end
                end
            end
        end
    end
    return nil
end

-- FALLBACK: ClockTime-based detection
local function FallbackDetect()
    local ct = Lighting.ClockTime or 12
    local isNight = ct < 5.5 or ct > 18.5
    
    -- Check particles
    local found = nil
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            local n = (v.Name.." "..(v.Parent and v.Parent.Name or "")):lower()
            if n:find("lightning") then found="Lightning";break end
            if n:find("rain") and not n:find("bow") then found="Rain";break end
            if n:find("snow") or n:find("blizzard") then found="Snowfall";break end
            if n:find("starfall") then found="Starfall";break end
            if n:find("rainbow") and not n:find("rain") then found="Rainbow";break end
        end
    end
    if found then return found end
    
    -- Check ambient for moon events
    if isNight then
        local amb = Lighting.Ambient or Color3.new()
        if amb.R > 0.35 and amb.G < 0.06 and amb.B < 0.06 then return "BloodMoon" end
        if amb.R > 0.35 and amb.G > 0.25 and amb.B < 0.06 then return "GoldMoon" end
        if amb.R < 0.2 and amb.G > 0.2 and amb.B > 0.35 then return "RainbowMoon" end
        return "Night"
    end
    
    return "Day"
end

-- ==========================================
-- BUILD UI
-- ==========================================
local function MakeDraggable(frame)
    local dragging, dragStart, startPos
    local c1 = frame.InputBegan:Connect(function(input)
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
    table.insert(_connections, c1)
    
    local c2 = frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(_connections, c2)
end

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 400, 0, 500)
MainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = Library

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

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

local TabNames = {"Main", "Defense", "Shop", "Weather", "Info"}
local TabIcons = {"🌱", "🛡️", "🏪", "🌤️", "ℹ️"}

local function SwitchTab(tabName)
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") then child.Visible = false end
    end
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == tabName then child.Visible = true end
    end
    for _, btn in pairs(TabContainer:GetChildren()) do
        if btn:IsA("TextButton") then btn.BackgroundColor3 = Color3.fromRGB(30, 30, 45) end
    end
    local tabBtn = TabContainer:FindFirstChild(tabName)
    if tabBtn then tabBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80) end
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
    if i == 1 then tabBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80) end
    tabBtn.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
end

-- CreateToggle helper
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
        circle.Position = toggled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
    end)
    
    return toggleBtn, function() return toggled end
end

local function CreateLabel(tab, text, color)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, text == "" and 10 or 28)
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
-- BUILD ALL TABS
-- ==========================================

-- MAIN TAB
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

local spacer = Instance.new("Frame")
spacer.Size = UDim2.new(1, 0, 0, 20)
spacer.BackgroundTransparency = 1
spacer.Parent = MainTab

-- DEFENSE TAB
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

-- SHOP TAB
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

-- WEATHER TAB
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
CreateLabel(WeatherTab, "=== WEATHER TYPES ===", Color3.fromRGB(150, 255, 150))
CreateLabel(WeatherTab, "🌧️ Rain - 2x growth speed", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "⚡ Lightning - Electric mutation (80x)", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌈 Rainbow - Rainbow mutation boost", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "❄️ Snowfall - Frozen mutation (5x)", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "⭐ Starfall - Starstruck mutation", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "", Color3.fromRGB(255,255,255))
CreateLabel(WeatherTab, "=== NIGHT EVENTS ===", Color3.fromRGB(150, 150, 255))
CreateLabel(WeatherTab, "🌑 Blood Moon - Bloodlit mutation", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌟 Gold Moon - Golden seeds spawn!", Color3.fromRGB(180, 180, 180))
CreateLabel(WeatherTab, "🌈 Rainbow Moon - Rainbow seeds spawn!", Color3.fromRGB(180, 180, 180))

-- INFO TAB
local InfoTab = Instance.new("Frame")
InfoTab.Name = "Info"
InfoTab.Size = UDim2.new(1, 0, 0, 400)
InfoTab.BackgroundTransparency = 1
InfoTab.Visible = false
InfoTab.Parent = ContentFrame

CreateLabel(InfoTab, "=== GROW A GARDEN 2 ===", Color3.fromRGB(40, 180, 80))
CreateLabel(InfoTab, "Red Team Edition v1.0", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "Delta Executor Compatible", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "FEATURES:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "✅ Event seed auto-collect", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Weather prediction system", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Seed shop rotation tracker", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto-stay at base during night", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto defense with weapons", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "Tip: Stay in your garden during", Color3.fromRGB(200, 200, 150))
CreateLabel(InfoTab, "night to prevent theft!", Color3.fromRGB(200, 200, 150))

-- Canvas update
local function UpdateCanvas()
    local totalH = 0
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Visible then
            for _, row in pairs(child:GetChildren()) do
                if row:IsA("Frame") then totalH = totalH + row.Size.Y.Offset + 5 end
            end
        end
    end
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, totalH + 20)
end
UpdateCanvas()

-- Toggle minimize
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
-- CORE FEATURES
-- ==========================================

-- Track connections
local _connections = {}

-- Find event seeds
local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local isTarget = ((name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit")))
                or ((name:find("rainbow")) and (name:find("seed") or name:find("fruit")))
            
            if isTarget then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

local function CollectSeed(seedObj)
    pcall(function()
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector")
        if detector then fireclickdetector(detector); return true end
        local prompt = seedObj:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then fireproximityprompt(prompt); return true end
        local touch = seedObj:FindFirstChildWhichIsA("TouchTransmitter")
        if touch and RootPart then
            RootPart.CFrame = seedObj.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.1)
            return true
        end
    end)
    return false
end

local function TeleportTo(pos)
    if RootPart then RootPart.CFrame = CFrame.new(pos) end
end

local function FindMyBase()
    local playerName = LocalPlayer.Name
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (name:find("garden") or name:find("plot") or name:find("base")) then
            if name:find(playerName:sub(1, 5):lower()) then return obj end
        end
    end
    for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
            local txt = gui.Text:lower()
            if txt:find("garden") or txt:find("home") or txt:find("base") then return gui end
        end
    end
    return nil
end

local function FindThreatsInBase()
    local base = FindMyBase()
    if not base then return {} end
    local basePos = base:IsA("BasePart") and base.Position or (base:FindFirstChildWhichIsA("BasePart") and base:FindFirstChildWhichIsA("BasePart").Position or nil)
    if not basePos then return {} end
    local threats = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - basePos).Magnitude
            if dist < Config.DefenseRange then table.insert(threats, player) end
        end
    end
    return threats
end

local function EquipWeapon(weaponName)
    local backpack = LocalPlayer.Backpack
    if not backpack then return false end
    local targetName = weaponName:lower()
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name:lower():find(targetName) or targetName:find(item.Name:lower()) then
            LocalPlayer.Character.Humanoid:EquipTool(item)
            task.wait(0.3)
            return item
        end
    end
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = tool.Name:lower()
                if tn:find(targetName) or targetName:find(tn) then return tool end
            end
        end
    end
    return nil
end

local function AttackThief(thief)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    local targetRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    if RootPart then
        RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
    end
    for _, weaponName in ipairs(Config.DefenseWeapons) do
        local weapon = EquipWeapon(weaponName)
        if weapon then
            if weapon:FindFirstChild("ClickDetector") then fireclickdetector(weapon.ClickDetector) end
            weapon:Activate()
            task.wait(0.1)
            local handle = weapon:FindFirstChild("Handle")
            if handle then
                if RootPart then RootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3) end
                weapon:Activate()
            end
            StatusLabel.Text = "⚔️ Attacking " .. thief.Name .. " with " .. weaponName
            break
        end
    end
end

-- ==========================================
-- MAIN LOOP
-- ==========================================

local function MainLoop()
    while task.wait(1) do
        pcall(function()
            -- WEATHER: Try remote first, then game UI, then fallback
            if not weatherConnected then
                local fromUI = ReadWeatherFromGameUI()
                local detected = fromUI or FallbackDetect()
                
                if detected ~= currentWeather then
                    currentWeather = detected
                    weatherStartTime = tick()
                    weatherDuration = 120
                    if currentWeather == "Day" then weatherDuration = 160
                    elseif currentWeather == "Night" then weatherDuration = 80 end
                    
                    local info = WeatherInfo[currentWeather] or WeatherInfo.Day
                    WeatherLabel.Text = "Current: " .. info.icon .. " " .. currentWeather
                    WeatherLabel.TextColor3 = info.color
                    StatusLabel.Text = "🌤️ Weather: " .. currentWeather
                    
                    if currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                        StatusLabel.Text = "⭐ EVENT: " .. currentWeather .. " - Seeds spawning!"
                    end
                end
            end
            
            -- Update timer
            local duration = weatherDuration
            local elapsed = tick() - weatherStartTime
            local remaining = math.max(0, duration - elapsed)
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            WeatherTimerLabel.Text = string.format("Time remaining: %02d:%02d", mins, secs)
            
            -- Auto-Collect
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
            
            -- Shop Prediction
            if getShopNotif() then
                local shopCycle = tick() % 300
                local nextRestock = 300 - shopCycle
                local restockMins = math.floor(nextRestock / 60)
                local restockSecs = math.floor(nextRestock % 60)
                local rareWindow = tick() % 1800
                local epicWindow = tick() % 2700
                local prediction = string.format("Next restock: %dm %ds | Rare: %s | Epic: %s",
                    restockMins, restockSecs,
                    (rareWindow < 60) and "SOON!" or (1800 - rareWindow < 120) and "SOON!" or "waiting",
                    (epicWindow < 60) and "SOON!" or (2700 - epicWindow < 120) and "SOON!" or "waiting"
                )
                ShopPredictLabel.Text = prediction
            end
            
            -- Auto Stay Base at Night
            if getAutoStay() then
                local isNight = currentWeather == "Night" or currentWeather == "BloodMoon" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon"
                if isNight then
                    local base = FindMyBase()
                    if base then
                        local basePos = base:IsA("BasePart") and base.Position or (base:FindFirstChildWhichIsA("BasePart") and base:FindFirstChildWhichIsA("BasePart").Position or nil)
                        if basePos and RootPart then
                            local distFromBase = (RootPart.Position - basePos).Magnitude
                            if distFromBase > 15 then
                                TeleportTo(basePos + Vector3.new(0, 3, 0))
                                StatusLabel.Text = "🌙 Night - Returned to base"
                            end
                        end
                    end
                end
            end
            
            -- Auto Defense
            if getAutoDefense() then
                local threats = FindThreatsInBase()
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
            
            -- Update status
            if not StatusLabel.Text:find("⚔️") and not StatusLabel.Text:find("🎯") and not StatusLabel.Text:find("🌙") and not StatusLabel.Text:find("⭐") then
                StatusLabel.Text = "✅ Active | " .. currentWeather .. " | Monitoring..."
            end
        end)
    end
end

-- Character respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    RootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-- Connect to weather remote
task.spawn(function()
    task.wait(3)
    ConnectWeatherRemote()
end)

-- Start main loop
task.spawn(MainLoop)

-- Initial
StatusLabel.Text = "✅ Script loaded | Waiting for events..."
WeatherLabel.Text = "Current: ☀️ Day"
WeatherLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
WeatherTimerLabel.Text = "Time remaining: --:--"

-- Chat notification
pcall(function()
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = "🌱 GAG2 Red Team Script loaded! Delta Compatible | 5 Features Active",
        Color = Color3.fromRGB(40, 180, 80),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
end)

print("🌱 GAG2 Red Team Script loaded successfully!")