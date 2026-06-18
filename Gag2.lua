--[[
    Grow a Garden 2 - Premium Bot v2
    Authorized educational automation script
]]

-- ==========================================
-- CONFIG
-- ==========================================
local Config = {
    AutoCollect = true,
    AutoReturn = true,
    WalkEnabled = false,
    WalkSpeed = 24,
    CollectRadius = 25,
    ScanInterval = 0.5,
    EventCheckInterval = 2,
    WalkKey = "LeftShift",   -- Toggle walk on/off key
}

local SEED_TYPES = {
    GoldSeed = "Gold Seed",
    RainbowSeed = "Rainbow Seed",
    Bird = "Bird",
    SeedPack = "Seed Pack",
}

-- ==========================================
-- SERVICES
-- ==========================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")

-- Player setup
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Mouse = Player:GetMouse()

-- State
local State = {
    Collecting = false,
    InEvent = false,
    EventEnding = false,
    Running = true,
    OriginalSpeed = 16,
    MenuOpen = true,
}

-- ==========================================
-- UI SETUP
-- ==========================================

local function CreatePremiumUI()
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GardenBotPremium"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Try to put in CoreGui, fallback to PlayerGui
    local parent = CoreGui or Player:FindFirstChild("PlayerGui") or StarterGui
    ScreenGui.Parent = parent

    -- ==========================================
    -- COLOR SCHEME (SpeedHub Dark)
    -- ==========================================
    local Colors = {
        Background = Color3.fromRGB(18, 18, 22),
        Secondary = Color3.fromRGB(24, 24, 30),
        Card = Color3.fromRGB(30, 30, 38),
        Accent = Color3.fromRGB(88, 101, 242),      -- Discord blurple
        AccentHover = Color3.fromRGB(104, 117, 255),
        Danger = Color3.fromRGB(237, 66, 69),
        Success = Color3.fromRGB(87, 210, 150),
        Warning = Color3.fromRGB(255, 191, 64),
        Text = Color3.fromRGB(220, 220, 230),
        TextDim = Color3.fromRGB(140, 140, 155),
        Border = Color3.fromRGB(38, 38, 46),
        InputBg = Color3.fromRGB(22, 22, 28),
        ToggleOn = Color3.fromRGB(88, 101, 242),
        ToggleOff = Color3.fromRGB(50, 50, 60),
        HeaderBg = Color3.fromRGB(22, 22, 28),
    }

    -- ==========================================
    -- MAIN FRAME
    -- ==========================================
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 340, 0, 460)
    MainFrame.Position = UDim2.new(0.5, -170, 0.5, -230)
    MainFrame.BackgroundColor3 = Colors.Background
    MainFrame.BorderColor3 = Colors.Border
    MainFrame.BorderSizePixel = 1
    MainFrame.ClipsDescendants = true

    -- Shadow
    local Shadow = Instance.new("ImageLabel")
    Shadow.Name = "Shadow"
    Shadow.Size = UDim2.new(1, 30, 1, 30)
    Shadow.Position = UDim2.new(0, -15, 0, -15)
    Shadow.BackgroundTransparency = 1
    Shadow.Image = "rbxassetid://1316045217"
    Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency = 0.7
    Shadow.ScaleType = Enum.ScaleType.Slice
    Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
    Shadow.Parent = MainFrame

    -- Corner
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    -- ==========================================
    -- HEADER / DRAG BAR
    -- ==========================================
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 44)
    Header.BackgroundColor3 = Colors.HeaderBg
    Header.BorderColor3 = Colors.Border
    Header.BorderSizePixel = 1

    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 8)
    HeaderCorner.Parent = Header

    -- Cover top-right corner
    local HeaderFill = Instance.new("Frame")
    HeaderFill.Size = UDim2.new(1, 0, 0, 4)
    HeaderFill.Position = UDim2.new(0, 0, 0, 40)
    HeaderFill.BackgroundColor3 = Colors.HeaderBg
    HeaderFill.BorderSizePixel = 0
    HeaderFill.Parent = Header

    -- Logo icon
    local LogoIcon = Instance.new("ImageLabel")
    LogoIcon.Size = UDim2.new(0, 22, 0, 22)
    LogoIcon.Position = UDim2.new(0, 14, 0, 11)
    LogoIcon.BackgroundTransparency = 1
    LogoIcon.Image = "rbxassetid://4483345998"
    LogoIcon.ImageColor3 = Colors.Accent
    LogoIcon.Parent = Header

    -- Title
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 160, 1, 0)
    Title.Position = UDim2.new(0, 42, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "Garden Bot"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Colors.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header

    -- Version badge
    local VersionBadge = Instance.new("Frame")
    VersionBadge.Size = UDim2.new(0, 42, 0, 18)
    VersionBadge.Position = UDim2.new(0, 175, 0, 13)
    VersionBadge.BackgroundColor3 = Colors.Accent
    VersionBadge.BackgroundColor3 = Color3.fromRGB(88, 101, 242)

    local BadgeCorner = Instance.new("UICorner")
    BadgeCorner.CornerRadius = UDim.new(0, 4)
    BadgeCorner.Parent = VersionBadge

    local BadgeText = Instance.new("TextLabel")
    BadgeText.Size = UDim2.new(1, 0, 1, 0)
    BadgeText.BackgroundTransparency = 1
    BadgeText.Text = "v2.0"
    BadgeText.Font = Enum.Font.GothamBold
    BadgeText.TextSize = 10
    BadgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    BadgeText.Parent = VersionBadge

    VersionBadge.Parent = Header

    -- Close Button
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 28, 0, 28)
    CloseBtn.Position = UDim2.new(1, -34, 0, 8)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://6031094678"
    CloseBtn.ImageColor3 = Colors.TextDim
    CloseBtn.Parent = Header

    -- Close hover
    CloseBtn.MouseEnter:Connect(function()
        CloseBtn.ImageColor3 = Colors.Danger
    end)
    CloseBtn.MouseLeave:Connect(function()
        CloseBtn.ImageColor3 = Colors.TextDim
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        State.MenuOpen = not State.MenuOpen
        MainFrame.Visible = State.MenuOpen
    end)

    -- ==========================================
    -- DRAG SCRIPT
    -- ==========================================
    local dragging, dragInput, dragStart, startPos

    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    Header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            MainFrame.Position = newPos
        end
    end)

    Header.Parent = MainFrame

    -- ==========================================
    -- BODY
    -- ==========================================
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Size = UDim2.new(1, -20, 1, -64)
    Body.Position = UDim2.new(0, 10, 0, 54)
    Body.BackgroundTransparency = 1
    Body.Parent = MainFrame

    -- Navigation Tabs
    local NavBar = Instance.new("Frame")
    NavBar.Name = "NavBar"
    NavBar.Size = UDim2.new(1, 0, 0, 32)
    NavBar.BackgroundTransparency = 1
    NavBar.Parent = Body

    local TabButtons = {}
    local TabContents = {}
    local ActiveTab = "Farm"

    local function CreateTabButton(name, text)
        local btn = Instance.new("TextButton")
        btn.Name = name .. "Tab"
        btn.Size = UDim2.new(0.5, -4, 1, 0)
        btn.BackgroundColor3 = Colors.Secondary
        btn.Text = text
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 13
        btn.TextColor3 = Colors.TextDim
        btn.AutoButtonColor = false

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            ActiveTab = name
            for _, b in ipairs(TabButtons) do
                b.BackgroundColor3 = Colors.Secondary
                b.TextColor3 = Colors.TextDim
            end
            btn.BackgroundColor3 = Colors.Accent
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            for tabName, frame in pairs(TabContents) do
                frame.Visible = (tabName == name)
            end
        end)

        btn.Parent = NavBar
        return btn
    end

    local farmBtn = CreateTabButton("Farm", "Farm")
    local walkBtn = CreateTabButton("Walk", "Walk")
    table.insert(TabButtons, farmBtn)
    table.insert(TabButtons, walkBtn)

    -- Position tabs
    farmBtn.Position = UDim2.new(0, 0, 0, 0)
    walkBtn.Position = UDim2.new(0.5, 4, 0, 0)

    -- Default active tab
    farmBtn.BackgroundColor3 = Colors.Accent
    farmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)

    -- ==========================================
    -- TAB: FARM
    -- ==========================================
    local FarmTab = Instance.new("ScrollingFrame")
    FarmTab.Name = "FarmTab"
    FarmTab.Size = UDim2.new(1, 0, 1, -42)
    FarmTab.Position = UDim2.new(0, 0, 0, 42)
    FarmTab.BackgroundTransparency = 1
    FarmTab.BorderSizePixel = 0
    FarmTab.ScrollBarThickness = 3
    FarmTab.ScrollBarImageColor3 = Colors.Accent
    FarmTab.CanvasSize = UDim2.new(0, 0, 0, 320)
    FarmTab.Parent = Body
    TabContents["Farm"] = FarmTab

    local FarmLayout = Instance.new("UIListLayout")
    FarmLayout.Padding = UDim.new(0, 8)
    FarmLayout.SortOrder = Enum.SortOrder.LayoutOrder
    FarmLayout.Parent = FarmTab

    local FarmPadding = Instance.new("UIPadding")
    FarmPadding.PaddingTop = UDim.new(0, 4)
    FarmPadding.Parent = FarmTab

    -- Section Helper
    local function CreateSection(parent, title)
        local section = Instance.new("Frame")
        section.Name = title .. "Section"
        section.Size = UDim2.new(1, 0, 0, 120)
        section.BackgroundColor3 = Colors.Card
        section.BorderColor3 = Colors.Border
        section.BorderSizePixel = 1

        local sectionCorner = Instance.new("UICorner")
        sectionCorner.CornerRadius = UDim.new(0, 6)
        sectionCorner.Parent = section

        local sectionTitle = Instance.new("TextLabel")
        sectionTitle.Size = UDim2.new(1, -16, 0, 24)
        sectionTitle.Position = UDim2.new(0, 12, 0, 8)
        sectionTitle.BackgroundTransparency = 1
        sectionTitle.Text = title
        sectionTitle.Font = Enum.Font.GothamSemibold
        sectionTitle.TextSize = 13
        sectionTitle.TextColor3 = Colors.Text
        sectionTitle.TextXAlignment = Enum.TextXAlignment.Left
        sectionTitle.Parent = section

        section.Parent = parent
        return section
    end

    local function CreateToggle(parent, title, desc, default, callback, yOffset)
        local y = yOffset or 0
        
        local bg = Instance.new("Frame")
        bg.Name = title .. "Toggle"
        bg.Size = UDim2.new(1, -24, 0, 36)
        bg.Position = UDim2.new(0, 12, 0, y)
        bg.BackgroundTransparency = 1
        bg.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 180, 0, 18)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Colors.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = bg

        if desc then
            local descLbl = Instance.new("TextLabel")
            descLbl.Size = UDim2.new(0, 200, 0, 14)
            descLbl.Position = UDim2.new(0, 0, 0, 20)
            descLbl.BackgroundTransparency = 1
            descLbl.Text = desc
            descLbl.Font = Enum.Font.Gotham
            descLbl.TextSize = 11
            descLbl.TextColor3 = Colors.TextDim
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.Parent = bg
        end

        -- Toggle switch
        local toggleBg = Instance.new("Frame")
        toggleBg.Name = "ToggleBg"
        toggleBg.Size = UDim2.new(0, 44, 0, 22)
        toggleBg.Position = UDim2.new(1, -44, 0, 4)
        toggleBg.BackgroundColor3 = default and Colors.ToggleOn or Colors.ToggleOff
        toggleBg.BorderSizePixel = 0
        toggleBg.ClipsDescendants = true

        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 11)
        toggleCorner.Parent = toggleBg

        local toggleCircle = Instance.new("Frame")
        toggleCircle.Name = "ToggleCircle"
        toggleCircle.Size = UDim2.new(0, 18, 0, 18)
        toggleCircle.Position = UDim2.new(0, default and 24 or 2, 0, 2)
        toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleCircle.BorderSizePixel = 0

        local circleCorner = Instance.new("UICorner")
        circleCorner.CornerRadius = UDim.new(0, 9)
        circleCorner.Parent = toggleCircle

        toggleCircle.Parent = toggleBg
        toggleBg.Parent = bg

        -- Button for toggle
        local btn = Instance.new("ImageButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.ImageTransparency = 1
        btn.Parent = bg

        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            -- Animate
            local targetX = toggled and 24 or 2
            local targetColor = toggled and Colors.ToggleOn or Colors.ToggleOff
            
            toggleBg.BackgroundColor3 = targetColor
            toggleCircle:TweenPosition(UDim2.new(0, targetX, 0, 2), "Out", "Quad", 0.2, true)
            
            if callback then
                callback(toggled)
            end
        end)

        return bg
    end

    -- Farm Settings Section
    local farmSection = CreateSection(FarmTab, "Collection Settings")
    farmSection.Size = UDim2.new(1, 0, 0, 210)

    local autoCollectToggle = CreateToggle(farmSection, "Auto Collect", "Collect seeds automatically", true, function(val)
        Config.AutoCollect = val
    end, 32)

    local autoReturnToggle = CreateToggle(farmSection, "Auto Return", "Return on event end", true, function(val)
        Config.AutoReturn = val
    end, 74)

    -- Slider helper function
    local function CreateSlider(parent, title, min, max, default, suffix, callback, yOffset)
        local y = yOffset or 0
        
        local bg = Instance.new("Frame")
        bg.Name = title .. "Slider"
        bg.Size = UDim2.new(1, -24, 0, 44)
        bg.Position = UDim2.new(0, 12, 0, y)
        bg.BackgroundTransparency = 1
        bg.Parent = parent

        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 200, 0, 16)
        lbl.Position = UDim2.new(0, 0, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = title
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 14
        lbl.TextColor3 = Colors.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = bg

        local valueLbl = Instance.new("TextLabel")
        valueLbl.Name = "Value"
        valueLbl.Size = UDim2.new(0, 50, 0, 16)
        valueLbl.Position = UDim2.new(1, -50, 0, 0)
        valueLbl.BackgroundTransparency = 1
        valueLbl.Text = tostring(default) .. (suffix or "")
        valueLbl.Font = Enum.Font.GothamBold
        valueLbl.TextSize = 13
        valueLbl.TextColor3 = Colors.Accent
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right
        valueLbl.Parent = bg

        -- Slider bar
        local sliderBg = Instance.new("Frame")
        sliderBg.Name = "SliderBg"
        sliderBg.Size = UDim2.new(1, 0, 0, 6)
        sliderBg.Position = UDim2.new(0, 0, 0, 28)
        sliderBg.BackgroundColor3 = Colors.InputBg
        sliderBg.BorderSizePixel = 0
        sliderBg.ClipsDescendants = true

        local sliderCorner = Instance.new("UICorner")
        sliderCorner.CornerRadius = UDim.new(0, 3)
        sliderCorner.Parent = sliderBg

        local sliderFill = Instance.new("Frame")
        sliderFill.Name = "SliderFill"
        sliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
        sliderFill.BackgroundColor3 = Colors.Accent
        sliderFill.BorderSizePixel = 0

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = sliderFill

        sliderFill.Parent = sliderBg
        sliderBg.Parent = bg

        -- Slider button (draggable)
        local sliderBtn = Instance.new("ImageButton")
        sliderBtn.Size = UDim2.new(1, 0, 1, 0)
        sliderBtn.BackgroundTransparency = 1
        sliderBtn.ImageTransparency = 1
        sliderBtn.Parent = bg

        local dragging = false
        sliderBtn.MouseButton1Down:Connect(function()
            dragging = true
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)

        sliderBtn.MouseMoved:Connect(function()
            if not dragging then return end
            local pos = UserInputService:GetMouseLocation()
            local absX = sliderBg.AbsolutePosition.X
            local absW = sliderBg.AbsoluteSize.X
            local ratio = math.clamp((pos.X - absX) / absW, 0, 1)
            local val = math.round(min + ratio * (max - min))
            
            sliderFill.Size = UDim2.new(ratio, 0, 1, 0)
            valueLbl.Text = tostring(val) .. (suffix or "")
            
            if callback then
                callback(val)
            end
        end)

        return bg
    end

    CreateSlider(farmSection, "Walk Speed", 16, 40, 24, "", function(val)
        Config.WalkSpeed = val
        if State.WalkEnabled then
            Humanoid.WalkSpeed = val
        end
    end, 120)

    CreateSlider(farmSection, "Scan Radius", 10, 50, 25, "s", function(val)
        Config.CollectRadius = val
    end, 168)

    -- ==========================================
    -- TAB: WALK SETTINGS
    -- ==========================================
    local WalkTab = Instance.new("ScrollingFrame")
    WalkTab.Name = "WalkTab"
    WalkTab.Size = UDim2.new(1, 0, 1, -42)
    WalkTab.Position = UDim2.new(0, 0, 0, 42)
    WalkTab.BackgroundTransparency = 1
    WalkTab.BorderSizePixel = 0
    WalkTab.ScrollBarThickness = 3
    WalkTab.ScrollBarImageColor3 = Colors.Accent
    WalkTab.CanvasSize = UDim2.new(0, 0, 0, 380)
    WalkTab.Visible = false
    WalkTab.Parent = Body
    TabContents["Walk"] = WalkTab

    local WalkLayout = Instance.new("UIListLayout")
    WalkLayout.Padding = UDim.new(0, 8)
    WalkLayout.SortOrder = Enum.SortOrder.LayoutOrder
    WalkLayout.Parent = WalkTab

    local WalkPadding = Instance.new("UIPadding")
    WalkPadding.PaddingTop = UDim.new(0, 4)
    WalkPadding.Parent = WalkTab

    -- Walk Section
    local walkSection = CreateSection(WalkTab, "Walk Speed Control")
    walkSection.Size = UDim2.new(1, 0, 0, 280)

    -- Walk toggle
    local walkToggle = CreateToggle(walkSection, "Enable Fast Walk", "Speed boost on/off", false, function(val)
        Config.WalkEnabled = val
        State.WalkEnabled = val
        if val then
            Humanoid.WalkSpeed = Config.WalkSpeed
        else
            Humanoid.WalkSpeed = State.OriginalSpeed
        end
    end, 32)

    -- Walk speed slider (larger, more visible)
    local walkSpeedSlider = CreateSlider(walkSection, "Walk Speed", 16, 50, 24, "", function(val)
        Config.WalkSpeed = val
        if Config.WalkEnabled then
            Humanoid.WalkSpeed = val
        end
    end, 80)

    -- Current speed display
    local speedDisplayBg = Instance.new("Frame")
    speedDisplayBg.Name = "SpeedDisplay"
    speedDisplayBg.Size = UDim2.new(1, -24, 0, 52)
    speedDisplayBg.Position = UDim2.new(0, 12, 0, 135)
    speedDisplayBg.BackgroundColor3 = Colors.InputBg
    speedDisplayBg.BorderSizePixel = 0

    local speedCorner = Instance.new("UICorner")
    speedCorner.CornerRadius = UDim.new(0, 6)
    speedCorner.Parent = speedDisplayBg

    local speedLbl = Instance.new("TextLabel")
    speedLbl.Size = UDim2.new(1, 0, 0, 20)
    speedLbl.Position = UDim2.new(0, 12, 0, 6)
    speedLbl.BackgroundTransparency = 1
    speedLbl.Text = "Current Speed"
    speedLbl.Font = Enum.Font.Gotham
    speedLbl.TextSize = 12
    speedLbl.TextColor3 = Colors.TextDim
    speedLbl.TextXAlignment = Enum.TextXAlignment.Left
    speedLbl.Parent = speedDisplayBg

    local speedVal = Instance.new("TextLabel")
    speedVal.Size = UDim2.new(1, -24, 0, 24)
    speedVal.Position = UDim2.new(0, 12, 0, 24)
    speedVal.BackgroundTransparency = 1
    speedVal.Text = "16 (Normal)"
    speedVal.Font = Enum.Font.GothamBold
    speedVal.TextSize = 20
    speedVal.TextColor3 = Colors.Accent
    speedVal.TextXAlignment = Enum.TextXAlignment.Left
    speedVal.Parent = speedDisplayBg

    speedDisplayBg.Parent = walkSection

    -- Update speed display
    local function UpdateSpeedDisplay()
        local speed = Humanoid.WalkSpeed
        local label = tostring(speed)
        if Config.WalkEnabled then
            label = label .. " (Boosted)"
        else
            label = label .. " (Normal)"
        end
        speedVal.Text = label
        speedVal.TextColor3 = Config.WalkEnabled and Colors.Success or Colors.Accent
    end

    -- Hotkey display
    local keyDisplayBg = Instance.new("Frame")
    keyDisplayBg.Name = "KeyDisplay"
    keyDisplayBg.Size = UDim2.new(1, -24, 0, 52)
    keyDisplayBg.Position = UDim2.new(0, 12, 0, 195)
    keyDisplayBg.BackgroundColor3 = Colors.InputBg
    keyDisplayBg.BorderSizePixel = 0

    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = UDim.new(0, 6)
    keyCorner.Parent = keyDisplayBg

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(1, 0, 0, 20)
    keyLbl.Position = UDim2.new(0, 12, 0, 6)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = "Toggle Key"
    keyLbl.Font = Enum.Font.Gotham
    keyLbl.TextSize = 12
    keyLbl.TextColor3 = Colors.TextDim
    keyLbl.TextXAlignment = Enum.TextXAlignment.Left
    keyLbl.Parent = keyDisplayBg

    local keyBind = Instance.new("TextLabel")
    keyBind.Size = UDim2.new(1, -24, 0, 24)
    keyBind.Position = UDim2.new(0, 12, 0, 24)
    keyBind.BackgroundTransparency = 1
    keyBind.Text = "[ LeftShift ]"
    keyBind.Font = Enum.Font.GothamBold
    keyBind.TextSize = 18
    keyBind.TextColor3 = Colors.Warning
    keyBind.TextXAlignment = Enum.TextXAlignment.Left
    keyBind.Parent = keyDisplayBg

    keyDisplayBg.Parent = walkSection

    -- ==========================================
    -- FOOTER
    -- ==========================================
    local Footer = Instance.new("Frame")
    Footer.Name = "Footer"
    Footer.Size = UDim2.new(1, 0, 0, 28)
    Footer.Position = UDim2.new(0, 0, 1, -28)
    Footer.BackgroundColor3 = Colors.HeaderBg
    Footer.BorderColor3 = Colors.Border
    Footer.BorderSizePixel = 1

    local FooterCorner = Instance.new("UICorner")
    FooterCorner.CornerRadius = UDim.new(0, 8)
    FooterCorner.Parent = Footer

    local FooterFill = Instance.new("Frame")
    FooterFill.Size = UDim2.new(1, 0, 0, 4)
    FooterFill.Position = UDim2.new(0, 0, 0, -4)
    FooterFill.BackgroundColor3 = Colors.HeaderBg
    FooterFill.BorderSizePixel = 0
    FooterFill.Parent = Footer

    local footerText = Instance.new("TextLabel")
    footerText.Size = UDim2.new(1, -16, 1, 0)
    footerText.Position = UDim2.new(0, 16, 0, 0)
    footerText.BackgroundTransparency = 1
    footerText.Text = "Premium Edition  •  Press [LeftShift] to toggle Walk"
    footerText.Font = Enum.Font.Gotham
    footerText.TextSize = 10
    footerText.TextColor3 = Colors.TextDim
    footerText.TextXAlignment = Enum.TextXAlignment.Left
    footerText.Parent = Footer

    Footer.Parent = MainFrame

    -- ==========================================
    -- MINIMIZE BUTTON (small icon top-right)
    -- ==========================================
    local MinimizeBtn = Instance.new("ImageButton")
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 16, 0, 16)
    MinimizeBtn.Position = UDim2.new(0, 10, 1, -22)
    MinimizeBtn.BackgroundTransparency = 1
    MinimizeBtn.Image = "rbxassetid://6034697041"
    MinimizeBtn.ImageColor3 = Colors.TextDim
    MinimizeBtn.Parent = MainFrame

    MinimizeBtn.MouseButton1Click:Connect(function()
        Body.Visible = not Body.Visible
        NavBar.Visible = not NavBar.Visible
        MinimizeBtn.Rotation = Body.Visible and 0 or 180
    end)

    MainFrame.Parent = ScreenGui

    -- Return all the important UI elements so we can update them
    return {
        ScreenGui = ScreenGui,
        MainFrame = MainFrame,
        SpeedVal = speedVal,
        UpdateSpeedDisplay = UpdateSpeedDisplay,
    }
