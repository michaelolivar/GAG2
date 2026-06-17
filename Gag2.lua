--[[
╔══════════════════════════════════════════════════════════════╗
║          🌱 GROW A GARDEN 2 — Devo v2.1 (Fixed)             ║
║          Premium UI Edition · by: bebe Ed Sheeran            ║
╠══════════════════════════════════════════════════════════════╣
║  BUGS FIXED IN THIS VERSION:                                 ║
║  [FIX 1] getWeatherNotif was hardcoded true — now a real     ║
║          toggle (line ~429 original: replaced w/ CreateToggle)║
║  [FIX 2] MinBtn re-assigns ContentFrame via FindFirstChild   ║
║          which could nil it out — removed bad re-assignment  ║
║  [FIX 3] TouchTransmitter check was wrong type — corrected  ║
║          to TouchInterest (actual child name in Roblox)      ║
║  [FIX 4] DescendantAdded obj validity check before acting    ║
║          Added IsDescendantOf(Workspace) guard               ║
║  [FIX 5] StatusLabel.Parent.LayoutOrder = 101 conflicted     ║
║          with auto toggleOrder — removed manual override     ║
║  [FIX 6] Weather cards clip on narrow screens — switched     ║
║          to UIGridLayout-based rows                          ║
║  [FIX 7] CreateLabel missing TextXAlignment — added Left     ║
║                                                              ║
║  UI IMPROVEMENTS:                                            ║
║  • Glassy frosted-panel aesthetic with layered depth          ║
║  • Animated gradient accent bar on title                     ║
║  • Tab indicator underline instead of just color swap        ║
║  • Toggle has smooth spring-style tween                      ║
║  • Section dividers with inline icon badges                  ║
║  • Status bar always visible at bottom (outside scroll)      ║
║  • Weather cards use grid — no clipping on small screens     ║
╚══════════════════════════════════════════════════════════════╝
--]]

-- ==========================================
-- SERVICES
-- ==========================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local Lighting            = game:GetService("Lighting")
local UserInputService    = game:GetService("UserInputService")
local TweenService        = game:GetService("TweenService")
local CoreGui             = game:GetService("CoreGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Workspace           = game:GetService("Workspace")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local RootPart    = Character:WaitForChild("HumanoidRootPart")

-- Configuration
local Config = {
    DefenseWeapons = {"Freeze Ray", "Power Hose", "Crowbar", "Shovel"},
    DefenseRange   = 30,
    WeaponCooldown = 2,
}

-- ==========================================
-- CLEANUP
-- ==========================================
if CoreGui:FindFirstChild("DevoGag2") then
    CoreGui:FindFirstChild("DevoGag2"):Destroy()
end

local _connections  = {}
local _scriptRunning = true

-- ==========================================
-- THEME TOKENS
-- ==========================================
local T = {
    -- Base surfaces
    bg0        = Color3.fromRGB(12,  12,  18),   -- deepest bg
    bg1        = Color3.fromRGB(18,  18,  26),   -- main panel
    bg2        = Color3.fromRGB(24,  24,  36),   -- title bar
    bg3        = Color3.fromRGB(30,  30,  44),   -- section/card bg
    bg4        = Color3.fromRGB(36,  36,  52),   -- hover/active tab

    -- Accent palette  (green → cyan → violet gradient)
    accent1    = Color3.fromRGB(32,  210, 110),  -- primary green
    accent2    = Color3.fromRGB(20,  165, 230),  -- cyan mid
    accent3    = Color3.fromRGB(110,  70, 255),  -- violet end

    -- Text
    textPrimary   = Color3.fromRGB(235, 235, 245),
    textSecondary = Color3.fromRGB(155, 155, 170),
    textMuted     = Color3.fromRGB(90,   90, 110),
    textAccent    = Color3.fromRGB(32,  210, 110),

    -- Semantic
    danger  = Color3.fromRGB(210,  50,  50),
    warning = Color3.fromRGB(240, 170,  40),
    info    = Color3.fromRGB(60,  150, 255),
    success = Color3.fromRGB(32,  210, 110),

    -- Borders
    stroke  = Color3.fromRGB(42,  42,  60),
    strokeHi = Color3.fromRGB(60, 60, 88),

    -- Toggle
    toggleOff = Color3.fromRGB(38,  38,  54),
    toggleOn  = Color3.fromRGB(32,  210, 110),
}

-- ==========================================
-- SCREEN GUI
-- ==========================================
local Library        = Instance.new("ScreenGui")
Library.Name         = "DevoGag2"
Library.Parent       = CoreGui
Library.ResetOnSpawn = false
Library.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ==========================================
-- DRAGGABLE HELPER
-- ==========================================
local function MakeDraggable(dragHandle, targetFrame)
    local dragging, dragStart, startPos = false, nil, nil

    local c1 = dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = targetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    table.insert(_connections, c1)

    local c2 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            targetFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
    table.insert(_connections, c2)
end

-- ==========================================
-- MAIN FRAME  (glass panel)
-- ==========================================
local MainFrame = Instance.new("Frame")
MainFrame.Name            = "MainFrame"
MainFrame.Size            = UDim2.new(0.9, 0, 0.85, 0)
MainFrame.AnchorPoint     = Vector2.new(0.5, 0.5)
MainFrame.Position        = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = T.bg1
MainFrame.BorderSizePixel = 0
MainFrame.Active          = true
MainFrame.ClipsDescendants = true
MainFrame.Parent          = Library

local _sizeC = Instance.new("UISizeConstraint")
_sizeC.MaxSize = Vector2.new(410, 560)
_sizeC.MinSize = Vector2.new(280, 44)
_sizeC.Parent  = MainFrame

local _mainCorner = Instance.new("UICorner")
_mainCorner.CornerRadius = UDim.new(0, 12)
_mainCorner.Parent       = MainFrame

local _mainStroke = Instance.new("UIStroke")
_mainStroke.Color     = T.stroke
_mainStroke.Thickness = 1.2
_mainStroke.Parent    = MainFrame

-- Soft drop-shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Name               = "Shadow"
Shadow.AnchorPoint        = Vector2.new(0.5, 0.5)
Shadow.BackgroundTransparency = 1
Shadow.Position           = UDim2.new(0.5, 0, 0.5, 6)
Shadow.Size               = UDim2.new(1, 40, 1, 40)
Shadow.ZIndex             = -1
Shadow.Image              = "rbxassetid://6015897843"
Shadow.ImageColor3        = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency  = 0.45
Shadow.ScaleType          = Enum.ScaleType.Slice
Shadow.SliceCenter        = Rect.new(49, 49, 450, 450)
Shadow.Parent             = MainFrame

-- ==========================================
-- TITLE BAR
-- ==========================================
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = T.bg2
TitleBar.BorderSizePixel  = 0
TitleBar.ZIndex           = 3
TitleBar.Parent           = MainFrame

-- Only top corners rounded — fill bottom gap
local _tbCorner = Instance.new("UICorner")
_tbCorner.CornerRadius = UDim.new(0, 12)
_tbCorner.Parent       = TitleBar

local _tbFill = Instance.new("Frame")
_tbFill.Size             = UDim2.new(1, 0, 0, 14)
_tbFill.Position         = UDim2.new(0, 0, 1, -14)
_tbFill.BackgroundColor3 = T.bg2
_tbFill.BorderSizePixel  = 0
_tbFill.Parent           = TitleBar

-- Animated gradient accent line
local AccentLine = Instance.new("Frame")
AccentLine.Name           = "AccentLine"
AccentLine.Size           = UDim2.new(1, 0, 0, 2)
AccentLine.Position       = UDim2.new(0, 0, 1, -2)
AccentLine.BorderSizePixel = 0
AccentLine.Parent         = TitleBar

local _accentGrad = Instance.new("UIGradient")
_accentGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   T.accent1),
    ColorSequenceKeypoint.new(0.5, T.accent2),
    ColorSequenceKeypoint.new(1,   T.accent3),
})
_accentGrad.Parent = AccentLine

-- Animate gradient offset for shimmer effect
task.spawn(function()
    local t = 0
    while _scriptRunning and AccentLine.Parent do
        t = t + 0.015
        _accentGrad.Offset = Vector2.new(math.sin(t) * 0.5, 0)
        task.wait(0.05)
    end
end)

-- Title icon + text
local TitleIcon = Instance.new("TextLabel")
TitleIcon.Size               = UDim2.new(0, 28, 1, 0)
TitleIcon.Position           = UDim2.new(0, 10, 0, 0)
TitleIcon.BackgroundTransparency = 1
TitleIcon.Text               = "🌱"
TitleIcon.TextSize           = 18
TitleIcon.Font               = Enum.Font.GothamBold
TitleIcon.ZIndex             = 4
TitleIcon.Parent             = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size              = UDim2.new(1, -120, 1, 0)
TitleLabel.Position          = UDim2.new(0, 42, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text              = "Devo GAG2  ·  by bebe Ed"
TitleLabel.TextColor3        = T.textPrimary
TitleLabel.TextSize          = 14
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.ZIndex            = 4
TitleLabel.Parent            = TitleBar

local VersionBadge = Instance.new("TextLabel")
VersionBadge.Size            = UDim2.new(0, 34, 0, 16)
VersionBadge.Position        = UDim2.new(0, 42, 0.5, -8)
-- offset from TitleLabel right -- we do it inline with position
VersionBadge.AnchorPoint     = Vector2.new(0, 0.5)
-- nudge it next to the title text
VersionBadge.Position        = UDim2.new(0, 200, 0.5, 0)
VersionBadge.BackgroundColor3 = T.accent1
VersionBadge.Text            = "v2.1"
VersionBadge.TextColor3      = Color3.fromRGB(10, 30, 15)
VersionBadge.TextSize        = 10
VersionBadge.Font            = Enum.Font.GothamBold
VersionBadge.ZIndex          = 4
VersionBadge.BorderSizePixel = 0
VersionBadge.Parent          = TitleBar
local _vbCorner = Instance.new("UICorner")
_vbCorner.CornerRadius = UDim.new(0, 4)
_vbCorner.Parent       = VersionBadge

-- Minimize button (styled pill)
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 28, 0, 28)
MinBtn.Position         = UDim2.new(1, -66, 0.5, -14)
MinBtn.BackgroundColor3 = T.bg3
MinBtn.Text             = "–"
MinBtn.TextColor3       = T.textSecondary
MinBtn.TextSize         = 16
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 4
MinBtn.Parent           = TitleBar
local _minC = Instance.new("UICorner")
_minC.CornerRadius = UDim.new(0, 8)
_minC.Parent       = MinBtn
local _minS = Instance.new("UIStroke")
_minS.Color     = T.stroke
_minS.Thickness = 1
_minS.Parent    = MinBtn

