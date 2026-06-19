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

local function MakeDraggable(dragHandle, targetFrame)
    targetFrame = targetFrame or dragHandle
    local dragging, dragStart, startPos
    dragHandle.InputBegan:Connect(function(input)
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
    dragHandle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Dark Premium Theme Colors
local Theme = {
    Background = Color3.fromRGB(15, 15, 20),
    Secondary = Color3.fromRGB(25, 25, 30),
    Accent = Color3.fromRGB(0, 230, 118),
    Text = Color3.fromRGB(240, 240, 240),
    TextMuted = Color3.fromRGB(150, 150, 150),
    Stroke = Color3.fromRGB(40, 40, 50)
}

-- Build UI
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 450, 0.85, 0)
MainFrame.Position = UDim2.new(0.5, -225, 0.075, 0)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = true
MainFrame.Parent = Library

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Theme.Stroke
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

-- Chat Head (Messenger Style)
local ChatHead = Instance.new("ImageButton")
ChatHead.Name = "ChatHead"
ChatHead.Size = UDim2.new(0, 60, 0, 60)
ChatHead.Position = UDim2.new(0.5, -30, 0, 20)
ChatHead.BackgroundColor3 = Theme.Background
ChatHead.BorderSizePixel = 0
ChatHead.Visible = false
ChatHead.ClipsDescendants = true
ChatHead.Parent = Library

local success, avatarUrl = pcall(function()
    return game:GetService("Players"):GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
end)
if success and avatarUrl then
    ChatHead.Image = avatarUrl
else
    ChatHead.Image = "rbxassetid://6031201550"
end

local ChatHeadCorner = Instance.new("UICorner")
ChatHeadCorner.CornerRadius = UDim.new(1, 0)
ChatHeadCorner.Parent = ChatHead

local ChatHeadStroke = Instance.new("UIStroke")
ChatHeadStroke.Color = Theme.Accent
ChatHeadStroke.Thickness = 2
ChatHeadStroke.Parent = ChatHead

MakeDraggable(ChatHead)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Theme.Secondary
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local TitleBottomFix = Instance.new("Frame")
TitleBottomFix.Size = UDim2.new(1, 0, 0, 10)
TitleBottomFix.Position = UDim2.new(0, 0, 1, -10)
TitleBottomFix.BackgroundColor3 = Theme.Secondary
TitleBottomFix.BorderSizePixel = 0
TitleBottomFix.Parent = TitleBar

local TitleSeparator = Instance.new("Frame")
TitleSeparator.Size = UDim2.new(1, 0, 0, 1)
TitleSeparator.Position = UDim2.new(0, 0, 1, 0)
TitleSeparator.BackgroundColor3 = Theme.Stroke
TitleSeparator.BorderSizePixel = 0
TitleSeparator.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 20, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🌱 GAG2 Red Team"
TitleLabel.TextColor3 = Theme.Accent
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 30, 0, 30)
ToggleBtn.Position = UDim2.new(1, -40, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
ToggleBtn.Text = "-"
ToggleBtn.TextColor3 = Theme.Text
ToggleBtn.TextSize = 20
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.Parent = TitleBar

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

MakeDraggable(TitleBar, MainFrame)

-- Toggle logic
ToggleBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    ChatHead.Visible = true
end)

ChatHead.MouseButton1Click:Connect(function()
    ChatHead.Visible = false
    MainFrame.Visible = true
end)

-- Tab system
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, -40, 0, 40)
TabContainer.Position = UDim2.new(0, 20, 0, 65)
TabContainer.BackgroundColor3 = Theme.Secondary
TabContainer.BorderSizePixel = 0
TabContainer.Parent = MainFrame

local TabContainerCorner = Instance.new("UICorner")
TabContainerCorner.CornerRadius = UDim.new(0, 8)
TabContainerCorner.Parent = TabContainer

local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -40, 1, -125)
ContentFrame.Position = UDim2.new(0, 20, 0, 115)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness = 0
ContentFrame.ScrollBarImageColor3 = Theme.Accent
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local function CreateTab(name)
    local tab = Instance.new("Frame")
    tab.Name = name
    tab.Size = UDim2.new(1, 0, 1, 0)
    tab.BackgroundTransparency = 1
    tab.Visible = false
    tab.Parent = ContentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = tab
    
    return tab
end

local TabNames = {"Main", "Defense", "Shop", "Weather", "Server", "Info"}
local TabIcons = {"🌱", "🛡️", "🏪", "🌤️", "🌐", "ℹ️"}
local tabWidth = 1 / #TabNames

local function SwitchTab(tabName)
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") then
            child.Visible = false
        end
    end
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name == tabName then
            child.Visible = true
            local layout = child:FindFirstChildOfClass("UIListLayout")
            if layout then
                ContentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
            end
        end
    end
    for _, btn in pairs(TabContainer:GetChildren()) do
        if btn:IsA("TextButton") then
            btn.TextColor3 = Theme.TextMuted
            local indicator = btn:FindFirstChild("Indicator")
            if indicator then
                indicator.Visible = false
            end
        end
    end
    local tabBtn = TabContainer:FindFirstChild(tabName)
    if tabBtn then
        tabBtn.TextColor3 = Theme.Accent
        local indicator = tabBtn:FindFirstChild("Indicator")
        if indicator then
            indicator.Visible = true
        end
    end
