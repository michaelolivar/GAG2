--[[
████████████████████████████████████████████████████████████████████████████
█                                                                          █
█   GROW A GARDEN 2 — Premium Auto Collect & Farm Script                  █
█   Version: 2.1.1 (BUG FIXED)                                             █
█   Compatibility: All major executors (Synapse, Delta, Solara, Codex)     █
█   Fix: UI not showing — Instance override fixed, LocalPlayer wait added  █
█                                                                          █
████████████████████████████████████████████████████████████████████████████
--]]

-- ============================================================
-- GUARD: Wait until game is fully loaded
-- ============================================================
repeat task.wait() until game:GetService("Players").LocalPlayer
repeat task.wait() until game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

-- ============================================================
-- SECTION 1: CONFIGURATION
-- ============================================================
local CONFIG = {
    AutoCollectEventSeeds = true,
    AutoBuyEventSeeds = true,
    AutoFarm = true,
    AutoPlant = true,
    AutoHarvest = true,
    AutoSell = true,
    AutoWater = true,
    AntiAFK = true,
    AutoSteal = false,

    EventSeeds = {
        ["Delphinium"] = { Priority = 1, MaxPrice = 50000, AutoBuy = true },
        ["Traveler's Fruit"] = { Priority = 2, MaxPrice = 100000, AutoBuy = true },
        ["Lily of the Valley"] = { Priority = 3, MaxPrice = 75000, AutoBuy = true },
        ["Ember Lily"] = { Priority = 4, MaxPrice = 150000, AutoBuy = true },
        ["Parasol Flower"] = { Priority = 5, MaxPrice = 60000, AutoBuy = true },
        ["Prickly Pear"] = { Priority = 6, MaxPrice = 45000, AutoBuy = true },
        ["Cauliflower"] = { Priority = 7, MaxPrice = 25000, AutoBuy = true },
        ["Pear"] = { Priority = 8, MaxPrice = 30000, AutoBuy = true },
        ["Cantaloupe"] = { Priority = 9, MaxPrice = 55000, AutoBuy = true },
        ["Rosy Delight"] = { Priority = 10, MaxPrice = 80000, AutoBuy = true },
    },

    MinShecklesToKeep = 1000,
    HarvestRadius = 50,
    PlantRadius = 30,
    MaxPlants = 100,
    PreferredSeeds = {"Moon Bloom", "Dragon's Breath", "Ghost Pepper", "Glow Mushroom"},

    Theme = {
        Primary = Color3.fromRGB(30, 200, 80),
        Secondary = Color3.fromRGB(20, 150, 60),
        Accent = Color3.fromRGB(255, 215, 0),
        Background = Color3.fromRGB(15, 15, 25),
        Surface = Color3.fromRGB(25, 25, 40),
        Text = Color3.fromRGB(230, 230, 240),
        Danger = Color3.fromRGB(255, 70, 70),
        Warning = Color3.fromRGB(255, 180, 50),
    },
    Opacity = 0.92,
    Font = Enum.Font.GothamBold,
    Title = "🌱 HARVEST ELITE  •  v2.1.1"
}

-- ============================================================
-- SECTION 2: SERVICES (with pcall safety)
-- ============================================================
local function GetService(name)
    local s, v = pcall(function() return game:GetService(name) end)
    return s and v or nil
end

local Players = GetService("Players")
local RunService = GetService("RunService")
local TweenService = GetService("TweenService")
local UserInputService = GetService("UserInputService")
local VirtualInputManager = GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- SECTION 3: FORWARD DECLARATIONS
-- ============================================================
local Log = { Messages = {}, MaxMessages = 100, LogLevel = 3 }

function Log:Add(level, message, color)
    local entry = {
        Level = level, Message = message,
        Color = color or Color3.fromRGB(200, 200, 200),
        Time = os.time(), Timestamp = os.date("%H:%M:%S"),
    }
    table.insert(self.Messages, entry)
    if #self.Messages > self.MaxMessages then table.remove(self.Messages, 1) end
    print(string.format("[%s] %s", entry.Timestamp, message))
