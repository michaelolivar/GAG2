--[[
    ╔═══════════════════════════════════════════════════════════════════╗
    ║             HARVEST ELITE v2.1.0 - COMPLETE EDITION             ║
    ║                    ALL-IN-ONE CONSOLIDATED FILE                  ║
    ║                    Ready for Direct Execution                     ║
    ╚═══════════════════════════════════════════════════════════════════╝
    
    This file contains the complete game including:
    - Core game logic (harvest_elite.lua)
    - UI rendering system (ui_renderer.lua)
    - Main entry point (main.lua)
    
    No dependencies needed - just run this file!
]]--

--[[════════════════════════════════════════════════════════════════════════
    PART 1: CORE GAME ENGINE (harvest_elite.lua)
════════════════════════════════════════════════════════════════════════]]--

local HarvestElite = {}
HarvestElite.version = "2.1.0"
HarvestElite.status = "ACTIVE"

-- Game State
local gameState = {
    balance = 1000,
    plantsActive = 0,
    seedsOwned = 5,
    farmScore = 0.260,
    planttPlants = 0,
    farminiteActive = 0.15,
    seedsSeedRate = 0,
    scriptRunning = true,
    
    -- Farm data
    farms = {},
    inventory = {},
    events = {},
    logs = {},
    
    -- Plant tracking
    plants = {},
    currentPlantId = 0
}

-- Initialize inventory
function HarvestElite.initInventory()
    gameState.inventory = {
        {id = 1, name = "Tomato Seed", quantity = 3, rarity = "common"},
        {id = 2, name = "Carrot Seed", quantity = 2, rarity = "common"},
        {id = 3, name = "Golden Wheat", quantity = 0, rarity = "rare"},
        {id = 4, name = "Mystic Herb", quantity = 0, rarity = "epic"},
        {id = 5, name = "Fertilizer", quantity = 5, rarity = "common"},
        {id = 6, name = "Growth Potion", quantity = 1, rarity = "rare"}
    }
end

-- Initialize farms
function HarvestElite.initFarms()
    gameState.farms = {
        {id = 1, name = "Farm Alpha", size = 4, fertility = 0.8, planted = 0},
        {id = 2, name = "Farm Beta", size = 6, fertility = 0.6, planted = 0},
        {id = 3, name = "Farm Gamma", size = 3, fertility = 0.9, planted = 0}
    }
end

-- Plant a seed
function HarvestElite.plantSeed(farmId, seedType, quantity)
    quantity = quantity or 1
    
    local seedFound = false
    for i, item in ipairs(gameState.inventory) do
        if item.name == seedType and item.quantity > 0 then
            if item.quantity >= quantity then
                item.quantity = item.quantity - quantity
                seedFound = true
                break
            end
        end
    end
    
    if not seedFound then
        table.insert(gameState.events, {
            timestamp = os.time(),
            type = "error",
            message = "Insufficient seeds: " .. seedType
        })
        return false
    end
    
    for i = 1, quantity do
        gameState.currentPlantId = gameState.currentPlantId + 1
        local plant = {
            id = gameState.currentPlantId,
            type = seedType,
            farmId = farmId,
            plantedTime = os.time(),
            growthStage = 1,
            health = 100,
            daysGrowing = 0
        }
        table.insert(gameState.plants, plant)
    end
    
    gameState.plantsActive = gameState.plantsActive + quantity
    table.insert(gameState.events, {
        timestamp = os.time(),
        type = "success",
        message = "Planted " .. quantity .. " " .. seedType .. " on Farm " .. farmId
    })
    
    return true
end

-- Harvest plants
function HarvestElite.harvestPlants(farmId)
    local harvested = 0
    local newPlants = {}
    
    for i, plant in ipairs(gameState.plants) do
        if plant.farmId == farmId and plant.growthStage >= 3 then
            local reward = 100 + (math.random() * 50)
            gameState.balance = gameState.balance + reward
            gameState.farmScore = gameState.farmScore + 0.05
            
            table.insert(gameState.logs, {
                timestamp = os.time(),
                action = "harvest",
                plant = plant.type,
                reward = reward
            })
            
            harvested = harvested + 1
        else
            table.insert(newPlants, plant)
        end
    end
    
    gameState.plants = newPlants
    gameState.plantsActive = gameState.plantsActive - harvested
    
    if harvested > 0 then
        table.insert(gameState.events, {
            timestamp = os.time(),
            type = "success",
            message = "Harvested " .. harvested .. " plants. Earned B" .. (harvested * 100)
        })
    end
    
    return harvested
