-- ╔═══════════════════════════════════════════════════════════╗
-- ║         GAG2 Hub  |  Grow a Garden 2 Script              ║
-- ║         Auto Event Seed Collector  |  v1.0               ║
-- ║         Premium SpeedHub-Style UI                        ║
-- ╚═══════════════════════════════════════════════════════════╝

-- ╔═ SERVICES ═══════════════════════════════════════════════╗
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ CONFIG ═════════════════════════════════════════════════╗
local Config = {
    AutoCollect   = false,
    CollectDelay  = 0.4,     -- Delay between collections (seconds)
    ScanInterval  = 1.2,     -- How often to scan for seeds (seconds)
    TeleportMode  = true,    -- Teleport to seed vs walk
    SelectedSeeds = {
        ["Gold Seed"]    = false,
        ["Rainbow Seed"] = false,
        ["Bird"]         = false,
        ["Seed Pack"]    = false,
    },
}

local State = {
    Collected   = 0,
    LogCount    = 0,
    Minimized   = false,
    DropOpen    = false,
    AllSelected = false,
}
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ SEED DEFINITIONS ═══════════════════════════════════════╗
local SeedList = {
    { name = "Gold Seed",    icon = "⭐", color = Color3.fromRGB(255, 200, 0),   keywords = {"goldseed","gold seed","golden seed","gold_seed","eventgoldseed","goldenseed"} },
    { name = "Rainbow Seed", icon = "🌈", color = Color3.fromRGB(180, 100, 255), keywords = {"rainbowseed","rainbow seed","rainbow_seed","eventrainbowseed"} },
    { name = "Bird",         icon = "🐦", color = Color3.fromRGB(80,  160, 255), keywords = {"birdseed","bird seed","bird_seed","eventbird","birdegg","bird egg"} },
    { name = "Seed Pack",    icon = "📦", color = Color3.fromRGB(50,  210, 120), keywords = {"seedpack","seed pack","seed_pack","eventseedpack","seedbundle"} },
}
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ THEME ══════════════════════════════════════════════════╗
local T = {
    BG          = Color3.fromRGB(9,   9,  14),
    Surface     = Color3.fromRGB(14,  14, 22),
    Card        = Color3.fromRGB(18,  18, 30),
    Hover       = Color3.fromRGB(26,  26, 42),
    Border      = Color3.fromRGB(35,  35, 55),
    AccentHi    = Color3.fromRGB(110, 120, 255),
    Accent      = Color3.fromRGB(88,  98,  242),
    AccentLo    = Color3.fromRGB(60,  68,  210),
    Text        = Color3.fromRGB(235, 235, 245),
    TextSub     = Color3.fromRGB(130, 130, 160),
    TextMuted   = Color3.fromRGB(75,  75,  105),
    Green       = Color3.fromRGB(52,  199, 110),
    Yellow      = Color3.fromRGB(255, 185, 50),
    Red         = Color3.fromRGB(235, 60,  65),
    White       = Color3.fromRGB(255, 255, 255),
}
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ UTILITY ════════════════════════════════════════════════╗
local function New(class, props, children)
    local i = Instance.new(class)
    for k, v in pairs(props or {}) do i[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = i end
    return i
end

local function Tween(obj, props, dur, style, dir)
    TweenService:Create(obj, TweenInfo.new(
        dur or 0.25,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    ), props):Play()
end

local function Corner(r, parent)
    return New("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent })
end

local function Stroke(color, thick, trans, parent)
    return New("UIStroke", {
        Color = color, Thickness = thick,
        Transparency = trans or 0, Parent = parent
    })
end

local function Gradient(c1, c2, rot, parent)
    return New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, c1),
            ColorSequenceKeypoint.new(1, c2),
        }),
        Rotation = rot or 0,
        Parent = parent,
    })
end

-- onClick (optional) only fires if release happens within DRAG_THRESHOLD px
-- of press point, so dragging never accidentally triggers a click action.
-- Also clamps the frame so it can never be dragged off-screen — critical on
-- small mobile displays where it's easy to lose the panel past the edge.
local DRAG_THRESHOLD = 6

local function ClampOffset(frame, scaleX, scaleY, offsetX, offsetY)
    local camera = workspace.CurrentCamera
    if not camera then return offsetX, offsetY end
    local vp = camera.ViewportSize
    local absSize = frame.AbsoluteSize
    local ap = frame.AnchorPoint

    local minOffX = -scaleX * vp.X + ap.X * absSize.X
    local maxOffX = vp.X - absSize.X - scaleX * vp.X + ap.X * absSize.X
    local minOffY = -scaleY * vp.Y + ap.Y * absSize.Y
    local maxOffY = vp.Y - absSize.Y - scaleY * vp.Y + ap.Y * absSize.Y

    local clampedX = math.clamp(offsetX, math.min(minOffX, maxOffX), math.max(minOffX, maxOffX))
    local clampedY = math.clamp(offsetY, math.min(minOffY, maxOffY), math.max(minOffY, maxOffY))
    return clampedX, clampedY
