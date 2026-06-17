--[[
████████████████████████████████████████████████████████████████████████████
█                                                                          █
█   GROW A GARDEN 2 — Premium Auto Collect & Farm Script                  █
█   Version: 2.1.1 FULL FIXED                                              █
█   Fix: UI not showing — Instance override, LocalPlayer wait              █
█   ALL PAGES INTACT: Main, Events, Farm, Inventory, Logs                  █
█                                                                          █
████████████████████████████████████████████████████████████████████████████
--]]

-- ============================================================
-- GUARD: Wait for game to fully load
-- ============================================================
repeat task.wait() until game:GetService("Players").LocalPlayer
repeat task.wait() until game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") or game:GetService("CoreGui")

-- ============================================================
-- SECTION 1: CONFIGURATION
-- ============================================================
local CONFIG = {
    AutoCollectEventSeeds = true, AutoBuyEventSeeds = true,
    AutoFarm = true, AutoPlant = true, AutoHarvest = true,
    AutoSell = true, AutoWater = true, AntiAFK = true, AutoSteal = false,

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

    MinShecklesToKeep = 1000, HarvestRadius = 50, PlantRadius = 30,
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
-- SECTION 2: SERVICES (SAFE)
-- ============================================================
local function GS(name) local s,v = pcall(function() return game:GetService(name) end); return s and v or nil end
local Players = GS("Players")
local RunService = GS("RunService")
local TweenService = GS("TweenService")
local UserInputService = GS("UserInputService")
local VirtualInputManager = GS("VirtualInputManager")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================
-- SECTION 3: LOG SYSTEM
-- ============================================================
local Log = { Messages = {}, MaxMessages = 100, LogLevel = 3 }
function Log:Add(level, msg, color)
    local e = { Level = level, Message = msg, Color = color or Color3.fromRGB(200,200,200), Time = os.time(), Timestamp = os.date("%H:%M:%S") }
    table.insert(self.Messages, e)
    if #self.Messages > self.MaxMessages then table.remove(self.Messages, 1) end
    print(string.format("[%s] %s", e.Timestamp, msg))
end
Log.Error = function(_, m) Log:Add("ERROR", m, Color3.fromRGB(255,70,70)) end
Log.Warn = function(_, m) Log:Add("WARN", m, Color3.fromRGB(255,180,50)) end
Log.Info = function(_, m) Log:Add("INFO", m, Color3.fromRGB(100,200,255)) end
Log.Debug = function(_, m) if Log.LogLevel >= 4 then Log:Add("DEBUG", m, Color3.fromRGB(150,150,150)) end end
Log.Success = function(_, m) Log:Add("SUCCESS", m, Color3.fromRGB(50,255,100)) end

-- ============================================================
-- SECTION 4: UI TABLE
-- ============================================================
local UI = {
    ScreenGui = nil,
    MainFrame = nil,
    Elements = {},
    Dragging = false,
    DragOffset = Vector2.new(0,0),
    Minimized = false,
    Tabs = {},
    ActiveTab = "Main",
}

-- ============================================================
-- SECTION 5: UTILITIES
-- ============================================================
local Utilities = {}

function Utilities.FindRemote(name)
    local paths = { GS("ReplicatedStorage"), GS("ReplicatedFirst"), LocalPlayer.PlayerGui, LocalPlayer.Backpack, LocalPlayer.Character, workspace }
    for _,c in ipairs(paths) do
        if not c then continue end
        local f = c:FindFirstChild(name, true)
        if f and (f:IsA("RemoteEvent") or f:IsA("RemoteFunction")) then return f end
    end
    for _,c in ipairs(paths) do
        if not c then continue end
        for _,o in ipairs(c:GetDescendants()) do
            if o.Name == name and (o:IsA("RemoteEvent") or o:IsA("RemoteFunction")) then return o end
        end
    end
    return nil
end

function Utilities.FireRemote(name, ...)
    local r = Utilities.FindRemote(name)
    if r then
        local args = {...}
        local s,e = pcall(function()
            if r:IsA("RemoteEvent") then r:FireServer(unpack(args))
            elseif r:IsA("RemoteFunction") then r:InvokeServer(unpack(args)) end
        end)
        if not s then warn("[HARVEST] Remote:", e) end
        return s
    end
    return false
end

function Utilities.GetPlayerBalance()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local c = ls:FindFirstChild("Sheckles") or ls:FindFirstChild("Money") or ls:FindFirstChild("Balance") or ls:FindFirstChild("Points")
        if c then return c.Value end
    end
    for _,ch in ipairs(LocalPlayer:GetDescendants()) do
        if ch:IsA("NumberValue") and (ch.Name:lower():find("sheck") or ch.Name:lower():find("money") or ch.Name:lower():find("coin")) then
            return ch.Value
        end
    end
    return 0
end

function Utilities.GetSeedInventory()
    local seeds = {}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _,it in ipairs(bp:GetChildren()) do
            if it:IsA("Tool") or it:IsA("Part") then table.insert(seeds, it.Name) end
        end
    end
    local ch = LocalPlayer.Character
    if ch then
        for _,it in ipairs(ch:GetChildren()) do
            if it:IsA("Tool") then table.insert(seeds, it.Name) end
        end
    end
    return seeds
end

function Utilities.GetHarvestablePlants(radius)
    local h = {}
    local pos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or Vector3.new(0,0,0)
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("plant") or o.Name:lower():find("crop")) then
            local prim = o:FindFirstChild("PrimaryPart") or o:FindFirstChildOfClass("Part") or o:FindFirstChildOfClass("MeshPart")
            if prim and (pos - prim.Position).Magnitude <= radius then
                if o:FindFirstChildWhichIsA("ProximityPrompt") or o:FindFirstChildWhichIsA("ClickDetector") then table.insert(h, o) end
            end
        end
    end
    return h
end

-- ============================================================
-- SECTION 6: ENGINES
-- ============================================================
local EventSeedCollector = { Running = false, Connection = nil, CollectedSeeds = {}, CheckInterval = 3 }
function EventSeedCollector:Start()
    if self.Running then return end
    self.Running = true
    self.Connection = RunService.Stepped:Connect(function() if self.Running then self:CheckEventShop() end end)
    task.spawn(function() while self.Running do task.wait(self.CheckInterval) self:CheckEventShop() end end)
end
function EventSeedCollector:Stop() self.Running = false; if self.Connection then self.Connection:Disconnect() self.Connection = nil end end
function EventSeedCollector:CheckEventShop()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local shopFrame = nil
    for _,g in ipairs(pg:GetDescendants()) do
        if (g:IsA("Frame") or g:IsA("ScrollingFrame")) and (g.Name:lower():find("shop") or g.Name:lower():find("seed") or g.Name:lower():find("event") or g.Name:lower():find("summer") or g.Name:lower():find("tom")) then
            shopFrame = g; break end
    end
    if not shopFrame then self:OpenSeedShop(); return end
    self:ScanAndPurchase(shopFrame)
