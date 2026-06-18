local players = game:GetService("Players")
local lp = players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("ScanResult2")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "ScanResult2"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.95, 0, 0.85, 0)
frame.Position = UDim2.new(0.025, 0, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.2
frame.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -10, 1, -10)
label.Position = UDim2.new(0, 5, 0, 5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.TextSize = 13
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = frame

local fruitNames = {
    "Tomato","Carrot","Strawberry","Blueberry","Apple",
    "Corn","Mushroom","Grape","Pineapple","Mango","Coconut",
    "Banana","Cherry","Watermelon","Bamboo","Sunflower","Tulip",
    "Green Bean","Ghost Pepper"
}

local lines = {}

for _, plantModel in ipairs(workspace:GetChildren()) do
    for _, fname in ipairs(fruitNames) do
        if plantModel.Name == fname then
            local fruitsFolder = plantModel:FindFirstChild("Fruits")
            if fruitsFolder then
                table.insert(lines, "=== " .. fname .. " > Fruits ===")
                for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                    table.insert(lines, "FRUIT: " .. fruit.ClassName .. " '" .. fruit.Name .. "'")
                    -- Attributes
                    for k, v in pairs(fruit:GetAttributes()) do
                        table.insert(lines, "  ATTR: " .. k .. " = " .. tostring(v))
                    end
                    -- Children
                    for _, child in ipairs(fruit:GetChildren()) do
                        local val = child:IsA("ValueBase") and ("=" .. tostring(child.Value)) or ""
                        table.insert(lines, "  CHILD: " .. child.ClassName .. " '" .. child.Name .. "'" .. val)
                    end
                end
            end
        end
    end
end

if #lines == 0 then
    table.insert(lines, "WALANG NAHANAP SA FRUITS FOLDER!")
    table.insert(lines, "Siguraduhing may MATURE/GROWN na halaman.")
end

label.Text = table.concat(lines, "\n")