end

-- ==========================================
-- CREATE UI
-- ==========================================
local UI = CreatePremiumUI()

-- ==========================================
-- SERVICES (CONTINUED)
-- ==========================================

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function Log(msg)
    print("[GardenBot] " .. tostring(msg))
end

local function GetDistance(a, b)
    return (a.Position - b.Position).Magnitude
end

local function IsAlive()
    return Character and Character:FindFirstChild("Humanoid") and Humanoid.Health > 0
end

-- ==========================================
-- WALK SPEED CONTROL
-- ==========================================

-- Save original speed
State.OriginalSpeed = Humanoid.WalkSpeed

-- Toggle walk with keybind
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.LeftShift then
        Config.WalkEnabled = not Config.WalkEnabled
        State.WalkEnabled = Config.WalkEnabled
        
        if Config.WalkEnabled then
            Humanoid.WalkSpeed = Config.WalkSpeed
            Log("Fast Walk ENABLED (" .. Config.WalkSpeed .. ")")
        else
            Humanoid.WalkSpeed = State.OriginalSpeed
            Log("Fast Walk DISABLED (reset to " .. State.OriginalSpeed .. ")")
        end
        
        -- Update UI
        if UI and UI.UpdateSpeedDisplay then
            UI.UpdateSpeedDisplay()
        end
    end
