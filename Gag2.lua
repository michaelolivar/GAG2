--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - Devo GAG2                     ║
║         Delta Executor Optimized • Drawing API UI           ║
╚══════════════════════════════════════════════════════════════╝
Features:
  1. Event Seeds Auto Collect (Golden, Rainbow, Gold Moon, Rainbow Moon)
  2. Weather Prediction - reads game remote events
  3. Seed Shop Prediction
  4. Auto Stay Base at Night
  5. Auto Defense (Shovel, Crowbar, Freeze Ray, Power Hose)
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local LP = Players.LocalPlayer
local char = LP.Character or LP.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

-- Configuration
local Config = {
    AutoCollect = true,
    AutoDefense = true,
    AutoStayBase = true,
    NotifyWeather = true,
    WeaponCooldown = 1.5,
    DefenseRange = 35,
    Weapons = {"Freeze Ray", "Power Hose", "Crowbar", "Shovel"},
}

-- Current State
local currentWeather = "Day"
local weatherStartTime = tick()
local weatherDuration = 160
local weatherEndTime = 0
local weatherConnected = false
local minimized = false

-- Weather Info
local WeatherInfo = {
    Day         = {icon="☀️", color=Color3.fromRGB(255,220,80),  desc="Normal growth"},
    Night       = {icon="🌙", color=Color3.fromRGB(140,140,220), desc="Stealing active"},
    Rain        = {icon="🌧️", color=Color3.fromRGB(100,180,255), desc="2x growth speed"},
    Lightning   = {icon="⚡", color=Color3.fromRGB(255,255,80),  desc="Electric (80x)"},
    Rainbow     = {icon="🌈", color=Color3.fromRGB(255,130,255), desc="Rainbow luck boost"},
    Snowfall    = {icon="❄️", color=Color3.fromRGB(200,230,255), desc="Frozen (5x)"},
    Starfall    = {icon="⭐", color=Color3.fromRGB(255,230,150), desc="Starstruck"},
    BloodMoon   = {icon="🌑", color=Color3.fromRGB(220,60,60),   desc="Bloodlit"},
    GoldMoon    = {icon="🌟", color=Color3.fromRGB(255,210,60),  desc="✦ GOLDEN SEEDS ✦"},
    RainbowMoon = {icon="🌈", color=Color3.fromRGB(100,255,200), desc="✦ RAINBOW SEEDS ✦"},
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

-- CONNECT TO WEATHER REMOTE
local function ConnectWeather()
    local ok, remote = pcall(function()
        return ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("WeatherEventStarted")
    end)
    
    if ok and remote then
        remote.OnClientEvent:Connect(function(eventName, lengthSec)
            pcall(function()
                if type(eventName) ~= "string" then return end
                local norm = WeatherMap[eventName:lower():gsub("%s+","")]
                if not norm then
                    for k,v in pairs(WeatherMap) do
                        if eventName:lower():find(k) then norm = v; break end
                    end
                end
                if not norm then norm = eventName end
                
                local dur = (type(lengthSec) == "number" and lengthSec > 0) and lengthSec or 120
                currentWeather = norm
                weatherDuration = dur
                weatherStartTime = tick()
                weatherEndTime = tick() + dur
                weatherConnected = true
                
                local info = WeatherInfo[currentWeather] or WeatherInfo.Day
                UpdateWeatherDisplay(info)
            end)
        end)
    end
end

-- FALLBACK DETECTION
local function DetectWeatherFallback()
    local ct = Lighting.ClockTime or 12
    local isNight = ct < 5.5 or ct > 18.5
    
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            local n = (v.Name.." "..(v.Parent and v.Parent.Name or "")):lower()
            if n:find("lightning") then return "Lightning" end
            if n:find("rain") and not n:find("bow") then return "Rain" end
            if n:find("snow") or n:find("blizzard") then return "Snowfall" end
            if n:find("starfall") then return "Starfall" end
            if n:find("rainbow") and not n:find("rain") then return "Rainbow" end
        end
    end
    
    if isNight then
        local amb = Lighting.Ambient or Color3.new()
        if amb.R > 0.35 and amb.G < 0.06 then return "BloodMoon" end
        if amb.R > 0.35 and amb.G > 0.25 then return "GoldMoon" end
        if amb.R < 0.2 and amb.G > 0.2 then return "RainbowMoon" end
        return "Night"
    end
    return "Day"
end

-- ==========================================
-- DRAWING API UI (100% Delta Compatible)
-- ==========================================
local UI = {
    Bg = nil,
    Title = nil,
    CloseBtn = nil,
    WeatherIcon = nil,
    WeatherText = nil,
    WeatherTime = nil,
    StatusText = nil,
    ToggleLabels = {},
    ToggleBgs = {},
    ToggleCircles = {},
    Toggles = {},
}

local ScreenSize = workspace.CurrentCamera.ViewportSize

local function CreateDrawing(dType, props)
    local d = Drawing.new(dType)
    for k,v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

-- INIT UI
local bgColor = Color3.fromRGB(25, 25, 35)
local accentColor = Color3.fromRGB(40, 180, 80)
local textColor = Color3.fromRGB(230, 230, 230)
local dimColor = Color3.fromRGB(140, 140, 140)
local dangerColor = Color3.fromRGB(220, 60, 60)

-- Background
UI.Bg = CreateDrawing("Square", {
    Size = Vector2.new(380, 440),
    Position = Vector2.new(ScreenSize.X/2 - 190, ScreenSize.Y/2 - 220),
    Color = bgColor,
    Filled = true,
    Transparency = 1,
    Visible = true,
    ZIndex = 999,
})

-- Title bar
UI.TitleBg = CreateDrawing("Square", {
    Size = Vector2.new(380, 36),
    Position = Vector2.new(ScreenSize.X/2 - 190, ScreenSize.Y/2 - 220),
    Color = accentColor,
    Filled = true,
    Transparency = 1,
    Visible = true,
    ZIndex = 1000,
})

UI.Title = CreateDrawing("Text", {
    Text = "🌱 GAG2 Red Team",
    Color = Color3.fromRGB(255, 255, 255),
    Size = 16,
    Position = Vector2.new(ScreenSize.X/2 - 180, ScreenSize.Y/2 - 214),
    Center = false,
    Outline = true,
    Visible = true,
    ZIndex = 1001,
    Font = 2,
})

UI.CloseBtn = CreateDrawing("Square", {
    Size = Vector2.new(26, 26),
    Position = Vector2.new(ScreenSize.X/2 + 165, ScreenSize.Y/2 - 216),
    Color = dangerColor,
    Filled = true,
    Transparency = 1,
    Visible = true,
    ZIndex = 1000,
})

UI.CloseText = CreateDrawing("Text", {
    Text = "X",
    Color = Color3.fromRGB(255, 255, 255),
    Size = 14,
    Position = Vector2.new(ScreenSize.X/2 + 178, ScreenSize.Y/2 - 210),
    Center = true,
    Visible = true,
    ZIndex = 1001,
    Font = 2,
})

-- Section 1: Weather
local yOff = ScreenSize.Y/2 - 175
UI.WeatherIcon = CreateDrawing("Text", {
    Text = "☀️",
    Color = Color3.fromRGB(255, 220, 80),
    Size = 20,
    Position = Vector2.new(ScreenSize.X/2 - 175, yOff),
    Center = false,
    Visible = true,
    ZIndex = 1001,
})

UI.WeatherText = CreateDrawing("Text", {
    Text = "Current: Day",
    Color = Color3.fromRGB(255, 220, 80),
    Size = 14,
    Position = Vector2.new(ScreenSize.X/2 - 145, yOff + 3),
    Center = false,
    Visible = true,
    ZIndex = 1001,
    Font = 2,
})

UI.WeatherTime = CreateDrawing("Text", {
    Text = "Remaining: --:--",
    Color = dimColor,
    Size = 12,
    Position = Vector2.new(ScreenSize.X/2 - 175, yOff + 24),
    Center = false,
    Visible = true,
    ZIndex = 1001,
})

-- Section 2: Status
local sY = yOff + 50
UI.StatusText = CreateDrawing("Text", {
    Text = "✅ Script Active | Waiting...",
    Color = textColor,
    Size = 13,
    Position = Vector2.new(ScreenSize.X/2 - 175, sY),
    Center = false,
    Visible = true,
    ZIndex = 1001,
})

-- Separator 1
local sep1Y = sY + 30
local sep1 = CreateDrawing("Line", {
    From = Vector2.new(ScreenSize.X/2 - 180, sep1Y),
    To = Vector2.new(ScreenSize.X/2 + 180, sep1Y),
    Color = Color3.fromRGB(50, 50, 65),
    Thickness = 1,
    Visible = true,
    ZIndex = 1000,
})

-- Section 3: Toggles
local toggleLabels_texts = {
    "Auto-Collect Seeds",
    "Auto Defense",
    "Auto Stay at Base",
    "Weather Alerts",
}

local toggleDesc_texts = {
    "Golden & Rainbow seeds",
    "Attack thieves in base",
    "Return at night",
    "Weather change alerts",
}

local toggleY = sep1Y + 12
UI.ToggleStartY = toggleY

for i = 1, 4 do
    local ty = toggleY + (i-1) * 52
    
    local lbl = CreateDrawing("Text", {
        Text = toggleLabels_texts[i],
        Color = textColor,
        Size = 14,
        Position = Vector2.new(ScreenSize.X/2 - 175, ty),
        Center = false,
        Visible = true,
        ZIndex = 1001,
        Font = 2,
    })
    table.insert(UI.ToggleLabels, lbl)
    
    local desc = CreateDrawing("Text", {
        Text = toggleDesc_texts[i],
        Color = dimColor,
        Size = 11,
        Position = Vector2.new(ScreenSize.X/2 - 175, ty + 20),
        Center = false,
        Visible = true,
        ZIndex = 1001,
    })
    table.insert(UI.ToggleLabels, desc)
    
    -- Toggle background
    local tBg = CreateDrawing("Square", {
        Size = Vector2.new(44, 22),
        Position = Vector2.new(ScreenSize.X/2 + 130, ty + 1),
        Color = Color3.fromRGB(60, 60, 70),
        Filled = true,
        Transparency = 1,
        Visible = true,
        ZIndex = 1000,
    })
    table.insert(UI.ToggleBgs, tBg)
    
    -- Circle
    local circ = CreateDrawing("Square", {
        Size = Vector2.new(18, 18),
        Position = Vector2.new(ScreenSize.X/2 + 132, ty + 3),
        Color = Color3.fromRGB(255, 255, 255),
        Filled = true,
        Transparency = 1,
        Visible = true,
        ZIndex = 1001,
    })
    table.insert(UI.ToggleCircles, circ)
    
    UI.Toggles[i] = (i <= 3) -- first 3 on by default
    if UI.Toggles[i] then
        tBg.Color = accentColor
        circ.Position = Vector2.new(ScreenSize.X/2 + 154, ty + 3)
    end
end

-- Separator 2
local sep2Y = toggleY + 4*52 + 8
local sep2 = CreateDrawing("Line", {
    From = Vector2.new(ScreenSize.X/2 - 180, sep2Y),
    To = Vector2.new(ScreenSize.X/2 + 180, sep2Y),
    Color = Color3.fromRGB(50, 50, 65),
    Thickness = 1,
    Visible = true,
    ZIndex = 1000,
})

-- Info text at bottom
local infoY = sep2Y + 10
UI.InfoText = CreateDrawing("Text", {
    Text = "Gold Moon → Golden Seeds | Rainbow Moon → Rainbow Seeds",
    Color = Color3.fromRGB(180, 180, 100),
    Size = 11,
    Position = Vector2.new(ScreenSize.X/2 - 175, infoY),
    Center = false,
    Visible = true,
    ZIndex = 1001,
})

UI.InfoText2 = CreateDrawing("Text", {
    Text = "2% chance to spawn Rainbow Pet during events",
    Color = dimColor,
    Size = 11,
    Position = Vector2.new(ScreenSize.X/2 - 175, infoY + 18),
    Center = false,
    Visible = true,
    ZIndex = 1001,
})

-- ==========================================
-- UI HELPERS
-- ==========================================
local function UpdateWeatherDisplay(info)
    if not info then info = WeatherInfo[currentWeather] or WeatherInfo.Day end
    UI.WeatherIcon.Text = info.icon
    UI.WeatherText.Text = "Current: " .. currentWeather
    UI.WeatherText.Color = info.color
    UI.WeatherIcon.Color = info.color
end

local function UpdateWeatherTimer()
    local elapsed = tick() - weatherStartTime
    local remaining = math.max(0, weatherDuration - elapsed)
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    UI.WeatherTime.Text = string.format("Remaining: %02d:%02d", mins, secs)
end

local function SetStatus(text)
    UI.StatusText.Text = text
end

local function ToggleToggle(idx)
    UI.Toggles[idx] = not UI.Toggles[idx]
    local bg = UI.ToggleBgs[idx]
    local circ = UI.ToggleCircles[idx]
    local ty = UI.ToggleStartY + (idx-1) * 52
    
    if UI.Toggles[idx] then
        bg.Color = accentColor
        circ.Position = Vector2.new(ScreenSize.X/2 + 154, ty + 3)
    else
        bg.Color = Color3.fromRGB(60, 60, 70)
        circ.Position = Vector2.new(ScreenSize.X/2 + 132, ty + 3)
    end
end

-- ==========================================
-- MOUSE INPUT
-- ==========================================
local dragging = false
local dragOffset = Vector2.new(0, 0)
local dragStart = Vector2.new(0, 0)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local pos = input.Position
    local bgPos = UI.Bg.Position
    local bgSize = UI.Bg.Size
    
    -- Check close button
    local cx, cy = UI.CloseBtn.Position.X, UI.CloseBtn.Position.Y
    if pos.X >= cx and pos.X <= cx + 26 and pos.Y >= cy and pos.Y <= cy + 26 and input.UserInputType == Enum.UserInputType.MouseButton1 then
        minimized = not minimized
        if minimized then
            UI.Bg.Size = Vector2.new(200, 36)
            UI.TitleBg.Size = Vector2.new(200, 36)
            UI.WeatherIcon.Visible = false
            UI.WeatherText.Visible = false
            UI.WeatherTime.Visible = false
            UI.StatusText.Visible = false
            UI.InfoText.Visible = false
            UI.InfoText2.Visible = false
            sep1.Visible = false
            sep2.Visible = false
            for _,v in pairs(UI.ToggleLabels) do v.Visible = false end
            for _,v in pairs(UI.ToggleBgs) do v.Visible = false end
            for _,v in pairs(UI.ToggleCircles) do v.Visible = false end
            UI.CloseText.Text = "+"
            UI.CloseText.Position = Vector2.new(bgPos.X + 186, bgPos.Y + 8)
            UI.CloseBtn.Position = Vector2.new(bgPos.X + 173, bgPos.Y + 5)
            UI.Title.Text = "🌱 GAG2"
            UI.Title.Position = Vector2.new(bgPos.X + 8, bgPos.Y + 8)
        else
            UI.Bg.Size = Vector2.new(380, 440)
            UI.TitleBg.Size = Vector2.new(380, 36)
            UI.WeatherIcon.Visible = true
            UI.WeatherText.Visible = true
            UI.WeatherTime.Visible = true
            UI.StatusText.Visible = true
            UI.InfoText.Visible = true
            UI.InfoText2.Visible = true
            sep1.Visible = true
            sep2.Visible = true
            for _,v in pairs(UI.ToggleLabels) do v.Visible = true end
            for _,v in pairs(UI.ToggleBgs) do v.Visible = true end
            for _,v in pairs(UI.ToggleCircles) do v.Visible = true end
            UI.CloseText.Text = "X"
            UI.CloseText.Position = Vector2.new(bgPos.X + 13, bgPos.Y - 6 + 36)
            UI.CloseBtn.Position = Vector2.new(bgPos.X, bgPos.Y - 2 + 36)
            UI.Title.Text = "🌱 GAG2 Red Team"
            UI.Title.Position = Vector2.new(bgPos.X + 10, bgPos.Y + 6)
        end
        return
    end
    
    -- Check title bar drag
    if pos.Y >= bgPos.Y and pos.Y <= bgPos.Y + 36 and pos.X >= bgPos.X and pos.X <= bgPos.X + bgSize.X then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragOffset = Vector2.new(pos.X - bgPos.X, pos.Y - bgPos.Y)
        end
    end
    
    -- Check toggles
    for i = 1, 4 do
        local ty = UI.ToggleStartY + (i-1) * 52
        local bgX = ScreenSize.X/2 + 130
        if pos.X >= bgX and pos.X <= bgX + 44 and pos.Y >= ty + 1 and pos.Y <= ty + 23 then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                ToggleToggle(i)
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gpe)
    if gpe then return end
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local pos = input.Position
        local newX = pos.X - dragOffset.X
        local newY = pos.Y - dragOffset.Y
        local size = UI.Bg.Size
        
        UI.Bg.Position = Vector2.new(newX, newY)
        UI.TitleBg.Position = Vector2.new(newX, newY)
        UI.Title.Position = Vector2.new(newX + 10, newY + 8)
        UI.CloseBtn.Position = Vector2.new(newX + size.X - 28, newY + 5)
        UI.CloseText.Position = Vector2.new(newX + size.X - 15, newY + 10)
        
        local wY = newY + 45
        UI.WeatherIcon.Position = Vector2.new(newX + 5, wY)
        UI.WeatherText.Position = Vector2.new(newX + 35, wY + 3)
        UI.WeatherTime.Position = Vector2.new(newX + 5, wY + 24)
        
        local sY2 = wY + 50
        UI.StatusText.Position = Vector2.new(newX + 5, sY2)
        
        local sep1Y2 = sY2 + 30
        sep1.From = Vector2.new(newX, sep1Y2)
        sep1.To = Vector2.new(newX + size.X, sep1Y2)
        
        local tY2 = sep1Y2 + 12
        UI.ToggleStartY = tY2
        for i = 1, 4 do
            local ty2 = tY2 + (i-1) * 52
            UI.ToggleLabels[(i-1)*2+1].Position = Vector2.new(newX + 5, ty2)
            UI.ToggleLabels[(i-1)*2+2].Position = Vector2.new(newX + 5, ty2 + 20)
            UI.ToggleBgs[i].Position = Vector2.new(newX + size.X - 50, ty2 + 1)
            if UI.Toggles[i] then
                UI.ToggleCircles[i].Position = Vector2.new(newX + size.X - 30, ty2 + 3)
            else
                UI.ToggleCircles[i].Position = Vector2.new(newX + size.X - 48, ty2 + 3)
            end
        end
        
        local sep2Y2 = tY2 + 4*52 + 8
        sep2.From = Vector2.new(newX, sep2Y2)
        sep2.To = Vector2.new(newX + size.X, sep2Y2)
        
        local iY2 = sep2Y2 + 10
        UI.InfoText.Position = Vector2.new(newX + 5, iY2)
        UI.InfoText2.Position = Vector2.new(newX + 5, iY2 + 18)
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==========================================
-- CORE FEATURES
-- ==========================================

