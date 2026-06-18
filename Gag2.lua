-- Gumawa ng on-screen text display
local players = game:GetService("Players")
local lp = players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- Tanggalin ang luma
local old = pg:FindFirstChild("ScanResult")
if old then old:Destroy() end

-- Gumawa ng bagong GUI
local sg = Instance.new("ScreenGui")
sg.Name = "ScanResult"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.9, 0, 0.8, 0)
frame.Position = UDim2.new(0.05, 0, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.3
frame.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -10, 1, -10)
label.Position = UDim2.new(0, 5, 0, 5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextSize = 14
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = frame

-- I-scan ang workspace
local fruitNames = {
    "Tomato","Carrot","Strawberry","Blueberry","Apple",
    "Corn","Mushroom","Grape","Pineapple","Mango","Coconut",
    "Banana","Cherry","Watermelon","Bamboo","Sunflower","Tulip"
}

local lines = {}

for _, plantModel in ipairs(workspace:GetChildren()) do
    for _, fname in ipairs(fruitNames) do
        if plantModel.Name == fname then
            table.insert(lines, "=== PLANT: " .. fname .. " ===")
            
            -- Attributes ng plant mismo
            for k, v in pairs(plantModel:GetAttributes()) do
                table.insert(lines, "PLANT_ATTR: " .. k .. "=" .. tostring(v))
            end
            
            -- Children ng plant
            for _, child in ipairs(plantModel:GetChildren()) do
                local val = child:IsA("ValueBase") and ("=" .. tostring(child.Value)) or ""
                local attrs = ""
                for k, v in pairs(child:GetAttributes()) do
                    attrs = attrs .. k .. "=" .. tostring(v) .. " "
                end
                table.insert(lines, child.ClassName .. " '" .. child.Name .. "'" .. val)
                if attrs ~= "" then
                    table.insert(lines, "  ATTRS: " .. attrs)
                end
                
                -- Grandchildren (fruits siguro nandito)
                for _, gc in ipairs(child:GetChildren()) do
                    local gcval = gc:IsA("ValueBase") and ("=" .. tostring(gc.Value)) or ""
                    local gcattrs = ""
                    for k, v in pairs(gc:GetAttributes()) do
                        gcattrs = gcattrs .. k .. "=" .. tostring(v) .. " "
                    end
                    table.insert(lines, "  >" .. gc.ClassName .. " '" .. gc.Name .. "'" .. gcval)
                    if gcattrs ~= "" then
                        table.insert(lines, "    ATTRS: " .. gcattrs)
                    end
                end
            end
        end
    end
end

if #lines == 0 then
    table.insert(lines, "WALANG NAHANAP!")
    table.insert(lines, "Siguraduhing may tanim na halaman sa garden mo.")
end

label.Text = table.concat(lines, "\n")