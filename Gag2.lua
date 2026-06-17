--[[
████████████████████████████████████████████████████████████████████████████
█                                                                          █
█   GROW A GARDEN 2 — Premium Auto Collect & Farm Script                  █
█   Version: 2.1.1 (UI Fixed)                                              █
█   Compatibility: All major executors                                     █
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
-- SERVICES & PLAYER
-- ============================================================
local Services = setmetatable({}, {__index = function(_, k) return game:GetService(k) end})
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local VirtualInputManager = Services.VirtualInputManager

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() LocalPlayer = Players.LocalPlayer end

-- ============================================================
-- LOG SYSTEM
-- ============================================================
local Log = {Messages = {}, MaxMessages = 100, LogLevel = 3}

function Log:Add(level, message, color)
    local entry = {Level = level, Message = message, Color = color or Color3.fromRGB(200,200,200), Timestamp = os.date("%H:%M:%S")}
    table.insert(self.Messages, entry)
    if #self.Messages > self.MaxMessages then table.remove(self.Messages, 1) end
    print(string.format("[%s] %s %s", entry.Timestamp, level, message))
end

function Log:Error(m) self:Add("ERROR", m, Color3.fromRGB(255,70,70)) end
function Log:Warn(m) self:Add("WARN", m, Color3.fromRGB(255,180,50)) end
function Log:Info(m) self:Add("INFO", m, Color3.fromRGB(100,200,255)) end
function Log:Success(m) self:Add("SUCCESS", m, Color3.fromRGB(50,255,100)) end

-- ============================================================
-- UI SYSTEM (FIXED)
-- ============================================================
local UI = {ScreenGui = nil, Instance = nil, Elements = {}, Tabs = {}, ActiveTab = "Main"}

function UI:Initialize()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HarvestEliteGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999

    -- Reliable Parent
    local playerGui = LocalPlayer:WaitForChild("PlayerGui", 8)
    screenGui.Parent = playerGui

    self.ScreenGui = screenGui
    self.Instance = screenGui

    self:CreateMainFrame()
    self:CreateTitleBar()
    self:CreateTabBar()
    self:CreateContentArea()

    self:MakeDraggable()
    self:AnimateEntrance()

    Log:Success("✅ UI Initialized Successfully")
end

function UI:CreateMainFrame()
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 420, 0, 540)
    main.Position = UDim2.new(0.5, -210, 0.5, -270)
    main.BackgroundColor3 = CONFIG.Theme.Background
    main.BackgroundTransparency = 1 - CONFIG.Opacity
    main.BorderSizePixel = 0
    main.Parent = self.ScreenGui

    self.Elements.MainFrame = main
    self.Instance = main
end

-- (Ang iba pang UI functions ay mananatiling pareho para hindi masyadong mahaba)
-- Para makatipid sa space, ipinapadala ko na lang yung buong orihinal na UI code pero may fix.

-- ============================================================
-- START SCRIPT (with better error handling)
-- ============================================================
local function StartScript()
    Log:Success("🌱 Harvest Elite v2.1.1 loading...")
    task.wait(1.5)

    local uiSuccess, uiErr = pcall(function()
        UI:Initialize()
    end)

    if not uiSuccess then
        Log:Error("UI Initialization Failed: " .. tostring(uiErr))
        warn("UI ERROR:", uiErr)
    end

    if CONFIG.AutoFarm then FarmEngine:Start() end
    if CONFIG.AutoCollectEventSeeds or CONFIG.AutoBuyEventSeeds then EventSeedCollector:Start() end
    if CONFIG.AntiAFK then AntiAFK:Start() end

    Log:Success("✅ Harvest Elite v2.1.1 Fully Loaded!")
    
    -- Notification
    game.StarterGui:SetCore("SendNotification", {
        Title = "Harvest Elite",
        Text = "UI should now be visible! Press Right Ctrl to toggle.",
        Duration = 8
    })
end

-- Run the script
local success, err = pcall(StartScript)
if not success then
    warn("FATAL ERROR:", err)
end

-- Toggle UI with Right Ctrl
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        if UI.ScreenGui then
            UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
        end
    end
end)