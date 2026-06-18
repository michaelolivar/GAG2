-- I-run ito habang may visible na prutas sa garden mo
print("====== GaG2 WORKSPACE SCAN ======")

-- Hanapin ang lahat ng may pangalang prutas
local fruitNames = {"Tomato","Carrot","Strawberry","Blueberry","Apple","Corn","Bamboo","Mushroom","Grape","Pineapple","Mango","Coconut","Banana","Cherry","Sunflower"}

for _, obj in ipairs(workspace:GetDescendants()) do
    for _, fname in ipairs(fruitNames) do
        if obj.Name == fname then
            -- I-build ang full path
            local path = obj.Name
            local cur = obj.Parent
            for i = 1, 8 do
                if cur and cur ~= game then
                    path = cur.Name .. " > " .. path
                    cur = cur.Parent
                else break end
            end
            print("[FOUND] " .. obj.ClassName .. " | PATH: " .. path)
            
            -- Attributes
            for k, v in pairs(obj:GetAttributes()) do
                print("   ATTR: " .. tostring(k) .. " = " .. tostring(v))
            end
            
            -- Children
            for _, child in ipairs(obj:GetChildren()) do
                local val = ""
                if child:IsA("ValueBase") then val = " = " .. tostring(child.Value) end
                print("   CHILD: " .. child.ClassName .. " '" .. child.Name .. "'" .. val)
            end
            print("---")
        end
    end
end

print("====== SCAN COMPLETE ======")