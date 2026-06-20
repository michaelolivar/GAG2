--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - Devo GAG2                     ║
║         Delta Executor • Drawing API • Fixed UI             ║
╚══════════════════════════════════════════════════════════════╝
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local Chat = game:GetService("Chat")

local LP = Players.LocalPlayer
local char = LP.Character or LP.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")
local ScreenSize = workspace.CurrentCamera.ViewportSize

-- ==========================================
-- WEATHER DATA - EXACT GAME NAMES
-- ==========================================
-- The game sends these exact weather names via WeatherEventStarted remote:
-- "Sunny", "Rain", "Lightning", "Rainbow", "Snowfall", "Starfall", "Blood Moon", "Gold Moon", "Rainbow Moon"
-- Night = clock time < 5.5 or > 18.5

local currentWeather = "Sunny"
local weatherStartTime = tick()
local weatherDuration = 300
local weatherConnected = false
local isNight = false

local WeatherDB = {
    Sunny       = {icon="☀️", color=Color3.fromRGB(255,220,80),  dur=999, desc="Normal growth"},
    Rain        = {icon="🌧️", color=Color3.fromRGB(100,180,255), dur=300, desc="2x growth speed"},
    Lightning   = {icon="⚡", color=Color3.fromRGB(255,255,80),  dur=300, desc="Electric mutation (80x)"},
    Rainbow     = {icon="🌈", color=Color3.fromRGB(255,130,255), dur=300, desc="Rainbow luck +10x"},
    Snowfall    = {icon="❄️", color=Color3.fromRGB(200,230,255), dur=150, desc="Frozen mutation (3x)"},
    Starfall    = {icon="⭐", color=Color3.fromRGB(255,230,150), dur=120, desc="Starstruck mutation"},
    ["Blood Moon"] = {icon="🌑", color=Color3.fromRGB(220,60,60),   dur=120, desc="Bloodlit mutation (night)"},
    ["Gold Moon"]  = {icon="🌟", color=Color3.fromRGB(255,210,60),  dur=120, desc="✦ Gold Seeds spawning ✦"},
    ["Rainbow Moon"] = {icon="🌈", color=Color3.fromRGB(100,255,200), dur=120, desc="✦ Rainbow Seeds spawning ✦"},
    Night       = {icon="🌙", color=Color3.fromRGB(140,140,220), dur=80,  desc="Stealing active!"},
}

-- Map all possible variations the game might send
local WeatherNameMap = {}
for k,v in pairs(WeatherDB) do
    local key = k:lower():gsub("[^a-z]","")
    WeatherNameMap[key] = k
end
WeatherNameMap["goldmoon"] = "Gold Moon"
WeatherNameMap["goldenmoon"] = "Gold Moon"
WeatherNameMap["rainbowmoon"] = "Rainbow Moon"
WeatherNameMap["midas"] = "Gold Moon"
WeatherNameMap["bloodmoon"] = "Blood Moon"
WeatherNameMap["thunderstorm"] = "Lightning"
WeatherNameMap["thunder"] = "Lightning"
WeatherNameMap["blizzard"] = "Snowfall"
WeatherNameMap["snow"] = "Snowfall"

-- ==========================================
-- CONNECT TO WEATHER REMOTE
-- ==========================================
local function SetupWeatherRemote()
    local success, remote = pcall(function()
        return ReplicatedStorage:FindFirstChild("GameEvents") and ReplicatedStorage.GameEvents:FindFirstChild("WeatherEventStarted")
    end)
    
    if success and remote then
        remote.OnClientEvent:Connect(function(eventName, lengthSec)
            pcall(function()
                if type(eventName) ~= "string" then return end
                
                -- Normalize the weather name
                local clean = eventName:lower():gsub("[^a-z]","")
                local mapped = WeatherNameMap[clean]
                if not mapped then
                    for k,v in pairs(WeatherNameMap) do
                        if clean:find(k) or k:find(clean) then mapped = v; break end
                    end
                end
                if not mapped then mapped = eventName end
                
                local dur = (type(lengthSec) == "number" and lengthSec > 0) and lengthSec or (WeatherDB[mapped] and WeatherDB[mapped].dur or 120)
                
                currentWeather = mapped
                weatherDuration = dur
                weatherStartTime = tick()
                weatherConnected = true
                
                local info = WeatherDB[currentWeather] or WeatherDB.Sunny
                UpdateWeatherDisplay(info)
                
                -- Special alerts
                if currentWeather == "Gold Moon" then
                    SetStatus("🌟 GOLD MOON - Golden seeds spawning!")
                elseif currentWeather == "Rainbow Moon" then
                    SetStatus("🌈 RAINBOW MOON - Rainbow seeds spawning!")
                elseif currentWeather == "Blood Moon" then
                    SetStatus("🌑 BLOOD MOON - Bloodlit mutation active!")
                elseif currentWeather == "Rainbow" then
                    SetStatus("🌈 RAINBOW - Rainbow luck boosted 10x!")
                elseif currentWeather == "Lightning" then
                    SetStatus("⚡ LIGHTNING - Electric mutation (80x)!")
                elseif currentWeather == "Snowfall" then
                    SetStatus("❄️ SNOWFALL - Frozen mutation (3x)!")
                elseif currentWeather == "Starfall" then
                    SetStatus("⭐ STARFALL - Starstruck mutation!")
                elseif currentWeather == "Rain" then
                    SetStatus("🌧️ RAIN - 2x growth speed!")
                end
            end)
        end)
    else
        warn("⚠️ Weather remote not found, using fallback detection")
    end