-- Close button (red)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size             = UDim2.new(0, 28, 0, 28)
CloseBtn.Position         = UDim2.new(1, -32, 0.5, -14)
CloseBtn.BackgroundColor3 = T.danger
CloseBtn.Text             = "✕"
CloseBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize         = 12
CloseBtn.Font             = Enum.Font.GothamBold
CloseBtn.BorderSizePixel  = 0
CloseBtn.ZIndex           = 4
CloseBtn.Parent           = TitleBar
local _closeC = Instance.new("UICorner")
_closeC.CornerRadius = UDim.new(0, 8)
_closeC.Parent       = CloseBtn
local _closeS = Instance.new("UIStroke")
_closeS.Color     = Color3.fromRGB(240, 80, 80)
_closeS.Thickness = 1
_closeS.Parent    = CloseBtn

-- Button hover effects
for _, btn in ipairs({MinBtn, CloseBtn}) do
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = btn == CloseBtn and Color3.fromRGB(230, 70, 70) or T.bg4
        }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), {
            BackgroundColor3 = btn == CloseBtn and T.danger or T.bg3
        }):Play()
    end)
end

-- Minimize logic — [FIX 2]: do NOT re-assign ContentFrame from FindFirstChild
local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    -- Hide/show all children except title bar and non-visual stuff
    for _, child in pairs(MainFrame:GetChildren()) do
        if child ~= TitleBar and child ~= Shadow
        and not child:IsA("UICorner") and not child:IsA("UIStroke")
        and not child:IsA("UISizeConstraint") then
            child.Visible = not isMinimized
        end
    end
    MainFrame.Size = isMinimized
        and UDim2.new(0.9, 0, 0, 44)
        or  UDim2.new(0.9, 0, 0.85, 0)
    MinBtn.Text = isMinimized and "+" or "–"
end)

MakeDraggable(TitleBar, MainFrame)

-- ==========================================
-- TAB BAR
-- ==========================================
local TabBar = Instance.new("Frame")
TabBar.Name             = "TabBar"
TabBar.Size             = UDim2.new(1, 0, 0, 38)
TabBar.Position         = UDim2.new(0, 0, 0, 44)
TabBar.BackgroundColor3 = T.bg0
TabBar.BorderSizePixel  = 0
TabBar.ClipsDescendants = true
TabBar.ZIndex           = 2
TabBar.Parent           = MainFrame

local _tabLayout = Instance.new("UIListLayout")
_tabLayout.FillDirection = Enum.FillDirection.Horizontal
_tabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
_tabLayout.Padding       = UDim.new(0, 0)
_tabLayout.Parent        = TabBar

-- Thin separator line under tab bar
local TabSep = Instance.new("Frame")
TabSep.Size             = UDim2.new(1, 0, 0, 1)
TabSep.Position         = UDim2.new(0, 0, 1, -1)
TabSep.BackgroundColor3 = T.stroke
TabSep.BorderSizePixel  = 0
TabSep.Parent           = TabBar

-- ==========================================
-- SCROLL CONTENT AREA
-- ==========================================
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Name                = "ContentScroll"
ContentFrame.Size                = UDim2.new(1, -14, 1, -102)
ContentFrame.Position            = UDim2.new(0, 7, 0, 86)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ScrollBarThickness  = 3
ContentFrame.ScrollBarImageColor3 = T.accent1
ContentFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
ContentFrame.BorderSizePixel     = 0
ContentFrame.ScrollingDirection  = Enum.ScrollingDirection.Y
ContentFrame.Parent              = MainFrame

-- ==========================================
-- STATUS BAR (fixed at bottom, outside scroll)
-- ==========================================
local StatusBar = Instance.new("Frame")
StatusBar.Name             = "StatusBar"
StatusBar.Size             = UDim2.new(1, 0, 0, 16)
StatusBar.Position         = UDim2.new(0, 0, 1, -16)
StatusBar.BackgroundColor3 = T.bg0
StatusBar.BorderSizePixel  = 0
StatusBar.ZIndex           = 3
StatusBar.Parent           = MainFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size             = UDim2.new(1, -12, 1, 0)
StatusLabel.Position         = UDim2.new(0, 6, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text             = "⏳ Script Active | Waiting..."
StatusLabel.TextColor3       = T.textMuted
StatusLabel.TextSize         = 10
StatusLabel.Font             = Enum.Font.Gotham
StatusLabel.TextXAlignment   = Enum.TextXAlignment.Left
StatusLabel.ZIndex           = 3
StatusLabel.Parent           = StatusBar

-- ==========================================
-- TAB SYSTEM
-- ==========================================
local TabNames = {"Main", "Steal", "Defense", "Shop", "Weather", "Info"}
local TabIcons = {"🌱",   "🥷",    "🛡️",      "🏪",   "🌤️",     "ℹ️"}

local function SwitchTab(tabName)
    -- Hide all content panels
    for _, child in pairs(ContentFrame:GetChildren()) do
        if child:IsA("Frame") then child.Visible = false end
    end
    -- Show target
    local panel = ContentFrame:FindFirstChild(tabName)
    if panel then panel.Visible = true end
    -- Reset scroll
    ContentFrame.CanvasPosition = Vector2.new(0, 0)
    -- Update tab button styles
    for _, btn in pairs(TabBar:GetChildren()) do
        if btn:IsA("TextButton") then
            local isActive = btn.Name == tabName
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = isActive and T.bg4 or T.bg0,
                TextColor3       = isActive and T.textAccent or T.textMuted,
            }):Play()
            -- Move underline indicator
            local ind = btn:FindFirstChild("ActiveIndicator")
            if ind then
                ind.BackgroundTransparency = isActive and 0 or 1
            end
        end
    end
end

for i, tabName in ipairs(TabNames) do
    local tabBtn = Instance.new("TextButton")
    tabBtn.Name             = tabName
    tabBtn.Size             = UDim2.new(1 / #TabNames, 0, 1, 0)
    tabBtn.LayoutOrder      = i
    tabBtn.BackgroundColor3 = i == 1 and T.bg4 or T.bg0
    tabBtn.Text             = TabIcons[i] .. "\n" .. tabName
    tabBtn.TextColor3       = i == 1 and T.textAccent or T.textMuted
    tabBtn.TextSize         = 9
    tabBtn.Font             = Enum.Font.GothamSemibold
    tabBtn.BorderSizePixel  = 0
    tabBtn.TextTruncate     = Enum.TextTruncate.AtEnd
    tabBtn.LineHeight       = 1.1
    tabBtn.ZIndex           = 2
    tabBtn.Parent           = TabBar

    -- Active underline indicator
    local indicator = Instance.new("Frame")
    indicator.Name              = "ActiveIndicator"
    indicator.Size              = UDim2.new(0.7, 0, 0, 2)
    indicator.Position          = UDim2.new(0.15, 0, 1, -2)
    indicator.BackgroundColor3  = T.accent1
    indicator.BorderSizePixel   = 0
    indicator.BackgroundTransparency = i == 1 and 0 or 1
    indicator.ZIndex            = 3
    indicator.Parent            = tabBtn
    local _indCorner = Instance.new("UICorner")
    _indCorner.CornerRadius = UDim.new(0, 1)
    _indCorner.Parent       = indicator

    tabBtn.MouseButton1Click:Connect(function() SwitchTab(tabName) end)
    tabBtn.MouseEnter:Connect(function()
        if tabBtn.TextColor3 == T.textMuted then
            TweenService:Create(tabBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = T.bg3
            }):Play()
        end
    end)
    tabBtn.MouseLeave:Connect(function()
        if tabBtn.TextColor3 == T.textMuted then
            TweenService:Create(tabBtn, TweenInfo.new(0.1), {
                BackgroundColor3 = T.bg0
            }):Play()
        end
    end)
end

-- ==========================================
-- UI COMPONENT HELPERS
-- ==========================================
local _rowOrder = 0

-- Section header
local function MakeSection(parent, title, iconEmoji, color)
    _rowOrder = _rowOrder + 1
    local wrap = Instance.new("Frame")
    wrap.Name               = "Section_" .. _rowOrder
    wrap.Size               = UDim2.new(1, 0, 0, 28)
    wrap.BackgroundTransparency = 1
    wrap.LayoutOrder        = _rowOrder
    wrap.Parent             = parent

    local line = Instance.new("Frame")
    line.Size               = UDim2.new(1, 0, 0, 1)
    line.Position           = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3   = T.stroke
    line.BorderSizePixel    = 0
    line.Parent             = wrap

    local badge = Instance.new("TextLabel")
    badge.Size              = UDim2.new(0, 0, 0, 20)
    badge.AutomaticSize     = Enum.AutomaticSize.X
    badge.Position          = UDim2.new(0, 0, 0.5, -10)
    badge.BackgroundColor3  = T.bg1
    badge.Text              = "  " .. (iconEmoji or "") .. "  " .. title:upper() .. "  "
    badge.TextColor3        = color or T.textSecondary
    badge.TextSize          = 10
    badge.Font              = Enum.Font.GothamBold
    badge.BorderSizePixel   = 0
    badge.Parent            = wrap
    local _badgeCorner = Instance.new("UICorner")
    _badgeCorner.CornerRadius = UDim.new(0, 3)
    _badgeCorner.Parent       = badge