end

local function MakeDraggable(frame, handle, onClick)
    local drag, mouseStart, frameStart, moved = false, nil, nil, false
    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
            moved = false
            mouseStart = inp.Position
            frameStart = frame.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    drag = false
                    if onClick and not moved then onClick() end
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local d = inp.Position - mouseStart
            if math.abs(d.X) > DRAG_THRESHOLD or math.abs(d.Y) > DRAG_THRESHOLD then
                moved = true
            end
            local offX, offY = ClampOffset(
                frame, frameStart.X.Scale, frameStart.Y.Scale,
                frameStart.X.Offset + d.X, frameStart.Y.Offset + d.Y
            )
            frame.Position = UDim2.new(frameStart.X.Scale, offX, frameStart.Y.Scale, offY)
        end
    end)
end


local function HoverEffect(btn, normal, hover)
    btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = hover }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = normal }, 0.15) end)
end
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ DESTROY OLD INSTANCE ═══════════════════════════════════╗
if CoreGui:FindFirstChild("GAG2Hub") then
    CoreGui:FindFirstChild("GAG2Hub"):Destroy()
end
-- ╚══════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════════════════════════╗
-- ║                        MAIN GUI                         ║
-- ╚══════════════════════════════════════════════════════════╝
local ScreenGui = New("ScreenGui", {
    Name = "GAG2Hub", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false, IgnoreGuiInset = true, Parent = CoreGui,
})

-- ── Main Frame ──────────────────────────────────────────────
local BASE_W, BASE_H = 400, 560  -- design-time reference size

local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, BASE_W, 0, BASE_H),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5, 0.5),  -- center anchor so UIScale shrinks evenly
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Parent = ScreenGui,
})
Corner(14, Main)
Stroke(T.Border, 1, 0.2, Main)

-- Responsive scale: shrinks the whole panel to fit small mobile screens
-- without needing to rebuild every internal offset.
local MainScale = New("UIScale", { Scale = 1, Parent = Main })

local function UpdateResponsiveScale()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local vp = camera.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return end
    local marginX, marginY = 20, 24  -- breathing room from screen edges
    local scaleX = (vp.X - marginX) / BASE_W
    local scaleY = (vp.Y - marginY) / BASE_H
    local scale = math.clamp(math.min(scaleX, scaleY, 1), 0.55, 1)
    Tween(MainScale, { Scale = scale }, 0.25)
end

UpdateResponsiveScale()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
        UpdateResponsiveScale()
    end
end)
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateResponsiveScale)
end

-- Outer ambient glow
local GlowBG = New("Frame", {
    Size = UDim2.new(1, 60, 1, 60),
    Position = UDim2.new(0, -30, 0, -30),
    BackgroundColor3 = T.Accent,
    BackgroundTransparency = 0.88,
    BorderSizePixel = 0,
    ZIndex = -1,
    Parent = Main,
})
Corner(20, GlowBG)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                      CHAT HEAD                          ║
-- ╚══════════════════════════════════════════════════════════╝
local CH_SIZE = 58

local ChatHead = New("Frame", {
    Name = "ChatHead",
    Size = UDim2.new(0, CH_SIZE, 0, CH_SIZE),
    Position = UDim2.new(1, -(CH_SIZE + 18), 0.5, -(CH_SIZE / 2)),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 200,
    Parent = ScreenGui,
})
Corner(99, ChatHead)
Gradient(T.AccentHi, T.AccentLo, 135, ChatHead)

-- Outer ring
local CHRing = New("Frame", {
    Size = UDim2.new(1, 10, 1, 10),
    Position = UDim2.new(0, -5, 0, -5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 199,
    Parent = ChatHead,
})
Corner(99, CHRing)
Stroke(T.AccentHi, 2, 0.4, CHRing)

-- Icon
New("TextLabel", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "🌱",
    TextSize = 24,
    Font = Enum.Font.GothamBold,
    ZIndex = 201,
    Parent = ChatHead,
})

-- Status dot (top-right corner of chat head)
local CHDot = New("Frame", {
    Name = "CHDot",
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -3, 0, -3),
    BackgroundColor3 = T.TextMuted,
    BorderSizePixel = 0,
    ZIndex = 202,
    Parent = ChatHead,
})
Corner(99, CHDot)
New("UIStroke", { Color = T.BG, Thickness = 2.5, Parent = CHDot })

-- Clickable button
local CHBtn = New("TextButton", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "",
    ZIndex = 203,
    Parent = ChatHead,
})

