-- I-run ito sa loob ng GaG2
-- Lalabas ang results bilang Roblox notifications sa screen

local function notify(txt)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "GaG2 Scan",
        Text = txt,
        Duration = 10
    })
end

local fruitNames = {
    "Tomato","Carrot","Strawberry","Blueberry","Apple",
    "Corn","Mushroom","Grape","Pineapple","Mango","Coconut"
}

local found = false
for _, obj in ipairs(workspace:GetDescendants()) do
    for _, fname in ipairs(fruitNames) do
        if obj.Name == fname then
            found = true
            -- I-build ang path
            local path = obj.Name
            local cur = obj.Parent
            for i = 1, 6 do
                if cur and cur ~= game then
                    path = cur.Name .. ">" .. path
                    cur = cur.Parent
                else break end
            end
            -- Kuhanin ang attributes
            local attrs = ""
            for k, v in pairs(obj:GetAttributes()) do
                attrs = attrs .. k .. "=" .. tostring(v) .. " "
            end
            notify(path .. " | " .. attrs)
            task.wait(1)
        end
    end
end

if not found then
    notify("Walang nahanap! Siguraduhing may prutas sa garden mo.")
end