end

-- Info label (single line)
local function MakeLabel(parent, text, color, size)
    _rowOrder = _rowOrder + 1
    local row = Instance.new("Frame")
    row.Name            = "Row_" .. _rowOrder
    row.Size            = UDim2.new(1, 0, 0, text == "" and 6 or (size or 20))
    row.BackgroundTransparency = 1
    row.LayoutOrder     = _rowOrder
    row.Parent          = parent

    if text ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Size            = UDim2.new(1, 0, 1, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text            = text
        lbl.TextColor3      = color or T.textSecondary
        lbl.TextSize        = size or 12
        lbl.Font            = Enum.Font.Gotham
        lbl.TextXAlignment  = Enum.TextXAlignment.Left  -- [FIX 7]
        lbl.Parent          = row
        return lbl
    end
    return nil
end

-- Toggle row
-- Returns: toggleBtn (click target), getter function
local function MakeToggle(parent, name, desc, default)
    _rowOrder = _rowOrder + 1
    local row = Instance.new("Frame")
    row.Name            = "Toggle_" .. _rowOrder
    row.Size            = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = T.bg3
    row.BorderSizePixel = 0
    row.LayoutOrder     = _rowOrder
    row.Parent          = parent
    local _rowC = Instance.new("UICorner")
    _rowC.CornerRadius = UDim.new(0, 8)
    _rowC.Parent       = row
    local _rowS = Instance.new("UIStroke")
    _rowS.Color     = T.stroke
    _rowS.Thickness = 1
    _rowS.Parent    = row

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size           = UDim2.new(1, -70, 0, 22)
    nameLabel.Position       = UDim2.new(0, 12, 0, 7)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text           = name
    nameLabel.TextColor3     = T.textPrimary
    nameLabel.TextSize       = 13
    nameLabel.Font           = Enum.Font.GothamSemibold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent         = row

    local descLabel = Instance.new("TextLabel")
    descLabel.Size           = UDim2.new(1, -70, 0, 16)
    descLabel.Position       = UDim2.new(0, 12, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text           = desc
    descLabel.TextColor3     = T.textMuted
    descLabel.TextSize       = 10
    descLabel.Font           = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.Parent         = row

    -- Toggle track
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 46, 0, 24)
    track.Position         = UDim2.new(1, -58, 0.5, -12)
    track.BackgroundColor3 = default and T.toggleOn or T.toggleOff
    track.BorderSizePixel  = 0
    track.Parent           = row
    local _trackC = Instance.new("UICorner")
    _trackC.CornerRadius = UDim.new(0, 12)
    _trackC.Parent       = track
    local _trackS = Instance.new("UIStroke")
    _trackS.Color     = default and T.accent1 or T.stroke
    _trackS.Thickness = 1
    _trackS.Parent    = track

    -- Transparent click overlay (full row)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size             = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text             = ""
    toggleBtn.Parent           = row

    -- Knob
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 18, 0, 18)
    knob.Position         = default and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 2
    knob.Parent           = track
    local _knobC = Instance.new("UICorner")
    _knobC.CornerRadius = UDim.new(0, 9)
    _knobC.Parent       = knob

    local state = default

    toggleBtn.MouseButton1Click:Connect(function()
        state = not state
        local ti = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(track, ti, {
            BackgroundColor3 = state and T.toggleOn or T.toggleOff
        }):Play()
        TweenService:Create(_trackS, ti, {
            Color = state and T.accent1 or T.stroke
        }):Play()
        TweenService:Create(knob, ti, {
            Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        }):Play()
        -- Flash row bg briefly
        TweenService:Create(row, TweenInfo.new(0.1), {
            BackgroundColor3 = state and Color3.fromRGB(30, 55, 38) or T.bg3
        }):Play()
        task.delay(0.25, function()
            TweenService:Create(row, TweenInfo.new(0.2), {
                BackgroundColor3 = T.bg3
            }):Play()
        end)
    end)

    return toggleBtn, function() return state end
end

-- Card widget (for weather/info cards)
local function MakeCard(parent, order, h)
    _rowOrder = _rowOrder + 1
    local card = Instance.new("Frame")
    card.Name            = "Card_" .. _rowOrder
    card.Size            = UDim2.new(1, 0, 0, h or 40)
    card.BackgroundColor3 = T.bg3
    card.BorderSizePixel = 0
    card.LayoutOrder     = order or _rowOrder
    card.Parent          = parent
    local _cC = Instance.new("UICorner")
    _cC.CornerRadius = UDim.new(0, 8)
    _cC.Parent       = card
    local _cS = Instance.new("UIStroke")
    _cS.Color     = T.stroke
    _cS.Thickness = 1
    _cS.Parent    = card
    return card
end

-- ==========================================
-- TAB: MAIN
-- ==========================================
local MainTab = Instance.new("Frame")
MainTab.Name            = "Main"
MainTab.Size            = UDim2.new(1, 0, 0, 0)
MainTab.AutomaticSize   = Enum.AutomaticSize.Y
MainTab.BackgroundTransparency = 1
MainTab.Parent          = ContentFrame

local _mainTL = Instance.new("UIListLayout")
_mainTL.SortOrder  = Enum.SortOrder.LayoutOrder
_mainTL.Padding    = UDim.new(0, 5)
_mainTL.Parent     = MainTab

local _mainPad = Instance.new("UIPadding")
_mainPad.PaddingTop    = UDim.new(0, 6)
_mainPad.PaddingBottom = UDim.new(0, 8)
_mainPad.Parent        = MainTab

MakeSection(MainTab, "Automation", "⚡", T.success)
local _, getAutoCollect = MakeToggle(MainTab, "Auto-Collect Events",    "Golden, Rainbow, Bird & Seed Packs", true)

-- [FIX 1]: getWeatherNotif is now a real toggle (was hardcoded `function() return true end`)
local _, getWeatherNotif = MakeToggle(MainTab, "Weather Notifications", "Show weather change alerts",          true)
local _, getShopNotif    = MakeToggle(MainTab, "Shop Predictions",      "Track seed shop rotations",           true)

MakeSection(MainTab, "Defense", "🛡️", T.danger)
local _, getAutoDefense = MakeToggle(MainTab, "Auto Defense",       "Auto-attack thieves in your base",      true)
local _, getAutoStay    = MakeToggle(MainTab, "Auto Stay at Base",  "Return to base at night",               true)

MakeSection(MainTab, "Utilities", "🔧", T.warning)
local _, getAntiAFK   = MakeToggle(MainTab, "Anti-AFK",            "Prevent Roblox kick",                   true)
local _, getAntiPause = MakeToggle(MainTab, "Anti Gameplay Pause", "Prevent game freeze/pause",             true)
local _, getAutoSkip  = MakeToggle(MainTab, "Auto Skip Cutscenes", "Skip intro & event cutscenes",          true)

-- ==========================================
-- TAB: STEAL
-- ==========================================
local StealTab = Instance.new("Frame")
StealTab.Name            = "Steal"
StealTab.Size            = UDim2.new(1, 0, 0, 0)
StealTab.AutomaticSize   = Enum.AutomaticSize.Y
StealTab.BackgroundTransparency = 1
StealTab.Visible         = false
StealTab.Parent          = ContentFrame

local _stealTL = Instance.new("UIListLayout")
_stealTL.SortOrder = Enum.SortOrder.LayoutOrder
_stealTL.Padding   = UDim.new(0, 5)
_stealTL.Parent    = StealTab

local _stealPad = Instance.new("UIPadding")
_stealPad.PaddingTop    = UDim.new(0, 6)
_stealPad.PaddingBottom = UDim.new(0, 8)
_stealPad.Parent        = StealTab

MakeSection(StealTab, "Stealing Controls", "🥷", Color3.fromRGB(180, 80, 220))

local _, getAutoSteal      = MakeToggle(StealTab, "Auto Steal (Night)", "Steal crops from other bases at night", false)
local _, getStealHighValue = MakeToggle(StealTab, "High Value Only",    "Only target rare/epic/legendary crops",  true)
local _, getAutoAttackOwner = MakeToggle(StealTab, "Attack Plot Owner", "Attack owners while stealing",          false)

MakeSection(StealTab, "Info", "ℹ️", T.textSecondary)
MakeLabel(StealTab, "Invades other gardens during Night cycle.", T.textSecondary, 11)
MakeLabel(StealTab, "Overrides Auto Stay Base while active.", Color3.fromRGB(200, 150, 200), 11)

-- ==========================================
-- TAB: DEFENSE
-- ==========================================
local DefenseTab = Instance.new("Frame")
DefenseTab.Name            = "Defense"
DefenseTab.Size            = UDim2.new(1, 0, 0, 0)
DefenseTab.AutomaticSize   = Enum.AutomaticSize.Y
DefenseTab.BackgroundTransparency = 1
DefenseTab.Visible         = false
DefenseTab.Parent          = ContentFrame

local _defTL = Instance.new("UIListLayout")
_defTL.SortOrder = Enum.SortOrder.LayoutOrder
_defTL.Padding   = UDim.new(0, 5)
_defTL.Parent    = DefenseTab

local _defPad = Instance.new("UIPadding")
_defPad.PaddingTop    = UDim.new(0, 6)
_defPad.PaddingBottom = UDim.new(0, 8)
_defPad.Parent        = DefenseTab

MakeSection(DefenseTab, "Weapon Priority", "⚔️", T.danger)