end

for i, tabName in ipairs(TabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name = tabName
    tabBtn.Size = UDim2.new(tabWidth, 0, 1, 0)
    tabBtn.Position = UDim2.new(tabWidth * (i-1), 0, 0, 0)
    tabBtn.BackgroundTransparency = 1
    tabBtn.Text = TabIcons[i] .. " " .. tabName
    tabBtn.TextColor3 = (i == 1) and Theme.Accent or Theme.TextMuted
    tabBtn.TextSize = 13
    tabBtn.Font = Enum.Font.GothamSemibold
    tabBtn.BorderSizePixel = 0
    tabBtn.Parent = TabContainer
    
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0.6, 0, 0, 2)
    indicator.Position = UDim2.new(0.2, 0, 1, -2)
    indicator.BackgroundColor3 = Theme.Accent
    indicator.BorderSizePixel = 0
    indicator.Visible = (i == 1)
    indicator.Parent = tabBtn
    
    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 2)
    indCorner.Parent = indicator
    
    tabBtn.MouseButton1Click:Connect(function()
        SwitchTab(tabName)
    end)
end

-- Helper: Create toggle row
local function CreateToggle(tab, name, desc, default)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 55)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, -5)
    bg.Position = UDim2.new(0, 0, 0, 2)
    bg.BackgroundColor3 = Theme.Secondary
    bg.BorderSizePixel = 0
    bg.Parent = row
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 8)
    bgCorner.Parent = bg
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.7, -15, 0, 20)
    label.Position = UDim2.new(0, 15, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bg
    
    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(0.7, -15, 0, 16)
    descLabel.Position = UDim2.new(0, 15, 0, 28)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = desc
    descLabel.TextColor3 = Theme.TextMuted
    descLabel.TextSize = 12
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent = bg
    
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 46, 0, 24)
    toggle.Position = UDim2.new(1, -60, 0.5, -12)
    toggle.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(50, 50, 60)
    toggle.BorderSizePixel = 0
    toggle.Parent = bg
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
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
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local toggled = default
    
    toggleBtn.MouseButton1Click:Connect(function()
        toggled = not toggled
        local targetColor = toggled and Theme.Accent or Color3.fromRGB(50, 50, 60)
        local targetPos = toggled and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
        
        game:GetService("TweenService"):Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = targetColor}):Play()
        game:GetService("TweenService"):Create(circle, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = targetPos}):Play()
    end)
    
    return toggleBtn, function() return toggled end
end

-- Helper: Create Dropdown
local function CreateDropdown(tab, name, options, defaultOption, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 65)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, -10, 1, -5)
    bg.Position = UDim2.new(0, 5, 0, 2)
    bg.BackgroundColor3 = Theme.Secondary
    bg.BorderSizePixel = 0
    bg.ClipsDescendants = true
    bg.Parent = row
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 8)
    bgCorner.Parent = bg
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Theme.Text
    label.TextSize = 14
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = bg
    
    local selectedBtn = Instance.new("TextButton")
    selectedBtn.Size = UDim2.new(1, -20, 0, 26)
    selectedBtn.Position = UDim2.new(0, 10, 0, 32)
    selectedBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    selectedBtn.Text = "  " .. defaultOption .. " ▼"
    selectedBtn.TextColor3 = Theme.TextMuted
    selectedBtn.TextSize = 12
    selectedBtn.Font = Enum.Font.Gotham
    selectedBtn.TextXAlignment = Enum.TextXAlignment.Left
    selectedBtn.Parent = bg
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = selectedBtn
    
    local listFrame = Instance.new("Frame")
    listFrame.Size = UDim2.new(1, -20, 0, #options * 26)
    listFrame.Position = UDim2.new(0, 10, 0, 62)
    listFrame.BackgroundTransparency = 1
    listFrame.Parent = bg
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = listFrame
    
    local selectedValue = defaultOption
    local isOpen = false
    
    local function UpdateCanvas()
        local parentTab = row.Parent
        local parentLayout = parentTab:FindFirstChildOfClass("UIListLayout")
        if parentLayout and parentTab.Parent and parentTab.Parent:IsA("ScrollingFrame") then
            parentTab.Parent.CanvasSize = UDim2.new(0, 0, 0, parentLayout.AbsoluteContentSize.Y + 20)
        end
    end
    
    selectedBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            row.Size = UDim2.new(1, 0, 0, 70 + (#options * 26))
            selectedBtn.Text = "  " .. selectedValue .. " ▲"
        else
            row.Size = UDim2.new(1, 0, 0, 65)
            selectedBtn.Text = "  " .. selectedValue .. " ▼"
        end
        UpdateCanvas()
    end)
    
    for _, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton")
        optBtn.Size = UDim2.new(1, 0, 0, 26)
        optBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        optBtn.Text = "  " .. opt
        optBtn.TextColor3 = Theme.TextMuted
        optBtn.TextSize = 12
        optBtn.Font = Enum.Font.Gotham
        optBtn.TextXAlignment = Enum.TextXAlignment.Left
        optBtn.Parent = listFrame
        
        local optBtnCorner = Instance.new("UICorner")
        optBtnCorner.CornerRadius = UDim.new(0, 4)
        optBtnCorner.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            selectedValue = opt
            selectedBtn.Text = "  " .. opt .. " ▼"
            isOpen = false
            row.Size = UDim2.new(1, 0, 0, 65)
            UpdateCanvas()
            if callback then callback(selectedValue) end
        end)
    end
    
    return function() return selectedValue end
end

-- Helper: Create label row
local function CreateLabel(tab, text, color, isHeader)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, isHeader and 35 or 25)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 1, 0)
    label.Position = UDim2.new(0, 5, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Theme.TextMuted
    label.TextSize = isHeader and 14 or 13
    label.Font = isHeader and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = isHeader and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
    label.Parent = row
    
    return label
end

-- Helper: Create Spacer
local function CreateSpacer(tab, height)
    local spacer = Instance.new("Frame")
    spacer.Size = UDim2.new(1, 0, 0, height or 10)
    spacer.BackgroundTransparency = 1
    spacer.Parent = tab
end

-- Helper: Create Button
local function CreateButton(tab, text, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 45)
    row.BackgroundTransparency = 1
    row.Parent = tab
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, -5)
    btn.Position = UDim2.new(0, 0, 0, 2)
    btn.BackgroundColor3 = Theme.Secondary
    btn.Text = text
    btn.TextColor3 = Theme.Text
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamSemibold
    btn.BorderSizePixel = 0
    btn.Parent = row
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = btn
    
    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Theme.Stroke
    btnStroke.Thickness = 1
    btnStroke.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
        task.delay(0.1, function()
            game:GetService("TweenService"):Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Theme.Secondary}):Play()
        end)
        if callback then callback() end
    end)
    
    return btn