end

-- Update plant growth
function HarvestElite.updatePlants()
    local currentTime = os.time()
    
    for i, plant in ipairs(gameState.plants) do
        local timeDiff = currentTime - plant.plantedTime
        local daysGrowing = math.floor(timeDiff / 86400)
        
        plant.daysGrowing = daysGrowing
        
        if daysGrowing >= 3 then
            plant.growthStage = 4
        elseif daysGrowing >= 2 then
            plant.growthStage = 3
        elseif daysGrowing >= 1 then
            plant.growthStage = 2
        end
    end
    
    gameState.seedsSeedRate = #gameState.plants / 10
    gameState.planttPlants = #gameState.plants
end

-- Buy seeds
function HarvestElite.buySeed(seedType, quantity)
    quantity = quantity or 1
    local seedPrice = {
        ["Tomato Seed"] = 50,
        ["Carrot Seed"] = 60,
        ["Golden Wheat"] = 200,
        ["Mystic Herb"] = 500
    }
    
    local price = seedPrice[seedType] or 100
    local totalCost = price * quantity
    
    if gameState.balance < totalCost then
        table.insert(gameState.events, {
            timestamp = os.time(),
            type = "error",
            message = "Insufficient balance. Need B" .. totalCost .. " but have B" .. gameState.balance
        })
        return false
    end
    
    gameState.balance = gameState.balance - totalCost
    
    local found = false
    for i, item in ipairs(gameState.inventory) do
        if item.name == seedType then
            item.quantity = item.quantity + quantity
            found = true
            break
        end
    end
    
    if not found then
        table.insert(gameState.inventory, {
            id = #gameState.inventory + 1,
            name = seedType,
            quantity = quantity,
            rarity = "common"
        })
    end
    
    gameState.seedsOwned = gameState.seedsOwned + quantity
    
    table.insert(gameState.events, {
        timestamp = os.time(),
        type = "success",
        message = "Purchased " .. quantity .. " " .. seedType .. " for B" .. totalCost
    })
    
    return true
end

-- Use item
function HarvestElite.useItem(itemName, quantity)
    quantity = quantity or 1
    
    for i, item in ipairs(gameState.inventory) do
        if item.name == itemName and item.quantity > 0 then
            if item.quantity >= quantity then
                item.quantity = item.quantity - quantity
                
                if itemName == "Fertilizer" then
                    gameState.farmScore = gameState.farmScore + 0.02
                    table.insert(gameState.events, {
                        timestamp = os.time(),
                        type = "success",
                        message = "Applied " .. quantity .. " Fertilizer. Farm score increased!"
                    })
                    return true
                elseif itemName == "Growth Potion" then
                    for j, plant in ipairs(gameState.plants) do
                        plant.growthStage = math.min(plant.growthStage + 1, 4)
                    end
                    table.insert(gameState.events, {
                        timestamp = os.time(),
                        type = "success",
                        message = "Used Growth Potion! Plants grew faster."
                    })
                    return true
                end
            end
        end
    end
    
    return false
end

-- Start farming script
function HarvestElite.startScript()
    gameState.scriptRunning = true
    table.insert(gameState.logs, {
        timestamp = os.time(),
        action = "start",
        message = "Farming script started"
    })
end

-- Stop farming script
function HarvestElite.stopScript()
    gameState.scriptRunning = false
    table.insert(gameState.logs, {
        timestamp = os.time(),
        action = "stop",
        message = "Farming script stopped"
    })
end

-- Refresh game state
function HarvestElite.refresh()
    HarvestElite.updatePlants()
    table.insert(gameState.logs, {
        timestamp = os.time(),
        action = "refresh",
        message = "Game state refreshed"
    })
end

