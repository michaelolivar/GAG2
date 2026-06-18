-- Paste this in executor while in GaG2, near a grown plant/fruit
print("=== WORKSPACE TOP LEVEL ===")
for _, c in ipairs(workspace:GetChildren()) do
    print(c.ClassName, "|", c.Name, "| children:", #c:GetChildren())
end

print("\n=== SEARCHING FOR FRUIT/PLANT/CROP FOLDERS ===")
for _, obj in ipairs(workspace:GetDescendants()) do
    local n = obj.Name:lower()
    if n:find("fruit") or n:find("plant") or n:find("crop") or n:find("harvest") or n:find("farm") or n:find("garden") then
        local p = obj.Parent
        print(obj.ClassName, "|", obj.Name, "| parent:", p and p.Name or "nil", "| grandparent:", p and p.Parent and p.Parent.Name or "nil")
    end
end

print("\n=== MODELS WITH PRIMARYPART (likely fruits/plants) ===")
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Model") and obj.PrimaryPart then
        local p = obj.Parent
        print("Model:", obj.Name, "| parent:", p and p.Name or "nil", "| grandparent:", p and p.Parent and p.Parent.Name or "nil")
    end
end