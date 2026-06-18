--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                    GROW A GARDEN 2                          ║
    ║              PREMIUM SCRIPT - V1.0.0                        ║
    ╠══════════════════════════════════════════════════════════════╣
    ║  Features:                                                  ║
    ║  • Auto Collect Event Seeds (Gold, Rainbow, Bird, Packs)    ║
    ║  • Auto Return Base on Event End                            ║
    ║  • Premium Dark Mode UI (SpeedHub Inspired)                 ║
    ╚══════════════════════════════════════════════════════════════╝
--]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Configuration
local Settings = {
    AutoCollect = true,
    AutoReturn = true,
    CollectGold = true,
    CollectRainbow = true,
    CollectBird = true,
    CollectSeedPack = true,
    Notification = true,
    CollectionRadius = 100,
    ReturnDelay = 3,
}

-- Color Palette (Premium Dark Mode)
local Colors = {
    Background = Color3.fromRGB(15, 15, 20),
    BackgroundAlt = Color3.fromRGB(22, 22, 30),
    Panel = Color3.fromRGB(18, 18, 26),
    PanelBorder = Color3.fromRGB(35, 35, 50),
    Accent = Color3.fromRGB(100, 180, 255),
    AccentDim = Color3.fromRGB(60, 120, 200),
    Success = Color3.fromRGB(80, 220, 140),
    Warning = Color3.fromRGB(255, 200, 60),
    Danger = Color3.fromRGB(255, 80, 80),
    Text = Color3.fromRGB(220, 220, 235),
    TextDim = Color3.fromRGB(140, 140, 160),
    TextDark = Color3.fromRGB(60, 60, 80),
    Gold = Color3.fromRGB(255, 215, 50),
    Rainbow = Color3.fromRGB(200, 100, 255),
    GradientTop = Color3.fromRGB(25, 25, 40),
    GradientBottom = Color3.fromRGB(12, 12, 18),
    ToggleOn = Color3.fromRGB(80, 200, 120),
    ToggleOff = Color3.fromRGB(50, 50, 65),
    Glow = Color3.fromRGB(100, 180, 255),
}

-- Premium UI Library
local PremiumUI = {}
PremiumUI.__index = PremiumUI

