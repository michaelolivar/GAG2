-- ╔═══════════════════════════════════════════════════════════╗
-- ║         GAG2 Hub  |  Grow a Garden 2 Script              ║
-- ║         Auto Event Seed Collector  |  v1.1               ║
-- ║         Fixed Auto-Claim + Responsive UI                 ║
-- ╚═══════════════════════════════════════════════════════════╝

-- ╔═ SERVICES ═══════════════════════════════════════════════╗
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui          = game:GetService("CoreGui")
local Debris           = game:GetService("Debris")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ CONFIG ═════════════════════════════════════════════════╗
local Config = {
    AutoCollect   = false,
    CollectDelay  = 0.3,
    ScanInterval  = 1.0,
    TeleportMode  = true,
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
    { name = "Gold Seed",    icon = "⭐", color = Color3.fromRGB(255, 200, 0),   keywords = {"goldseed","gold seed","golden seed","gold"} },
    { name = "Rainbow Seed", icon = "🌈", color = Color3.fromRGB(180, 100, 255), keywords = {"rainbowseed","rainbow seed","rainbow","rainbow_seed"} },
    { name = "Bird",         icon = "🐦", color = Color3.fromRGB(80,  160, 255), keywords = {"bird","birdseed","bird seed","birb"} },
    { name = "Seed Pack",    icon = "📦", color = Color3.fromRGB(50,  210, 120), keywords = {"seedpack","seed pack","pack","seed_pack"} },
}

-- Additional dynamic seed names to watch for (game updates)
local DynamicSeedPatterns = {
    "EventSeed", "Event_Seed", "event_seed", "MysterySeed", 
    "SpecialSeed", "LimitedSeed", "HolidaySeed", "Token",
    "Crystal", "Gem", "Orb", "Shard", "Essence"
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

-- Responsive scaling: base width 400, scale based on screen size
local ViewportSize = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
local ScaleFactor = math.min(1, math.max(0.65, ViewportSize.X / 430))
local UI_WIDTH = math.floor(400 * ScaleFactor)
local UI_HEIGHT = math.floor(560 * ScaleFactor)
local UI_PAD = math.floor(10 * ScaleFactor)
local FONT_SIZE = math.max(9, math.floor(12 * ScaleFactor))
local FONT_SIZE_SM = math.max(8, math.floor(10 * ScaleFactor))
local FONT_SIZE_XS = math.max(7, math.floor(9 * ScaleFactor))

local DRAG_THRESHOLD = 6
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
            frame.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + d.X,
                frameStart.Y.Scale, frameStart.Y.Offset + d.Y
            )
        end
    end)
end

local function HoverEffect(btn, normal, hover)
    btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = hover }, 0.15) end)
    btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = normal }, 0.15) end)
end

-- Better seed detection: check ALL relevant containers
local function FindRelevantContainers()
    local containers = {}
    -- Common places event seeds spawn
    local pathsToCheck = {
        workspace, 
        workspace:FindFirstChild("Map"),
        workspace:FindFirstChild("World"),
        workspace:FindFirstChild("Terrain"),
        workspace:FindFirstChild("Events"),
        workspace:FindFirstChild("Drops"),
        workspace:FindFirstChild("Collectibles"),
        workspace:FindFirstChild("Items"),
    }
    for _, container in ipairs(pathsToCheck) do
        if container then table.insert(containers, container) end
    end
    return containers
end
-- ╚══════════════════════════════════════════════════════════╝

-- ╔═ DESTROY OLD INSTANCE ═══════════════════════════════════╗
if CoreGui:FindFirstChild("GAG2Hub") then
    CoreGui:FindFirstChild("GAG2Hub"):Destroy()
end
-- ╚══════════════════════════════════════════════════════════╝

-- ╔══════════════════════════════════════════════════════════╗
-- ║                   RESPONSIVE MAIN GUI                    ║
-- ╚══════════════════════════════════════════════════════════╝
local ScreenGui = New("ScreenGui", {
    Name = "GAG2Hub", ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    ResetOnSpawn = false, IgnoreGuiInset = true,
    ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
    Parent = CoreGui,
})

-- ── Main Frame ──────────────────────────────────────────────
local Main = New("Frame", {
    Name = "Main",
    Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT),
    Position = UDim2.new(0.5, -UI_WIDTH/2, 0.5, -UI_HEIGHT/2),
    BackgroundColor3 = T.BG,
    BorderSizePixel = 0,
    ClipsDescendants = false,
    Parent = ScreenGui,
})
Corner(14, Main)
Stroke(T.Border, 1, 0.2, Main)

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
local CH_SIZE = math.max(42, math.floor(58 * ScaleFactor))

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
    TextSize = math.floor(24 * ScaleFactor),
    Font = Enum.Font.GothamBold,
    ZIndex = 201,
    Parent = ChatHead,
})

