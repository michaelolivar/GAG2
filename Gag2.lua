--[[
╔══════════════════════════════════════════════════════════════╗
║             GROW A GARDEN 2 - Devo                           ║
║              bebe Ed sheeran                                 ║
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

-- Cleanup: destroy old UI if script is re-run
if CoreGui:FindFirstChild("DevoGag2") then
    CoreGui:FindFirstChild("DevoGag2"):Destroy()
end

-- Track all connections for cleanup
local _connections = {}
local _scriptRunning = true

-- UI Library
local Library = Instance.new("ScreenGui")
Library.Name = "DevoGag2"
Library.Parent = CoreGui
Library.ResetOnSpawn = false
Library.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proper draggable: moves MainFrame from title bar drag
local function MakeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragStart, startPos
    
    local c1 = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    table.insert(_connections, c1)
    
    local c2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(_connections, c2)
end

-- ==========================================
-- BUILD UI - Professional Dark Mode
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.9, 0, 0.85, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(400, 520)
sizeConstraint.MinSize = Vector2.new(280, 42)
sizeConstraint.Parent = MainFrame
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Parent = Library

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = MainFrame

-- Subtle border stroke
local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 60)
mainStroke.Thickness = 1.5
mainStroke.Parent = MainFrame

-- Drop shadow (outer glow)
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0.5, 0, 0.5, 4)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = -1
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
shadow.Parent = MainFrame

-- Title Bar with gradient
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

-- Bottom corner fill (so only top corners are rounded)
local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 12)
titleFill.Position = UDim2.new(0, 0, 1, -12)
titleFill.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
titleFill.BorderSizePixel = 0
titleFill.Parent = TitleBar

-- Accent line under title bar
local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, 0, 0, 2)
accentLine.Position = UDim2.new(0, 0, 1, -2)
accentLine.BorderSizePixel = 0
accentLine.Parent = TitleBar

local accentGradient = Instance.new("UIGradient")
accentGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 200, 120)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 160, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 80, 255))
})
accentGradient.Parent = accentLine

-- Title text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌱 Devo GAG2 by:bebe Ed⁠"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -68, 0, 7)
MinBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(180, 180, 190)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = TitleBar
local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = MinBtn

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -35, 0, 7)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = CloseBtn

-- Minimize toggle
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    ContentFrame = MainFrame:FindFirstChild("ContentScroll") -- re-reference
    for _, child in pairs(MainFrame:GetChildren()) do
        if child.Name ~= "TitleBar" and child.Name ~= "Shadow" and not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UISizeConstraint") then
            child.Visible = not isMinimized
        end
    end
    MainFrame.Size = isMinimized and UDim2.new(0.9, 0, 0, 42) or UDim2.new(0.9, 0, 0.85, 0)
    MinBtn.Text = isMinimized and "+" or "—"
end)

-- Make draggable via title bar (moves MainFrame)
MakeDraggable(TitleBar, MainFrame)

-- Tab system
local TabContainer = Instance.new("Frame")
TabContainer.Name = "TabContainer"
TabContainer.Size = UDim2.new(1, 0, 0, 36)
TabContainer.Position = UDim2.new(0, 0, 0, 44)
TabContainer.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
TabContainer.BorderSizePixel = 0
TabContainer.ClipsDescendants = true
TabContainer.Parent = MainFrame

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Padding = UDim.new(0, 1)
TabLayout.Parent = TabContainer

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name = "ContentScroll"
ContentFrame.Size = UDim2.new(1, -20, 1, -100)
ContentFrame.Position = UDim2.new(0, 10, 0, 84)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 4
ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(40, 200, 120)
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.BorderSizePixel = 0
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
            btn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
            btn.TextColor3 = Color3.fromRGB(120, 120, 130)
        end
    end
    local tabBtn = TabContainer:FindFirstChild(tabName)
    if tabBtn then
        tabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        tabBtn.TextColor3 = Color3.fromRGB(40, 200, 120)
    end
    
    -- Try to update canvas if function exists (it gets defined later)
    pcall(function()
        if UpdateCanvas then UpdateCanvas() end
    end)
    
    -- Reset scroll position to top when switching tabs
    ContentFrame.CanvasPosition = Vector2.new(0, 0)
end

for i, tabName in ipairs(TabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName
    tabBtn.Size = UDim2.new(1 / #TabNames, -1, 1, 0)
    tabBtn.LayoutOrder = i
    tabBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 20)
    tabBtn.Text = TabIcons[i] .. " " .. tabName
    tabBtn.TextColor3 = Color3.fromRGB(120, 120, 130)
    tabBtn.TextSize = 11
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.BorderSizePixel = 0
    tabBtn.TextTruncate = Enum.TextTruncate.AtEnd
    tabBtn.Parent = TabContainer
    
    if i == 1 then
        tabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
        tabBtn.TextColor3 = Color3.fromRGB(40, 200, 120)
    end
    
    tabBtn.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

-- Helper: Create toggle row
local toggleOrder = 0
local function CreateToggle(tab, name, desc, default)
    toggleOrder = toggleOrder + 1
    local row = Instance.new("Frame")
    row.Name = "Toggle_" .. toggleOrder
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundTransparency = 1
    row.LayoutOrder = toggleOrder
    row.Parent = tab
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -5, 0, 22)
    label.Position = UDim2.new(0, 0, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, -5, 0, 16)
    descLabel.Position = UDim2.new(0, 0, 0, 28)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    descLabel.TextSize = 11
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = row
    
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 50, 0, 24)
    toggle.Position = UDim2.new(1, -55, 0, 13)
    toggle.BackgroundColor3 = default and Color3.fromRGB(40, 200, 120) or Color3.fromRGB(35, 35, 45)
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
        toggle.BackgroundColor3 = toggled and Color3.fromRGB(40, 200, 120) or Color3.fromRGB(35, 35, 45)
        circle:TweenPosition(UDim2.new(toggled and 1 or 0, toggled and -22 or 2, 0, 2), "Out", "Quad", 0.15, true)
    end)
    
    return toggleBtn, function() return toggled end
end

-- Helper: Create label row
local labelOrder = 0
local function CreateLabel(tab, text, color)
    labelOrder = labelOrder + 1
    local row = Instance.new("Frame")
    row.Name = "Label_" .. labelOrder
    row.Size = UDim2.new(1, 0, 0, (text == "") and 8 or 24)
    row.BackgroundTransparency = 1
    row.LayoutOrder = labelOrder
    row.Parent = tab
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(180, 180, 180)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row
    
    return label
end