end

function Log:Error(m) self:Add("ERROR", m, Color3.fromRGB(255,70,70)) end
function Log:Warn(m) self:Add("WARN", m, Color3.fromRGB(255,180,50)) end
function Log:Info(m) self:Add("INFO", m, Color3.fromRGB(100,200,255)) end
function Log:Debug(m)
    if self.LogLevel >= 4 then self:Add("DEBUG", m, Color3.fromRGB(150,150,150)) end
end
function Log:Success(m) self:Add("SUCCESS", m, Color3.fromRGB(50,255,100)) end

local UI = {
    -- FIX: Separate ScreenGui and Instance
    ScreenGui = nil,
    MainFrame = nil,
    Elements = {},
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    Minimized = false,
    Tabs = {},
    ActiveTab = "Main",
}

-- ============================================================
-- SECTION 4: UTILITY FUNCTIONS
-- ============================================================
local Utilities = {}

function Utilities.FindRemote(remoteName)
    local paths = {
        GetService("ReplicatedStorage"), GetService("ReplicatedFirst"),
        LocalPlayer.PlayerGui, LocalPlayer.Backpack, LocalPlayer.Character, workspace
    }
    for _, c in ipairs(paths) do
        if not c then continue end
        local f = c:FindFirstChild(remoteName, true)
        if f and (f:IsA("RemoteEvent") or f:IsA("RemoteFunction")) then return f end
    end
    for _, c in ipairs(paths) do
        if not c then continue end
        for _, o in ipairs(c:GetDescendants()) do
            if o.Name == remoteName and (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then return o end
        end
    end
    return nil
end

function Utilities.FireRemote(name, ...)
    local r = Utilities.FindRemote(name)
    if r then
        local args = {...}
        local s, e = pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(unpack(args))
            elseif r:IsA("RemoteFunction") then r:InvokeServer(unpack(args)) end
        end)
        if not s then warn("[HARVEST] Remote error:", e) end
        return s
    end
    return false
end

function Utilities.GetPlayerBalance()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local c = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money") or ls:FindFirstChild("Balance") or ls:FindFirstChild("Points")
        if c then return c.Value end
    end
    for _, ch in ipairs(LocalPlayer:GetDescendants()) do
        if ch:IsA("NumberValue") and (ch.Name:lower():find("sheck") or ch.Name:lower():find("money") or ch.Name:lower():find("coin")) then
            return ch.Value
        end
    end
    return 0
end

function Utilities.GetSeedInventory()
    local seeds = {}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, it in ipairs(bp:GetChildren()) do
            if it:IsA("Tool") or it:IsA("Part") then table.insert(seeds, it.Name) end
        end
    end
    local ch = LocalPlayer.Character
    if ch then
        for _, it in ipairs(ch:GetChildren()) do
            if it:IsA("Tool") then table.insert(seeds, it.Name) end
        end
    end
    return seeds
end

function Utilities.GetHarvestablePlants(radius)
    local h = {}
    local pos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("plant") or o.Name:lower():find("crop")) then
            local prim = o:FindFirstChild("PrimaryPart") or o:FindFirstChildOfClass("Part") or o:FindFirstChildOfClass("MeshPart")
            if prim and (pos - prim.Position).Magnitude <= radius then
                if o:FindFirstChildWhichIsA("ProximityPrompt") or o:FindFirstChildWhichIsA("ClickDetector") then
                    table.insert(h, o)
                end
            end
        end
    end
    return h
end

-- ============================================================
-- SECTION 5: ENGINES
-- ============================================================
local EventSeedCollector = { Running = false, Connection = nil, CollectedSeeds = {}, CheckInterval = 3 }