-- Status dot
local CHDot = New("Frame", {
    Name = "CHDot",
    Size = UDim2.new(0, math.max(10, math.floor(14 * ScaleFactor)), 0, math.max(10, math.floor(14 * ScaleFactor))),
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

-- ── Chat head functions ────────────────────────────────────
local function ShowChatHead()
    ChatHead.Visible = true
    ChatHead.Size = UDim2.new(0, 0, 0, 0)
    ChatHead.BackgroundTransparency = 1
    Tween(ChatHead, { Size = UDim2.new(0, CH_SIZE + 8, 0, CH_SIZE + 8), BackgroundTransparency = 0 }, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    task.wait(0.2)
    Tween(ChatHead, { Size = UDim2.new(0, CH_SIZE, 0, CH_SIZE) }, 0.15, Enum.EasingStyle.Quart)
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
    Main.Size = UDim2.new(0, UI_WIDTH, 0, 0)
    Main.BackgroundTransparency = 1
    Tween(Main, { Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT), BackgroundTransparency = 0 }, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local function CloseMain()
    Tween(Main, { Size = UDim2.new(0, UI_WIDTH, 0, 0), BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quart)
    task.delay(0.26, function()
        Main.Visible = false
        ShowChatHead()
    end)
end

MakeDraggable(ChatHead, CHBtn, OpenMain)

-- ── HEADER ──────────────────────────────────────────────────
local HEADER_H = math.max(42, math.floor(58 * ScaleFactor))
local Header = New("Frame", {
    Size = UDim2.new(1, 0, 0, HEADER_H),
    BackgroundColor3 = T.Surface,
    BorderSizePixel = 0,
    ZIndex = 5,
    Parent = Main,
})
Corner(14, Header)
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
local LOGO_SIZE = math.max(28, math.floor(38 * ScaleFactor))
local LogoBox = New("Frame", {
    Size = UDim2.new(0, LOGO_SIZE, 0, LOGO_SIZE),
    Position = UDim2.new(0, UI_PAD, 0.5, -LOGO_SIZE/2),
    BackgroundColor3 = T.Accent,
    BorderSizePixel = 0, ZIndex = 6, Parent = Header,
})
Corner(9, LogoBox)
Gradient(T.AccentHi, T.AccentLo, 135, LogoBox)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌱", TextSize = math.floor(18 * ScaleFactor), Font = Enum.Font.GothamBold, ZIndex = 7, Parent = LogoBox,
})

-- Title + subtitle
local TITLE_OFFSET = LOGO_SIZE + UI_PAD + 8
New("TextLabel", {
    Size = UDim2.new(0, 200, 0, math.floor(20 * ScaleFactor)), Position = UDim2.new(0, TITLE_OFFSET, 0, UI_PAD - 2),
    BackgroundTransparency = 1, Text = "Grow a Garden 2",
    TextColor3 = T.Text, TextSize = FONT_SIZE, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = Header,
})
New("TextLabel", {
    Size = UDim2.new(0, 200, 0, math.floor(15 * ScaleFactor)), Position = UDim2.new(0, TITLE_OFFSET, 0, UI_PAD + math.floor(18 * ScaleFactor)),
    BackgroundTransparency = 1, Text = "Event Seed Collector",
    TextColor3 = T.TextSub, TextSize = FONT_SIZE_SM, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6, Parent = Header,
})

-- Version pill
local VerPill = New("Frame", {
    Size = UDim2.new(0, math.max(34, math.floor(44 * ScaleFactor)), 0, math.max(14, math.floor(18 * ScaleFactor))),
    Position = UDim2.new(1, -UI_PAD - 80, 0.5, -math.max(7, math.floor(9 * ScaleFactor))),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 6, Parent = Header,
})
Corner(20, VerPill)
Gradient(T.AccentHi, T.AccentLo, 90, VerPill)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "v1.1", TextColor3 = T.White, TextSize = FONT_SIZE_XS,
    Font = Enum.Font.GothamBold, ZIndex = 7, Parent = VerPill,
})

-- Minimize + Close buttons
local BTN_W = math.max(22, math.floor(28 * ScaleFactor))
local MinBtn = New("TextButton", {
    Size = UDim2.new(0, BTN_W, 0, BTN_W), Position = UDim2.new(1, -UI_PAD - BTN_W - 5 - BTN_W, 0.5, -BTN_W/2),
    BackgroundColor3 = T.Hover, BorderSizePixel = 0,
    Text = "—", TextColor3 = T.TextSub, TextSize = math.floor(14 * ScaleFactor),
    Font = Enum.Font.GothamBold, ZIndex = 6, Parent = Header,
})
Corner(7, MinBtn)