end
function EventSeedCollector:OpenSeedShop()
    for _,o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Model") and (o.Name:lower():find("tom") or o.Name:lower():find("sam") or o.Name:lower():find("npc") or o.Name:lower():find("shop")) then
            local prompt = o:FindFirstChildWhichIsA("ProximityPrompt")
            if prompt then
                local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local prim = o:FindFirstChild("PrimaryPart") or o:FindFirstChildOfClass("Part") or o:FindFirstChildOfClass("MeshPart")
                    if prim then
                        hrp.CFrame = prim.CFrame * CFrame.new(0,0,-3); task.wait(0.5)
                        fireproximityprompt(prompt); return
                    end
                end
            end
        end
    end
    Utilities.FireRemote("OpenShop", "SeedShop"); Utilities.FireRemote("ShopRequest", "Tom"); Utilities.FireRemote("RequestShop")
end
function EventSeedCollector:ScanAndPurchase(shopFrame)
    if not CONFIG.AutoBuyEventSeeds then return end
    local balance = Utilities.GetPlayerBalance()
    for _,item in ipairs(shopFrame:GetDescendants()) do
        if item:IsA("ImageButton") or item:IsA("TextButton") or item:IsA("Frame") then
            for seedName, seedConfig in pairs(CONFIG.EventSeeds) do
                if not seedConfig.AutoBuy then continue end
                if item.Name:lower():find(seedName:lower()) or (item:FindFirstChildOfClass("TextLabel") and item:FindFirstChildOfClass("TextLabel").Text:lower():find(seedName:lower())) then
                    local priceLabel = item:FindFirstChild("Price") or item:FindFirstChildOfClass("TextLabel")
                    local price = seedConfig.MaxPrice
                    if priceLabel then local pt = priceLabel.Text:match("%d+"); if pt then price = tonumber(pt) or price end end
                    local stockLabel = item:FindFirstChild("Stock") or item:FindFirstChild("Amount")
                    if stockLabel and (stockLabel.Text:lower():find("out") or (tonumber(stockLabel.Text) and tonumber(stockLabel.Text) <= 0)) then goto continue end
                    if balance - price >= CONFIG.MinShecklesToKeep then
                        local cd = item:FindFirstChildWhichIsA("ClickDetector")
                        if cd then
                            fireclickdetector(cd); table.insert(self.CollectedSeeds, seedName)
                            Log:Info(string.format("✅ Bought: %s (₿%d)", seedName, price)); task.wait(0.3)
                        else
                            local ap = item.AbsolutePosition
                            if VirtualInputManager then
                                VirtualInputManager:SendMouseButtonEvent(ap.X+5, ap.Y+5, 0, true, game, 1); task.wait(0.05)
                                VirtualInputManager:SendMouseButtonEvent(ap.X+5, ap.Y+5, 0, false, game, 1)
                                table.insert(self.CollectedSeeds, seedName); Log:Info(string.format("✅ Clicked: %s", seedName)); task.wait(0.3)
                            end
                        end
                    end
                end
                ::continue::
            end
        end
    end
end

local FarmEngine = { Running = false, Connection = nil, CycleCount = 0, TotalEarned = 0 }
function FarmEngine:Start()
    if self.Running then return end; self.Running = true
    self.Connection = RunService.Stepped:Connect(function() if self.Running then self:FarmCycle() end end)
    task.spawn(function() while self.Running do task.wait(2) self:FarmCycle() end end)
    Log:Success("🌱 Farm Engine started")
end
function FarmEngine:Stop() self.Running = false; if self.Connection then self.Connection:Disconnect() self.Connection = nil end end
function FarmEngine:FarmCycle()
    if not CONFIG.AutoFarm then return end
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
    local pos = LocalPlayer.Character.HumanoidRootPart.Position
    self.CycleCount = self.CycleCount + 1
    if CONFIG.AutoHarvest then self:HarvestPlants(pos) end
    if CONFIG.AutoPlant then self:PlantSeeds(pos) end
    if CONFIG.AutoWater then self:WaterPlants(pos) end
    if CONFIG.AutoSell then self:SellHarvest() end
end
function FarmEngine:HarvestPlants(pos)
    local plants = Utilities.GetHarvestablePlants(CONFIG.HarvestRadius)
    local count = 0
    for _,p in ipairs(plants) do
        if not self.Running then break end
        local prompt = p:FindFirstChildWhichIsA("ProximityPrompt")
        if prompt then
            local prim = p:FindFirstChild("PrimaryPart") or p:FindFirstChildOfClass("Part")
            if prim then
                LocalPlayer.Character.HumanoidRootPart.CFrame = prim.CFrame * CFrame.new(0,0,-2); task.wait(0.1)
                fireproximityprompt(prompt); count = count + 1; task.wait(0.15)
            end
        end
        local cd = p:FindFirstChildWhichIsA("ClickDetector")
        if cd then fireclickdetector(cd); count = count + 1; task.wait(0.1) end
        for _,rn in ipairs({"Harvest","Collect","Pick","Gather","HarvestPlant"}) do
            local r = Utilities.FindRemote(rn)
            if r then Utilities.FireRemote(rn, p); count = count + 1; break end
        end
        if count >= 15 then break end
    end
    if count > 0 then Log:Debug(string.format("🧺 Harvested %d plants", count)) end
end
function FarmEngine:PlantSeeds(pos)
    local si = Utilities.GetSeedInventory()
    if #si == 0 then return end
    local plots = {}
    for _,o in ipairs(workspace:GetDescendants()) do
        local n = o.Name:lower()
        if (o:IsA("Part") or o:IsA("MeshPart")) and (n:find("plot") or n:find("bed") or n:find("soil") or n:find("dirt") or n:find("ground")) then
            if (pos - o.Position).Magnitude <= CONFIG.PlantRadius then table.insert(plots, o) end
        end
    end
    local planted = 0
    for _,plot in ipairs(plots) do
        if not self.Running or planted >= 5 then break end
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then
            for _,st in ipairs(bp:GetChildren()) do
                if st:IsA("Tool") then
                    local pref = #CONFIG.PreferredSeeds == 0
                    for _,ps in ipairs(CONFIG.PreferredSeeds) do
                        if st.Name:lower():find(ps:lower()) then pref = true; break end
                    end
                    if pref then
                        LocalPlayer.Character.Humanoid:EquipTool(st); task.wait(0.2)
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(plot.Position + Vector3.new(0,1,0)); task.wait(0.15)
                        Utilities.FireRemote("PlantSeed", plot.Position, st.Name)
                        Utilities.FireRemote("Plant", plot, st)
                        Utilities.FireRemote("Grow", st.Name, plot.Position)
                        planted = planted + 1; task.wait(0.2); break
                    end
                end
            end
        end
    end
    if planted > 0 then Log:Debug(string.format("🌱 Planted %d seeds", planted)) end
