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
    
    DefenseWeapons = {
        "Freeze Ray",
        "Power Hose",
        "Crowbar",
        "Shovel"
    },
    
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
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Cleanup
if CoreGui:FindFirstChild("DevoGag2") then
    CoreGui:FindFirstChild("DevoGag2"):Destroy()
end

local _connections = {}
local _scriptRunning = true

-- UI Library
local Library = Instance.new("ScreenGui")
Library.Name = "DevoGag2"
Library.Parent = CoreGui
Library.ResetOnSpawn = false
Library.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

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
-- BUILD UI
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

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(45, 45, 60)
mainStroke.Thickness = 1.5
mainStroke.Parent = MainFrame

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

local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 42)
TitleBar.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = TitleBar

local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 12)
titleFill.Position = UDim2.new(0, 0, 1, -12)
titleFill.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
titleFill.BorderSizePixel = 0
titleFill.Parent = TitleBar

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

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌱 Devo GAG2 v3.0"
TitleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

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

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, child in pairs(MainFrame:GetChildren()) do
        if child.Name ~= "TitleBar" and child.Name ~= "Shadow" and not child:IsA("UICorner") and not child:IsA("UIStroke") and not child:IsA("UISizeConstraint") then
            child.Visible = not isMinimized
        end
    end
    MainFrame.Size = isMinimized and UDim2.new(0.9, 0, 0, 42) or UDim2.new(0.9, 0, 0.85, 0)
    MinBtn.Text = isMinimized and "+" or "—"
end)

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

local Tabs = {}
local TabNames = {"Main", "Weather", "Shop", "Defense", "Info"}
local TabIcons = {"🌱", "🌤️", "🏪", "🛡️", "ℹ️"}

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

-- Helpers
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

local _, getAutoCollect = CreateToggle(MainTab, "Auto-Collect Events", "Collect Golden, Rainbow seeds", true)
local _, getAutoDefense = CreateToggle(MainTab, "Auto Defense", "Auto-attack thieves in your base", true)
local _, getAutoStay = CreateToggle(MainTab, "Auto Stay at Base", "Return to base at night", true)
local _, getAntiAFK = CreateToggle(MainTab, "Anti-AFK", "Prevent Roblox from kicking you", true)

CreateLabel(MainTab, "=== STATUS ===", Color3.fromRGB(80, 180, 255))

local StatusLabel = CreateLabel(MainTab, "Script Active | Waiting...", Color3.fromRGB(180, 180, 180))

-- ==========================================
-- TAB: WEATHER (REWRITTEN FOR ACCURACY)
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

-- Current weather display (big)
labelOrder = labelOrder + 1
local CurrentWeatherRow = Instance.new("Frame")
CurrentWeatherRow.Name = "CurrentWeather"
CurrentWeatherRow.Size = UDim2.new(1, 0, 0, 50)
CurrentWeatherRow.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
CurrentWeatherRow.BorderSizePixel = 0
CurrentWeatherRow.LayoutOrder = labelOrder
CurrentWeatherRow.Parent = WeatherTab
local cwCorner = Instance.new("UICorner")
cwCorner.CornerRadius = UDim.new(0, 6)
cwCorner.Parent = CurrentWeatherRow

local WeatherIcon = Instance.new("TextLabel")
WeatherIcon.Size = UDim2.new(0, 50, 1, 0)
WeatherIcon.Position = UDim2.new(0, 8, 0, 0)
WeatherIcon.BackgroundTransparency = 1
WeatherIcon.Text = "☀️"
WeatherIcon.TextSize = 28
WeatherIcon.Font = Enum.Font.GothamBold
WeatherIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
WeatherIcon.Parent = CurrentWeatherRow

local WeatherLabel = Instance.new("TextLabel")
WeatherLabel.Size = UDim2.new(0.5, -60, 0, 20)
WeatherLabel.Position = UDim2.new(0, 58, 0, 5)
WeatherLabel.BackgroundTransparency = 1
WeatherLabel.Text = "Day"
WeatherLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
WeatherLabel.TextSize = 16
WeatherLabel.Font = Enum.Font.GothamBold
WeatherLabel.TextXAlignment = Enum.TextXAlignment.Left
WeatherLabel.Parent = CurrentWeatherRow

