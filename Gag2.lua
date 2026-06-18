-- Run near a fully grown plant to find fruit objects
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") or obj:IsA("BasePart") then
        local parent = obj.Parent
        if parent and (
            parent.Name:lower():find("fruit") or
            parent.Name:lower():find("plant") or
            parent.Name:lower():find("crop") or
            parent.Name:lower():find("harvest")
        ) then
            print("FOUND: " .. obj.ClassName .. " '" .. obj.Name .. "' inside '" .. parent.Name .. "' (parent of parent: '" .. (parent.Parent and parent.Parent.Name or "nil") .. "')")
        end
    end
end