end
function FarmEngine:WaterPlants(pos)
    local bp = LocalPlayer:FindFirstChild("Backpack")
    local wc = bp and (bp:FindFirstChild("Watering Can") or bp:FindFirstChild("WateringCan"))
    if not wc then
        local ch = LocalPlayer.Character
        if ch then wc = ch:FindFirstChild("Watering Can") or ch:FindFirstChild("WateringCan") end
    end
    if not wc then return end
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:EquipTool(wc); task.wait(0.15)
    end
    local watered = 0
    for _,o in ipairs(workspace:GetDescendants()) do
        if not self.Running or watered >= 10 then break end
        if o:IsA("Model") and (o.Name:lower():find("plant") or o.Name:lower():find("crop") or o.Name:lower():find("seed")) then
            local wl = o:FindFirstChild("Water") or o:FindFirstChild("Hydration") or o:FindFirstChild("Moisture")
            local nw = o:FindFirstChild("NeedsWater") or o:FindFirstChild("Thirsty")
            if nw or (wl and wl.Value < 50) then
                local prim = o:FindFirstChild("PrimaryPart") or o:FindFirstChildOfClass("Part") or o:FindFirstChildOfClass("MeshPart")
                if prim and (pos - prim.Position).Magnitude <= CONFIG.HarvestRadius then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = prim.CFrame * CFrame.new(0,0,-1.5); task.wait(0.15)
                    Utilities.FireRemote("Water", o); Utilities.FireRemote("WaterPlant", o); Utilities.FireRemote("Hydrate", o)
                    watered = watered + 1; task.wait(0.1)
                end
            end
        end
    end
end
function FarmEngine:SellHarvest()
    for _,rn in ipairs({"Sell","SellAll","SellHarvest","SellCrops","SellItems"}) do
        local r = Utilities.FindRemote(rn)
        if r then local s = Utilities.FireRemote(rn, "All"); if s then Log:Debug("💰 Sold harvest"); return end end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then
        for _,g in ipairs(pg:GetDescendants()) do
            if (g:IsA("ImageButton") or g:IsA("TextButton")) and (g.Text or g.Name):lower():find("sell") then
                local ap = g.AbsolutePosition
                if VirtualInputManager then
                    VirtualInputManager:SendMouseButtonEvent(ap.X+5, ap.Y+5, 0, true, game, 1); task.wait(0.05)
                    VirtualInputManager:SendMouseButtonEvent(ap.X+5, ap.Y+5, 0, false, game, 1)
                    Log:Debug("💰 Sell button pressed"); return
                end
            end
        end
    end
end

local AntiAFK = { Running = false, Connection = nil }
function AntiAFK:Start()
    if self.Running then return end; self.Running = true
    self.Connection = RunService.Heartbeat:Connect(function()
        if not self.Running or not CONFIG.AntiAFK then return end
        local ch = LocalPlayer.Character
        if ch and ch:FindFirstChild("HumanoidRootPart") then
            local p = ch.HumanoidRootPart.Position
            ch.HumanoidRootPart.CFrame = CFrame.new(p + Vector3.new(math.random(-50,50)/100, 0, math.random(-50,50)/100))
            task.wait(30)
        end
    end)
end
function AntiAFK:Stop() self.Running = false; if self.Connection then self.Connection:Disconnect() self.Connection = nil end end

function ToggleAll(enabled)
    CONFIG.AutoFarm = enabled; CONFIG.AutoCollectEventSeeds = enabled; CONFIG.AutoBuyEventSeeds = enabled
    CONFIG.AutoPlant = enabled; CONFIG.AutoHarvest = enabled; CONFIG.AutoSell = enabled
    if enabled then
        FarmEngine:Start(); EventSeedCollector:Start(); AntiAFK:Start()
        Log:Success("▶ ALL SYSTEMS STARTED")
    else
        FarmEngine:Stop(); EventSeedCollector:Stop(); AntiAFK:Stop()
        Log:Warn("⏹ ALL SYSTEMS STOPPED")
    end
end

-- Override Log:Add to update UI
local _origLogAdd = Log.Add
function Log:Add(level, msg, color)
    _origLogAdd(self, level, msg, color)
    if UI and UI.Elements and UI.Elements.LogList then
        pcall(function() UI:UpdateLogList() end)
    end
end

-- ============================================================
-- SECTION 7: FULL UI WITH ALL PAGES
-- ============================================================

function UI:Initialize()
    -- Cleanup old GUI
    local cp = {pcall(function() return GS("CoreGui") end) and GS("CoreGui") or nil, LocalPlayer:FindFirstChild("PlayerGui")}
    for _,p in ipairs(cp) do if p then local o = p:FindFirstChild("HarvestEliteGUI"); if o then pcall(function() o:Destroy() end) end end end

    local sg = Instance.new("ScreenGui")
    sg.Name = "HarvestEliteGUI"; sg.ResetOnSpawn = false; sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder = 999; sg.Enabled = true
    local ok, cg = pcall(function() return GS("CoreGui") end)
    sg.Parent = (ok and cg) or LocalPlayer:FindFirstChild("PlayerGui") or (function() local p = Instance.new("PlayerGui"); p.Parent = LocalPlayer; return p end)()
    
    self.ScreenGui = sg
    self.Instance = sg  -- ROOT = ScreenGui (NEVER OVERRIDE)
    
    self:CreateMainFrame()
    self:CreateTitleBar()
    self:CreateTabBar()
    self:CreateContentArea()
    self:MakeDraggable()
    self:AnimateEntrance()
    Log:Success("✅ UI Initialized (5 tabs)")
end

function UI:CreateMainFrame()
    local t = CONFIG.Theme
    local m = Instance.new("Frame")
    m.Name = "MainFrame"; m.Size = UDim2.new(0, 420, 0, 540)
    m.Position = UDim2.new(0.5, -210, 0.5, -270)
    m.BackgroundColor3 = t.Background; m.BackgroundTransparency = 1 - CONFIG.Opacity
    m.BorderSizePixel = 0; m.ClipsDescendants = false
    m.Parent = self.ScreenGui  -- FIX: Always ScreenGui
    
    local b = Instance.new("Frame")
    b.Size = UDim2.new(1,0,1,0); b.BackgroundColor3 = t.Secondary; b.BackgroundTransparency = 0.5; b.BorderSizePixel = 0; b.Parent = m
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, t.Secondary), ColorSequenceKeypoint.new(0.5, t.Primary), ColorSequenceKeypoint.new(1, t.Secondary)})
    g.Rotation = 90; g.Parent = b
    
    self.MainFrame = m
    self.Elements.MainFrame = m