function PremiumUI:CreateDrag(dragObject, moveObject)
    local dragging = false
    local dragInput, dragStart, startPos
    
    moveObject = moveObject or dragObject
    
    dragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = moveObject.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    dragObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moveObject.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function PremiumUI:CreateShadow(size, parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 1
    shadow.Size = size + UDim2.new(0, 40, 0, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    shadow.Parent = parent
    return shadow
end

function PremiumUI:CreateGradient(parent, colors, direction)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(colors)
    if direction then
        gradient.Rotation = direction
    end
    gradient.Parent = parent
    return gradient
end

function PremiumUI:CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

function PremiumUI:CreateStroke(parent, color, thickness, transparency)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Colors.PanelBorder
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.Parent = parent
    return stroke
end

function PremiumUI:NewWindow(title, subtitle)
    local self = setmetatable({}, PremiumUI)
    
    -- Main ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "GaG2Premium"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Check for existing
    local existing = CoreGui:FindFirstChild("GaG2Premium")
    if existing then existing:Destroy() end
    
    gui.Parent = CoreGui
    
    -- Main Frame
    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 420, 0, 560)
    main.Position = UDim2.new(0.5, -210, 0.5, -280)
    main.BackgroundColor3 = Colors.Background
    main.ClipsDescendants = true
    main.Parent = gui
    
    self:CreateShadow(UDim2.new(0, 420, 0, 560), main)
    self:CreateCorner(main, 12)
    self:CreateStroke(main, Colors.PanelBorder, 1.5)
    
    -- Background Gradient
    local bgGradient = Instance.new("Frame")
    bgGradient.Size = UDim2.new(1, 0, 1, 0)
    bgGradient.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    bgGradient.BackgroundTransparency = 1
    bgGradient.Parent = main
    self:CreateGradient(bgGradient, {
        ColorSequenceKeypoint.new(0, Colors.GradientTop),
        ColorSequenceKeypoint.new(1, Colors.GradientBottom)
    }, 90)
    
    -- Glow overlay
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 0, 2)
    glow.BackgroundColor3 = Colors.Glow
    glow.Position = UDim2.new(0, 0, 0, 0)
    glow.BackgroundTransparency = 0.3
    glow.Parent = main
    
    -- Title Bar (for dragging)
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Colors.BackgroundAlt
    titleBar.BorderSizePixel = 0
    titleBar.Parent = main
    self:CreateCorner(titleBar, 12)
    
    -- Fix corner clipping
    local titleBarCornerFix = Instance.new("Frame")
    titleBarCornerFix.Size = UDim2.new(1, 0, 0, 6)
    titleBarCornerFix.Position = UDim2.new(0, 0, 1, -6)
    titleBarCornerFix.BackgroundColor3 = Colors.BackgroundAlt
    titleBarCornerFix.BorderSizePixel = 0
    titleBarCornerFix.Parent = titleBar
    
    -- Scroll bar overlay on top of corner fix
    local titleBarLine = Instance.new("Frame")
    titleBarLine.Size = UDim2.new(1, 0, 0, 1)
    titleBarLine.Position = UDim2.new(0, 0, 1, -1)
    titleBarLine.BackgroundColor3 = Colors.PanelBorder
    titleBarLine.BorderSizePixel = 0
    titleBarLine.Parent = titleBar
    
    -- Logo / Icon
    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(0, 22, 0, 22)
    logo.Position = UDim2.new(0, 14, 0.5, -11)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://14278824786"
    logo.ImageColor3 = Colors.Accent
    logo.Parent = titleBar
    
    -- Title Text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Position = UDim2.new(0, 44, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title or "Devo - Ed"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Colors.Text
    titleLabel.Parent = titleBar
    
    -- Subtitle
    local subLabel = Instance.new("TextLabel")
    subLabel.Size = UDim2.new(0, 200, 1, 0)
    subLabel.Position = UDim2.new(0, 44, 0, 20)
    subLabel.BackgroundTransparency = 1
    subLabel.Text = subtitle or "Premium Collection"
    subLabel.Font = Enum.Font.Gotham
    subLabel.TextSize = 11
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextColor3 = Colors.TextDim
    subLabel.Parent = titleBar
    
    -- Minimize Button
    local minimizeBtn = Instance.new("ImageButton")
    minimizeBtn.Name = "Minimize"
    minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
    minimizeBtn.Position = UDim2.new(1, -76, 0.5, -16)
    minimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    minimizeBtn.Image = "rbxassetid://14278818776"
    minimizeBtn.ImageColor3 = Colors.TextDim
    minimizeBtn.Parent = titleBar
    self:CreateCorner(minimizeBtn, 6)
    self:CreateStroke(minimizeBtn, Colors.PanelBorder, 1)
    
    -- Close Button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "Close"
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -36, 0.5, -16)
    closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    closeBtn.Image = "rbxassetid://14278807410"
    closeBtn.ImageColor3 = Colors.TextDim
    closeBtn.Parent = titleBar
    self:CreateCorner(closeBtn, 6)
    self:CreateStroke(closeBtn, Colors.PanelBorder, 1)
    
    -- Tab Bar
    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 44)
    tabBar.Position = UDim2.new(0, 0, 0, 50)
    tabBar.BackgroundColor3 = Colors.Background
    tabBar.BorderSizePixel = 0
    tabBar.Parent = main
    
    local tabLine = Instance.new("Frame")
    tabLine.Size = UDim2.new(1, 0, 0, 1)
    tabLine.Position = UDim2.new(0, 0, 1, -1)
    tabLine.BackgroundColor3 = Colors.PanelBorder
    tabLine.BorderSizePixel = 0
    tabLine.Parent = tabBar
    
    -- Content Area
    local contentArea = Instance.new("Frame")
    contentArea.Name = "Content"
    contentArea.Size = UDim2.new(1, -24, 1, -110)
    contentArea.Position = UDim2.new(0, 12, 0, 98)
    contentArea.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    contentArea.BackgroundTransparency = 1
    contentArea.ClipsDescendants = true
    contentArea.Parent = main
    
    -- Scrolling Frame
    local scrollingFrame = Instance.new("ScrollingFrame")
    scrollingFrame.Name = "Pages"
    scrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollingFrame.BackgroundTransparency = 1
    scrollingFrame.BorderSizePixel = 0
    scrollingFrame.ScrollBarThickness = 4
    scrollingFrame.ScrollBarImageColor3 = Colors.AccentDim
    scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scrollingFrame.Parent = contentArea
    
    -- Store references
    self.Gui = gui
    self.Main = main
    self.TitleBar = titleBar
    self.TabBar = tabBar
    self.ScrollingFrame = scrollingFrame
    self.Tabs = {}
    self.CurrentTab = nil
    self.Minimized = false
    
    -- Drag setup
    self:CreateDrag(titleBar, main)
    
    -- Minimize functionality
    minimizeBtn.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        local targetSize = self.Minimized and UDim2.new(0, 420, 0, 50) or UDim2.new(0, 420, 0, 560)
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        local tween = TweenService:Create(main, tweenInfo, {Size = targetSize})
        tween:Play()
        minimizeBtn.ImageColor3 = self.Minimized and Colors.Accent or Colors.TextDim
    end)
    
    -- Close functionality
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Hover effects for buttons
    local function setupHover(btn)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 55)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30, 30, 42)}):Play()
        end)
    end
    setupHover(minimizeBtn)
    setupHover(closeBtn)
    
    -- Tab indicators
    self.TabIndicator = Instance.new("Frame")
    self.TabIndicator.Size = UDim2.new(0, 60, 0, 2)
    self.TabIndicator.Position = UDim2.new(0, 20, 1, -1)
    self.TabIndicator.BackgroundColor3 = Colors.Accent
    self.TabIndicator.BorderSizePixel = 0
    self.TabIndicator.Parent = tabBar
    self:CreateCorner(self.TabIndicator, 1)
    
    return self