end)

-- Update speed display every second
spawn(function()
    while wait(1) do
        if UI and UI.UpdateSpeedDisplay then
            UI.UpdateSpeedDisplay()
        end
    end
end)

-- ==========================================
-- ANTI-AFK
-- ==========================================

local function AntiAFK()
    if Player then
        Player.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            Log("Anti-AFK triggered")
        end)
    end
end

-- ==========================================
-- EVENT DETECTION
-- ==========================================

local function CheckEventStatus()
    local eventActive = false
    local eventEndingSoon = false
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("StringValue") and v.Name == "EventStatus" then
            if v.Value == "Active" then
                eventActive = true
            elseif v.Value == "Ending" then
                eventEndingSoon = true
                eventActive = true
            end
        end
    end
    
    local collectionGui = Player:FindFirstChild("PlayerGui"):FindFirstChild("CollectionGUI")
        or Player:FindFirstChild("PlayerGui"):FindFirstChild("EventGUI")
    
    if collectionGui then
        eventActive = true
        local timerLabel = collectionGui:FindFirstChild("Timer")
            or collectionGui:FindFirstChild("TimeLeft")
        if timerLabel and timerLabel:IsA("TextLabel") then
            local timeText = timerLabel.Text
            local timeNum = tonumber(timeText:match("%d+"))
            if timeNum and timeNum <= 10 then
                eventEndingSoon = true
            end
        end
    end
    
    State.InEvent = eventActive
    State.EventEnding = eventEndingSoon
    return eventActive, eventEndingSoon
