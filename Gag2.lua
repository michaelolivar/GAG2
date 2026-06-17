--[[
████████████████████████████████████████████████████████████████████████████
█                                                                          █
█   GROW A GARDEN 2 — Premium Auto Collect & Farm Script                  █
█   Version: 2.1.0                                                         █
█   Compatibility: All major executors (Synapse, Delta, Solara, Codex)    █
█   Author: HackerAI Security Research                                     █
█                                                                          █
█   DISCLAIMER: For authorized pentesting & educational purposes only.    █
█   Report bugs to game devs responsibly.                                  █
█                                                                          █
████████████████████████████████████████████████████████████████████████████
--]]

-- ============================================================
-- SECTION 1: CONFIGURATION (User-editable settings)
-- ============================================================
local CONFIG = {
    -- Core Toggles
    AutoCollectEventSeeds = true,      -- Auto-collect event seeds from shop
    AutoBuyEventSeeds = true,           -- Auto-purchase event seeds when in stock
    AutoFarm = true,                    -- Full auto farm cycle
    AutoPlant = true,                   -- Plant seeds automatically
    AutoHarvest = true,                 -- Harvest mature crops
    AutoSell = true,                    -- Sell harvested crops
    AutoWater = true,                   -- Water plants if needed
    AntiAFK = true,                     -- Prevent kick for inactivity
    AutoSteal = false,                  -- Steal from other gardens (use at own risk)

    -- Event Seed Configuration
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

    -- Farming Settings
    MinShecklesToKeep = 1000,           -- Minimum balance to maintain
    HarvestRadius = 50,                 -- Radius to scan for harvestable crops
    PlantRadius = 30,                   -- Radius to scan for empty plots
    MaxPlants = 100,                    -- Maximum plants to maintain
    PreferredSeeds = {"Moon Bloom", "Dragon's Breath", "Ghost Pepper", "Glow Mushroom"},

    -- UI Settings
    Theme = {
        Primary = Color3.fromRGB(30, 200, 80),      -- Emerald green
        Secondary = Color3.fromRGB(20, 150, 60),     -- Darker green
        Accent = Color3.fromRGB(255, 215, 0),        -- Gold
        Background = Color3.fromRGB(15, 15, 25),     -- Dark
        Surface = Color3.fromRGB(25, 25, 40),        -- Card surface
        Text = Color3.fromRGB(230, 230, 240),        -- Light text
        Danger = Color3.fromRGB(255, 70, 70),        -- Red
        Warning = Color3.fromRGB(255, 180, 50),      -- Orange
    },
    Opacity = 0.92,
    Font = Enum.Font.GothamBold,
    Title = "🌱 HARVEST ELITE  •  v2.1.0"
}

-- ============================================================
-- SECTION 2: SERVICE CACHING (Optimized lookups)
-- ============================================================
local Services = setmetatable({}, {
    __index = function(_, key)
        local success, service = pcall(function()
            return game:GetService(key)
        end)
        return success and service or nil
    end
})

local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local TweenService = Services.TweenService
local VirtualInputManager = Services.VirtualInputManager
local MarketplaceService = Services.MarketplaceService
local HttpService = Services.HttpService

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- FORWARD DECLARATIONS (needed before engines reference them)
-- ============================================================
local Log = {
    Messages = {},
    MaxMessages = 100,
    LogLevel = 3,  -- 1=Error, 2=Warn, 3=Info, 4=Debug
}

function Log:Add(level, message, color)
    local entry = {
        Level = level,
        Message = message,
        Color = color or Color3.fromRGB(200, 200, 200),
        Time = os.time(),
        Timestamp = os.date("%H:%M:%S"),
    }
    table.insert(self.Messages, entry)
    if #self.Messages > self.MaxMessages then
        table.remove(self.Messages, 1)
    end
    local prefix = os.date("[%H:%M:%S]")
    local icons = {["ERROR"] = "\226\156\150", ["WARN"] = "\226\154\160", ["INFO"] = "\226\132\185", ["DEBUG"] = "\226\151\143", ["SUCCESS"] = "\226\156\148"}
    local icon = icons[level] or "●"
    print(string.format("%s %s %s", prefix, icon, message))
end

function Log:Error(message) self:Add("ERROR", message, Color3.fromRGB(255, 70, 70)) end
function Log:Warn(message) self:Add("WARN", message, Color3.fromRGB(255, 180, 50)) end
function Log:Info(message) self:Add("INFO", message, Color3.fromRGB(100, 200, 255)) end
function Log:Debug(message)
    if self.LogLevel >= 4 then
        self:Add("DEBUG", message, Color3.fromRGB(150, 150, 150))
    end
end
function Log:Success(message) self:Add("SUCCESS", message, Color3.fromRGB(50, 255, 100)) end

local UI = {
    ScreenGui = nil,
    Instance = nil,
    Elements = {},
    Dragging = false,
    DragOffset = Vector2.new(0, 0),
    Minimized = false,
    Tabs = {},
    ActiveTab = "Main",
}

-- ============================================================
-- SECTION 3: UTILITY FUNCTIONS
-- ============================================================
local Utilities = {}

function Utilities.FindRemote(remoteName)
    local searchPaths = {
        game:GetService("ReplicatedStorage"),
        game:GetService("ReplicatedFirst"),
        LocalPlayer.PlayerGui,
        LocalPlayer.Backpack,
        LocalPlayer.Character,
        Workspace,
    }
    for _, container in ipairs(searchPaths) do
        if not container then continue end
        local found = container:FindFirstChild(remoteName, true)
        if found and (found:IsA("RemoteEvent") or found:IsA("RemoteFunction") or found:IsA("UnreliableRemoteEvent")) then
            return found
        end
    end
    -- Recursive scan as fallback
    for _, container in ipairs(searchPaths) do
        if not container then continue end
        for _, obj in ipairs(container:GetDescendants()) do
            if obj.Name == remoteName and (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) then
                return obj
            end
        end
    end
    return nil
end

function Utilities.FireRemote(remoteName, ...)
    local remote = Utilities.FindRemote(remoteName)
    if remote then
        local args = {...}
        local success, err = pcall(function()
            if remote:IsA("RemoteEvent") then
                remote:FireServer(unpack(args))
            elseif remote:IsA("RemoteFunction") then
                remote:InvokeServer(unpack(args))
            end
        end)
        if not success then
            warn("[HARVEST] Remote error:", err)
        end
        return success
    end
    return false
end

function Utilities.GetPlayerBalance()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        local currency = leaderstats:FindFirstChild("Sheckles")
            or leaderstats:FindFirstChild("Money")
            or leaderstats:FindFirstChild("Balance")
            or leaderstats:FindFirstChild("Points")
        if currency then
            return currency.Value
        end
    end
    -- Fallback: scan player for value objects
    for _, child in ipairs(LocalPlayer:GetDescendants()) do
        if child:IsA("NumberValue") and (child.Name:lower():find("sheck") or child.Name:lower():find("money") or child.Name:lower():find("coin")) then
            return child.Value
        end
    end
    return 0
end

function Utilities.FindClosestPlayer(radius)
    local closest, closestDist = nil, radius
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                and (LocalPlayer.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude)
                or math.huge
            if dist < closestDist then
                closestDist = dist
                closest = player
            end
        end
    end
    return closest, closestDist
end

function Utilities.GetPlantsInRadius(position, radius)
    local plants = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("plant") or obj.Name:lower():find("crop") or obj.Name:lower():find("seed")) then
            local primary = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
            if primary then
                local dist = (position - primary.Position).Magnitude
                if dist <= radius then
                    table.insert(plants, obj)
                end
            end
        end
    end
    return plants