-- ── Chat head helper functions ────────────────────────────
local function ShowChatHead()
    ChatHead.Visible = true
    ChatHead.Size = UDim2.new(0, 0, 0, 0)
    ChatHead.BackgroundTransparency = 1
    -- Bounce in
    Tween(ChatHead, { Size = UDim2.new(0, CH_SIZE + 8, 0, CH_SIZE + 8), BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.2)
    Tween(ChatHead, { Size = UDim2.new(0, CH_SIZE, 0, CH_SIZE) }, 0.15, Enum.EasingStyle.Quart)
    -- Sync dot color with collect state
    CHDot.BackgroundColor3 = Config.AutoCollect and T.Green or T.Red
end

local function HideChatHead()
    Tween(ChatHead, { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }, 0.2, Enum.EasingStyle.Quart)
    task.delay(0.22, function() ChatHead.Visible = false end)
end

local function OpenMain()
    HideChatHead()
    task.wait(0.1)
    Main.Visible = true
    Main.Size = UDim2.new(0, 400, 0, 0)
    Main.BackgroundTransparency = 1
    Tween(Main, { Size = UDim2.new(0, 400, 0, 560), BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function CloseMain()
    Tween(Main, { Size = UDim2.new(0, 400, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quart)
    task.delay(0.26, function()
        Main.Visible = false
        ShowChatHead()
    end)
end

MakeDraggable(ChatHead, CHBtn, OpenMain)

-- ── HEADER ──────────────────────────────────────────────────
local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = T.Surface,
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = Main,
})
Corner(14, Header)
-- Fix bottom corners
New("Frame", { Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14),
    BackgroundColor3 = T.Surface, BorderSizePixel = 0, ZIndex = 5, Parent = Header })

-- Accent line
local AccentBar = New("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0, 0, 1, -1),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0, ZIndex = 6, Parent = Header,
})
Gradient(T.AccentHi, T.AccentLo, 0, AccentBar)

-- Logo
local LogoBox = New("Frame", {
    Size = UDim2.new(0, 38, 0, 38),
    Position = UDim2.new(0, 13, 0.5, -19),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0, ZIndex = 6, Parent = Header,
})
Corner(9, LogoBox)
Gradient(T.AccentHi, T.AccentLo, 135, LogoBox)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌱", TextSize = 18, Font = Enum.Font.GothamBold, ZIndex = 7, Parent = LogoBox,
})

-- Title + subtitle
New("TextLabel", {
    Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 62, 0, 10),
    BackgroundTransparency = 1, Text = "Grow a Garden 2",
    TextColor3 = T.Text, TextSize = 14, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = Header,
})
New("TextLabel", {
    Size = UDim2.new(0, 200, 0, 15), Position = UDim2.new(0, 62, 0, 31),
    BackgroundTransparency = 1, Text = "Event Seed Collector",
    TextColor3 = T.TextSub, TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = Header,
})

-- Version pill
local VerPill = New("Frame", {
    Size = UDim2.new(0, 44, 0, 18), Position = UDim2.new(1, -118, 0.5, -9),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 6, Parent = Header,
})
Corner(20, VerPill)
Gradient(T.AccentHi, T.AccentLo, 90, VerPill)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "v1.0", TextColor3 = T.White, TextSize = 10,
    Font = Enum.Font.GothamBold, ZIndex = 7, Parent = VerPill,
})

-- Minimize button
local MinBtn = New("TextButton", {
    Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -68, 0.5, -14),
    BackgroundColor3 = T.Hover, BorderSizePixel = 0,
    Text = "—", TextColor3 = T.TextSub, TextSize = 14,
    Font = Enum.Font.GothamBold, ZIndex = 6, Parent = Header,
})
Corner(7, MinBtn)

-- Close button
local CloseBtn = New("TextButton", {
    Size = UDim2.new(0, 28, 0, 28), Position = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = T.Hover, BorderSizePixel = 0,
    Text = "✕", TextColor3 = T.TextSub, TextSize = 11,
    Font = Enum.Font.GothamBold, ZIndex = 6, Parent = Header,
})
Corner(7, CloseBtn)

HoverEffect(MinBtn, T.Hover, Color3.fromRGB(40, 40, 65))
HoverEffect(CloseBtn, T.Hover, T.Red)
MakeDraggable(Main, Header)

-- ── BODY (clips content when minimized) ─────────────────────
local Body = New("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -20, 1, -78),
    Position = UDim2.new(0, 10, 0, 66),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ClipsDescendants = true, Parent = Main,
})