local weapons = {
    {"🧊 Freeze Ray",  "Premium — 749 Robux",  T.info},
    {"💧 Power Hose",  "Premium — 299 Robux",  T.accent2},
    {"🔧 Crowbar",     "Rare — Gear Shop",     T.warning},
    {"⛏️ Shovel",      "Default — Free",        T.success},
}
for _, w in ipairs(weapons) do
    local card = MakeCard(DefenseTab, nil, 42)
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 36, 1, 0)
    icon.BackgroundTransparency = 1
    icon.Text = w[1]:sub(1, 2) -- emoji only
    icon.TextSize = 18
    icon.Font = Enum.Font.GothamBold
    icon.TextColor3 = w[3]
    icon.Parent = card
    local wname = Instance.new("TextLabel")
    wname.Size = UDim2.new(0.55, 0, 0, 20)
    wname.Position = UDim2.new(0, 36, 0, 5)
    wname.BackgroundTransparency = 1
    wname.Text = w[1]:sub(4) -- name without emoji
    wname.TextSize = 12
    wname.Font = Enum.Font.GothamSemibold
    wname.TextColor3 = T.textPrimary
    wname.TextXAlignment = Enum.TextXAlignment.Left
    wname.Parent = card
    local wdesc = Instance.new("TextLabel")
    wdesc.Size = UDim2.new(0.55, 0, 0, 16)
    wdesc.Position = UDim2.new(0, 36, 0, 22)
    wdesc.BackgroundTransparency = 1
    wdesc.Text = w[2]
    wdesc.TextSize = 10
    wdesc.Font = Enum.Font.Gotham
    wdesc.TextColor3 = T.textMuted
    wdesc.TextXAlignment = Enum.TextXAlignment.Left
    wdesc.Parent = card
    local wpill = Instance.new("TextLabel")
    wpill.Size = UDim2.new(0, 38, 0, 18)
    wpill.Position = UDim2.new(1, -46, 0.5, -9)
    wpill.BackgroundColor3 = w[3]
    wpill.Text = "AUTO"
    wpill.TextSize = 9
    wpill.Font = Enum.Font.GothamBold
    wpill.TextColor3 = Color3.fromRGB(8, 8, 12)
    wpill.BorderSizePixel = 0
    wpill.Parent = card
    local _pc = Instance.new("UICorner")
    _pc.CornerRadius = UDim.new(0, 4)
    _pc.Parent = wpill
end

MakeSection(DefenseTab, "How It Works", "ℹ️", T.textSecondary)
MakeLabel(DefenseTab, "Auto-detects players in your garden area", T.textSecondary, 11)
MakeLabel(DefenseTab, "and equips the best available weapon.", T.textSecondary, 11)

-- ==========================================
-- TAB: SHOP
-- ==========================================
local ShopTab = Instance.new("Frame")
ShopTab.Name            = "Shop"
ShopTab.Size            = UDim2.new(1, 0, 0, 0)
ShopTab.AutomaticSize   = Enum.AutomaticSize.Y
ShopTab.BackgroundTransparency = 1
ShopTab.Visible         = false
ShopTab.Parent          = ContentFrame

local _shopTL = Instance.new("UIListLayout")
_shopTL.SortOrder = Enum.SortOrder.LayoutOrder
_shopTL.Padding   = UDim.new(0, 4)
_shopTL.Parent    = ShopTab

local _shopPad = Instance.new("UIPadding")
_shopPad.PaddingTop    = UDim.new(0, 6)
_shopPad.PaddingBottom = UDim.new(0, 8)
_shopPad.Parent        = ShopTab

-- Restock header card
_rowOrder = _rowOrder + 1
local RestockCard = MakeCard(ShopTab, _rowOrder, 40)
RestockCard.BackgroundColor3 = Color3.fromRGB(42, 35, 14)
local _rsg = Instance.new("UIGradient")
_rsg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(50, 42, 16)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(35, 28, 10)),
})
_rsg.Rotation = 90
_rsg.Parent = RestockCard

local ShopPredictLabel = Instance.new("TextLabel")
ShopPredictLabel.Size = UDim2.new(1, -16, 1, 0)
ShopPredictLabel.Position = UDim2.new(0, 8, 0, 0)
ShopPredictLabel.BackgroundTransparency = 1
ShopPredictLabel.Text = "🔄 Next Restock: --:--"
ShopPredictLabel.TextColor3 = T.warning
ShopPredictLabel.TextSize = 14
ShopPredictLabel.Font = Enum.Font.GothamBold
ShopPredictLabel.TextXAlignment = Enum.TextXAlignment.Left
ShopPredictLabel.Parent = RestockCard

-- Seed data
local SeedData = {
    {name="Carrot",       emoji="🥕", rarity="Common",    cycle=5},
    {name="Strawberry",   emoji="🍓", rarity="Common",    cycle=5},
    {name="Blueberry",    emoji="🔵", rarity="Common",    cycle=5},
    {name="Tulip",        emoji="🌷", rarity="Uncommon",  cycle=10},
    {name="Tomato",       emoji="🍅", rarity="Uncommon",  cycle=10},
    {name="Apple",        emoji="🍎", rarity="Uncommon",  cycle=10},
    {name="Bamboo",       emoji="🎋", rarity="Rare",      cycle=20},
    {name="Corn",         emoji="🌽", rarity="Rare",      cycle=20},
    {name="Cactus",       emoji="🌵", rarity="Rare",      cycle=20},
    {name="Pineapple",    emoji="🍍", rarity="Rare",      cycle=20},
    {name="Mushroom",     emoji="🍄", rarity="Epic",      cycle=45},
    {name="Banana",       emoji="🍌", rarity="Epic",      cycle=45},
    {name="Grape",        emoji="🍇", rarity="Epic",      cycle=45},
    {name="Coconut",      emoji="🥥", rarity="Epic",      cycle=45},
    {name="Mango",        emoji="🥭", rarity="Epic",      cycle=45},
    {name="Green Bean",   emoji="🌿", rarity="Epic",      cycle=45},
    {name="Dragon Fruit", emoji="🐉", rarity="Legendary", cycle=90},
    {name="Acorn",        emoji="🌰", rarity="Legendary", cycle=90},
    {name="Cherry",       emoji="🍒", rarity="Legendary", cycle=90},
    {name="Sunflower",    emoji="🌻", rarity="Legendary", cycle=90},
    {name="Venus Flytrap",emoji="🕷️", rarity="Mythic",    cycle=180},
    {name="Pomegranate",  emoji="🔴", rarity="Mythic",    cycle=180},
    {name="Moon Bloom",   emoji="💮", rarity="Super",     cycle=240},
    {name="Dragon's Breath",emoji="🔥",rarity="Super",    cycle=240},
}

local RarityColors = {
    Common   = Color3.fromRGB(180,180,180),
    Uncommon = Color3.fromRGB(80, 200, 80),
    Rare     = Color3.fromRGB(60, 140,255),
    Epic     = Color3.fromRGB(180, 80,255),
    Legendary= Color3.fromRGB(255,180, 40),
    Mythic   = Color3.fromRGB(255, 60, 80),
    Super    = Color3.fromRGB(0,  240,240),
}
local RarityBG = {
    Common   = Color3.fromRGB(38,38,48),
    Uncommon = Color3.fromRGB(28,48,28),
    Rare     = Color3.fromRGB(22,32,58),
    Epic     = Color3.fromRGB(42,22,58),
    Legendary= Color3.fromRGB(52,42,18),
    Mythic   = Color3.fromRGB(52,18,22),
    Super    = Color3.fromRGB(18,52,58),
}

local seedTimerLabels = {}
local curRarity = ""
for i, seed in ipairs(SeedData) do
    if seed.rarity ~= curRarity then
        curRarity = seed.rarity
        _rowOrder = _rowOrder + 1
        local hdr = Instance.new("Frame")
        hdr.Name = "RarHdr_" .. seed.rarity
        hdr.Size = UDim2.new(1, 0, 0, 20)
        hdr.BackgroundTransparency = 1
        hdr.LayoutOrder = _rowOrder
        hdr.Parent = ShopTab
        local hl = Instance.new("TextLabel")
        hl.Size = UDim2.new(1, 0, 1, 0)
        hl.BackgroundTransparency = 1
        hl.Text = "▸ " .. seed.rarity:upper()
        hl.TextColor3 = RarityColors[seed.rarity]
        hl.TextSize = 11
        hl.Font = Enum.Font.GothamBold
        hl.TextXAlignment = Enum.TextXAlignment.Left
        hl.Parent = hdr
    end

    _rowOrder = _rowOrder + 1
    local row = Instance.new("Frame")
    row.Name = "Seed_" .. seed.name
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = RarityBG[seed.rarity]
    row.BorderSizePixel = 0
    row.LayoutOrder = _rowOrder
    row.Parent = ShopTab
    local _rrc = Instance.new("UICorner")
    _rrc.CornerRadius = UDim.new(0, 5)
    _rrc.Parent = row

    local nameL = Instance.new("TextLabel")
    nameL.Size = UDim2.new(0.55, 0, 1, 0)
    nameL.Position = UDim2.new(0, 8, 0, 0)
    nameL.BackgroundTransparency = 1
    nameL.Text = seed.emoji .. " " .. seed.name
    nameL.TextColor3 = RarityColors[seed.rarity]
    nameL.TextSize = 11
    nameL.Font = Enum.Font.GothamSemibold
    nameL.TextXAlignment = Enum.TextXAlignment.Left
    nameL.Parent = row

    local timerL = Instance.new("TextLabel")
    timerL.Name = "Timer"
    timerL.Size = UDim2.new(0.42, 0, 1, 0)
    timerL.Position = UDim2.new(0.55, 0, 0, 0)
    timerL.BackgroundTransparency = 1
    timerL.Text = "In --:--"
    timerL.TextColor3 = T.textSecondary
    timerL.TextSize = 10
    timerL.Font = Enum.Font.GothamSemibold
    timerL.TextXAlignment = Enum.TextXAlignment.Right
    timerL.Parent = row

    seedTimerLabels[i] = {label = timerL, data = seed, row = row}