end

function PremiumUI:AddTab(name, icon)
    local tabCount = #self.Tabs + 1
    local tabObj = {Name = name, Pages = {}, Elements = {}}
    
    -- Tab Button
    local btn = Instance.new("TextButton")
    btn.Name = name
    btn.Size = UDim2.new(0, 0, 1, 0)
    btn.Position = UDim2.new(0, 20 + (tabCount - 1) * 100, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "  " .. (icon or "") .. "  " .. name
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.TextColor3 = Colors.TextDim
    btn.BorderSizePixel = 0
    btn.Parent = self.TabBar
    btn.Size = UDim2.new(0, btn.TextBounds.X + 24, 1, 0)
    
    -- Page (hidden by default)
    local page = Instance.new("Frame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, 0, 0, 0)
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = self.ScrollingFrame
    
    local pageLayout = Instance.new("UIListLayout")
    pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pageLayout.Padding = UDim.new(0, 20)
    pageLayout.Parent = page
    
    tabObj.Button = btn
    tabObj.Page = page
    
    -- Click to switch
    btn.MouseButton1Click:Connect(function()
        self:SwitchTab(tabCount)
    end)
    
    -- Hover
    btn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tabCount then
            btn.TextColor3 = Colors.Text
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tabCount then
            btn.TextColor3 = Colors.TextDim
        end
    end)
    
    table.insert(self.Tabs, tabObj)
    
    -- Auto switch to first tab
    if tabCount == 1 then
        self:SwitchTab(1)
    end
    
    return tabObj
end

function PremiumUI:SwitchTab(index)
    self.CurrentTab = index
    
    for i, tab in ipairs(self.Tabs) do
        local isActive = (i == index)
        tab.Page.Visible = isActive
        tab.Button.TextColor3 = isActive and Colors.Accent or Colors.TextDim
        
        if isActive then
            -- Move indicator
            local btnSize = tab.Button.AbsoluteSize.X
            local btnPos = tab.Button.AbsolutePosition.X
            local mainPos = self.TabBar.AbsolutePosition.X
            local relativeX = btnPos - mainPos
            
            TweenService:Create(self.TabIndicator, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, relativeX + 8, 1, -1),
                Size = UDim2.new(0, btnSize - 16, 0, 2)
            }):Play()
        end
    end
    
    -- Reset scroll
    self.ScrollingFrame.CanvasPosition = Vector2.new(0, 0)