local WeatherDesc = Instance.new("TextLabel")
WeatherDesc.Size = UDim2.new(0.5, -60, 0, 16)
WeatherDesc.Position = UDim2.new(0, 58, 0, 28)
WeatherDesc.BackgroundTransparency = 1
WeatherDesc.Text = "Normal growth"
WeatherDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
WeatherDesc.TextSize = 11
WeatherDesc.Font = Enum.Font.Gotham
WeatherDesc.TextXAlignment = Enum.TextXAlignment.Left
WeatherDesc.Parent = CurrentWeatherRow

local WeatherTimerLabel = Instance.new("TextLabel")
WeatherTimerLabel.Size = UDim2.new(0.4, -10, 1, 0)
WeatherTimerLabel.Position = UDim2.new(0.6, 0, 0, 0)
WeatherTimerLabel.BackgroundTransparency = 1
WeatherTimerLabel.Text = "--:--"
WeatherTimerLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
WeatherTimerLabel.TextSize = 18
WeatherTimerLabel.Font = Enum.Font.GothamBold
WeatherTimerLabel.TextXAlignment = Enum.TextXAlignment.Center
WeatherTimerLabel.Parent = CurrentWeatherRow

-- Next weather prediction
labelOrder = labelOrder + 1
local NextWeatherFrame = Instance.new("Frame")
NextWeatherFrame.Name = "NextWeather"
NextWeatherFrame.Size = UDim2.new(1, 0, 0, 30)
NextWeatherFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
NextWeatherFrame.BorderSizePixel = 0
NextWeatherFrame.LayoutOrder = labelOrder
NextWeatherFrame.Parent = WeatherTab

local nwCorner = Instance.new("UICorner")
nwCorner.CornerRadius = UDim.new(0, 6)
nwCorner.Parent = NextWeatherFrame

local NextLabel = Instance.new("TextLabel")
NextLabel.Size = UDim2.new(1, -16, 1, 0)
NextLabel.Position = UDim2.new(0, 8, 0, 0)
NextLabel.BackgroundTransparency = 1
NextLabel.Text = "⏳ Next: -- (in --:--)"
NextLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
NextLabel.TextSize = 13
NextLabel.Font = Enum.Font.GothamSemibold
NextLabel.TextXAlignment = Enum.TextXAlignment.Left
NextLabel.Parent = NextWeatherFrame

-- Weather history log
labelOrder = labelOrder + 1
local LogLabel = CreateLabel(WeatherTab, "=== WEATHER LOG ===", Color3.fromRGB(80, 180, 255))
LogLabel.Parent.LayoutOrder = labelOrder

-- Weather description table
local WeatherInfo = {
    Day =        {icon = "☀️", desc = "Normal growth", color = Color3.fromRGB(255, 255, 150)},
    Night =      {icon = "🌙", desc = "Stealing is active!", color = Color3.fromRGB(100, 100, 180)},
    Rain =       {icon = "🌧️", desc = "2x growth speed, Wet mutation", color = Color3.fromRGB(100, 150, 255)},
    Lightning =  {icon = "⚡", desc = "Electric mutation (80x value!)", color = Color3.fromRGB(255, 255, 50)},
    Rainbow =    {icon = "🌈", desc = "Rainbow mutation chance boosted", color = Color3.fromRGB(255, 100, 255)},
    Snowfall =   {icon = "❄️", desc = "Frozen mutation (5x value)", color = Color3.fromRGB(180, 220, 255)},
    Starfall =   {icon = "⭐", desc = "Starstruck mutation", color = Color3.fromRGB(200, 200, 100)},
    BloodMoon =  {icon = "🌑", desc = "Bloodlit mutation, enhanced stealing", color = Color3.fromRGB(200, 50, 50)},
    GoldMoon =   {icon = "🌟", desc = "Gold seeds spawn on map!", color = Color3.fromRGB(255, 200, 50)},
    RainbowMoon ={icon = "🌈", desc = "Rainbow seeds spawn on map!", color = Color3.fromRGB(100, 255, 200)},
}

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