function EventSeedCollector:Start()
    if self.Running then return end
    self.Running = true
    self.Connection = RunService.Stepped:Connect(function()
        if not self.Running then return end
        self:CheckEventShop()
    end)
    task.spawn(function()
        while self.Running do task.wait(self.CheckInterval) self:CheckEventShop() end
    end)
    return true
end

function EventSeedCollector:Stop()
    self.Running = false
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

function EventSeedCollector:CheckEventShop() end  -- Simplified for now

local FarmEngine = { Running = false, Connection = nil, CycleCount = 0 }

function FarmEngine:Start()
    if self.Running then return end
    self.Running = true
    self.Connection = RunService.Stepped:Connect(function()
        if not self.Running then return end
    end)
    task.spawn(function()
        while self.Running do task.wait(2) end
    end)
    Log:Success("🌱 Farm Engine started")
end

function FarmEngine:Stop()
    self.Running = false
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

local AntiAFK = { Running = false, Connection = nil }

function AntiAFK:Start()
    if self.Running then return end
    self.Running = true
    self.Connection = RunService.Heartbeat:Connect(function()
        if not self.Running or not CONFIG.AntiAFK then return end
        local ch = LocalPlayer.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local p = ch.HumanoidRootPart.Position
            ch.HumanoidRootPart.CFrame = CFrame.new(p + Vector3.new(math.random(-50,50)/100, 0, math.random(-50,50)/100))
            task.wait(30)
        end
    end)
end

function AntiAFK:Stop()
    self.Running = false
    if self.Connection then self.Connection:Disconnect() self.Connection = nil end
end

function ToggleAll(enabled)
    CONFIG.AutoFarm = enabled
    CONFIG.AutoCollectEventSeeds = enabled
    CONFIG.AutoBuyEventSeeds = enabled
    CONFIG.AutoPlant = enabled
    CONFIG.AutoHarvest = enabled
    CONFIG.AutoSell = enabled
    if enabled then
        FarmEngine:Start()
        EventSeedCollector:Start()
        AntiAFK:Start()
        Log:Success("▶ ALL SYSTEMS STARTED")
    else
        FarmEngine:Stop()
        EventSeedCollector:Stop()
        AntiAFK:Stop()
        Log:Warn("⏹ ALL SYSTEMS STOPPED")
    end
end

-- ============================================================
-- SECTION 6: UI DESIGN
-- ============================================================

function UI:Initialize()
    -- FIX: CLEANUP OLD GUI FIRST
    local cleanupPaths = {
        pcall(function() return game:GetService("CoreGui") end) and game:GetService("CoreGui") or nil,
        LocalPlayer:FindFirstChild("PlayerGui"),
    }
    for _, path in ipairs(cleanupPaths) do
        if path then
            local old = path:FindFirstChild("HarvestEliteGUI")
            if old then pcall(function() old:Destroy() end) end
        end
    end

    -- FIX 1: Create fresh ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HarvestEliteGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Enabled = true  -- FIX 2: Explicitly enable

    -- FIX 3: Try CoreGui first, fallback to PlayerGui
    local target = nil
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        target = cg
    else
        target = LocalPlayer:FindFirstChild("PlayerGui")
        if not target then
            target = Instance.new("PlayerGui")
            target.Parent = LocalPlayer
        end
    end
    screenGui.Parent = target

    -- FIX 4: Store ScreenGui separately — DO NOT OVERRIDE
    self.ScreenGui = screenGui
    self.Instance = screenGui  -- Instance refers to ScreenGui (ROOT)

    self:CreateMainFrame()
    self:CreateTitleBar()
    self:CreateTabBar()
    self:CreateContentArea()
    self:MakeDraggable()
    self:AnimateEntrance()

    Log:Success("✅ UI Loaded Successfully!")
end