end

function PremiumUI:AddSection(pageObj, title)
    local section = Instance.new("Frame")
    section.Name = title .. "Section"
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundTransparency = 1
    section.Parent = pageObj.Page
    
    -- Section Header
    local header = Instance.new("TextLabel")
    header.Size = UDim2.new(1, 0, 0, 30)
    header.BackgroundTransparency = 1
    header.Text = title
    header.Font = Enum.Font.GothamBold
    header.TextSize = 14
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.TextColor3 = Colors.Text
    header.Parent = section
    
    -- Section line (decorative)
    local line = Instance.new("Frame")
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 1, -1)
    line.BackgroundColor3 = Colors.PanelBorder
    line.BorderSizePixel = 0
    line.Parent = header
    
    -- Content container
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, 0, 0, 0)
    content.Position = UDim2.new(0, 0, 0, 38)
    content.BackgroundTransparency = 1
    content.Parent = section
    content.AutomaticSize = Enum.AutomaticSize.Y
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)
    listLayout.Parent = content
    
    local sectionData = {
        Section = section,
        Header = header,
        Content = content,
        Elements = {}
    }
    
    table.insert(pageObj.Elements, sectionData)
    
    self:RepositionElements(pageObj)
    
    return sectionData
end

function PremiumUI:RepositionElements(pageObj)
    -- Layout is now handled automatically by UIListLayout and AutomaticSize
end

function PremiumUI:AddToggle(sectionData, title, description, default, callback)
    local toggle = Instance.new("Frame")
    toggle.Name = title .. "Toggle"
    toggle.Size = UDim2.new(1, 0, 0, 52)
    toggle.BackgroundColor3 = Colors.Panel
    toggle.Parent = sectionData.Content
    self:CreateCorner(toggle, 8)
    self:CreateStroke(toggle, Colors.PanelBorder, 1)
    
    -- State
    local toggled = default or false
    
    -- Toggle button
    local toggleBtn = Instance.new("Frame")
    toggleBtn.Name = "ToggleBtn"
    toggleBtn.Size = UDim2.new(0, 44, 0, 24)
    toggleBtn.Position = UDim2.new(1, -58, 0.5, -12)
    toggleBtn.BackgroundColor3 = toggled and Colors.ToggleOn or Colors.ToggleOff
    toggleBtn.Parent = toggle
    self:CreateCorner(toggleBtn, 12)
    
    -- Toggle knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = toggled and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = toggleBtn
    self:CreateCorner(knob, 10)
    
    -- Inner shadow on knob
    local knobShadow = Instance.new("Frame")
    knobShadow.Size = UDim2.new(1, 0, 1, 0)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.85
    knobShadow.Parent = knob
    self:CreateCorner(knobShadow, 10)
    
    -- Title
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 280, 0, 20)
    label.Position = UDim2.new(0, 14, 0.5, -10)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Colors.Text
    label.Parent = toggle
    
    -- Description
    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0, 280, 0, 16)
        desc.Position = UDim2.new(0, 14, 0.5, 6)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = Colors.TextDim
        desc.Parent = toggle
        toggle.Size = UDim2.new(1, 0, 0, 60)
    end
    
    -- Click detection
    local inputBtn = Instance.new("ImageButton")
    inputBtn.Size = UDim2.new(1, 0, 1, 0)
    inputBtn.BackgroundTransparency = 1
    inputBtn.ImageTransparency = 1
    inputBtn.Parent = toggle
    
    -- Toggle function
    local function setState(state)
        toggled = state
        TweenService:Create(toggleBtn, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundColor3 = toggled and Colors.ToggleOn or Colors.ToggleOff
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = toggled and UDim2.new(1, -24, 0.5, -10) or UDim2.new(0, 4, 0.5, -10)
        }):Play()
        if callback then
            pcall(callback, toggled)
        end
    end
    
    inputBtn.MouseButton1Click:Connect(function()
        setState(not toggled)
    end)
    
    -- Hover effect
    inputBtn.MouseEnter:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(24, 24, 34)
        }):Play()
    end)
    inputBtn.MouseLeave:Connect(function()
        TweenService:Create(toggle, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Panel
        }):Play()
    end)
    
    return toggle, setState