end

function UI:CreateTitleBar()
    local t = CONFIG.Theme
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1,0,0,42); tb.BackgroundColor3 = t.Surface; tb.BorderSizePixel = 0; tb.Parent = self.MainFrame
    
    local tt = Instance.new("TextLabel")
    tt.Size = UDim2.new(1,-80,1,0); tt.Position = UDim2.new(0,12,0,0); tt.BackgroundTransparency = 1
    tt.Text = CONFIG.Title; tt.Font = CONFIG.Font; tt.TextSize = 16; tt.TextColor3 = t.Text; tt.TextXAlignment = Enum.TextXAlignment.Left; tt.Parent = tb
    
    local bd = Instance.new("Frame")
    bd.Size = UDim2.new(0,50,0,18); bd.Position = UDim2.new(0,12,0,24); bd.BackgroundColor3 = t.Primary; bd.BackgroundTransparency = 0.3; bd.BorderSizePixel = 0; bd.Parent = tb
    local bt = Instance.new("TextLabel")
    bt.Size = UDim2.new(1,0,1,0); bt.BackgroundTransparency = 1; bt.Text = "ACTIVE"; bt.Font = Enum.Font.Gotham; bt.TextSize = 10; bt.TextColor3 = Color3.fromRGB(255,255,255); bt.Parent = bd
    
    local mn = Instance.new("TextButton")
    mn.Size = UDim2.new(0,28,0,28); mn.Position = UDim2.new(1,-68,0,7); mn.BackgroundTransparency = 1
    mn.Text = "−"; mn.TextColor3 = Color3.fromRGB(180,180,180); mn.Font = Enum.Font.GothamBold; mn.TextSize = 18; mn.Parent = tb
    mn.MouseButton1Click:Connect(function() self:ToggleMinimize() end)
    
    local cl = Instance.new("TextButton")
    cl.Size = UDim2.new(0,28,0,28); cl.Position = UDim2.new(1,-34,0,7); cl.BackgroundTransparency = 1
    cl.Text = "✕"; cl.TextColor3 = Color3.fromRGB(220,80,80); cl.Font = Enum.Font.GothamBold; cl.TextSize = 16; cl.Parent = tb
    cl.MouseButton1Click:Connect(function() self:Destroy() end)
    
    local bl = Instance.new("Frame")
    bl.Size = UDim2.new(1,0,0,2); bl.Position = UDim2.new(0,0,1,0); bl.BackgroundColor3 = t.Primary; bl.BorderSizePixel = 0; bl.Parent = tb
    self.Elements.TitleBar = tb
end

function UI:CreateTabBar()
    local t = CONFIG.Theme
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1,0,0,34); tb.Position = UDim2.new(0,0,0,42); tb.BackgroundColor3 = Color3.fromRGB(18,18,30); tb.BorderSizePixel = 0; tb.Parent = self.MainFrame
    
    local tabs = {{Name="Main",Icon="🏠"},{Name="Events",Icon="🎯"},{Name="Farm",Icon="🌱"},{Name="Inventory",Icon="📦"},{Name="Logs",Icon="📋"}}
    local tw = 420 / #tabs
    for i,tab in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Name = tab.Name.."Tab"; btn.Size = UDim2.new(0,tw,0.8,0); btn.Position = UDim2.new(0,(i-1)*tw,0.1,0)
        btn.BackgroundColor3 = t.Surface; btn.BackgroundTransparency = 0.5; btn.BorderSizePixel = 0
        btn.Text = tab.Icon.." "..tab.Name; btn.Font = CONFIG.Font; btn.TextSize = 12; btn.TextColor3 = Color3.fromRGB(160,160,170); btn.Parent = tb
        
        local ind = Instance.new("Frame")
        ind.Name = "Indicator"; ind.Size = UDim2.new(0.8,0,0,3); ind.Position = UDim2.new(0.1,0,1,-3)
        ind.BackgroundColor3 = t.Primary; ind.BorderSizePixel = 0; ind.BackgroundTransparency = (tab.Name ~= "Main") and 1 or 0.2; ind.Parent = btn
        
        btn.MouseButton1Click:Connect(function()
            self:SwitchTab(tab.Name)
            for _,c in ipairs(tb:GetChildren()) do
                if c:IsA("TextButton") and c:FindFirstChild("Indicator") then
                    c:FindFirstChild("Indicator").BackgroundTransparency = 1; c.TextColor3 = Color3.fromRGB(160,160,170)
                end
            end
            btn.TextColor3 = t.Text; ind.BackgroundTransparency = 0.2
        end)
        self.Tabs[tab.Name] = {Button = btn, Indicator = ind}
    end
    self.Elements.TabBar = tb
end

function UI:CreateContentArea()
    local t = CONFIG.Theme
    local c = Instance.new("Frame")
    c.Name = "Content"; c.Size = UDim2.new(1,-20,1,-116); c.Position = UDim2.new(0,10,0,80)
    c.BackgroundColor3 = t.Surface; c.BackgroundTransparency = 0.3; c.BorderSizePixel = 0; c.Parent = self.MainFrame
    local cr = Instance.new("UICorner"); cr.CornerRadius = UDim.new(0,6); cr.Parent = c
    self.Elements.Content = c
    self.Elements.ContentPages = {}
    
    self:CreateMainPage()
    self:CreateEventPage()
    self:CreateFarmPage()
    self:CreateInventoryPage()
    self:CreateLogPage()
    self:SwitchTab("Main")
end