end

function Utilities.GetHarvestablePlants(radius)
    local harvestable = {}
    local pos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
    local plants = Utilities.GetPlantsInRadius(pos, radius)
    for _, plant in ipairs(plants) do
        -- Check if plant is harvestable (has a ProximityPrompt or is glowing/ready)
        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt")
        local billboard = plant:FindFirstChildWhichIsA("BillboardGui")
        local clickDetector = plant:FindFirstChildWhichIsA("ClickDetector")
        if prompt or billboard or clickDetector then
            table.insert(harvestable, plant)
        end
        -- Also check for harvest value
        local harvestVal = plant:FindFirstChild("Harvested") or plant:FindFirstChild("Ready") or plant:FindFirstChild("Grown")
        if harvestVal and harvestVal.Value == true then
            table.insert(harvestable, plant)
        end
    end
    return harvestable
end

function Utilities.GetSeedInventory()
    local seeds = {}
    local backpack = LocalPlayer:FindFirstChild("Backpack") or LocalPlayer:FindFirstChildWhichIsA("Backpack")
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") or item:IsA("Part") then
                table.insert(seeds, item.Name)
            end
        end
    end
    local character = LocalPlayer.Character
    if character then
        for _, item in ipairs(character:GetChildren()) do
            if item:IsA("Tool") then
                table.insert(seeds, item.Name)
            end
        end
    end
    return seeds
end

function Utilities.HasSeed(seedName)
    local inventory = Utilities.GetSeedInventory()
    for _, name in ipairs(inventory) do
        if name:lower():find(seedName:lower()) then
            return true
        end
    end
    return false
end

-- ============================================================
-- SECTION 4: EVENT SEED AUTO-COLLECT ENGINE
-- ============================================================
local EventSeedCollector = {
    Running = false,
    Connection = nil,
    CollectedSeeds = {},
    CheckInterval = 3,  -- seconds between checks
}

function EventSeedCollector:Start()
    if self.Running then return end
    self.Running = true
    self.CollectedSeeds = {}

    self.Connection = RunService.Stepped:Connect(function()
        if not self.Running then return end
        self:CheckEventShop()
    end)

    -- Also run on a timer for reliability
    task.spawn(function()
        while self.Running do
            task.wait(self.CheckInterval)
            self:CheckEventShop()
        end
    end)

    return true
end

function EventSeedCollector:Stop()
    self.Running = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function EventSeedCollector:CheckEventShop()
    if not CONFIG.AutoCollectEventSeeds and not CONFIG.AutoBuyEventSeeds then return end

    -- Find the Seed Shop GUI / UI elements
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return end

    -- Scan for seed shop UI elements
    local shopFrame = nil
    for _, gui in ipairs(playerGui:GetDescendants()) do
        if gui:IsA("Frame") or gui:IsA("ScrollingFrame") then
            local name = gui.Name:lower()
            if name:find("shop") or name:find("seed") or name:find("event") or name:find("summer") or name:find("tom") then
                shopFrame = gui
                break
            end
        end
    end

    if not shopFrame then
        -- Try to open the shop UI
        self:OpenSeedShop()
        return
    end

    -- Scan for seed buttons/purchase options
    self:ScanAndPurchase(shopFrame)
end

function EventSeedCollector:OpenSeedShop()
    -- Find the NPC (Tom/Sam) and interact
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj.Name:lower():find("tom") or obj.Name:lower():find("sam") or obj.Name:lower():find("npc") or obj.Name:lower():find("shop")) then
            local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                -- Teleport nearby and trigger
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local primary = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
                    if primary then
                        hrp.CFrame = primary.CFrame * CFrame.new(0, 0, -3)
                        task.wait(0.5)
                        fireproximityprompt(prompt)
                        return
                    end
                end
            end
        end
    end

    -- Fallback: fire remote to open shop
    Utilities.FireRemote("OpenShop", "SeedShop")
    Utilities.FireRemote("ShopRequest", "Tom")
    Utilities.FireRemote("RequestShop")
end

function EventSeedCollector:ScanAndPurchase(shopFrame)
    if not CONFIG.AutoBuyEventSeeds then return end

    local balance = Utilities.GetPlayerBalance()

    -- Scan all buttons/items in the shop UI
    for _, item in ipairs(shopFrame:GetDescendants()) do
        if item:IsA("ImageButton") or item:IsA("TextButton") or item:IsA("Frame") then
            local itemName = item.Name
            -- Check if this matches an event seed
            for seedName, seedConfig in pairs(CONFIG.EventSeeds) do
                if not seedConfig.AutoBuy then continue end
                if itemName:lower():find(seedName:lower()) or (item:FindFirstChildOfClass("TextLabel")
                    and item:FindFirstChildOfClass("TextLabel").Text:lower():find(seedName:lower())) then

                    -- Check price
                    local priceLabel = item:FindFirstChild("Price") or item:FindFirstChildOfClass("TextLabel")
                    local price = seedConfig.MaxPrice
                    if priceLabel then
                        local priceText = priceLabel.Text:match("%d+")
                        if priceText then
                            price = tonumber(priceText) or price
                        end
                    end

                    -- Also check for "Out of Stock" or price display
                    local stockLabel = item:FindFirstChild("Stock") or item:FindFirstChild("Amount")
                    if stockLabel and stockLabel.Text:lower():find("out") or stockLabel and tonumber(stockLabel.Text) and tonumber(stockLabel.Text) <= 0 then
                        goto continue  -- skip if out of stock
                    end

                    if balance - price >= CONFIG.MinShecklesToKeep then
                        -- Attempt to buy/collect
                        if item:IsA("ImageButton") or item:IsA("TextButton") then
                            local success = pcall(function()
                                item:WaitForChild("GuiButton", 0.5)  -- some games have nested buttons
                                fireclickdetector(item:FindFirstChildWhichIsA("ClickDetector"))
                                item:WaitForChild("ClickDetector", 0.5)
                            end)
                            -- Fire button click
                            local clickDetector = item:FindFirstChildWhichIsA("ClickDetector")
                            if clickDetector then
                                fireclickdetector(clickDetector)
                                table.insert(self.CollectedSeeds, seedName)
                                Log:Info(string.format("✅ Bought event seed: %s (₿%d)", seedName, price))
                                task.wait(0.3)
                            else
                                -- Simulate click
                                local absPos = item.AbsolutePosition
                                VirtualInputManager:SendMouseButtonEvent(absPos.X + 5, absPos.Y + 5, 0, true, game, 1)
                                task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(absPos.X + 5, absPos.Y + 5, 0, false, game, 1)
                                table.insert(self.CollectedSeeds, seedName)
                                Log:Info(string.format("✅ Clicked to buy: %s", seedName))
                                task.wait(0.3)
                            end
                        end
                    end
                end
                ::continue::
            end
        end
    end
end

-- ============================================================
-- SECTION 5: AUTO FARM CORE ENGINE
-- ============================================================
local FarmEngine = {
    Running = false,
    Connection = nil,
    CycleCount = 0,
    TotalEarned = 0,
}

function FarmEngine:Start()
    if self.Running then return end
    self.Running = true

    self.Connection = RunService.Stepped:Connect(function()
        if not self.Running then return end
        self:FarmCycle()
    end)

    task.spawn(function()
        while self.Running do
            task.wait(2)
            self:FarmCycle()
        end
    end)

    Log:Success("🌱 Farm Engine started")
    return true