end

function PremiumUI:AddSlider(sectionData, title, min, max, default, suffix, callback)
    local slider = Instance.new("Frame")
    slider.Name = title .. "Slider"
    slider.Size = UDim2.new(1, 0, 0, 60)
    slider.BackgroundColor3 = Colors.Panel
    slider.Parent = sectionData.Content
    self:CreateCorner(slider, 8)
    self:CreateStroke(slider, Colors.PanelBorder, 1)
    
    -- Title
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 20)
    label.Position = UDim2.new(0, 14, 0, 10)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Colors.Text
    label.Parent = slider
    
    -- Value display
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Position = UDim2.new(1, -74, 0, 10)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default or min) .. (suffix or "")
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 14
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextColor3 = Colors.Accent
    valueLabel.Parent = slider
    
    -- Slider track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, -28, 0, 4)
    track.Position = UDim2.new(0, 14, 0, 44)
    track.BackgroundColor3 = Colors.ToggleOff
    track.Parent = slider
    self:CreateCorner(track, 2)
    
    -- Slider fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Colors.Accent
    fill.Parent = track
    self:CreateCorner(fill, 2)
    
    -- Slider knob
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 16, 0, 16)
    sliderKnob.Position = UDim2.new(0, -8, 0.5, -8)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    sliderKnob.Parent = fill
    self:CreateCorner(sliderKnob, 8)
    
    -- Inner shadow
    local knobShadow = Instance.new("Frame")
    knobShadow.Size = UDim2.new(1, 0, 1, 0)
    knobShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    knobShadow.BackgroundTransparency = 0.8
    knobShadow.Parent = sliderKnob
    self:CreateCorner(knobShadow, 8)
    
    -- Value
    local currentValue = default or min
    
    local function updateSlider(inputPos)
        local trackPos = track.AbsolutePosition.X
        local trackSize = track.AbsoluteSize.X
        local relativeX = math.clamp(inputPos - trackPos, 0, trackSize)
        local percent = relativeX / trackSize
        local value = math.floor(min + (max - min) * percent)
        currentValue = value
        
        fill.Size = UDim2.new(percent, 0, 1, 0)
        valueLabel.Text = tostring(value) .. (suffix or "")
        
        if callback then
            pcall(callback, value)
        end
    end
    
    -- Dragging
    local dragging = false
    local inputBtn = Instance.new("ImageButton")
    inputBtn.Size = UDim2.new(1, 0, 1, 0)
    inputBtn.BackgroundTransparency = 1
    inputBtn.ImageTransparency = 1
    inputBtn.Parent = slider
    
    inputBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    
    -- Hover
    inputBtn.MouseEnter:Connect(function()
        TweenService:Create(slider, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(24, 24, 34)
        }):Play()
    end)
    inputBtn.MouseLeave:Connect(function()
        TweenService:Create(slider, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Panel
        }):Play()
    end)
    
    -- Initial value
    if default then
        local percent = (default - min) / (max - min)
        fill.Size = UDim2.new(percent, 0, 1, 0)
    end
    
    return slider