local CloseBtn = New("TextButton", {
    Size = UDim2.new(0, BTN_W, 0, BTN_W), Position = UDim2.new(1, -UI_PAD - BTN_W, 0.5, -BTN_W/2),
    BackgroundColor3 = T.Hover, BorderSizePixel = 0,
    Text = "✕", TextColor3 = T.TextSub, TextSize = math.floor(11 * ScaleFactor),
    Font = Enum.Font.GothamBold, ZIndex = 6, Parent = Header,
})
Corner(7, CloseBtn)

HoverEffect(MinBtn, T.Hover, Color3.fromRGB(40, 40, 65))
HoverEffect(CloseBtn, T.Hover, T.Red)
MakeDraggable(Main, Header)

-- ── BODY ────────────────────────────────────────────────────
local BODY_TOP = HEADER_H + UI_PAD
local BODY_H = UI_HEIGHT - BODY_TOP - UI_PAD - math.max(22, math.floor(28 * ScaleFactor))
local Body = New("Frame", {
    Name = "Body",
    Size = UDim2.new(1, -UI_PAD*2, 1, -(HEADER_H + math.max(22, math.floor(28 * ScaleFactor)) + UI_PAD*2)),
    Position = UDim2.new(0, UI_PAD, 0, HEADER_H + UI_PAD),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ClipsDescendants = true, Parent = Main,
})

-- ╔═════════════════════════════════════════════════════════╗
-- ║  1.  STATUS CARD                                        ║
-- ╚═════════════════════════════════════════════════════════╝
local STATUS_H = math.max(48, math.floor(62 * ScaleFactor))
local StatusCard = New("Frame", {
    Size = UDim2.new(1, 0, 0, STATUS_H),
    BackgroundColor3 = T.Card, BorderSizePixel = 0, Parent = Body,
})
Corner(11, StatusCard)
Stroke(T.Border, 1, 0.5, StatusCard)

local DOT_SIZE = math.max(7, math.floor(9 * ScaleFactor))
local StatusDot = New("Frame", {
    Size = UDim2.new(0, DOT_SIZE, 0, DOT_SIZE), Position = UDim2.new(0, UI_PAD, 0.5, -DOT_SIZE/2),
    BackgroundColor3 = T.Red, BorderSizePixel = 0, Parent = StatusCard,
})
Corner(99, StatusDot)

local STATUS_TITLE_SIZE = math.floor(20 * ScaleFactor)
local STATUS_SUB_SIZE = math.floor(14 * ScaleFactor)
local StatusTitle = New("TextLabel", {
    Size = UDim2.new(1, -UI_PAD - 82, 0, STATUS_TITLE_SIZE), Position = UDim2.new(0, UI_PAD + DOT_SIZE + 6, 0, UI_PAD - 2),
    BackgroundTransparency = 1, Text = "Auto Collect: Inactive",
    TextColor3 = T.Text, TextSize = FONT_SIZE, Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusCard,
})
local StatusSub = New("TextLabel", {
    Size = UDim2.new(1, -UI_PAD - 82, 0, STATUS_SUB_SIZE), Position = UDim2.new(0, UI_PAD + DOT_SIZE + 6, 0, UI_PAD + STATUS_TITLE_SIZE - 2),
    BackgroundTransparency = 1, Text = "0 seeds collected this session",
    TextColor3 = T.TextSub, TextSize = FONT_SIZE_SM, Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left, Parent = StatusCard,
})

-- Toggle pill
local TOGGLE_W = math.max(56, math.floor(72 * ScaleFactor))
local TOGGLE_H = math.max(24, math.floor(30 * ScaleFactor))
local ToggleTrack = New("TextButton", {
    Size = UDim2.new(0, TOGGLE_W, 0, TOGGLE_H), Position = UDim2.new(1, -UI_PAD - TOGGLE_W, 0.5, -TOGGLE_H/2),
    BackgroundColor3 = T.Red, BorderSizePixel = 0,
    Text = "OFF", TextColor3 = T.White, TextSize = FONT_SIZE_SM,
    Font = Enum.Font.GothamBold, Parent = StatusCard,
})
Corner(8, ToggleTrack)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  2.  SECTION LABEL                                      ║
-- ╚═════════════════════════════════════════════════════════╝
local function SectionLabel(text, ypos, bodyRef)
    local parent = bodyRef or Body
    return New("TextLabel", {
        Size = UDim2.new(1, 0, 0, math.floor(14 * ScaleFactor)),
        Position = UDim2.new(0, 2, 0, ypos),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = T.TextMuted, TextSize = FONT_SIZE_XS,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
    })
end

