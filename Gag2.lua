-- ui.lua - Module para sa UI creation at update
local UiModule = {}
local TweenService = game:GetService("TweenService")

-- Ilagay ang color at style constants (maaari galing sa styles.lua)
local COLORS = {
    Background = Color3.fromHex("#1C2F3C"),
    Header = Color3.fromHex("#65C18C"),
    Text = Color3.fromHex("#FFFFFF"),
    Inactive = Color3.fromHex("#A0A0A0"),
    ButtonStart = Color3.fromHex("#28A745"),
    ButtonStop = Color3.fromHex("#DC3545"),
    ButtonRefresh = Color3.fromHex("#FFC107")
}
local FONTS = {
    Title = Enum.Font.GothamBold,
    Body = Enum.Font.Gotham
}

-- Function upang malikha ang pangunahing screen GUI
function UiModule:InitializeGui()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HarvestEliteUI"
    screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
    
    -- Header Frame
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.BackgroundColor3 = COLORS.Header
    header.Size = UDim2.new(1, 0, 0, 40)
    header.Parent = screenGui
    
    -- Title Label
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "HARVEST ELITE"
    title.Font = FONTS.Title
    title.TextSize = 20
    title.TextColor3 = COLORS.Text
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 10, 0, 0)
    title.Size = UDim2.new(0, 200, 1, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Version Label
    local version = Instance.new("TextLabel")
    version.Name = "Version"
    version.Text = "v2.1.0"
    version.Font = FONTS.Body
    version.TextSize = 14
    version.TextColor3 = COLORS.Inactive
    version.BackgroundTransparency = 1
    version.Position = UDim2.new(0, 210, 0, 12)
    version.Size = UDim2.new(0, 50, 0, 20)
    version.Parent = header
    
    -- Active Status Pill
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Text = "ACTIVE"
    status.Font = FONTS.Body
    status.TextSize = 14
    status.TextColor3 = COLORS.Text
    status.BackgroundColor3 = COLORS.Header
    status.BorderSizePixel = 0
    status.Position = UDim2.new(1, -100, 0, 8)
    status.Size = UDim2.new(0, 80, 0, 24)
    status.BackgroundColor3 = COLORS.ButtonStart  -- green background
    status.Parent = header
    status.TextScaled = true
    status.ClipsDescendants = true
    -- Border radius (UIStroke or UICorner could be added if available)
    
    -- Tabs (Main, Events, Farm, Inventory, Logs)
    local tabNames = {"Main", "Events", "Farm", "Inventory", "Logs"}
    local tabsFrame = Instance.new("Frame")
    tabsFrame.Name = "Tabs"
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.Size = UDim2.new(1, 0, 0, 30)
    tabsFrame.Position = UDim2.new(0, 0, 0, 40)
    tabsFrame.Parent = screenGui

    for i, name in ipairs(tabNames) do
        local tab = Instance.new("TextButton")
        tab.Name = name .. "Tab"
        tab.Text = name
        tab.Font = FONTS.Body
        tab.TextSize = 16
        tab.BackgroundTransparency = 1
        tab.Position = UDim2.new((i-1)*0.2, 0, 0, 0)
        tab.Size = UDim2.new(0.2, 0, 1, 0)
        tab.TextColor3 = (i == 1) and COLORS.ButtonStart or COLORS.Inactive  -- active tab green
        tab.Parent = tabsFrame
        
        -- OnClick event (sobra-simplified; dapat mag-switch ng frames)
        tab.MouseButton1Click:Connect(function()
            -- Mark this tab active (green) and others inactive
            for _, sibling in ipairs(tabsFrame:GetChildren()) do
                if sibling:IsA("TextButton") then
                    sibling.TextColor3 = (sibling == tab) and COLORS.ButtonStart or COLORS.Inactive
                end
            end
            -- TODO: I-display ang content ng napiling tab
        end)
    end

    -- System Status section with cards
    local sysHeader = Instance.new("TextLabel")
    sysHeader.Text = "SYSTEM STATUS"
    sysHeader.Font = FONTS.Body
    sysHeader.TextSize = 14
    sysHeader.TextColor3 = COLORS.Text
    sysHeader.BackgroundTransparency = 1
    sysHeader.Position = UDim2.new(0, 10, 0, 80)
    sysHeader.Size = UDim2.new(0, 200, 0, 20)
    sysHeader.Parent = screenGui
    -- (Similar code needed for icon and underline if desired)
    
    -- Cards frame (Grid)
    local cardGrid = Instance.new("Frame")
    cardGrid.Name = "SystemGrid"
    cardGrid.BackgroundTransparency = 1
    cardGrid.Position = UDim2.new(0, 10, 0, 110)
    cardGrid.Size = UDim2.new(1, -20, 0, 120)
    cardGrid.Parent = screenGui
    -- Using UIGridLayout for simplicity
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize = UDim2.new(0, 200, 0, 50)
    gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
    gridLayout.Parent = cardGrid
    
    -- Helper: Create a status card
    local function createStatusCard(name, iconId, valueText, parentGrid)
        local card = Instance.new("Frame")
        card.Name = name .. "Card"
        card.BackgroundColor3 = COLORS.Background
        card.Size = UDim2.new(0, 200, 0, 50)
        card.Parent = parentGrid
        card.BorderSizePixel = 0
        
        local img = Instance.new("ImageLabel")
        img.Name = "Icon"
        img.Image = iconId
        img.Size = UDim2.new(0, 24, 0, 24)
        img.Position = UDim2.new(0, 5, 0.5, -12)
        img.BackgroundTransparency = 1
        img.Parent = card
        
        local label = Instance.new("TextLabel")
        label.Name = "Label"
        label.Text = valueText
        label.Font = FONTS.Body
        label.TextSize = 16
        label.TextColor3 = COLORS.Text
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 35, 0, 12)
        label.Size = UDim2.new(1, -40, 1, 0)
        label.Parent = card
    end
    
    -- Gumawa ng apat na System Status cards
    createStatusCard("ScriptStatus", "rbxassetid://ICON_KIDLAT", "Running", cardGrid)
    createStatusCard("Balance", "rbxassetid://ICON_COINS", "฿1,000", cardGrid)
    createStatusCard("PlantsActive", "rbxassetid://ICON_PLANT", "0", cardGrid)
    createStatusCard("SeedsOwned", "rbxassetid://ICON_SEEDS", "5", cardGrid)
    
    -- Quick Actions Section Title
    local quickHeader = Instance.new("TextLabel")
    quickHeader.Text = "QUICK ACTIONS"
    quickHeader.Font = FONTS.Body
    quickHeader.TextSize = 14
    quickHeader.TextColor3 = COLORS.Text
    quickHeader.BackgroundTransparency = 1
    quickHeader.Position = UDim2.new(0, 10, 0, 190)
    quickHeader.Size = UDim2.new(0, 200, 0, 20)
    quickHeader.Parent = screenGui
    
    -- Quick actions buttons
    local actions = { {Name="StartAll", Text="Start All", Color=COLORS.ButtonStart}, 
                      {Name="StopAll", Text="Stop All", Color=COLORS.ButtonStop}, 
                      {Name="Refresh", Text="Refresh", Color=COLORS.ButtonRefresh} }
    local actionsFrame = Instance.new("Frame")
    actionsFrame.Name = "Actions"
    actionsFrame.BackgroundTransparency = 1
    actionsFrame.Position = UDim2.new(0, 10, 0, 220)
    actionsFrame.Size = UDim2.new(1, -20, 0, 50)
    actionsFrame.Parent = screenGui
    -- Horizontal layout
    local hLayout = Instance.new("UIListLayout")
    hLayout.FillDirection = Enum.FillDirection.Horizontal
    hLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hLayout.Padding = UDim.new(0, 10)
    hLayout.Parent = actionsFrame
    
    for _, act in ipairs(actions) do
        local btn = Instance.new("TextButton")
        btn.Name = act.Name .. "Btn"
        btn.Text = act.Text
        btn.Font = FONTS.Body
        btn.TextSize = 16
        btn.TextColor3 = COLORS.Text
        btn.BackgroundColor3 = act.Color
        btn.Size = UDim2.new(0, 120, 1, 0)
        btn.Parent = actionsFrame
        
        -- Button click handlers (panuto)
        btn.MouseButton1Click:Connect(function()
            if act.Name == "StartAll" then
                self:OnStartAllClicked()
            elseif act.Name == "StopAll" then
                self:OnStopAllClicked()
            elseif act.Name == "Refresh" then
                self:OnRefreshClicked()
            end
        end)
    end
    
    -- Session Statistics section
    local statHeader = Instance.new("TextLabel")
    statHeader.Text = "SESSION STATISTICS"
    statHeader.Font = FONTS.Body
    statHeader.TextSize = 14
    statHeader.TextColor3 = COLORS.Text
    statHeader.BackgroundTransparency = 1
    statHeader.Position = UDim2.new(0, 10, 0, 290)
    statHeader.Size = UDim2.new(0, 200, 0, 20)
    statHeader.Parent = screenGui
    
    local statGrid = Instance.new("Frame")
    statGrid.Name = "StatsGrid"
    statGrid.BackgroundTransparency = 1
    statGrid.Position = UDim2.new(0, 10, 0, 320)
    statGrid.Size = UDim2.new(1, -20, 0, 100)
    statGrid.Parent = screenGui
    local grid2 = Instance.new("UIGridLayout")
    grid2.CellSize = UDim2.new(0, 200, 0, 50)
    grid2.CellPadding = UDim2.new(0, 10, 0, 10)
    grid2.Parent = statGrid
    
    createStatusCard("FarmScore", "rbxassetid://ICON_CHART", "0.260", statGrid)
    createStatusCard("PlantCount", "rbxassetid://ICON_PLANT", "0", statGrid)
    createStatusCard("FarminiteActive", "rbxassetid://ICON_WRENCH", "0.15", statGrid)
    createStatusCard("SeedRate", "rbxassetid://ICON_RATE", "0", statGrid)
    
    -- Store references for later updates
    self.ui = {
        Header = header,
        StatusLabel = status,
        Tabs = tabsFrame,
        SystemGrid = cardGrid,
        Actions = actionsFrame,
        StatsGrid = statGrid
    }