-- ╔═════════════════════════════════════════════════════════╗
-- ║  1.  STATUS CARD                                        ║
-- ╚═════════════════════════════════════════════════════════╝
local StatusCard = New("Frame", {
    Size = UDim2.new(1, 0, 0, 62),
    BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = Body,
})
Corner(11, StatusCard)
Stroke(T.Border, 1, 0.5, StatusCard)

local StatusDot = New("Frame", {
    Size = UDim2.new(0, 9, 0, 9), Position = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = T.Red, BorderSizePixel = 0, Parent = StatusCard,
})
Corner(99, StatusDot)

local StatusTitle = New("TextLabel", {
    Size = UDim2.new(1, -100, 0, 20), Position = UDim2.new(0, 32, 0, 11),
    BackgroundTransparency = 1, Text = "Auto Collect: Inactive",
    TextColor3 = T.Text, TextSize = 13, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusCard,
})
local StatusSub = New("TextLabel", {
    Size = UDim2.new(1, -100, 0, 14), Position = UDim2.new(0, 32, 0, 34),
    BackgroundTransparency = 1, Text = "0 seeds collected this session",
    TextColor3 = T.TextSub, TextSize = 11, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusCard,
})

-- Toggle pill
local ToggleTrack = New("TextButton", {
    Size = UDim2.new(0, 72, 0, 30), Position = UDim2.new(1, -82, 0.5, -15),
    BackgroundColor3 = T.Red, BorderSizePixel = 0,
    Text = "OFF", TextColor3 = T.White, TextSize = 11,
    Font = Enum.Font.GothamBold, Parent = StatusCard,
})
Corner(8, ToggleTrack)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  2.  SECTION LABEL                                      ║
-- ╚═════════════════════════════════════════════════════════╝
local function SectionLabel(text, ypos)
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14), Position = UDim2.new(0, 2, 0, ypos),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = T.TextMuted, TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = Body,
    })
end

SectionLabel("EVENT SEEDS", 72)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  3.  DROPDOWN MENU                                      ║
-- ╚═════════════════════════════════════════════════════════╝
local ITEM_H    = 46
local DROP_CLOSED = 48
local DROP_OPEN   = DROP_CLOSED + 8 + (#SeedList * ITEM_H) + 8

local DropWrap = New("Frame", {
    Name = "DropWrap",
    Size = UDim2.new(1, 0, 0, DROP_CLOSED),
    Position = UDim2.new(0, 0, 0, 90),
    BackgroundColor3 = T.Card,
    BorderSizePixel = 0, ClipsDescendants = true,
    ZIndex = 20, Parent = Body,
})
Corner(11, DropWrap)
local DropStroke = Stroke(T.Accent, 1, 0.6, DropWrap)

-- Dropdown header row
local DropHeader = New("TextButton", {
    Size = UDim2.new(1, 0, 0, DROP_CLOSED),
    BackgroundTransparency = 1, Text = "",
    ZIndex = 21, Parent = DropWrap,
})

-- Icon inside header
local DropIconBox = New("Frame", {
    Size = UDim2.new(0, 32, 0, 32), Position = UDim2.new(0, 10, 0.5, -16),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 22, Parent = DropHeader,
})
Corner(8, DropIconBox)
Gradient(T.AccentHi, T.AccentLo, 135, DropIconBox)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌱", TextSize = 15, Font = Enum.Font.GothamBold, ZIndex = 23, Parent = DropIconBox,
})

local DropLabel = New("TextLabel", {
    Size = UDim2.new(1, -90, 0, DROP_CLOSED),
    Position = UDim2.new(0, 52, 0, 0),
    BackgroundTransparency = 1, Text = "Select Seeds to Collect",
    TextColor3 = T.Text, TextSize = 13, Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = DropHeader,
})

local DropArrow = New("TextLabel", {
    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -32, 0.5, -12),
    BackgroundTransparency = 1, Text = "▾",
    TextColor3 = T.TextSub, TextSize = 14, Font = Enum.Font.GothamBold,
    ZIndex = 22, Parent = DropHeader,
})

-- Separator
New("Frame", {
    Size = UDim2.new(1, -24, 0, 1), Position = UDim2.new(0, 12, 0, DROP_CLOSED),
    BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 21, Parent = DropWrap,
})

-- ── Seed rows ────────────────────────────────────────────────
local SeedChecks = {}  -- { row, checkBg, checkMark, checked }