local SECTION_1_Y = STATUS_H + UI_PAD
SectionLabel("EVENT SEEDS", SECTION_1_Y)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  3.  DROPDOWN MENU                                      ║
-- ╚═════════════════════════════════════════════════════════╝
local ITEM_H = math.max(36, math.floor(46 * ScaleFactor))
local DROP_CLOSED = math.max(38, math.floor(48 * ScaleFactor))
local DROP_OPEN = DROP_CLOSED + 8 + (#SeedList * ITEM_H) + 8

-- Clamp DROP_OPEN so it doesn't overflow body
local MAX_DROP = Body.AbsoluteSize.Y - SECTION_1_Y - ITEM_H - 48
if MAX_DROP > 0 then
    DROP_OPEN = math.min(DROP_OPEN, SECTION_1_Y + MAX_DROP)
end

local DropWrap = New("Frame", {
    Name = "DropWrap",
    Size = UDim2.new(1, 0, 0, DROP_CLOSED),
    Position = UDim2.new(0, 0, 0, SECTION_1_Y + math.floor(18 * ScaleFactor)),
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

-- Icon
local DROP_ICON = math.max(26, math.floor(32 * ScaleFactor))
local DropIconBox = New("Frame", {
    Size = UDim2.new(0, DROP_ICON, 0, DROP_ICON), Position = UDim2.new(0, UI_PAD, 0.5, -DROP_ICON/2),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0, ZIndex = 22, Parent = DropHeader,
})
Corner(8, DropIconBox)
Gradient(T.AccentHi, T.AccentLo, 135, DropIconBox)
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌱", TextSize = math.floor(15 * ScaleFactor), Font = Enum.Font.GothamBold, ZIndex = 23, Parent = DropIconBox,
})

local DropLabel = New("TextLabel", {
    Size = UDim2.new(1, -UI_PAD - DROP_ICON - 50, 0, DROP_CLOSED),
    Position = UDim2.new(0, UI_PAD + DROP_ICON + 8, 0, 0),
    BackgroundTransparency = 1, Text = "Select Seeds to Collect",
    TextColor3 = T.Text, TextSize = FONT_SIZE, Font = Enum.Font.GothamSemibold,
    TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 22, Parent = DropHeader,
})

local DropArrow = New("TextLabel", {
    Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -UI_PAD - 5, 0.5, -12),
    BackgroundTransparency = 1, Text = "▾",
    TextColor3 = T.TextSub, TextSize = math.floor(14 * ScaleFactor), Font = Enum.Font.GothamBold,
    ZIndex = 22, Parent = DropHeader,
})

-- Separator
New("Frame", {
    Size = UDim2.new(1, -UI_PAD*2, 0, 1), Position = UDim2.new(0, UI_PAD, 0, DROP_CLOSED),
    BackgroundColor3 = T.Border, BorderSizePixel = 0, ZIndex = 21, Parent = DropWrap,
})

-- ── Seed rows ────────────────────────────────────────────────
local SeedChecks = {}

for idx, seed in ipairs(SeedList) do
    local rowY = DROP_CLOSED + 8 + (idx - 1) * ITEM_H

    local Row = New("Frame", {
        Size = UDim2.new(1, -UI_PAD*2, 0, ITEM_H - 4),
        Position = UDim2.new(0, UI_PAD, 0, rowY),
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
        Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, UI_PAD, 0.5, -4),
        BackgroundColor3 = seed.color, BorderSizePixel = 0, ZIndex = 23, Parent = Row,
    })
    Corner(99, Pip)

    -- Emoji
    New("TextLabel", {
        Size = UDim2.new(0, 28, 1, 0), Position = UDim2.new(0, UI_PAD + 12, 0, 0),
        BackgroundTransparency = 1, Text = seed.icon, TextSize = math.floor(16 * ScaleFactor),
        Font = Enum.Font.GothamBold, ZIndex = 23, Parent = Row,
    })

    -- Name
    New("TextLabel", {
        Size = UDim2.new(1, -UI_PAD - 70, 1, 0), Position = UDim2.new(0, UI_PAD + 44, 0, 0),
        BackgroundTransparency = 1, Text = seed.name,
        TextColor3 = T.Text, TextSize = FONT_SIZE, Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 23, Parent = Row,
    })

    -- Checkbox
    local CHECK_SIZE = math.max(18, math.floor(22 * ScaleFactor))
    local CheckBg = New("Frame", {
        Size = UDim2.new(0, CHECK_SIZE, 0, CHECK_SIZE), Position = UDim2.new(1, -UI_PAD - CHECK_SIZE, 0.5, -CHECK_SIZE/2),
        BackgroundColor3 = T.Surface, BorderSizePixel = 0, ZIndex = 23, Parent = Row,
    })
    Corner(6, CheckBg)
    Stroke(T.Border, 1.5, 0, CheckBg)

    local CheckMark = New("TextLabel", {
        Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        Text = "", TextColor3 = T.White, TextSize = math.floor(13 * ScaleFactor),
        Font = Enum.Font.GothamBold, ZIndex = 24, Parent = CheckBg,
    })

    SeedChecks[seed.name] = { Row = Row, Bg = CheckBg, Mark = CheckMark, Checked = false }

    local function UpdateCheck(on)
        SeedChecks[seed.name].Checked = on
        Config.SelectedSeeds[seed.name] = on
        Tween(CheckBg, { BackgroundColor3 = on and T.Accent or T.Surface }, 0.2)
        CheckMark.Text = on and "✓" or ""
        Tween(Row, { BackgroundTransparency = on and 0 or 1 }, 0.2)
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