function UI:CreateMainPage()
    local t = CONFIG.Theme
    local c = self.Elements.Content; if not c then return end
    local p = Instance.new("ScrollingFrame")
    p.Name = "MainPage"; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.ScrollBarImageColor3 = t.Primary; p.CanvasSize = UDim2.new(0,0,0,0); p.Visible = false; p.Parent = c
    
    local y = 10
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1,-20,0,20); sl.Position = UDim2.new(0,10,0,y); sl.BackgroundTransparency = 1
    sl.Text = "📊 SYSTEM STATUS"; sl.Font = CONFIG.Font; sl.TextSize = 13; sl.TextColor3 = t.Accent; sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Parent = p; y = y + 25
    
    local items = {
        {L="⚡ Status", V="Running", C=Color3.fromRGB(50,255,100)},
        {L="💰 Balance", V="₿"..self:FormatNumber(Utilities.GetPlayerBalance()), C=t.Accent},
        {L="🌱 Plants", V="0", C=t.Primary},
        {L="📦 Seeds", V=tostring(#Utilities.GetSeedInventory()), C=Color3.fromRGB(100,200,255)},
    }
    for i,item in ipairs(items) do
        local col = (i-1)%2; local row = math.floor((i-1)/2)
        local cd = self:CreateCard(p, UDim2.new(0,185,0,52), UDim2.new(0,10+(col*195),0,y+(row*58)))
        cd.Parent = p
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1,-10,0,18); lb.Position = UDim2.new(0,8,0,6); lb.BackgroundTransparency = 1
        lb.Text = item.L; lb.Font = Enum.Font.Gotham; lb.TextSize = 10; lb.TextColor3 = Color3.fromRGB(160,160,170); lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = cd
        local vl = Instance.new("TextLabel")
        vl.Name = "Value"; vl.Size = UDim2.new(1,-10,0,22); vl.Position = UDim2.new(0,8,0,26); vl.BackgroundTransparency = 1
        vl.Text = item.V; vl.Font = CONFIG.Font; vl.TextSize = 14; vl.TextColor3 = item.C; vl.TextXAlignment = Enum.TextXAlignment.Left; vl.Parent = cd
    end
    y = y + 120
    
    local al = Instance.new("TextLabel")
    al.Size = UDim2.new(1,-20,0,20); al.Position = UDim2.new(0,10,0,y); al.BackgroundTransparency = 1
    al.Text = "⚡ QUICK ACTIONS"; al.Font = CONFIG.Font; al.TextSize = 13; al.TextColor3 = t.Accent; al.TextXAlignment = Enum.TextXAlignment.Left; al.Parent = p; y = y + 25
    
    local acts = {
        {N="▶ Start All", C=t.Primary, A=function() ToggleAll(true) end},
        {N="⏹ Stop All", C=t.Danger, A=function() ToggleAll(false) end},
        {N="🔄 Refresh", C=t.Warning, A=function() Log:Info("🔄 Refreshing...") end},
    }
    for i,act in ipairs(acts) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0,(380/#acts)-6,0,34); btn.Position = UDim2.new(0,10+((i-1)*((380/#acts)+3)),0,y)
        btn.BackgroundColor3 = act.C; btn.BackgroundTransparency = 0.7; btn.BorderSizePixel = 0
        btn.Text = act.N; btn.Font = CONFIG.Font; btn.TextSize = 12; btn.TextColor3 = Color3.fromRGB(255,255,255); btn.Parent = p
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = btn
        btn.MouseButton1Click:Connect(act.A)
        btn.MouseEnter:Connect(function() btn.BackgroundTransparency = 0.4 end)
        btn.MouseLeave:Connect(function() btn.BackgroundTransparency = 0.7 end)
    end
    y = y + 45
    
    local stl = Instance.new("TextLabel")
    stl.Size = UDim2.new(1,-20,0,20); stl.Position = UDim2.new(0,10,0,y); stl.BackgroundTransparency = 1
    stl.Text = "📈 SESSION STATS"; stl.Font = CONFIG.Font; stl.TextSize = 13; stl.TextColor3 = t.Accent; stl.TextXAlignment = Enum.TextXAlignment.Left; stl.Parent = p; y = y + 25
    
    local stats = {
        {L="Cycles", V="0", C=t.Primary}, {L="Event Seeds", V="0", C=Color3.fromRGB(255,150,50)},
        {L="Earned", V="₿0", C=t.Accent}, {L="Uptime", V="0m", C=Color3.fromRGB(100,200,255)},
    }
    for i,st in ipairs(stats) do
        local col = (i-1)%2; local row = math.floor((i-1)/2)
        local cd = self:CreateCard(p, UDim2.new(0,185,0,48), UDim2.new(0,10+(col*195),0,y+(row*52)))
        cd.Parent = p
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1,-10,0,16); lb.Position = UDim2.new(0,8,0,4); lb.BackgroundTransparency = 1
        lb.Text = st.L; lb.Font = Enum.Font.Gotham; lb.TextSize = 10; lb.TextColor3 = Color3.fromRGB(160,160,170); lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = cd
        local vl = Instance.new("TextLabel")
        vl.Name = "Value"; vl.Size = UDim2.new(1,-10,0,22); vl.Position = UDim2.new(0,8,0,22); vl.BackgroundTransparency = 1
        vl.Text = st.V; vl.Font = CONFIG.Font; vl.TextSize = 14; vl.TextColor3 = st.C; vl.TextXAlignment = Enum.TextXAlignment.Left; vl.Parent = cd
    end
    y = y + 110
    p.CanvasSize = UDim2.new(0,0,0,y+20)
    self.Elements.ContentPages["Main"] = p
end

function UI:CreateEventPage()
    local t = CONFIG.Theme
    local c = self.Elements.Content; if not c then return end
    local p = Instance.new("ScrollingFrame")
    p.Name = "EventPage"; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.ScrollBarImageColor3 = t.Primary; p.CanvasSize = UDim2.new(0,0,0,0); p.Visible = false; p.Parent = c
    
    local y = 10
    local hd = self:CreateCard(p, UDim2.new(0,380,0,70), UDim2.new(0,10,0,y)); hd.Parent = p; y = y + 78
    local ct = Instance.new("TextLabel")
    ct.Size = UDim2.new(1,-10,0,20); ct.Position = UDim2.new(0,8,0,6); ct.BackgroundTransparency = 1
    ct.Text = "🎯 Event Seed Collector"; ct.Font = CONFIG.Font; ct.TextSize = 14; ct.TextColor3 = t.Text; ct.TextXAlignment = Enum.TextXAlignment.Left; ct.Parent = hd
    local cd = Instance.new("TextLabel")
    cd.Size = UDim2.new(1,-10,0,16); cd.Position = UDim2.new(0,8,0,28); cd.BackgroundTransparency = 1
    cd.Text = "Auto-collects event seeds from Tom's Shop & Summer Merchant"; cd.Font = Enum.Font.Gotham; cd.TextSize = 10; cd.TextColor3 = Color3.fromRGB(140,140,150); cd.TextXAlignment = Enum.TextXAlignment.Left; cd.Parent = hd
    
    local tog = self:CreateToggle(hd, "Auto-Collect Event Seeds", CONFIG.AutoCollectEventSeeds, UDim2.new(0,8,0,44), function(v)
        CONFIG.AutoCollectEventSeeds = v; if v then EventSeedCollector:Start() else EventSeedCollector:Stop() end
        Log:Info(string.format("🎯 Auto-Collect: %s", v and "ON" or "OFF"))
    end); tog.Parent = hd
    
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1,-20,0,20); sl.Position = UDim2.new(0,10,0,y); sl.BackgroundTransparency = 1
    sl.Text = "🌱 EVENT SEEDS"; sl.Font = CONFIG.Font; sl.TextSize = 13; sl.TextColor3 = t.Accent; sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Parent = p; y = y + 25
    
    for sn, sc in pairs(CONFIG.EventSeeds) do
        local cd = self:CreateCard(p, UDim2.new(0,380,0,40), UDim2.new(0,10,0,y)); cd.Parent = p; y = y + 44
        local nl = Instance.new("TextLabel")
        nl.Size = UDim2.new(0,160,1,0); nl.Position = UDim2.new(0,8,0,0); nl.BackgroundTransparency = 1
        nl.Text = sn; nl.Font = CONFIG.Font; nl.TextSize = 12; nl.TextColor3 = t.Text; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = cd
        local pl = Instance.new("TextLabel")
        pl.Size = UDim2.new(0,80,1,0); pl.Position = UDim2.new(0,170,0,0); pl.BackgroundTransparency = 1
        pl.Text = "≤ ₿"..self:FormatNumber(sc.MaxPrice); pl.Font = Enum.Font.Gotham; pl.TextSize = 10; pl.TextColor3 = Color3.fromRGB(180,180,180); pl.TextXAlignment = Enum.TextXAlignment.Left; pl.Parent = cd
        local tg = self:CreateToggle(cd, "", sc.AutoBuy, UDim2.new(1,-50,0,8), function(v) CONFIG.EventSeeds[sn].AutoBuy = v end); tg.Parent = cd
    end
    p.CanvasSize = UDim2.new(0,0,0,y+20)
    self.Elements.ContentPages["Events"] = p