for idx, seed in ipairs(SeedList) do
    local rowY = DROP_CLOSED + 8 + (idx - 1) * ITEM_H

    local Row = New("Frame", {
        Size = UDim2.new(1, -20, 0, ITEM_H - 4),
        Position = UDim2.new(0, 10, 0, rowY),
        BackgroundColor3 = T.Hover, BackgroundTransparency = 1,
        BorderSizePixel = 0, ZIndex = 22, Parent = DropWrap,
    })
    Corner(9, Row)

    local RowBtn = New("TextButton", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", ZIndex = 23, Parent = Row,
    })

    -- Color pip
    local Pip = New("Frame", {
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 10, 0.5, -4),
        BackgroundColor3 = seed.color, BorderSizePixel = 0, ZIndex = 23, Parent = Row,
    })
    Corner(99, Pip)

    -- Emoji
    New("TextLabel", {
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, 24, 0, 0),
        BackgroundTransparency = 1, Text = seed.icon, TextSize = 16,
        Font = Enum.Font.GothamBold, ZIndex = 23, Parent = Row,
    })

    -- Name
    New("TextLabel", {
        Size = UDim2.new(1, -90, 1, 0), Position = UDim2.new(0, 58, 0, 0),
        BackgroundTransparency = 1, Text = seed.name,
        TextColor3 = T.Text, TextSize = 13, Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = Row,
    })

    -- Checkbox
    local CheckBg = New("Frame", {
        Size = UDim2.new(0, 22, 0, 22), Position = UDim2.new(1, -32, 0.5, -11),
        BackgroundColor3 = T.Surface, BorderSizePixel = 0, ZIndex = 23, Parent = Row,
    })
    Corner(6, CheckBg)
    Stroke(T.Border, 1.5, 0, CheckBg)

    local CheckMark = New("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", TextColor3 = T.White, TextSize = 13,
        Font = Enum.Font.GothamBold, ZIndex = 24, Parent = CheckBg,
    })

    SeedChecks[seed.name] = { Row = Row, Bg = CheckBg, Mark = CheckMark, Checked = false }

    local function UpdateCheck(on)
        SeedChecks[seed.name].Checked = on
        Config.SelectedSeeds[seed.name] = on
        Tween(CheckBg, { BackgroundColor3 = on and T.Accent or T.Surface }, 0.2)
        CheckMark.Text = on and "✓" or ""
        Tween(Row, { BackgroundTransparency = on and 0 or 1 }, 0.2)
        -- Update label
        local ct, names = 0, {}
        for k, v in pairs(Config.SelectedSeeds) do
            if v then ct += 1; table.insert(names, k) end
        end
        DropLabel.Text = ct == 0 and "Select Seeds to Collect"
            or ct == 1 and names[1]
            or ct .. " Seeds Selected"
    end

    RowBtn.MouseButton1Click:Connect(function()
        UpdateCheck(not SeedChecks[seed.name].Checked)
    end)
    RowBtn.MouseEnter:Connect(function()
        if not SeedChecks[seed.name].Checked then
            Tween(Row, { BackgroundTransparency = 0.5 }, 0.15)
        end
    end)
    RowBtn.MouseLeave:Connect(function()
        if not SeedChecks[seed.name].Checked then
            Tween(Row, { BackgroundTransparency = 1 }, 0.15)
        end
    end)
end

-- Dropdown open / close
DropHeader.MouseButton1Click:Connect(function()
    State.DropOpen = not State.DropOpen
    Tween(DropWrap, { Size = UDim2.new(1, 0, 0, State.DropOpen and DROP_OPEN or DROP_CLOSED) }, 0.3)
    Tween(DropArrow, { Rotation = State.DropOpen and 180 or 0 }, 0.3)
    Tween(DropStroke, { Transparency = State.DropOpen and 0.2 or 0.6 }, 0.2)
end)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  4.  ACTION BUTTONS                                     ║
-- ╚═════════════════════════════════════════════════════════╝
SectionLabel("ACTIONS", 156)

local BtnRow = New("Frame", {
    Size = UDim2.new(1, 0, 0, 42), Position = UDim2.new(0, 0, 0, 174),
    BackgroundTransparency = 1, Parent = Body,
})

-- Collect Once
local CollectBtn = New("TextButton", {
    Size = UDim2.new(0.5, -5, 1, 0),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0,
    Text = "✨  Collect Once", TextColor3 = T.White,
    TextSize = 12, Font = Enum.Font.GothamBold, Parent = BtnRow,
})
Corner(10, CollectBtn)
Gradient(T.AccentHi, T.AccentLo, 90, CollectBtn)

-- Select All / Clear
local SelectAllBtn = New("TextButton", {
    Size = UDim2.new(0.5, -5, 1, 0), Position = UDim2.new(0.5, 5, 0, 0),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
    Text = "☑  Select All", TextColor3 = T.TextSub,
    TextSize = 12, Font = Enum.Font.GothamSemibold, Parent = BtnRow,
})
Corner(10, SelectAllBtn)
Stroke(T.Border, 1, 0, SelectAllBtn)

HoverEffect(CollectBtn, T.Accent, T.AccentHi)
HoverEffect(SelectAllBtn, T.Card, T.Hover)