end

-- ==========================================
-- SEED/ITEM DETECTION
-- ==========================================

local function IsCollectibleSeed(part)
    if not part or not part:IsA("BasePart") then return false end
    
    local itemName = part.Name or ""
    local parentName = part.Parent and part.Parent.Name or ""
    
    for _, seedType in pairs(SEED_TYPES) do
        if itemName:find(seedType) or parentName:find(seedType) then
            return true
        end
    end
    
    if itemName:find("Seed") or parentName:find("Seed") then
        return true
    end
    
    if itemName:find("Collectible") or part:GetAttribute("Collectible") then
        return true
    end
    
    if part:FindFirstChild("ClickDetector") then
        return true
    end
    
    return false
end

local function FindCollectibleSeeds()
    local seeds = {}
    
    for _, v in ipairs(Workspace:GetDescendants()) do
        if IsCollectibleSeed(v) then
            table.insert(seeds, v)
        end
    end
    
    table.sort(seeds, function(a, b)
        return GetDistance(RootPart, a) < GetDistance(RootPart, b)
    end)
    
    return seeds
end

-- ==========================================
-- COLLECTION LOGIC
-- ==========================================

local function AttemptCollect(part)
    if not part or not part.Parent then return false end
    
    local success = false
    
    -- Method 1: Remote events
    local remote = ReplicatedStorage:FindFirstChild("CollectSeed")
        or ReplicatedStorage:FindFirstChild("Collect")
        or ReplicatedStorage:FindFirstChild("GrabItem")
        or ReplicatedStorage:FindFirstChild("Pickup")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(part)
        success = true
    end
    
    -- Method 2: Remote function
    local remoteFunc = ReplicatedStorage:FindFirstChild("CollectSeed_Func")
        or ReplicatedStorage:FindFirstChild("Collect_Func")
    if remoteFunc and remoteFunc:IsA("RemoteFunction") then
        remoteFunc:InvokeServer(part)
        success = true
    end
    
    -- Method 3: ClickDetector
    local clickDetector = part:FindFirstChild("ClickDetector")
    if clickDetector then
        fireclickdetector(clickDetector)
        success = true
    end
    
    -- Method 4: Module scripts
    for _, v in ipairs(Player:GetDescendants()) do
        if v:IsA("ModuleScript") and (v.Name:find("Collect") or v.Name:find("Seed")) then
            local module = require(v)
            if type(module) == "table" and type(module.Collect) == "function" then
                module.Collect(part)
                success = true
            elseif type(module) == "function" then
                module(part)
                success = true
            end
        end
    end
    
    -- Method 5: Touch trigger
    if part:FindFirstChild("TouchInterest") or part.CanCollide == false then
        part.CFrame = RootPart.CFrame * CFrame.new(0, -2, 0)
        success = true
    end
    
    return success