end

-- ==========================================
-- TAB: WEATHER
-- ==========================================
local WeatherTab = Instance.new("Frame")
WeatherTab.Name            = "Weather"
WeatherTab.Size            = UDim2.new(1, 0, 0, 0)
WeatherTab.AutomaticSize   = Enum.AutomaticSize.Y
WeatherTab.BackgroundTransparency = 1
WeatherTab.Visible         = false
WeatherTab.Parent          = ContentFrame

local _wxTL = Instance.new("UIListLayout")
_wxTL.SortOrder = Enum.SortOrder.LayoutOrder
_wxTL.Padding   = UDim.new(0, 5)
_wxTL.Parent    = WeatherTab

local _wxPad = Instance.new("UIPadding")
_wxPad.PaddingTop    = UDim.new(0, 6)
_wxPad.PaddingBottom = UDim.new(0, 8)
_wxPad.Parent        = WeatherTab

-- Current weather row
_rowOrder = _rowOrder + 1
local CurrWxCard = MakeCard(WeatherTab, _rowOrder, 44)
CurrWxCard.BackgroundColor3 = Color3.fromRGB(28, 38, 55)

local WeatherLabel = Instance.new("TextLabel")
WeatherLabel.Size = UDim2.new(0.6, 0, 1, 0)
WeatherLabel.Position = UDim2.new(0, 10, 0, 0)
WeatherLabel.BackgroundTransparency = 1
WeatherLabel.Text = "☀️  Day"
WeatherLabel.TextColor3 = Color3.fromRGB(255, 240, 140)
WeatherLabel.TextSize = 15
WeatherLabel.Font = Enum.Font.GothamBold
WeatherLabel.TextXAlignment = Enum.TextXAlignment.Left
WeatherLabel.Parent = CurrWxCard

local WeatherTimerLabel = Instance.new("TextLabel")
WeatherTimerLabel.Size = UDim2.new(0.38, 0, 1, 0)
WeatherTimerLabel.Position = UDim2.new(0.62, 0, 0, 0)
WeatherTimerLabel.BackgroundTransparency = 1
WeatherTimerLabel.Text = "--:-- left"
WeatherTimerLabel.TextColor3 = T.textSecondary
WeatherTimerLabel.TextSize = 12
WeatherTimerLabel.Font = Enum.Font.GothamSemibold
WeatherTimerLabel.TextXAlignment = Enum.TextXAlignment.Right
WeatherTimerLabel.Parent = CurrWxCard

-- Next weather row
_rowOrder = _rowOrder + 1
local NextWxCard = MakeCard(WeatherTab, _rowOrder, 30)
NextWxCard.BackgroundColor3 = Color3.fromRGB(24, 32, 46)

local NextWeatherLabel = Instance.new("TextLabel")
NextWeatherLabel.Size = UDim2.new(1, -16, 1, 0)
NextWeatherLabel.Position = UDim2.new(0, 8, 0, 0)
NextWeatherLabel.BackgroundTransparency = 1
NextWeatherLabel.Text = "Next: ⏳ Calculating..."
NextWeatherLabel.TextColor3 = Color3.fromRGB(180, 255, 200)
NextWeatherLabel.TextSize = 11
NextWeatherLabel.Font = Enum.Font.GothamSemibold
NextWeatherLabel.TextXAlignment = Enum.TextXAlignment.Left
NextWeatherLabel.Parent = NextWxCard

MakeSection(WeatherTab, "Forecast", "🗓️", T.info)

-- [FIX 6]: Weather cards now use UIGridLayout inside a container frame
-- instead of absolute-positioned cards which clipped on narrow screens
local weatherCardLabels = {}

local weatherCardDefs = {
    {"Day",          "☀️",  Color3.fromRGB(255,220,60)},
    {"Moon",         "🌙",  Color3.fromRGB(160,160,220)},
    {"Goldmoon",     "🌟",  Color3.fromRGB(255,200,40)},
    {"Bloodmoon",    "🌑",  Color3.fromRGB(200,40,40)},
    {"Rainbow Moon", "🌈",  Color3.fromRGB(120,220,255)},
    {"Rain",         "🌧️", Color3.fromRGB(100,160,255)},
    {"Lightning",    "⚡",  Color3.fromRGB(255,230,60)},
    {"Snowfall",     "❄️",  Color3.fromRGB(200,230,255)},
    {"Rainbow",      "🌈",  Color3.fromRGB(120,220,180)},
    {"Starfall",     "⭐",  Color3.fromRGB(240,220,100)},
}

_rowOrder = _rowOrder + 1
local WxGrid = Instance.new("Frame")
WxGrid.Name = "WxGrid"
WxGrid.Size = UDim2.new(1, 0, 0, 0)
WxGrid.AutomaticSize = Enum.AutomaticSize.Y
WxGrid.BackgroundTransparency = 1
WxGrid.LayoutOrder = _rowOrder
WxGrid.Parent = WeatherTab

local _wxGrid = Instance.new("UIGridLayout")
_wxGrid.CellSize    = UDim2.new(0.5, -4, 0, 72)
_wxGrid.CellPadding = UDim2.new(0, 4, 0, 4)
_wxGrid.SortOrder   = Enum.SortOrder.LayoutOrder
_wxGrid.Parent      = WxGrid

for idx, def in ipairs(weatherCardDefs) do
    local wname, wicon, wcolor = def[1], def[2], def[3]
    local card = Instance.new("Frame")
    card.Name = "WxCard_" .. wname
    card.Size = UDim2.new(0.5, -4, 0, 72) -- grid overrides this
    card.BackgroundColor3 = Color3.fromRGB(28, 38, 58)
    card.BorderSizePixel = 0
    card.LayoutOrder = idx
    card.Parent = WxGrid
    local _cc = Instance.new("UICorner")
    _cc.CornerRadius = UDim.new(0, 8)
    _cc.Parent = card
    local _cs = Instance.new("UIStroke")
    _cs.Color     = T.stroke
    _cs.Thickness = 1
    _cs.Parent    = card

    local iconL = Instance.new("TextLabel")
    iconL.Size = UDim2.new(1, 0, 0, 28)
    iconL.Position = UDim2.new(0, 0, 0, 4)
    iconL.BackgroundTransparency = 1
    iconL.Text = wicon
    iconL.TextSize = 20
    iconL.Font = Enum.Font.GothamBold
    iconL.TextColor3 = Color3.fromRGB(255, 255, 255)
    iconL.Parent = card

    local nameL2 = Instance.new("TextLabel")
    nameL2.Size = UDim2.new(1, -8, 0, 16)
    nameL2.Position = UDim2.new(0, 4, 0, 30)
    nameL2.BackgroundTransparency = 1
    nameL2.Text = wname
    nameL2.TextSize = 11
    nameL2.Font = Enum.Font.GothamBold
    nameL2.TextColor3 = wcolor
    nameL2.TextWrapped = true
    nameL2.Parent = card

    local timerL2 = Instance.new("TextLabel")
    timerL2.Name = "WxTimer"
    timerL2.Size = UDim2.new(1, -8, 0, 16)
    timerL2.Position = UDim2.new(0, 4, 0, 50)
    timerL2.BackgroundTransparency = 1
    timerL2.Text = "--:--"
    timerL2.TextSize = 10
    timerL2.Font = Enum.Font.GothamSemibold
    timerL2.TextColor3 = Color3.fromRGB(180, 200, 255)
    timerL2.Parent = card

    weatherCardLabels[wname] = {label = timerL2, card = card, stroke = _cs, baseColor = Color3.fromRGB(28, 38, 58)}
end

-- Helper: update a weather card's active state
local function SetWxCardActive(wname, isActive)
    local entry = weatherCardLabels[wname]
    if not entry then return end
    local targetBG = isActive and Color3.fromRGB(30, 70, 34) or entry.baseColor
    local targetStroke = isActive and T.accent1 or T.stroke
    TweenService:Create(entry.card, TweenInfo.new(0.2), {BackgroundColor3 = targetBG}):Play()
    TweenService:Create(entry.stroke, TweenInfo.new(0.2), {Color = targetStroke}):Play()
    if isActive then
        entry.label.Text = "▶ NOW!"
        entry.label.TextColor3 = T.accent1
    end
end

-- ==========================================
-- TAB: INFO
-- ==========================================
local InfoTab = Instance.new("Frame")
InfoTab.Name            = "Info"
InfoTab.Size            = UDim2.new(1, 0, 0, 0)
InfoTab.AutomaticSize   = Enum.AutomaticSize.Y
InfoTab.BackgroundTransparency = 1
InfoTab.Visible         = false
InfoTab.Parent          = ContentFrame

local _infoTL = Instance.new("UIListLayout")
_infoTL.SortOrder = Enum.SortOrder.LayoutOrder
_infoTL.Padding   = UDim.new(0, 4)
_infoTL.Parent    = InfoTab

local _infoPad = Instance.new("UIPadding")
_infoPad.PaddingTop    = UDim.new(0, 6)
_infoPad.PaddingBottom = UDim.new(0, 8)
_infoPad.Parent        = InfoTab