-- Find event seeds
local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            local isTarget = (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("coin") or name:find("nugget"))
                or (name:find("rainbow")) and (name:find("seed") or name:find("fruit") or name:find("star"))
            
            if isTarget then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchTransmitter") or obj:FindFirstChildWhichIsA("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

local function CollectSeed(obj)
    pcall(function()
        local detector = obj:FindFirstChildWhichIsA("ClickDetector")
        if detector then fireclickdetector(detector); return true end
        local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then fireproximityprompt(prompt); return true end
        local touch = obj:FindFirstChild("TouchTransmitter")
        if touch and root then
            root.CFrame = obj.CFrame * CFrame.new(0, 2, 0)
            task.wait(0.05)
            firetouchinterest(root, obj, 0)
            task.wait(0.05)
            firetouchinterest(root, obj, 1)
        end
    end)
    return false
end

local function Teleport(pos)
    if root then root.CFrame = CFrame.new(pos) end
end

local function FindBase()
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (name:find("garden") or name:find("plot") or name:find("base") or name:find("home")) and name:find(LP.Name:sub(1, 5):lower()) then
            return obj
        end
    end
    -- Fallback: find player's garden area
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("plot") or obj.Name:lower():find("garden")) then
            local dist = root and (root.Position - obj.Position).Magnitude or 999
            if dist < 100 then return obj end
        end
    end
    return nil