end

function UI:CreateFarmPage()
    local t = CONFIG.Theme
    local c = self.Elements.Content; if not c then return end
    local p = Instance.new("ScrollingFrame")
    p.Name = "FarmPage"; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.ScrollBarImageColor3 = t.Primary; p.CanvasSize = UDim2.new(0,0,0,0); p.Visible = false; p.Parent = c
    
    local y = 10
    local hd = self:CreateCard(p, UDim2.new(0,380,0,40), UDim2.new(0,10,0,y)); hd.Parent = p; y = y + 48
    local ft = Instance.new("TextLabel")
    ft.Size = UDim2.new(1,-10,0,20); ft.Position = UDim2.new(0,8,0,6); ft.BackgroundTransparency = 1
    ft.Text = "🌱 Farm Controls"; ft.Font = CONFIG.Font; ft.TextSize = 14; ft.TextColor3 = t.Text; ft.TextXAlignment = Enum.TextXAlignment.Left; ft.Parent = hd
    
    local toggles = {
        {L="Auto Farm", K="AutoFarm", D=CONFIG.AutoFarm},
        {L="Auto Plant", K="AutoPlant", D=CONFIG.AutoPlant},
        {L="Auto Harvest", K="AutoHarvest", D=CONFIG.AutoHarvest},
        {L="Auto Sell", K="AutoSell", D=CONFIG.AutoSell},
        {L="Auto Water", K="AutoWater", D=CONFIG.AutoWater},
        {L="Anti-AFK", K="AntiAFK", D=CONFIG.AntiAFK},
        {L="Auto Steal", K="AutoSteal", D=CONFIG.AutoSteal},
    }
    for _,td in ipairs(toggles) do
        local cd = self:CreateCard(p, UDim2.new(0,380,0,36), UDim2.new(0,10,0,y)); cd.Parent = p; y = y + 40
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(0,250,1,0); lb.Position = UDim2.new(0,8,0,0); lb.BackgroundTransparency = 1
        lb.Text = td.L; lb.Font = CONFIG.Font; lb.TextSize = 12; lb.TextColor3 = t.Text; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = cd
        local tg = self:CreateToggle(cd, "", td.D, UDim2.new(1,-50,0,6), function(v)
            CONFIG[td.K] = v
            if td.K == "AutoFarm" then if v then FarmEngine:Start() else FarmEngine:Stop() end
            elseif td.K == "AntiAFK" then if v then AntiAFK:Start() else AntiAFK:Stop() end end
            Log:Info(string.format("🔧 %s: %s", td.L, v and "ON" or "OFF"))
        end); tg.Parent = cd
    end
    y = y + 10
    local sl = Instance.new("TextLabel")
    sl.Size = UDim2.new(1,-20,0,20); sl.Position = UDim2.new(0,10,0,y); sl.BackgroundTransparency = 1
    sl.Text = "⚙️ SETTINGS"; sl.Font = CONFIG.Font; sl.TextSize = 13; sl.TextColor3 = t.Accent; sl.TextXAlignment = Enum.TextXAlignment.Left; sl.Parent = p; y = y + 25
    
    local settings = {
        {L="Harvest Radius", V=tostring(CONFIG.HarvestRadius), Mn=10, Mx=200, K="HarvestRadius"},
        {L="Max Plants", V=tostring(CONFIG.MaxPlants), Mn=10, Mx=500, K="MaxPlants"},
        {L="Min Sheckles", V=tostring(CONFIG.MinShecklesToKeep), Mn=100, Mx=100000, K="MinShecklesToKeep"},
    }
    for _,st in ipairs(settings) do
        local cd = self:CreateCard(p, UDim2.new(0,380,0,44), UDim2.new(0,10,0,y)); cd.Parent = p; y = y + 48
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(0,180,0,20); lb.Position = UDim2.new(0,8,0,6); lb.BackgroundTransparency = 1
        lb.Text = st.L; lb.Font = Enum.Font.Gotham; lb.TextSize = 11; lb.TextColor3 = t.Text; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = cd
        local vb = Instance.new("TextBox")
        vb.Size = UDim2.new(0,80,0,26); vb.Position = UDim2.new(0,190,0,8)
        vb.BackgroundColor3 = Color3.fromRGB(30,30,50); vb.BorderSizePixel = 0; vb.Text = st.V
        vb.Font = CONFIG.Font; vb.TextSize = 12; vb.TextColor3 = t.Text; vb.PlaceholderText = "Value"; vb.ClearTextOnFocus = false; vb.Parent = cd
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,4); bc.Parent = vb
        vb.FocusLost:Connect(function(enter)
            if enter then
                local v = tonumber(vb.Text)
                if v then CONFIG[st.K] = math.clamp(v, st.Mn, st.Mx); vb.Text = tostring(CONFIG[st.K]); Log:Info(string.format("⚙️ %s set to %d", st.L, CONFIG[st.K]))
                else vb.Text = tostring(CONFIG[st.K]) end
            end
        end)
    end
    p.CanvasSize = UDim2.new(0,0,0,y+20)
    self.Elements.ContentPages["Farm"] = p
end