-- Branding card
_rowOrder = _rowOrder + 1
local brandCard = MakeCard(InfoTab, _rowOrder, 60)
brandCard.BackgroundColor3 = Color3.fromRGB(18, 35, 22)
local _bg2 = Instance.new("UIGradient")
_bg2.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 42, 24)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 18, 14)),
})
_bg2.Rotation = 135
_bg2.Parent = brandCard
local brandTitle = Instance.new("TextLabel")
brandTitle.Size = UDim2.new(1, -20, 0, 28)
brandTitle.Position = UDim2.new(0, 10, 0, 6)
brandTitle.BackgroundTransparency = 1
brandTitle.Text = "🌱 Grow A Garden 2"
brandTitle.TextColor3 = T.accent1
brandTitle.TextSize = 16
brandTitle.Font = Enum.Font.GothamBold
brandTitle.TextXAlignment = Enum.TextXAlignment.Left
brandTitle.Parent = brandCard
local brandSub = Instance.new("TextLabel")
brandSub.Size = UDim2.new(1, -20, 0, 18)
brandSub.Position = UDim2.new(0, 10, 0, 34)
brandSub.BackgroundTransparency = 1
brandSub.Text = "Script by Devo  ·  bebe Ed Sheeran ♪"
brandSub.TextColor3 = T.textMuted
brandSub.TextSize = 11
brandSub.Font = Enum.Font.Gotham
brandSub.TextXAlignment = Enum.TextXAlignment.Left
brandSub.Parent = brandCard

MakeSection(InfoTab, "How to Use", "📋", T.warning)
MakeLabel(InfoTab, "1. Equip weapons from your inventory",    T.textSecondary, 11)
MakeLabel(InfoTab, "2. Toggle features on the Main tab",      T.textSecondary, 11)
MakeLabel(InfoTab, "3. Script auto-detects events & weather", T.textSecondary, 11)

MakeSection(InfoTab, "Features", "✅", T.success)
local feats = {
    "Event seed auto-collect (Golden, Rainbow, Birds)",
    "Weather prediction & real-time cycle tracking",
    "Seed shop rotation timer per rarity",
    "Auto-stay at base during Night phase",
    "Auto defense using priority weapon list",
    "Auto steal (Night only) with high-value filter",
    "Anti-AFK & cutscene skipper",
}
for _, f in ipairs(feats) do
    MakeLabel(InfoTab, "✅ " .. f, T.success, 11)
end

MakeSection(InfoTab, "Bug Fixes v2.1", "🔧", T.info)
local fixes = {
    "Weather toggle now works correctly",
    "Minimize no longer nulls ContentFrame",
    "TouchInterest detection fixed",
    "DescendantAdded validity guard added",
    "Weather cards use grid (no clipping)",
}
for _, f in ipairs(fixes) do
    MakeLabel(InfoTab, "→ " .. f, T.info, 10)
end

-- ==========================================
-- INITIALIZE — show Main tab
-- ==========================================
SwitchTab("Main")

-- ==========================================
-- CORE GAME LOGIC
-- ==========================================

-- Weather system data
local currentWeather  = "Day"
local weatherStartTime = tick()

local weatherDurations = {
    Day=160, Night=80, Rain=120, Lightning=120,
    Rainbow=120, Snowfall=120, Starfall=120,
    BloodMoon=80, GoldMoon=80, RainbowMoon=80,
}

local weatherIcons = {
    Day="☀️", Night="🌙", Rain="🌧️", Lightning="⚡",
    Rainbow="🌈", Snowfall="❄️", Starfall="⭐",
    BloodMoon="🌑", GoldMoon="🌟", RainbowMoon="🌈",
}

local function ReadGameWeather()
    local result = nil
    pcall(function()
        for _, a in ipairs({"Weather","CurrentWeather","GameWeather","WeatherType"}) do
            local v = Workspace:GetAttribute(a)
            if v and tostring(v) ~= "" then result = tostring(v) return end
        end
    end)
    if result then return result end
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local wo = rs:FindFirstChild("Weather") or rs:FindFirstChild("GameWeather") or rs:FindFirstChild("WeatherSystem")
        if wo then
            if wo:IsA("StringValue") then result = wo.Value
            elseif wo:IsA("Folder") or wo:IsA("Configuration") then
                local cur = wo:FindFirstChild("Current") or wo:FindFirstChild("Type") or wo:FindFirstChild("State")
                if cur and cur:IsA("StringValue") then result = cur.Value end
            end
            local v2 = wo:GetAttribute("Current") or wo:GetAttribute("Type")
            if v2 then result = tostring(v2) end
        end
    end)
    if result and result ~= "" then return result end
    pcall(function()
        for _, a in ipairs({"Weather","CurrentWeather","WeatherType"}) do
            local v = Lighting:GetAttribute(a)
            if v and tostring(v) ~= "" then result = tostring(v) return end
        end
    end)
    return result
end

local function ReadNextWeather()
    local result = nil
    pcall(function()
        for _, a in ipairs({"NextWeather","UpcomingWeather","NextEvent"}) do
            local v = Workspace:GetAttribute(a) or Lighting:GetAttribute(a)
            if v and tostring(v) ~= "" then result = tostring(v) return end
        end
    end)
    if result then return result end
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        local wo = rs:FindFirstChild("Weather") or rs:FindFirstChild("GameWeather") or rs:FindFirstChild("WeatherSystem")
        if wo then
            local nx = wo:FindFirstChild("Next") or wo:FindFirstChild("Upcoming")
            if nx and nx:IsA("StringValue") then result = nx.Value end
            local v2 = wo:GetAttribute("Next") or wo:GetAttribute("Upcoming")
            if v2 then result = tostring(v2) end
        end
    end)
    return result
end

local function NormalizeWeatherName(text)
    if not text then return nil end
    local t = text:lower():gsub("%s+","")
    if t=="bloodmoon" or t=="blood_moon" then return "BloodMoon" end
    if t=="goldmoon"  or t=="gold_moon"  or t=="midas" then return "GoldMoon" end
    if t=="rainbowmoon" or t=="rainbow_moon" then return "RainbowMoon" end
    if t=="lightning" or t=="thunder" or t=="thunderstorm" then return "Lightning" end
    if t=="rainbow" then return "Rainbow" end
    if t=="rain" or t=="rainy" then return "Rain" end
    if t=="snowfall" or t=="snow" or t=="blizzard" then return "Snowfall" end
    if t=="starfall" then return "Starfall" end
    if t=="night" or t=="moon" or t=="nighttime" then return "Night" end
    if t=="day" or t=="daytime" or t=="morning" or t=="sunny" then return "Day" end
    return nil
end

local function DetectWeather()
    local fromGame = NormalizeWeatherName(ReadGameWeather())
    if fromGame then return fromGame end

    local clockTime = Lighting.ClockTime or 12
    local isNight = (clockTime < 6 or clockTime >= 18)

    local activeEffect = nil
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") and v.Enabled then
                local n = (v.Name .. " " .. (v.Parent and v.Parent.Name or "")):lower()
                if n:find("thundereffect") or n:find("lightningeffect") or n:find("lightningbolt") then
                    activeEffect = "Lightning" break
                elseif (n:find("raineffect") or n:find("raindrop") or n:find("rainparticle")) and not n:find("rainbow") then
                    activeEffect = "Rain" break
                elseif n:find("snoweffect") or n:find("snowflake") or n:find("snowparticle") or n:find("blizzard") then
                    activeEffect = "Snowfall" break
                elseif n:find("starfalleffect") or n:find("fallingstar") then
                    activeEffect = "Starfall" break
                elseif (n:find("rainboweffect") or n:find("rainbowarc")) and not n:find("moon") then
                    activeEffect = "Rainbow" break
                end
            end
        end
    end)
    if activeEffect then return activeEffect end

    if isNight then
        local amb = Lighting.Ambient or Color3.new(0,0,0)
        if amb.R > 0.4 and amb.G < 0.08 and amb.B < 0.08 then return "BloodMoon" end
        if amb.R > 0.4 and amb.G > 0.3  and amb.B < 0.08 then return "GoldMoon" end
        return "Night"
    end
    return "Day"
end

local dynamicClockData = {
    lastClockTime   = Lighting.ClockTime or 12,
    lastTick        = tick(),
    secPerDayHour   = 160 / 12.0,
    secPerNightHour = 80  / 12.0,
}

local function UpdateClockSpeed()
    local ct  = Lighting.ClockTime or 12
    local now = tick()
    local dt  = now - dynamicClockData.lastTick
    if dt >= 1.0 then
        local dC = ct - dynamicClockData.lastClockTime
        if dC < -12 then dC = dC + 24 end
        if dC >  12 then dC = dC - 24 end
        if dC > 0 and dC < 2 then
            local sph = dt / dC
            if sph > 2 and sph < 100 then
                if ct >= 6 and ct < 18 then
                    dynamicClockData.secPerDayHour   = dynamicClockData.secPerDayHour   * 0.8 + sph * 0.2
                else
                    dynamicClockData.secPerNightHour = dynamicClockData.secPerNightHour * 0.8 + sph * 0.2
                end
            end
        end
        dynamicClockData.lastClockTime = ct
        dynamicClockData.lastTick      = now
        weatherDurations.Day       = math.floor(dynamicClockData.secPerDayHour   * 12)
        weatherDurations.Night     = math.floor(dynamicClockData.secPerNightHour * 12)
        weatherDurations.BloodMoon = weatherDurations.Night
        weatherDurations.GoldMoon  = weatherDurations.Night
        weatherDurations.RainbowMoon = weatherDurations.Night
    end
end

local function GetCycleTimeRemaining()
    local ct = Lighting.ClockTime or 12
    local SD = dynamicClockData.secPerDayHour
    local SN = dynamicClockData.secPerNightHour
    local timeToMoon, timeToDay
    if ct >= 6 and ct < 18 then
        local hl = 18 - ct
        timeToMoon = hl * SD
        timeToDay  = timeToMoon + 12 * SN
    else
        local hl = (ct >= 18) and (24 - ct + 6) or (6 - ct)
        timeToDay  = hl * SN
        timeToMoon = timeToDay + 12 * SD
    end
    return timeToMoon, timeToDay
end