local SeedData = {
    {name = "Carrot", emoji = "🥕", rarity = "Common", cycle = 5},
    {name = "Strawberry", emoji = "🍓", rarity = "Common", cycle = 5},
    {name = "Blueberry", emoji = "🔵", rarity = "Common", cycle = 5},
    {name = "Tulip", emoji = "🌷", rarity = "Uncommon", cycle = 10},
    {name = "Tomato", emoji = "🍅", rarity = "Uncommon", cycle = 10},
    {name = "Apple", emoji = "🍎", rarity = "Uncommon", cycle = 10},
    {name = "Bamboo", emoji = "🎋", rarity = "Rare", cycle = 20},
    {name = "Corn", emoji = "🌽", rarity = "Rare", cycle = 20},
    {name = "Cactus", emoji = "🌵", rarity = "Rare", cycle = 20},
    {name = "Pineapple", emoji = "🍍", rarity = "Rare", cycle = 20},
    {name = "Mushroom", emoji = "🍄", rarity = "Epic", cycle = 45},
    {name = "Banana", emoji = "🍌", rarity = "Epic", cycle = 45},
    {name = "Grape", emoji = "🍇", rarity = "Epic", cycle = 45},
    {name = "Dragon Fruit", emoji = "🐉", rarity = "Legendary", cycle = 90},
    {name = "Acorn", emoji = "🌰", rarity = "Legendary", cycle = 90},
    {name = "Cherry", emoji = "🍒", rarity = "Legendary", cycle = 90},
    {name = "Venus Flytrap", emoji = "🕷️", rarity = "Mythic", cycle = 180},
    {name = "Dragon's Breath", emoji = "🔥", rarity = "Super", cycle = 240},
}

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

local seedTimerLabels = {}
local currentRarity = ""

for i, seed in ipairs(SeedData) do
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

CreateLabel(InfoTab, "=== GROW A GARDEN 2 v3.0 ===", Color3.fromRGB(40, 180, 80))
CreateLabel(InfoTab, "Weather-Accurate Edition", Color3.fromRGB(180, 180, 180))
CreateLabel(InfoTab, "", Color3.fromRGB(255,255,255))
CreateLabel(InfoTab, "Features:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "✅ Event seed auto-collect (Golden/Rainbow)", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ ACCURATE weather (reads game remotes)", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Seed shop rotation tracker", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto-stay at base during night", Color3.fromRGB(150, 255, 150))
CreateLabel(InfoTab, "✅ Auto defense with weapons", Color3.fromRGB(150, 255, 150))

-- ==========================================
-- ==========================================
-- CORE SYSTEM: ACCURATE WEATHER
-- ==========================================
-- ==========================================

-- Weather state variables
local currentWeather = "Day"
local weatherStartTime = tick()
local weatherEndTime = 0
local weatherDuration = 530 -- seconds
local weatherHistory = {}
local maxHistoryEntries = 20

-- Map of game weather names to our standardized names
local WeatherNameMapping = {
    ["Day"] = "Day",
    ["day"] = "Day",
    ["Sunny"] = "Day",
    ["sunny"] = "Day",
    ["Night"] = "Night",
    ["night"] = "Night",
    ["Moon"] = "Night",
    ["moon"] = "Night",
    ["Rain"] = "Rain",
    ["rain"] = "Rain",
    ["rainy"] = "Rain",
    ["Lightning"] = "Lightning",
    ["lightning"] = "Lightning",
    ["Thunderstorm"] = "Lightning",
    ["thunderstorm"] = "Lightning",
    ["Rainbow"] = "Rainbow",
    ["rainbow"] = "Rainbow",
    ["Snowfall"] = "Snowfall",
    ["snowfall"] = "Snowfall",
    ["Blizzard"] = "Snowfall",
    ["blizzard"] = "Snowfall",
    ["Snow"] = "Snowfall",
    ["snow"] = "Snowfall",
    ["Starfall"] = "Starfall",
    ["starfall"] = "Starfall",
    ["BloodMoon"] = "BloodMoon",
    ["Blood Moon"] = "BloodMoon",
    ["bloodmoon"] = "BloodMoon",
    ["blood moon"] = "BloodMoon",
    ["GoldMoon"] = "GoldMoon",
    ["Gold Moon"] = "GoldMoon",
    ["goldmoon"] = "GoldMoon",
    ["gold moon"] = "GoldMoon",
    ["Midas"] = "GoldMoon",
    ["midas"] = "GoldMoon",
    ["RainbowMoon"] = "RainbowMoon",
    ["Rainbow Moon"] = "RainbowMoon",
    ["rainbowmoon"] = "RainbowMoon",
    ["rainbow moon"] = "RainbowMoon",
}

