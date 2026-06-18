--[[
    Grow a Garden 2 - Advanced Auto Farm Script
    For authorized educational/automation purposes only
]]

-- Configuration
local Config = {
    AutoCollect = true,
    AutoReturn = true,
    FastWalk = true,
    WalkSpeed = 24,          -- Default is 16, max safe ~30-32
    CollectRadius = 25,      -- Collection radius in studs
    ScanInterval = 0.5,      -- Seconds between scans
    EventCheckInterval = 2,  -- Seconds between event checks
}

-- Seed types to prioritize
local SEED_TYPES = {
    GoldSeed = "Gold Seed",
    RainbowSeed = "Rainbow Seed", 
    Bird = "Bird",
    SeedPack = "Seed Pack",
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

-- Local player setup
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- State tracking
local State = {
    Collecting = false,
    InEvent = false,
    EventEnding = false,
    Running = true,
}

-- ==========================================
-- UTILITY FUNCTIONS
-- ==========================================

local function Log(msg)
    warn("[GardenBot] " .. tostring(msg))
end

local function GetDistance(a, b)
    return (a.Position - b.Position).Magnitude
end

local function IsAlive()
    return Character and Character:FindFirstChild("Humanoid") and Humanoid.Health > 0
end

local function ToggleFastWalk(enable)
    if not Config.FastWalk then return end
    if enable then
        Humanoid.WalkSpeed = Config.WalkSpeed
    else
        Humanoid.WalkSpeed = 16
    end
end

local function MoveTo(targetPosition)
    if not IsAlive() then return end
    ToggleFastWalk(true)
    Humanoid:MoveTo(targetPosition)
end

-- ==========================================
-- EVENT DETECTION
-- ==========================================

local function CheckEventStatus()
    -- Look for event indicators in the workspace
    local eventActive = false
    local eventEndingSoon = false
    
    -- Common event indicators: GUI frames, workspace objects, or value objects
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
    
    -- Check for collection GUI (gather zone indicators)
    local collectionGui = Player:FindFirstChild("PlayerGui"):FindFirstChild("CollectionGUI")
        or Player:FindFirstChild("PlayerGui"):FindFirstChild("EventGUI")
    
    if collectionGui then
        eventActive = true
        -- Check for event end countdown
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
    -- Check if part is a seed/dropped item we want
    if not part or not part:IsA("BasePart") then return false end
    
    local itemName = part.Name or ""
    local parentName = part.Parent and part.Parent.Name or ""
    
    -- Check against our target seed types
    for _, seedType in pairs(SEED_TYPES) do
        if itemName:find(seedType) or parentName:find(seedType) then
            return true
        end
    end
    
    -- Generic collectible detection
    if itemName:find("Seed") or parentName:find("Seed") then
        return true
    end
    
    if itemName:find("Collectible") or part:GetAttribute("Collectible") then
        return true
    end
    
    -- Check if it has a ClickDetector (manual collect)
    if part:FindFirstChild("ClickDetector") then
        return true
    end
    
    return false
end

local function FindCollectibleSeeds()
    local seeds = {}
    
    -- Search workspace for collectible items
    for _, v in ipairs(Workspace:GetDescendants()) do
        if IsCollectibleSeed(v) then
            table.insert(seeds, v)
        end
    end
    
    -- Sort by distance (closest first)
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
    
    -- Method 1: Fire remote (most modern games)
    local remote = ReplicatedStorage:FindFirstChild("CollectSeed")
        or ReplicatedStorage:FindFirstChild("Collect")
        or ReplicatedStorage:FindFirstChild("GrabItem")
        or ReplicatedStorage:FindFirstChild("Pickup")
        or ReplicatedStorage:FindFirstChild("RemoteEvent")
    
    if remote and remote:IsA("RemoteEvent") then
        remote:FireServer(part)
        success = true
    end
    
    -- Method 2: Fire remote function
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
    
    -- Method 4: Find collection module in player scripts
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
        
        -- Check distance first
        local dist = GetDistance(RootPart, seed)
        
        if dist > Config.CollectRadius then
            -- Move closer
            MoveTo(seed.Position)
            wait(0.3)
        end
        
        -- Attempt collection
        if seed and seed.Parent then
            local success = AttemptCollect(seed)
            if success then
                collected = collected + 1
            end
        end
        
        -- Small delay between collections
        wait(0.15)
    end
    
    Log("Collected " .. tostring(collected) .. " items")
    State.Collecting = false
end

-- ==========================================
-- RETURN TO BASE LOGIC
-- ==========================================

local function FindSpawnPoint()
    -- Find the spawn location
    local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
        or Workspace:FindFirstChild("Base")
        or Workspace:FindFirstChild("Home")
        or Workspace:FindFirstChild("Spawn")
    
    if spawnLocation then
        return spawnLocation.Position
    end
    
    -- Fallback: use player's spawn
    local spawns = Workspace:FindFirstChild("SpawnLocations")
    if spawns then
        local spawnPoint = spawns:FindFirstChild(Player.Name) 
            or spawns:FindFirstChildOfClass("SpawnLocation")
        if spawnPoint then
            return spawnPoint.Position
        end
    end
    
    -- Last resort: (0, 10, 0)
    return Vector3.new(0, 10, 0)
end

local function ReturnToBase()
    Log("Returning to base...")
    local targetPos = FindSpawnPoint()
    
    MoveTo(targetPos)
    
    -- Wait until we arrive or timeout
    local startTime = tick()
    while tick() - startTime < 15 do
        wait(0.5)
        if not IsAlive() then break end
        
        local dist = GetDistance(RootPart, CFrame.new(targetPos).Position)
        -- Also check using workspace spawn
        local spawnObj = Workspace:FindFirstChild("SpawnLocation")
        local spawnDist = spawnObj and GetDistance(RootPart, spawnObj) or dist
        
        if spawnDist < 5 then
            Log("Arrived at base")
            ToggleFastWalk(false)
            return true
        end
        
        -- Re-issue move command
        MoveTo(targetPos)
    end
    
    ToggleFastWalk(false)
    return false
end

-- ==========================================
-- EVENT AUTO-RETURN (triggered by event end)
-- ==========================================

local function OnEventEnding()
    if not Config.AutoReturn then return end
    
    Log("Event ending detected! Returning to base...")
    ReturnToBase()
    
    -- Wait out the event transition
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
    Log("Character respawned")
    wait(1)
end)