end

-- ==========================================
-- FALLBACK WEATHER DETECTION
-- ==========================================
local function DetectWeatherFallback()
    -- Check particle emitters for active weather
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") and v.Enabled then
            local tag = (v.Name.." "..(v.Parent and v.Parent.Name or "")):lower()
            if tag:find("lightning") or tag:find("thunder") then return "Lightning" end
            if tag:find("rain") and not tag:find("bow") and not tag:find("bow") then return "Rain" end
            if tag:find("snow") or tag:find("blizzard") then return "Snowfall" end
            if tag:find("star") and tag:find("fall") then return "Starfall" end
            if tag:find("rainbow") and not tag:find("rain") then return "Rainbow" end
        end
    end
    
    -- Check clock time for night
    local ct = Lighting.ClockTime or 12
    isNight = ct < 5.5 or ct > 18.5
    
    -- Check ambient for moon events
    if isNight then
        local amb = Lighting.Ambient or Color3.new()
        if amb.R > 0.35 and amb.G < 0.08 then return "Blood Moon" end
        if amb.R > 0.35 and amb.G > 0.25 then return "Gold Moon" end
        if amb.B > 0.4 and amb.R < 0.2 then return "Rainbow Moon" end
        return "Night"
    end
    
    -- Check sky appearance
    for _,v in pairs(Workspace:GetDescendants()) do
        if v:IsA("Sky") then
            local skyColor = v.SkyboxBk or v.SkyboxUp
            -- Can't easily read skybox colors, skip
        end
    end
    
    -- Try reading weather icon in player GUI
    local plrGui = LP:FindFirstChild("PlayerGui")
    if plrGui then
        for _, gui in pairs(plrGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("TextLabel") then
                local txt = (gui:IsA("TextLabel") and gui.Text or gui.Name):lower()
                for weatherName in pairs(WeatherDB) do
                    if txt:find(weatherName:lower():gsub("[^a-z]","")) then
                        return weatherName
                    end
                end
            end
        end
    end
    
    return "Sunny"
end

-- ==========================================
-- DRAWING API UI - FIXED VERSION
-- ==========================================
local UI = {
    Bg = nil,
    TitleBg = nil,
    Title = nil,
    MinimizeBtn = nil,
    MinimizeText = nil,
    CloseBtn = nil,
    CloseText = nil,
    WeatherIcon = nil,
    WeatherText = nil,
    WeatherTime = nil,
    WeatherDesc = nil,
    StatusText = nil,
    Sep1 = nil,
    Sep2 = nil,
    InfoText = nil,
    ToggleLabels = {},
    ToggleDescs = {},
    ToggleBgs = {},
    ToggleCircles = {},
    Toggles = {},
}

-- Toggle states: 1=AutoCollect, 2=AutoDefense, 3=AutoStayBase, 4=WeatherAlerts
local ToggleState = {true, true, true, true}

local function Draw(type, props)
    local d = Drawing.new(type)
    for k,v in pairs(props) do
        pcall(function() d[k] = v end)
    end
    return d
end

local C = {
    bg = Color3.fromRGB(25, 25, 35),
    accent = Color3.fromRGB(40, 180, 80),
    text = Color3.fromRGB(230, 230, 230),
    dim = Color3.fromRGB(140, 140, 140),
    danger = Color3.fromRGB(220, 60, 60),
    gold = Color3.fromRGB(255, 210, 60),
    warn = Color3.fromRGB(255, 180, 50),
}

local W = 400
local H = 460
local TitleH = 36
local startX = ScreenSize.X/2 - W/2
local startY = ScreenSize.Y/2 - H/2

-- Background
UI.Bg = Draw("Square", {
    Size = Vector2.new(W, H),
    Position = Vector2.new(startX, startY),
    Color = C.bg,
    Filled = true,
    Transparency = 1,
    ZIndex = 999,
})

-- Title bar
UI.TitleBg = Draw("Square", {
    Size = Vector2.new(W, TitleH),
    Position = Vector2.new(startX, startY),
    Color = C.accent,
    Filled = true,
    Transparency = 1,
    ZIndex = 1000,
})

UI.Title = Draw("Text", {
    Text = "🌱 GAG2 Red Team",
    Color = Color3.fromRGB(255, 255, 255),
    Size = 16,
    Position = Vector2.new(startX + 10, startY + 8),
    Center = false,
    Outline = true,
    ZIndex = 1001,
    Font = 2,
})

-- Close button (X)
UI.CloseBtn = Draw("Square", {
    Size = Vector2.new(28, 28),
    Position = Vector2.new(startX + W - 34, startY + 4),
    Color = C.danger,
    Filled = true,
    Transparency = 1,
    ZIndex = 1000,
})

UI.CloseText = Draw("Text", {
    Text = "X",
    Color = Color3.fromRGB(255, 255, 255),
    Size = 14,
    Position = Vector2.new(startX + W - 20, startY + 10),
    Center = true,
    ZIndex = 1001,
    Font = 2,
})

-- Minimize button (-)
UI.MinimizeBtn = Draw("Square", {
    Size = Vector2.new(28, 28),
    Position = Vector2.new(startX + W - 68, startY + 4),
    Color = C.warn,
    Filled = true,
    Transparency = 1,
    ZIndex = 1000,
})

UI.MinimizeText = Draw("Text", {
    Text = "—",
    Color = Color3.fromRGB(255, 255, 255),
    Size = 14,
    Position = Vector2.new(startX + W - 54, startY + 10),
    Center = true,
    ZIndex = 1001,
    Font = 2,
})

-- ==========================================
-- BUILD UI CONTENT
-- ==========================================
local function BuildFullUI()
    local y = startY + 50
    
    -- Weather section header
    local weatherHdr = Draw("Text", {
        Text = "=== WEATHER TRACKER ===",
        Color = Color3.fromRGB(80, 180, 255),
        Size = 12,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
        Font = 2,
    })
    y = y + 22
    
    UI.WeatherIcon = Draw("Text", {
        Text = "☀️",
        Color = Color3.fromRGB(255, 220, 80),
        Size = 22,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
    })
    
    UI.WeatherText = Draw("Text", {
        Text = "Current: Sunny",
        Color = Color3.fromRGB(255, 220, 80),
        Size = 15,
        Position = Vector2.new(startX + 42, y + 3),
        Center = false,
        ZIndex = 1001,
        Font = 2,
    })
    
    y = y + 26
    
    UI.WeatherDesc = Draw("Text", {
        Text = "Normal growth",
        Color = C.dim,
        Size = 11,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
    })
    y = y + 16
    
    UI.WeatherTime = Draw("Text", {
        Text = "Remaining: --:--",
        Color = C.dim,
        Size = 12,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
    })
    y = y + 30
    
    -- Separator
    UI.Sep1 = Draw("Line", {
        From = Vector2.new(startX + 5, y),
        To = Vector2.new(startX + W - 5, y),
        Color = Color3.fromRGB(50, 50, 65),
        Thickness = 1,
        ZIndex = 1000,
    })
    y = y + 12
    
    -- Status
    UI.StatusText = Draw("Text", {
        Text = "✅ Script Active | Monitoring...",
        Color = C.text,
        Size = 13,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
    })
    y = y + 30
    
    -- Separator
    UI.Sep2 = Draw("Line", {
        From = Vector2.new(startX + 5, y),
        To = Vector2.new(startX + W - 5, y),
        Color = Color3.fromRGB(50, 50, 65),
        Thickness = 1,
        ZIndex = 1000,
    })
    y = y + 10
    
    -- Section header
    local toggleHdr = Draw("Text", {
        Text = "=== FEATURES ===",
        Color = C.accent,
        Size = 12,
        Position = Vector2.new(startX + 10, y),
        Center = false,
        ZIndex = 1001,
        Font = 2,
    })
    y = y + 22
    
    -- Toggle items
    local toggleData = {
        {label="Auto-Collect Event Seeds", desc="Golden & Rainbow seeds"},
        {label="Auto Defense", desc="Attack thieves in your base"},
        {label="Auto Stay at Base (Night)", desc="Return to base at night"},
        {label="Weather Alerts", desc="Notify on weather changes"},
    }
    
    for i = 1, 4 do
        local ty = y + (i-1) * 48
        
        local lbl = Draw("Text", {
            Text = toggleData[i].label,
            Color = C.text,
            Size = 14,
            Position = Vector2.new(startX + 10, ty),
            Center = false,
            ZIndex = 1001,
            Font = 2,
        })
        table.insert(UI.ToggleLabels, lbl)
        
        local desc = Draw("Text", {
            Text = toggleData[i].desc,
            Color = C.dim,
            Size = 11,
            Position = Vector2.new(startX + 10, ty + 18),
            Center = false,
            ZIndex = 1001,
        })
        table.insert(UI.ToggleDescs, desc)
        
        -- Toggle background
        local tBg = Draw("Square", {
            Size = Vector2.new(46, 24),
            Position = Vector2.new(startX + W - 60, ty + 2),
            Color = ToggleState[i] and C.accent or Color3.fromRGB(60, 60, 70),
            Filled = true,
            Transparency = 1,
            ZIndex = 1000,
        })
        table.insert(UI.ToggleBgs, tBg)
        
        -- Circle/knob
        local circ = Draw("Square", {
            Size = Vector2.new(20, 20),
            Position = ToggleState[i] and Vector2.new(startX + W - 56, ty + 4) or Vector2.new(startX + W - 82, ty + 4),
            Color = Color3.fromRGB(255, 255, 255),
            Filled = true,
            Transparency = 1,
            ZIndex = 1001,
        })
        table.insert(UI.ToggleCircles, circ)
    end
    
    local yEnd = y + 4*48 + 15
    
    -- Separator
    local sep3 = Draw("Line", {
        From = Vector2.new(startX + 5, yEnd),
        To = Vector2.new(startX + W - 5, yEnd),
        Color = Color3.fromRGB(50, 50, 65),
        Thickness = 1,
        ZIndex = 1000,
    })
    yEnd = yEnd + 12
    
    -- Info text
    UI.InfoText = Draw("Text", {
        Text = "Gold Moon → Golden Seeds | Rainbow Moon → Rainbow Seeds",
        Color = Color3.fromRGB(180, 180, 100),
        Size = 11,
        Position = Vector2.new(startX + 10, yEnd),
        Center = false,
        ZIndex = 1001,
    })
    yEnd = yEnd + 16
    
    local info2 = Draw("Text", {
        Text = "2% chance to spawn Rainbow Pet during Rainbow events",
        Color = C.dim,
        Size = 11,
        Position = Vector2.new(startX + 10, yEnd),
        Center = false,
        ZIndex = 1001,
    })
end

BuildFullUI()

-- ==========================================
-- UI FUNCTIONS
-- ==========================================
local minimized = false

local function UpdateWeatherDisplay(info)
    if not info then info = WeatherDB[currentWeather] or WeatherDB.Sunny end
    UI.WeatherIcon.Text = info.icon
    UI.WeatherText.Text = "Current: " .. currentWeather
    UI.WeatherText.Color = info.color
    UI.WeatherIcon.Color = info.color
    UI.WeatherDesc.Text = info.desc
end

local function UpdateWeatherTimer()
    local elapsed = tick() - weatherStartTime
    local remaining = math.max(0, weatherDuration - elapsed)
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    UI.WeatherTime.Text = string.format("Remaining: %02d:%02d", mins, secs)
end

local function SetStatus(text)
    if UI.StatusText then UI.StatusText.Text = text end
end

local function ToggleFeature(idx)
    ToggleState[idx] = not ToggleState[idx]
    local bg = UI.ToggleBgs[idx]
    local circ = UI.ToggleCircles[idx]
    local ty = 0
    -- Calculate y position
    for i = 1, 4 do
        if i == idx then
            ty = UI.ToggleLabels[idx].Position.Y - 2
            break
        end
    end
    
    if ToggleState[idx] then
        bg.Color = C.accent
        circ.Position = Vector2.new(startX + W - 56, ty)
    else
        bg.Color = Color3.fromRGB(60, 60, 70)
        circ.Position = Vector2.new(startX + W - 82, ty)
    end
end

local function MinimizeUI()
    minimized = not minimized
    if minimized then
        UI.Bg.Size = Vector2.new(200, TitleH)
        UI.TitleBg.Size = Vector2.new(200, TitleH)
        UI.Title.Text = "🌱 GAG2"
        UI.Title.Position = Vector2.new(startX + 8, startY + 8)
        
        -- Hide all content elements
        UI.CloseBtn.Visible = false
        UI.CloseText.Visible = false
        UI.MinimizeText.Text = "+"
        
        UI.WeatherIcon.Visible = false
        UI.WeatherText.Visible = false
        UI.WeatherTime.Visible = false
        UI.WeatherDesc.Visible = false
        UI.StatusText.Visible = false
        UI.InfoText.Visible = false
        UI.Sep1.Visible = false
        UI.Sep2.Visible = false
        
        for _,v in pairs(UI.ToggleLabels) do v.Visible = false end
        for _,v in pairs(UI.ToggleDescs) do v.Visible = false end
        for _,v in pairs(UI.ToggleBgs) do v.Visible = false end
        for _,v in pairs(UI.ToggleCircles) do v.Visible = false end
    else
        UI.Bg.Size = Vector2.new(W, H)
        UI.TitleBg.Size = Vector2.new(W, TitleH)
        UI.Title.Text = "🌱 GAG2 Red Team"
        UI.Title.Position = Vector2.new(startX + 10, startY + 8)
        
        UI.CloseBtn.Visible = true
        UI.CloseText.Visible = true
        UI.MinimizeText.Text = "—"
        
        UI.WeatherIcon.Visible = true
        UI.WeatherText.Visible = true
        UI.WeatherTime.Visible = true
        UI.WeatherDesc.Visible = true
        UI.StatusText.Visible = true
        UI.InfoText.Visible = true
        UI.Sep1.Visible = true
        UI.Sep2.Visible = true
        
        for _,v in pairs(UI.ToggleLabels) do v.Visible = true end
        for _,v in pairs(UI.ToggleDescs) do v.Visible = true end
        for _,v in pairs(UI.ToggleBgs) do v.Visible = true end
        for _,v in pairs(UI.ToggleCircles) do v.Visible = true end
    end
end

-- ==========================================
-- MOUSE INPUT HANDLING - FIXED VERSION
-- ==========================================
local dragging = false
local dragOffset = Vector2.new(0, 0)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    local pos = input.Position
    
    -- CLOSE BUTTON CHECK
    local cx, cy = UI.CloseBtn.Position.X, UI.CloseBtn.Position.Y
    if pos.X >= cx and pos.X <= cx + 28 and pos.Y >= cy and pos.Y <= cy + 28 then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Destroy UI completely
            for _,v in pairs(UI) do
                if type(v) == "table" then
                    for _,vv in pairs(v) do
                        if type(vv) == "Drawing" then pcall(function() vv:Remove() end) end
                    end
                elseif type(v) == "Drawing" then
                    pcall(function() v:Remove() end)
                end
            end
            print("GAG2: Script unloaded")
            return
        end
    end
    
    -- MINIMIZE BUTTON CHECK
    local mx, my = UI.MinimizeBtn.Position.X, UI.MinimizeBtn.Position.Y
    if pos.X >= mx and pos.X <= mx + 28 and pos.Y >= my and pos.Y <= my + 28 then
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            MinimizeUI()
            return
        end
    end
    
    -- DRAG CHECK (title bar area, not on buttons)
    local bgPos = UI.Bg.Position
    local bgSize = UI.Bg.Size
    if pos.Y >= bgPos.Y and pos.Y <= bgPos.Y + TitleH and pos.X >= bgPos.X and pos.X <= bgPos.X + bgSize.X then
        -- Check if not on close or minimize button
        local onClose = pos.X >= cx and pos.X <= cx + 28
        local onMin = pos.X >= mx and pos.X <= mx + 28
        if not onClose and not onMin then
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragOffset = Vector2.new(pos.X - bgPos.X, pos.Y - bgPos.Y)
            end
        end
    end
    
    -- TOGGLE CHECKS (only if not minimized)
    if not minimized then
        for i = 1, 4 do
            local tBg = UI.ToggleBgs[i]
            if tBg and tBg.Visible then
                local tx, ty = tBg.Position.X, tBg.Position.Y
                if pos.X >= tx and pos.X <= tx + 46 and pos.Y >= ty and pos.Y <= ty + 24 then
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        ToggleFeature(i)
                        return
                    end
                end
            end
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gpe)
    if gpe then return end
    if dragging then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local pos = input.Position
            startX = pos.X - dragOffset.X
            startY = pos.Y - dragOffset.Y
            
            -- Update all positions
            local function MoveDraw(obj, newX, newY)
                if obj and type(obj) == "Drawing" then
                    obj.Position = Vector2.new(newX, newY)
                end
            end
            
            MoveDraw(UI.Bg, startX, startY)
            MoveDraw(UI.TitleBg, startX, startY)
            MoveDraw(UI.Title, startX + 10, startY + 8)
            MoveDraw(UI.CloseBtn, startX + W - 34, startY + 4)
            MoveDraw(UI.CloseText, startX + W - 20, startY + 10)
            MoveDraw(UI.MinimizeBtn, startX + W - 68, startY + 4)
            MoveDraw(UI.MinimizeText, startX + W - 54, startY + 10)
            
            if not minimized then
                local y = startY + 50
                MoveDraw(UI.WeatherIcon, startX + 10, y + 22)
                MoveDraw(UI.WeatherText, startX + 42, y + 25)
                y = y + 48
                MoveDraw(UI.WeatherDesc, startX + 10, y)
                y = y + 16
                MoveDraw(UI.WeatherTime, startX + 10, y)
                y = y + 30
                
                if UI.Sep1 then
                    UI.Sep1.From = Vector2.new(startX + 5, y)
                    UI.Sep1.To = Vector2.new(startX + W - 5, y)
                end
                y = y + 12
                MoveDraw(UI.StatusText, startX + 10, y)
                y = y + 30
                
                if UI.Sep2 then
                    UI.Sep2.From = Vector2.new(startX + 5, y)
                    UI.Sep2.To = Vector2.new(startX + W - 5, y)
                end
                y = y + 32
                
                for i = 1, 4 do
                    local ty = y + (i-1) * 48
                    if UI.ToggleLabels[i] then
                        MoveDraw(UI.ToggleLabels[i], startX + 10, ty)
                    end
                    if UI.ToggleDescs[i] then
                        MoveDraw(UI.ToggleDescs[i], startX + 10, ty + 18)
                    end
                    if UI.ToggleBgs[i] then
                        MoveDraw(UI.ToggleBgs[i], startX + W - 60, ty + 2)
                    end
                    if UI.ToggleCircles[i] then
                        if ToggleState[i] then
                            MoveDraw(UI.ToggleCircles[i], startX + W - 56, ty + 4)
                        else
                            MoveDraw(UI.ToggleCircles[i], startX + W - 82, ty + 4)
                        end
                    end
                end
                
                local yEnd = y + 4*48 + 15
                MoveDraw(UI.InfoText, startX + 10, yEnd + 12)
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ==========================================
-- CHAT HEAD SYSTEM
-- ==========================================
local ChatHead = nil
local ChatHeadText = nil
local ChatHeadEnabled = true