end

local function CollectSeeds()
    if State.Collecting then return end
    State.Collecting = true
    
    local seeds = FindCollectibleSeeds()
    local collected = 0
    
    for _, seed in ipairs(seeds) do
        if not State.Running then break end
        
        local dist = GetDistance(RootPart, seed)
        
        if dist > Config.CollectRadius then
            -- Use walk speed if enabled
            if Config.WalkEnabled then
                Humanoid.WalkSpeed = Config.WalkSpeed
            end
            Humanoid:MoveTo(seed.Position)
            wait(0.3)
        end
        
        if seed and seed.Parent then
            local success = AttemptCollect(seed)
            if success then
                collected = collected + 1
            end
        end
        
        wait(0.15)
    end
    
    Log("Collected " .. tostring(collected) .. " items")
    State.Collecting = false
end

-- ==========================================
-- RETURN TO BASE
-- ==========================================

local function FindSpawnPoint()
    local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
        or Workspace:FindFirstChild("Base")
        or Workspace:FindFirstChild("Home")
        or Workspace:FindFirstChild("Spawn")
    
    if spawnLocation then
        return spawnLocation.Position
    end
    
    local spawns = Workspace:FindFirstChild("SpawnLocations")
    if spawns then
        local spawnPoint = spawns:FindFirstChild(Player.Name)
            or spawns:FindFirstChildOfClass("SpawnLocation")
        if spawnPoint then
            return spawnPoint.Position
        end
    end
    
    return Vector3.new(0, 10, 0)