-- ==========================================
-- ANTI-AFK
-- ==========================================

local function AntiAFK()
    if Player then
        local vUser = game:GetService("VirtualUser")
        Player.Idled:Connect(function()
            vUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            wait(1)
            vUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            Log("Anti-AFK triggered")
        end)
    end
end

-- ==========================================
-- MAIN LOOP
-- ==========================================

local function MainLoop()
    Log("Garden Bot started - AutoCollect: " .. tostring(Config.AutoCollect) ..
        ", AutoReturn: " .. tostring(Config.AutoReturn) ..
        ", FastWalk: " .. tostring(Config.FastWalk))
    
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
        
        -- Check event status periodically
        if currentTime - lastEventCheck >= Config.EventCheckInterval then
            local inEvent, eventEnding = CheckEventStatus()
            
            if eventEnding then
                OnEventEnding()
            end
            
            lastEventCheck = currentTime
        end
        
        -- Auto-collect seeds
        if Config.AutoCollect and currentTime - lastCollection >= Config.ScanInterval then
            CollectSeeds()
            lastCollection = currentTime
        end
    end
end

-- ==========================================
-- USER COMMANDS (Run these in console to control)
-- ==========================================

--[[
-- Control commands (copy & paste into console):
--
-- Start bot:
_G.GardenBot = true
_G.StartBot = coroutine.wrap(MainLoop)
_G.StartBot()

-- Toggle features:
Config.AutoCollect = false  -- Disable auto collect
Config.AutoCollect = true   -- Enable auto collect
Config.AutoReturn = false   -- Disable auto return
Config.FastWalk = false     -- Disable fast walk

-- Manually return to base:
ReturnToBase()

-- Force collect now:
CollectSeeds()

-- Stop bot:
State.Running = false
Config.AutoCollect = false

-- Change walk speed (default 24):
Config.WalkSpeed = 28
Humanoid.WalkSpeed = Config.WalkSpeed

-- Change scan radius:
Config.CollectRadius = 35

-- Adjust scan speed:
Config.ScanInterval = 0.3  -- Faster scanning (may be detected)
Config.ScanInterval = 1.0  -- Slower scanning (stealthier)
--]]

-- Auto-start
coroutine.wrap(MainLoop)()