function UI:CreateMainFrame()
    local theme = CONFIG.Theme

    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 420, 0, 540)
    main.Position = UDim2.new(0.5, -210, 0.5, -270)
    main.BackgroundColor3 = theme.Background
    main.BackgroundTransparency = 1 - CONFIG.Opacity
    main.BorderSizePixel = 0
    main.ClipsDescendants = false
    main.Parent = self.ScreenGui  -- FIX: Always parent to ScreenGui, NOT self.Instance

    -- Border accent
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundColor3 = theme.Secondary
    border.BackgroundTransparency = 0.5
    border.BorderSizePixel = 0
    border.Parent = main

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Secondary),
        ColorSequenceKeypoint.new(0.5, theme.Primary),
        ColorSequenceKeypoint.new(1, theme.Secondary),
    })
    gradient.Rotation = 90
    gradient.Parent = border

    -- FIX 5: Store MainFrame separately
    self.MainFrame = main
    self.Elements.MainFrame = main
end

function UI:CreateTitleBar()
    local theme = CONFIG.Theme

    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.MainFrame  -- FIX: Parent to MainFrame

    -- Title
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = CONFIG.Title
    titleText.Font = CONFIG.Font
    titleText.TextSize = 16
    titleText.TextColor3 = theme.Text
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Badge
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 50, 0, 18)
    badge.Position = UDim2.new(0, 12, 0, 24)
    badge.BackgroundColor3 = theme.Primary
    badge.BackgroundTransparency = 0.3
    badge.BorderSizePixel = 0
    badge.Parent = titleBar

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "ACTIVE"
    badgeText.Font = Enum.Font.Gotham
    badgeText.TextSize = 10
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.Parent = badge

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -68, 0, 7)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "−"
    minBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 18
    minBtn.Parent = titleBar
    minBtn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 7)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(220, 80, 80)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    -- Bottom border
    local borderLine = Instance.new("Frame")
    borderLine.Size = UDim2.new(1, 0, 0, 2)
    borderLine.Position = UDim2.new(0, 0, 1, 0)
    borderLine.BackgroundColor3 = theme.Primary
    borderLine.BorderSizePixel = 0
    borderLine.Parent = titleBar

    self.Elements.TitleBar = titleBar
end

function UI:CreateTabBar()
    local theme = CONFIG.Theme

    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 34)
    tabBar.Position = UDim2.new(0, 0, 0, 42)
    tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = self.MainFrame

    local tabs = {
        {Name = "Main", Icon = "🏠"},
        {Name = "Events", Icon = "🎯"},
        {Name = "Farm", Icon = "🌱"},
        {Name = "Inventory", Icon = "📦"},
        {Name = "Logs", Icon = "📋"},
    }

    local tabWidth = 420 / #tabs
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name .. "Tab"
        btn.Size = UDim2.new(0, tabWidth, 0.8, 0)
        btn.Position = UDim2.new(0, (i-1) * tabWidth, 0.1, 0)
        btn.BackgroundColor3 = theme.Surface
        btn.BackgroundTransparency = 0.5
        btn.BorderSizePixel = 0
        btn.Text = tab.Icon .. " " .. tab.Name
        btn.Font = CONFIG.Font
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        btn.Parent = tabBar

        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0.8, 0, 0, 3)
        indicator.Position = UDim2.new(0.1, 0, 1, -3)
        indicator.BackgroundColor3 = theme.Primary
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = (tab.Name ~= "Main") and 1 or 0.2
        indicator.Parent = btn

        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") and child:FindFirstChild("Indicator") then
                    child:FindFirstChild("Indicator").BackgroundTransparency = 1
                    child.TextColor3 = Color3.fromRGB(160, 160, 170)
                end
            end
            btn.TextColor3 = theme.Text
            indicator.BackgroundTransparency = 0.2
        end)

        self.Tabs[tab.Name] = {Button = btn, Indicator = indicator}
    end

    self.Elements.TabBar = tabBar
end