-- Default durations (seconds) - used as fallback if game doesn't provide length
local DefaultWeatherDurations = {
    Day = 160,
    Night = 80,
    Rain = 120,
    Lightning = 120,
    Rainbow = 120,
    Snowfall = 120,
    Starfall = 120,
    BloodMoon = 80,
    GoldMoon = 80,
    RainbowMoon = 80,
}

-- ==========================================
-- METHOD 1: Connect to WeatherEventStarted RemoteEvent
-- This is THE MOST ACCURATE way - reads directly from the game
-- ==========================================
local weatherRemoteConnected = false

local function ConnectToWeatherRemote()
    local success, weatherRemote = pcall(function()
        return ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("WeatherEventStarted", 10)
    end)
    
    if success and weatherRemote then
        local connection = weatherRemote.OnClientEvent:Connect(function(eventName, eventLength)
            -- eventName = string like "Rain", "Lightning", "Blood Moon", etc.
            -- eventLength = duration in seconds (number)
            if not eventName or type(eventName) ~= "string" then return end
            
            local normalized = WeatherNameMapping[eventName]
            if not normalized then
                -- Try fuzzy matching
                local lower = eventName:lower():gsub("%s+", "")
                for k, v in pairs(WeatherNameMapping) do
                    if k:lower():gsub("%s+", "") == lower then
                        normalized = v
                        break
                    end
                end
            end
            
            if not normalized then normalized = eventName end
            
            local duration = (type(eventLength) == "number" and eventLength > 0) and eventLength or (DefaultWeatherDurations[normalized] or 120)
            
            -- Update weather state
            currentWeather = normalized
            weatherStartTime = tick()
            weatherDuration = duration
            weatherEndTime = tick() + duration
            
            -- Add to history
            table.insert(weatherHistory, 1, {
                weather = normalized,
                time = os.time(),
                duration = duration
            })
            if #weatherHistory > maxHistoryEntries then
                table.remove(weatherHistory)
            end
            
            -- Update UI
            UpdateWeatherUI()
            
            StatusLabel.Text = "🌤️ Weather: " .. normalized .. " (" .. duration .. "s)"
            
            -- Special alerts
            if normalized == "GoldMoon" or normalized == "RainbowMoon" or normalized == "Rainbow" then
                StatusLabel.Text = "⭐ EVENT: " .. normalized .. " - Seeds spawning!"
            end
        end)
        table.insert(_connections, connection)
        weatherRemoteConnected = true
        print("[Devo GAG2] Connected to WeatherEventStarted remote!")
        return true
    else
        warn("[Devo GAG2] WeatherEventStarted remote not found, using fallback detection")
        return false
    end
end

-- ==========================================
-- METHOD 2: Also check DataStream for weather data (backup)
-- ==========================================
local function ConnectToDataStream()
    local success, dataStream = pcall(function()
        return ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("DataStream", 5)
    end)
    
    if success and dataStream then
        local connection = dataStream.OnClientEvent:Connect(function(...)
            local args = {...}
            if #args >= 2 then
                local dataType = tostring(args[1])
                if dataType:lower():find("weather") then
                    -- DataStream often sends weather info as second argument
                    local weatherData = args[2]
                    if type(weatherData) == "string" then
                        local normalized = WeatherNameMapping[weatherData]
                        if normalized and normalized ~= currentWeather then
                            currentWeather = normalized
                            weatherStartTime = tick()
                            weatherDuration = DefaultWeatherDurations[normalized] or 120
                            weatherEndTime = tick() + weatherDuration
                            UpdateWeatherUI()
                        end
                    end
                end
            end
        end)
        table.insert(_connections, connection)
    end
end