end

function PremiumUI:AddButton(sectionData, title, description, accentColor, callback)
    local btn = Instance.new("Frame")
    btn.Name = title .. "Button"
    btn.Size = UDim2.new(1, 0, 0, 52)
    btn.BackgroundColor3 = Colors.Panel
    btn.Parent = sectionData.Content
    self:CreateCorner(btn, 8)
    self:CreateStroke(btn, Colors.PanelBorder, 1)
    
    local color = accentColor or Colors.Accent
    
    -- Accent bar on left
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 3, 0.6, 0)
    accentBar.Position = UDim2.new(0, 0, 0.2, 0)
    accentBar.BackgroundColor3 = color
    accentBar.BorderSizePixel = 0
    accentBar.Parent = btn
    self:CreateCorner(accentBar, 1.5)
    
    -- Title
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 280, 0, 20)
    label.Position = UDim2.new(0, 18, 0.5, -10)
    label.BackgroundTransparency = 1
    label.Text = title
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Colors.Text
    label.Parent = btn
    
    -- Description
    if description then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(0, 280, 0, 16)
        desc.Position = UDim2.new(0, 18, 0.5, 6)
        desc.BackgroundTransparency = 1
        desc.Text = description
        desc.Font = Enum.Font.Gotham
        desc.TextSize = 11
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextColor3 = Colors.TextDim
        desc.Parent = btn
        btn.Size = UDim2.new(1, 0, 0, 60)
    end
    
    -- Arrow indicator
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 30, 1, 0)
    arrow.Position = UDim2.new(1, -40, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "→"
    arrow.Font = Enum.Font.GothamBold
    arrow.TextSize = 18
    arrow.TextColor3 = color
    arrow.Parent = btn
    
    -- Click handling
    local inputBtn = Instance.new("ImageButton")
    inputBtn.Size = UDim2.new(1, 0, 1, 0)
    inputBtn.BackgroundTransparency = 1
    inputBtn.ImageTransparency = 1
    inputBtn.Parent = btn
    
    inputBtn.MouseButton1Click:Connect(function()
        if callback then
            pcall(callback)
        end
    end)
    
    inputBtn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(28, 28, 40)
        }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 3, 1, 0),
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end)
    
    inputBtn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = Colors.Panel
        }):Play()
        TweenService:Create(accentBar, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 3, 0.6, 0),
            Position = UDim2.new(0, 0, 0.2, 0)
        }):Play()
    end)
    
    return btn
end

function PremiumUI:AddLabel(sectionData, text, isDim)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = isDim and Colors.TextDim or Colors.Text
    label.Parent = sectionData.Content
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 14)
    padding.Parent = label
    
    return label
end

-- ============================================================
--  BUILDER START
-- ============================================================

-- Create Window
local ui = PremiumUI:NewWindow("Grow a Garden 2", "Premium Script v1.0.0")

-- Tab 1: Collection
local collectTab = ui:AddTab("Collect", "🌱")

-- Collect Section
local collectSection = ui:AddSection(collectTab, "Auto Collection")

local seedTypes = {
    {title = "Gold Seeds", desc = "Collect gold seeds during Midas/Gold Moon events", key = "CollectGold", color = Colors.Gold},
    {title = "Rainbow Seeds", desc = "Collect rainbow seeds during Rainbow Moon events", key = "CollectRainbow", color = Colors.Rainbow},
    {title = "Bird Seeds", desc = "Collect bird event seeds", key = "CollectBird", color = Colors.Success},
    {title = "Seed Packs", desc = "Auto collect all seed packs from events", key = "CollectSeedPack", color = Colors.Warning},
}

for _, seed in ipairs(seedTypes) do
    ui:AddToggle(collectSection, seed.title, seed.desc, true, function(state)
        Settings[seed.key] = state
    end)
end

-- Collection Radius
local radiusSection = ui:AddSection(collectTab, "Collection Settings")