end

function FarmEngine:Stop()
    self.Running = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function FarmEngine:FarmCycle()
    if not CONFIG.AutoFarm then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end

    local pos = LocalPlayer.Character.HumanoidRootPart.Position
    self.CycleCount = self.CycleCount + 1

    -- Phase 1: Harvest mature plants
    if CONFIG.AutoHarvest then
        self:HarvestPlants(pos)
    end

    -- Phase 2: Plant new seeds
    if CONFIG.AutoPlant then
        self:PlantSeeds(pos)
    end

    -- Phase 3: Water plants
    if CONFIG.AutoWater then
        self:WaterPlants(pos)
    end

    -- Phase 4: Sell harvest
    if CONFIG.AutoSell then
        self:SellHarvest()
    end
end

function FarmEngine:HarvestPlants(position)
    local plants = Utilities.GetHarvestablePlants(CONFIG.HarvestRadius)
    local harvested = 0

    for _, plant in ipairs(plants) do
        if not self.Running then break end

        -- Try proximity prompt
        local prompt = plant:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            local primary = plant:FindFirstChild("PrimaryPart") or plant:FindFirstChildOfClass("Part")
            if primary then
                -- Move nearby
                LocalPlayer.Character.HumanoidRootPart.CFrame = primary.CFrame * CFrame.new(0, 0, -2)
                task.wait(0.1)
                fireproximityprompt(prompt)
                harvested = harvested + 1
                task.wait(0.15)
            end
        end

        -- Try click detector
        local clickDetector = plant:FindFirstChildWhichIsA("ClickDetector")
        if clickDetector then
            fireclickdetector(clickDetector)
            harvested = harvested + 1
            task.wait(0.1)
        end

        -- Try remote harvesting
        local remoteNames = {"Harvest", "Collect", "Pick", "Gather", "HarvestPlant"}
        for _, remoteName in ipairs(remoteNames) do
            local remote = Utilities.FindRemote(remoteName)
            if remote then
                Utilities.FireRemote(remoteName, plant)
                harvested = harvested + 1
                break
            end
        end

        -- Limit per cycle
        if harvested >= 15 then break end
    end

    if harvested > 0 then
        Log:Debug(string.format("🧺 Harvested %d plants", harvested))
    end
end

function FarmEngine:PlantSeeds(position)
    local seedInventory = Utilities.GetSeedInventory()
    if #seedInventory == 0 then return end

    -- Find empty plots / seedbeds
    local plots = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (obj:IsA("Part") or obj:IsA("MeshPart")) and (name:find("plot") or name:find("bed") or name:find("soil") or name:find("dirt") or name:find("ground")) then
            local dist = (position - obj.Position).Magnitude
            if dist <= CONFIG.PlantRadius then
                table.insert(plots, obj)
            end
        end
    end

    local planted = 0
    for _, plot in ipairs(plots) do
        if not self.Running then break end
        if planted >= 5 then break end  -- Limit per cycle

        -- Equip a seed tool
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, seedTool in ipairs(backpack:GetChildren()) do
                if seedTool:IsA("Tool") and seedTool.Name:lower():find("seed") == nil then
                    -- Check if it's one of our preferred seeds or any seed
                    local isPreferred = false
                    for _, prefSeed in ipairs(CONFIG.PreferredSeeds) do
                        if seedTool.Name:lower():find(prefSeed:lower()) then
                            isPreferred = true
                            break
                        end
                    end
                    if isPreferred or #CONFIG.PreferredSeeds == 0 then
                        -- Equip the tool
                        LocalPlayer.Character.Humanoid:EquipTool(seedTool)
                        task.wait(0.2)

                        -- Move to plot
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(plot.Position + Vector3.new(0, 1, 0))
                        task.wait(0.15)

                        -- Plant using remote
                        Utilities.FireRemote("PlantSeed", plot.Position, seedTool.Name)
                        Utilities.FireRemote("Plant", plot, seedTool)
                        Utilities.FireRemote("Grow", seedTool.Name, plot.Position)

                        planted = planted + 1
                        task.wait(0.2)
                        break
                    end
                end
            end
        end
    end

    if planted > 0 then
        Log:Debug(string.format("🌱 Planted %d seeds", planted))
    end
end

function FarmEngine:WaterPlants(position)
    -- Find watering can tool
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    local wateringCan = nil
    if backpack then
        wateringCan = backpack:FindFirstChild("Watering Can") or backpack:FindFirstChild("WateringCan")
    end
    if not wateringCan then
        local char = LocalPlayer.Character
        if char then
            wateringCan = char:FindFirstChild("Watering Can") or char:FindFirstChild("WateringCan")
        end
    end

    if not wateringCan then return end

    -- Equip watering can
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:EquipTool(wateringCan)
        task.wait(0.15)
    end

    -- Find plants that need watering
    local watered = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if not self.Running then break end
        if watered >= 10 then break end

        if obj:IsA("Model") and (obj.Name:lower():find("plant") or obj.Name:lower():find("crop") or obj.Name:lower():find("seed")) then
            -- Check if needs water
            local waterLevel = obj:FindFirstChild("Water") or obj:FindFirstChild("Hydration") or obj:FindFirstChild("Moisture")
            local needsWater = obj:FindFirstChild("NeedsWater") or obj:FindFirstChild("Thirsty")

            if needsWater or (waterLevel and waterLevel.Value < 50) then
                local primary = obj:FindFirstChild("PrimaryPart") or obj:FindFirstChildOfClass("Part") or obj:FindFirstChildOfClass("MeshPart")
                if primary then
                    local dist = (position - primary.Position).Magnitude
                    if dist <= CONFIG.HarvestRadius then
                        -- Move nearby and water
                        LocalPlayer.Character.HumanoidRootPart.CFrame = primary.CFrame * CFrame.new(0, 0, -1.5)
                        task.wait(0.15)
                        Utilities.FireRemote("Water", obj)
                        Utilities.FireRemote("WaterPlant", obj)
                        Utilities.FireRemote("Hydrate", obj)
                        watered = watered + 1
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end

function FarmEngine:SellHarvest()
    -- Find sell-related remotes
    local sellRemotes = {"Sell", "SellAll", "SellHarvest", "SellCrops", "SellItems"}
    for _, remoteName in ipairs(sellRemotes) do
        local remote = Utilities.FindRemote(remoteName)
        if remote then
            local success = Utilities.FireRemote(remoteName, "All")
            if success then
                Log:Debug("💰 Sold harvest")
                return
            end
        end
    end

    -- Fallback: find sell button in UI
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if playerGui then
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("ImageButton") or gui:IsA("TextButton") then
                local text = gui.Text or gui.Name
                if text:lower():find("sell") then
                    local absPos = gui.AbsolutePosition
                    VirtualInputManager:SendMouseButtonEvent(absPos.X + 5, absPos.Y + 5, 0, true, game, 1)
                    task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(absPos.X + 5, absPos.Y + 5, 0, false, game, 1)
                    Log:Debug("💰 Sell button pressed")
                    return
                end
            end
        end
    end
end

-- ============================================================
-- SECTION 6: ANTI-AFK ENGINE
-- ============================================================
local AntiAFK = {
    Running = false,
    Connection = nil,
}

function AntiAFK:Start()
    if self.Running then return end
    self.Running = true
    self.Connection = RunService.Heartbeat:Connect(function()
        if not self.Running then return end
        if not CONFIG.AntiAFK then return end

        -- Move slightly to prevent timeout
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = char.HumanoidRootPart.Position
            char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(
                math.random(-50, 50) / 100,
                0,
                math.random(-50, 50) / 100
            ))
            task.wait(30)  -- Every 30 seconds
        end
    end)