function UI:CreateInventoryPage()
    local t = CONFIG.Theme
    local c = self.Elements.Content; if not c then return end
    local p = Instance.new("ScrollingFrame")
    p.Name = "InventoryPage"; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.BorderSizePixel = 0
    p.ScrollBarThickness = 4; p.ScrollBarImageColor3 = t.Primary; p.CanvasSize = UDim2.new(0,0,0,0); p.Visible = false; p.Parent = c
    
    local y = 10
    local hd = self:CreateCard(p, UDim2.new(0,380,0,40), UDim2.new(0,10,0,y)); hd.Parent = p; y = y + 48
    local it = Instance.new("TextLabel")
    it.Size = UDim2.new(1,-10,0,20); it.Position = UDim2.new(0,8,0,6); it.BackgroundTransparency = 1
    it.Text = "📦 Seed Inventory"; it.Font = CONFIG.Font; it.TextSize = 14; it.TextColor3 = t.Text; it.TextXAlignment = Enum.TextXAlignment.Left; it.Parent = hd
    
    local rb = Instance.new("TextButton")
    rb.Size = UDim2.new(0,80,0,24); rb.Position = UDim2.new(1,-90,0,8)
    rb.BackgroundColor3 = t.Primary; rb.BackgroundTransparency = 0.5; rb.BorderSizePixel = 0
    rb.Text = "🔄 Scan"; rb.Font = CONFIG.Font; rb.TextSize = 10; rb.TextColor3 = Color3.fromRGB(255,255,255); rb.Parent = hd
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,4); rc.Parent = rb
    
    local sc = Instance.new("Frame")
    sc.Name = "SeedList"; sc.Size = UDim2.new(1,-20,0,280); sc.Position = UDim2.new(0,10,0,y)
    sc.BackgroundColor3 = Color3.fromRGB(20,20,35); sc.BackgroundTransparency = 0.3; sc.BorderSizePixel = 0; sc.Parent = p
    local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0,4); lc.Parent = sc
    local sl = Instance.new("UIListLayout"); sl.Padding = UDim.new(0,2); sl.Parent = sc
    y = y + 290
    
    local function Refresh()
        for _,ch in ipairs(sc:GetChildren()) do if ch:IsA("Frame") and ch ~= sl then ch:Destroy() end end
        local seeds = Utilities.GetSeedInventory()
        if #seeds == 0 then
            local el = Instance.new("TextLabel")
            el.Size = UDim2.new(1,-10,0,40); el.Position = UDim2.new(0,5,0,5); el.BackgroundTransparency = 1
            el.Text = "No seeds found. Start farming!"; el.Font = Enum.Font.Gotham; el.TextSize = 12; el.TextColor3 = Color3.fromRGB(140,140,150); el.Parent = sc
        else
            for i,sn in ipairs(seeds) do
                if i > 30 then break end
                local item = Instance.new("Frame")
                item.Size = UDim2.new(1,-10,0,28); item.BackgroundColor3 = Color3.fromRGB(30,30,50); item.BackgroundTransparency = 0.3; item.BorderSizePixel = 0; item.Parent = sc
                local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,4); ic.Parent = item
                local nl = Instance.new("TextLabel")
                nl.Size = UDim2.new(1,-10,1,0); nl.Position = UDim2.new(0,8,0,0); nl.BackgroundTransparency = 1
                nl.Text = string.format("%d. %s", i, sn); nl.Font = Enum.Font.Gotham; nl.TextSize = 11; nl.TextColor3 = t.Text; nl.TextXAlignment = Enum.TextXAlignment.Left; nl.Parent = item
            end
        end
    end
    
    rb.MouseButton1Click:Connect(Refresh)
    task.spawn(Refresh)
    
    p.CanvasSize = UDim2.new(0,0,0,y+20)
    self.Elements.ContentPages["Inventory"] = p
end

function UI:CreateLogPage()
    local t = CONFIG.Theme
    local c = self.Elements.Content; if not c then return end
    local p = Instance.new("Frame")
    p.Name = "LogPage"; p.Size = UDim2.new(1,0,1,0); p.BackgroundTransparency = 1; p.Visible = false; p.Parent = c
    
    local ll = Instance.new("ScrollingFrame")
    ll.Name = "LogList"; ll.Size = UDim2.new(1,-20,1,-60); ll.Position = UDim2.new(0,10,0,10)
    ll.BackgroundColor3 = Color3.fromRGB(15,15,28); ll.BackgroundTransparency = 0.2; ll.BorderSizePixel = 0
    ll.ScrollBarThickness = 4; ll.ScrollBarImageColor3 = t.Primary; ll.CanvasSize = UDim2.new(0,0,0,0); ll.Parent = p
    local ll2 = Instance.new("UIListLayout"); ll2.Padding = UDim.new(0,1); ll2.Parent = ll
    
    local cb = Instance.new("TextButton")
    cb.Size = UDim2.new(0,100,0,28); cb.Position = UDim2.new(1,-110,1,-35)
    cb.BackgroundColor3 = t.Danger; cb.BackgroundTransparency = 0.5; cb.BorderSizePixel = 0
    cb.Text = "🗑 Clear"; cb.Font = CONFIG.Font; cb.TextSize = 10; cb.TextColor3 = Color3.fromRGB(255,255,255); cb.Parent = p
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,4); cc.Parent = cb
    cb.MouseButton1Click:Connect(function()
        Log.Messages = {}
        for _,ch in ipairs(ll:GetChildren()) do if ch:IsA("Frame") and ch ~= ll2 then ch:Destroy() end end
        ll.CanvasSize = UDim2.new(0,0,0,0)
    end)
    
    self.Elements.LogList = ll
    self.Elements.ContentPages["Logs"] = p
end