-- ==========================================
-- METHOD 3: Fallback detection using Lightning, Workspace, and Particles
-- ==========================================
local function FallbackDetectWeather()
    -- Try game attributes first
    local gameText = nil
    pcall(function()
        for _, obj in ipairs({Workspace, Lighting, ReplicatedStorage}) do
            for _, attr in ipairs({"Weather", "CurrentWeather", "GameWeather", "WeatherType"}) do
                local val = obj:GetAttribute(attr)
                if val and tostring(val) ~= "" then
                    gameText = tostring(val)
                    return
                end
            end
        end
    end)
    
    if gameText then
        local normalized = WeatherNameMapping[gameText]
        if normalized then return normalized end
    end
    
    -- Check ClockTime for basic day/night
    local clockTime = Lighting.ClockTime or 12
    local isNight = (clockTime < 6 or clockTime >= 18)
    
    -- Check particles for weather effects
    local foundWeather = nil
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") and v.Enabled then
                local name = v.Name:lower()
                local parentName = v.Parent and v.Parent.Name:lower() or ""
                local combined = name .. " " .. parentName
                
                if combined:find("lightning") or combined:find("thunder") then
                    foundWeather = "Lightning"; break
                elseif combined:find("rain") and not combined:find("rainbow") then
                    foundWeather = "Rain"; break
                elseif combined:find("snow") or combined:find("blizzard") then
                    foundWeather = "Snowfall"; break
                elseif combined:find("starfall") or combined:find("fallingstar") then
                    foundWeather = "Starfall"; break
                elseif combined:find("rainbow") and not combined:find("rain") then
                    foundWeather = "Rainbow"; break
                end
            end
        end
    end)
    
    if foundWeather then return foundWeather end
    
    -- Fallback to day/night
    if isNight then
        local ambient = Lighting.Ambient or Color3.new(0, 0, 0)
        if ambient.R > 0.4 and ambient.G < 0.08 and ambient.B < 0.08 then return "BloodMoon" end
        if ambient.R > 0.4 and ambient.G > 0.3 and ambient.B < 0.08 then return "GoldMoon" end
        return "Night"
    end
    
    return "Day"
end

-- ==========================================
-- Update Weather UI
-- ==========================================
local function UpdateWeatherUI()
    local info = WeatherInfo[currentWeather] or WeatherInfo.Day
    WeatherIcon.Text = info.icon
    WeatherLabel.Text = currentWeather
    WeatherLabel.TextColor3 = info.color
    WeatherDesc.Text = info.desc
    
    -- Update the current weather row background color
    CurrentWeatherRow.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    
    -- Update timer
    local remaining = math.max(0, weatherEndTime - tick())
    local mins = math.floor(remaining / 60)
    local secs = math.floor(remaining % 60)
    WeatherTimerLabel.Text = string.format("%02d:%02d", mins, secs)
end

-- ==========================================
-- Update weather timers every second
-- ==========================================
local function WeatherTimerLoop()
    while _scriptRunning and task.wait(0.5) do
        pcall(function()
            local remaining = math.max(0, weatherEndTime - tick())
            local mins = math.floor(remaining / 60)
            local secs = math.floor(remaining % 60)
            WeatherTimerLabel.Text = string.format("%02d:%02d", mins, secs)
            
            -- Predict next weather
            local clockTime = Lighting.ClockTime or 12
            local isNight = (clockTime < 6 or clockTime >= 18)
            
            if isNight then
                local timeToDay = (clockTime >= 18) and ((24 - clockTime + 6) * 13.33) or ((6 - clockTime) * 13.33)
                NextLabel.Text = string.format("☀️ Next: Day (in %02d:%02d)", math.floor(timeToDay/60), math.floor(timeToDay%60))
            else
                local timeToNight = (18 - clockTime) * 13.33
                NextLabel.Text = string.format("🌙 Next: Night (in %02d:%02d)", math.floor(timeToNight/60), math.floor(timeToNight%60))
            end
        end)
    end
end

-- ==========================================
-- OTHER FEATURES
-- ==========================================

local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local isTarget = false
            
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit")) then isTarget = true
            elseif (name:find("rainbow") and (name:find("seed") or name:find("fruit"))) then isTarget = true
            elseif name:find("seed pack") or (name:find("seed") and name:find("pack")) then isTarget = true
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

local function CollectSeed(seedObj)
    pcall(function()
        local touch = seedObj:FindFirstChildWhichIsA("TouchTransmitter")
        if touch and RootPart then
            RootPart.CFrame = seedObj.CFrame * CFrame.new(0, 1, 0)
            task.wait(0.05)
            return true
        end
        
        local prompt = seedObj:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            pcall(function() prompt.HoldDuration = 0 end)
            fireproximityprompt(prompt, 1, true)
            return true
        end
        
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector")
        if detector then
            fireclickdetector(detector)
            return true
        end
    end)
    return false
end

local function TeleportTo(pos)
    if RootPart then
        RootPart.CFrame = CFrame.new(pos)
    end
end

local myBasePosCache = nil
local lastCacheTime = 0