local function CreateChatHead()
    -- Chat head drawing circle
    ChatHead = Draw("Circle", {
        Position = Vector2.new(ScreenSize.X - 60, ScreenSize.Y - 160),
        Radius = 28,
        Color = C.accent,
        Filled = true,
        Transparency = 0.2,
        ZIndex = 998,
        NumSides = 32,
        Thickness = 3,
    })
    
    ChatHeadText = Draw("Text", {
        Text = "GAG2",
        Color = Color3.fromRGB(255, 255, 255),
        Size = 11,
        Position = Vector2.new(ScreenSize.X - 60, ScreenSize.Y - 164),
        Center = true,
        Outline = true,
        ZIndex = 999,
        Font = 2,
    })
    
    -- Chat head label
    ChatHeadLabel = Draw("Text", {
        Text = "✅",
        Color = Color3.fromRGB(0, 255, 0),
        Size = 16,
        Position = Vector2.new(ScreenSize.X - 60, ScreenSize.Y - 145),
        Center = true,
        ZIndex = 999,
    })
end

local function UpdateChatHead(text, color)
    if not ChatHeadEnabled then return end
    if not ChatHead then CreateChatHead() end
    if ChatHeadText then
        ChatHeadText.Text = text or "GAG2"
    end
    if ChatHead then
        ChatHead.Color = color or C.accent
        -- Pulse animation
        local pulse = math.sin(tick() * 3) * 0.08
        ChatHead.Transparency = 0.15 + pulse
    end