end

local function ReturnToBase()
    Log("Returning to base...")
    local targetPos = FindSpawnPoint()
    
    if Config.WalkEnabled then
        Humanoid.WalkSpeed = Config.WalkSpeed
    end
    Humanoid:MoveTo(targetPos)
    
    local startTime = tick()
    while tick() - startTime < 15 do
        wait(0.5)
        if not IsAlive() then break end
        
        local spawnObj = Workspace:FindFirstChild("SpawnLocation")
        local spawnDist = spawnObj and GetDistance(RootPart, spawnObj) or GetDistance(RootPart, CFrame.new(targetPos))
        
        if spawnDist < 5 then
            Log("Arrived at base")
            if not Config.WalkEnabled then
                Humanoid.WalkSpeed = State.OriginalSpeed
            end
            return true
        end
        
        Humanoid:MoveTo(targetPos)
    end
    
    if not Config.WalkEnabled then
        Humanoid.WalkSpeed = State.OriginalSpeed
    end
    return false
end

-- ==========================================
-- EVENT AUTO-RETURN
-- ==========================================

local function OnEventEnding()
    if not Config.AutoReturn then return end
    
    Log("Event ending detected! Returning to base...")
    ReturnToBase()
    wait(3)
    State.InEvent = false
    State.EventEnding = false
end

-- ==========================================
-- CHARACTER RESET HANDLING
-- ==========================================

Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
    State.OriginalSpeed = Humanoid.WalkSpeed
    Log("Character respawned")
    wait(1)
end)

-- ==========================================
-- MAIN LOOP
-- ==========================================

local function MainLoop()
    Log("Garden Bot Premium started")
    Log("Press [LeftShift] to toggle Fast Walk")
    
    AntiAFK()
    
    local lastEventCheck = 0
    local lastCollection = 0
    
    while State.Running do
        wait(0.1)
        
        if not IsAlive() then
            wait(1)
            continue
        end
        
        local currentTime = tick()
        
        -- Check event status
        if currentTime - lastEventCheck >= Config.EventCheckInterval then
            local inEvent, eventEnding = CheckEventStatus()
            if eventEnding then
                OnEventEnding()
            end
            lastEventCheck = currentTime
        end
        
        -- Auto-collect
        if Config.AutoCollect and currentTime - lastCollection >= Config.ScanInterval then
            CollectSeeds()
            lastCollection = currentTime
        end
    end
end

-- ==========================================
-- START
-- ==========================================

coroutine.wrap(MainLoop)()