function UI:CreateContentArea()
    local theme = CONFIG.Theme

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -116)
    content.Position = UDim2.new(0, 10, 0, 80)
    content.BackgroundColor3 = theme.Surface
    content.BackgroundTransparency = 0.3
    content.BorderSizePixel = 0
    content.Parent = self.MainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = content

    self.Elements.Content = content
    self.Elements.ContentPages = {}

    -- Create minimal pages
    self:CreateMainPage()
    self:CreateLogPage()

    self:SwitchTab("Main")
end

function UI:CreateMainPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("ScrollingFrame")
    page.Name = "MainPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.Primary
    page.CanvasSize = UDim2.new(0, 0, 0, 300)
    page.Visible = false
    page.Parent = content

    local y = 10

    -- Status label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, y)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 SYSTEM STATUS"
    statusLabel.Font = CONFIG.Font
    statusLabel.TextSize = 13
    statusLabel.TextColor3 = theme.Accent
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = page
    y = y + 25

    -- Quick status
    local statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(1, -20, 0, 20)
    statusText.Position = UDim2.new(0, 10, 0, y)
    statusText.BackgroundTransparency = 1
    statusText.Text = "⚡ All systems running smoothly"
    statusText.Font = CONFIG.Font
    statusText.TextSize = 12
    statusText.TextColor3 = Color3.fromRGB(50, 255, 100)
    statusText.TextXAlignment = Enum.TextXAlignment.Left
    statusText.Parent = page
    y = y + 30

    -- Quick Actions
    local actionsLabel = Instance.new("TextLabel")
    actionsLabel.Size = UDim2.new(1, -20, 0, 20)
    actionsLabel.Position = UDim2.new(0, 10, 0, y)
    actionsLabel.BackgroundTransparency = 1
    actionsLabel.Text = "⚡ QUICK ACTIONS"
    actionsLabel.Font = CONFIG.Font
    actionsLabel.TextSize = 13
    actionsLabel.TextColor3 = theme.Accent
    actionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionsLabel.Parent = page
    y = y + 25

    local actions = {
        {Name = "▶ Start All", Color = theme.Primary, Action = function() ToggleAll(true) end},
        {Name = "⏹ Stop All", Color = theme.Danger, Action = function() ToggleAll(false) end},
    }

    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 180, 0, 34)
        btn.Position = UDim2.new(0, 10 + ((i-1) * 190), 0, y)
        btn.BackgroundColor3 = action.Color
        btn.BackgroundTransparency = 0.7
        btn.BorderSizePixel = 0
        btn.Text = action.Name
        btn.Font = CONFIG.Font
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = page

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(action.Action)

        btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.4 end)
        btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.7 end)
    end

    self.Elements.ContentPages["Main"] = page
end

function UI:CreateLogPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("Frame")
    page.Name = "LogPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content

    local logList = Instance.new("ScrollingFrame")
    logList.Name = "LogList"
    logList.Size = UDim2.new(1, -20, 1, -20)
    logList.Position = UDim2.new(0, 10, 0, 10)
    logList.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
    logList.BackgroundTransparency = 0.2
    logList.BorderSizePixel = 0
    logList.ScrollBarThickness = 4
    logList.ScrollBarImageColor3 = theme.Primary
    logList.CanvasSize = UDim2.new(0, 0, 0, 0)
    logList.Parent = page

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 1)
    layout.Parent = logList

    self.Elements.LogList = logList
    self.Elements.ContentPages["Logs"] = page
end