-- Dropdown toggle
DropHeader.MouseButton1Click:Connect(function()
    State.DropOpen = not State.DropOpen
    local targetH = State.DropOpen and math.min(DROP_OPEN, Body.AbsoluteSize.Y - SECTION_1_Y - 24) or DROP_CLOSED
    Tween(DropWrap, { Size = UDim2.new(1, 0, 0, targetH) }, 0.3)
    Tween(DropArrow, { Rotation = State.DropOpen and 180 or 0 }, 0.3)
    Tween(DropStroke, { Transparency = State.DropOpen and 0.2 or 0.6 }, 0.2)
end)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  4.  ACTION BUTTONS                                     ║
-- ╚═════════════════════════════════════════════════════════╝
local BTN_Y = SECTION_1_Y + math.floor(18 * ScaleFactor) + DROP_CLOSED + UI_PAD + 2
local BTN_ROW_H = math.max(34, math.floor(42 * ScaleFactor))

local BtnRow = New("Frame", {
    Size = UDim2.new(1, 0, 0, BTN_ROW_H), Position = UDim2.new(0, 0, 0, BTN_Y),
    BackgroundTransparency = 1, Parent = Body,
})

local CollectBtn = New("TextButton", {
    Size = UDim2.new(0.5, -UI_PAD/2, 1, 0),
    BackgroundColor3 = T.Accent, BorderSizePixel = 0,
    Text = "✨  Collect Once", TextColor3 = T.White,
    TextSize = FONT_SIZE_SM, Font = Enum.Font.GothamBold, Parent = BtnRow,
})
Corner(10, CollectBtn)
Gradient(T.AccentHi, T.AccentLo, 90, CollectBtn)

local SelectAllBtn = New("TextButton", {
    Size = UDim2.new(0.5, -UI_PAD/2, 1, 0), Position = UDim2.new(0.5, UI_PAD/2, 0, 0),
    BackgroundColor3 = T.Card, BorderSizePixel = 0,
    Text = "☑  Select All", TextColor3 = T.TextSub,
    TextSize = FONT_SIZE_SM, Font = Enum.Font.GothamSemibold, Parent = BtnRow,
})
Corner(10, SelectAllBtn)
Stroke(T.Border, 1, 0, SelectAllBtn)

HoverEffect(CollectBtn, T.Accent, T.AccentHi)
HoverEffect(SelectAllBtn, T.Card, T.Hover)

-- ╔═════════════════════════════════════════════════════════╗
-- ║  5.  ACTIVITY LOG                                       ║
-- ╚═════════════════════════════════════════════════════════╝
local LOG_Y = BTN_Y + BTN_ROW_H + UI_PAD
local LOG_H = Body.AbsoluteSize.Y - LOG_Y - 2

local LogScroll = New("ScrollingFrame", {
    Size = UDim2.new(1, 0, 0, math.max(40, LOG_H)),
    Position = UDim2.new(0, 0, 0, LOG_Y),
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
    PaddingLeft = UDim.new(0, UI_PAD), PaddingRight = UDim.new(0, UI_PAD),
    PaddingTop = UDim.new(0, 7),   PaddingBottom = UDim.new(0, 7),
    Parent = LogScroll,
})

local function Log(msg, ltype)
    State.LogCount += 1
    local colors = { info = T.TextSub, success = T.Green, warn = T.Yellow, err = T.Red }
    local icons  = { info = "·", success = "✓", warn = "⚠", err = "✗" }
    local ts = os.date("%H:%M:%S")
    New("TextLabel", {
        Size = UDim2.new(1, 0, 0, math.floor(17 * ScaleFactor)), BackgroundTransparency = 1,
        Text = string.format("[%s] %s  %s", ts, icons[ltype] or "·", msg),
        TextColor3 = colors[ltype] or T.TextSub,
        TextSize = FONT_SIZE_XS, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = State.LogCount, Parent = LogScroll,
    })
    LogScroll.CanvasSize = UDim2.new(0, 0, 0, LogLayout.AbsoluteContentSize.Y + 14)
    LogScroll.CanvasPosition = Vector2.new(0, math.huge)