end

local function FindThreats()
    local base = FindBase()
    if not base or not base:IsA("BasePart") then return {} end
    local basePos = base.Position
    local threats = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - basePos).Magnitude
            if dist < Config.DefenseRange then table.insert(threats, plr) end
        end
    end
    return threats
end

local function EquipTool(name)
    local backpack = LP.Backpack
    if not backpack then return nil end
    local target = name:lower()
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find(target) or target:find(item.Name:lower())) then
            char.Humanoid:EquipTool(item)
            task.wait(0.2)
            return item
        end
    end
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool.Name:lower():find(target) or target:find(tool.Name:lower())) then
                return tool
            end
        end
    end
    return nil
end

local function AttackThief(thief)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    local tRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not tRoot then return end
    
    if root then root.CFrame = CFrame.lookAt(root.Position, tRoot.Position) end
    
    for _, weaponName in ipairs(Config.Weapons) do
        local weapon = EquipTool(weaponName)
        if weapon then
            if weapon.ToolTip and root then
                root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 3)
            end
            weapon:Activate()
            task.wait(0.1)
            weapon:Activate()
            SetStatus("⚔️ Attacking " .. thief.Name .. " with " .. weaponName)
            break
        end
    end
end

-- ==========================================
-- MAIN LOOP
-- ==========================================