-- Debug Scan (diagnostic helper — lists matching objects & remotes)
local DebugBtn = New("TextButton", {
    Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, 222),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
    Text = "🔍  Run Debug Scan (Diagnose Event Seeds)", TextColor3 = T.TextSub,
    TextSize = 11, Font = Enum.Font.GothamSemibold, Parent = Body,
})
Corner(9, DebugBtn)
Stroke(T.Border, 1, 0.3, DebugBtn)
HoverEffect(DebugBtn, T.Card, T.Hover)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  5.  ACTIVITY LOG                                       ║
-- ╚═════════════════════════════════════════════════════════╝
SectionLabel("ACTIVITY LOG", 264)

local LogScroll = New("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, 150),
    Position = UDim2.new(0, 0, 0, 282),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = T.Accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ClipsDescendants = true,
    Parent = Body,
})
Corner(11, LogScroll)
Stroke(T.Border, 1, 0.5, LogScroll)

local LogLayout = New("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 1), Parent = LogScroll,
})
New("UIPadding", {
    PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
    PaddingTop = UDim.new(0, 7),   PaddingBottom = UDim.new(0, 7),
    Parent = LogScroll,
})

local function Log(msg, ltype)
    State.LogCount += 1
    local colors = { info = T.TextSub, success = T.Green, warn = T.Yellow, err = T.Red }
    local icons  = { info = "·", success = "✓", warn = "⚠", err = "✗" }
    local ts = os.date("%H:%M:%S")
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, 17), BackgroundTransparency = 1,
        Text = string.format("[%s] %s  %s", ts, icons[ltype] or "·", msg),
        TextColor3 = colors[ltype] or T.TextSub,
        TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = State.LogCount, Parent = LogScroll,
    })
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y + 14)
    LogScroll.CanvasPosition = Vector2.new(0, math.huge)
end

-- ╔═════════════════════════════════════════════════════════╗
-- ║  6.  FOOTER                                             ║
-- ╚═════════════════════════════════════════════════════════╝
local Footer = New("Frame", {
    Size = UDim2.new(1, 0, 0, 28),
    Position = UDim2.new(0, 0, 1, -28),
    BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = Main,
})
Corner(14, Footer)
New("Frame", { Size = UDim2.new(1,0,0,14), BackgroundColor3 = T.Surface,
    BorderSizePixel = 0, Parent = Footer })
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌿 GAG2 Hub  ·  RightCtrl to show/hide",
    TextColor3 = T.TextMuted, TextSize = 10, Font = Enum.Font.Gotham, Parent = Footer,
})

-- ══════════════════════════════════════════════════════════════
--  LOGIC
-- ══════════════════════════════════════════════════════════════

-- ── Seed scanner ─────────────────────────────────────────────
local function HasSelection()
    for _, v in pairs(Config.SelectedSeeds) do if v then return true end end
    return false
end

local function MatchesSeed(name)
    local lower = name:lower()
    for seedName, enabled in pairs(Config.SelectedSeeds) do
        if enabled then
            for _, kw in ipairs((function()
                for _, s in ipairs(SeedList) do
                    if s.name == seedName then return s.keywords end
                end
                return {}
            end)()) do
                if lower:find(kw, 1, true) then return seedName end
            end
        end
    end
    return nil
end

local function MatchesAttributes(obj)
    local ok, attrs = pcall(function() return obj:GetAttributes() end)
    if not ok or not attrs then return nil end
    for _, v in pairs(attrs) do
        if typeof(v) == "string" then
            local m = MatchesSeed(v)
            if m then return m end
        end
    end
    return nil
end

local function ScanWorkspace()
    local found = {}
    local function Recurse(obj)
        local matched = MatchesSeed(obj.Name) or MatchesAttributes(obj)
        if matched and (obj:IsA("BasePart") or obj:IsA("Model")) then
            table.insert(found, { obj = obj, seedName = matched })
        end
        for _, c in ipairs(obj:GetChildren()) do Recurse(c) end
    end
    Recurse(workspace)
    return found
end