function UI:UpdateLogList()
    local ll = self.Elements.LogList; if not ll then return end
    for _,ch in ipairs(ll:GetChildren()) do if ch:IsA("Frame") then ch:Destroy() end end
    local si = math.max(1, #Log.Messages - 49)
    for i = si, #Log.Messages do
        local e = Log.Messages[i]
        local item = Instance.new("Frame")
        item.Size = UDim2.new(1,-10,0,20); item.BackgroundColor3 = Color3.fromRGB(25,25,40); item.BackgroundTransparency = 0.5; item.BorderSizePixel = 0; item.Parent = ll
        local lb = Instance.new("TextLabel")
        lb.Size = UDim2.new(1,-6,1,0); lb.Position = UDim2.new(0,4,0,0); lb.BackgroundTransparency = 1
        lb.Text = string.format("[%s] %s", e.Timestamp, e.Message); lb.Font = Enum.Font.Code; lb.TextSize = 9; lb.TextColor3 = e.Color; lb.TextXAlignment = Enum.TextXAlignment.Left; lb.Parent = item
    end
    ll.CanvasSize = UDim2.new(0,0,0,#Log.Messages*21); ll.CanvasPosition = Vector2.new(0, math.huge)
end

-- ============================================================
-- SECTION 8: UI HELPERS
-- ============================================================
function UI:CreateCard(parent, size, position)
    local card = Instance.new("Frame")
    card.Size = size; card.Position = position; card.BackgroundColor3 = CONFIG.Theme.Surface; card.BackgroundTransparency = 0.4; card.BorderSizePixel = 0; card.Parent = parent
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,6); cc.Parent = card
    return card
end

function UI:CreateToggle(parent, label, defaultValue, position, callback)
    local t = CONFIG.Theme; local toggled = defaultValue
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0,320,0,24); container.Position = position; container.BackgroundTransparency = 1; container.Parent = parent
    local lw = Instance.new("TextLabel")
    lw.Size = UDim2.new(1,-50,1,0); lw.BackgroundTransparency = 1; lw.Text = label; lw.Font = Enum.Font.Gotham; lw.TextSize = 11; lw.TextColor3 = t.Text; lw.TextXAlignment = Enum.TextXAlignment.Left; lw.Parent = container
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(0,40,0,22); if label:len() > 0 then tb.Position = UDim2.new(0,label:len()>0 and 260 or 0,0,1) else tb.Position = UDim2.new(0,0,0,1) end
    tb.BackgroundColor3 = toggled and t.Primary or Color3.fromRGB(50,50,60); tb.BorderSizePixel = 0; tb.Parent = container
    local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0,11); tc.Parent = tb
    local tcr = Instance.new("Frame")
    tcr.Size = UDim2.new(0,18,0,18); tcr.Position = UDim2.new(0, toggled and 20 or 2, 0, 2); tcr.BackgroundColor3 = Color3.fromRGB(255,255,255); tcr.BorderSizePixel = 0; tcr.Parent = tb
    local tcc = Instance.new("UICorner"); tcc.CornerRadius = UDim.new(0,9); tcc.Parent = tcr
    local function Update(v)
        toggled = v; tb.BackgroundColor3 = toggled and t.Primary or Color3.fromRGB(50,50,60)
        tcr.Position = UDim2.new(0, toggled and 20 or 2, 0, 2)
        if callback then callback(toggled) end
    end
    tb.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then Update(not toggled) end end)
    return container
end

function UI:FormatNumber(num)
    if num >= 1000000 then return string.format("%.1fM", num/1000000)
    elseif num >= 1000 then return string.format("%.1fK", num/1000) end
    return tostring(num)
end

function UI:MakeDraggable()
    local tb = self.Elements.TitleBar; if not tb then return end
    tb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.Dragging = true
            self.DragOffset = Vector2.new(input.Position.X - self.MainFrame.AbsolutePosition.X, input.Position.Y - self.MainFrame.AbsolutePosition.Y)
        end
    end)
    tb.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then self.Dragging = false end end)
    if UserInputService then
        UserInputService.InputChanged:Connect(function(input)
            if self.Dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local d = input.Delta
                self.MainFrame.Position = UDim2.new(0, self.MainFrame.AbsolutePosition.X + d.X, 0, self.MainFrame.AbsolutePosition.Y + d.Y)
            end
        end)
    end
end

function UI:SwitchTab(tabName)
    self.ActiveTab = tabName
    for n,p in pairs(self.Elements.ContentPages) do if p then p.Visible = (n == tabName) end end
end

function UI:ToggleMinimize()
    self.Minimized = not self.Minimized
    self.MainFrame.Size = self.Minimized and UDim2.new(0, 420, 0, 42) or UDim2.new(0, 420, 0, 540)
    for _, child in ipairs(self.MainFrame:GetChildren()) do
        if child ~= self.Elements.TitleBar then
            child.Visible = not self.Minimized
        end
    end
end

function UI:AnimateEntrance()
    if not TweenService then
        self.MainFrame.Position = UDim2.new(0.5, -210, 0.5, -270)
        return
    end
    self.MainFrame.Position = UDim2.new(0.5, -210, 0.3, 0)
    self.MainFrame.BackgroundTransparency = 0.8
    pcall(function()
        TweenService:Create(self.MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1 - CONFIG.Opacity,
            Position = UDim2.new(0.5, -210, 0.5, -270)
        }):Play()
    end)
end

function UI:Destroy()
    if self.ScreenGui then pcall(function() self.ScreenGui:Destroy() end) end
    self.ScreenGui = nil; self.MainFrame = nil; self.Instance = nil
end

-- ============================================================
-- SECTION 9: MAIN EXECUTION
-- ============================================================
local function main()
    Log:Success("🌱 Harvest Elite v2.1.1 loading...")
    task.wait(1)
    
    UI:Initialize()
    
    if CONFIG.AutoFarm then FarmEngine:Start() end
    if CONFIG.AutoCollectEventSeeds or CONFIG.AutoBuyEventSeeds then EventSeedCollector:Start() end
    if CONFIG.AntiAFK then AntiAFK:Start() end
    
    Log:Success("✅ Harvest Elite v2.1.1 ready!")
    Log:Info("📌 Press [Right Ctrl] to toggle UI")
    
    if UserInputService then
        UserInputService.InputBegan:Connect(function(input, gp)
            if not gp and input.KeyCode == Enum.KeyCode.RightControl then
                if UI.ScreenGui then UI.ScreenGui.Enabled = not UI.ScreenGui.Enabled end
            end
        end)
    end
    
    local startTime = os.time()
    task.spawn(function()
        while task.wait(10) do
            if FarmEngine.Running then
                local balance = Utilities.GetPlayerBalance()
            end
        end
    end)
end

local ok, err = pcall(main)
if not ok then
    warn("HARVEST ELITE ERROR: " .. tostring(err))
    local sg = Instance.new("ScreenGui")
    sg.Name = "HarvestEliteError"
    local tgt, _ = pcall(function() return game:GetService("CoreGui") end)
    sg.Parent = tgt and game:GetService("CoreGui") or LocalPlayer:WaitForChild("PlayerGui")
    local tb = Instance.new("TextButton")
    tb.Size = UDim2.new(0, 400, 0, 100)
    tb.Position = UDim2.new(0.5, -200, 0.5, -50)
    tb.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    tb.TextColor3 = Color3.fromRGB(255, 255, 255)
    tb.TextScaled = true
    tb.Text = "🚨 ERROR: " .. tostring(err) .. "\n\nClick to dismiss"
    tb.Parent = sg
    tb.MouseButton1Click:Connect(function() sg:Destroy() end)
end

-- ============================================================
-- END OF SCRIPT
-- ============================================================