local function MainLoop()
    while task.wait(0.5) do
        pcall(function()
            local screenSize = workspace.CurrentCamera.ViewportSize
            
            -- Update screen position if resized
            if math.abs(screenSize.X - ScreenSize.X) > 10 or math.abs(screenSize.Y - ScreenSize.Y) > 10 then
                if not dragging and not minimized then
                    local oldBgPos = UI.Bg.Position
                    local oldScreenSize = ScreenSize
                    local ratioX = screenSize.X / oldScreenSize.X
                    local ratioY = screenSize.Y / oldScreenSize.Y
                    -- Only auto-center if position is off-screen
                    if oldBgPos.X + UI.Bg.Size.X > screenSize.X or oldBgPos.Y + UI.Bg.Size.Y > screenSize.Y then
                        UI.Bg.Position = Vector2.new(screenSize.X/2 - 190, screenSize.Y/2 - 220)
                        UI.TitleBg.Position = UI.Bg.Position
                        UI.Title.Position = Vector2.new(UI.Bg.Position.X + 10, UI.Bg.Position.Y + 8)
                        UI.CloseBtn.Position = Vector2.new(UI.Bg.Position.X + 352, UI.Bg.Position.Y + 5)
                        UI.CloseText.Position = Vector2.new(UI.Bg.Position.X + 365, UI.Bg.Position.Y + 10)
                        local wY = UI.Bg.Position.Y + 45
                        UI.WeatherIcon.Position = Vector2.new(UI.Bg.Position.X + 5, wY)
                        UI.WeatherText.Position = Vector2.new(UI.Bg.Position.X + 35, wY + 3)
                        UI.WeatherTime.Position = Vector2.new(UI.Bg.Position.X + 5, wY + 24)
                        local sY2 = wY + 50
                        UI.StatusText.Position = Vector2.new(UI.Bg.Position.X + 5, sY2)
                    end
                end
                ScreenSize = screenSize
            end
            
            -- Weather detection
            if not weatherConnected then
                local detected = DetectWeatherFallback()
                if detected ~= currentWeather then
                    currentWeather = detected
                    weatherStartTime = tick()
                    if currentWeather == "Day" then weatherDuration = 160
                    elseif currentWeather == "Night" then weatherDuration = 80
                    else weatherDuration = 120 end
                    UpdateWeatherDisplay()
                    
                    if currentWeather == "GoldMoon" then
                        SetStatus("🌟 GOLD MOON - Golden seeds spawning!")
                    elseif currentWeather == "RainbowMoon" then
                        SetStatus("🌈 RAINBOW MOON - Rainbow seeds spawning!")
                    else
                        SetStatus("🌤️ Weather: " .. currentWeather)
                    end
                end
            end
            
            UpdateWeatherTimer()
            
            -- Auto Collect Seeds
            if UI.Toggles[1] then
                local seeds = FindEventSeeds()
                if #seeds > 0 then
                    for _, seed in ipairs(seeds) do
                        local dist = (seed.Position - root.Position).Magnitude
                        if dist < 150 then
                            Teleport(seed.CFrame * CFrame.new(0, 2, 0))
                            task.wait(0.1)
                            CollectSeed(seed)
                            SetStatus("🎯 Collected " .. seed.Name)
                            task.wait(0.3)
                        end
                    end
                end
            end
            
            -- Auto Stay Base at Night
            if UI.Toggles[3] then
                local isNight = currentWeather == "Night" or currentWeather == "BloodMoon" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon"
                if isNight then
                    local base = FindBase()
                    if base and base:IsA("BasePart") and root then
                        local dist = (root.Position - base.Position).Magnitude
                        if dist > 15 then
                            Teleport(base.Position + Vector3.new(0, 3, 0))
                            SetStatus("🌙 Night - Returned to base")
                            task.wait(1)
                        end
                    end
                end
            end
            
            -- Auto Defense
            if UI.Toggles[2] then
                local threats = FindThreats()
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
            
            -- Idle status update
            if not UI.StatusText.Text:find("⚔️") and not UI.StatusText.Text:find("🎯") and not UI.StatusText.Text:find("🌙") and not UI.StatusText.Text:find("🌟") and not UI.StatusText.Text:find("🌈") then
                SetStatus("✅ Active | " .. currentWeather .. " | Monitoring...")
            end
        end)
    end
end

-- Init
task.spawn(function()
    task.wait(2)
    ConnectWeather()
end)

-- Character respawn
LP.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = newChar:WaitForChild("HumanoidRootPart")
end)

-- Start
task.spawn(MainLoop)

SetStatus("✅ Script loaded | Delta Compatible")

-- Chat notification
pcall(function()
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = "🌱 GAG2 Red Team Loaded | 5 Features | Delta Compatible",
        Color = Color3.fromRGB(40, 180, 80),
    })
end)

print("🌱 GAG2 Red Team Script Loaded Successfully!")