-- Get Main tab data
function HarvestElite.getMainTabData()
    return {
        systemStatus = {
            scriptStatus = gameState.scriptRunning and "Running" or "Stopped",
            balance = gameState.balance,
            plantsActive = gameState.plantsActive,
            seedsOwned = gameState.seedsOwned
        },
        sessionStatistics = {
            farmScore = string.format("%.3f", gameState.farmScore),
            planttPlants = gameState.planttPlants,
            farminiteActive = string.format("%.2f", gameState.farminiteActive),
            seedsSeedRate = gameState.seedsSeedRate
        }
    }
end

-- Get Events tab data
function HarvestElite.getEventsTabData()
    local recentEvents = {}
    local eventCount = math.min(10, #gameState.events)
    
    for i = #gameState.events - eventCount + 1, #gameState.events do
        if i > 0 then
            table.insert(recentEvents, gameState.events[i])
        end
    end
    
    return recentEvents
end

-- Get Farm tab data
function HarvestElite.getFarmTabData()
    return {
        farms = gameState.farms,
        plants = gameState.plants,
        activePlants = gameState.plantsActive
    }
end

-- Get Inventory tab data
function HarvestElite.getInventoryTabData()
    return {
        items = gameState.inventory,
        totalItems = #gameState.inventory,
        totalQuantity = 0
    }
end

-- Get Logs tab data
function HarvestElite.getLogsTabData()
    local recentLogs = {}
    local logCount = math.min(20, #gameState.logs)
    
    for i = #gameState.logs - logCount + 1, #gameState.logs do
        if i > 0 then
            table.insert(recentLogs, gameState.logs[i])
        end
    end
    
    return recentLogs
end

-- Initialize the game
function HarvestElite.init()
    HarvestElite.initInventory()
    HarvestElite.initFarms()
    
    table.insert(gameState.events, {
        timestamp = os.time(),
        type = "info",
        message = "Harvest Elite v2.1.0 initialized"
    })
    
    table.insert(gameState.logs, {
        timestamp = os.time(),
        action = "init",
        message = "Game initialized"
    })
    
    gameState.scriptRunning = true
    return true
end

-- Print current game state
function HarvestElite.printState()
    print("\n=== HARVEST ELITE v" .. HarvestElite.version .. " ===")
    print("Status: " .. HarvestElite.status)
    print("\n--- SYSTEM STATUS ---")
    print("Script Running: " .. tostring(gameState.scriptRunning))
    print("Balance: B" .. gameState.balance)
    print("Plants Active: " .. gameState.plantsActive)
    print("Seeds Owned: " .. gameState.seedsOwned)
    
    print("\n--- SESSION STATISTICS ---")
    print("Farm Score: " .. string.format("%.3f", gameState.farmScore))
    print("Plantt Plants: " .. gameState.planttPlants)
    print("Farminite Active: " .. string.format("%.2f", gameState.farminiteActive))
    print("Seeds Seed Rate: " .. gameState.seedsSeedRate)
    
    print("\n--- INVENTORY (" .. #gameState.inventory .. " types) ---")
    for i, item in ipairs(gameState.inventory) do
        print("  " .. item.name .. " x" .. item.quantity .. " (" .. item.rarity .. ")")
    end
    
    print("\n--- RECENT EVENTS (" .. #gameState.events .. " total) ---")
    local recentCount = math.min(3, #gameState.events)
    for i = #gameState.events - recentCount + 1, #gameState.events do
        if i > 0 then
            print("  [" .. gameState.events[i].type .. "] " .. gameState.events[i].message)
        end
    end
end

-- Run demo/test
function HarvestElite.demo()
    print("\n>>> Starting Harvest Elite Demo <<<\n")
    
    HarvestElite.init()
    HarvestElite.printState()
    
    print("\n>>> Purchasing seeds...")
    HarvestElite.buySeed("Tomato Seed", 2)
    HarvestElite.buySeed("Golden Wheat", 1)
    
    print("\n>>> Planting seeds...")
    HarvestElite.plantSeed(1, "Tomato Seed", 2)
    HarvestElite.plantSeed(2, "Golden Wheat", 1)
    
    print("\n>>> Using fertilizer...")
    HarvestElite.useItem("Fertilizer", 2)
    
    print("\n>>> Refreshing game state...")
    HarvestElite.refresh()
    
    print("\n>>> Harvesting plants...")
    HarvestElite.harvestPlants(1)
    
    print("\n>>> Final state...")
    HarvestElite.printState()
    
    print("\n>>> Main Tab Data:")
    local mainData = HarvestElite.getMainTabData()
    print("System Status: Running=" .. tostring(mainData.systemStatus.scriptStatus))
    print("Balance: B" .. mainData.systemStatus.balance)
    
    print("\n>>> Events Tab Data (" .. #HarvestElite.getEventsTabData() .. " events)")
    print("\n>>> Farm Tab Data:")
    local farmData = HarvestElite.getFarmTabData()
    print("Farms: " .. #farmData.farms .. ", Active Plants: " .. farmData.activePlants)
    
    print("\n>>> Inventory Tab Data:")
    local invData = HarvestElite.getInventoryTabData()
    print("Item Types: " .. invData.totalItems)
    
    print("\n>>> Logs Tab Data (" .. #HarvestElite.getLogsTabData() .. " logs)")
    
    print("\n>>> Demo Complete <<<\n")
end

--[[════════════════════════════════════════════════════════════════════════
    PART 2: UI RENDERER (ui_renderer.lua)
════════════════════════════════════════════════════════════════════════]]--

local UIRenderer = {}

-- Color codes for terminal
local colors = {
    reset = "\27[0m",
    bright = "\27[1m",
    dim = "\27[2m",
    
    black = "\27[30m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    
    bg_black = "\27[40m",
    bg_red = "\27[41m",
    bg_green = "\27[42m",
    bg_yellow = "\27[43m",
    bg_blue = "\27[44m",
    bg_magenta = "\27[45m",
    bg_cyan = "\27[46m",
    bg_white = "\27[47m",
}

-- Format a value with color
local function colorize(text, colorCode)
    return colorCode .. text .. colors.reset
end

-- Render Main Tab
function UIRenderer.renderMainTab()
    local width = 65
    HarvestElite.refresh()
    local mainData = HarvestElite.getMainTabData()
    
    print(colorize("\n╔═══════════════════════════════════════════════════════════╗", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("║  🌱 HARVEST ELITE • v2.1.0 " .. colorize("ACTIVE", colors.green) .. string.rep(" ", 23) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    print(colorize("║  " .. colorize("🏠 Main", colors.green .. colors.bright) .. "   📋 Events   🌾 Farm   📦 Inventory   📜 Logs" .. string.rep(" ", 7) .. "║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    print(colorize("║  📊 SYSTEM STATUS" .. string.rep(" ", 44) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    local scriptStatusColor = mainData.systemStatus.scriptStatus == "Running" and colors.green or colors.red
    local scriptStatusText = colorize(mainData.systemStatus.scriptStatus, scriptStatusColor .. colors.bright)
    print(colorize("║  ⚡ Script Status: " .. scriptStatusText .. string.rep(" ", 38 - #mainData.systemStatus.scriptStatus) .. "║", colors.cyan))
    
    print(colorize("║  💰 Balance: " .. colorize("B" .. mainData.systemStatus.balance, colors.yellow) .. string.rep(" ", 43 - #tostring(mainData.systemStatus.balance)) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    print(colorize("║  🌱 Plants Active: " .. mainData.systemStatus.plantsActive .. string.rep(" ", 38) .. "║", colors.cyan))
    print(colorize("║  🌾 Seeds Owned: " .. mainData.systemStatus.seedsOwned .. string.rep(" ", 40) .. "║", colors.cyan))
    
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    print(colorize("║  ⚡ QUICK ACTIONS" .. string.rep(" ", 45) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("║  " .. colorize("▶ Start All", colors.green) .. "        " .. colorize("⏹ Stop All", colors.red) .. "        " .. colorize("🔄 Refresh", colors.yellow) .. string.rep(" ", 20) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    print(colorize("║  📈 SESSION STATISTICS" .. string.rep(" ", 40) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    print(colorize("║  📊 Farm Score: " .. colorize(mainData.sessionStatistics.farmScore, colors.bright) .. string.rep(" ", 40 - #mainData.sessionStatistics.farmScore) .. "║", colors.cyan))
    print(colorize("║  🌿 Plantt Plants: " .. mainData.sessionStatistics.planttPlants .. string.rep(" ", 40) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    print(colorize("║  💎 Farminite Active: " .. colorize(mainData.sessionStatistics.farminiteActive, colors.bright) .. string.rep(" ", 37 - #mainData.sessionStatistics.farminiteActive) .. "║", colors.cyan))
    print(colorize("║  📊 Seeds Seeds Rate: " .. mainData.sessionStatistics.seedsSeedRate .. string.rep(" ", 40) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("╚═══════════════════════════════════════════════════════════╝", colors.cyan))
end

-- Render Events Tab
function UIRenderer.renderEventsTab()
    print(colorize("\n╔═══════════════════════════════════════════════════════════╗", colors.cyan))
    print(colorize("║  📋 EVENTS                                                 ║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    local events = HarvestElite.getEventsTabData()
    
    if #events == 0 then
        print(colorize("║  No events yet.                                           ║", colors.cyan))
    else
        for i, event in ipairs(events) do
            local eventColor = event.type == "success" and colors.green or (event.type == "error" and colors.red or colors.yellow)
            local eventIcon = event.type == "success" and "✓" or (event.type == "error" and "✗" or "ℹ")
            local eventText = eventIcon .. " " .. event.message
            
            if #eventText > 58 then
                eventText = eventText:sub(1, 55) .. "..."
            end
            
            print(colorize("║  " .. colorize(eventText, eventColor) .. string.rep(" ", 60 - #eventText) .. "║", colors.cyan))
        end
    end
    
    print(colorize("╚═══════════════════════════════════════════════════════════╝", colors.cyan))
end

-- Render Farm Tab
function UIRenderer.renderFarmTab()
    print(colorize("\n╔═══════════════════════════════════════════════════════════╗", colors.cyan))
    print(colorize("║  🌾 FARM MANAGEMENT                                        ║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    local farmData = HarvestElite.getFarmTabData()
    
    print(colorize("║  📍 FARMS                                                   ║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    for i, farm in ipairs(farmData.farms) do
        local farmInfo = "Farm " .. farm.id .. ": " .. farm.name .. " (Size: " .. farm.size .. ", Fertility: " .. farm.fertility .. ")"
        if #farmInfo > 58 then
            farmInfo = farmInfo:sub(1, 55) .. "..."
        end
        print(colorize("║  " .. colorize(farmInfo, colors.yellow) .. string.rep(" ", 60 - #farmInfo) .. "║", colors.cyan))
    end
    
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("║  🌱 ACTIVE PLANTS: " .. colorize(farmData.activePlants, colors.green) .. string.rep(" ", 41) .. "║", colors.cyan))
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    
    if #farmData.plants > 0 then
        for i, plant in ipairs(farmData.plants) do
            local stage = "Seed"
            if plant.growthStage == 2 then stage = "Sprout"
            elseif plant.growthStage == 3 then stage = "Growing"
            elseif plant.growthStage == 4 then stage = "Mature"
            end
            
            local plantInfo = "Plant " .. plant.id .. ": " .. plant.type .. " (" .. stage .. ", Health: " .. plant.health .. "%)"
            if #plantInfo > 58 then
                plantInfo = plantInfo:sub(1, 55) .. "..."
            end
            print(colorize("║  " .. plantInfo .. string.rep(" ", 60 - #plantInfo) .. "║", colors.cyan))
        end
    else
        print(colorize("║  No plants currently growing.                           ║", colors.cyan))
    end
    
    print(colorize("║" .. string.rep(" ", 63) .. "║", colors.cyan))
    print(colorize("╚═══════════════════════════════════════════════════════════╝", colors.cyan))
end

-- Render Inventory Tab
function UIRenderer.renderInventoryTab()
    print(colorize("\n╔═══════════════════════════════════════════════════════════╗", colors.cyan))
    print(colorize("║  📦 INVENTORY                                              ║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    local invData = HarvestElite.getInventoryTabData()
    
    print(colorize("║  ITEM                                        QTY    RARITY    ║", colors.bright .. colors.yellow))
    print(colorize("╟───────────────────────────────────────────────────────────╢", colors.cyan))
    
    for i, item in ipairs(invData.items) do
        local itemName = item.name
        local qty = "x" .. item.quantity
        local rarity = item.rarity:upper()
        
        local rarityColor = item.rarity == "common" and colors.white or
                           (item.rarity == "rare" and colors.blue or
                           (item.rarity == "epic" and colors.magenta or colors.yellow))
        
        local line = "║  " .. itemName .. string.rep(" ", 38 - #itemName) .. qty .. string.rep(" ", 7 - #qty) .. colorize(rarity, rarityColor) .. string.rep(" ", 8 - #rarity) .. "║"
        print(colorize(line, colors.cyan))
    end
    
    print(colorize("╚═══════════════════════════════════════════════════════════╝", colors.cyan))
end

-- Render Logs Tab
function UIRenderer.renderLogsTab()
    print(colorize("\n╔═══════════════════════════════════════════════════════════╗", colors.cyan))
    print(colorize("║  📜 LOGS                                                   ║", colors.cyan))
    print(colorize("╠═══════════════════════════════════════════════════════════╣", colors.cyan))
    
    local logs = HarvestElite.getLogsTabData()
    
    if #logs == 0 then
        print(colorize("║  No logs yet.                                             ║", colors.cyan))
    else
        for i, log in ipairs(logs) do
            local actionText = "[" .. log.action:upper() .. "] " .. (log.message or log.plant or "")
            
            if #actionText > 58 then
                actionText = actionText:sub(1, 55) .. "..."
            end
            
            print(colorize("║  " .. actionText .. string.rep(" ", 60 - #actionText) .. "║", colors.cyan))
        end
    end
    
    print(colorize("╚═══════════════════════════════════════════════════════════╝", colors.cyan))
end

-- Render all tabs in sequence
function UIRenderer.renderAllTabs()
    HarvestElite.init()
    
    print(colorize("\n" .. string.rep("=", 65), colors.cyan))
    print(colorize("HARVEST ELITE v2.1.0 - Full Tab Display", colors.bright .. colors.yellow))
    print(colorize(string.rep("=", 65) .. "\n", colors.cyan))
    
    UIRenderer.renderMainTab()
    UIRenderer.renderEventsTab()
    UIRenderer.renderFarmTab()
    UIRenderer.renderInventoryTab()
    UIRenderer.renderLogsTab()
end

-- Interactive demo
function UIRenderer.interactiveDemo()
    UIRenderer.renderAllTabs()
    
    print("\n--- Running Demo Actions ---\n")
    
    print(colorize("→ Purchasing 2 Tomato Seeds...", colors.yellow))
    HarvestElite.buySeed("Tomato Seed", 2)
    
    print(colorize("→ Purchasing 1 Golden Wheat...", colors.yellow))
    HarvestElite.buySeed("Golden Wheat", 1)
    
    print(colorize("→ Planting 2 Tomato Seeds in Farm 1...", colors.yellow))
    HarvestElite.plantSeed(1, "Tomato Seed", 2)
    
    print(colorize("→ Planting 1 Golden Wheat in Farm 2...", colors.yellow))
    HarvestElite.plantSeed(2, "Golden Wheat", 1)
    
    print(colorize("→ Using 1 Fertilizer...", colors.yellow))
    HarvestElite.useItem("Fertilizer", 1)
    
    print(colorize("→ Refreshing game state...\n", colors.yellow))
    HarvestElite.refresh()
    
    print(colorize("=== Updated Game State ===\n", colors.cyan))
    UIRenderer.renderAllTabs()
end

--[[════════════════════════════════════════════════════════════════════════
    PART 3: MAIN ENTRY POINT & EXECUTION
════════════════════════════════════════════════════════════════════════]]--

-- Auto-run the interactive demo
print("\n" .. string.rep("=", 70))
print("🌱 HARVEST ELITE v2.1.0 - STARTING...")
print(string.rep("=", 70) .. "\n")

-- Run the demo automatically
UIRenderer.interactiveDemo()

print("\n" .. string.rep("=", 70))
print("✅ HARVEST ELITE - EXECUTION COMPLETE")
print(string.rep("=", 70) .. "\n")

-- Make functions available for continued use
print("📝 You can now use these functions:")
print("   • HarvestElite.buySeed(type, qty)")
print("   • HarvestElite.plantSeed(farmId, type, qty)")
print("   • HarvestElite.harvestPlants(farmId)")
print("   • HarvestElite.useItem(name, qty)")
print("   • HarvestElite.refresh()")
print("   • HarvestElite.getMainTabData()")
print("   • UIRenderer.renderAllTabs()")
print("\n")