local function FindMyBasePos()
    if myBasePosCache and (os.time() - lastCacheTime < 30) then return myBasePosCache end
    
    local playerName = LocalPlayer.Name
    local display = LocalPlayer.DisplayName
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and not obj:FindFirstChild("Humanoid") then
            local isMyBase = false
            local name = obj.Name
            
            if name == playerName or name == display then isMyBase = true end
            
            if not isMyBase then
                pcall(function()
                    for _, valName in ipairs({"Owner", "owner", "PlayerId"}) do
                        local ownerVal = obj:FindFirstChild(valName)
                        if ownerVal then
                            if tostring(ownerVal.Value) == playerName or tostring(ownerVal.Value) == display then
                                isMyBase = true
                            end
                        end
                    end
                end)
            end
            
            if not isMyBase then
                local lowerName = name:lower()
                if lowerName:find("garden") or lowerName:find("plot") or lowerName:find("base") then
                    for _, label in pairs(obj:GetDescendants()) do
                        if (label:IsA("TextLabel") or label:IsA("TextButton")) and (label.Text:find(playerName) or label.Text:find(display)) then
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
                    local part = obj:FindFirstChild("Base") or obj:FindFirstChildWhichIsA("BasePart", true)
                    if part then pos = part.Position end
                end
                if pos then
                    myBasePosCache = pos
                    lastCacheTime = os.time()
                    return pos
                end
            end
        end
    end
    return nil
end

local function FindThreatsInBase(basePos)
    if not basePos then return {} end
    local threats = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local dist = (player.Character.HumanoidRootPart.Position - basePos).Magnitude
            if dist < Config.DefenseRange then
                table.insert(threats, player)
            end
        end
    end
    return threats
end

local function EquipWeapon(weaponName)
    local backpack = LocalPlayer.Backpack
    if not backpack then return false end
    
    for _, item in pairs(backpack:GetChildren()) do
        local itemName = item.Name:lower()
        local targetName = weaponName:lower()
        if itemName:find(targetName) or targetName:find(itemName) then
            LocalPlayer.Character.Humanoid:EquipTool(item)
            task.wait(0.3)
            return item
        end
    end
    
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