-- ==========================================
-- TAB: MAIN
-- ==========================================
local MainTab = Instance.new("Frame")
MainTab.Name = "Main"
MainTab.Size = UDim2.new(1, 0, 0, 0)
MainTab.AutomaticSize = Enum.AutomaticSize.Y
MainTab.BackgroundTransparency = 1
MainTab.Parent = ContentFrame

local MainLayout = Instance.new("UIListLayout")
MainLayout.SortOrder = Enum.SortOrder.LayoutOrder
MainLayout.Padding = UDim.new(0, 4)
MainLayout.Parent = MainTab

CreateLabel(MainTab, "=== AUTOMATION CONTROLS ===", Color3.fromRGB(40, 180, 80))

local _, getAutoCollect = CreateToggle(MainTab, "Auto-Collect Events", "Collect Golden, Rainbow, Bird, & Packs", true)
local function getWeatherNotif() return true end
local _, getShopNotif = CreateToggle(MainTab, "Shop Predictions", "Track seed shop rotations", true)

CreateLabel(MainTab, "=== DEFENSE CONTROLS ===", Color3.fromRGB(200, 80, 80))

local _, getAutoDefense = CreateToggle(MainTab, "Auto Defense", "Auto-attack thieves in your base", true)
local _, getAutoStay = CreateToggle(MainTab, "Auto Stay at Base", "Return to base at night", true)

local StatusLabelTitle = CreateLabel(MainTab, "=== STATUS ===", Color3.fromRGB(80, 180, 255))
StatusLabelTitle.LayoutOrder = 100

local StatusLabel = CreateLabel(MainTab, "Script Active | Waiting...", Color3.fromRGB(180, 180, 180))
StatusLabel.Parent.LayoutOrder = 101

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
            local layout = child:FindFirstChildWhichIsA("UIListLayout")
            if layout then
                totalH = math.max(totalH, layout.AbsoluteContentSize.Y)
            else
                for _, row in pairs(child:GetChildren()) do
                    if row:IsA("Frame") then
                        totalH = totalH + row.Size.Y.Offset + 5
                    end
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
DefenseTab.Size = UDim2.new(1, 0, 0, 0)
DefenseTab.AutomaticSize = Enum.AutomaticSize.Y
DefenseTab.BackgroundTransparency = 1
DefenseTab.Visible = false
DefenseTab.Parent = ContentFrame

local DefenseLayout = Instance.new("UIListLayout")
DefenseLayout.SortOrder = Enum.SortOrder.LayoutOrder
DefenseLayout.Padding = UDim.new(0, 4)
DefenseLayout.Parent = DefenseTab

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
ShopTab.Size = UDim2.new(1, 0, 0, 0)
ShopTab.AutomaticSize = Enum.AutomaticSize.Y
ShopTab.BackgroundTransparency = 1
ShopTab.Visible = false
ShopTab.Parent = ContentFrame

local ShopLayout = Instance.new("UIListLayout")
ShopLayout.SortOrder = Enum.SortOrder.LayoutOrder
ShopLayout.Padding = UDim.new(0, 3)
ShopLayout.Parent = ShopTab

-- Restock timer header
labelOrder = labelOrder + 1
local RestockHeader = Instance.new("Frame")
RestockHeader.Name = "RestockHeader"
RestockHeader.Size = UDim2.new(1, 0, 0, 36)
RestockHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
RestockHeader.BorderSizePixel = 0
RestockHeader.LayoutOrder = labelOrder
RestockHeader.Parent = ShopTab
local rhCorner = Instance.new("UICorner")
rhCorner.CornerRadius = UDim.new(0, 6)
rhCorner.Parent = RestockHeader

local ShopPredictLabel = Instance.new("TextLabel")
ShopPredictLabel.Size = UDim2.new(1, -16, 1, 0)
ShopPredictLabel.Position = UDim2.new(0, 8, 0, 0)
ShopPredictLabel.BackgroundTransparency = 1
ShopPredictLabel.Text = "🔄 Next Restock: --:--"
ShopPredictLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
ShopPredictLabel.TextSize = 14
ShopPredictLabel.Font = Enum.Font.GothamBold
ShopPredictLabel.TextXAlignment = Enum.TextXAlignment.Left
ShopPredictLabel.Parent = RestockHeader

-- Seed data: {name, emoji, rarity, restockMinutes (estimated avg cycle)}
local SeedData = {
    -- Common (always available, restock every 5 min)
    {name = "Carrot", emoji = "🥕", rarity = "Common", cycle = 5},
    {name = "Strawberry", emoji = "🍓", rarity = "Common", cycle = 5},
    {name = "Blueberry", emoji = "🔵", rarity = "Common", cycle = 5},
    -- Uncommon (restock ~10 min)
    {name = "Tulip", emoji = "🌷", rarity = "Uncommon", cycle = 10},
    {name = "Tomato", emoji = "🍅", rarity = "Uncommon", cycle = 10},
    {name = "Apple", emoji = "🍎", rarity = "Uncommon", cycle = 10},
    -- Rare (restock ~20 min)
    {name = "Bamboo", emoji = "🎋", rarity = "Rare", cycle = 20},
    {name = "Corn", emoji = "🌽", rarity = "Rare", cycle = 20},
    {name = "Cactus", emoji = "🌵", rarity = "Rare", cycle = 20},
    {name = "Pineapple", emoji = "🍍", rarity = "Rare", cycle = 20},
    -- Epic (restock ~45 min)
    {name = "Mushroom", emoji = "🍄", rarity = "Epic", cycle = 45},
    {name = "Banana", emoji = "🍌", rarity = "Epic", cycle = 45},
    {name = "Grape", emoji = "🍇", rarity = "Epic", cycle = 45},
    {name = "Coconut", emoji = "🥥", rarity = "Epic", cycle = 45},
    {name = "Mango", emoji = "🍋", rarity = "Epic", cycle = 45},
    {name = "Green Bean", emoji = "🌿", rarity = "Epic", cycle = 45},
    -- Legendary (restock ~90 min)
    {name = "Dragon Fruit", emoji = "🐉", rarity = "Legendary", cycle = 90},
    {name = "Acorn", emoji = "🌰", rarity = "Legendary", cycle = 90},
    {name = "Cherry", emoji = "🍒", rarity = "Legendary", cycle = 90},
    {name = "Sunflower", emoji = "🌻", rarity = "Legendary", cycle = 90},
    -- Mythic (restock ~180 min)
    {name = "Venus Flytrap", emoji = "🕷️", rarity = "Mythic", cycle = 180},
    {name = "Pomegranate", emoji = "🔴", rarity = "Mythic", cycle = 180},
    -- Super (restock ~240 min)
    {name = "Moon Bloom", emoji = "💮", rarity = "Super", cycle = 240},
    {name = "Dragon's Breath", emoji = "🔥", rarity = "Super", cycle = 240},
}