end

-- Event handlers for Quick Action buttons (dummy implementations)
function UiModule:OnStartAllClicked()
    -- Halimbawa: tawagin ang GameAPI.StartAll() at i-update ang ScriptStatus sa UI
    print("Start All pressed")
    -- GameAPI.StartAll()
    -- Tween sa UI, palitan ang ScriptStatus card (to Running)
    local card = self.ui.SystemGrid:FindFirstChild("ScriptStatusCard")
    if card then card.Label.Text = "Running" end
end
function UiModule:OnStopAllClicked()
    print("Stop All pressed")
    -- GameAPI.StopAll()
    local card = self.ui.SystemGrid:FindFirstChild("ScriptStatusCard")
    if card then card.Label.Text = "Stopped" end
end
function UiModule:OnRefreshClicked()
    print("Refresh pressed")
    -- GameAPI.RefreshData()
    -- halimbawa, i-update lahat ng UI mula sa state data
end

return UiModule
-- state.lua - Module para sa pag-track ng data at estado
local State = {
    ScriptRunning = false,
    Balance = 1000,
    PlantsActive = 0,
    SeedsOwned = 5,
    FarmScore = 0.260,
    TotalPlants = 0,
    Farminite = 0.15,
    SeedRate = 0
}

function State:GetBalance() return self.Balance end
function State:GetPlantsActive() return self.PlantsActive end
function State:IsScriptRunning() return self.ScriptRunning end
-- atbp.

