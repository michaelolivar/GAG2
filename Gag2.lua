--[[
  Grow a Garden 2 - Red Team Script
  Features:
  1. Auto Collect Event Seeds (Gold Seed, Rainbow Seed, Bird, Seed Pack)
  2. Fast Move (Adjustable movement speed)
  3. Dark Mode UI with premium experience
  4. Minimize & Close buttons
  5. Chat head when minimized
  6. Fully draggable UI
  7. Auto-fit for PC, iPad, iPhone, Android
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player / Character
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- GUI System
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GrowAGarden2_Script"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

-- Safe parent (pc vs mobile wrapper)
local function safeParent(gui)
    local success, err = pcall(function()
        gui.Parent = CoreGui
    end)
    if not success then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- Screen size detection
local function getScreenScale()
    local vp = workspace.CurrentCamera.ViewportSize
    local baseWidth = 430
    local baseHeight = 932
    local scaleX = vp.X / baseWidth
    local scaleY = vp.Y / baseHeight
    return math.min(scaleX, scaleY)
end

local screenScale = getScreenScale()
local guiScale = math.clamp(screenScale, 0.5, 2.0)

-- UI Sizing constants
local UI_WIDTH = 380 * guiScale
local UI_HEIGHT = 520 * guiScale
local CORNER_RADIUS = 16
local HEADER_HEIGHT = 48 * guiScale
local PADDING = 12 * guiScale

-- Color palette (Dark Mode)
local COLORS = {
    Background = Color3.fromRGB(18, 18, 22),
    HeaderBg = Color3.fromRGB(28, 28, 35),
    PrimaryAccent = Color3.fromRGB(88, 200, 120),
    SecondaryAccent = Color3.fromRGB(50, 150, 255),
    WarningAccent = Color3.fromRGB(255, 180, 50),
    TextPrimary = Color3.fromRGB(235, 235, 245),
    TextSecondary = Color3.fromRGB(160, 160, 175),
    InputBg = Color3.fromRGB(38, 38, 45),
    InputBorder = Color3.fromRGB(55, 55, 65),
    ButtonHover = Color3.fromRGB(60, 60, 72),
    DropdownBg = Color3.fromRGB(30, 30, 38),
    CardBg = Color3.fromRGB(24, 24, 30),
    Success = Color3.fromRGB(72, 230, 120),
    CloseRed = Color3.fromRGB(230, 70, 70),
    MinimizeYellow = Color3.fromRGB(240, 200, 60),
    Shadow = Color3.fromRGB(0, 0, 0),
}

-- State
local state = {
    minimized = false,
    visible = true,
    selectedEventSeed = "Gold Seed",
    moveSpeed = 24, -- default roblox walkspeed
    speedEnabled = false,
    autoCollectEnabled = false,
    connection = nil,
    speedConnection = nil,
}

-- Utility: Create UI elements
local function createUI()
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT)
    MainFrame.Position = UDim2.new(0.5, -(UI_WIDTH/2), 0.5, -(UI_HEIGHT/2))
    MainFrame.BackgroundColor3 = COLORS.Background
    MainFrame.BorderSize = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Active = true
    MainFrame.Draggable = true

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    MainCorner.Parent = MainFrame

    local MainShadow = Instance.new("ImageLabel")
    MainShadow.Name = "MainShadow"
    MainShadow.Size = UDim2.new(1, 40, 1, 40)
    MainShadow.Position = UDim2.new(0, -20, 0, -20)
    MainShadow.BackgroundTransparency = 1
    MainShadow.Image = "rbxassetid://6014261993"
    MainShadow.ImageColor3 = COLORS.Shadow
    MainShadow.ImageTransparency = 0.7
    MainShadow.ScaleType = Enum.ScaleType.Slice
    MainShadow.SliceCenter = Rect.new(20, 20, 20, 20)
    MainShadow.ZIndex = -1
    MainShadow.Parent = MainFrame

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT)
    Header.BackgroundColor3 = COLORS.HeaderBg
    Header.BorderSize = 0
    Header.Parent = MainFrame

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
    HeaderCorner.Parent = Header

    -- Header top-only round
    local HeaderFill = Instance.new("Frame")
    HeaderFill.Size = UDim2.new(1, 0, 0, HEADER_HEIGHT / 2)
    HeaderFill.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT / 2)
    HeaderFill.BackgroundColor3 = COLORS.HeaderBg
    HeaderFill.BorderSize = 0
    HeaderFill.Parent = Header

    -- App Icon / Title
    local TitleIcon = Instance.new("ImageLabel")
    TitleIcon.Size = UDim2.new(0, 24 * guiScale, 0, 24 * guiScale)
    TitleIcon.Position = UDim2.new(0, PADDING, 0.5, -12 * guiScale)
    TitleIcon.BackgroundTransparency = 1
    TitleIcon.Image = "rbxassetid://4483345998" -- leaf/seed icon placeholder
    TitleIcon.ImageColor3 = COLORS.PrimaryAccent
    TitleIcon.Parent = Header

    local TitleText = Instance.new("TextLabel")
    TitleText.Size = UDim2.new(0, 180 * guiScale, 1, 0)
    TitleText.Position = UDim2.new(0, 44 * guiScale, 0, 0)
    TitleText.BackgroundTransparency = 1
    TitleText.Text = "Grow a Garden 2"
    TitleText.TextColor3 = COLORS.TextPrimary
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextSize = 16 * guiScale
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Parent = Header

    -- Window Controls (macOS-style dots)
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 14 * guiScale, 0, 14 * guiScale)
    CloseBtn.Position = UDim2.new(1, -(PADDING + 14 * guiScale), 0.5, -7 * guiScale)
    CloseBtn.BackgroundColor3 = COLORS.CloseRed
    CloseBtn.Text = ""
    CloseBtn.BorderSize = 0
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = Header

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 14 * guiScale, 0, 14 * guiScale)
    MinimizeBtn.Position = UDim2.new(1, -(PADDING + 14 * guiScale + 20 * guiScale), 0.5, -7 * guiScale)
    MinimizeBtn.BackgroundColor3 = COLORS.MinimizeYellow
    MinimizeBtn.Text = ""
    MinimizeBtn.BorderSize = 0
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.Parent = Header

    local MinimizeCorner = Instance.new("UICorner")
    MinimizeCorner.CornerRadius = UDim.new(1, 0)
    MinimizeCorner.Parent = MinimizeBtn

    -- Separator
    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(1, -PADDING * 2, 0, 1)
    Separator.Position = UDim2.new(0, PADDING, 0, HEADER_HEIGHT)
    Separator.BackgroundColor3 = COLORS.InputBorder
    Separator.BorderSize = 0
    Separator.Parent = MainFrame

    -- Scrollable Content
    local ScrollingFrame = Instance.new("ScrollingFrame")
    ScrollingFrame.Name = "Content"
    ScrollingFrame.Size = UDim2.new(1, 0, 1, -(HEADER_HEIGHT + 2))
    ScrollingFrame.Position = UDim2.new(0, 0, 0, HEADER_HEIGHT + 2)
    ScrollingFrame.BackgroundTransparency = 1
    ScrollingFrame.BorderSize = 0
    ScrollingFrame.ScrollBarThickness = 4 * guiScale
    ScrollingFrame.ScrollBarImageColor3 = COLORS.PrimaryAccent
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollingFrame.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, PADDING)
    UIListLayout.Parent = ScrollingFrame

    local UIPadding = Instance.new("UIPadding")
    UIPadding.PaddingLeft = UDim.new(0, PADDING)
    UIPadding.PaddingRight = UDim.new(0, PADDING)
    UIPadding.PaddingTop = UDim.new(0, PADDING)
    UIPadding.PaddingBottom = UDim.new(0, PADDING * 2)
    UIPadding.Parent = ScrollingFrame

    -- Helper: Card wrapper
    local function createCard(title)
        local Card = Instance.new("Frame")
        Card.BackgroundColor3 = COLORS.CardBg
        Card.BorderSize = 0
        Card.Size = UDim2.new(1, -PADDING * 2, 0, 0)
        Card.AutomaticSize = Enum.AutomaticSize.Y

        local CardCorner = Instance.new("UICorner")
        CardCorner.CornerRadius = UDim.new(0, 12)
        CardCorner.Parent = Card

        local CardPadding = Instance.new("UIPadding")
        CardPadding.PaddingLeft = UDim.new(0, 14 * guiScale)
        CardPadding.PaddingRight = UDim.new(0, 14 * guiScale)
        CardPadding.PaddingTop = UDim.new(0, 14 * guiScale)
        CardPadding.PaddingBottom = UDim.new(0, 14 * guiScale)
        CardPadding.Parent = Card

        local CardList = Instance.new("UIListLayout")
        CardList.Padding = UDim.new(0, 10 * guiScale)
        CardList.SortOrder = Enum.SortOrder.LayoutOrder
        CardList.Parent = Card

        local TitleLabel = Instance.new("TextLabel")
        TitleLabel.Size = UDim2.new(1, 0, 0, 22 * guiScale)
        TitleLabel.BackgroundTransparency = 1
        TitleLabel.Text = title
        TitleLabel.TextColor3 = COLORS.TextPrimary
        TitleLabel.Font = Enum.Font.GothamSemibold
        TitleLabel.TextSize = 15 * guiScale
        TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
        TitleLabel.Parent = Card

        return Card, CardList, CardPadding, TitleLabel
    end

    -- Dropdown helper
    local function createDropdown(cardList, options, default, callback)
        local DropdownFrame = Instance.new("Frame")
        DropdownFrame.Size = UDim2.new(1, 0, 0, 36 * guiScale)
        DropdownFrame.BackgroundColor3 = COLORS.InputBg
        DropdownFrame.BorderSize = 0
        DropdownFrame.ClipsDescendants = true

        local DropCorner = Instance.new("UICorner")
        DropCorner.CornerRadius = UDim.new(0, 10)
        DropCorner.Parent = DropdownFrame

        local DropBorder = Instance.new("UIStroke")
        DropBorder.Color = COLORS.InputBorder
        DropBorder.Thickness = 1
        DropBorder.Parent = DropdownFrame

        local SelectedText = Instance.new("TextLabel")
        SelectedText.Name = "SelectedText"
        SelectedText.Size = UDim2.new(1, -40 * guiScale, 1, 0)
        SelectedText.Position = UDim2.new(0, 10 * guiScale, 0, 0)
        SelectedText.BackgroundTransparency = 1
        SelectedText.Text = default
        SelectedText.TextColor3 = COLORS.TextPrimary
        SelectedText.Font = Enum.Font.Gotham
        SelectedText.TextSize = 14 * guiScale
        SelectedText.TextXAlignment = Enum.TextXAlignment.Left
        SelectedText.Parent = DropdownFrame

        local Arrow = Instance.new("ImageLabel")
        Arrow.Size = UDim2.new(0, 12 * guiScale, 0, 12 * guiScale)
        Arrow.Position = UDim2.new(1, -24 * guiScale, 0.5, -6 * guiScale)
        Arrow.BackgroundTransparency = 1
        Arrow.Image = "rbxassetid://6031094669"
        Arrow.ImageColor3 = COLORS.TextSecondary
        Arrow.Rotation = 180
        Arrow.Parent = DropdownFrame

        local DropdownBtn = Instance.new("TextButton")
        DropdownBtn.Size = UDim2.new(1, 0, 1, 0)
        DropdownBtn.BackgroundTransparency = 1
        DropdownBtn.Text = ""
        DropdownBtn.AutoButtonColor = false
        DropdownBtn.ZIndex = 10
        DropdownBtn.Parent = DropdownFrame

        local expanded = false
        local dropdownList = Instance.new("Frame")
        dropdownList.Size = UDim2.new(1, 0, 0, 0)
        dropdownList.BackgroundColor3 = COLORS.DropdownBg
        dropdownList.BorderSize = 0
        dropdownList.Visible = false
        dropdownList.ClipsDescendants = true

        local DropListCorner = Instance.new("UICorner")
        DropListCorner.CornerRadius = UDim.new(0, 10)
        DropListCorner.Parent = dropdownList

        local DropListBorder = Instance.new("UIStroke")
        DropListBorder.Color = COLORS.InputBorder
        DropListBorder.Thickness = 1
        DropListBorder.Parent = dropdownList

        local DropListLayout = Instance.new("UIListLayout")
        DropListLayout.Padding = UDim.new(0, 2)
        DropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        DropListLayout.Parent = dropdownList

        local function closeDropdown()
            expanded = false
            dropdownList.Visible = false
            dropdownList.Size = UDim2.new(1, 0, 0, 0)
            Arrow.Rotation = 180
            DropdownFrame.Size = UDim2.new(1, 0, 0, 36 * guiScale)
        end

        for _, option in ipairs(options) do
            local OptBtn = Instance.new("TextButton")
            OptBtn.Size = UDim2.new(1, -8, 0, 32 * guiScale)
            OptBtn.BackgroundTransparency = 0.9
            OptBtn.BackgroundColor3 = COLORS.TextPrimary
            OptBtn.Text = option
            OptBtn.TextColor3 = COLORS.TextPrimary
            OptBtn.Font = Enum.Font.Gotham
            OptBtn.TextSize = 13 * guiScale
            OptBtn.BorderSize = 0
            OptBtn.AutoButtonColor = false
            OptBtn.Parent = dropdownList

            local OptCorner = Instance.new("UICorner")
            OptCorner.CornerRadius = UDim.new(0, 8)
            OptCorner.Parent = OptBtn

            OptBtn.MouseEnter:Connect(function()
                OptBtn.BackgroundTransparency = 0.7
            end)
            OptBtn.MouseLeave:Connect(function()
                OptBtn.BackgroundTransparency = 0.9
            end)
            OptBtn.MouseButton1Click:Connect(function()
                SelectedText.Text = option
                callback(option)
                closeDropdown()
            end)
        end

        DropdownBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            if expanded then
                dropdownList.Visible = true
                Arrow.Rotation = 0
                local count = #options
                local listHeight = math.min(count * (34 * guiScale) + 4, 160 * guiScale)
                dropdownList.Size = UDim2.new(1, 0, 0, listHeight)
                DropdownFrame.Size = UDim2.new(1, 0, 0, 36 * guiScale + listHeight + 4)
            else
                closeDropdown()
            end
        end)

        dropdownList.Parent = DropdownFrame
        DropdownFrame.Parent = cardList

        return DropdownFrame
    end

    -- Toggle helper
    local function createToggle(cardList, label, default, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 36 * guiScale)
        ToggleFrame.BackgroundColor3 = COLORS.InputBg
        ToggleFrame.BorderSize = 0

        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 10)
        ToggleCorner.Parent = ToggleFrame

        local ToggleBorder = Instance.new("UIStroke")
        ToggleBorder.Color = COLORS.InputBorder
        ToggleBorder.Thickness = 1
        ToggleBorder.Parent = ToggleFrame

        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(1, -60 * guiScale, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 10 * guiScale, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = label
        ToggleLabel.TextColor3 = COLORS.TextPrimary
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextSize = 14 * guiScale
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = ToggleFrame

        local ToggleBtn = Instance.new("Frame")
        ToggleBtn.Name = "ToggleBtn"
        ToggleBtn.Size = UDim2.new(0, 42 * guiScale, 0, 24 * guiScale)
        ToggleBtn.Position = UDim2.new(1, -(52 * guiScale), 0.5, -12 * guiScale)
        ToggleBtn.BackgroundColor3 = default and COLORS.PrimaryAccent or COLORS.InputBorder
        ToggleBtn.BorderSize = 0

        local ToggleCorner2 = Instance.new("UICorner")
        ToggleCorner2.CornerRadius = UDim.new(1, 0)
        ToggleCorner2.Parent = ToggleBtn

        local ToggleKnob = Instance.new("Frame")
        ToggleKnob.Name = "Knob"
        ToggleKnob.Size = UDim2.new(0, 20 * guiScale, 0, 20 * guiScale)
        ToggleKnob.Position = UDim2.new(0, default and (20 * guiScale) or 2 * guiScale, 0.5, -10 * guiScale)
        ToggleKnob.BackgroundColor3 = COLORS.TextPrimary
        ToggleKnob.BorderSize = 0

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = ToggleKnob

        ToggleKnob.Parent = ToggleBtn

        local ToggleClick = Instance.new("TextButton")
        ToggleClick.Size = UDim2.new(1, 0, 1, 0)
        ToggleClick.BackgroundTransparency = 1
        ToggleClick.Text = ""
        ToggleClick.AutoButtonColor = false
        ToggleClick.ZIndex = 10
        ToggleClick.Parent = ToggleFrame

        local toggled = default
        ToggleClick.MouseButton1Click:Connect(function()
            toggled = not toggled
            ToggleBtn.BackgroundColor3 = toggled and COLORS.PrimaryAccent or COLORS.InputBorder
            local targetPos = toggled and UDim2.new(0, 20 * guiScale, 0.5, -10 * guiScale) or UDim2.new(0, 2 * guiScale, 0.5, -10 * guiScale)
            ToggleKnob:TweenPosition(targetPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
            callback(toggled)
        end)

        ToggleFrame.Parent = cardList
        return ToggleFrame, ToggleBtn, ToggleKnob
    end

    -- Slider helper
    local function createSlider(cardList, label, min, max, default, formatStr, callback)
        local SliderFrame = Instance.new("Frame")
        SliderFrame.Size = UDim2.new(1, 0, 0, 50 * guiScale)
        SliderFrame.BackgroundColor3 = COLORS.InputBg
        SliderFrame.BorderSize = 0

        local SliderCorner = Instance.new("UICorner")
        SliderCorner.CornerRadius = UDim.new(0, 10)
        SliderCorner.Parent = SliderFrame

        local SliderBorder = Instance.new("UIStroke")
        SliderBorder.Color = COLORS.InputBorder
        SliderBorder.Thickness = 1
        SliderBorder.Parent = SliderFrame

        local SliderLabel = Instance.new("TextLabel")
        SliderLabel.Size = UDim2.new(0, 150 * guiScale, 0, 18 * guiScale)
        SliderLabel.Position = UDim2.new(0, 10 * guiScale, 0, 6 * guiScale)
        SliderLabel.BackgroundTransparency = 1
        SliderLabel.Text = label
        SliderLabel.TextColor3 = COLORS.TextSecondary
        SliderLabel.Font = Enum.Font.Gotham
        SliderLabel.TextSize = 12 * guiScale
        SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
        SliderLabel.Parent = SliderFrame

        local ValueLabel = Instance.new("TextLabel")
        ValueLabel.Size = UDim2.new(0, 80 * guiScale, 0, 18 * guiScale)
        ValueLabel.Position = UDim2.new(1, -(90 * guiScale), 0, 6 * guiScale)
        ValueLabel.BackgroundTransparency = 1
        ValueLabel.Text = formatStr:format(default)
        ValueLabel.TextColor3 = COLORS.PrimaryAccent
        ValueLabel.Font = Enum.Font.GothamSemibold
        ValueLabel.TextSize = 13 * guiScale
        ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
        ValueLabel.Parent = SliderFrame

        local Track = Instance.new("Frame")
        Track.Size = UDim2.new(1, -20 * guiScale, 0, 4 * guiScale)
        Track.Position = UDim2.new(0, 10 * guiScale, 0, 36 * guiScale)
        Track.BackgroundColor3 = COLORS.InputBorder
        Track.BorderSize = 0

        local TrackCorner = Instance.new("UICorner")
        TrackCorner.CornerRadius = UDim.new(1, 0)
        TrackCorner.Parent = Track

        local Fill = Instance.new("Frame")
        Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        Fill.BackgroundColor3 = COLORS.PrimaryAccent
        Fill.BorderSize = 0

        local FillCorner = Instance.new("UICorner")
        FillCorner.CornerRadius = UDim.new(1, 0)
        FillCorner.Parent = Fill
        Fill.Parent = Track

        local Knob = Instance.new("Frame")
        Knob.Size = UDim2.new(0, 16 * guiScale, 0, 16 * guiScale)
        Knob.Position = UDim2.new((default - min) / (max - min), -8 * guiScale, 0.5, -8 * guiScale)
        Knob.BackgroundColor3 = COLORS.TextPrimary
        Knob.BorderSize = 0

        local KnobCorner = Instance.new("UICorner")
        KnobCorner.CornerRadius = UDim.new(1, 0)
        KnobCorner.Parent = Knob
        Knob.Parent = Track

        Track.Parent = SliderFrame

        local dragging = false
        local function updateSlider(input)
            local pos = UserInputService:GetMouseLocation()
            local absPos = Track.AbsolutePosition
            local absSize = Track.AbsoluteSize.X
            local relativeX = math.clamp((pos.X - absPos.X) / absSize, 0, 1)
            local value = math.floor(min + (max - min) * relativeX)
            Fill.Size = UDim2.new(relativeX, 0, 1, 0)
            Knob.Position = UDim2.new(relativeX, -8 * guiScale, 0.5, -8 * guiScale)
            ValueLabel.Text = formatStr:format(value)
            callback(value)
        end

        local SliderClick = Instance.new("TextButton")
        SliderClick.Size = UDim2.new(1, 0, 1, 0)
        SliderClick.BackgroundTransparency = 1
        SliderClick.Text = ""
        SliderClick.AutoButtonColor = false
        SliderClick.ZIndex = 5
        SliderClick.Parent = SliderFrame

        SliderClick.MouseButton1Down:Connect(function()
            dragging = true
            updateSlider()
            local conn
            conn = UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement) then
                updateSlider()
            end
        end)

        SliderFrame.Parent = cardList
        return SliderFrame
    end

    -- ====== BUILD UI ======

    -- SECTION 1: Auto Collect Event Seeds
    local Card1, List1 = createCard("Auto Collect Event Seeds")
    Card1.Parent = ScrollingFrame

    local dropdown = createDropdown(List1, {"Gold Seed", "Rainbow Seed", "Bird", "Seed Pack"}, state.selectedEventSeed, function(val)
        state.selectedEventSeed = val
    end)

    local toggle1 = createToggle(List1, "Auto Collect", state.autoCollectEnabled, function(val)
        state.autoCollectEnabled = val
        if val then
            startAutoCollect()
        else
            stopAutoCollect()
        end
    end)

    -- SECTION 2: Fast Move
    local Card2, List2 = createCard("Fast Move")
    Card2.Parent = ScrollingFrame

    local toggle2 = createToggle(List2, "Fast Move", state.speedEnabled, function(val)
        state.speedEnabled = val
        if val then
            applySpeed()
        else
            resetSpeed()
        end
    end)

    local slider = createSlider(List2, "Movement Speed", 16, 120, state.moveSpeed, "%dx Speed", function(val)
        state.moveSpeed = val
        if state.speedEnabled then
            applySpeed()
        end
    end)

    -- SECTION 3: Info / Credits
    local Card3, List3 = createCard("About")
    Card3.Parent = ScrollingFrame

    local infoText = Instance.new("TextLabel")
    infoText.Size = UDim2.new(1, 0, 0, 36 * guiScale)
    infoText.BackgroundTransparency = 1
    infoText.Text = "Grow a Garden 2 · Red Team Edition\nDark Mode UI · v1.0"
    infoText.TextColor3 = COLORS.TextSecondary
    infoText.Font = Enum.Font.Gotham
    infoText.TextSize = 12 * guiScale
    infoText.TextXAlignment = Enum.TextXAlignment.Left
    infoText.RichText = true
    infoText.Parent = List3

    -- Functions
    local autoCollectLoop = nil

    function startAutoCollect()
        if autoCollectLoop then return end
        autoCollectLoop = RunService.Heartbeat:Connect(function()
            if not state.autoCollectEnabled then return end
            -- Collect event seeds based on selection
            local collectionTargets = {
                ["Gold Seed"] = "GoldSeed",
                ["Rainbow Seed"] = "RainbowSeed",
                ["Bird"] = "Bird",
                ["Seed Pack"] = "SeedPack",
            }
            local target = collectionTargets[state.selectedEventSeed]
            if not target then return end

            -- Find and collect nearby event seeds
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name == target then
                    local distance = (obj.Position - HumanoidRootPart.Position).Magnitude
                    if distance < 50 then
                        firetouchinterest(HumanoidRootPart, obj, 0)
                        task.wait(0.05)
                        firetouchinterest(HumanoidRootPart, obj, 1)
                    end
                end
            end

            -- Also try collecting via RemoteEvent if game uses that pattern
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Remote")
            if remotes then
                local collectEvent = remotes:FindFirstChild("CollectEventSeed") or remotes:FindFirstChild("CollectSeed") or remotes:FindFirstChild("Collect")
                if collectEvent then
                    collectEvent:FireServer(target)
                end
            end
        end)
    end

    function stopAutoCollect()
        if autoCollectLoop then
            autoCollectLoop:Disconnect()
            autoCollectLoop = nil
        end
    end

    function applySpeed()
        if Character and HumanoidRootPart then
            local humanoid = Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = state.moveSpeed
            end
        end
    end

    function resetSpeed()
        if Character and HumanoidRootPart then
            local humanoid = Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 24
            end
        end
    end

    -- Character respawn handling
    LocalPlayer.CharacterAdded:Connect(function(newChar)
        Character = newChar
        HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
        if state.speedEnabled then
            task.wait(0.5)
            applySpeed()
        end
    end)

    -- Minimize / Close handlers
    MinimizeBtn.MouseButton1Click:Connect(function()
        state.minimized = true
        MainFrame.Visible = false
        createChatHead()
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        state.visible = false
        if autoCollectLoop then
            autoCollectLoop:Disconnect()
        end
        if state.speedEnabled then
            resetSpeed()
        end
        MainFrame.Visible = false
        task.wait(0.5)
        ScreenGui:Destroy()
    end)

    -- Chat head
    function createChatHead()
        if ScreenGui:FindFirstChild("ChatHead") then return end

        local ChatHead = Instance.new("ImageButton")
        ChatHead.Name = "ChatHead"
        ChatHead.Size = UDim2.new(0, 54 * guiScale, 0, 54 * guiScale)
        ChatHead.Position = UDim2.new(0, 20, 1, -(80 * guiScale))
        ChatHead.BackgroundTransparency = 1
        ChatHead.Image = "rbxassetid://4483345998"
        ChatHead.ImageColor3 = COLORS.PrimaryAccent
        ChatHead.Draggable = true
        ChatHead.Active = true
        ChatHead.Parent = ScreenGui

        local HeadShadow = Instance.new("ImageLabel")
        HeadShadow.Size = UDim2.new(1, 20, 1, 20)
        HeadShadow.Position = UDim2.new(0, -10, 0, -10)
        HeadShadow.BackgroundTransparency = 1
        HeadShadow.Image = "rbxassetid://6014261993"
        HeadShadow.ImageColor3 = COLORS.Shadow
        HeadShadow.ImageTransparency = 0.6
        HeadShadow.ScaleType = Enum.ScaleType.Slice
        HeadShadow.SliceCenter = Rect.new(10, 10, 10, 10)
        HeadShadow.ZIndex = -1
        HeadShadow.Parent = ChatHead

        local Badge = Instance.new("Frame")
        Badge.Size = UDim2.new(0, 14 * guiScale, 0, 14 * guiScale)
        Badge.Position = UDim2.new(1, -6 * guiScale, 0, -2 * guiScale)
        Badge.BackgroundColor3 = COLORS.PrimaryAccent
        Badge.BorderSize = 0

        local BadgeCorner = Instance.new("UICorner")
        BadgeCorner.CornerRadius = UDim.new(1, 0)
        BadgeCorner.Parent = Badge
        Badge.Parent = ChatHead

        ChatHead.MouseButton1Click:Connect(function()
            ChatHead:Destroy()
            state.minimized = false
            MainFrame.Visible = true
        end)

        -- Animate chat head entry
        ChatHead.Position = UDim2.new(0, 20, 1, 20)
        ChatHead:TweenPosition(UDim2.new(0, 20, 1, -(80 * guiScale)), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.5, true)
    end

    -- Animate main frame entry
    MainFrame.Position = UDim2.new(0.5, -(UI_WIDTH/2), 0.5, -UI_HEIGHT)
    MainFrame.Parent = ScreenGui
    MainFrame:TweenPosition(UDim2.new(0.5, -(UI_WIDTH/2), 0.5, -(UI_HEIGHT/2)), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.4, true)

    -- Fade in
    MainFrame.BackgroundTransparency = 0.1
    task.wait(0.05)
    MainFrame.BackgroundTransparency = 0

    return MainFrame
end

-- Initialize
safeParent(ScreenGui)
createUI()

-- Anti-AFK
local virtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    virtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    virtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Notify
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Grow a Garden 2",
    Text = "Script loaded successfully!",
    Duration = 3,
})