-- Rarity colors
local RarityColors = {
    Common = Color3.fromRGB(180, 180, 180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare = Color3.fromRGB(60, 140, 255),
    Epic = Color3.fromRGB(180, 80, 255),
    Legendary = Color3.fromRGB(255, 180, 40),
    Mythic = Color3.fromRGB(255, 60, 80),
    Super = Color3.fromRGB(0, 255, 255),
}

local RarityBG = {
    Common = Color3.fromRGB(40, 40, 50),
    Uncommon = Color3.fromRGB(30, 50, 30),
    Rare = Color3.fromRGB(25, 35, 60),
    Epic = Color3.fromRGB(45, 25, 60),
    Legendary = Color3.fromRGB(55, 45, 20),
    Mythic = Color3.fromRGB(55, 20, 25),
    Super = Color3.fromRGB(20, 55, 60),
}

-- Create seed rows
local seedTimerLabels = {}
local currentRarity = ""

for i, seed in ipairs(SeedData) do
    -- Add rarity header when rarity changes
    if seed.rarity ~= currentRarity then
        currentRarity = seed.rarity
        labelOrder = labelOrder + 1
        local header = Instance.new("Frame")
        header.Name = "Header_" .. seed.rarity
        header.Size = UDim2.new(1, 0, 0, 22)
        header.BackgroundTransparency = 1
        header.LayoutOrder = labelOrder
        header.Parent = ShopTab
        
        local headerLabel = Instance.new("TextLabel")
        headerLabel.Size = UDim2.new(1, 0, 1, 0)
        headerLabel.BackgroundTransparency = 1
        headerLabel.Text = "▸ " .. seed.rarity:upper()
        headerLabel.TextColor3 = RarityColors[seed.rarity]
        headerLabel.TextSize = 12
        headerLabel.Font = Enum.Font.GothamBold
        headerLabel.TextXAlignment = Enum.TextXAlignment.Left
        headerLabel.Parent = header
    end
    
    labelOrder = labelOrder + 1
    local row = Instance.new("Frame")
    row.Name = "Seed_" .. seed.name
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = RarityBG[seed.rarity]
    row.BorderSizePixel = 0
    row.LayoutOrder = labelOrder
    row.Parent = ShopTab
    
    local rowCorner = Instance.new("UICorner")
    rowCorner.CornerRadius = UDim.new(0, 4)
    rowCorner.Parent = row
    
    -- Emoji + Name
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 8, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = seed.emoji .. " " .. seed.name
    nameLabel.TextColor3 = RarityColors[seed.rarity]
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row
    
    -- Timer label
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(0.42, 0, 1, 0)
    timerLabel.Position = UDim2.new(0.55, 0, 0, 0)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "In --:--"
    timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    timerLabel.TextSize = 11
    timerLabel.Font = Enum.Font.GothamSemibold
    timerLabel.TextXAlignment = Enum.TextXAlignment.Right
    timerLabel.Parent = row
    
    seedTimerLabels[i] = {label = timerLabel, data = seed, row = row}
end

-- ==========================================
-- TAB: WEATHER
-- ==========================================
local WeatherTab = Instance.new("Frame")
WeatherTab.Name = "Weather"
WeatherTab.Size = UDim2.new(1, 0, 0, 0)
WeatherTab.AutomaticSize = Enum.AutomaticSize.Y
WeatherTab.BackgroundTransparency = 1
WeatherTab.Visible = false
WeatherTab.Parent = ContentFrame

local WeatherLayout = Instance.new("UIListLayout")
WeatherLayout.SortOrder = Enum.SortOrder.LayoutOrder
WeatherLayout.Padding = UDim.new(0, 6)
WeatherLayout.Parent = WeatherTab

-- Current weather display
labelOrder = labelOrder + 1
local CurrentWeatherRow = Instance.new("Frame")
CurrentWeatherRow.Name = "CurrentWeather"
CurrentWeatherRow.Size = UDim2.new(1, 0, 0, 40)
CurrentWeatherRow.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
CurrentWeatherRow.BorderSizePixel = 0
CurrentWeatherRow.LayoutOrder = labelOrder
CurrentWeatherRow.Parent = WeatherTab
local cwCorner = Instance.new("UICorner")
cwCorner.CornerRadius = UDim.new(0, 6)
cwCorner.Parent = CurrentWeatherRow

local WeatherLabel = Instance.new("TextLabel")
WeatherLabel.Size = UDim2.new(0.6, 0, 1, 0)
WeatherLabel.Position = UDim2.new(0, 10, 0, 0)
WeatherLabel.BackgroundTransparency = 1
WeatherLabel.Text = "Current: ☀️ Day"
WeatherLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
WeatherLabel.TextSize = 14
WeatherLabel.Font = Enum.Font.GothamBold
WeatherLabel.TextXAlignment = Enum.TextXAlignment.Left
WeatherLabel.Parent = CurrentWeatherRow

local WeatherTimerLabel = Instance.new("TextLabel")
WeatherTimerLabel.Size = UDim2.new(0.4, -10, 1, 0)
WeatherTimerLabel.Position = UDim2.new(0.6, 0, 0, 0)
WeatherTimerLabel.BackgroundTransparency = 1
WeatherTimerLabel.Text = "--:--"
WeatherTimerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
WeatherTimerLabel.TextSize = 13
WeatherTimerLabel.Font = Enum.Font.GothamSemibold
WeatherTimerLabel.TextXAlignment = Enum.TextXAlignment.Right
WeatherTimerLabel.Parent = CurrentWeatherRow

-- Next Weather display
labelOrder = labelOrder + 1
local NextWeatherRow = Instance.new("Frame")
NextWeatherRow.Name = "NextWeather"
NextWeatherRow.Size = UDim2.new(1, 0, 0, 28)
NextWeatherRow.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
NextWeatherRow.BorderSizePixel = 0
NextWeatherRow.LayoutOrder = labelOrder
NextWeatherRow.Parent = WeatherTab

local nwCorner = Instance.new("UICorner")
nwCorner.CornerRadius = UDim.new(0, 6)
nwCorner.Parent = NextWeatherRow

local NextWeatherLabel = Instance.new("TextLabel")
NextWeatherLabel.Size = UDim2.new(1, -20, 1, 0)
NextWeatherLabel.Position = UDim2.new(0, 10, 0, 0)
NextWeatherLabel.BackgroundTransparency = 1
NextWeatherLabel.Text = "Next: ⏳ Calculating..."
NextWeatherLabel.TextColor3 = Color3.fromRGB(200, 255, 200)
NextWeatherLabel.TextSize = 12
NextWeatherLabel.Font = Enum.Font.GothamSemibold
NextWeatherLabel.TextXAlignment = Enum.TextXAlignment.Left
NextWeatherLabel.Parent = NextWeatherRow

-- Weather card builder
local weatherCardLabels = {}

local function CreateWeatherCard(parent, weatherName, icon, order)
    local card = Instance.new("Frame")
    card.Name = "Card_" .. weatherName
    card.Size = UDim2.new(0.48, 0, 0, 70)
    card.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.Parent = parent
    
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card
    
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = Color3.fromRGB(80, 130, 200)
    cardStroke.Thickness = 1.5
    cardStroke.Parent = card
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 0, 28)
    iconLabel.Position = UDim2.new(0, 0, 0, 4)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = icon
    iconLabel.TextSize = 22
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconLabel.Parent = card
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 16)
    nameLabel.Position = UDim2.new(0, 0, 0, 30)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = weatherName
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Parent = card
    
    local timerLabel = Instance.new("TextLabel")
    timerLabel.Name = "Timer"
    timerLabel.Size = UDim2.new(1, 0, 0, 16)
    timerLabel.Position = UDim2.new(0, 0, 0, 48)
    timerLabel.BackgroundTransparency = 1
    timerLabel.Text = "In --:--"
    timerLabel.TextSize = 11
    timerLabel.Font = Enum.Font.GothamSemibold
    timerLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    timerLabel.Parent = card
    
    weatherCardLabels[weatherName] = timerLabel
    return card