-- Update functions (halimbawa, kapag nagbago ang laro)
function State:SetBalance(value)
    self.Balance = value
    -- Trigger event/callback kung mayroon
end

-- Toggle script state
function State:StartScript()
    self.ScriptRunning = true
end
function State:StopScript()
    self.ScriptRunning = false
end

return State
-- api.lua - Wrapper para sa Grow A Garden 2 game API (hypothetical)
local GameAPI = {}
-- Pwedeng code dito para tawagan ang aktwal na game functions 
-- o mag-subscribe sa RemoteEvents, depende sa modding environment.

function GameAPI.StartAll()
    -- Halimbawa, tawagin ang server function o local handler
    print("GameAPI: StartAll triggered")
    -- React to state
    require(script.Parent.state):StartScript()
end
function GameAPI.StopAll()
    print("GameAPI: StopAll triggered")
    require(script.Parent.state):StopScript()
end
function GameAPI.RefreshData()
    print("GameAPI: RefreshData triggered")
    -- Pwedeng kunin mula sa server ang latest values at i-set sa State module
end

-- Halimbawa ng pagkuha ng data
function GameAPI.GetBalance() return require(script.Parent.state):GetBalance() end
function GameAPI.GetPlantsActive() return require(script.Parent.state):GetPlantsActive() end

-- Event hooks (dapat ang modding environment ay may event system, dito
-- pseudo-code lang ito)
GameAPI.OnBalanceChanged = {}  -- maaaring isang table ng callbacks
GameAPI.OnPlantsChanged = {}
-- Iba pang hooks...

return GameAPI
-- assets.lua - Listahan ng mga image asset at style constants
-- (Palitan ang mga URL o assetid ayon sa aktwal na assets)
return {
    Icons = {
        Leaf = "rbxassetid://icon_leaf_32",
        Coin = "rbxassetid://icon_coin_24",
        Seed = "rbxassetid://icon_seed_24",
        Chart = "rbxassetid://icon_chart_24",
        Wrench = "rbxassetid://icon_wrench_24",
        Play = "rbxassetid://icon_play_24",
        Stop = "rbxassetid://icon_stop_24",
        Refresh = "rbxassetid://icon_refresh_24"
    },
    Styles = {
        FontTitle = Enum.Font.GothamBold,
        FontBody = Enum.Font.Gotham,
        ColorBackground = Color3.fromHex("#1C2F3C"),
        ColorAccent = Color3.fromHex("#65C18C"),
        ColorText = Color3.fromHex("#FFFFFF"),
        ColorInactive = Color3.fromHex("#A0A0A0"),
        ButtonStart = Color3.fromHex("#28A745"),
        ButtonStop = Color3.fromHex("#DC3545"),
        ButtonRefresh = Color3.fromHex("#FFC107")
    }
}
