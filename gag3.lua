--[[
████████████████████████████████████████████████████████████████████████████
█                                                                          █
█   GROW A GARDEN 2 — Premium Auto Collect & Farm Script                  █
█   Version: 2.1.1 (UI FIXED)                                              █
█   Compatibility: All major executors                                    █
█                                                                          █
████████████████████████████████████████████████████████████████████████████
--]]

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
-- SECTION 2: SERVICES
-- ============================================================
local Services = setmetatable({}, {__index = function(_, k) return game:GetService(k) end})
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local VirtualInputManager = Services.VirtualInputManager

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- SECTIONS 3-7: UTILITIES, ENGINES, LOG (kept as original)
-- ============================================================
local Utilities = {} -- (full original utilities here - same as your file)

-- Paste the rest of your original Sections 3-7 here if needed. For brevity, the critical fix is below.

-- ============================================================
-- SECTION 8: FIXED UI (Main Fix)
-- ============================================================
local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    Elements = {},
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    Minimized = false,
    Tabs = {},
    ActiveTab = "Main",
}

function UI:Initialize()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HarvestEliteGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.IgnoreGuiInset = true

    if gethui then
        screenGui.Parent = gethui()
    else
        pcall(function() screenGui.Parent = game:GetService("CoreGui") end)
    end

    if not screenGui.Parent then
        local pg = LocalPlayer:FindFirstChild("PlayerGui") or Instance.new("PlayerGui")
        screenGui.Parent = pg
    end

    self.ScreenGui = screenGui
    self:CreateMainFrame()
    self:CreateTitleBar()
    self:CreateTabBar()
    self:CreateContentArea()
    self:CreateStatusBar()

    self:MakeDraggable()
    self:AnimateEntrance()

    Log:Success("🌐 UI Initialized Successfully")
end

function UI:CreateMainFrame()
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 420, 0, 540)
    main.Position = UDim2.new(0.5, -210, 0.5, -270)
    main.BackgroundColor3 = CONFIG.Theme.Background
    main.BackgroundTransparency = 1 - CONFIG.Opacity
    main.BorderSizePixel = 0
    main.ClipsDescendants = true
    main.Parent = self.ScreenGui

    self.MainFrame = main
    self.Elements.MainFrame = main
end

-- The rest of the UI functions (CreateTitleBar, CreateTabBar, etc.) are the same as your original.
-- To save space here, copy the rest from your original file and just use the fixed Initialize and MainFrame.

-- Hotkey Fix
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        if UI.ScreenGui then
            UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
        end
    end
end)

Log:Success("🌱 Harvest Elite v2.1.1 Loaded - UI should now appear!")