-- ── Collect one seed ─────────────────────────────────────────
local function CollectOne(seedObj, seedName)
    local char = LocalPlayer.Character
    if not char then return false end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local pos
    if seedObj:IsA("Model") then
        local ok, p = pcall(function() return seedObj:GetPivot().Position end)
        pos = ok and p or (seedObj:FindFirstChildWhichIsA("BasePart") and seedObj:FindFirstChildWhichIsA("BasePart").Position)
    else
        pos = seedObj.Position
    end
    if not pos then return false end

    -- Teleport
    if Config.TeleportMode then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        task.wait(0.1)
    end

    -- Try proximity prompt
    local function TryProximity(obj)
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ProximityPrompt") then
                pcall(function() fireproximityprompt(d) end); return true
            end
        end
        return false
    end

    -- Try click detector
    local function TryClick(obj)
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then
                pcall(function() fireClickDetector(d) end); return true
            end
        end
        if obj:IsA("ClickDetector") then
            pcall(function() fireClickDetector(obj) end); return true
        end
        return false
    end

    -- Try remote events (broad sweep — exact remote name depends on the game's
    -- own implementation, which we can't see ahead of time)
    local function TryRemote(obj)
        local remoteNames = {
            "Collect","CollectSeed","CollectItem","CollectEvent","CollectEventSeed",
            "PickupItem","Pickup","PickUp","GrabSeed","TakeSeed","GetSeed",
            "EventCollect","ClaimSeed","ClaimItem","Claim","ClaimEvent",
            "Interact","InteractSeed","UseSeed","HarvestSeed","Harvest",
        }
        for _, container in ipairs({ ReplicatedStorage, workspace }) do
            for _, name in ipairs(remoteNames) do
                local r = container:FindFirstChild(name, true)
                if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                    pcall(function()
                        if r:IsA("RemoteEvent") then r:FireServer(obj)
                        else r:InvokeServer(obj) end
                    end)
                    return true
                end
            end
        end
        return false
    end

    if not TryProximity(seedObj) then
        if not TryClick(seedObj) then
            TryRemote(seedObj)
        end
    end

    return true
end

-- ── Auto-claim event popups ────────────────────────────────────
-- Many games show a "Claim" button in a ScreenGui popup when an Event item
-- drops, instead of (or in addition to) a physical pickup in Workspace.
-- This scans PlayerGui for visible claim/collect buttons and clicks them.
local function TryAutoClaimGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return 0 end
    local claimedCount = 0
    for _, d in ipairs(pg:GetDescendants()) do
        if (d:IsA("TextButton") or d:IsA("ImageButton")) and d.Visible then
            local txt = ((d:IsA("TextButton") and d.Text) or "") .. " " .. d.Name
            local lower = txt:lower()
            if lower:find("claim", 1, true) or lower:find("collectevent", 1, true) then
                local ok = pcall(function() firesignal(d.MouseButton1Click) end)
                if ok then claimedCount += 1 end
            end
        end
    end
    return claimedCount
end

-- ── Auto collect thread ───────────────────────────────────────
local autoThread = nil

local function StopAuto()
    Config.AutoCollect = false
    if autoThread then task.cancel(autoThread); autoThread = nil end
    Tween(ToggleTrack, { BackgroundColor3 = T.Red }, 0.25)
    ToggleTrack.Text = "OFF"
    Tween(StatusDot, { BackgroundColor3 = T.Red }, 0.25)
    StatusTitle.Text = "Auto Collect: Inactive"
    StatusTitle.TextColor3 = T.Text
    Log("Auto collect stopped.", "info")
end

local function StartAuto()
    if not HasSelection() then
        Log("No seeds selected! Pick at least one.", "warn"); return
    end
    Config.AutoCollect = true
    Tween(ToggleTrack, { BackgroundColor3 = T.Green }, 0.25)
    ToggleTrack.Text = "ON"
    Tween(StatusDot, { BackgroundColor3 = T.Green }, 0.25)
    StatusTitle.Text = "Auto Collect: Active"
    StatusTitle.TextColor3 = T.Green
    Log("Auto collect started!", "success")

    autoThread = task.spawn(function()
        while Config.AutoCollect do
            if not HasSelection() then
                Log("No seeds selected, pausing...", "warn"); task.wait(2); continue
            end

            -- Some games show a "Claim" popup for event drops instead of (or
            -- alongside) a physical pickup — check for that every cycle.
            local claimed = TryAutoClaimGui()
            if claimed > 0 then
                State.Collected += claimed
                StatusSub.Text = State.Collected .. " seeds collected this session"
                Log(("Auto-claimed %d popup reward(s)"):format(claimed), "success")
            end

            local seeds = ScanWorkspace()
            if #seeds > 0 then
                Log(("Found %d event seed(s)!"):format(#seeds), "success")
                for _, s in ipairs(seeds) do
                    if not Config.AutoCollect then break end
                    local ok, err = pcall(CollectOne, s.obj, s.seedName)
                    if ok then
                        State.Collected += 1
                        StatusSub.Text = State.Collected .. " seeds collected this session"
                        Log(("Collected: %s"):format(s.seedName), "success")
                    else
                        Log(("Error: %s"):format(tostring(err):sub(1,40)), "err")
                    end
                    task.wait(Config.CollectDelay)
                end
            else
                Log("Scanning for event seeds...", "info")
            end
            task.wait(Config.ScanInterval)
        end
    end)
end

-- ── Debug Scan ──────────────────────────────────────────────────
-- Diagnostic helper: lists every Workspace object whose name matches loose
-- "event item" heuristics, plus every RemoteEvent/RemoteFunction found in
-- ReplicatedStorage. Use this to find the real object/remote names if
-- auto-collect isn't picking up an active Event — then update the keyword
-- or remoteNames lists to match.
local function DebugScan()
    Log("── Debug Scan started ──", "info")
    local heuristics = {"seed","egg","event","gift","crate","capsule","pack","bird","gold","rainbow","drop","spawn","claim"}
    local count = 0
    local function Recurse(obj)
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local lname = obj.Name:lower()
            for _, h in ipairs(heuristics) do
                if lname:find(h, 1, true) then
                    count += 1
                    if count <= 25 then
                        Log(("Found: %s [%s]"):format(obj.Name, obj.ClassName), "info")
                    end
                    break
                end
            end
        end
        for _, c in ipairs(obj:GetChildren()) do Recurse(c) end
    end
    Recurse(workspace)
    Log(("Workspace scan done — %d possible match(es)"):format(count), "success")

    Log("── Remotes in ReplicatedStorage ──", "info")
    local rcount = 0
    for _, d in ipairs(ReplicatedStorage:GetDescendants()) do
        if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") then
            rcount += 1
            if rcount <= 20 then
                Log(("%s: %s"):format(d.ClassName, d.Name), "info")
            end
        end
    end
    Log(("Total remotes found: %d"):format(rcount), "success")
    Log("Tip: share these names so the keyword/remote lists can be tuned.", "warn")
end

DebugBtn.MouseButton1Click:Connect(DebugScan)

-- ── Button wiring ─────────────────────────────────────────────
ToggleTrack.MouseButton1Click:Connect(function()
    if Config.AutoCollect then StopAuto() else StartAuto() end
end)

CollectBtn.MouseButton1Click:Connect(function()
    if not HasSelection() then
        Log("No seeds selected! Pick at least one.", "warn"); return
    end
    Log("Running one-time collect...", "info")
    task.spawn(function()
        local claimed = TryAutoClaimGui()
        if claimed > 0 then
            State.Collected += claimed
            StatusSub.Text = State.Collected .. " seeds collected this session"
            Log(("Auto-claimed %d popup reward(s)"):format(claimed), "success")
        end
        local seeds = ScanWorkspace()
        if #seeds == 0 then Log("No event seeds found in Workspace.", "warn"); return end
        Log(("Found %d seed(s). Collecting..."):format(#seeds), "success")
        for _, s in ipairs(seeds) do
            pcall(CollectOne, s.obj, s.seedName)
            State.Collected += 1
            StatusSub.Text = State.Collected .. " seeds collected this session"
            Log(("Collected: %s"):format(s.seedName), "success")
            task.wait(Config.CollectDelay)
        end
    end)
end)

SelectAllBtn.MouseButton1Click:Connect(function()
    State.AllSelected = not State.AllSelected
    for _, seed in ipairs(SeedList) do
        local sc = SeedChecks[seed.name]
        sc.Checked = State.AllSelected
        Config.SelectedSeeds[seed.name] = State.AllSelected
        Tween(sc.Bg, { BackgroundColor3 = State.AllSelected and T.Accent or T.Surface }, 0.2)
        sc.Mark.Text = State.AllSelected and "✓" or ""
        Tween(sc.Row, { BackgroundTransparency = State.AllSelected and 0 or 1 }, 0.2)
    end
    DropLabel.Text = State.AllSelected and "All Seeds Selected" or "Select Seeds to Collect"
    SelectAllBtn.Text = State.AllSelected and "✕  Clear All" or "☑  Select All"
end)

CloseBtn.MouseButton1Click:Connect(function()
    if Config.AutoCollect then StopAuto() end
    HideChatHead()
    Tween(Main, { BackgroundTransparency = 1, Size = UDim2.new(0, 400, 0, 0) }, 0.3)
    task.wait(0.35); ScreenGui:Destroy()
end)

-- MinBtn → collapse to chat head
MinBtn.MouseButton1Click:Connect(function()
    CloseMain()
end)

-- ── Keybind: RightCtrl → toggle between full window & chat head ──
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then
            CloseMain()
        elseif ChatHead.Visible then
            OpenMain()
        else
            OpenMain()
        end
    end
end)

-- ── Startup animation ─────────────────────────────────────────
Main.Size = UDim2.new(0, 400, 0, 0)
Main.BackgroundTransparency = 1
Tween(Main, { Size = UDim2.new(0, 400, 0, 560), BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

Log("GAG2 Hub loaded successfully!", "success")
Log("Select seeds then toggle ON to start.", "info")

print("[ GAG2 Hub ] Loaded  |  RightCtrl = toggle visibility")