end

-- Row 1: Day cycle
labelOrder = labelOrder + 1
local Row1 = Instance.new("Frame")
Row1.Name = "Row1"
Row1.Size = UDim2.new(1, 0, 0, 70)
Row1.BackgroundTransparency = 1
Row1.LayoutOrder = labelOrder
Row1.Parent = WeatherTab

CreateWeatherCard(Row1, "Day", "☀️", 1).Position = UDim2.new(0, 0, 0, 0)
CreateWeatherCard(Row1, "Moon", "🌙", 2).Position = UDim2.new(0.52, 0, 0, 0)

-- Row 2: Special moons
labelOrder = labelOrder + 1
local Row2 = Instance.new("Frame")
Row2.Name = "Row2"
Row2.Size = UDim2.new(1, 0, 0, 70)
Row2.BackgroundTransparency = 1
Row2.LayoutOrder = labelOrder
Row2.Parent = WeatherTab

CreateWeatherCard(Row2, "Goldmoon", "🌟", 1).Position = UDim2.new(0, 0, 0, 0)
CreateWeatherCard(Row2, "Bloodmoon", "🌑", 2).Position = UDim2.new(0.52, 0, 0, 0)

-- Row 3: Rainbow Moon + Rain
labelOrder = labelOrder + 1
local Row3 = Instance.new("Frame")
Row3.Name = "Row3"
Row3.Size = UDim2.new(1, 0, 0, 70)
Row3.BackgroundTransparency = 1
Row3.LayoutOrder = labelOrder
Row3.Parent = WeatherTab

CreateWeatherCard(Row3, "Rainbow Moon", "🌈", 1).Position = UDim2.new(0, 0, 0, 0)
CreateWeatherCard(Row3, "Rain", "🌧️", 2).Position = UDim2.new(0.52, 0, 0, 0)

-- Row 4: Lightning + Snowfall
labelOrder = labelOrder + 1
local Row4 = Instance.new("Frame")
Row4.Name = "Row4"
Row4.Size = UDim2.new(1, 0, 0, 70)
Row4.BackgroundTransparency = 1
Row4.LayoutOrder = labelOrder
Row4.Parent = WeatherTab

CreateWeatherCard(Row4, "Lightning", "⚡", 1).Position = UDim2.new(0, 0, 0, 0)
CreateWeatherCard(Row4, "Snowfall", "❄️", 2).Position = UDim2.new(0.52, 0, 0, 0)

-- Row 5: Rainbow + Starfall
labelOrder = labelOrder + 1
local Row5 = Instance.new("Frame")
Row5.Name = "Row5"
Row5.Size = UDim2.new(1, 0, 0, 70)
Row5.BackgroundTransparency = 1
Row5.LayoutOrder = labelOrder
Row5.Parent = WeatherTab

CreateWeatherCard(Row5, "Rainbow", "🌈", 1).Position = UDim2.new(0, 0, 0, 0)
CreateWeatherCard(Row5, "Starfall", "⭐", 2).Position = UDim2.new(0.52, 0, 0, 0)

-- ==========================================
-- TAB: INFO
-- ==========================================
local InfoTab = Instance.new("Frame")
InfoTab.Name = "Info"
InfoTab.Size = UDim2.new(1, 0, 0, 0)
InfoTab.AutomaticSize = Enum.AutomaticSize.Y
InfoTab.BackgroundTransparency = 1
InfoTab.Visible = false
InfoTab.Parent = ContentFrame

local InfoLayout = Instance.new("UIListLayout")
InfoLayout.SortOrder = Enum.SortOrder.LayoutOrder
InfoLayout.Padding = UDim.new(0, 4)
InfoLayout.Parent = InfoTab

CreateLabel(InfoTab, "=== GROW A GARDEN 2 by: Devo ===", Color3.fromRGB(40, 180, 80))
CreateLabel(InfoTab, "bebe Ed sheeran", Color3.fromRGB(180, 180, 180))
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

-- End of Info Tab

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

-- Accurate GAG2 weather cycle timings
local currentWeather = "Day"
local weatherStartTime = tick()

-- Accurate durations based on actual GAG2 data
local weatherDurations = {
    Day = 160,         -- 2m 40s
    Night = 80,        -- 1m 20s
    Rain = 120,        -- 2min
    Lightning = 120,   -- 2min
    Rainbow = 120,     -- 2min
    Snowfall = 120,    -- 2min
    Starfall = 120,    -- 2min
    BloodMoon = 80,    -- 1m 20s
    GoldMoon = 80,     -- 1m 20s
    RainbowMoon = 80,  -- 1m 20s
}

-- Full day-night cycle dynamically updated
local FULL_CYCLE = 160 + 80