end

-- Helper: Create 3-Column Grid for Seeds
local function CreateSeedGrid(tab, items)
    for i = 1, #items, 3 do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 16)
        row.BackgroundTransparency = 1
        row.Parent = tab
        
        for j = 0, 2 do
            if items[i + j] then
                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.33, 0, 1, 0)
                label.Position = UDim2.new(0.33 * j, 0, 0, 0)
                label.BackgroundTransparency = 1
                label.Text = items[i + j]
                label.TextColor3 = Theme.TextMuted
                label.TextSize = 11
                label.Font = Enum.Font.Gotham
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.Parent = row
            end
        end
    end
end

-- ==========================================
-- TAB: MAIN
-- ==========================================
local MainTab = CreateTab("Main")
MainTab.Visible = true

CreateLabel(MainTab, "AUTO-COLLECT ITEMS", Theme.Accent, true)
local collectOptions = {"All Collectibles", "🟡 Gold Seed", "🌈 Rainbow Seed", "🐦 Bird", "📦 Seed Pack", "None"}
local getCollectTarget = CreateDropdown(MainTab, "Target Item", collectOptions, "All Collectibles")

CreateSpacer(MainTab)
CreateLabel(MainTab, "NOTIFICATIONS", Color3.fromRGB(80, 180, 255), true)
local _, getWeatherNotif = CreateToggle(MainTab, "Weather Notifications", "Alert on weather changes", true)
local _, getShopNotif = CreateToggle(MainTab, "Shop Predictions", "Track seed shop rotations", true)

CreateSpacer(MainTab)
CreateLabel(MainTab, "DEFENSE CONTROLS", Color3.fromRGB(255, 80, 80), true)
local _, getAutoDefense = CreateToggle(MainTab, "Auto Defense", "Auto-attack thieves in your base", true)
local _, getAutoStay = CreateToggle(MainTab, "Auto Stay at Base", "Return to base at night", true)



CreateSpacer(MainTab)
CreateLabel(MainTab, "STATUS", Color3.fromRGB(80, 180, 255), true)
local StatusLabel = CreateLabel(MainTab, "Script Active | Waiting...", Theme.Text)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Center

-- ==========================================
-- TAB: DEFENSE
-- ==========================================
local DefenseTab = CreateTab("Defense")

CreateLabel(DefenseTab, "WEAPON SETTINGS", Color3.fromRGB(255, 80, 80), true)
CreateLabel(DefenseTab, "✓ Shovel (Default - Free)", Theme.Accent)
CreateLabel(DefenseTab, "✓ Crowbar (Rare - Gear Shop)", Theme.Accent)
CreateLabel(DefenseTab, "✓ Freeze Ray (Premium - 749 Robux)", Theme.Accent)
CreateLabel(DefenseTab, "✓ Power Hose (Premium - 299 Robux)", Theme.Accent)

CreateSpacer(DefenseTab)
CreateLabel(DefenseTab, "Auto-detects thieves in your garden area", Theme.TextMuted)
CreateLabel(DefenseTab, "and equips best available weapon to", Theme.TextMuted)
CreateLabel(DefenseTab, "attack intruders automatically.", Theme.TextMuted)

-- ==========================================
-- TAB: SHOP
-- ==========================================
local ShopTab = CreateTab("Shop")