end

local chatHeadMessages = {
    "GAG2", "🌱", "✅", "⚔️", "🌙", "🌟", "🌈"
}
local chatMsgIdx = 1
local chatMsgTimer = 0

-- Make chat head draggable too
local chDragging = false
local chDragOffset = Vector2.new(0,0)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not ChatHead then return end
    local pos = input.Position
    local chPos = ChatHead.Position
    local dist = (Vector2.new(pos.X, pos.Y) - chPos).Magnitude
    if dist < 35 then
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            chDragging = true
            chDragOffset = Vector2.new(pos.X - chPos.X, pos.Y - chPos.Y)
        end
    end
end)

UserInputService.InputChanged:Connect(function(input, gpe)
    if gpe then return end
    if chDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local pos = input.Position
        local nx = pos.X - chDragOffset.X
        local ny = pos.Y - chDragOffset.Y
        if ChatHead then ChatHead.Position = Vector2.new(nx, ny) end
        if ChatHeadText then ChatHeadText.Position = Vector2.new(nx, ny - 4) end
        if ChatHeadLabel then ChatHeadLabel.Position = Vector2.new(nx, ny + 15) end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        chDragging = false
    end
end)

-- ==========================================
-- CORE GAME FEATURES
-- ==========================================

local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            local hasDetector = obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchTransmitter") or obj:FindFirstChildWhichIsA("ProximityPrompt")
            if hasDetector then
                local isTarget = (name:find("gold") and (name:find("seed") or name:find("coin") or name:find("nugget") or name:find("fruit")))
                    or (name:find("rainbow") and (name:find("seed") or name:find("fruit") or name:find("star")))
                    or name:find("goldenseed") or name:find("rainbowseed")
                    or name:find("midas")
                if isTarget then
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
end

