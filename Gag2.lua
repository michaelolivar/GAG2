-- TEST 1: Basic UI test — kung ito gumana, working ang executor mo
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "TestGUI"
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 200)
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
Frame.BackgroundTransparency = 0.5
Frame.Parent = ScreenGui

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, 0, 1, 0)
Label.BackgroundTransparency = 1
Label.Text = "✅ WORKING!"
Label.Font = Enum.Font.GothamBold
Label.TextSize = 24
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.Parent = Frame

print("✅ TEST UI LOADED - Executor is working!")