CreateLabel(ShopTab, "SEED SHOP PREDICTIONS", Color3.fromRGB(255, 180, 50), true)
local ShopPredictLabel = CreateLabel(ShopTab, "Monitoring shop rotations...", Theme.Text)
ShopPredictLabel.TextXAlignment = Enum.TextXAlignment.Center

CreateSpacer(ShopTab)
CreateLabel(ShopTab, "SEED ROTATIONS:", Theme.Accent)
local CommonLabel = CreateLabel(ShopTab, "⚪ Common: Always Available", Color3.fromRGB(200, 200, 200))
CreateSeedGrid(ShopTab, {"🥕 Carrot", "🍓 Strawberry", "🫐 Blueberry"})
local UncommonLabel = CreateLabel(ShopTab, "🟢 Uncommon: --:--", Color3.fromRGB(100, 255, 100))
CreateSeedGrid(ShopTab, {"🌷 Tulip", "🍅 Tomato", "🍎 Apple"})
local RareLabel = CreateLabel(ShopTab, "🔵 Rare: --:--", Color3.fromRGB(100, 150, 255))
CreateSeedGrid(ShopTab, {"🎋 Bamboo", "🌽 Corn", "🌵 Cactus", "🍍 Pineapple"})
local EpicLabel = CreateLabel(ShopTab, "🟣 Epic: --:--", Color3.fromRGB(200, 100, 255))
CreateSeedGrid(ShopTab, {"🍄 Mushroom", "🌿 Green Bean", "🍌 Banana", "🍇 Grape", "🥥 Coconut", "🥭 Mango"})
local LegendaryLabel = CreateLabel(ShopTab, "🟡 Legendary: --:--", Color3.fromRGB(255, 215, 0))
CreateSeedGrid(ShopTab, {"🐉 Dragon Fruit", "🌰 Acorn", "🍒 Cherry", "🌻 Sunflower"})
local MythicLabel = CreateLabel(ShopTab, "🔴 Mythic: --:--", Color3.fromRGB(255, 80, 80))
CreateSeedGrid(ShopTab, {"🪴 Venus Fly Trap", "🍎 Pomegranate", "🍏 Poison Apple"})
local SuperLabel = CreateLabel(ShopTab, "💎 Super: --:--", Color3.fromRGB(80, 255, 255))
CreateSeedGrid(ShopTab, {"🌕 Moon Bloom", "🐲 Dragon's Breath"})

-- ==========================================
-- TAB: WEATHER
-- ==========================================
local WeatherTab = CreateTab("Weather")

CreateLabel(WeatherTab, "WEATHER TRACKER", Color3.fromRGB(80, 180, 255), true)
local WeatherLabel = CreateLabel(WeatherTab, "Current: ☀️ Day", Theme.Text)
WeatherLabel.TextXAlignment = Enum.TextXAlignment.Center
local WeatherTimerLabel = CreateLabel(WeatherTab, "Time remaining: --:--", Theme.TextMuted)
WeatherTimerLabel.TextXAlignment = Enum.TextXAlignment.Center

CreateSpacer(WeatherTab)
CreateLabel(WeatherTab, "Weather types:", Theme.Accent)
CreateLabel(WeatherTab, "🌧️ Rain (5min) - 2x growth speed", Theme.TextMuted)
CreateLabel(WeatherTab, "⚡ Lightning (5min) - Electric mutation 80x", Theme.TextMuted)
CreateLabel(WeatherTab, "🌈 Rainbow (2min) - Rainbow mutation boost", Theme.TextMuted)
CreateLabel(WeatherTab, "❄️ Snowfall (2.5min) - Frozen mutation 5x", Theme.TextMuted)
CreateLabel(WeatherTab, "⭐ Starfall (2min) - Starstruck mutation", Theme.TextMuted)

CreateSpacer(WeatherTab)
CreateLabel(WeatherTab, "Night events (2min each):", Color3.fromRGB(150, 150, 255))
CreateLabel(WeatherTab, "🌑 Blood Moon - Bloodlit mutation", Theme.TextMuted)
CreateLabel(WeatherTab, "🌟 Gold Moon - Gold Seed spawns (15x)", Theme.TextMuted)
CreateLabel(WeatherTab, "🌈 Rainbow Moon - Rainbow seed spawns", Theme.TextMuted)

-- ==========================================
-- TAB: SERVER
-- ==========================================
local ServerTab = CreateTab("Server")

CreateLabel(ServerTab, "SERVER CONTROLS", Color3.fromRGB(200, 100, 255), true)
CreateButton(ServerTab, "🔄 Rejoin Server", function()
    local TeleportService = game:GetService("TeleportService")
    local Players = game:GetService("Players")
    if #Players:GetPlayers() <= 1 then
        Players.LocalPlayer:Kick("\nRejoining...")
        task.wait()
        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
    end
end)

CreateButton(ServerTab, "🌐 Server Hop", function()
    local HttpService = game:GetService("HttpService")
    local TeleportService = game:GetService("TeleportService")
    local serversApi = "https://games.roblox.com/v1/games/" .. tostring(game.PlaceId) .. "/servers/Public?sortOrder=Desc&limit=100"
    local success, response = pcall(function()
        return game:HttpGet(serversApi)
    end)
    if success and response then
        local data = HttpService:JSONDecode(response)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if type(server) == "table" and server.playing and server.maxPlayers and server.playing < server.maxPlayers - 1 and server.id ~= game.JobId then
                    pcall(function()
                        TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, game:GetService("Players").LocalPlayer)
                    end)
                    task.wait(1)
                end
            end
        end
    end
