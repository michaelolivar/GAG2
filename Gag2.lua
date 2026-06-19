--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - Devo GAG2 FINAL               ║
║           Delta Executor Compatible • Premium UI            ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- Configuration
local Config = {
    AutoCollectSeeds = true,
    AutoDefense = true,
    AutoStayBase = true,
    NotifyShop = true,
    AntiAFK = true,
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
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Cleanup existing
pcall(function()
    if CoreGui:FindFirstChild("DevoGAG2") then CoreGui:FindFirstChild("DevoGAG2"):Destroy() end
    if CoreGui:FindFirstChild("DevoGAG2_Loading") then CoreGui:FindFirstChild("DevoGAG2_Loading"):Destroy() end
end)

local _connections = {}
local _running = true
local currentWeather = "Day"
local weatherDuration = 0
local weatherStartTime = tick()
local weatherConnected = false

-- Weather info table
local WeatherInfo = {
    Day =         {icon="☀️", color=Color3.fromRGB(255,220,80),  desc="Normal growth"},
    Night =       {icon="🌙", color=Color3.fromRGB(140,140,220), desc="Stealing active!"},
    Rain =        {icon="🌧️", color=Color3.fromRGB(100,180,255), desc="2x growth • Wet mutation"},
    Lightning =   {icon="⚡", color=Color3.fromRGB(255,255,80),  desc="Electric mutation (80x!)"},
    Rainbow =     {icon="🌈", color=Color3.fromRGB(255,130,255), desc="Rainbow mutation boosted"},
    Snowfall =    {icon="❄️", color=Color3.fromRGB(200,230,255), desc="Frozen mutation (5x)"},
    Starfall =    {icon="⭐", color=Color3.fromRGB(255,230,150), desc="Starstruck mutation"},
    BloodMoon =   {icon="🌑", color=Color3.fromRGB(220,60,60),   desc="Bloodlit mutation"},
    GoldMoon =    {icon="🌟", color=Color3.fromRGB(255,210,60),  desc="✦ GOLD SEEDS SPAWNING ✦"},
    RainbowMoon = {icon="🌈", color=Color3.fromRGB(100,255,200), desc="✦ RAINBOW SEEDS SPAWNING ✦"},
}

-- Weather name mapping
local WeatherMap = {}
for k,v in pairs(WeatherInfo) do
    WeatherMap[k:lower()] = k
    WeatherMap[k] = k
end
WeatherMap["thunderstorm"] = "Lightning"
WeatherMap["thunder"] = "Lightning"
WeatherMap["blizzard"] = "Snowfall"
WeatherMap["snow"] = "Snowfall"
WeatherMap["midas"] = "GoldMoon"
WeatherMap["gold"] = "GoldMoon"
WeatherMap["blood moon"] = "BloodMoon"
WeatherMap["gold moon"] = "GoldMoon"
WeatherMap["rainbow moon"] = "RainbowMoon"

-- ==========================================
-- Wrapper para safe sa Delta
-- ==========================================
local function safePcall(f)
    local ok, err = pcall(f)
    if not ok and _running then
        warn("[DevoGAG2] Error:", err)
    end
    return ok, err
end

local function safeFire(func, ...)
    local args = {...}
    safePcall(function()
        func(unpack(args))
    end)
end

-- ==========================================
// DELTA-COMPATIBLE UI
// ==========================================

-- Gumamit ng task.wait para hindi ma-block
task.spawn(function()
    task.wait(0.5) -- Give time for executor to initialize
    
    safePcall(function()
        -- Try CoreGui first, fallback to PlayerGui
        local parent = CoreGui
        local loadSuccess = false
        
        -- Show loading indicator
        local loadGui = Instance.new("ScreenGui")
        loadGui.Name = "DevoGAG2_Loading"
        loadGui.ResetOnSpawn = false
        loadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        loadGui.DisplayOrder = 9999
        
        -- Try to parent - Delta sometimes blocks CoreGui
        local parentSuccess, parentErr = pcall(function()
            loadGui.Parent = CoreGui
        end)
        
        if not parentSuccess then
            -- Fallback sa PlayerGui
            parentSuccess, parentErr = pcall(function()
                loadGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
                parent = LocalPlayer.PlayerGui
            end)
        end
        
        if not parentSuccess then
            -- Last resort: try to create without parent
            warn("[DevoGAG2] Cannot parent to CoreGui or PlayerGui!")
            return
        end
        
        -- Loading frame
        local loadFrame = Instance.new("Frame")
        loadFrame.Size = UDim2.new(0, 200, 0, 50)
        loadFrame.Position = UDim2.new(0.5, -100, 0.5, -25)
        loadFrame.BackgroundColor3 = Color3.fromRGB(14,14,20)
        loadFrame.BorderSizePixel = 0
        loadFrame.Active = true
        loadFrame.Parent = loadGui
        local lc = Instance.new("UICorner")
        lc.CornerRadius = UDim.new(0, 8)
        lc.Parent = loadFrame
        local ls = Instance.new("UIStroke")
        ls.Color = Color3.fromRGB(40,40,55)
        ls.Thickness = 1
        ls.Parent = loadFrame
        
        local loadText = Instance.new("TextLabel")
        loadText.Size = UDim2.new(1, -20, 1, 0)
        loadText.Position = UDim2.new(0, 10, 0, 0)
        loadText.BackgroundTransparency = 1
        loadText.Text = "⚡ Loading Devo GAG2..."
        loadText.TextColor3 = Color3.fromRGB(40,220,120)
        loadText.TextSize = 14
        loadText.Font = Enum.Font.GothamBold
        loadText.TextXAlignment = Enum.TextXAlignment.Center
        loadText.Parent = loadFrame
        
        task.wait(1)
        
        -- ==========================================
        // MAIN UI
        // ==========================================
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DevoGAG2"
        screenGui.ResetOnSpawn = false
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        screenGui.DisplayOrder = 999
        screenGui.Parent = parent
        
        -- Main container
        local main = Instance.new("Frame")
        main.Size = UDim2.new(0, 380, 0, 480)
        main.Position = UDim2.new(0.5, -190, 0.5, -240)
        main.BackgroundColor3 = Color3.fromRGB(14,14,20)
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        main.Active = true
        main.Visible = true
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,12); c.Parent=main
        local s = Instance.new("UIStroke"); s.Color=Color3.fromRGB(40,40,55); s.Thickness=1.5; s.Parent=main
        main.Parent = screenGui
        
        -- Shadow
        local sh = Instance.new("ImageLabel")
        sh.Name="Shadow"
        sh.Size=UDim2.new(1,40,1,40); sh.Position=UDim2.new(0,-20,0,24)
        sh.BackgroundTransparency=1; sh.ZIndex=-1
        sh.Image="rbxassetid://6015897843"; sh.ImageColor3=Color3.fromRGB(0,0,0)
        sh.ImageTransparency=0.6; sh.ScaleType=Enum.ScaleType.Slice
        sh.SliceCenter=Rect.new(49,49,450,450); sh.Parent=main
        
        -- Resize constraint
        local uisc = Instance.new("UISizeConstraint")
        uisc.MaxSize=Vector2.new(420,560); uisc.MinSize=Vector2.new(260,42); uisc.Parent=main
        
        -- Title bar
        local tb = Instance.new("Frame")
        tb.Size=UDim2.new(1,0,0,44); tb.BackgroundColor3=Color3.fromRGB(18,18,26)
        tb.BorderSizePixel=0; tb.Parent=main
        local tbcr = Instance.new("UICorner"); tbcr.CornerRadius=UDim.new(0,12); tbcr.Parent=tb
        local tbf = Instance.new("Frame")
        tbf.Size=UDim2.new(1,0,0,14); tbf.Position=UDim2.new(0,0,1,-14)
        tbf.BackgroundColor3=Color3.fromRGB(18,18,26); tbf.BorderSizePixel=0; tbf.Parent=tb
        
        -- Accent line
        local al = Instance.new("Frame")
        al.Size=UDim2.new(1,0,0,2); al.Position=UDim2.new(0,0,1,-2)
        al.BorderSizePixel=0; al.Parent=tb
        local alg = Instance.new("UIGradient")
        alg.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(40,220,120)),
            ColorSequenceKeypoint.new(0.5,Color3.fromRGB(40,180,240)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(160,100,255))})
        alg.Parent=al
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size=UDim2.new(1,-90,1,0); title.Position=UDim2.new(0,14,0,0)
        title.BackgroundTransparency=1; title.Text="⚡ Devo GAG2"
        title.TextColor3=Color3.fromRGB(240,240,250); title.TextSize=16
        title.Font=Enum.Font.GothamBold; title.TextXAlignment=Enum.TextXAlignment.Left
        title.Parent=tb
        
        -- Minimize btn
        local minBtn = Instance.new("TextButton")
        minBtn.Size=UDim2.new(0,30,0,30); minBtn.Position=UDim2.new(1,-72,0,7)
        minBtn.BackgroundColor3=Color3.fromRGB(45,45,60); minBtn.Text="−"
        minBtn.TextColor3=Color3.fromRGB(180,180,190); minBtn.TextSize=18
        minBtn.Font=Enum.Font.GothamBold; minBtn.BorderSizePixel=0; minBtn.Parent=tb
        local mc = Instance.new("UICorner"); mc.CornerRadius=UDim.new(0,8); mc.Parent=minBtn
        
        -- Close btn
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size=UDim2.new(0,30,0,30); closeBtn.Position=UDim2.new(1,-36,0,7)
        closeBtn.BackgroundColor3=Color3.fromRGB(200,40,40); closeBtn.Text="✕"
        closeBtn.TextColor3=Color3.fromRGB(255,255,255); closeBtn.TextSize=14
        closeBtn.Font=Enum.Font.GothamBold; closeBtn.BorderSizePixel=0; closeBtn.Parent=tb
        local cc = Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,8); cc.Parent=closeBtn
        
        -- Draggable
        local dragData = {drag=false, start=nil, pos=nil}
        local c1 = tb.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
                dragData.drag=true; dragData.start=i.Position; dragData.pos=main.Position
                local ch = i.Changed:Connect(function()
                    if i.UserInputState==Enum.UserInputState.End then dragData.drag=false end
                end)
                table.insert(_connections,ch)
            end
        end); table.insert(_connections,c1)
        local c2 = UserInputService.InputChanged:Connect(function(i)
            if dragData.drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
                local d = i.Position-dragData.start
                main.Position=UDim2.new(dragData.pos.X.Scale,dragData.pos.X.Offset+d.X,dragData.pos.Y.Scale,dragData.pos.Y.Offset+d.Y)
            end
        end); table.insert(_connections,c2)
        
        -- Minimize toggle
        local minimized = false
        minBtn.MouseButton1Click:Connect(function()
            minimized = not minimized
            for _,child in pairs(main:GetChildren()) do
                if child~=tb and child~=sh and not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UISizeConstraint") then
                    child.Visible = not minimized
                end
            end
            main.Size = minimized and UDim2.new(0,380,0,44) or UDim2.new(0,380,0,480)
            minBtn.Text = minimized and "+" or "−"
        end)
        
        -- Tab bar
        local tabBar = Instance.new("Frame")
        tabBar.Size=UDim2.new(1,0,0,38); tabBar.Position=UDim2.new(0,0,0,44)
        tabBar.BackgroundColor3=Color3.fromRGB(10,10,16); tabBar.BorderSizePixel=0; tabBar.ClipsDescendants=true
        tabBar.Parent=main
        
        local tabLayout = Instance.new("UIListLayout")
        tabLayout.FillDirection=Enum.FillDirection.Horizontal; tabLayout.SortOrder=Enum.SortOrder.LayoutOrder; tabLayout.Padding=UDim.new(0,2)
        tabLayout.Parent=tabBar
        
        -- Content scroll
        local content = Instance.new("ScrollingFrame")
        content.Name="Content"
        content.Size=UDim2.new(1,-16,1,-104); content.Position=UDim2.new(0,8,0,88)
        content.BackgroundTransparency=1; content.ScrollBarThickness=4
        content.ScrollBarImageColor3=Color3.fromRGB(40,220,120); content.BorderSizePixel=0
        content.AutomaticCanvasSize=Enum.AutomaticSize.Y; content.Parent=main
        
        -- Tab data
        local tabs = {"Main","Weather","Shop","Defense","Info"}
        local icons = {"🌱","🌤️","🏪","🛡️","ℹ️"}
        local activeTab = "Main"
        
        local function switchTab(name)
            activeTab = name
            for _,f in pairs(content:GetChildren()) do
                if f:IsA("Frame") then f.Visible=(f.Name==name) end
            end
            for _,btn in pairs(tabBar:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = Color3.fromRGB(10,10,16)
                    btn.TextColor3 = Color3.fromRGB(100,100,110)
                end
            end
            local btn = tabBar:FindFirstChild(name)
            if btn then btn.BackgroundColor3=Color3.fromRGB(28,28,38); btn.TextColor3=Color3.fromRGB(40,220,120) end
            content.CanvasPosition=Vector2.new(0,0)
        end
        
        for i,name in ipairs(tabs) do
            local btn = Instance.new("TextButton")
            btn.Name=name; btn.Size=UDim2.new(1/#tabs,-1,1,0); btn.LayoutOrder=i
            btn.BackgroundColor3=Color3.fromRGB(10,10,16); btn.Text=icons[i].." "..name
            btn.TextColor3=Color3.fromRGB(100,100,110); btn.TextSize=11
            btn.Font=Enum.Font.GothamSemibold; btn.BorderSizePixel=0; btn.TextTruncate=Enum.TextTruncate.AtEnd
            btn.Parent=tabBar
            if i==1 then btn.BackgroundColor3=Color3.fromRGB(28,28,38); btn.TextColor3=Color3.fromRGB(40,220,120) end
            btn.MouseButton1Click:Connect(function() switchTab(name) end)
        end
        
        -- ==========================================
        // TAB BUILDER HELPERS
        // ==========================================
        local ord = 0
        
        local function createLabel(text, color)
            ord=ord+1
            local r = Instance.new("Frame"); r.Size=UDim2.new(1,0,0,text=="" and 6 or 26)
            r.BackgroundTransparency=1; r.LayoutOrder=ord; r.Parent=content
            local l = Instance.new("TextLabel"); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1
            l.Text=text; l.TextColor3=color or Color3.fromRGB(180,180,180); l.TextSize=13
            l.Font=Enum.Font.Gotham; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
        end
        
        local function createToggle(name, desc, default)
            ord=ord+1
            local r = Instance.new("Frame"); r.Size=UDim2.new(1,0,0,52)
            r.BackgroundTransparency=1; r.LayoutOrder=ord
            r.Parent=content
            
            local l = Instance.new("TextLabel"); l.Size=UDim2.new(0.65,-5,0,22); l.Position=UDim2.new(0,0,0,4)
            l.BackgroundTransparency=1; l.Text=name; l.TextColor3=Color3.fromRGB(220,220,220)
            l.TextSize=14; l.Font=Enum.Font.GothamSemibold; l.TextXAlignment=Enum.TextXAlignment.Left; l.Parent=r
            
            local d = Instance.new("TextLabel"); d.Size=UDim2.new(0.65,-5,0,16); d.Position=UDim2.new(0,0,0,28)
            d.BackgroundTransparency=1; d.Text=desc; d.TextColor3=Color3.fromRGB(130,130,140)
            d.TextSize=11; d.Font=Enum.Font.Gotham; d.TextXAlignment=Enum.TextXAlignment.Left; d.Parent=r
            
            local tog = Instance.new("Frame")
            tog.Size=UDim2.new(0,52,0,26); tog.Position=UDim2.new(1,-60,0,13)
            tog.BackgroundColor3=default and Color3.fromRGB(40,220,120) or Color3.fromRGB(35,35,45)
            tog.BorderSizePixel=0; tog.Parent=r
            local tcr = Instance.new("UICorner"); tcr.CornerRadius=UDim.new(0,13); tcr.Parent=tog
            
            local tbtn = Instance.new("TextButton"); tbtn.Size=UDim2.new(1,0,1,0)
            tbtn.BackgroundTransparency=1; tbtn.Text=""; tbtn.Parent=tog
            
            local circle = Instance.new("Frame")
            circle.Size=UDim2.new(0,22,0,22); circle.Position=default and UDim2.new(1,-24,0,2) or UDim2.new(0,2,0,2)
            circle.BackgroundColor3=Color3.fromRGB(255,255,255); circle.BorderSizePixel=0; circle.Parent=tog
            local cir = Instance.new("UICorner"); cir.CornerRadius=UDim.new(0,11); cir.Parent=circle
            
            local state = default
            tbtn.MouseButton1Click:Connect(function()
                state = not state
                tog.BackgroundColor3 = state and Color3.fromRGB(40,220,120) or Color3.fromRGB(35,35,45)
                circle.Position = state and UDim2.new(1,-24,0,2) or UDim2.new(0,2,0,2)
            end)
            
            return function() return state end
        end
        
        -- ==========================================
        // BUILD TABS
        // ==========================================
        
        -- MAIN TAB
        local mt = Instance.new("Frame"); mt.Name="Main"; mt.Size=UDim2.new(1,0,0,0)
        mt.AutomaticSize=Enum.AutomaticSize.Y; mt.BackgroundTransparency=1; mt.Parent=content
        local mlo = Instance.new("UIListLayout"); mlo.SortOrder=Enum.SortOrder.LayoutOrder; mlo.Padding=UDim.new(0,4); mlo.Parent=mt
        local mlo2 = Instance.new("UIPadding"); mlo2.PaddingTop=UDim.new(0,6); mlo2.Parent=mt
        
        createLabel("=== AUTOMATION ===",Color3.fromRGB(40,220,120))
        local getCollect = createToggle("Auto-Collect Seeds","Golden, Rainbow, Bird, Packs",true)
        local getDefense = createToggle("Auto Defense","Attack thieves in your base",true)
        local getStay = createToggle("Auto Stay at Night","Return to base after dark",true)
        local getShop = createToggle("Shop Predictions","Track seed rotation timers",true)
        local getAFK = createToggle("Anti-AFK","Prevent idle kick",true)
        
        createLabel("",Color3.fromRGB(255,255,255))
        createLabel("=== STATUS ===",Color3.fromRGB(80,200,255))
        
        local status = Instance.new("TextLabel")
        status.Size=UDim2.new(1,0,0,22); status.BackgroundTransparency=1
        status.Text="✅ Initializing..."; status.TextColor3=Color3.fromRGB(180,180,180); status.TextSize=13
        status.Font=Enum.Font.GothamSemibold; status.TextXAlignment=Enum.TextXAlignment.Left
        status.LayoutOrder=ord+1; status.Parent=mt
        
        local stime = Instance.new("TextLabel")
        stime.Size=UDim2.new(1,0,0,18); stime.BackgroundTransparency=1
        stime.Text=""; stime.TextColor3=Color3.fromRGB(120,120,130); stime.TextSize=11
        stime.Font=Enum.Font.Gotham; stime.TextXAlignment=Enum.TextXAlignment.Left
        stime.LayoutOrder=ord+2; stime.Parent=mt
        
        -- WEATHER TAB
        local wt = Instance.new("Frame"); wt.Name="Weather"; wt.Size=UDim2.new(1,0,0,0)
        wt.AutomaticSize=Enum.AutomaticSize.Y; wt.BackgroundTransparency=1; wt.Visible=false; wt.Parent=content
        local wlo = Instance.new("UIListLayout"); wlo.SortOrder=Enum.SortOrder.LayoutOrder; wlo.Padding=UDim.new(0,5); wlo.Parent=wt
        local wp = Instance.new("UIPadding"); wp.PaddingTop=UDim.new(0,6); wp.Parent=wt
        
        -- Current weather card
        local wcard = Instance.new("Frame"); wcard.Size=UDim2.new(1,0,0,64)
        wcard.BackgroundColor3=Color3.fromRGB(30,30,45); wcard.BorderSizePixel=0; wcard.LayoutOrder=1; wcard.Parent=wt
        local wcc = Instance.new("UICorner"); wcc.CornerRadius=UDim.new(0,10); wcc.Parent=wcard
        local wcs = Instance.new("UIStroke"); wcs.Color=Color3.fromRGB(50,50,70); wcs.Thickness=1; wcs.Parent=wcard
        
        local wIcon = Instance.new("TextLabel")
        wIcon.Size=UDim2.new(0,54,1,0); wIcon.Position=UDim2.new(0,8,0,0); wIcon.BackgroundTransparency=1
        wIcon.Text="☀️"; wIcon.TextSize=30; wIcon.Font=Enum.Font.GothamBold; wIcon.Parent=wcard
        
        local wName = Instance.new("TextLabel")
        wName.Size=UDim2.new(0.5,-62,0,22); wName.Position=UDim2.new(0,62,0,6); wName.BackgroundTransparency=1
        wName.Text="Day"; wName.TextColor3=Color3.fromRGB(255,220,80); wName.TextSize=18
        wName.Font=Enum.Font.GothamBold; wName.TextXAlignment=Enum.TextXAlignment.Left; wName.Parent=wcard
        
        local wDesc = Instance.new("TextLabel")
        wDesc.Size=UDim2.new(0.5,-62,0,16); wDesc.Position=UDim2.new(0,62,0,32); wDesc.BackgroundTransparency=1
        wDesc.Text="Normal growth"; wDesc.TextColor3=Color3.fromRGB(160,160,170); wDesc.TextSize=12
        wDesc.Font=Enum.Font.Gotham; wDesc.TextXAlignment=Enum.TextXAlignment.Left; wDesc.Parent=wcard
        
        local wTimer = Instance.new("TextLabel")
        wTimer.Size=UDim2.new(0.4,0,0,28); wTimer.Position=UDim2.new(0.6,0,0,18); wTimer.BackgroundTransparency=1
        wTimer.Text="--:--"; wTimer.TextColor3=Color3.fromRGB(255,255,255); wTimer.TextSize=22
        wTimer.Font=Enum.Font.GothamBold; wTimer.TextXAlignment=Enum.TextXAlignment.Center; wTimer.Parent=wcard
        
        -- Next weather
        local wnext = Instance.new("Frame"); wnext.Size=UDim2.new(1,0,0,36)
        wnext.BackgroundColor3=Color3.fromRGB(22,22,34); wnext.BorderSizePixel=0; wnext.LayoutOrder=2; wnext.Parent=wt
        local wncr = Instance.new("UICorner"); wncr.CornerRadius=UDim.new(0,8); wncr.Parent=wnext
        
        local wnextL = Instance.new("TextLabel")
        wnextL.Size=UDim2.new(1,-16,1,0); wnextL.Position=UDim2.new(0,8,0,0); wnextL.BackgroundTransparency=1
        wnextL.Text="⏳ Next: --"; wnextL.TextColor3=Color3.fromRGB(180,200,240); wnextL.TextSize=13
        wnextL.Font=Enum.Font.GothamSemibold; wnextL.TextXAlignment=Enum.TextXAlignment.Left; wnextL.Parent=wnext
        
        -- Weather info
        createLabel("Weather probabilities:",Color3.fromRGB(100,200,255))
        local wprob = Instance.new("TextLabel")
        wprob.Size=UDim2.new(1,0,0,0); wprob.AutomaticSize=Enum.AutomaticSize.Y; wprob.BackgroundTransparency=1
        wprob.TextColor3=Color3.fromRGB(160,160,170); wprob.TextSize=12; wprob.Font=Enum.Font.Gotham
        wprob.TextXAlignment=Enum.TextXAlignment.Left; wprob.TextWrapped=true; wprob.LayoutOrder=ord+1
        wprob.Parent=wt
        
        -- SHOP TAB
        local stb = Instance.new("Frame"); stb.Name="Shop"; stb.Size=UDim2.new(1,0,0,0)
        stb.AutomaticSize=Enum.AutomaticSize.Y; stb.BackgroundTransparency=1; stb.Visible=false; stb.Parent=content
        local slo = Instance.new("UIListLayout"); slo.SortOrder=Enum.SortOrder.LayoutOrder; slo.Padding=UDim.new(0,3); slo.Parent=stb
        local sp = Instance.new("UIPadding"); sp.PaddingTop=UDim.new(0,6); sp.Parent=stb
        
        -- Restock header
        local rh = Instance.new("Frame"); rh.Size=UDim2.new(1,0,0,38)
        rh.BackgroundColor3=Color3.fromRGB(35,35,50); rh.BorderSizePixel=0; rh.LayoutOrder=1; rh.Parent=stb
        local rhc = Instance.new("UICorner"); rhc.CornerRadius=UDim.new(0,8); rhc.Parent=rh
        
        local rl = Instance.new("TextLabel")
        rl.Size=UDim2.new(1,-16,1,0); rl.Position=UDim2.new(0,8,0,0); rl.BackgroundTransparency=1
        rl.Text="🔄 Next Restock: --:--"; rl.TextColor3=Color3.fromRGB(255,210,80); rl.TextSize=14
        rl.Font=Enum.Font.GothamBold; rl.TextXAlignment=Enum.TextXAlignment.Left; rl.Parent=rh
        
        -- Seed data
        local seedData = {
            {n="🥕 Carrot",r="Common",c=5},{n="🍓 Strawberry",r="Common",c=5},{n="🔵 Blueberry",r="Common",c=5},
            {n="🌷 Tulip",r="Uncommon",c=10},{n="🍅 Tomato",r="Uncommon",c=10},{n="🍎 Apple",r="Uncommon",c=10},
            {n="🎋 Bamboo",r="Rare",c=20},{n="🌽 Corn",r="Rare",c=20},{n="🌵 Cactus",r="Rare",c=20},{n="🍍 Pineapple",r="Rare",c=20},
            {n="🍄 Mushroom",r="Epic",c=45},{n="🍌 Banana",r="Epic",c=45},{n="🍇 Grape",r="Epic",c=45},{n="🥥 Coconut",r="Epic",c=45},
            {n="🐉 Dragon Fruit",r="Legendary",c=90},{n="🌰 Acorn",r="Legendary",c=90},{n="🍒 Cherry",r="Legendary",c=90},
            {n="🕷️ Venus Flytrap",r="Mythic",c=180},{n="🔥 Dragon's Breath",r="Super",c=240},
        }
        local rCol = {Common=Color3.fromRGB(180,180,180),Uncommon=Color3.fromRGB(80,200,80),Rare=Color3.fromRGB(60,140,255),Epic=Color3.fromRGB(180,80,255),Legendary=Color3.fromRGB(255,180,40),Mythic=Color3.fromRGB(255,60,80),Super=Color3.fromRGB(0,255,255)}
        local rBG = {Common=Color3.fromRGB(38,38,48),Uncommon=Color3.fromRGB(28,48,28),Rare=Color3.fromRGB(23,33,58),Epic=Color3.fromRGB(43,23,58),Legendary=Color3.fromRGB(53,43,18),Mythic=Color3.fromRGB(53,18,23),Super=Color3.fromRGB(18,53,58)}
        
        local seedRows = {}
        local curR = ""
        for _,sd in ipairs(seedData) do
            if sd.r ~= curR then
                curR = sd.r; ord=ord+1
                local hr = Instance.new("Frame"); hr.Size=UDim2.new(1,0,0,20)
                hr.BackgroundTransparency=1; hr.LayoutOrder=ord; hr.Parent=stb
                local hl = Instance.new("TextLabel"); hl.Size=UDim2.new(1,0,1,0); hl.BackgroundTransparency=1
                hl.Text="▸ "..sd.r:upper(); hl.TextColor3=rCol[sd.r]; hl.TextSize=11; hl.Font=Enum.Font.GothamBold
                hl.TextXAlignment=Enum.TextXAlignment.Left; hl.Parent=hr
            end
            ord=ord+1
            local rw = Instance.new("Frame"); rw.Size=UDim2.new(1,0,0,26); rw.BackgroundColor3=rBG[sd.r] or Color3.fromRGB(40,40,50)
            rw.BorderSizePixel=0; rw.LayoutOrder=ord; rw.Parent=stb
            local rwc = Instance.new("UICorner"); rwc.CornerRadius=UDim.new(0,4); rwc.Parent=rw
            
            local nl = Instance.new("TextLabel"); nl.Size=UDim2.new(0.55,0,1,0); nl.Position=UDim2.new(0,8,0,0)
            nl.BackgroundTransparency=1; nl.Text=sd.n; nl.TextColor3=rCol[sd.r]; nl.TextSize=12
            nl.Font=Enum.Font.GothamSemibold; nl.TextXAlignment=Enum.TextXAlignment.Left; nl.Parent=rw
            
            local tl = Instance.new("TextLabel"); tl.Name="Timer"
            tl.Size=UDim2.new(0.42,0,1,0); tl.Position=UDim2.new(0.55,0,0,0); tl.BackgroundTransparency=1
            tl.Text="--:--"; tl.TextColor3=Color3.fromRGB(200,200,200); tl.TextSize=11
            tl.Font=Enum.Font.GothamSemibold; tl.TextXAlignment=Enum.TextXAlignment.Right; tl.Parent=rw
            
            seedRows[sd.n] = {timer=tl, cycle=sd.c, rarity=sd.r, row=rw}
        end
        
        -- DEFENSE TAB
        local dtb = Instance.new("Frame"); dtb.Name="Defense"; dtb.Size=UDim2.new(1,0,0,0)
        dtb.AutomaticSize=Enum.AutomaticSize.Y; dtb.BackgroundTransparency=1; dtb.Visible=false; dtb.Parent=content
        local dlo = Instance.new("UIListLayout"); dlo.SortOrder=Enum.SortOrder.LayoutOrder; dlo.Padding=UDim.new(0,4); dlo.Parent=dtb
        local dp = Instance.new("UIPadding"); dp.PaddingTop=UDim.new(0,6); dp.Parent=dtb
        
        createLabel("=== WEAPONS (Priority Order) ===",Color3.fromRGB(220,80,80))
        createLabel("✅ Shovel (Free)",Color3.fromRGB(150,255,150))
        createLabel("✅ Crowbar (Gear Shop)",Color3.fromRGB(150,255,150))
        createLabel("✅ Freeze Ray (749 Robux)",Color3.fromRGB(150,255,150))
        createLabel("✅ Power Hose (299 Robux)",Color3.fromRGB(150,255,150))
        createLabel("",Color3.fromRGB(255,255,255))
        createLabel("Auto-detects thieves in your garden",Color3.fromRGB(200,200,160))
        createLabel("and attacks with best available weapon.",Color3.fromRGB(200,200,160))
        
        -- INFO TAB
        local itb = Instance.new("Frame"); itb.Name="Info"; itb.Size=UDim2.new(1,0,0,0)
        itb.AutomaticSize=Enum.AutomaticSize.Y; itb.BackgroundTransparency=1; itb.Visible=false; itb.Parent=content
        local ilo = Instance.new("UIListLayout"); ilo.SortOrder=Enum.SortOrder.LayoutOrder; ilo.Padding=UDim.new(0,4); ilo.Parent=itb
        local ip = Instance.new("UIPadding"); ip.PaddingTop=UDim.new(0,6); ip.Parent=itb
        
        createLabel("=== DEVOGAG2 v3.0 ===",Color3.fromRGB(40,220,120))
        createLabel("Delta Executor Compatible Edition",Color3.fromRGB(160,160,170))
        createLabel("",Color3.fromRGB(255,255,255))
        createLabel("FEATURES:",Color3.fromRGB(255,210,100))
        createLabel("✅ Auto-Collect Event Seeds",Color3.fromRGB(150,255,150))
        createLabel("✅ 100% Accurate Weather (reads game remote)",Color3.fromRGB(150,255,150))
        createLabel("✅ Seed Shop Rotation Timer",Color3.fromRGB(150,255,150))
        createLabel("✅ Auto-Stay at Base Night",Color3.fromRGB(150,255,150))
        createLabel("✅ Auto Defense (4 weapons)",Color3.fromRGB(150,255,150))
        createLabel("✅ Premium Drag UI",Color3.fromRGB(150,255,150))
        
        -- ==========================================
        // WEATHER REMOTE CONNECTION
        // ==========================================
        
        local function UpdateWeatherUI()
            local info = WeatherInfo[currentWeather] or WeatherInfo.Day
            wIcon.Text = info.icon
            wName.Text = currentWeather
            wName.TextColor3 = info.color
            wDesc.Text = info.desc
            local remaining = math.max(0, weatherDuration - (tick() - weatherStartTime))
            wTimer.Text = string.format("%02d:%02d", math.floor(remaining/60), math.floor(remaining%60))
        end
        
        -- Connect to weather remote
        task.spawn(function()
            task.wait(0.5)
            safePcall(function()
                local ge = ReplicatedStorage:FindFirstChild("GameEvents")
                if ge then
                    local wr = ge:FindFirstChild("WeatherEventStarted")
                    if wr then
                        local conn = wr.OnClientEvent:Connect(function(eventName, lengthSec)
                            safePcall(function()
                                if type(eventName)~="string" then return end
                                local norm = WeatherMap[eventName:lower():gsub("%s+","")]
                                if not norm then
                                    for k,v in pairs(WeatherMap) do
                                        if eventName:lower():find(k:lower()) then norm=v; break end
                                    end
                                end
                                if not norm then norm = eventName end
                                local dur = (type(lengthSec)=="number" and lengthSec>0) and lengthSec or 120
                                currentWeather = norm
                                weatherDuration = dur
                                weatherStartTime = tick()
                                weatherConnected = true
                                UpdateWeatherUI()
                                if norm=="GoldMoon" then status.Text="🌟 GOLD MOON - Golden seeds spawning!"
                                elseif norm=="RainbowMoon" then status.Text="🌈 RAINBOW MOON - Rainbow seeds spawning!"
                                elseif norm=="Rainbow" then status.Text="🌈 RAINBOW - Rainbow mutation boosted!"
                                elseif norm=="Lightning" then status.Text="⚡ LIGHTNING - Electric mutation (80x)!"
                                elseif norm=="Snowfall" then status.Text="❄️ SNOWFALL - Frozen mutation (5x)!"
                                else status.Text="🌤️ Weather: "..norm end
                            end)
                        end)
                        table.insert(_connections, conn)
                        status.Text="✅ Weather system connected!"
                    else
                        status.Text="⚠️ Weather remote not found, using fallback"
                    end
                else
                    status.Text="⚠️ GameEvents not found, using fallback"
                end
            end)
        end)
        
        -- ==========================================
        // FEATURE IMPLEMENTATIONS
        // ==========================================
        
        local function FindSeeds()
            local s = {}
            for _,o in pairs(Workspace:GetDescendants()) do
                if (o:IsA("Part") or o:IsA("MeshPart") or o:IsA("Model")) then
                    local n = o.Name:lower()
                    local hit = (n:find("gold") or n:find("golden")) and (n:find("seed") or n:find("fruit"))
                        or (n:find("rainbow") and (n:find("seed") or n:find("fruit")))
                        or n:find("bird") or n:find("seed pack")
                    if hit and (o:FindFirstChildWhichIsA("ClickDetector") or o:FindFirstChild("TouchInterest") or o:FindFirstChild("ProximityPrompt")) then
                        table.insert(s,o)
                    end
                end
            end
            return s
        end
        
        local function CollectSeed(o)
            return safePcall(function()
                local t = o:FindFirstChildWhichIsA("TouchTransmitter")
                if t and RootPart then RootPart.CFrame=o.CFrame; return end
                local p = o:FindFirstChildWhichIsA("ProximityPrompt")
                if p then p.HoldDuration=0; fireproximityprompt(p,1,true); return end
                local d = o:FindFirstChildWhichIsA("ClickDetector")
                if d then fireclickdetector(d) end
            end)
        end
        
        local baseCache = nil; local baseTime = 0
        local function FindBase()
            if baseCache and os.time()-baseTime<20 then return baseCache end
            local n = LocalPlayer.Name; local d = LocalPlayer.DisplayName
            for _,o in pairs(Workspace:GetDescendants()) do
                if (o:IsA("Model") or o:IsA("Folder")) and not o:FindFirstChild("Humanoid") then
                    local is = false
                    if o.Name==n or o.Name==d then is=true end
                    if not is then safePcall(function()
                        local ow = o:FindFirstChild("Owner") or o:FindFirstChild("owner")
                        if ow and (tostring(ow.Value)==n or tostring(ow.Value)==d) then is=true end
                    end) end
                    if not is then
                        local ln = o.Name:lower()
                        if ln:find("garden") or ln:find("plot") or ln:find("base") then
                            for _,l in pairs(o:GetDescendants()) do
                                if (l:IsA("TextLabel") or l:IsA("TextButton")) and (l.Text:find(n) or l.Text:find(d)) then is=true; break end
                            end
                        end
                    end
                    if is then
                        local pos = o:IsA("Model") and o.PrimaryPart and o.PrimaryPart.Position
                            or (o:FindFirstChild("Base") or o:FindFirstChildWhichIsA("BasePart",true)) and (o:FindFirstChild("Base") or o:FindFirstChildWhichIsA("BasePart",true)).Position
                        if pos then baseCache=pos; baseTime=os.time(); return pos end
                    end
                end
            end
            return nil
        end
        
        local function GetThreats(pos)
            if not pos then return {} end
            local t={}
            for _,p in pairs(Players:GetPlayers()) do
                if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local d = (p.Character.HumanoidRootPart.Position-pos).Magnitude
                    if d<Config.DefenseRange then table.insert(t,p) end
                end
            end
            return t
        end
        
        local function Equip(wName)
            local bp = LocalPlayer.Backpack; if not bp then return nil end
            local wn = wName:lower()
            for _,i in pairs(bp:GetChildren()) do
                if i.Name:lower():find(wn) or wn:find(i.Name:lower()) then
                    LocalPlayer.Character.Humanoid:EquipTool(i); task.wait(0.2); return i
                end
            end
            return nil
        end
        
        local function Attack(thief, basePos)
            safePcall(function()
                if not thief.Character or not thief.Character:FindFirstChild("HumanoidRootPart") then return end
                local tr = thief.Character.HumanoidRootPart
                if basePos and (tr.Position-basePos).Magnitude>Config.DefenseRange then return end
                if RootPart then RootPart.CFrame=CFrame.lookAt(RootPart.Position,tr.Position) end
                for _,wn in ipairs(Config.DefenseWeapons) do
                    local w = Equip(wn)
                    if w then w:Activate(); task.wait(0.1); break end
                end
            end)
        end
        
        -- ==========================================
        // MAIN LOOP
        // ==========================================
        
        local function formatTime(sec)
            sec = math.max(0, math.floor(sec))
            return string.format("%02d:%02d", math.floor(sec/60), sec%60)
        end
        
        task.spawn(function()
            while _running and task.wait(1) do
                safePcall(function()
                    -- Fallback weather if remote not connected
                    if not weatherConnected then
                        local ct = Lighting.ClockTime or 12
                        local fb = "Day"
                        if ct<5.5 or ct>18.5 then
                            local amb = Lighting.Ambient or Color3.new()
                            if amb.R>0.35 and amb.G<0.06 and amb.B<0.06 then fb="BloodMoon"
                            elseif amb.R>0.35 and amb.G>0.25 and amb.B<0.06 then fb="GoldMoon"
                            elseif amb.R<0.2 and amb.G>0.2 and amb.B>0.35 then fb="RainbowMoon"
                            else fb="Night" end
                        else
                            for _,v in pairs(Workspace:GetDescendants()) do
                                if v:IsA("ParticleEmitter") and v.Enabled then
                                    local n = (v.Name.." "..(v.Parent and v.Parent.Name or "")):lower()
                                    if n:find("lightning") then fb="Lightning";break end
                                    if n:find("rain") and not n:find("bow") then fb="Rain";break end
                                    if n:find("snow") or n:find("blizzard") then fb="Snowfall";break end
                                    if n:find("starfall") then fb="Starfall";break end
                                    if n:find("rainbow") and not n:find("rain") then fb="Rainbow";break end
                                end
                            end
                        end
                        if fb ~= currentWeather then
                            currentWeather = fb
                            weatherDuration = (fb=="Night" or fb:find("Moon")) and 80 or 160
                            weatherStartTime = tick()
                            UpdateWeatherUI()
                        end
                    end
                    
                    UpdateWeatherUI()
                    
                    -- Next weather prediction
                    local ct = Lighting.ClockTime or 12
                    local isNight = ct<5.5 or ct>18.5
                    local nextW = isNight and "Day" or "Night"
                    local timeTo = isNight and ((ct>=18 and (24-ct+5.5) or (5.5-ct))*13.33) or ((18.5-ct)*13.33)
                    wnextL.Text = string.format("⏳ %s Next: %s (in %s)", isNight and "☀️" or "🌙", nextW, formatTime(timeTo))
                    wprob.Text = "🌧️ Rain 40% | ⚡ Lightning 12% | 🌈 Rainbow 8% | ❄️ Snowfall 15% | ⭐ Starfall 5%\n🌑 Blood Moon 2% | 🌟 Gold Moon 13% | 🌈 Rainbow Moon 4%"
                    
                    -- Auto-Collect
                    if getCollect() then
                        local seeds = FindSeeds()
                        if #seeds>0 and RootPart then
                            local orig = RootPart.CFrame
                            for _,s in ipairs(seeds) do
                                RootPart.CFrame = s.CFrame
                                task.wait(0.05); CollectSeed(s)
                                status.Text="🎯 Collected "..s.Name
                            end
                            task.wait(0.1); RootPart.CFrame = orig
                        end
                    end
                    
                    local basePos = FindBase()
                    
                    -- Auto Stay
                    local ct2 = Lighting.ClockTime or 12
                    local isNight2 = ct2<5.5 or ct2>18.5
                    if getStay() and isNight2 and basePos and RootPart then
                        local dist = Vector2.new(RootPart.Position.X,RootPart.Position.Z)-Vector2.new(basePos.X,basePos.Z)
                        if dist.Magnitude>40 then
                            RootPart.CFrame = CFrame.new(basePos+Vector3.new(0,3,0))
                            status.Text="🌙 Night - Returned to base"
                        end
                    end
                    
                    -- Auto Defense
                    if getDefense() then
                        local threats = GetThreats(basePos)
                        for _,t in ipairs(threats) do
                            Attack(t, basePos)
                            task.wait(Config.WeaponCooldown)
                        end
                    end
                    
                    -- Anti-AFK
                    if getAFK() then
                        safePcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
                    end
                    
                    -- Shop timers
                    if getShop() then
                        local now = os.time()
                        local restock = 300-(now%300)
                        rl.Text = string.format("🔄 Next Restock: %02d:%02d", math.floor(restock/60), restock%60)
                        for _,sr in pairs(seedRows) do
                            local cyc = sr.cycle*60; local nextT = cyc-(now%cyc)
                            if nextT<30 then
                                sr.timer.Text="⚡ SOON!"; sr.timer.TextColor3=Color3.fromRGB(255,220,80)
                                sr.row.BackgroundColor3=Color3.fromRGB(58,53,18)
                            else
                                sr.timer.Text=formatTime(nextT); sr.timer.TextColor3=Color3.fromRGB(200,200,200)
                                sr.row.BackgroundColor3=rBG[sr.rarity] or Color3.fromRGB(40,40,50)
                            end
                        end
                    end
                    
                    -- Status
                    local up = math.floor((tick()-weatherStartTime)/60)
                    stime.Text = "Uptime: "..up.."m | "..(weatherConnected and "🔵 Live" or "🟡 Fallback")
                    
                    if not status.Text:find("🎯") and not status.Text:find("🌙") and not status.Text:find("⚔️") and not status.Text:find("🌟") and not status.Text:find("🌈") and not status.Text:find("⚡") and not status.Text:find("❄️") and not status.Text:find("🌤️") then
                        status.Text = "✅ Active | "..currentWeather
                    end
                end)
            end
        end)
        
        -- Cleanup
        closeBtn.MouseButton1Click:Connect(function()
            _running=false
            for _,conn in ipairs(_connections) do
                pcall(function() conn:Disconnect() end)
            end
            _connections = {}
            pcall(function()
                if screenGui and screenGui.Parent then screenGui:Destroy() end
                if loadGui and loadGui.Parent then loadGui:Destroy() end
            end)
        end)
        
        -- Remove loading screen
        pcall(function() loadGui:Destroy() end)
        
        -- Chat notification
        safePcall(function()
            StarterGui:SetCore("ChatMakeSystemMessage", {
                Text="⚡ Devo GAG2 v3.0 loaded! Delta Compatible",
                Color=Color3.fromRGB(40,220,120), Font=Enum.Font.GothamBold, TextSize=16
            })
        end)
        
        print("⚡ Devo GAG2 v3.0 loaded! Delta Compatible")
        
        status.Text="✅ Script active | "..currentWeather
    end) -- end safePcall
end) -- end task.spawn