local function TeleportTo(pos)
    if root then root.CFrame = CFrame.new(pos) end
end

local function FindMyBase()
    local pName = LP.Name:lower()
    -- Check gardens folder
    local gardens = Workspace:FindFirstChild("Gardens")
    if gardens then
        local garden = gardens:FindFirstChild(LP.Name)
        if garden then return garden end
        -- Check by partial name
        for _, v in pairs(gardens:GetChildren()) do
            if v.Name:lower():find(pName:sub(1, 5)) then return v end
        end
    end
    -- Check workspace for plots
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if (name:find("plot") or name:find("garden") or name:find("base")) and (name:find(pName:sub(1, 5)) or (root and (obj.Position - root.Position).Magnitude < 30)) then
                return obj
            end
        end
    end
    -- Fallback: find any plot near player
    if root then
        local closest, closestDist = nil, 999
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("plot") or obj.Name:lower():find("garden")) then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < closestDist then closest = obj; closestDist = dist end
            end
        end
        if closest then return closest end
    end
    return nil
end

local function FindThreats()
    local base = FindMyBase()
    if not base then return {} end
    local basePos = base:IsA("BasePart") and base.Position or nil
    if not basePos then return {} end
    local threats = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (plr.Character.HumanoidRootPart.Position - basePos).Magnitude
            if dist < 35 then table.insert(threats, plr) end
        end
    end
    return threats