-- Seed collector
local function FindEventSeeds()
    local seeds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local ok = false
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then ok=true
            elseif (name:find("rainbow") or name:find("rain")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then ok=true
            elseif name:find("bird") or name:find("crow") or name:find("pigeon") then ok=true
            elseif name:find("seed pack") or (name:find("seed") and name:find("pack")) then ok=true
            end
            if ok and (obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt")) then
                table.insert(seeds, obj)
            end
        end
    end
    return seeds
end

-- [FIX 3]: CollectSeed — corrected TouchTransmitter → TouchInterest check
local function CollectSeed(seedObj)
    pcall(function()
        -- 1. TouchInterest (correct child name, not TouchTransmitter)
        local touch = seedObj:FindFirstChild("TouchInterest")
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
        -- 2. ProximityPrompt
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
        -- 3. ClickDetector
        local detector = seedObj:FindFirstChildWhichIsA("ClickDetector")
        if detector and fireclickdetector then
            fireclickdetector(detector)
            return true
        end
        -- 4. RemoteEvent fallback
        for _, remote in pairs(seedObj:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                remote:FireServer(seedObj)
                return true
            end
        end
    end)
    return false
end

local function TeleportTo(pos)
    if RootPart then RootPart.CFrame = CFrame.new(pos) end
end

local myBasePosCache = nil
local lastCacheTime  = 0

local function FindMyBasePos()
    if myBasePosCache and (os.time() - lastCacheTime < 30) then return myBasePosCache end
    local pName   = LocalPlayer.Name
    local display = LocalPlayer.DisplayName
    local uid     = tostring(LocalPlayer.UserId)
    for _, obj in pairs(Workspace:GetDescendants()) do
        if (obj:IsA("Model") or obj:IsA("Folder")) and not obj:FindFirstChild("Humanoid") then
            local isMyBase = false
            local name = obj.Name
            if name == pName or name == display or name == uid then isMyBase = true end
            if not isMyBase then
                local oa = obj:GetAttribute("Owner")
                if tostring(oa) == pName or tostring(oa) == display or tostring(oa) == uid then isMyBase = true end
            end
            if not isMyBase then
                for _, vn in ipairs({"Owner","Player","PlayerName","owner","PlayerId"}) do
                    local ov = obj:FindFirstChild(vn)
                    if ov then
                        local val = tostring(ov.Value)
                        if val == pName or val == display or val == uid then isMyBase = true end
                        if ov:IsA("ObjectValue") and ov.Value == LocalPlayer then isMyBase = true end
                    end
                end
            end
            if not isMyBase then
                local ln = name:lower()
                if ln:find("garden") or ln:find("plot") or ln:find("base") or ln:find("tycoon") or ln:find("land") or ln:find("farm") then
                    for _, lbl in ipairs(obj:GetDescendants()) do
                        local tx = (lbl:IsA("TextLabel") or lbl:IsA("TextButton")) and lbl.Text or lbl.Name
                        if tx:find(pName) or tx:find(display) then isMyBase = true break end
                    end
                end
            end
            if isMyBase then
                local pos = nil
                if obj:IsA("Model") and obj.PrimaryPart then
                    pos = obj.PrimaryPart.Position
                else
                    local p = obj:FindFirstChild("Base") or obj:FindFirstChild("Floor") or obj:FindFirstChildWhichIsA("BasePart", true)
                    if p then pos = p.Position end
                end
                if not pos then
                    local ap = obj:FindFirstChildWhichIsA("BasePart", true)
                    if ap then pos = ap.Position end
                end
                if pos then
                    myBasePosCache = pos
                    lastCacheTime  = os.time()
                    return pos
                end
            end
        end
    end
    return nil
end

local function FindPlayerNear(pos, radius)
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if (player.Character.HumanoidRootPart.Position - pos).Magnitude < radius then
                return player
            end
        end
    end
    return nil
end

local function GetOtherPlayersPlants()
    local plants = {}
    local myBasePos = FindMyBasePos()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local interactable = obj:FindFirstChildWhichIsA("ProximityPrompt") or obj:FindFirstChildWhichIsA("TouchTransmitter") or obj:FindFirstChildWhichIsA("ClickDetector")
            local isPlant = false
            if interactable then
                if name:find("plant") or name:find("fruit") or name:find("crop") or name:find("seed") or name:find("tree") or name:find("apple") or name:find("berry") then isPlant = true end
                local pp = obj:FindFirstChildWhichIsA("ProximityPrompt")
                if pp then
                    local at = pp.ActionText:lower()
                    local ot = pp.ObjectText:lower()
                    if at:find("harvest") or at:find("steal") or at:find("pick") or at:find("take") or at:find("collect") or at:find("grab") then isPlant = true end
                    if ot:find("plant") or ot:find("crop") or ot:find("tree") or ot:find("seed") then isPlant = true end
                    if not isPlant and not (name:find("door") or name:find("gate") or name:find("buy") or name:find("button") or name:find("upgrade")) then isPlant = true end
                end
            end
            if isPlant then
                local part = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    local isHighValue = name:find("gold") or name:find("rainbow") or name:find("diamond") or name:find("mythic") or name:find("rare") or name:find("epic") or name:find("legend")
                    local isMine = myBasePos and (Vector2.new(part.Position.X, part.Position.Z) - Vector2.new(myBasePos.X, myBasePos.Z)).Magnitude < 60
                    if not isMine then
                        table.insert(plants, {obj=obj, part=part, highValue=isHighValue and true or false})
                    end
                end
            end
        end
    end
    return plants
end

local function FindThreatsInBase(basePos)
    if not basePos then return {} end
    local threats = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            if (player.Character.HumanoidRootPart.Position - basePos).Magnitude < Config.DefenseRange then
                table.insert(threats, player)
            end
        end
    end
    return threats
end

local function EquipWeapon(weaponName)
    local backpack = LocalPlayer.Backpack
    if not backpack then return nil end
    local target = weaponName:lower()
    for _, item in pairs(backpack:GetChildren()) do
        if item.Name:lower():find(target) or target:find(item.Name:lower()) then
            LocalPlayer.Character.Humanoid:EquipTool(item)
            task.wait(0.3)
            return item
        end
    end
    if Character then
        for _, tool in pairs(Character:GetChildren()) do
            if tool:IsA("Tool") then
                local tn = tool.Name:lower()
                if tn:find(target) or target:find(tn) then return tool end
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
    for _, wName in ipairs(Config.DefenseWeapons) do
        local weapon = EquipWeapon(wName)
        if weapon then
            if weapon:FindFirstChild("ClickDetector") and fireclickdetector then
                fireclickdetector(weapon.ClickDetector)
            elseif weapon:FindFirstChildWhichIsA("RemoteEvent") then
                weapon:FindFirstChildWhichIsA("RemoteEvent"):FireServer(thief)
            end
            weapon:Activate()
            task.wait(0.1)
            local handle = weapon:FindFirstChild("Handle")
            if handle and RootPart then
                local dest = targetRoot.CFrame * CFrame.new(0, 0, 3)
                if not basePos or (dest.Position - basePos).Magnitude <= Config.DefenseRange then
                    RootPart.CFrame = dest
                else
                    RootPart.CFrame = CFrame.lookAt(RootPart.Position, targetRoot.Position)
                end
                weapon:Activate()
            end
            StatusLabel.Text = "⚔️ Defending vs " .. thief.Name
            break
        end
    end
end

-- ==========================================
-- FORMAT HELPER
-- ==========================================
local function FormatTime(secs)
    secs = math.max(0, math.floor(secs))
    local h = math.floor(secs / 3600)
    local m = math.floor((secs % 3600) / 60)
    local s = secs % 60
    if h > 0 then return string.format("In %d:%02d:%02d", h, m, s)
    else           return string.format("In %02d:%02d", m, s) end
end

-- ==========================================
-- INSTANT EVENT SNATCHER
-- [FIX 4]: Added validity guard before interacting
-- ==========================================
Workspace.DescendantAdded:Connect(function(obj)
    if not _scriptRunning or not getAutoCollect() then return end
    task.spawn(function()
        task.wait(0.1)
        -- [FIX 4]: Verify obj still exists in workspace before acting
        if not obj or not obj.Parent or not obj:IsDescendantOf(Workspace) then return end

        if obj:IsA("Part") or obj:IsA("MeshPart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local isTarget = false
            if (name:find("gold") or name:find("golden")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then isTarget=true
            elseif (name:find("rainbow") or name:find("rain")) and (name:find("seed") or name:find("fruit") or name:find("plant")) then isTarget=true
            elseif name:find("bird") or name:find("crow") or name:find("pigeon") then isTarget=true
            elseif name:find("seed pack") or (name:find("seed") and name:find("pack")) then isTarget=true
            end
            if isTarget and RootPart then
                if obj:FindFirstChildWhichIsA("ClickDetector") or obj:FindFirstChild("TouchInterest") or obj:FindFirstChild("ProximityPrompt") then
                    local orig = RootPart.CFrame
                    RootPart.CFrame = obj.CFrame
                    task.wait(0.05)
                    CollectSeed(obj)
                    if StatusLabel then StatusLabel.Text = "⚡ Snatched " .. obj.Name end
                    task.wait(0.1)
                    RootPart.CFrame = orig
                end
            end
        end
    end)
end)

-- ==========================================
-- MAIN LOOP
-- ==========================================
local function MainLoop()
    while _scriptRunning and task.wait(1) do
        local ok, err = pcall(function()
            UpdateClockSpeed()

            -- 1. Auto-collect
            if getAutoCollect() then
                local seeds = FindEventSeeds()
                if #seeds > 0 and RootPart then
                    local orig = RootPart.CFrame
                    for _, seed in ipairs(seeds) do
                        RootPart.CFrame = seed.CFrame
                        task.wait(0.05)
                        CollectSeed(seed)
                        StatusLabel.Text = "🎯 Collected " .. seed.Name
                    end
                    task.wait(0.1)
                    RootPart.CFrame = orig
                end
            end

            -- 2. Weather
            if getWeatherNotif() then  -- [FIX 1] now reads real toggle state
                local det = DetectWeather()
                if det ~= currentWeather then
                    currentWeather  = det
                    weatherStartTime = tick()
                    local icon = weatherIcons[currentWeather] or "❓"
                    WeatherLabel.Text = icon .. "  " .. currentWeather
                    StatusLabel.Text = "🌤️ Weather → " .. currentWeather
                    if currentWeather == "Rainbow" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon" then
                        StatusLabel.Text = "⭐ EVENT WEATHER: " .. currentWeather
                    end
                end

                local dur     = weatherDurations[currentWeather] or 120
                local elapsed = tick() - weatherStartTime
                local rem     = math.max(0, dur - elapsed)
                WeatherTimerLabel.Text = string.format("%02d:%02d left", math.floor(rem/60), math.floor(rem%60))

                local timeToMoon, timeToDay = GetCycleTimeRemaining()
                local curClock = Lighting.ClockTime or 12
                local nextName = (curClock >= 6 and curClock < 18) and "Night" or "Day"
                local nextTime = (curClock >= 6 and curClock < 18) and timeToMoon or timeToDay

                local explicitNext = NormalizeWeatherName(ReadNextWeather())
                if explicitNext then nextName = explicitNext end

                if NextWeatherLabel then
                    local nIcon = weatherIcons[nextName] or "❓"
                    NextWeatherLabel.Text = "Next: " .. nIcon .. " " .. nextName .. "  (" .. FormatTime(nextTime) .. ")"
                end

                -- Reset all cards first
                for wname, entry in pairs(weatherCardLabels) do
                    local isActive = false
                    if wname == "Day"         and currentWeather == "Day"         then isActive = true end
                    if wname == "Moon"        and (currentWeather == "Night" or currentWeather == "BloodMoon" or currentWeather == "GoldMoon" or currentWeather == "RainbowMoon") then isActive = true end
                    if wname == "Goldmoon"    and currentWeather == "GoldMoon"    then isActive = true end
                    if wname == "Bloodmoon"   and currentWeather == "BloodMoon"   then isActive = true end
                    if wname == "Rainbow Moon" and currentWeather == "RainbowMoon" then isActive = true end
                    if wname == currentWeather then isActive = true end

                    if isActive then
                        SetWxCardActive(wname, true)
                    else
                        -- Reset color
                        TweenService:Create(entry.card, TweenInfo.new(0.2), {BackgroundColor3 = entry.baseColor}):Play()
                        TweenService:Create(entry.stroke, TweenInfo.new(0.2), {Color = T.stroke}):Play()
                        -- Set timer text
                        local wremain = 0
                        if wname == "Day" then
                            wremain = (currentWeather ~= "Day") and timeToDay or 0
                        elseif wname == "Moon" or wname == "Goldmoon" or wname == "Bloodmoon" or wname == "Rainbow Moon" then
                            wremain = (currentWeather == "Day") and timeToMoon or 0
                            if wname == "Goldmoon"    then entry.label.Text = (wremain > 0) and FormatTime(wremain) .. " (13%)" or "Active"
                            elseif wname == "Bloodmoon"   then entry.label.Text = (wremain > 0) and FormatTime(wremain) .. " (2%)"  or "Active"
                            elseif wname == "Rainbow Moon" then entry.label.Text = (wremain > 0) and FormatTime(wremain) .. " (6%)"  or "Active"
                            else   entry.label.Text = FormatTime(wremain) end
                            entry.label.TextColor3 = T.textSecondary
                            goto continue
                        else
                            -- Random event weathers
                            if currentWeather == wname then
                                local wr = math.max(0, (weatherDurations[wname] or 120) - (tick() - weatherStartTime))
                                entry.label.Text = FormatTime(wr) .. " left"
                            else
                                entry.label.Text = "Random"
                            end
                        end
                        if wname == "Day" then
                            entry.label.Text = FormatTime(wremain)
                        end
                        entry.label.TextColor3 = T.textSecondary
                        ::continue::
                    end
                end
            end

            -- 3. Shop prediction
            if getShopNotif() then
                local now = os.time()
                local baseRestock = 300
                local next5 = baseRestock - (now % baseRestock)
                ShopPredictLabel.Text = string.format("🔄 Next Restock: %02d:%02d", math.floor(next5/60), math.floor(next5%60))
                for _, entry in ipairs(seedTimerLabels) do
                    local cyc = entry.data.cycle * 60
                    local sNext = cyc - (now % cyc)
                    if sNext < 30 then
                        entry.label.Text = "⚡ SOON!"
                        entry.label.TextColor3 = T.warning
                        entry.row.BackgroundColor3 = Color3.fromRGB(55, 50, 18)
                    else
                        entry.label.Text = FormatTime(sNext)
                        entry.label.TextColor3 = T.textSecondary
                        entry.row.BackgroundColor3 = RarityBG[entry.data.rarity]
                    end
                end
            end

            local basePos       = FindMyBasePos()
            local curClock2     = Lighting.ClockTime or 12
            local isNightTime   = (curClock2 < 6 or curClock2 >= 18)
            local isStealing    = false

            -- 4. Auto Steal (Night)
            if isNightTime and getAutoSteal() then
                local plants = GetOtherPlayersPlants()
                local target = nil
                for _, p in ipairs(plants) do
                    if p.highValue then target = p break end
                end
                if not target and not getStealHighValue() then
                    if #plants > 0 then target = plants[1] end
                end
                if target and RootPart then
                    isStealing = true
                    if getAutoAttackOwner() then
                        local owner = FindPlayerNear(target.part.Position, 40)
                        if owner then AttackThief(owner, target.part.Position) task.wait(0.2) end
                    end
                    RootPart.CFrame = target.part.CFrame
                    task.wait(0.05)
                    CollectSeed(target.obj)
                    StatusLabel.Text = "🥷 Stealing " .. target.obj.Name
                    task.wait(0.1)
                end
            end

            -- 5. Auto Stay Base
            if getAutoStay() and isNightTime and not isStealing then
                if basePos and RootPart then
                    local d = Vector2.new(RootPart.Position.X, RootPart.Position.Z) - Vector2.new(basePos.X, basePos.Z)
                    if d.Magnitude > 40 then
                        TeleportTo(basePos + Vector3.new(0, 3, 0))
                        StatusLabel.Text = "🌙 Night — returned to base"
                    end
                end
            end

            -- 6. Auto Defense
            if getAutoDefense() then
                local threats = FindThreatsInBase(basePos)
                for _, thief in ipairs(threats) do
                    AttackThief(thief, basePos)
                    task.wait(Config.WeaponCooldown)
                end
            end

            -- 7. Utilities
            if getAntiPause() then
                pcall(function() game:GetService("GuiService"):SetGameplayPausedNotificationEnabled(false) end)
            end

            if getAutoSkip() then
                pcall(function()
                    local pg = LocalPlayer:FindFirstChild("PlayerGui")
                    if not pg then return end
                    for _, gui in pairs(pg:GetDescendants()) do
                        if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                            local text = gui:IsA("TextButton") and gui.Text:lower() or gui.Name:lower()
                            if text:find("skip") or text:find("continue") or text:find("start") then
                                if gui.Visible and gui.Active and gui.AbsoluteSize.X > 0 then
                                    local sg = gui:FindFirstAncestorWhichIsA("ScreenGui")
                                    if sg and (sg.Name:lower():find("intro") or sg.Name:lower():find("loading") or sg.Name:lower():find("menu") or text:find("skip")) then
                                        if getconnections then
                                            for _, c in pairs(getconnections(gui.MouseButton1Click)) do c:Fire() end
                                        else
                                            local pos = gui.AbsolutePosition + gui.AbsoluteSize / 2
                                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true,  game, 1)
                                            task.wait(0.05)
                                            VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end

            -- Update status if nothing more specific
            if not StatusLabel.Text:find("⚔️") and not StatusLabel.Text:find("🎯") and not StatusLabel.Text:find("🌙") and not StatusLabel.Text:find("⚡") and not StatusLabel.Text:find("🥷") then
                StatusLabel.Text = "✅ Active · " .. currentWeather .. " · monitoring"
            end
        end)

        if not ok then
            warn("GAG2 Loop Error:", err)
            StatusLabel.Text = "⚠️ " .. tostring(err):sub(1, 50)
        end
    end
end

-- ==========================================
-- CHARACTER RESPAWN
-- ==========================================
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    RootPart  = char:WaitForChild("HumanoidRootPart")
    task.wait(2)
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    if getAntiAFK() then
        local VU = game:GetService("VirtualUser")
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end
end)

-- ==========================================
-- CLEANUP
-- ==========================================
local function CleanupScript()
    _scriptRunning = false
    for _, conn in ipairs(_connections) do pcall(function() conn:Disconnect() end) end
    _connections = {}
    if Library and Library.Parent then Library:Destroy() end
end

CloseBtn.MouseButton1Click:Connect(CleanupScript)

if script then
    pcall(function() script.Destroying:Connect(CleanupScript) end)
    pcall(function()
        script.AncestryChanged:Connect(function(_, np)
            if not np then CleanupScript() end
        end)
    end)
end

game.Players.LocalPlayer.AncestryChanged:Connect(function(_, np)
    if not np then CleanupScript() end
end)

-- ==========================================
-- START
-- ==========================================
task.spawn(MainLoop)

StatusLabel.Text = "✅ Devo GAG2 v2.1 loaded · Monitoring..."
WeatherLabel.Text = "☀️  Day"
WeatherTimerLabel.Text = "--:-- left"

pcall(function()
    game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
        Text     = "🌱 Devo GAG2 v2.1 loaded! bebe Ed Sheeran ♪  (7 bugs fixed)",
        Color    = Color3.fromRGB(32, 210, 110),
        Font     = Enum.Font.GothamBold,
        TextSize = 16,
    })
end)

print("🌱 Devo GAG2 v2.1 — Fixed & Premium UI — loaded!")