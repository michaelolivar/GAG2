local function notify(txt)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Fruit Scan",
        Text = txt,
        Duration = 12
    })
end

local fruitNames = {
    "Tomato","Carrot","Strawberry","Blueberry","Apple",
    "Corn","Mushroom","Grape","Pineapple","Mango","Coconut",
    "Banana","Cherry","Watermelon","Bamboo"
}

for _, plantModel in ipairs(workspace:GetChildren()) do
    for _, fname in ipairs(fruitNames) do
        if plantModel.Name == fname then
            -- I-scan ang lahat ng children ng plant
            for _, child in ipairs(plantModel:GetChildren()) do
                local attrs = ""
                for k, v in pairs(child:GetAttributes()) do
                    attrs = attrs .. k .. "=" .. tostring(v) .. " "
                end
                local val = child:IsA("ValueBase") and ("=" .. tostring(child.Value)) or ""
                notify(fname .. " > " .. child.ClassName .. " '" .. child.Name .. "'" .. val .. " | " .. attrs)
                task.wait(1.5)
            end
        end
    end
end