end

function AntiAFK:Stop()
    self.Running = false
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

-- ============================================================
-- SECTION 7: LOG UI UPDATE (now that UI is available)
-- ============================================================
-- Override Log:Add to include UI update
local _origLogAdd = Log.Add
function Log:Add(level, message, color)
    _origLogAdd(self, level, message, color)
    -- Update UI log list if available
    if UI and UI.Elements and UI.Elements.LogList then
        pcall(function() UI:UpdateLogList() end)
    end
end

-- ============================================================
-- SECTION 8: PREMIUM PROFESSIONAL UI
-- ============================================================

function UI:Initialize()
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HarvestEliteGUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    -- Add to CoreGui or PlayerGui (Executor Safe)
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if gethui then
        screenGui.Parent = gethui()
    elseif success and coreGui then
        screenGui.Parent = coreGui
    else
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then
            playerGui = Instance.new("PlayerGui")
            playerGui.Parent = LocalPlayer
        end
        screenGui.Parent = playerGui
    end

    self.ScreenGui = screenGui
    self.Instance = screenGui
    self:CreateMainFrame()
    self:CreateTitleBar()
    self:CreateTabBar()
    self:CreateContentArea()

    -- Make draggable
    self:MakeDraggable()

    -- Animate entrance
    self:AnimateEntrance()

    Log:Success("UI Initialized successfully")
end

function UI:CreateMainFrame()
    local theme = CONFIG.Theme

    -- Main frame
    local main = Instance.new("Frame")
    main.Name = "MainFrame"
    main.Size = UDim2.new(0, 420, 0, 540)
    main.Position = UDim2.new(0.5, -210, 0.5, -270)
    main.BackgroundColor3 = theme.Background
    main.BackgroundTransparency = 1 - CONFIG.Opacity
    main.BorderSizePixel = 0
    main.ClipsDescendants = false
    main.Parent = self.Instance

    -- Add shadow/glow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014262763"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(20, 20, 20, 20)
    shadow.Parent = main

    -- Border accent
    local border = Instance.new("Frame")
    border.Name = "Border"
    border.Size = UDim2.new(1, 0, 1, 0)
    border.BackgroundColor3 = theme.Secondary
    border.BackgroundTransparency = 0.5
    border.BorderSizePixel = 0
    border.Parent = main

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.Secondary),
        ColorSequenceKeypoint.new(0.5, theme.Primary),
        ColorSequenceKeypoint.new(1, theme.Secondary),
    })
    gradient.Rotation = 90
    gradient.Parent = border

    self.Elements.MainFrame = main
    self.Instance = main  -- Switch context to MainFrame for child UI elements
end

function UI:CreateTitleBar()
    local theme = CONFIG.Theme

    -- Title bar background
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 42)
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.BackgroundColor3 = theme.Surface
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.Instance

    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 30, 20)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 45, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 30, 20)),
    })
    titleGradient.Parent = titleBar

    -- Bottom border line
    local titleBorder = Instance.new("Frame")
    titleBorder.Name = "BorderLine"
    titleBorder.Size = UDim2.new(1, 0, 0, 2)
    titleBorder.Position = UDim2.new(0, 0, 1, 0)
    titleBorder.BackgroundColor3 = theme.Primary
    titleBorder.BorderSizePixel = 0
    titleBorder.Parent = titleBar

    -- Title text
    local titleText = Instance.new("TextLabel")
    titleText.Name = "Title"
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = CONFIG.Title
    titleText.Font = CONFIG.Font
    titleText.TextSize = 16
    titleText.TextColor3 = theme.Text
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    -- Version badge
    local badge = Instance.new("Frame")
    badge.Name = "VersionBadge"
    badge.Size = UDim2.new(0, 50, 0, 18)
    badge.Position = UDim2.new(0, 12, 0, 24)
    badge.BackgroundColor3 = theme.Primary
    badge.BackgroundTransparency = 0.3
    badge.BorderSizePixel = 0
    badge.Parent = titleBar

    local badgeText = Instance.new("TextLabel")
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.BackgroundTransparency = 1
    badgeText.Text = "ACTIVE"
    badgeText.Font = Enum.Font.Gotham
    badgeText.TextSize = 10
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.Parent = badge

    -- Minimize button
    local minBtn = Instance.new("ImageButton")
    minBtn.Name = "MinimizeBtn"
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -68, 0, 7)
    minBtn.BackgroundTransparency = 1
    minBtn.Image = "rbxassetid://6031094662"
    minBtn.ImageColor3 = Color3.fromRGB(180, 180, 180)
    minBtn.Parent = titleBar

    minBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end)

    -- Close button
    local closeBtn = Instance.new("ImageButton")
    closeBtn.Name = "CloseBtn"
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 7)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Image = "rbxassetid://6031094677"
    closeBtn.ImageColor3 = Color3.fromRGB(220, 80, 80)
    closeBtn.Parent = titleBar

    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    self.Elements.TitleBar = titleBar
    self.Elements.MinimizeBtn = minBtn
    self.Elements.CloseBtn = closeBtn
end

function UI:CreateTabBar()
    local theme = CONFIG.Theme

    local tabBar = Instance.new("Frame")
    tabBar.Name = "TabBar"
    tabBar.Size = UDim2.new(1, 0, 0, 34)
    tabBar.Position = UDim2.new(0, 0, 0, 42)
    tabBar.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
    tabBar.BorderSizePixel = 0
    tabBar.Parent = self.Instance

    -- Tab buttons
    local tabs = {
        {Name = "Main", Icon = "🏠"},
        {Name = "Events", Icon = "🎯"},
        {Name = "Farm", Icon = "🌱"},
        {Name = "Inventory", Icon = "📦"},
        {Name = "Logs", Icon = "📋"},
    }

    local tabWidth = 420 / #tabs
    for i, tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name .. "Tab"
        btn.Size = UDim2.new(0, tabWidth, 0.8, 0)
        btn.Position = UDim2.new(0, (i-1) * tabWidth, 0.1, 0)
        btn.BackgroundColor3 = theme.Surface
        btn.BackgroundTransparency = 0.5
        btn.BorderSizePixel = 0
        btn.Text = tab.Icon .. " " .. tab.Name
        btn.Font = CONFIG.Font
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(160, 160, 170)
        btn.Parent = tabBar

        -- Active indicator
        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.Size = UDim2.new(0.8, 0, 0, 3)
        indicator.Position = UDim2.new(0.1, 0, 1, -3)
        indicator.BackgroundColor3 = theme.Primary
        indicator.BorderSizePixel = 0
        indicator.BackgroundTransparency = (tab.Name ~= "Main") and 1 or 0.2
        indicator.Parent = btn

        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
            -- Update indicators
            for _, child in ipairs(tabBar:GetChildren()) do
                if child:IsA("TextButton") and child:FindFirstChild("Indicator") then
                    child:FindFirstChild("Indicator").BackgroundTransparency = 1
                    child.TextColor3 = Color3.fromRGB(160, 160, 170)
                end
            end
            btn.TextColor3 = theme.Text
            indicator.BackgroundTransparency = 0.2
        end)

        btn.MouseEnter:Connect(function()
            if self.ActiveTab ~= tab.Name then
                btn.TextColor3 = Color3.fromRGB(200, 200, 210)
            end
        end)
        btn.MouseLeave:Connect(function()
            if self.ActiveTab ~= tab.Name then
                btn.TextColor3 = Color3.fromRGB(160, 160, 170)
            end
        end)

        self.Tabs[tab.Name] = {Button = btn, Indicator = indicator}
    end

    self.Elements.TabBar = tabBar