end)

-- ==========================================
-- TAB: INFO
-- ==========================================
local InfoTab = CreateTab("Info")

CreateLabel(InfoTab, "GROW A GARDEN 2", Theme.Accent, true)
CreateLabel(InfoTab, "Red Team Edition v1.0", Theme.TextMuted)

CreateSpacer(InfoTab)
CreateLabel(InfoTab, "HOW TO USE:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "1. Equip weapons in your inventory", Theme.TextMuted)
CreateLabel(InfoTab, "2. Toggle features on/off", Theme.TextMuted)
CreateLabel(InfoTab, "3. Script auto-detects events", Theme.TextMuted)

CreateSpacer(InfoTab)
CreateLabel(InfoTab, "Features:", Color3.fromRGB(255, 200, 100))
CreateLabel(InfoTab, "✅ Event seed auto-collect", Theme.TextMuted)
CreateLabel(InfoTab, "✅ Weather prediction system", Theme.TextMuted)
CreateLabel(InfoTab, "✅ Seed shop rotation tracker", Theme.TextMuted)
CreateLabel(InfoTab, "✅ Auto-stay at base during night", Theme.TextMuted)
CreateLabel(InfoTab, "✅ Auto defense with weapons", Theme.TextMuted)

CreateSpacer(InfoTab)
CreateLabel(InfoTab, "Tip: Stay in your garden during", Theme.Accent)
CreateLabel(InfoTab, "night to prevent theft!", Theme.Accent)

task.delay(0.1, function()
    local layout = MainTab:FindFirstChildOfClass("UIListLayout")
    if layout then
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
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

-- Weather state
local currentWeather = "Day"
local weatherStartTime = tick()
local cachedBase = nil
local lastBaseScan = 0
local lastStayTeleport = 0

-- Correct GAG2 weather durations (from wiki)
local weatherDurations = {
    Day = 450,         -- 7m 30s
    Rain = 300,        -- 5min
    Lightning = 300,   -- 5min
    Rainbow = 300,     -- 5min
    Snowfall = 150,    -- 2m 30s
    Starfall = 120,    -- 2min
    Night = 120,       -- 2min
    BloodMoon = 120,   -- 2min
    GoldMoon = 120,    -- 2min
    RainbowMoon = 120, -- 2min
}

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

-- Detect weather by Lighting children, Atmosphere, and ClockTime
local function DetectWeather()
    local clockTime = Lighting.ClockTime or 12
    local brightness = Lighting.Brightness or 1
    local ambient = Lighting.Ambient or Color3.new(0, 0, 0)
    local fogColor = Lighting.FogColor or Color3.new(0.5, 0.5, 0.5)
    local fogEnd = Lighting.FogEnd or 10000
    
    -- Method 1: Check for named weather objects in Lighting (most reliable)
    for _, child in pairs(Lighting:GetChildren()) do
        local n = child.Name:lower()
        if n:find("blood") then return "BloodMoon"
        elseif n:find("gold") or n:find("midas") then return "GoldMoon"
        elseif n:find("rainbowmoon") then return "RainbowMoon"
        elseif n:find("rainbow") and not n:find("moon") then return "Rainbow"
        elseif n:find("lightning") or n:find("thunder") or n:find("storm") then return "Lightning"
        elseif n:find("rain") and not n:find("bow") then return "Rain"
        elseif n:find("snow") or n:find("blizzard") then return "Snowfall"
        elseif n:find("star") then return "Starfall"
        end
    end
    
    -- Method 2: Check Atmosphere object for weather effects
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        local density = atmo.Density or 0
        local haze = atmo.Haze or 0
        if density > 0.5 and haze > 5 then
            -- Heavy atmosphere = likely Rain or Snowfall
            if fogColor.B > 0.6 and fogColor.R < 0.4 then
                return "Rain"
            elseif fogColor.R > 0.7 and fogColor.G > 0.7 and fogColor.B > 0.7 then
                return "Snowfall"
            end
        end
    end
    
    -- Method 3: Night detection by ClockTime
    if clockTime < 6 or clockTime > 20 then
        -- Check for special moon events by color
        if fogColor.R > 0.6 and fogColor.G < 0.3 and fogColor.B < 0.3 then
            return "BloodMoon"
        elseif fogColor.R > 0.7 and fogColor.G > 0.6 and fogColor.B < 0.3 then
            return "GoldMoon"
        elseif ambient.R > 0.3 and ambient.G < 0.2 and ambient.B > 0.4 then
            return "RainbowMoon"
        end
        return "Night"
    end
    
    -- Method 4: Daytime weather by fog/brightness
    if brightness < 0.5 and fogEnd < 500 then
        return "Rain"
    end
    if fogColor.R > 0.5 and fogColor.G > 0.3 and fogColor.B > 0.5 and brightness > 1 then
        return "Rainbow"
    end
    if fogColor.R > 0.7 and fogColor.G > 0.7 and fogColor.B > 0.8 and fogEnd < 300 then
        return "Snowfall"
    end
    if fogColor.R < 0.2 and fogColor.G < 0.15 and fogColor.B > 0.4 then
        return "Starfall"
    end
    
    return "Day"
end

-- Find collectible items based on enabled filters
local function FindCollectibles()
    local items = {}
    local checked = {}
    
    -- Build name patterns based on what's enabled
    local patterns = {}
    local target = getCollectTarget()
    
    if target == "None" then return items end
    
    if target == "All Collectibles" or target == "🟡 Gold Seed" then
        table.insert(patterns, {"gold", "seed"})
        table.insert(patterns, {"golden", "seed"})
        table.insert(patterns, {"gold", nil}) -- standalone gold objects
    end
    if target == "All Collectibles" or target == "🌈 Rainbow Seed" then
        table.insert(patterns, {"rainbow", "seed"})
        table.insert(patterns, {"rainbow", nil})
    end
    if target == "All Collectibles" or target == "🐦 Bird" then
        table.insert(patterns, {"bird", nil})
        table.insert(patterns, {"parrot", nil})
        table.insert(patterns, {"crow", nil})
        table.insert(patterns, {"dove", nil})
    end
    if target == "All Collectibles" or target == "📦 Seed Pack" then
        table.insert(patterns, {"seed", "pack"})
        table.insert(patterns, {"seedpack", nil})
        table.insert(patterns, {"gift", nil})
        table.insert(patterns, {"package", nil})
    end
    
    if #patterns == 0 then return items end
    
    -- Check if object name matches any enabled pattern
    local function IsTarget(obj)
        if checked[obj] then return false end
        checked[obj] = true
        if not (obj:IsA("BasePart") or obj:IsA("Model")) then return false end
        local name = obj.Name:lower()
        for _, pattern in ipairs(patterns) do
            if name:find(pattern[1]) then
                if pattern[2] == nil or name:find(pattern[2]) then
                    return true
                end
            end
        end
        return false
    end
    
    -- Priority 1: Check known folders
    local searchFolders = {"Seeds", "Drops", "EventSeeds", "Collectables", "DroppedItems", "Objects"}
    for _, folderName in ipairs(searchFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, obj in pairs(folder:GetDescendants()) do
                if IsTarget(obj) then
                    table.insert(items, obj)
                end
            end
        end
    end
    
    -- Priority 2: If no seeds found in folders, scan workspace (but only top-level children's descendants)
    if #items == 0 then
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Model") or obj:IsA("Folder") then
                -- Skip big models like Map, Terrain, etc
                if obj.Name ~= "Map" and obj.Name ~= "Terrain" and obj.Name ~= "Plots" then
                    for _, child in pairs(obj:GetDescendants()) do
                        if IsTarget(child) then
                            table.insert(items, child)
                        end
                    end
                end
            elseif IsTarget(obj) then
                table.insert(items, obj)
            end
        end
    end
    
    return items
end

-- Collect seed using the correct interaction method
local function CollectSeed(seedObj)
    local collected = false
    pcall(function()
        -- Get the actual part to interact with
        local target = seedObj
        if seedObj:IsA("Model") then
            target = seedObj.PrimaryPart or seedObj:FindFirstChildWhichIsA("BasePart") or seedObj
        end
        
        -- Method 1: ProximityPrompt (primary method in GAG2)
        local prompt = seedObj:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            fireproximityprompt(prompt)
            collected = true
            return
        end
        
        -- Method 2: ClickDetector
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector", true)
        if detector then
            fireclickdetector(detector)
            collected = true
            return
        end
        
        -- Method 3: firetouchinterest (touch-based collection)
        if target:IsA("BasePart") and RootPart then
            if firetouchinterest then
                firetouchinterest(RootPart, target, 0)
                task.wait(0.1)
                firetouchinterest(RootPart, target, 1)
                collected = true
                return
            end
        end
        
        -- Method 4: Direct teleport to touch it
        if target:IsA("BasePart") and RootPart then
            RootPart.CFrame = target.CFrame * CFrame.new(0, 0, 0)
            task.wait(0.15)
            collected = true
        end
    end)
    return collected
end

-- Teleport to position
local function TeleportTo(pos)
    if RootPart then
        RootPart.CFrame = CFrame.new(pos)
    end
end

-- Find base/garden plot (with caching)
local function FindMyBase()
    -- Return cached result if recent (cache for 30 seconds)
    if cachedBase and cachedBase.Parent and (tick() - lastBaseScan) < 30 then
        return cachedBase
    end
    
    local playerName = LocalPlayer.Name
    local playerId = tostring(LocalPlayer.UserId)
    local displayName = LocalPlayer.DisplayName
    
    -- Method 1: Check Workspace.Plots (standard GAG2 structure)
    local plotFolders = {"Plots", "PlayerPlots", "Gardens", "Map", "Bases"}
    for _, folderName in ipairs(plotFolders) do
        local folder = Workspace:FindFirstChild(folderName)
        if folder then
            for _, plot in pairs(folder:GetChildren()) do
                local pName = plot.Name
                -- Match by UserId, Username, or DisplayName
                if pName == playerName or pName == playerId or pName == displayName then
                    cachedBase = plot
                    lastBaseScan = tick()
                    return plot
                end
                -- Check if plot has an attribute identifying the owner
                local ownerId = plot:GetAttribute("Owner") or plot:GetAttribute("PlayerName") or plot:GetAttribute("UserId")
                if ownerId and (tostring(ownerId) == playerId or tostring(ownerId) == playerName) then
                    cachedBase = plot
                    lastBaseScan = tick()
                    return plot
                end
            end
            -- Also check subchildren for player-named models
            for _, plot in pairs(folder:GetDescendants()) do
                if (plot:IsA("Model") or plot:IsA("Folder")) and (plot.Name == playerName or plot.Name == playerId) then
                    cachedBase = plot
                    lastBaseScan = tick()
                    return plot
                end
            end
        end
    end
    
    -- Method 2: Search workspace top-level for player-named model
    for _, obj in pairs(Workspace:GetChildren()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) then
            local n = obj.Name
            if n == playerName or n == playerId or n:find(playerName) then
                cachedBase = obj
                lastBaseScan = tick()
                return obj
            end
        end
    end
    
    -- Method 3: Broader search for garden/plot objects containing player reference
    for _, obj in pairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) then
            local n = obj.Name:lower()
            if (n:find("plot") or n:find("garden")) and (n:find(playerName:lower()) or n:find(playerId)) then
                cachedBase = obj
                lastBaseScan = tick()
                return obj
            end
        end
    end
    
    lastBaseScan = tick()
    return nil
end

-- Find thieves in base area
local function FindThreatsInBase()
    local base = FindMyBase()
    if not base then return {} end
    
    -- Get base position from Model or BasePart
    local basePos = nil
    if base:IsA("BasePart") then
        basePos = base.Position
    elseif base:IsA("Model") and base.PrimaryPart then
        basePos = base.PrimaryPart.Position
    else
        local firstPart = base:FindFirstChildWhichIsA("BasePart", true)
        if firstPart then
            basePos = firstPart.Position
        end
    end
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
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    
    -- Check if already equipped in character
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find(weaponName:lower()) then
            return tool
        end
    end
    
    -- Find weapon in backpack and equip
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if backpack then
        for _, item in pairs(backpack:GetChildren()) do
            if item:IsA("Tool") and item.Name:lower():find(weaponName:lower()) then
                humanoid:EquipTool(item)
                task.wait(0.3)
                return item
            end
        end
    end
    
    return nil
end

-- Attack a player/thief
local function AttackThief(thief)
    if not thief.Character or not thief.Character:FindFirstChild("Humanoid") then return end
    if not RootPart then return end
    
    local targetRoot = thief.Character:FindFirstChild("HumanoidRootPart")
    if not targetRoot then return end
    
    -- Step 1: Move close to the target FIRST
    RootPart.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 3)
    task.wait(0.1)
    
    -- Step 2: Try each weapon in priority order
    for _, weaponName in ipairs(Config.DefenseWeapons) do
        local weapon = EquipWeapon(weaponName)
        if weapon then
            -- Face the target
            RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
            
            -- Activate weapon (swing/use)
            pcall(function() weapon:Activate() end)
            task.wait(0.15)
            pcall(function() weapon:Activate() end)
            
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
        -- Safely refresh character references
        pcall(function()
            if not Character or not Character.Parent then
                Character = LocalPlayer.Character
            end
            if Character and (not RootPart or not RootPart.Parent) then
                RootPart = Character:FindFirstChild("HumanoidRootPart")
            end
        end)
        if not RootPart then continue end
        
        -- 1. Auto-Collect Items (Gold Seed, Rainbow Seed, Bird, Seed Pack)
        pcall(function()
            if getCollectTarget() ~= "None" then
                local items = FindCollectibles()
                for _, item in ipairs(items) do
                    if not item or not item.Parent then continue end
                    -- Get item position
                    local itemPos = nil
                    if item:IsA("BasePart") then
                        itemPos = item.CFrame
                    elseif item:IsA("Model") then
                        local part = item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")
                        if part then itemPos = part.CFrame end
                    end
                    if itemPos and RootPart then
                        RootPart.CFrame = itemPos * CFrame.new(0, 2, 0)
                        task.wait(0.15)
                        CollectSeed(item)
                        StatusLabel.Text = "🎯 Collected " .. item.Name
                        task.wait(0.1)
                    end
                end
            end
        end)
        
        -- 2. Weather Detection & Notification
        pcall(function()
            if getWeatherNotif() then
                local detectedWeather = DetectWeather()
                
                -- Also try reading game's own weather attribute
                local gameAttr = Lighting:GetAttribute("Weather") or Lighting:GetAttribute("weather") or Lighting:GetAttribute("CurrentWeather")
                if gameAttr then
                    local attrStr = tostring(gameAttr):lower()
                    for weatherName, _ in pairs(weatherDurations) do
                        if attrStr:find(weatherName:lower()) then
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
                    StatusLabel.Text = "🌤️ Weather: " .. icon .. " " .. currentWeather
                    
                    -- Chat notification for important weather events
                    local isEventWeather = (currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" or 
                                           currentWeather == "BloodMoon" or currentWeather == "Rainbow" or 
                                           currentWeather == "Starfall")
                    if isEventWeather then
                        StatusLabel.Text = "⭐ EVENT: " .. icon .. " " .. currentWeather .. " - Seeds may spawn!"
                        pcall(function()
                            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                                Text = "⭐ " .. currentWeather .. " detected! Event seeds may spawn!",
                                Color = Color3.fromRGB(255, 215, 0),
                                Font = Enum.Font.GothamBold,
                                TextSize = 16
                            })
                        end)
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
        end)
        
        -- 3. Seed Shop Prediction
        pcall(function()
            if getShopNotif() then
                local now = os.time()
                
                local function FormatTime(secs)
                    if secs < 60 then return "SOON!" end
                    local h = math.floor(secs / 3600)
                    local m = math.floor((secs % 3600) / 60)
                    local s = math.floor(secs % 60)
                    if h > 0 then
                        return string.format("%02d:%02d:%02d", h, m, s)
                    else
                        return string.format("%02d:%02d", m, s)
                    end
                end
                
                local function GetCycle(cycleSecs)
                    local remain = cycleSecs - (now % cycleSecs)
                    return FormatTime(remain)
                end
                
                local nextRestock = 300 - (now % 300)
                ShopPredictLabel.Text = string.format("Next Restock: %02d:%02d", math.floor(nextRestock / 60), math.floor(nextRestock % 60))
                
                CommonLabel.Text = "⚪ Common: Always Available"
                UncommonLabel.Text = "🟢 Uncommon: " .. GetCycle(900)
                RareLabel.Text = "🔵 Rare: " .. GetCycle(1800)
                EpicLabel.Text = "🟣 Epic: " .. GetCycle(2700)
                LegendaryLabel.Text = "🟡 Legendary: " .. GetCycle(3600)
                MythicLabel.Text = "🔴 Mythic: " .. GetCycle(7200)
                SuperLabel.Text = "💎 Super: " .. GetCycle(14400)
            end
        end)
        
        -- 4. Auto Stay Base at Night (FIXED operator precedence)
        pcall(function()
            local isNightPhase = (currentWeather == "Night" or currentWeather == "BloodMoon" or 
                                  currentWeather == "GoldMoon" or currentWeather == "RainbowMoon")
            if getAutoStay() and isNightPhase then
                -- Cooldown: don't teleport more than once every 5 seconds
                if (tick() - lastStayTeleport) < 5 then return end
                
                local base = FindMyBase()
                if base then
                    local basePos = nil
                    if base:IsA("BasePart") then
                        basePos = base.Position
                    elseif base:IsA("Model") and base.PrimaryPart then
                        basePos = base.PrimaryPart.Position
                    else
                        local firstPart = base:FindFirstChildWhichIsA("BasePart", true)
                        if firstPart then basePos = firstPart.Position end
                    end
                    
                    if basePos and RootPart then
                        local distFromBase = (RootPart.Position - basePos).Magnitude
                        if distFromBase > 30 then
                            TeleportTo(basePos + Vector3.new(0, 3, 0))
                            lastStayTeleport = tick()
                            StatusLabel.Text = "🌙 Night - Returned to base"
                        end
                    end
                end
            end
        end)
        
        -- 5. Auto Defense
        pcall(function()
            if getAutoDefense() then
                local threats = FindThreatsInBase()
                if #threats > 0 then
                    for _, thief in ipairs(threats) do
                        AttackThief(thief)
                        task.wait(Config.WeaponCooldown)
                    end
                end
            end
        end)
        
        -- Update status label (only if no active event)
        pcall(function()
            local txt = StatusLabel.Text
            if not txt:find("⚔️") and not txt:find("🎯") and not txt:find("🌙") and not txt:find("⭐") then
                local icon = weatherIcons[currentWeather] or "❓"
                StatusLabel.Text = "✅ Active | " .. icon .. " " .. currentWeather .. " | Monitoring..."
            end
        end)
    end
end

-- Character respawn handler
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    RootPart = char:WaitForChild("HumanoidRootPart")
    cachedBase = nil -- Reset base cache on respawn
    task.wait(2)
end)

-- Start the script
task.spawn(MainLoop)

-- Initial status
StatusLabel.Text = "✅ Script loaded | Waiting for events..."
WeatherLabel.Text = "Current: ☀️ Day"
WeatherTimerLabel.Text = "Time remaining: --:--"

-- Print status to chat
pcall(function()
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text = "🌱 GAG2 Red Team Script loaded! All 5 features active.",
        Color = Color3.fromRGB(40, 180, 80),
        Font = Enum.Font.GothamBold,
        TextSize = 16
    })
end)

print("🌱 GAG2 Red Team Script loaded successfully!")
print("✅ Auto-Collect Event Seeds (ProximityPrompt + TouchInterest)")
print("✅ Weather Detection & Notification (Lighting-based)")
print("✅ Weather Prediction (Correct durations)")
print("✅ Auto Stay Base at Night (Fixed)")
print("✅ Auto Defense (Move→Equip→Attack)")