ui:AddSlider(radiusSection, "Collection Radius", 30, 200, 100, " studs", function(value)
    Settings.CollectionRadius = value
end)

ui:AddToggle(radiusSection, "Auto Return to Base", "Return to base when events end", true, function(state)
    Settings.AutoReturn = state
end)

ui:AddSlider(radiusSection, "Return Delay", 0, 10, 3, "s", function(value)
    Settings.ReturnDelay = value
end)

-- Notifications Section
local notifSection = ui:AddSection(collectTab, "Notifications")
ui:AddToggle(notifSection, "Enable Notifications", "Show collection notifications", true, function(state)
    Settings.Notification = state
end)

-- Tab 2: Status
local statusTab = ui:AddTab("Status", "📊")

local statusSection = ui:AddSection(statusTab, "Script Status")

-- Status labels
local statusLabel = ui:AddLabel(statusSection, "● Script Active", false)
local seedsCollected = ui:AddLabel(statusSection, "Seeds Collected: 0", true)

local eventSection = ui:AddSection(statusTab, "Event Detection")

local currentEventLabel = ui:AddLabel(eventSection, "Current Event: None", true)
local timeLabel = ui:AddLabel(eventSection, "Time: --:--:--", true)

-- Tab 3: About
local aboutTab = ui:AddTab("About", "ℹ️")

local aboutSection = ui:AddSection(aboutTab, "Grow a Garden 2 Premium")

ui:AddLabel(aboutSection, "Version: 1.0.0", false)
ui:AddLabel(aboutSection, "Made for bebe Ed <3", true)
ui:AddLabel(aboutSection, "", true)

local features = {
    "✓ Auto Collect Event Seeds",
    "✓ Gold / Rainbow / Bird / Packs",
    "✓ Auto Return on Event End",
    "✓ Premium Dark Mode UI",
    "✓ Real-time Status Updates"
}

for _, feature in ipairs(features) do
    ui:AddLabel(aboutSection, "  " .. feature, true)
end

ui:AddButton(aboutSection, "Destroy UI", "Remove the script interface", Colors.Danger, function()
    ui.Gui:Destroy()
end)

-- ============================================================
--  FUNCTIONALITY
-- ============================================================

-- Notification system
local function sendNotification(title, text, duration)
    if not Settings.Notification then return end
    
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Icon = "rbxassetid://14278824786",
            Duration = duration or 3.5
        })
    end)
end

-- Seed detection and collection
local collectedCount = 0
local currentEvent = "None"
local isInEvent = false

local function findSeeds()
    local seeds = {}
    local rootPos = humanoidRootPart.Position
    
    -- Search workspace for seeds
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and obj:FindFirstChild("Seed") then
            local seedValue = obj:FindFirstChild("Seed")
            if seedValue then
                local seedType = tostring(seedValue.Value)
                local distance = (obj.Position - rootPos).Magnitude
                
                if distance <= Settings.CollectionRadius then
                    local shouldCollect = false
                    
                    if seedType:find("Gold") and Settings.CollectGold then
                        shouldCollect = true
                    elseif seedType:find("Rainbow") and Settings.CollectRainbow then
                        shouldCollect = true
                    elseif seedType:find("Bird") and Settings.CollectBird then
                        shouldCollect = true
                    elseif seedType:find("Pack") and Settings.CollectSeedPack then
                        shouldCollect = true
                    end
                    
                    if shouldCollect then
                        table.insert(seeds, {Object = obj, Type = seedType, Distance = distance})
                    end
                end
            end
        end
    end
    
    return seeds
end

local function teleportTo(position)
    if humanoidRootPart and humanoidRootPart.Parent then
        humanoidRootPart.CFrame = CFrame.new(position)
    end
end