end

-- ╔═════════════════════════════════════════════════════════╗
-- ║  6.  FOOTER                                             ║
-- ╚═════════════════════════════════════════════════════════╝
local FOOTER_H = math.max(22, math.floor(28 * ScaleFactor))
local Footer = New("Frame", {
    Size = UDim2.new(1, 0, 0, FOOTER_H),
    Position = UDim2.new(0, 0, 1, -FOOTER_H),
    BackgroundColor3 = T.Surface, BorderSizePixel = 0, Parent = Main,
})
Corner(14, Footer)
New("Frame", { Size = UDim2.new(1,0,0,14), BackgroundColor3 = T.Surface,
    BorderSizePixel = 0, Parent = Footer })
New("TextLabel", {
    Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
    Text = "🌿 GAG2 Hub  ·  RightCtrl to show/hide",
    TextColor3 = T.TextMuted, TextSize = FONT_SIZE_XS, Font = Enum.Font.Gotham, Parent = Footer,
})

-- ══════════════════════════════════════════════════════════════
--  FIXED LOGIC — Auto Claim the Event Seeds properly
-- ══════════════════════════════════════════════════════════════

-- ── Better seed matching ─────────────────────────────────────
local function MatchesSeed(name)
    local lower = name:lower()
    for seedName, enabled in pairs(Config.SelectedSeeds) do
        if enabled then
            -- Find keywords for this seed
            for _, s in ipairs(SeedList) do
                if s.name == seedName then
                    for _, kw in ipairs(s.keywords) do
                        if lower:find(kw, 1, true) then
                            return seedName
                        end
                    end
                    -- Also check dynamic patterns
                    for _, pattern in ipairs(DynamicSeedPatterns) do
                        if lower:find(pattern:lower(), 1, true) then
                            return seedName
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- ── FIXED: Deep scan workspace for seeds ────────────────────
local function ScanForSeeds()
    local found = {}
    local containers = FindRelevantContainers()
    
    for _, container in ipairs(containers) do
        local function Recurse(obj, depth)
            if depth > 50 then return end -- safety limiter
            
            -- Check by name
            local matched = MatchesSeed(obj.Name)
            if matched then
                -- Only collect collectable objects
                if obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Tool") then
                    -- Skip if it's a character or non-collectible
                    if not obj:IsA("Model") or not obj:FindFirstChild("Humanoid") then
                        table.insert(found, { obj = obj, seedName = matched })
                    end
                end
            end
            
            -- Also check for objects tagged with CollectionService tags
            local tags = CollectionService:GetTags(obj)
            for _, tag in ipairs(tags) do
                if tag:lower():find("seed", 1, true) or tag:lower():find("event", 1, true) or tag:lower():find("collect", 1, true) then
                    if obj:IsA("BasePart") or obj:IsA("Model") then
                        table.insert(found, { obj = obj, seedName = "Tagged: " .. tag })
                    end
                end
            end
            
            -- Check for proximity prompts / click detectors as indicators
            if obj:IsA("ProximityPrompt") or obj:IsA("ClickDetector") then
                local parent = obj.Parent
                if parent and (parent:IsA("BasePart") or parent:IsA("Model")) then
                    -- Check if we already found this parent
                    local alreadyFound = false
                    for _, f in ipairs(found) do
                        if f.obj == parent then alreadyFound = true; break end
                    end
                    if not alreadyFound then
                        local inferredName = MatchesSeed(parent.Name) or "Unknown Seed"
                        if inferredName ~= "Unknown Seed" then
                            table.insert(found, { obj = parent, seedName = inferredName })
                        end
                    end
                end
            end
            
            for _, c in ipairs(obj:GetChildren()) do
                Recurse(c, depth + 1)
            end
        end
        Recurse(container, 0)
    end
    
    -- Deduplicate by object
    local seen = {}
    local deduped = {}
    for _, entry in ipairs(found) do
        if not seen[entry.obj] then
            seen[entry.obj] = true
            table.insert(deduped, entry)
        end
    end
    
    return deduped
end