end

function UI:CreateContentArea()
    local theme = CONFIG.Theme

    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Size = UDim2.new(1, -20, 1, -116)
    content.Position = UDim2.new(0, 10, 0, 80)
    content.BackgroundColor3 = theme.Surface
    content.BackgroundTransparency = 0.3
    content.BorderSizePixel = 0
    content.Parent = self.Instance

    -- Corner rounding
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = content

    self.Elements.Content = content
    self.Elements.ContentPages = {}

    -- Create each tab page
    self:CreateMainPage()
    self:CreateEventPage()
    self:CreateFarmPage()
    self:CreateInventoryPage()
    self:CreateLogPage()

    -- Show main by default
    self:SwitchTab("Main")
end

function UI:CreateMainPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("ScrollingFrame")
    page.Name = "MainPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.Primary
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content

    local yOffset = 10

    -- Status Section
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, -20, 0, 20)
    statusLabel.Position = UDim2.new(0, 10, 0, yOffset)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "📊 SYSTEM STATUS"
    statusLabel.Font = CONFIG.Font
    statusLabel.TextSize = 13
    statusLabel.TextColor3 = theme.Accent
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.Parent = page
    yOffset = yOffset + 25

    -- Status cards (2 columns)
    local statusItems = {
        {Label = "⚡ Script Status", Value = "Running", Color = Color3.fromRGB(50, 255, 100)},
        {Label = "💰 Balance", Value = "₿" .. self:FormatNumber(Utilities.GetPlayerBalance()), Color = theme.Accent},
        {Label = "🌱 Plants Active", Value = "0", Color = theme.Primary},
        {Label = "📦 Seeds Owned", Value = tostring(#Utilities.GetSeedInventory()), Color = Color3.fromRGB(100, 200, 255)},
    }

    for i, item in ipairs(statusItems) do
        local col = (i-1) % 2
        local row = math.floor((i-1) / 2)
        local card = self:CreateCard(page, UDim2.new(0, 185, 0, 52),
            UDim2.new(0, 10 + (col * 195), 0, yOffset + (row * 58)))
        card.Parent = page

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 18)
        label.Position = UDim2.new(0, 8, 0, 6)
        label.BackgroundTransparency = 1
        label.Text = item.Label
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextColor3 = Color3.fromRGB(160, 160, 170)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Size = UDim2.new(1, -10, 0, 22)
        value.Position = UDim2.new(0, 8, 0, 26)
        value.BackgroundTransparency = 1
        value.Text = item.Value
        value.Font = CONFIG.Font
        value.TextSize = 14
        value.TextColor3 = item.Color
        value.TextXAlignment = Enum.TextXAlignment.Left
        value.Parent = card
    end
    yOffset = yOffset + 120

    -- Quick Actions Section
    local actionsLabel = Instance.new("TextLabel")
    actionsLabel.Size = UDim2.new(1, -20, 0, 20)
    actionsLabel.Position = UDim2.new(0, 10, 0, yOffset)
    actionsLabel.BackgroundTransparency = 1
    actionsLabel.Text = "⚡ QUICK ACTIONS"
    actionsLabel.Font = CONFIG.Font
    actionsLabel.TextSize = 13
    actionsLabel.TextColor3 = theme.Accent
    actionsLabel.TextXAlignment = Enum.TextXAlignment.Left
    actionsLabel.Parent = page
    yOffset = yOffset + 25

    local actions = {
        {Name = "▶ Start All", Color = theme.Primary, Action = function() ToggleAll(true) end},
        {Name = "⏹ Stop All", Color = theme.Danger, Action = function() ToggleAll(false) end},
        {Name = "🔄 Refresh", Color = theme.Warning, Action = function()
            Log:Info("🔄 Refreshing...")
        end},
    }

    for i, action in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, (380 / #actions) - 6, 0, 34)
        btn.Position = UDim2.new(0, 10 + ((i-1) * ((380 / #actions) + 3)), 0, yOffset)
        btn.BackgroundColor3 = action.Color
        btn.BackgroundTransparency = 0.7
        btn.BorderSizePixel = 0
        btn.Text = action.Name
        btn.Font = CONFIG.Font
        btn.TextSize = 12
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = page

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            action.Action()
        end)

        btn.MouseEnter:Connect(function()
            btn.BackgroundTransparency = 0.4
        end)
        btn.MouseLeave:Connect(function()
            btn.BackgroundTransparency = 0.7
        end)
    end
    yOffset = yOffset + 45

    -- Session Stats
    local statsLabel = Instance.new("TextLabel")
    statsLabel.Size = UDim2.new(1, -20, 0, 20)
    statsLabel.Position = UDim2.new(0, 10, 0, yOffset)
    statsLabel.BackgroundTransparency = 1
    statsLabel.Text = "📈 SESSION STATISTICS"
    statsLabel.Font = CONFIG.Font
    statsLabel.TextSize = 13
    statsLabel.TextColor3 = theme.Accent
    statsLabel.TextXAlignment = Enum.TextXAlignment.Left
    statsLabel.Parent = page
    yOffset = yOffset + 25

    local statsData = {
        {Label = "Farm Cycles", Value = "0", Color = theme.Primary},
        {Label = "Event Seeds Collected", Value = "0", Color = Color3.fromRGB(255, 150, 50)},
        {Label = "Total Earned", Value = "₿0", Color = theme.Accent},
        {Label = "Uptime", Value = "0m", Color = Color3.fromRGB(100, 200, 255)},
    }

    for i, stat in ipairs(statsData) do
        local col = (i-1) % 2
        local row = math.floor((i-1) / 2)
        local card = self:CreateCard(page, UDim2.new(0, 185, 0, 48),
            UDim2.new(0, 10 + (col * 195), 0, yOffset + (row * 52)))
        card.Parent = page

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -10, 0, 16)
        label.Position = UDim2.new(0, 8, 0, 4)
        label.BackgroundTransparency = 1
        label.Text = stat.Label
        label.Font = Enum.Font.Gotham
        label.TextSize = 10
        label.TextColor3 = Color3.fromRGB(160, 160, 170)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local value = Instance.new("TextLabel")
        value.Name = "Value"
        value.Size = UDim2.new(1, -10, 0, 22)
        value.Position = UDim2.new(0, 8, 0, 22)
        value.BackgroundTransparency = 1
        value.Text = stat.Value
        value.Font = CONFIG.Font
        value.TextSize = 14
        value.TextColor3 = stat.Color
        value.TextXAlignment = Enum.TextXAlignment.Left
        value.Parent = card
    end
    yOffset = yOffset + 110

    page.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    self.Elements.ContentPages["Main"] = page
end

function UI:CreateEventPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("ScrollingFrame")
    page.Name = "EventPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.Primary
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content

    local yOffset = 10

    -- Event Collector Header
    local header = self:CreateCard(page, UDim2.new(0, 380, 0, 70), UDim2.new(0, 10, 0, yOffset))
    header.Parent = page
    yOffset = yOffset + 78

    local collectorTitle = Instance.new("TextLabel")
    collectorTitle.Size = UDim2.new(1, -10, 0, 20)
    collectorTitle.Position = UDim2.new(0, 8, 0, 6)
    collectorTitle.BackgroundTransparency = 1
    collectorTitle.Text = "🎯 Event Seed Collector"
    collectorTitle.Font = CONFIG.Font
    collectorTitle.TextSize = 14
    collectorTitle.TextColor3 = theme.Text
    collectorTitle.TextXAlignment = Enum.TextXAlignment.Left
    collectorTitle.Parent = header

    local collectorDesc = Instance.new("TextLabel")
    collectorDesc.Size = UDim2.new(1, -10, 0, 16)
    collectorDesc.Position = UDim2.new(0, 8, 0, 28)
    collectorDesc.BackgroundTransparency = 1
    collectorDesc.Text = "Auto-collects event seeds from Tom's Shop & Summer Merchant"
    collectorDesc.Font = Enum.Font.Gotham
    collectorDesc.TextSize = 10
    collectorDesc.TextColor3 = Color3.fromRGB(140, 140, 150)
    collectorDesc.TextXAlignment = Enum.TextXAlignment.Left
    collectorDesc.Parent = header

    -- Toggle buttons
    local collectToggle = self:CreateToggle(header, "Auto-Collect Event Seeds",
        CONFIG.AutoCollectEventSeeds, UDim2.new(0, 8, 0, 44), function(val)
            CONFIG.AutoCollectEventSeeds = val
            if val then EventSeedCollector:Start() else EventSeedCollector:Stop() end
            Log:Info(string.format("🎯 Auto-Collect Event Seeds: %s", val and "ON" or "OFF"))
        end)
    collectToggle.Parent = header

    -- Event Seeds List
    local seedsLabel = Instance.new("TextLabel")
    seedsLabel.Size = UDim2.new(1, -20, 0, 20)
    seedsLabel.Position = UDim2.new(0, 10, 0, yOffset)
    seedsLabel.BackgroundTransparency = 1
    seedsLabel.Text = "🌱 EVENT SEEDS"
    seedsLabel.Font = CONFIG.Font
    seedsLabel.TextSize = 13
    seedsLabel.TextColor3 = theme.Accent
    seedsLabel.TextXAlignment = Enum.TextXAlignment.Left
    seedsLabel.Parent = page
    yOffset = yOffset + 25

    for seedName, seedConfig in pairs(CONFIG.EventSeeds) do
        local card = self:CreateCard(page, UDim2.new(0, 380, 0, 40), UDim2.new(0, 10, 0, yOffset))
        card.Parent = page
        yOffset = yOffset + 44

        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(0, 160, 1, 0)
        nameLabel.Position = UDim2.new(0, 8, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = seedName
        nameLabel.Font = CONFIG.Font
        nameLabel.TextSize = 12
        nameLabel.TextColor3 = theme.Text
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = card

        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(0, 80, 1, 0)
        priceLabel.Position = UDim2.new(0, 170, 0, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = "≤ ₿" .. self:FormatNumber(seedConfig.MaxPrice)
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.TextSize = 10
        priceLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
        priceLabel.TextXAlignment = Enum.TextXAlignment.Left
        priceLabel.Parent = card

        local toggle = self:CreateToggle(card, "", seedConfig.AutoBuy,
            UDim2.new(1, -50, 0, 8), function(val)
                CONFIG.EventSeeds[seedName].AutoBuy = val
            end)
        toggle.Parent = card
    end

    page.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    self.Elements.ContentPages["Events"] = page
end

function UI:CreateFarmPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("ScrollingFrame")
    page.Name = "FarmPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.Primary
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content

    local yOffset = 10

    -- Farm Controls Header
    local header = self:CreateCard(page, UDim2.new(0, 380, 0, 40), UDim2.new(0, 10, 0, yOffset))
    header.Parent = page
    yOffset = yOffset + 48

    local farmTitle = Instance.new("TextLabel")
    farmTitle.Size = UDim2.new(1, -10, 0, 20)
    farmTitle.Position = UDim2.new(0, 8, 0, 6)
    farmTitle.BackgroundTransparency = 1
    farmTitle.Text = "🌱 Farm Engine Controls"
    farmTitle.Font = CONFIG.Font
    farmTitle.TextSize = 14
    farmTitle.TextColor3 = theme.Text
    farmTitle.TextXAlignment = Enum.TextXAlignment.Left
    farmTitle.Parent = header

    -- Toggles
    local farmToggles = {
        {Label = "Auto Farm (Full Cycle)", Key = "AutoFarm", Default = CONFIG.AutoFarm},
        {Label = "Auto Plant", Key = "AutoPlant", Default = CONFIG.AutoPlant},
        {Label = "Auto Harvest", Key = "AutoHarvest", Default = CONFIG.AutoHarvest},
        {Label = "Auto Sell", Key = "AutoSell", Default = CONFIG.AutoSell},
        {Label = "Auto Water", Key = "AutoWater", Default = CONFIG.AutoWater},
        {Label = "Anti-AFK", Key = "AntiAFK", Default = CONFIG.AntiAFK},
        {Label = "Auto Steal", Key = "AutoSteal", Default = CONFIG.AutoSteal},
    }

    for _, toggleData in ipairs(farmToggles) do
        local card = self:CreateCard(page, UDim2.new(0, 380, 0, 36), UDim2.new(0, 10, 0, yOffset))
        card.Parent = page
        yOffset = yOffset + 40

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 250, 1, 0)
        label.Position = UDim2.new(0, 8, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = toggleData.Label
        label.Font = CONFIG.Font
        label.TextSize = 12
        label.TextColor3 = theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local toggle = self:CreateToggle(card, "", toggleData.Default,
            UDim2.new(1, -50, 0, 6), function(val)
                CONFIG[toggleData.Key] = val
                if toggleData.Key == "AutoFarm" then
                    if val then FarmEngine:Start() else FarmEngine:Stop() end
                elseif toggleData.Key == "AntiAFK" then
                    if val then AntiAFK:Start() else AntiAFK:Stop() end
                end
                Log:Info(string.format("🔧 %s: %s", toggleData.Label, val and "ON" or "OFF"))
            end)
        toggle.Parent = card
    end

    -- Settings Section
    yOffset = yOffset + 10
    local settingsLabel = Instance.new("TextLabel")
    settingsLabel.Size = UDim2.new(1, -20, 0, 20)
    settingsLabel.Position = UDim2.new(0, 10, 0, yOffset)
    settingsLabel.BackgroundTransparency = 1
    settingsLabel.Text = "⚙️ FARM SETTINGS"
    settingsLabel.Font = CONFIG.Font
    settingsLabel.TextSize = 13
    settingsLabel.TextColor3 = theme.Accent
    settingsLabel.TextXAlignment = Enum.TextXAlignment.Left
    settingsLabel.Parent = page
    yOffset = yOffset + 25

    local settings = {
        {Label = "Harvest Radius", Value = tostring(CONFIG.HarvestRadius), Min = 10, Max = 200, Key = "HarvestRadius"},
        {Label = "Max Plants", Value = tostring(CONFIG.MaxPlants), Min = 10, Max = 500, Key = "MaxPlants"},
        {Label = "Min Sheckles", Value = tostring(CONFIG.MinShecklesToKeep), Min = 100, Max = 100000, Key = "MinShecklesToKeep"},
    }

    for _, setting in ipairs(settings) do
        local card = self:CreateCard(page, UDim2.new(0, 380, 0, 44), UDim2.new(0, 10, 0, yOffset))
        card.Parent = page
        yOffset = yOffset + 48

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 180, 0, 20)
        label.Position = UDim2.new(0, 8, 0, 6)
        label.BackgroundTransparency = 1
        label.Text = setting.Label
        label.Font = Enum.Font.Gotham
        label.TextSize = 11
        label.TextColor3 = theme.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = card

        local valueBox = Instance.new("TextBox")
        valueBox.Size = UDim2.new(0, 80, 0, 26)
        valueBox.Position = UDim2.new(0, 190, 0, 8)
        valueBox.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        valueBox.BorderSizePixel = 0
        valueBox.Text = setting.Value
        valueBox.Font = CONFIG.Font
        valueBox.TextSize = 12
        valueBox.TextColor3 = theme.Text
        valueBox.PlaceholderText = "Value"
        valueBox.ClearTextOnFocus = false
        valueBox.Parent = card

        local boxCorner = Instance.new("UICorner")
        boxCorner.CornerRadius = UDim.new(0, 4)
        boxCorner.Parent = valueBox

        valueBox.FocusLost:Connect(function(enter)
            if enter then
                local val = tonumber(valueBox.Text)
                if val then
                    CONFIG[setting.Key] = math.clamp(val, setting.Min, setting.Max)
                    valueBox.Text = tostring(CONFIG[setting.Key])
                    Log:Info(string.format("⚙️ %s set to %d", setting.Label, CONFIG[setting.Key]))
                else
                    valueBox.Text = tostring(CONFIG[setting.Key])
                end
            end
        end)
    end

    page.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    self.Elements.ContentPages["Farm"] = page
end

function UI:CreateInventoryPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("ScrollingFrame")
    page.Name = "InventoryPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = theme.Primary
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = content

    local yOffset = 10

    local header = self:CreateCard(page, UDim2.new(0, 380, 0, 40), UDim2.new(0, 10, 0, yOffset))
    header.Parent = page
    yOffset = yOffset + 48

    local invTitle = Instance.new("TextLabel")
    invTitle.Size = UDim2.new(1, -10, 0, 20)
    invTitle.Position = UDim2.new(0, 8, 0, 6)
    invTitle.BackgroundTransparency = 1
    invTitle.Text = "📦 Seed Inventory"
    invTitle.Font = CONFIG.Font
    invTitle.TextSize = 14
    invTitle.TextColor3 = theme.Text
    invTitle.TextXAlignment = Enum.TextXAlignment.Left
    invTitle.Parent = header

    -- Refresh button
    local refreshBtn = Instance.new("TextButton")
    refreshBtn.Size = UDim2.new(0, 80, 0, 24)
    refreshBtn.Position = UDim2.new(1, -90, 0, 8)
    refreshBtn.BackgroundColor3 = theme.Primary
    refreshBtn.BackgroundTransparency = 0.5
    refreshBtn.BorderSizePixel = 0
    refreshBtn.Text = "🔄 Scan"
    refreshBtn.Font = CONFIG.Font
    refreshBtn.TextSize = 10
    refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    refreshBtn.Parent = header

    local refreshCorner = Instance.new("UICorner")
    refreshCorner.CornerRadius = UDim.new(0, 4)
    refreshCorner.Parent = refreshBtn

    -- Seed list container
    local seedListContainer = Instance.new("Frame")
    seedListContainer.Name = "SeedList"
    seedListContainer.Size = UDim2.new(1, -20, 0, 260)
    seedListContainer.Position = UDim2.new(0, 10, 0, yOffset)
    seedListContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    seedListContainer.BackgroundTransparency = 0.3
    seedListContainer.BorderSizePixel = 0
    seedListContainer.Parent = page

    local listCorner = Instance.new("UICorner")
    listCorner.CornerRadius = UDim.new(0, 4)
    listCorner.Parent = seedListContainer

    local seedList = Instance.new("UIListLayout")
    seedList.Padding = UDim.new(0, 2)
    seedList.Parent = seedListContainer

    yOffset = yOffset + 270

    -- Populate seeds
    local function RefreshSeedList()
        for _, child in ipairs(seedListContainer:GetChildren()) do
            if child:IsA("Frame") and child ~= seedList then
                child:Destroy()
            end
        end
        local seeds = Utilities.GetSeedInventory()
        if #seeds == 0 then
            local emptyLabel = Instance.new("TextLabel")
            emptyLabel.Size = UDim2.new(1, -10, 0, 40)
            emptyLabel.Position = UDim2.new(0, 5, 0, 5)
            emptyLabel.BackgroundTransparency = 1
            emptyLabel.Text = "No seeds in inventory. Start farming!"
            emptyLabel.Font = Enum.Font.Gotham
            emptyLabel.TextSize = 12
            emptyLabel.TextColor3 = Color3.fromRGB(140, 140, 150)
            emptyLabel.Parent = seedListContainer
        else
            for i, seedName in ipairs(seeds) do
                if i > 30 then break end
                local item = Instance.new("Frame")
                item.Size = UDim2.new(1, -10, 0, 28)
                item.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
                item.BackgroundTransparency = 0.3
                item.BorderSizePixel = 0
                item.Parent = seedListContainer

                local itemCorner = Instance.new("UICorner")
                itemCorner.CornerRadius = UDim.new(0, 4)
                itemCorner.Parent = item

                local nameLabel = Instance.new("TextLabel")
                nameLabel.Size = UDim2.new(1, -10, 1, 0)
                nameLabel.Position = UDim2.new(0, 8, 0, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = string.format("%d. %s", i, seedName)
                nameLabel.Font = Enum.Font.Gotham
                nameLabel.TextSize = 11
                nameLabel.TextColor3 = theme.Text
                nameLabel.TextXAlignment = Enum.TextXAlignment.Left
                nameLabel.Parent = item
            end
        end
    end

    refreshBtn.MouseButton1Click:Connect(RefreshSeedList)

    task.spawn(RefreshSeedList)

    page.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
    self.Elements.ContentPages["Inventory"] = page
end

function UI:CreateLogPage()
    local theme = CONFIG.Theme
    local content = self.Elements.Content
    if not content then return end

    local page = Instance.new("Frame")
    page.Name = "LogPage"
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = content

    local logList = Instance.new("ScrollingFrame")
    logList.Name = "LogList"
    logList.Size = UDim2.new(1, -20, 1, -60)
    logList.Position = UDim2.new(0, 10, 0, 10)
    logList.BackgroundColor3 = Color3.fromRGB(15, 15, 28)
    logList.BackgroundTransparency = 0.2
    logList.BorderSizePixel = 0
    logList.ScrollBarThickness = 4
    logList.ScrollBarImageColor3 = theme.Primary
    logList.CanvasSize = UDim2.new(0, 0, 0, 0)
    logList.Parent = page

    local logListLayout = Instance.new("UIListLayout")
    logListLayout.Padding = UDim.new(0, 1)
    logListLayout.Parent = logList

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 100, 0, 28)
    clearBtn.Position = UDim2.new(1, -110, 1, -35)
    clearBtn.BackgroundColor3 = theme.Danger
    clearBtn.BackgroundTransparency = 0.5
    clearBtn.BorderSizePixel = 0
    clearBtn.Text = "🗑 Clear Logs"
    clearBtn.Font = CONFIG.Font
    clearBtn.TextSize = 10
    clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    clearBtn.Parent = page

    local clearCorner = Instance.new("UICorner")
    clearCorner.CornerRadius = UDim.new(0, 4)
    clearCorner.Parent = clearBtn

    clearBtn.MouseButton1Click:Connect(function()
        Log.Messages = {}
        for _, child in ipairs(logList:GetChildren()) do
            if child:IsA("Frame") and child ~= logListLayout then
                child:Destroy()
            end
        end
        logList.CanvasSize = UDim2.new(0, 0, 0, 0)
    end)

    self.Elements.LogList = logList
    self.Elements.ContentPages["Logs"] = page
end

function UI:UpdateLogList()
    local logList = self.Elements.LogList
    if not logList then return end

    -- Clear existing entries
    for _, child in ipairs(logList:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    -- Show last 50 messages
    local startIdx = math.max(1, #Log.Messages - 49)
    for i = startIdx, #Log.Messages do
        local entry = Log.Messages[i]
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1, -10, 0, 20)
        item.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
        item.BackgroundTransparency = 0.5
        item.BorderSizePixel = 0
        item.Parent = logList

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -6, 1, 0)
        label.Position = UDim2.new(0, 4, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = string.format("[%s] %s", entry.Timestamp, entry.Message)
        label.Font = Enum.Font.Code
        label.TextSize = 9
        label.TextColor3 = entry.Color
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTruncate = Enum.TextTruncate.None
        label.Parent = item
    end

    logList.CanvasSize = UDim2.new(0, 0, 0, #Log.Messages * 21)
    logList.CanvasPosition = Vector2.new(0, math.huge)
end

-- ============================================================
-- SECTION 9: UI HELPERS
-- ============================================================

function UI:CreateCard(parent, size, position)
    local card = Instance.new("Frame")
    card.Size = size
    card.Position = position
    card.BackgroundColor3 = CONFIG.Theme.Surface
    card.BackgroundTransparency = 0.4
    card.BorderSizePixel = 0
    card.Parent = parent

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 6)
    cardCorner.Parent = card

    return card
end

function UI:CreateToggle(parent, label, defaultValue, position, callback)
    local theme = CONFIG.Theme
    local toggled = defaultValue

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 320, 0, 24)
    container.Position = position
    container.BackgroundTransparency = 1
    container.Parent = parent

    local labelWidget = Instance.new("TextLabel")
    labelWidget.Size = UDim2.new(1, -50, 1, 0)
    labelWidget.BackgroundTransparency = 1
    labelWidget.Text = label
    labelWidget.Font = Enum.Font.Gotham
    labelWidget.TextSize = 11
    labelWidget.TextColor3 = theme.Text
    labelWidget.TextXAlignment = Enum.TextXAlignment.Left
    labelWidget.Parent = container

    local toggleBg = Instance.new("Frame")
    toggleBg.Name = "ToggleBg"
    toggleBg.Size = UDim2.new(0, 40, 0, 22)
    toggleBg.Position = UDim2.new(0, label:len() > 0 and 0 else 0, 0, 1)
    toggleBg.BackgroundColor3 = toggled and theme.Primary or Color3.fromRGB(50, 50, 60)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = container

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 11)
    toggleCorner.Parent = toggleBg

    local toggleCircle = Instance.new("Frame")
    toggleCircle.Name = "Circle"
    toggleCircle.Size = UDim2.new(0, 18, 0, 18)
    toggleCircle.Position = UDim2.new(0, toggled and 20 or 2, 0, 2)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    toggleCircle.BorderSizePixel = 0
    toggleCircle.Parent = toggleBg

    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(0, 9)
    circleCorner.Parent = toggleCircle

    local function UpdateToggle(val)
        toggled = val
        toggleBg.BackgroundColor3 = toggled and theme.Primary or Color3.fromRGB(50, 50, 60)
        toggleCircle:TweenPosition(UDim2.new(0, toggled and 20 or 2, 0, 2), "Out", "Quad", 0.15, true)
        if callback then callback(toggled) end
    end

    toggleBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            UpdateToggle(not toggled)
        end
    end)

    return container
end

function UI:FormatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

function UI:MakeDraggable()
    local titleBar = self.Elements.TitleBar
    if not titleBar then return end

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self.DragOffset = Vector2.new(
                input.Position.X - self.Instance.AbsolutePosition.X,
                input.Position.Y - self.Instance.AbsolutePosition.Y
            )
            input:GetPropertyChangedSignal("Position"):Connect(function()
                if self.Dragging then
                    local pos = self.Instance.AbsolutePosition
                    self.Instance.Position = UDim2.new(
                        0, input.Position.X - self.DragOffset.X,
                        0, input.Position.Y - self.DragOffset.Y
                    )
                end
            end)
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = false
        end
    end)
end

function UI:SwitchTab(tabName)
    self.ActiveTab = tabName
    for name, page in pairs(self.Elements.ContentPages) do
        if page then
            page.Visible = (name == tabName)
        end
    end
end

function UI:ToggleMinimize()
    self.Minimized = not self.Minimized
    self.Instance.Size = self.Minimized and UDim2.new(0, 420, 0, 42) or UDim2.new(0, 420, 0, 540)
    for _, child in ipairs(self.Instance:GetChildren()) do
        if child ~= self.Elements.TitleBar then
            child.Visible = not self.Minimized
        end
    end
end

function UI:AnimateEntrance()
    self.Instance.Position = UDim2.new(0.5, -210, 0.3, 0)
    self.Instance.BackgroundTransparency = 0.8
    TweenService:Create(self.Instance, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1 - CONFIG.Opacity,
        Position = UDim2.new(0.5, -210, 0.5, -270)
    }):Play()
end

function UI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
    self.ScreenGui = nil
    self.Instance = nil
end

-- ============================================================
-- SECTION 10: INITIALIZATION & CONTROL FUNCTIONS
-- ============================================================

function ToggleAll(enabled)
    CONFIG.AutoFarm = enabled
    CONFIG.AutoCollectEventSeeds = enabled
    CONFIG.AutoBuyEventSeeds = enabled
    CONFIG.AutoPlant = enabled
    CONFIG.AutoHarvest = enabled
    CONFIG.AutoSell = enabled

    if enabled then
        FarmEngine:Start()
        EventSeedCollector:Start()
        AntiAFK:Start()
        Log:Success("▶ ALL SYSTEMS STARTED")
    else
        FarmEngine:Stop()
        EventSeedCollector:Stop()
        AntiAFK:Stop()
        Log:Warn("⏹ ALL SYSTEMS STOPPED")
    end
end

-- ============================================================
-- SECTION 11: MAIN EXECUTION
-- ============================================================

Log:Success("🌱 Harvest Elite v2.1.0 loading...")

-- Delay to let game load
task.wait(1)

-- Initialize UI
UI:Initialize()

-- Start core engines based on config
if CONFIG.AutoFarm then FarmEngine:Start() end
if CONFIG.AutoCollectEventSeeds or CONFIG.AutoBuyEventSeeds then EventSeedCollector:Start() end
if CONFIG.AntiAFK then AntiAFK:Start() end

Log:Success("✅ Harvest Elite v2.1.0 fully loaded and operational")
Log:Info("📌 Press [Right Ctrl] to toggle UI visibility")
Log:Info("📌 Report bugs: https://help.hackerai.co")

-- UI Toggle Hotkey
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
        if UI.ScreenGui then
            UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled
        end
    end
end)

-- Auto-save collected seeds count tracking
local startTime = os.time()
task.spawn(function()
    while task.wait(10) do
        if FarmEngine.Running then
            local balance = Utilities.GetPlayerBalance()
            local uptime = math.floor((os.time() - startTime) / 60)
            -- Update UI stats if page exists
            local mainPage = UI.Elements.ContentPages and UI.Elements.ContentPages["Main"]
            if mainPage then
                for _, child in ipairs(mainPage:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Name == "Value" then
                        -- Update dynamically (simplified)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- END OF SCRIPT
-- ============================================================