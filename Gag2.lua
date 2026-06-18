local players = game:GetService("Players")
local lp = players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

local old = pg:FindFirstChild("FruitScan")
if old then old:Destroy() end

local sg = Instance.new("ScreenGui")
sg.Name = "FruitScan"
sg.ResetOnSpawn = false
sg.Parent = pg

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.95, 0, 0.85, 0)
frame.Position = UDim2.new(0.025, 0, 0.05, 0)
frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
frame.BackgroundTransparency = 0.2
frame.Parent = sg

local label = Instance.new("TextLabel")
label.Size = UDim2.new(1,-10,1,-10)
label.Position = UDim2.new(0,5,0,5)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(0, 255, 100)
label.TextSize = 13
label.Font = Enum.Font.GothamBold
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = frame

local lines = {}

-- Direktang hanapin ang Strawberry na may prutas
for _, plantModel in ipairs(workspace:GetChildren()) do
    local fruitsFolder = plantModel:FindFirstChild("Fruits")
    if fruitsFolder and #fruitsFolder:GetChildren() > 0 then
        table.insert(lines, "=== PLANT: " .. plantModel.Name .. " ===")
        
        for _, fruit in ipairs(fruitsFolder:GetChildren()) do
            table.insert(lines, "FRUIT: " .. fruit.ClassName .. " '" .. fruit.Name .. "'")
            
            -- Lahat ng attributes
            for k, v in pairs(fruit:GetAttributes()) do
                table.insert(lines, "  ATTR: " .. k .. " = " .. tostring(v))
            end
            
            -- Lahat ng children
            for _, child in ipairs(fruit:GetChildren()) do
                local val = ""
                if child:IsA("ValueBase") then
                    val = " = " .. tostring(child.Value)
                end
                table.insert(lines, "  CHILD: " .. child.ClassName .. " '" .. child.Name .. "'" .. val)
                
                -- Pati grandchildren
                for _, gc in ipairs(child:GetChildren()) do
                    local gcval = ""
                    if gc:IsA("ValueBase") then gcval = " = " .. tostring(gc.Value) end
                    table.insert(lines, "    GC: " .. gc.ClassName .. " '" .. gc.Name .. "'" .. gcval)
                    for k, v in pairs(gc:GetAttributes()) do
                        table.insert(lines, "      ATTR: " .. k .. " = " .. tostring(v))
                    end
                end
            end
        end
    end
end

if #lines == 0 then
    table.insert(lines, "WALANG FRUITS NA FOUND!")
    table.insert(lines, "Kailangan may VISIBLE na prutas sa harap mo.")
end

label.Text = table.concat(lines, "\n")