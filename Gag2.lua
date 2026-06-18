-- Run this FIRST to map the real workspace structure
local output = {}
for i, child in ipairs(workspace:GetChildren()) do
    local line = child.ClassName .. " | " .. child.Name
    local subChildren = child:GetChildren()
    if #subChildren > 0 and #subChildren < 10 then
        for _, sub in ipairs(subChildren) do
            line = line .. "\n   → " .. sub.ClassName .. " | " .. sub.Name
        end
    elseif #subChildren >= 10 then
        line = line .. "\n   → (" .. #subChildren .. " children)"
    end
    table.insert(output, line)
end
print(table.concat(output, "\n"))