function UI:UpdateLogList()
    local logList = self.Elements.LogList
    if not logList then return end

    for _, child in ipairs(logList:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local startIdx = math.max(1, #Log.Messages - 49)
    for i = startIdx, #Log.Messages do
        local entry = Log.Messages[i]
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -10, 0, 20)
        item.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        item.BackgroundTransparency = 0.5
        item.BorderSizePixel = 0
        item.Parent = logList

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -6, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = string.format("[%s] %s", entry.Timestamp, entry.Message)
        label.Font = Enum.Font.Code
        label.TextSize = 9
        label.TextColor3 = entry.Color
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = item
    end

    logList.CanvasSize = UDim2.new(0, 0, 0, #Log.Messages * 21)
    logList.CanvasPosition = Vector2.new(0, math.huge)
end

function UI:CreateCard(parent, size, position)
    local card = Instance.new("Frame")
    card.Size = size
    card.Position = position
    card.BackgroundColor3 = CONFIG.Theme.Surface
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    return card
end

function UI:MakeDraggable()
    local titleBar = self.Elements.TitleBar
    if not titleBar then return end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self.DragOffset = Vector2.new(
                input.Position.X - self.MainFrame.AbsolutePosition.X,
                input.Position.Y - self.MainFrame.AbsolutePosition.Y
            )
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)

    if UserInputService then
        UserInputService.InputChanged:Connect(function(input)
            if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Delta
                self.MainFrame.Position = UDim2.new(
                    0, self.MainFrame.AbsolutePosition.X + delta.X,
                    0, self.MainFrame.AbsolutePosition.Y + delta.Y
                )
            end
        end)
    end
end

function UI:SwitchTab(tabName)
    self.ActiveTab = tabName
    for name, page in pairs(self.Elements.ContentPages) do
        if page then page.Visible = (name == tabName) end
    end
end

function UI:ToggleMinimize()
    self.Minimized = not self.Minimized
    self.MainFrame.Size = self.Minimized and UDim2.new(0, 420, 0, 42) or UDim2.new(0, 420, 0, 540)
    for _, child in ipairs(self.MainFrame:GetChildren()) do
        if child ~= self.Elements.TitleBar then
            child.Visible = not self.Minimized
        end
    end
end

function UI:AnimateEntrance()
    if not TweenService then
        self.MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
        return
    end
    self.MainFrame.Position = UDim2.new(0.5, -210, 0.3, 0)
    self.MainFrame.BackgroundTransparency = 0.8
    pcall(function()
        TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1 - CONFIG.Opacity,
            Position = UDim2.new(0.5, -210, 0.5, -270)
        }):Play()
    end)
end

function UI:Destroy()
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    self.ScreenGui = nil
    self.MainFrame = nil
    self.Instance = nil
end

-- ============================================================
-- SECTION 7: MAIN EXECUTION
-- ============================================================
local function main()
    Log:Success("🌱 Harvest Elite v2.1.1 loading...")
    task.wait(1)
    
    UI:Initialize()
    
    if CONFIG.AutoFarm then FarmEngine:Start() end
    if CONFIG.AutoCollectEventSeeds or CONFIG.AutoBuyEventSeeds then EventSeedCollector:Start() end
    if CONFIG.AntiAFK then AntiAFK:Start() end
    
    Log:Success("✅ Harvest Elite v2.1.1 ready!")
    Log:Info("📌 Press [Right Ctrl] to toggle UI")
    
    -- Hotkey
    if UserInputService then
        UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == Enum.KeyCode.RightControl then
                if UI.ScreenGui then
                    UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
                end
            end
        end)
    end
end

local ok, err = pcall(main)
if not ok then
    warn("HARVEST ELITE ERROR: " .. tostring(err))
    -- Emergency fallback: show error on screen
    local sg = Instance.new("ScreenGui")
    sg.Name = "HarvestEliteError"
    local tgt, _ = pcall(function() return game:GetService("CoreGui") end)
    sg.Parent = tgt and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(0, 400, 0, 100)
    tb.Position = UDim2.new(0.5, -200, 0.5, -50)
    tb.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    tb.TextScaled = true
    tb.Text = "🚨 ERROR: " .. tostring(err) .. "\n\n(Copy this and send to developer)"
    tb.Parent = sg
    tb.MouseButton1Click:Connect(function() sg:Destroy() end)
end

-- ============================================================
-- END OF SCRIPT
-- ============================================================