local function collectSeed(seedObj)
    pcall(function()
        -- Try to fire remote if exists
        local remote = ReplicatedStorage:FindFirstChild("CollectSeed") or 
                      ReplicatedStorage:FindFirstChild("Pickup") or
                      ReplicatedStorage:FindFirstChild("Collect")
        
        if remote then
            remote:FireServer(seedObj.Object)
        else
            -- Fallback: attempt to collect via proximity
            fireproximityprompt(seedObj.Object:FindFirstChildWhichIsA("ProximityPrompt") or 
                              seedObj.Object:FindFirstChild("Prompt"), 1)
        end
        
        collectedCount = collectedCount + 1
        seedsCollected.Text = "Seeds Collected: " .. collectedCount
        
        sendNotification("Seed Collected", seedObj.Type .. " (+" .. tostring(collectedCount) .. ")", 2)
    end)
end

-- Event detection
local function detectEvent()
    -- Check for weather events
    local weather = workspace:FindFirstChild("Weather") or workspace:FindFirstChild("Events")
    if weather then
        for _, child in ipairs(weather:GetChildren()) do
            local name = child.Name:lower()
            if name:find("gold") or name:find("midas") then
                return "Gold Moon Event"
            elseif name:find("rainbow") then
                return "Rainbow Moon Event"
            elseif name:find("bird") then
                return "Bird Event"
            elseif name:find("event") then
                return "Special Event"
            end
        end
    end
    
    -- Check lighting
    local lighting = game:GetService("Lighting")
    if lighting:FindFirstChild("GoldEffect") or lighting:FindFirstChild("MidasEffect") then
        return "Gold Moon Event"
    elseif lighting:FindFirstChild("RainbowEffect") then
        return "Rainbow Moon Event"
    end
    
    -- Check for event bools
    for _, v in pairs(getgc(true)) do
        if type(v) == "table" then
            if v.IsEvent and v.IsEvent == true then
                if v.EventType then
                    local et = tostring(v.EventType)
                    if et:find("Gold") then return "Gold Moon Event" end
                    if et:find("Rainbow") then return "Rainbow Moon Event" end
                    if et:find("Bird") then return "Bird Event" end
                end
            end
        end
    end
    
    return nil
end

-- Main collection loop
local function collectionLoop()
    while task.wait(0.5) do
        if not ui.Gui.Parent then break end
        
        -- Update time
        timeLabel.Text = "Time: " .. os.date("%H:%M:%S")
        
        -- Detect event
        local detected = detectEvent()
        if detected then
            if currentEvent ~= detected then
                currentEvent = detected
                currentEventLabel.Text = "Current Event: " .. detected
                currentEventLabel.TextColor3 = Colors.Accent
                isInEvent = true
                sendNotification("Event Detected", detected, 3)
            end
        else
            if isInEvent and Settings.AutoReturn then
                -- Event ended, return to base after delay
                task.delay(Settings.ReturnDelay, function()
                    local spawn = workspace:FindFirstChild("Spawn") or 
                                 workspace:FindFirstChild("SpawnLocation") or
                                 workspace:FindFirstChild("Base")
                    if spawn then
                        teleportTo(spawn.Position)
                        sendNotification("Returned to Base", "Event ended, auto-return", 2)
                    end
                end)
            end
            currentEvent = "None"
            currentEventLabel.Text = "Current Event: None"
            currentEventLabel.TextColor3 = Colors.TextDim
            isInEvent = false
        end
        
        -- Find and collect seeds
        if Settings.AutoCollect then
            local seeds = findSeeds()
            if #seeds > 0 then
                table.sort(seeds, function(a, b) return a.Distance < b.Distance end)
                for _, seed in ipairs(seeds) do
                    collectSeed(seed)
                    task.wait(0.1)
                end
            end
        end
    end
end

-- Character respawn handling
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    task.wait(1)
end)

-- Start collection loop
task.spawn(collectionLoop)

-- Notification that script loaded
sendNotification("Script Loaded", "Grow a Garden 2 Premium is ready", 3)

-- Return the UI for external access
_G.GaG2Premium = {
    UI = ui,
    Settings = Settings,
    Collect = function() return findSeeds() end,
    GetEvent = function() return detectEvent() end,
    Destroy = function() ui.Gui:Destroy() end,
}