local weatherIcons = {
    Day = "☀️",
    Night = "🌙",
    Rain = "🌧️",
    Lightning = "⚡",
    Rainbow = "🌈",
    Snowfall = "❄️",
    Starfall = "⭐",
    BloodMoon = "🌑",
    GoldMoon = "🌟",
    RainbowMoon = "🌈"
}

-- Try to read weather directly from the game's dedicated weather system
local function ReadGameWeather()
    local result = nil
    
    -- Method 1: Check Workspace attributes (most reliable if game uses them)
    pcall(function()
        for _, attrName in ipairs({"Weather", "CurrentWeather", "GameWeather", "WeatherType"}) do
            local val = Workspace:GetAttribute(attrName)
            if val and tostring(val) ~= "" then result = tostring(val) return end
        end
    end)
    if result then return result end
    
    -- Method 2: Check ReplicatedStorage for weather values
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        -- Look for a dedicated weather folder/value
        local weatherObj = rs:FindFirstChild("Weather") or rs:FindFirstChild("GameWeather") or rs:FindFirstChild("WeatherSystem")
        if weatherObj then
            if weatherObj:IsA("StringValue") then
                result = weatherObj.Value
            elseif weatherObj:IsA("Folder") or weatherObj:IsA("Configuration") then
                local cur = weatherObj:FindFirstChild("Current") or weatherObj:FindFirstChild("Type") or weatherObj:FindFirstChild("State")
                if cur and cur:IsA("StringValue") then
                    result = cur.Value
                end
            end
            local val = weatherObj:GetAttribute("Current") or weatherObj:GetAttribute("Type")
            if val then result = tostring(val) end
        end
    end)
    if result and result ~= "" then return result end
    
    -- Method 3: Check Lighting attributes
    pcall(function()
        for _, attrName in ipairs({"Weather", "CurrentWeather", "WeatherType"}) do
            local val = Lighting:GetAttribute(attrName)
            if val and tostring(val) ~= "" then result = tostring(val) return end
        end
    end)
    if result then return result end
    
    return nil
end

-- Try to read explicit NEXT weather from the game
local function ReadNextWeather()
    local result = nil
    pcall(function()
        for _, attrName in ipairs({"NextWeather", "UpcomingWeather", "NextEvent"}) do
            local val = Workspace:GetAttribute(attrName) or Lighting:GetAttribute(attrName)
            if val and tostring(val) ~= "" then result = tostring(val) return end
        end
    end)
    if result then return result end
    
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local weatherObj = rs:FindFirstChild("Weather") or rs:FindFirstChild("GameWeather") or rs:FindFirstChild("WeatherSystem")
        if weatherObj then
            local nextObj = weatherObj:FindFirstChild("Next") or weatherObj:FindFirstChild("Upcoming")
            if nextObj and nextObj:IsA("StringValue") then
                result = nextObj.Value
            end
            local val = weatherObj:GetAttribute("Next") or weatherObj:GetAttribute("Upcoming")
            if val then result = tostring(val) end
        end
    end)
    return result
end

-- Map game text to our weather names (strict matching)
local function NormalizeWeatherName(text)
    if not text then return nil end
    local t = text:lower():gsub("%s+", "")
    -- Exact/strict matches only
    if t == "bloodmoon" or t == "blood_moon" or t == "blood moon" then return "BloodMoon" end
    if t == "goldmoon" or t == "gold_moon" or t == "gold moon" or t == "midas" then return "GoldMoon" end
    if t == "rainbowmoon" or t == "rainbow_moon" or t == "rainbow moon" then return "RainbowMoon" end
    if t == "lightning" or t == "thunder" or t == "thunderstorm" then return "Lightning" end
    if t == "rainbow" then return "Rainbow" end
    if t == "rain" or t == "rainy" then return "Rain" end
    if t == "snowfall" or t == "snow" or t == "blizzard" then return "Snowfall" end
    if t == "starfall" then return "Starfall" end
    if t == "night" or t == "moon" or t == "nighttime" then return "Night" end
    if t == "day" or t == "daytime" or t == "morning" or t == "sunny" then return "Day" end
    return nil
end

