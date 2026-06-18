-- Step 1: find anything named like a crop/fruit
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Tomato" or obj.Name == "Carrot" or obj.Name == "Strawberry" then
        local path = obj.Name
        local cur = obj.Parent
        for i = 1, 6 do
            if cur then
                path = cur.Name .. " > " .. path
                cur = cur.Parent
            end
        end
        print(obj.ClassName .. " | " .. path)
        -- print all attributes
        for k, v in pairs(obj:GetAttributes()) do
            print("  ATTR:", k, "=", v)
        end
        -- print all children
        for _, child in ipairs(obj:GetChildren()) do
            print("  CHILD:", child.ClassName, child.Name,
                  child:IsA("ValueBase") and ("= " .. tostring(child.Value)) or "")
        end
    end
end