end

local function EquipWeapon(name)
    local backpack = LP.Backpack
    if not backpack then return nil end
    local target = name:lower()
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") and (item.Name:lower():find(target) or target:find(item.Name:lower())) then
            char.Humanoid:EquipTool(item)
            task.wait(0.15)
            return item
        end
    end
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = tool.Name:lower()
                if tn:find(target) or target:find(tn) then return tool end
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
    
    local weapons = {"Freeze Ray", "Power Hose", "Crowbar", "Shovel"}
    for _, wName in ipairs(weapons) do
        local weapon = EquipWeapon(wName)
        if weapon then
            if root then root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 2.5) end
            weapon:Activate()
            task.wait(0.15)
            weapon:Activate()
            SetStatus("⚔️ Attacking " .. thief.Name .. " with " .. wName)
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
            -- Weather: try remote first, fallback to detection
            if not weatherConnected then
                local detected = DetectWeatherFallback()
                if detected ~= currentWeather then
                    currentWeather = detected
                    weatherStartTime = tick()
                    local info = WeatherDB[currentWeather] or WeatherDB.Sunny
                    weatherDuration = info.dur
                    UpdateWeatherDisplay(info)
                    if currentWeather == "Gold Moon" or currentWeather == "Rainbow Moon" then
                        SetStatus("⭐ EVENT: " .. currentWeather .. " - Seeds spawning!")
                    else
                        SetStatus("🌤️ Weather: " .. currentWeather)
                    end
                end
            end
            
            UpdateWeatherTimer()
            
            -- AUTO COLLECT SEEDS
            if ToggleState[1] then
                local seeds = FindEventSeeds()
                if #seeds > 0 then
                    for _, seed in ipairs(seeds) do
                        if root then
                            local dist = (seed.Position - root.Position).Magnitude
                            if dist < 150 then
                                TeleportTo(seed.CFrame * CFrame.new(0, 2, 0))
                                task.wait(0.1)
                                CollectSeed(seed)
                                SetStatus("🎯 Collected " .. seed.Name)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
            
            -- AUTO STAY BASE AT NIGHT
            if ToggleState[3] then
                local ct = Lighting.ClockTime or 12
                local nightTime = ct < 5.5 or ct > 18.5
                local isNightWeather = currentWeather == "Night" or currentWeather == "Blood Moon" or currentWeather == "Gold Moon" or currentWeather == "Rainbow Moon"
                
                if nightTime or isNightWeather then
                    local base = FindMyBase()
                    if base and base:IsA("BasePart") and root then
                        local dist = (root.Position - base.Position).Magnitude
                        if dist > 15 then
                            TeleportTo(base.Position + Vector3.new(0, 3, 0))
                            SetStatus("🌙 Night - Returned to base")
                            UpdateChatHead("🌙", Color3.fromRGB(140, 140, 220))
                            task.wait(1)
                        end
                    end
                end
            end
            
            -- AUTO DEFENSE
            if ToggleState[2] then
                local threats = FindThreats()
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief)
                        UpdateChatHead("⚔️", C.danger)
                        task.wait(1.5)
                    end
                end
            end
            
            -- Idle status
            local currentStatus = UI.StatusText and UI.StatusText.Text or ""
            if not currentStatus:find("⚔️") and not currentStatus:find("🎯") and not currentStatus:find("🌙") and not currentStatus:find("🌟") and not currentStatus:find("🌈") then
                SetStatus("✅ Active | " .. currentWeather .. " | Monitoring...")
            end
            
            -- CHAT HEAD ANIMATION
            chatMsgTimer = chatMsgTimer + 0.5
            if chatMsgTimer >= 5 then
                chatMsgTimer = 0
                chatMsgIdx = chatMsgIdx % #chatHeadMessages + 1
                local weatherIcon = WeatherDB[currentWeather] and WeatherDB[currentWeather].icon or "🌱"
                local msg = chatHeadMessages[chatMsgIdx]
                if msg == "GAG2" then
                    UpdateChatHead("GAG2", C.accent)
                elseif msg == "🌱" then
                    UpdateChatHead("🌱", C.accent)
                elseif msg == "✅" then
                    UpdateChatHead("✅", Color3.fromRGB(0, 255, 0))
                elseif msg == weatherIcon then
                    UpdateChatHead(weatherIcon, WeatherDB[currentWeather] and WeatherDB[currentWeather].color or C.text)
                else
                    UpdateChatHead(msg, Color3.fromRGB(255, 255, 255))
                end
            end
        end)
    end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

-- Connect weather remote
task.spawn(function()
    task.wait(2)
    SetupWeatherRemote()
end)

-- Character respawn handler
LP.CharacterAdded:Connect(function(newChar)
    char = newChar
    root = newChar:WaitForChild("HumanoidRootPart", 10)
end)

-- Create chat head
CreateChatHead()

-- Start main loop
task.spawn(MainLoop)

-- Initial status
SetStatus("✅ Script loaded | Delta Compatible")

-- Chat notification
pcall(function()
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = "🌱 GAG2 Red Team Loaded | 5 Features Active | Delta Compatible",
        Color = Color3.fromRGB(40, 180, 80),
    })
end)

print("🌱 GAG2 Red Team Script Loaded Successfully!")