-- ── FIXED: Robust collection method ──────────────────────────
local function CollectSeed(seedObj, seedName)
    local char = LocalPlayer.Character
    if not char then 
        -- Try to respawn character if missing
        LocalPlayer.CharacterAdded:Wait()
        char = LocalPlayer.Character
        if not char then return false end
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then
        task.wait(0.5)
        root = char:FindFirstChild("HumanoidRootPart")
        if not root then return false end
    end

    -- Get position
    local pos
    if seedObj:IsA("Model") then
        local success, pivot = pcall(function() return seedObj:GetPivot().Position end)
        if success then
            pos = pivot
        else
            local part = seedObj:FindFirstChildWhichIsA("BasePart")
            if part then pos = part.Position end
        end
    elseif seedObj:IsA("BasePart") then
        pos = seedObj.Position
    end
    
    if not pos then 
        Log(string.format("Cannot locate position of %s", seedName), "warn")
        return false 
    end

    -- Teleport directly on top of the seed
    if Config.TeleportMode then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
        task.wait(0.15)
    end

    -- METHOD 1: Fire all proximity prompts
    local function TryAllProximityPrompts(obj)
        local success = false
        for _, prompt in ipairs(obj:GetDescendants()) do
            if prompt:IsA("ProximityPrompt") then
                pcall(function()
                    fireproximityprompt(prompt, 1)
                end)
                success = true
                task.wait(0.05)
            end
        end
        -- Also check parent and siblings
        if obj.Parent then
            for _, prompt in ipairs(obj.Parent:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") and not success then
                    pcall(function()
                        fireproximityprompt(prompt, 1)
                    end)
                    success = true
                end
            end
        end
        return success
    end

    -- METHOD 2: Fire all click detectors
    local function TryAllClickDetectors(obj)
        local success = false
        for _, detector in ipairs(obj:GetDescendants()) do
            if detector:IsA("ClickDetector") then
                pcall(function() fireClickDetector(detector) end)
                success = true
                task.wait(0.05)
            end
        end
        if obj:IsA("ClickDetector") then
            pcall(function() fireClickDetector(obj) end)
            success = true
        end
        -- Check parent
        if obj.Parent then
            for _, detector in ipairs(obj.Parent:GetDescendants()) do
                if detector:IsA("ClickDetector") and not success then
                    pcall(function() fireClickDetector(detector) end)
                    success = true
                end
            end
        end
        return success
    end

    -- METHOD 3: Try ALL possible remote events
    local function TryAllRemotes(obj)
        local remoteNames = {
            "Collect", "CollectSeed", "PickupItem", "Pickup", "GrabSeed", 
            "TakeSeed", "EventCollect", "Claim", "ClaimSeed", "GetSeed",
            "OnSeedCollected", "SeedCollected", "CollectEvent", "GetEvent",
            "Grab", "Pick", "CollectItem", "EventPickup", "TakeItem",
            "InventoryAdd", "AddToInventory", "ClaimEvent"
        }
        local rs = ReplicatedStorage
        local success = false
        
        -- Check various locations
        local searchLocations = {
            rs,
            rs:FindFirstChild("Remotes"),
            rs:FindFirstChild("Remote"),
            rs:FindFirstChild("Events"),
            rs:FindFirstChild("Functions"),
            script,
            script.Parent,
        }
        
        for _, loc in ipairs(searchLocations) do
            if loc then
                for _, name in ipairs(remoteNames) do
                    local r = loc:FindFirstChild(name, true)
                    if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
                        local ok = pcall(function()
                            if r:IsA("RemoteEvent") then
                                r:FireServer(obj, obj.Position or pos)
                            else
                                r:InvokeServer(obj, obj.Position or pos)
                            end
                        end)
                        if ok then success = true end
                        task.wait(0.03)
                    end
                end
            end
        end
        
        return success
    end

    -- METHOD 4: Try to collect via touch/character collision
    local function TryTouchCollection(part)
        if part:IsA("BasePart") and root then
            -- Move character right onto the part
            root.CFrame = CFrame.new(part.Position)
            task.wait(0.1)
            -- Try to simulate touch
            pcall(function()
                if root:FindFirstChild("TouchInterest") then
                    -- Already has touch, just stay close
                end
                -- Fire touched event
                part.Touched:Fire(root)
            end)
        end
    end

    -- METHOD 5: Try finding remote by scanning for "collect" in all RemoteEvents
    local function TryGenericRemote(obj)
        local rs = ReplicatedStorage
        local success = false
        for _, child in ipairs(rs:GetDescendants()) do
            if (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) and
               (child.Name:lower():find("collect") or child.Name:lower():find("seed") or 
                child.Name:lower():find("pick") or child.Name:lower():find("grab") or
                child.Name:lower():find("claim") or child.Name:lower():find("event")) then
                local ok = pcall(function()
                    if child:IsA("RemoteEvent") then
                        child:FireServer(obj)
                    else
                        child:InvokeServer(obj)
                    end
                end)
                if ok then success = true end
                task.wait(0.03)
            end
        end
        return success
    end

    -- Execute all methods
    local collected = TryAllProximityPrompts(seedObj)
    if not collected then
        task.wait(0.1)
        collected = TryAllClickDetectors(seedObj)
    end
    if not collected then
        task.wait(0.1)
        collected = TryAllRemotes(seedObj)
    end
    if not collected then
        task.wait(0.1)
        collected = TryGenericRemote(seedObj)
    end
    if not collected and seedObj:IsA("BasePart") then
        TryTouchCollection(seedObj)
        task.wait(0.5)
        -- Try again with prompts after touching
        collected = TryAllProximityPrompts(seedObj)
    end

    -- Wait a moment then check if object still exists (if destroyed, it was collected)
    task.wait(0.3)
    local stillExists = seedObj and seedObj.Parent ~= nil
    
    if not stillExists then
        return true
    end
    
    return collected or false
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
    CHDot.BackgroundColor3 = T.Red
end

local function StartAuto()
    if not HasSelection() then
        Log("No seeds selected! Pick at least one.", "warn")
        return
    end
    Config.AutoCollect = true
    Tween(ToggleTrack, { BackgroundColor3 = T.Green }, 0.25)
    ToggleTrack.Text = "ON"
    Tween(StatusDot, { BackgroundColor3 = T.Green }, 0.25)
    StatusTitle.Text = "Auto Collect: Active"
    StatusTitle.TextColor3 = T.Green
    Log("Auto collect started!", "success")
    CHDot.BackgroundColor3 = T.Green

    autoThread = task.spawn(function()
        while Config.AutoCollect do
            if not HasSelection() then
                Log("No seeds selected, pausing...", "warn")
                task.wait(2)
                continue
            end

            local success, seeds = pcall(ScanForSeeds)
            if success and #seeds > 0 then
                Log(string.format("Found %d event seed(s)!", #seeds), "success")
                for _, entry in ipairs(seeds) do
                    if not Config.AutoCollect then break end
                    
                    local ok, err = pcall(CollectSeed, entry.obj, entry.seedName)
                    if ok then
                        State.Collected += 1
                        StatusSub.Text = State.Collected .. " seeds collected this session"
                        Log(string.format("Collected: %s", entry.seedName), "success")
                    else
                        Log(string.format("Failed: %s - %s", entry.seedName, tostring(err):sub(1, 50)), "err")
                    end
                    task.wait(Config.CollectDelay)
                end
            else
                -- Don't spam "scanning" message, only log periodically
                if math.random(1, 5) == 1 then
                    Log("Scanning for event seeds...", "info")
                end
            end
            task.wait(Config.ScanInterval)
        end
    end)
end

local function HasSelection()
    for _, v in pairs(Config.SelectedSeeds) do if v then return true end end
    return false
end

-- ╔═════════════════════════════════════════════════════════════╗
-- ║  BUTTON WIRING                                             ║
-- ╚═════════════════════════════════════════════════════════════╝
ToggleTrack.MouseButton1Click:Connect(function()
    if Config.AutoCollect then StopAuto() else StartAuto() end
end)

CollectBtn.MouseButton1Click:Connect(function()
    if not HasSelection() then
        Log("No seeds selected! Pick at least one.", "warn")
        return
    end
    Log("Running one-time collect...", "info")
    task.spawn(function()
        local success, seeds = pcall(ScanForSeeds)
        if not success or #seeds == 0 then
            Log("No event seeds found.", "warn")
            return
        end
        Log(string.format("Found %d seed(s). Collecting...", #seeds), "success")
        for _, entry in ipairs(seeds) do
            local ok = CollectSeed(entry.obj, entry.seedName)
            if ok then
                State.Collected += 1
                StatusSub.Text = State.Collected .. " seeds collected this session"
                Log(string.format("Collected: %s", entry.seedName), "success")
            end
            task.wait(Config.CollectDelay)
        end
        Log("One-time collect complete.", "success")
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
    Tween(Main, { BackgroundTransparency = 1, Size = UDim2.new(0, UI_WIDTH, 0, 0) }, 0.3)
    task.wait(0.35)
    ScreenGui:Destroy()
end)

MinBtn.MouseButton1Click:Connect(function()
    CloseMain()
end)

-- Keybind
UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
        if Main.Visible then
            CloseMain()
        else
            OpenMain()
        end
    end
end)

-- ╔═════════════════════════════════════════════════════════════╗
-- ║  STARTUP                                                   ║
-- ╚═════════════════════════════════════════════════════════════╝
Main.Size = UDim2.new(0, UI_WIDTH, 0, 0)
Main.BackgroundTransparency = 1
Tween(Main, { Size = UDim2.new(0, UI_WIDTH, 0, UI_HEIGHT), BackgroundTransparency = 0 }, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

Log("GAG2 Hub v1.1 loaded successfully!", "success")
Log("Select seeds then toggle ON to start.", "info")
Log(string.format("UI scaled for %dx%d screen", ViewportSize.X, ViewportSize.Y), "info")

print("[ GAG2 Hub v1.1 ] Loaded  |  RightCtrl = toggle")