local function AttackThief(thief, basePos)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    local targetRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    if basePos and (targetRoot.Position - basePos).Magnitude > Config.DefenseRange then return end
    
    if RootPart then
        RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
    end
    
    for _, weaponName in ipairs(Config.DefenseWeapons) do
        local weapon = EquipWeapon(weaponName)
        if weapon then
            weapon:Activate()
            task.wait(0.1)
            if weapon:FindFirstChild("Handle") then
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
    while _scriptRunning and task.wait(1) do
        local success, err = pcall(function()
            -- If remote is connected, fallback detection is only for backup
            if not weatherRemoteConnected then
                local detected = FallbackDetectWeather()
                if detected ~= currentWeather then
                    currentWeather = detected
                    weatherStartTime = tick()
                    weatherDuration = DefaultWeatherDurations[currentWeather] or 120
                    weatherEndTime = tick() + weatherDuration
                    
                    table.insert(weatherHistory, 1, {
                        weather = currentWeather,
                        time = os.time(),
                        duration = weatherDuration
                    })
                    if #weatherHistory > maxHistoryEntries then table.remove(weatherHistory) end
                    
                    UpdateWeatherUI()
                    StatusLabel.Text = "🌤️ Weather: " .. currentWeather
                end
            end
            
            -- Auto-Collect Event Seeds
            if getAutoCollect() then
                local seeds = FindEventSeeds()
                if #seeds > 0 and RootPart then
                    local originalPos = RootPart.CFrame
                    for _, seed in ipairs(seeds) do
                        RootPart.CFrame = seed.CFrame
                        task.wait(0.05)
                        CollectSeed(seed)
                        StatusLabel.Text = "🎯 Collected " .. seed.Name
                    end
                    task.wait(0.1)
                    RootPart.CFrame = originalPos
                end
            end
            
            local basePos = FindMyBasePos()
            local clockTime = Lighting.ClockTime or 12
            local isNightTime = (clockTime < 6 or clockTime >= 18)
            
            -- Auto Stay Base at Night
            if getAutoStay() and isNightTime then
                if basePos and RootPart then
                    local distFromBase = Vector2.new(RootPart.Position.X, RootPart.Position.Z) - Vector2.new(basePos.X, basePos.Z)
                    if distFromBase.Magnitude > 40 then
                        TeleportTo(basePos + Vector3.new(0, 3, 0))
                        StatusLabel.Text = "🌙 Night - Returned to base"
                    end
                end
            end
            
            -- Auto Defense
            if getAutoDefense() then
                local threats = FindThreatsInBase(basePos)
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief, basePos)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
            
            -- Anti-AFK
            if getAntiAFK() then
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                end)
            end
            
            -- Shop Prediction Update
            if Config.NotifyShop then
                local currentGlobalTime = os.time()
                local baseRestock = 300
                local shopCycle = currentGlobalTime % baseRestock
                local nextRestock = baseRestock - shopCycle
                local restockMins = math.floor(nextRestock / 60)
                local restockSecs = math.floor(nextRestock % 60)
                ShopPredictLabel.Text = string.format("🔄 Next Restock: %02d:%02d", restockMins, restockSecs)
                
                for _, entry in ipairs(seedTimerLabels) do
                    local cycleSec = entry.data.cycle * 60
                    local seedCycle = currentGlobalTime % cycleSec
                    local seedNext = cycleSec - seedCycle
                    
                    if seedNext < 30 then
                        entry.label.Text = "⚡ SOON!"
                        entry.label.TextColor3 = Color3.fromRGB(255, 220, 80)
                        entry.row.BackgroundColor3 = Color3.fromRGB(60, 55, 20)
                    else
                        entry.label.Text = string.format("In %02d:%02d", math.floor(seedNext/60), math.floor(seedNext%60))
                        entry.label.TextColor3 = Color3.fromRGB(200, 200, 200)
                        entry.row.BackgroundColor3 = RarityBG[entry.data.rarity]
                    end
                end
            end
            
            -- Update status
            if not StatusLabel.Text:find("⚔️") and not StatusLabel.Text:find("🎯") and not StatusLabel.Text:find("🌙") and not StatusLabel.Text:find("🌤️") and not StatusLabel.Text:find("⭐") then
                StatusLabel.Text = "✅ Active | " .. currentWeather .. " | Monitoring..."
            end
        end)
        
        if not success then
            warn("[Devo GAG2] Loop Error:", err)
        end
    end
end

-- ==========================================
-- INITIALIZATION
-- ==========================================

-- Connect to weather remote FIRST (most accurate method)
task.spawn(function()
    task.wait(3) -- Wait for game to fully load
    ConnectToWeatherRemote()
    ConnectToDataStream()
    
    -- If remote not found, use fallback to set initial weather
    if not weatherRemoteConnected then
        local initialWeather = FallbackDetectWeather()
        currentWeather = initialWeather
        weatherStartTime = tick()
        weatherDuration = DefaultWeatherDurations[currentWeather] or 120
        weatherEndTime = tick() + weatherDuration
        UpdateWeatherUI()
    end
    
    UpdateWeatherUI()
end)

-- Start weather timer loop
task.spawn(WeatherTimerLoop)

-- Start main loop
task.spawn(MainLoop)

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    RootPart = char:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-- Anti-AFK idle handler
LocalPlayer.Idled:Connect(function()
    if getAntiAFK() then
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end
end)

-- Initial status
StatusLabel.Text = "✅ Script active | Connecting to weather system..."
WeatherLabel.Text = "Day"
WeatherTimerLabel.Text = "--:--"
NextLabel.Text = "⏳ Next: -- (connecting...)"

-- Print to chat
pcall(function()
    local StarterGui = game:GetService("StarterGui")
    StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = "🌱 Devo GAG2 v3.0 loaded! Weather-Accurate Edition",
        Color = Color3.fromRGB(40, 200, 120),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
end)

print("🌱 Devo GAG2 v3.0 - Weather-Accurate Edition loaded!")

-- Cleanup
local function CleanupScript()
    _scriptRunning = false
    for _, conn in ipairs(_connections) do
        pcall(function() conn:Disconnect() end)
    end
    _connections = {}
    if Library and Library.Parent then
        Library:Destroy()
    end
end

CloseBtn.MouseButton1Click:Connect(function()
    CleanupScript()
end)

game.Players.LocalPlayer.AncestryChanged:Connect(function(_, newParent)
    if not newParent then CleanupScript() end
end)