-- Detect weather using ClockTime as primary, with conservative fallbacks
local function DetectWeather()
    -- Priority 1: Read from game's own weather data (attributes/values)
    local gameText = ReadGameWeather()
    local fromGame = NormalizeWeatherName(gameText)
    if fromGame then return fromGame end
    
    -- Priority 2: Use Lighting.ClockTime for day/night cycle (always reliable)
    local clockTime = Lighting.ClockTime or 12
    
    -- Determine base phase from clock
    local isNight = (clockTime < 6 or clockTime >= 18)
    
    -- Priority 3: Only check for active weather PARTICLES (not just any named object)
    -- Only ParticleEmitters that are Enabled count as active weather
    local activeWeatherEffect = nil
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") and v.Enabled then
                local name = v.Name:lower()
                local parentName = v.Parent and v.Parent.Name:lower() or ""
                local combined = name .. " " .. parentName
                -- Only match very specific weather effect names
                if combined:find("thundereffect") or combined:find("lightningeffect") or combined:find("lightningbolt") then
                    activeWeatherEffect = "Lightning"
                    break
                elseif combined:find("raineffect") or combined:find("raindrop") or combined:find("rainparticle") then
                    if not combined:find("rainbow") then
                        activeWeatherEffect = "Rain"
                        break
                    end
                elseif combined:find("snoweffect") or combined:find("snowflake") or combined:find("snowparticle") or combined:find("blizzard") then
                    activeWeatherEffect = "Snowfall"
                    break
                elseif combined:find("starfalleffect") or combined:find("fallingstar") then
                    activeWeatherEffect = "Starfall"
                    break
                elseif combined:find("rainboweffect") or combined:find("rainbowarc") then
                    if not combined:find("moon") then
                        activeWeatherEffect = "Rainbow"
                        break
                    end
                end
            end
        end
    end)
    
    -- If we found an active weather particle effect, trust it
    if activeWeatherEffect then return activeWeatherEffect end
    
    -- Night phase: check for special moons using Ambient color
    if isNight then
        local ambient = Lighting.Ambient or Color3.new(0, 0, 0)
        -- Blood moon: strong red, no green/blue
        if ambient.R > 0.4 and ambient.G < 0.08 and ambient.B < 0.08 then
            return "BloodMoon"
        end
        -- Gold moon: strong gold/yellow, low blue
        if ambient.R > 0.4 and ambient.G > 0.3 and ambient.B < 0.08 then
            return "GoldMoon"
        end
        -- Default night (don't guess RainbowMoon from colors - too unreliable)
        return "Night"
    end
    
    -- Default: Day (don't guess weather from fog/brightness - too unreliable)
    return "Day"
end

-- Dynamic Clock Speed Tracker for perfect sync
local dynamicClockData = {
    lastClockTime = Lighting.ClockTime or 12,
    lastTick = tick(),
    secPerDayHour = 160 / 12.0,  -- 13.33s per in-game hour
    secPerNightHour = 80 / 12.0, -- 6.66s per in-game hour
}

local function UpdateClockSpeed()
    local currentClockTime = Lighting.ClockTime or 12
    local currentTick = tick()
    local dt = currentTick - dynamicClockData.lastTick
    
    if dt >= 1.0 then
        local dClock = currentClockTime - dynamicClockData.lastClockTime
        if dClock < -12 then dClock = dClock + 24 end
        if dClock > 12 then dClock = dClock - 24 end
        
        if dClock > 0 and dClock < 2 then
            local hoursPerSec = dClock / dt
            if hoursPerSec > 0 then
                local secPerHour = 1 / hoursPerSec
                if secPerHour > 2 and secPerHour < 100 then
                    if currentClockTime >= 6 and currentClockTime < 18 then
                        dynamicClockData.secPerDayHour = dynamicClockData.secPerDayHour * 0.8 + secPerHour * 0.2
                    else
                        dynamicClockData.secPerNightHour = dynamicClockData.secPerNightHour * 0.8 + secPerHour * 0.2
                    end
                end
            end
        end
        dynamicClockData.lastClockTime = currentClockTime
        dynamicClockData.lastTick = currentTick
        
        weatherDurations.Day = math.floor(dynamicClockData.secPerDayHour * 12)
        weatherDurations.Night = math.floor(dynamicClockData.secPerNightHour * 12)
        weatherDurations.BloodMoon = weatherDurations.Night
        weatherDurations.GoldMoon = weatherDurations.Night
        weatherDurations.RainbowMoon = weatherDurations.Night
    end
end

-- Calculate time until next occurrence of each weather phase accurately using ClockTime
local function GetCycleTimeRemaining()
    local clockTime = Lighting.ClockTime or 12
    
    local timeToMoon, timeToDay
    local SEC_PER_DAY_HOUR = dynamicClockData.secPerDayHour
    local SEC_PER_NIGHT_HOUR = dynamicClockData.secPerNightHour
    
    if clockTime >= 6 and clockTime < 18 then
        local hoursLeftDay = 18 - clockTime
        timeToMoon = hoursLeftDay * SEC_PER_DAY_HOUR
        timeToDay = timeToMoon + (12 * SEC_PER_NIGHT_HOUR)
    else
        local hoursLeftNight = (clockTime >= 18) and (24 - clockTime + 6) or (6 - clockTime)
        timeToDay = hoursLeftNight * SEC_PER_NIGHT_HOUR
        timeToMoon = timeToDay + (12 * SEC_PER_DAY_HOUR)
    end
    
    return timeToMoon, timeToDay
end

-- Find event drops (Golden/Rainbow Seeds, Birds, Seed Packs) by scanning for pickable objects
local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local isTarget = false
            
            -- Golden seed check
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then
                isTarget = true
            -- Rainbow seed check
            elseif (name:find("rainbow") or name:find("rain")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then
                isTarget = true
            -- Bird check
            elseif name:find("bird") or name:find("crow") or name:find("pigeon") then
                isTarget = true
            -- Seed Pack check
            elseif name:find("seed pack") or (name:find("seed") and name:find("pack")) then
                isTarget = true
            end
            
            if isTarget then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    table.insert(seeds, obj)
                end
            end
        end
    end
    return seeds
end

-- Collect seed (simulate click/interact) - Ultra Fast Edition
local function CollectSeed(seedObj)
    pcall(function()
        -- 1. Try TouchInterest (Fastest)
        local touch = seedObj:FindFirstChildWhichIsA("TouchTransmitter")
        if touch then
            if firetouchinterest and RootPart then
                firetouchinterest(RootPart, seedObj, 0)
                task.wait()
                firetouchinterest(RootPart, seedObj, 1)
            else
                RootPart.CFrame = seedObj.CFrame
            end
            return true
        end
        
        -- 2. Try ProximityPrompt
        local prompt = seedObj:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            pcall(function() prompt.HoldDuration = 0 end)
            if fireproximityprompt then
                fireproximityprompt(prompt, 1, true)
            else
                prompt:InputHoldBegin()
                task.wait()
                prompt:InputHoldEnd()
            end
            return true
        end
        
        -- 3. Try ClickDetector
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector")
        if detector and fireclickdetector then
            fireclickdetector(detector)
            return true
        end
        
        -- 4. Try RemoteEvents directly
        for _, remote in pairs(seedObj:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
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

-- Find base/garden plot position
local myBasePosCache = nil
local function FindMyBasePos()
    if myBasePosCache then return myBasePosCache end
    
    local playerName = LocalPlayer.Name
    local display = LocalPlayer.DisplayName
    local userId = tostring(LocalPlayer.UserId)
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("Folder") then
            local isMyBase = false
            local name = obj.Name
            local lowerName = name:lower()
            
            if lowerName:find("garden") or lowerName:find("plot") or lowerName:find("base") or lowerName:find("tycoon") or lowerName:find("land") then
                if lowerName:find(playerName:lower()) or lowerName:find(display:lower()) then
                    isMyBase = true
                end
                
                if obj:GetAttribute("Owner") == playerName or obj:GetAttribute("Owner") == display or tostring(obj:GetAttribute("Owner")) == userId then 
                    isMyBase = true 
                end
                
                for _, valName in ipairs({"Owner", "Player", "PlayerName", "owner"}) do
                    local ownerVal = obj:FindFirstChild(valName)
                    if ownerVal then
                        local val = tostring(ownerVal.Value)
                        if val == playerName or val == display or val == userId then
                            isMyBase = true
                        elseif ownerVal:IsA("ObjectValue") and ownerVal.Value == LocalPlayer then
                            isMyBase = true
                        end
                    end
                end
                
                if not isMyBase then
                    for _, label in ipairs(obj:GetDescendants()) do
                        if label:IsA("TextLabel") or label:IsA("TextButton") or label:IsA("SurfaceGui") or label:IsA("BillboardGui") then
                            local text = label:IsA("TextLabel") and label.Text or label:IsA("TextButton") and label.Text or label.Name
                            if text:find(playerName) or text:find(display) then
                                isMyBase = true
                                break
                            end
                        end
                    end
                end
                
                if isMyBase then
                    local pos = nil
                    if obj:IsA("Model") and obj.PrimaryPart then 
                        pos = obj.PrimaryPart.Position 
                    else
                        local part = obj:FindFirstChild("Base") or obj:FindFirstChild("Floor") or obj:FindFirstChildWhichIsA("BasePart", true)
                        if part then pos = part.Position end
                    end
                    if pos then
                        myBasePosCache = pos
                        return pos
                    end
                end
            end
        end
    end
    return nil
end

-- Find thieves in base area
local function FindThreatsInBase(basePos)
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
local function AttackThief(thief, basePos)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    
    local targetRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Prevent chasing outside the base
    if basePos then
        local distFromBase = (targetRoot.Position - basePos).Magnitude
        if distFromBase > Config.DefenseRange then
            return -- Thief is outside garden, do not chase!
        end
    end
    
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
                if RootPart then
                    local targetDest = targetRoot.CFrame * CFrame.new(0, 0, 3)
                    -- Ensure destination is still inside base
                    if basePos and (targetDest.Position - basePos).Magnitude > Config.DefenseRange then
                        -- Don't teleport out! Just stay put and attack
                        RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
                    else
                        RootPart.CFrame = targetDest
                    end
                end
                weapon:Activate()
            end
            
            StatusLabel.Text = "⚔️ Attacking " .. thief.Name .. " with " .. weaponName
            break
        end
    end
end

-- ==========================================
-- MAIN LOOP & EVENT SNATCHER
-- ==========================================

-- Instant Event Snatcher: Beats other scripters by catching events the millisecond they spawn
Workspace.DescendantAdded:Connect(function(obj)
    if not _scriptRunning or not getAutoCollect() then return end
    
    task.spawn(function()
        task.wait(0.1) -- allow children to load
        if not obj or not obj.Parent then return end
        
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local isTarget = false
            
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then isTarget = true
            elseif (name:find("rainbow") or name:find("rain")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then isTarget = true
            elseif name:find("bird") or name:find("crow") or name:find("pigeon") then isTarget = true
            elseif name:find("seed pack") or (name:find("seed") and name:find("pack")) then isTarget = true
            end
            
            if isTarget and RootPart then
                -- Must have an interaction object
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    local originalPos = RootPart.CFrame
                    RootPart.CFrame = obj.CFrame
                    task.wait(0.05)
                    CollectSeed(obj)
                    if StatusLabel then StatusLabel.Text = "⚡ Instantly Snatched " .. obj.Name end
                    task.wait(0.1)
                    RootPart.CFrame = originalPos
                end
            end
        end
    end)
end)

-- Helper: format seconds to "H:MM:SS" or "MM:SS" string
local function FormatTime(seconds)
    seconds = math.max(0, math.floor(seconds))
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("In %d:%02d:%02d", h, m, s)
    else
        return string.format("In %02d:%02d", m, s)
    end
end

local function MainLoop()
    while _scriptRunning and task.wait(1) do
        local success, err = pcall(function()
            UpdateClockSpeed()
            
            -- 1. Auto-Collect Event Seeds
            if getAutoCollect() then
                local seeds = FindEventSeeds()
                if #seeds > 0 and RootPart then
                    local originalPos = RootPart.CFrame
                    for _, seed in ipairs(seeds) do
                        -- Instant teleport to bypass distance checks
                        RootPart.CFrame = seed.CFrame
                        task.wait(0.05)
                        CollectSeed(seed)
                        StatusLabel.Text = "🎯 Collected " .. seed.Name
                    end
                    task.wait(0.1)
                    RootPart.CFrame = originalPos
                end
            end
            
            -- 2. Weather Detection & Prediction
            if getWeatherNotif() then
                local detectedWeather = DetectWeather()
                
                if detectedWeather ~= currentWeather then
                    currentWeather = detectedWeather
                    weatherStartTime = tick()
                    local icon = weatherIcons[currentWeather] or "❓"
                    WeatherLabel.Text = "Current: " .. icon .. " " .. currentWeather
                    
                    StatusLabel.Text = "🌤️ Weather changed: " .. currentWeather
                    
                    if currentWeather == "Rainbow" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                        StatusLabel.Text = "⭐ EVENT WEATHER: " .. currentWeather .. " - Seeds may spawn!"
                    end
                end
                
                -- Update current weather remaining timer
                local duration = weatherDurations[currentWeather] or 120
                local elapsed = tick() - weatherStartTime
                local remaining = math.max(0, duration - elapsed)
                local mins = math.floor(remaining / 60)
                local secs = math.floor(remaining % 60)
                WeatherTimerLabel.Text = string.format("%02d:%02d left", mins, secs)
                
                -- Update weather card countdown timers
                local timeToMoon, timeToDay = GetCycleTimeRemaining()
                
                local currentClockTime = Lighting.ClockTime or 12
                local nextWeatherName = "Day"
                local nextWeatherTime = timeToDay
                
                if currentClockTime >= 6 and currentClockTime < 18 then
                    nextWeatherName = "Night"
                    nextWeatherTime = timeToMoon
                else
                    nextWeatherName = "Day"
                    nextWeatherTime = timeToDay
                end
                
                local explicitNext = ReadNextWeather()
                if explicitNext then
                    local normalized = NormalizeWeatherName(explicitNext)
                    if normalized then
                        nextWeatherName = normalized
                    end
                end
                
                if NextWeatherLabel then
                    local nIcon = weatherIcons[nextWeatherName] or "❓"
                    NextWeatherLabel.Text = string.format("Next: %s %s (%s)", nIcon, nextWeatherName, FormatTime(nextWeatherTime))
                end
                
                -- Day card
                if weatherCardLabels["Day"] then
                    if currentWeather == "Day" then
                        weatherCardLabels["Day"].Text = "NOW!"
                    else
                        weatherCardLabels["Day"].Text = FormatTime(timeToDay)
                    end
                end
                
                -- Moon (Night) card
                if weatherCardLabels["Moon"] then
                    if currentWeather == "Night" or currentWeather == "BloodMoon" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                        weatherCardLabels["Moon"].Text = "NOW!"
                    else
                        weatherCardLabels["Moon"].Text = FormatTime(timeToMoon)
                    end
                end
                
                -- Gold Moon card (next cycle + night with 13% chance)
                if weatherCardLabels["Goldmoon"] then
                    if currentWeather == "GoldMoon" then
                        weatherCardLabels["Goldmoon"].Text = "NOW!"
                    else
                        weatherCardLabels["Goldmoon"].Text = FormatTime(timeToMoon) .. " (13%)"
                    end
                end
                
                -- Blood Moon card (next night with 2% chance)
                if weatherCardLabels["Bloodmoon"] then
                    if currentWeather == "BloodMoon" then
                        weatherCardLabels["Bloodmoon"].Text = "NOW!"
                    else
                        weatherCardLabels["Bloodmoon"].Text = FormatTime(timeToMoon) .. " (2%)"
                    end
                end
                
                -- Rainbow Moon card (next night with 6% chance)
                if weatherCardLabels["Rainbow Moon"] then
                    if currentWeather == "RainbowMoon" then
                        weatherCardLabels["Rainbow Moon"].Text = "NOW!"
                    else
                        weatherCardLabels["Rainbow Moon"].Text = FormatTime(timeToMoon) .. " (6%)"
                    end
                end
                
                -- Weather events (random, show "Random" since they can't be predicted)
                local randomWeathers = {"Rain", "Lightning", "Snowfall", "Rainbow", "Starfall"}
                for _, wName in ipairs(randomWeathers) do
                    if weatherCardLabels[wName] then
                        if currentWeather == wName then
                            local wRemaining = math.max(0, (weatherDurations[wName] or 120) - (tick() - weatherStartTime))
                            weatherCardLabels[wName].Text = FormatTime(wRemaining) .. " left"
                        else
                            weatherCardLabels[wName].Text = "Random"
                        end
                    end
                end
                
                -- Highlight active weather card
                for cardName, label in pairs(weatherCardLabels) do
                    local card = label.Parent
                    if card then
                        local isActive = false
                        if cardName == "Day" and currentWeather == "Day" then isActive = true end
                        if cardName == "Moon" and currentWeather == "Night" then isActive = true end
                        if cardName == "Goldmoon" and currentWeather == "GoldMoon" then isActive = true end
                        if cardName == "Bloodmoon" and currentWeather == "BloodMoon" then isActive = true end
                        if cardName == "Rainbow Moon" and currentWeather == "RainbowMoon" then isActive = true end
                        if cardName == currentWeather then isActive = true end
                        
                        if isActive then
                            card.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
                            label.Text = "NOW!"
                        else
                            card.BackgroundColor3 = Color3.fromRGB(50, 90, 160)
                        end
                    end
                end
            end
            
            -- 3. Seed Shop Prediction
            if getShopNotif() then
                -- Base shop restock every 5 minutes (300 seconds)
                local baseRestock = 300
                local currentGlobalTime = os.time()
                local shopCycle = currentGlobalTime % baseRestock
                local nextRestock = baseRestock - shopCycle
                local restockMins = math.floor(nextRestock / 60)
                local restockSecs = math.floor(nextRestock % 60)
                ShopPredictLabel.Text = string.format("🔄 Next Restock: %02d:%02d", restockMins, restockSecs)
                
                -- Update per-seed timers
                for _, entry in ipairs(seedTimerLabels) do
                    local cycleSec = entry.data.cycle * 60
                    local seedCycle = currentGlobalTime % cycleSec
                    local seedNext = cycleSec - seedCycle
                    
                    if seedNext < 30 then
                        entry.label.Text = "⚡ SOON!"
                        entry.label.TextColor3 = Color3.fromRGB(255, 220, 80)
                        entry.row.BackgroundColor3 = Color3.fromRGB(60, 55, 20)
                    else
                        entry.label.Text = FormatTime(seedNext)
                        entry.label.TextColor3 = Color3.fromRGB(200, 200, 200)
                        entry.row.BackgroundColor3 = RarityBG[entry.data.rarity]
                    end
                end
            end
            
            local basePos = FindMyBasePos()

            -- 4. Auto Stay Base at Night
            local currentClockTime = Lighting.ClockTime or 12
            local isNightTime = (currentClockTime < 6 or currentClockTime >= 18)
            
            if getAutoStay() and isNightTime then
                if basePos and RootPart then
                    local distFromBase = Vector2.new(RootPart.Position.X, RootPart.Position.Z) - Vector2.new(basePos.X, basePos.Z)
                    if distFromBase.Magnitude > 40 then
                        -- Teleport back to base
                        TeleportTo(basePos + Vector3.new(0, 3, 0))
                        StatusLabel.Text = "🌙 Night - Returned to base"
                    end
                end
            end
            
            -- 5. Auto Defense
            if getAutoDefense() then
                local threats = FindThreatsInBase(basePos)
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief, basePos)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
            
            -- Update base status label
            if not StatusLabel.Text:find("⚔️") and not StatusLabel.Text:find("🎯") and not StatusLabel.Text:find("🌙") then
                StatusLabel.Text = "✅ Active | " .. currentWeather .. " | Monitoring..."
            end
        end)
        
        if not success then
            warn("MainLoop Error: ", err)
            StatusLabel.Text = "⚠️ Loop Error: " .. tostring(err):sub(1, 40)
        end
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
WeatherTimerLabel.Text = "--:--"

-- Print status to chat
pcall(function()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = "🌱 Devo GAG2 v2.0 loaded! bebe Ed Sheeran ♪",
        Color = Color3.fromRGB(40, 200, 120),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
end)

print("🌱 Devo GAG2 v2.0 loaded successfully!")

-- ==========================================
-- CLEANUP: Destroy UI when script is removed
-- ==========================================

-- Function to fully clean up
local function CleanupScript()
    _scriptRunning = false
    
    -- Disconnect all tracked connections
    for _, conn in ipairs(_connections) do
        pcall(function() conn:Disconnect() end)
    end
    _connections = {}
    
    -- Destroy the UI
    if Library and Library.Parent then
        Library:Destroy()
    end
end

-- Close button: fully destroys the script UI
CloseBtn.MouseButton1Click:Connect(function()
    CleanupScript()
end)

-- Auto-cleanup when script is destroyed from executor
-- This catches when user deletes/stops the script
if script then
    pcall(function()
        script.Destroying:Connect(function()
            CleanupScript()
        end)
    end)
    -- Fallback: AncestryChanged catches removal from parent
    pcall(function()
        script.AncestryChanged:Connect(function(_, newParent)
            if not newParent then
                CleanupScript()
            end
        end)
    end)
end

-- Also clean up if player leaves
game.Players.LocalPlayer.AncestryChanged:Connect(function(_, newParent)
    if not newParent then
        CleanupScript()
    end
end)