-- ╔═══════════════════════════════════════════════════════════════╗
-- ║         BARF Stock Hub — Discord Stock Notifier              ║
-- ║         Egg Shop & Gear Shop Tracker                        ║
-- ║         Made for Delta Executor                             ║
-- ╚═══════════════════════════════════════════════════════════════╝

local WEBHOOK_URL = "https://discord.com/api/webhooks/1513188279871082606/hsWmnfbJK9GPbzPCpq2RfK_kYLU1Eiv4qOZf2eghTe-OW-urMR04sMD8Arlxh5Hk3wFn"

-- ── Services ──────────────────────────────────────────────────────────────────
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local lp               = Players.LocalPlayer
local pg               = lp:WaitForChild("PlayerGui")

-- ── Destroy old GUI ───────────────────────────────────────────────────────────
if pg:FindFirstChild("BARFStockHub") then pg:FindFirstChild("BARFStockHub"):Destroy() end

-- ── State ─────────────────────────────────────────────────────────────────────
local autoScan   = false
local scanThread = nil
local lastKey    = ""
local totalScans = 0
local activeTab  = "Gear" -- "Gear" or "Egg"

-- ── Item Databases ────────────────────────────────────────────────────────────
local GEAR_ITEMS = {
    ["Basic Fertilizer"]      = {rarity="Common",    price=50},
    ["Strong Fertilizer"]     = {rarity="Uncommon",  price=150},
    ["Super Fertilizer"]      = {rarity="Rare",      price=500},
    ["Prismatic Fertilizer"]  = {rarity="Epic",      price=2000},
    ["Mythic Fertilizer"]     = {rarity="Mythical",  price=15000},
    ["Cosmic Spray"]          = {rarity="Legendary", price=5000},
    ["Rainbow Spray"]         = {rarity="Epic",      price=3000},
    ["Golden Spray"]          = {rarity="Rare",      price=800},
    ["Basic Spray"]           = {rarity="Common",    price=100},
    ["Watering Can"]          = {rarity="Common",    price=75},
    ["Speed Boost"]           = {rarity="Uncommon",  price=200},
    ["Harvest Aura"]          = {rarity="Rare",      price=1200},
    ["Basic Seed"]            = {rarity="Common",    price=30},
    ["Uncommon Seed"]         = {rarity="Uncommon",  price=120},
    ["Rare Seed"]             = {rarity="Rare",      price=500},
    ["Epic Seed"]             = {rarity="Epic",      price=2000},
    ["Legendary Seed"]        = {rarity="Legendary", price=8000},
    ["Mythical Seed"]         = {rarity="Mythical",  price=20000},
    ["Strawberry Seed"]       = {rarity="Common",    price=30},
    ["Carrot Seed"]           = {rarity="Common",    price=25},
    ["Sunflower Seed"]        = {rarity="Common",    price=40},
    ["Blueberry Seed"]        = {rarity="Uncommon",  price=120},
    ["Watermelon Seed"]       = {rarity="Uncommon",  price=180},
    ["Golden Apple Seed"]     = {rarity="Rare",      price=750},
    ["Crystal Seed"]          = {rarity="Rare",      price=900},
    ["Dragon Fruit Seed"]     = {rarity="Epic",      price=2500},
    ["Rainbow Tulip Seed"]    = {rarity="Epic",      price=4000},
    ["Elder Strawberry Seed"] = {rarity="Legendary", price=8000},
    ["Cosmic Rose Seed"]      = {rarity="Mythical",  price=20000},
    ["Void Seed"]             = {rarity="Mythical",  price=25000},
}

local EGG_ITEMS = {
    ["Bug Egg"]         = {rarity="Common",    price=500},
    ["Green Egg"]       = {rarity="Uncommon",  price=1200},
    ["Blue Egg"]        = {rarity="Rare",      price=3000},
    ["Purple Egg"]      = {rarity="Epic",      price=8000},
    ["Golden Egg"]      = {rarity="Legendary", price=20000},
    ["Rainbow Egg"]     = {rarity="Mythical",  price=50000},
    ["Cosmic Egg"]      = {rarity="Mythical",  price=75000},
    ["Event Egg"]       = {rarity="Event",     price=10000},
    ["Star Egg"]        = {rarity="Event",     price=15000},
    ["Void Egg"]        = {rarity="Mythical",  price=100000},
    ["Crystal Egg"]     = {rarity="Rare",      price=4000},
    ["Prismatic Egg"]   = {rarity="Epic",      price=12000},
}

local ALL_ITEMS = {}
for k,v in pairs(GEAR_ITEMS) do ALL_ITEMS[k] = v end
for k,v in pairs(EGG_ITEMS)  do ALL_ITEMS[k] = v end

local RARE_TIERS = {Epic=true, Legendary=true, Mythical=true, Event=true}

local RARITY_COLOR3 = {
    Common    = Color3.fromRGB(180, 180, 180),
    Uncommon  = Color3.fromRGB(60,  200, 100),
    Rare      = Color3.fromRGB(80,  150, 255),
    Epic      = Color3.fromRGB(180, 100, 255),
    Legendary = Color3.fromRGB(255, 200, 50),
    Mythical  = Color3.fromRGB(255, 80,  80),
    Event     = Color3.fromRGB(255, 120, 200),
}

local RARITY_EMOJI = {
    Common="⚪", Uncommon="🟢", Rare="🔵",
    Epic="🟣", Legendary="🟡", Mythical="🔴", Event="🌸"
}

local RARITY_INT = {
    Common=9934743, Uncommon=3066993, Rare=3447003,
    Epic=10181046, Legendary=16750592, Mythical=15158332, Event=16711935
}

-- ── Theme ─────────────────────────────────────────────────────────────────────
local C = {
    BG       = Color3.fromRGB(15,  15,  20),
    Panel    = Color3.fromRGB(22,  22,  30),
    Card     = Color3.fromRGB(28,  28,  40),
    Sidebar  = Color3.fromRGB(18,  18,  26),
    Accent   = Color3.fromRGB(88,  68,  220),
    AccentLt = Color3.fromRGB(108, 88,  255),
    Green    = Color3.fromRGB(50,  200, 100),
    Red      = Color3.fromRGB(210, 60,  60),
    Yellow   = Color3.fromRGB(240, 190, 40),
    Text     = Color3.fromRGB(235, 235, 255),
    Sub      = Color3.fromRGB(130, 130, 165),
    Border   = Color3.fromRGB(45,  45,  65),
    TabOn    = Color3.fromRGB(88,  68,  220),
    TabOff   = Color3.fromRGB(28,  28,  40),
}

-- ── GUI Root ──────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "BARFStockHub"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent          = pg

-- ── Main window ───────────────────────────────────────────────────────────────
local Win = Instance.new("Frame")
Win.Name                = "Window"
Win.Size                = UDim2.new(0, 460, 0, 380)
Win.Position            = UDim2.new(0.5, -230, 0.5, -190)
Win.BackgroundColor3    = C.BG
Win.BorderSizePixel     = 0
Win.ClipsDescendants    = true
Win.Parent              = ScreenGui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0, 10)
local winStroke = Instance.new("UIStroke", Win)
winStroke.Color     = C.Border
winStroke.Thickness = 1.5

-- ── Top bar ───────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = C.Panel
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 10
TopBar.Parent           = Win

-- Logo dot
local LogoDot = Instance.new("Frame")
LogoDot.Size             = UDim2.new(0, 10, 0, 10)
LogoDot.Position         = UDim2.new(0, 14, 0.5, -5)
LogoDot.BackgroundColor3 = C.Accent
LogoDot.BorderSizePixel  = 0
LogoDot.Parent           = TopBar
Instance.new("UICorner", LogoDot).CornerRadius = UDim.new(1, 0)

local Title = Instance.new("TextLabel")
Title.Size               = UDim2.new(0, 200, 1, 0)
Title.Position           = UDim2.new(0, 30, 0, 0)
Title.BackgroundTransparency = 1
Title.Text               = "BARF Stock Hub"
Title.TextColor3         = C.Text
Title.TextSize           = 14
Title.Font               = Enum.Font.GothamBold
Title.TextXAlignment     = Enum.TextXAlignment.Left
Title.Parent             = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size               = UDim2.new(0, 200, 0, 14)
SubTitle.Position           = UDim2.new(0, 30, 0.5, 2)
SubTitle.BackgroundTransparency = 1
SubTitle.Text               = "Egg Shop & Gear Shop Notifier"
SubTitle.TextColor3         = C.Sub
SubTitle.TextSize           = 10
SubTitle.Font               = Enum.Font.Gotham
SubTitle.TextXAlignment     = Enum.TextXAlignment.Left
SubTitle.Parent             = TopBar

-- Close + Minimize
local function makeTopBtn(xOff, bg, txt)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 26, 0, 26)
    b.Position         = UDim2.new(1, xOff, 0.5, -13)
    b.BackgroundColor3 = bg
    b.Text             = txt
    b.TextColor3       = Color3.new(1,1,1)
    b.TextSize         = 13
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.ZIndex           = 11
    b.Parent           = TopBar
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
    return b
end
local CloseBtn = makeTopBtn(-10, C.Red,    "✕")
local MinBtn   = makeTopBtn(-42, C.Accent, "−")

CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local isMin = false
local BodyFrame = Instance.new("Frame")
BodyFrame.Size             = UDim2.new(1, 0, 1, -40)
BodyFrame.Position         = UDim2.new(0, 0, 0, 40)
BodyFrame.BackgroundTransparency = 1
BodyFrame.Parent           = Win

MinBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    BodyFrame.Visible = not isMin
    TweenService:Create(Win, TweenInfo.new(0.2), {
        Size = isMin and UDim2.new(0, 460, 0, 40) or UDim2.new(0, 460, 0, 380)
    }):Play()
end)

-- ── Sidebar ───────────────────────────────────────────────────────────────────
local Sidebar = Instance.new("Frame")
Sidebar.Size             = UDim2.new(0, 120, 1, 0)
Sidebar.BackgroundColor3 = C.Sidebar
Sidebar.BorderSizePixel  = 0
Sidebar.Parent           = BodyFrame

local SideLayout = Instance.new("UIListLayout", Sidebar)
SideLayout.Padding       = UDim.new(0, 4)
SideLayout.SortOrder     = Enum.SortOrder.LayoutOrder
Instance.new("UIPadding", Sidebar).PaddingTop = UDim.new(0, 8)

-- Sidebar tab buttons
local function makeSideTab(label, icon, order)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, -8, 0, 38)
    btn.BackgroundColor3 = C.TabOff
    btn.Text             = ""
    btn.BorderSizePixel  = 0
    btn.LayoutOrder      = order
    btn.Parent           = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 7)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 4)

    local ico = Instance.new("TextLabel")
    ico.Size             = UDim2.new(0, 26, 1, 0)
    ico.Position         = UDim2.new(0, 6, 0, 0)
    ico.BackgroundTransparency = 1
    ico.Text             = icon
    ico.TextSize         = 18
    ico.Font             = Enum.Font.Gotham
    ico.TextColor3       = C.Text
    ico.Parent           = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -36, 1, 0)
    lbl.Position         = UDim2.new(0, 36, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextSize         = 12
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextColor3       = C.Sub
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = btn

    return btn, lbl, ico
end

local gearTabBtn, gearTabLbl = makeSideTab("Gear Shop", "⚙️", 1)
local eggTabBtn,  eggTabLbl  = makeSideTab("Egg Shop",  "🥚", 2)
local settTabBtn, settTabLbl = makeSideTab("Settings",  "⚙", 3)

-- Status indicator in sidebar bottom
local SideStatus = Instance.new("Frame")
SideStatus.Size             = UDim2.new(1, -8, 0, 52)
SideStatus.Position         = UDim2.new(0, 4, 1, -60)
SideStatus.BackgroundColor3 = C.Card
SideStatus.BorderSizePixel  = 0
SideStatus.Parent           = Sidebar
Instance.new("UICorner", SideStatus).CornerRadius = UDim.new(0, 7)

local SideDot = Instance.new("Frame")
SideDot.Size             = UDim2.new(0, 8, 0, 8)
SideDot.Position         = UDim2.new(0, 10, 0, 10)
SideDot.BackgroundColor3 = C.Red
SideDot.BorderSizePixel  = 0
SideDot.Parent           = SideStatus
Instance.new("UICorner", SideDot).CornerRadius = UDim.new(1, 0)

local SideStatusLbl = Instance.new("TextLabel")
SideStatusLbl.Size             = UDim2.new(1, -22, 0, 16)
SideStatusLbl.Position         = UDim2.new(0, 22, 0, 4)
SideStatusLbl.BackgroundTransparency = 1
SideStatusLbl.Text             = "Inactive"
SideStatusLbl.TextColor3       = C.Sub
SideStatusLbl.TextSize         = 11
SideStatusLbl.Font             = Enum.Font.GothamBold
SideStatusLbl.TextXAlignment   = Enum.TextXAlignment.Left
SideStatusLbl.Parent           = SideStatus

local SideScanLbl = Instance.new("TextLabel")
SideScanLbl.Size             = UDim2.new(1, -8, 0, 14)
SideScanLbl.Position         = UDim2.new(0, 8, 0, 24)
SideScanLbl.BackgroundTransparency = 1
SideScanLbl.Text             = "Scans: 0"
SideScanLbl.TextColor3       = C.Sub
SideScanLbl.TextSize         = 10
SideScanLbl.Font             = Enum.Font.Gotham
SideScanLbl.TextXAlignment   = Enum.TextXAlignment.Left
SideScanLbl.Parent           = SideStatus

local SideTimeLbl = Instance.new("TextLabel")
SideTimeLbl.Size             = UDim2.new(1, -8, 0, 12)
SideTimeLbl.Position         = UDim2.new(0, 8, 0, 38)
SideTimeLbl.BackgroundTransparency = 1
SideTimeLbl.Text             = "Last: --"
SideTimeLbl.TextColor3       = C.Sub
SideTimeLbl.TextSize         = 9
SideTimeLbl.Font             = Enum.Font.Gotham
SideTimeLbl.TextXAlignment   = Enum.TextXAlignment.Left
SideTimeLbl.Parent           = SideStatus

-- ── Content area ──────────────────────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Size             = UDim2.new(1, -128, 1, -8)
Content.Position         = UDim2.new(0, 124, 0, 4)
Content.BackgroundTransparency = 1
Content.Parent           = BodyFrame

-- ── Helper: make a page ───────────────────────────────────────────────────────
local function makePage()
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.Visible          = false
    f.Parent           = Content
    return f
end

-- ── Helper: section header ────────────────────────────────────────────────────
local function makeHeader(parent, text, yPos)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 0, 18)
    lbl.Position         = UDim2.new(0, 0, 0, yPos)
    lbl.BackgroundTransparency = 1
    lbl.Text             = text
    lbl.TextColor3       = C.Sub
    lbl.TextSize         = 11
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = parent
    return lbl
end

-- ── Helper: toggle row ────────────────────────────────────────────────────────
local function makeToggleRow(parent, label, sublabel, yPos)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 46)
    row.Position         = UDim2.new(0, 0, 0, yPos)
    row.BackgroundColor3 = C.Card
    row.BorderSizePixel  = 0
    row.Parent           = parent
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", row)
    s.Color     = C.Border
    s.Thickness = 1

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -60, 0, 20)
    lbl.Position         = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text             = label
    lbl.TextColor3       = C.Text
    lbl.TextSize         = 13
    lbl.Font             = Enum.Font.GothamBold
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local sub = Instance.new("TextLabel")
    sub.Size             = UDim2.new(1, -60, 0, 14)
    sub.Position         = UDim2.new(0, 12, 0, 26)
    sub.BackgroundTransparency = 1
    sub.Text             = sublabel
    sub.TextColor3       = C.Sub
    sub.TextSize         = 10
    sub.Font             = Enum.Font.Gotham
    sub.TextXAlignment   = Enum.TextXAlignment.Left
    sub.Parent           = row

    -- Toggle pill
    local pill = Instance.new("Frame")
    pill.Size             = UDim2.new(0, 40, 0, 22)
    pill.Position         = UDim2.new(1, -52, 0.5, -11)
    pill.BackgroundColor3 = C.Border
    pill.BorderSizePixel  = 0
    pill.Parent           = row
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C.Sub
    knob.BorderSizePixel  = 0
    knob.Parent           = pill
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local on = false
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.Parent           = row

    local function setToggle(state)
        on = state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position         = on and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
            BackgroundColor3 = on and Color3.new(1,1,1) or C.Sub,
        }):Play()
        TweenService:Create(pill, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C.Green or C.Border
        }):Play()
    end

    btn.MouseButton1Click:Connect(function() setToggle(not on) end)
    return row, btn, setToggle, function() return on end
end

-- ── Helper: action button ─────────────────────────────────────────────────────
local function makeActionBtn(parent, label, yPos, accent)
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 0, 36)
    btn.Position         = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = accent or C.Accent
    btn.Text             = label
    btn.TextColor3       = Color3.new(1,1,1)
    btn.TextSize         = 13
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
    btn.Parent           = parent
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    return btn
end

-- ── Helper: stock scroll list ─────────────────────────────────────────────────
local function makeStockList(parent, yPos, height)
    local frame = Instance.new("Frame")
    frame.Size             = UDim2.new(1, 0, 0, height)
    frame.Position         = UDim2.new(0, 0, 0, yPos)
    frame.BackgroundColor3 = C.Card
    frame.BorderSizePixel  = 0
    frame.ClipsDescendants = true
    frame.Parent           = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local s = Instance.new("UIStroke", frame)
    s.Color = C.Border s.Thickness = 1

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size               = UDim2.new(1, -4, 1, -8)
    scroll.Position           = UDim2.new(0, 4, 0, 4)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel    = 0
    scroll.ScrollBarThickness = 2
    scroll.ScrollBarImageColor3 = C.Accent
    scroll.Parent             = frame

    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding   = UDim.new(0, 3)
    layout.SortOrder = Enum.SortOrder.LayoutOrder

    return scroll, layout
end

-- ════════════════════════════════════════════════════════════════════
-- PAGE 1: GEAR SHOP
-- ════════════════════════════════════════════════════════════════════
local GearPage = makePage()

makeHeader(GearPage, "  GEAR SHOP", 0)
local gearScroll, gearLayout = makeStockList(GearPage, 22, 165)

local _, gearAutoBtn, setGearToggle, getGearToggle = makeToggleRow(
    GearPage, "Auto-Scan", "Checks gear shop every 15s", 196)
local gearScanBtn  = makeActionBtn(GearPage, "🔍  Scan Now",        246, C.Accent)
local gearSendBtn  = makeActionBtn(GearPage, "📤  Force Send to Discord", 288, C.Panel)
local gearStroke   = Instance.new("UIStroke", gearSendBtn)
gearStroke.Color = C.Accent gearStroke.Thickness = 1.5

-- ════════════════════════════════════════════════════════════════════
-- PAGE 2: EGG SHOP
-- ════════════════════════════════════════════════════════════════════
local EggPage = makePage()

makeHeader(EggPage, "  EGG SHOP", 0)
local eggScroll, eggLayout = makeStockList(EggPage, 22, 165)

local _, eggAutoBtn, setEggToggle, getEggToggle = makeToggleRow(
    EggPage, "Auto-Scan", "Checks egg shop every 15s", 196)
local eggScanBtn = makeActionBtn(EggPage, "🔍  Scan Now",        246, C.Accent)
local eggSendBtn = makeActionBtn(EggPage, "📤  Force Send to Discord", 288, C.Panel)
local eggStroke  = Instance.new("UIStroke", eggSendBtn)
eggStroke.Color = C.Accent eggStroke.Thickness = 1.5

-- ════════════════════════════════════════════════════════════════════
-- PAGE 3: SETTINGS
-- ════════════════════════════════════════════════════════════════════
local SettPage = makePage()
makeHeader(SettPage, "  SETTINGS", 0)

local infoCard = Instance.new("Frame")
infoCard.Size             = UDim2.new(1, 0, 0, 80)
infoCard.Position         = UDim2.new(0, 0, 0, 22)
infoCard.BackgroundColor3 = C.Card
infoCard.BorderSizePixel  = 0
infoCard.Parent           = SettPage
Instance.new("UICorner", infoCard).CornerRadius = UDim.new(0, 8)

local infoText = Instance.new("TextLabel")
infoText.Size             = UDim2.new(1, -16, 1, -16)
infoText.Position         = UDim2.new(0, 8, 0, 8)
infoText.BackgroundTransparency = 1
infoText.Text             = "BARF Stock Hub v1.0\nWebhook: Connected ✅\nScans Gear + Egg shop every 15s\nPings Discord on new stock found"
infoText.TextColor3       = C.Sub
infoText.TextSize         = 11
infoText.Font             = Enum.Font.Gotham
infoText.TextXAlignment   = Enum.TextXAlignment.Left
infoText.TextYAlignment   = Enum.TextYAlignment.Top
infoText.TextWrapped      = true
infoText.Parent           = infoCard

local testBtn = makeActionBtn(SettPage, "🧪  Test Webhook", 112, C.Green)
local clearBtn = makeActionBtn(SettPage, "🗑  Clear Stock Display", 156, C.Panel)
local clrStroke = Instance.new("UIStroke", clearBtn)
clrStroke.Color = C.Red clrStroke.Thickness = 1.5

-- ── Tab switching ─────────────────────────────────────────────────────────────
local pages   = {Gear=GearPage, Egg=EggPage, Settings=SettPage}
local tabBtns = {Gear=gearTabBtn, Egg=eggTabBtn, Settings=settTabBtn}
local tabLbls = {Gear=gearTabLbl, Egg=eggTabLbl, Settings=settTabLbl}

local function switchTab(name)
    activeTab = name
    for k, page in pairs(pages) do
        page.Visible = (k == name)
        TweenService:Create(tabBtns[k], TweenInfo.new(0.15), {
            BackgroundColor3 = (k==name) and C.TabOn or C.TabOff
        }):Play()
        tabLbls[k].TextColor3 = (k==name) and C.Text or C.Sub
    end
end

gearTabBtn.MouseButton1Click:Connect(function() switchTab("Gear") end)
eggTabBtn.MouseButton1Click:Connect(function()  switchTab("Egg")  end)
settTabBtn.MouseButton1Click:Connect(function() switchTab("Settings") end)
switchTab("Gear")

-- ── Stock display helpers ─────────────────────────────────────────────────────
local function clearList(scroll)
    for _, c in ipairs(scroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function addItemRow(scroll, layout, name, rarity, price, order)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, -4, 0, 28)
    row.BackgroundColor3 = C.Panel
    row.BorderSizePixel  = 0
    row.LayoutOrder      = order
    row.Parent           = scroll
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

    local emoji = RARITY_EMOJI[rarity] or "⚪"
    local col   = RARITY_COLOR3[rarity] or C.Sub

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(0, 200, 1, 0)
    nameLbl.Position         = UDim2.new(0, 8, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = emoji .. "  " .. name
    nameLbl.TextColor3       = col
    nameLbl.TextSize         = 11
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.Parent           = row

    local rarityBadge = Instance.new("TextLabel")
    rarityBadge.Size             = UDim2.new(0, 70, 0, 18)
    rarityBadge.Position         = UDim2.new(1, -140, 0.5, -9)
    rarityBadge.BackgroundColor3 = C.BG
    rarityBadge.Text             = rarity
    rarityBadge.TextColor3       = col
    rarityBadge.TextSize         = 9
    rarityBadge.Font             = Enum.Font.GothamBold
    rarityBadge.Parent           = row
    Instance.new("UICorner", rarityBadge).CornerRadius = UDim.new(0, 4)

    if price then
        local priceLbl = Instance.new("TextLabel")
        priceLbl.Size             = UDim2.new(0, 60, 1, 0)
        priceLbl.Position         = UDim2.new(1, -66, 0, 0)
        priceLbl.BackgroundTransparency = 1
        priceLbl.Text             = tostring(price)
        priceLbl.TextColor3       = C.Sub
        priceLbl.TextSize         = 10
        priceLbl.Font             = Enum.Font.Gotham
        priceLbl.TextXAlignment   = Enum.TextXAlignment.Right
        priceLbl.Parent           = row
    end

    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 6)
end

local function showEmpty(scroll, layout, msg)
    clearList(scroll)
    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, 0, 0, 30)
    lbl.BackgroundTransparency = 1
    lbl.Text             = msg
    lbl.TextColor3       = C.Sub
    lbl.TextSize         = 11
    lbl.Font             = Enum.Font.Gotham
    lbl.Parent           = scroll
    scroll.CanvasSize    = UDim2.new(0, 0, 0, 30)
end

-- ── Core scan function ────────────────────────────────────────────────────────
local function scanEverything(itemDB)
    local found = {}
    local function checkText(text, parent)
        if not text or #text < 3 then return end
        for itemName, data in pairs(itemDB) do
            if text == itemName or text:find(itemName, 1, true) then
                if not found[itemName] then
                    -- Try to find price nearby
                    local price = data.price
                    if parent then
                        for _, sib in ipairs(parent:GetDescendants()) do
                            if sib:IsA("TextLabel") or sib:IsA("TextButton") then
                                local n = (sib.Text or ""):gsub(",",""):gsub("%D","")
                                local num = tonumber(n)
                                if num and num > 0 and num < 10000000 then
                                    price = num
                                end
                            end
                        end
                    end
                    found[itemName] = {rarity=data.rarity, price=price}
                end
            end
        end
    end

    -- Scan PlayerGui
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
            checkText(obj.Text or "", obj.Parent)
        end
    end
    -- Scan Workspace
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            checkText(obj.Text or "", obj.Parent)
        elseif obj:IsA("StringValue") then
            checkText(obj.Value or "", nil)
        end
        checkText(obj.Name, nil)
        local ok, attrs = pcall(function() return obj:GetAttributes() end)
        if ok then for _, v in pairs(attrs) do checkText(tostring(v), nil) end end
    end

    return found
end

-- ── Webhook sender ────────────────────────────────────────────────────────────
local function sendToDiscord(found, shopName)
    if not next(found) then return false end

    local items   = {}
    local hasRare = false
    local topColor = RARITY_INT.Common

    local tierOrder = {"Mythical","Legendary","Epic","Event","Rare","Uncommon","Common"}

    for name, data in pairs(found) do
        if RARE_TIERS[data.rarity] then hasRare = true end
        table.insert(items, {name=name, rarity=data.rarity, price=data.price})
    end

    for _, tier in ipairs(tierOrder) do
        for _, item in ipairs(items) do
            if item.rarity == tier then
                topColor = RARITY_INT[tier] or topColor
                break
            end
        end
        if topColor ~= RARITY_INT.Common then break end
    end

    local lines = {}
    for _, item in ipairs(items) do
        local emoji    = RARITY_EMOJI[item.rarity] or "⚪"
        local priceStr = item.price and ("💰 " .. tostring(item.price) .. " coins") or ""
        table.insert(lines, emoji .. " **" .. item.name .. "** `" .. item.rarity .. "`" ..
            (priceStr ~= "" and "\n  " .. priceStr or ""))
    end

    local ok, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({
            content = hasRare and "🚨 **Rare item in stock!**" or nil,
            embeds  = {{
                title       = (shopName == "Egg" and "🥚" or "⚙️") .. " Build a Ring Farm — " .. shopName .. " Shop Stock",
                description = "Real-time stock from in-game scan!",
                color       = topColor,
                fields      = {{
                    name   = (shopName == "Egg" and "🥚 Egg Shop" or "⚙️ Gear Shop"),
                    value  = #lines > 0 and table.concat(lines, "\n") or "_Nothing detected_",
                    inline = false,
                }},
                footer    = {text = "Live scan • BARF Stock Hub"},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        }), Enum.HttpContentType.ApplicationJson, false)
    end)

    return ok
end

-- ── Update status bar ─────────────────────────────────────────────────────────
local function setStatus(running)
    SideDot.BackgroundColor3  = running and C.Green or C.Red
    SideStatusLbl.Text        = running and "Scanning..." or "Inactive"
    SideStatusLbl.TextColor3  = running and C.Green or C.Sub
end

local function updateScans()
    totalScans = totalScans + 1
    SideScanLbl.Text = "Scans: " .. totalScans
    SideTimeLbl.Text = "Last: " .. os.date("%H:%M:%S")
end

-- ── Scan + display for Gear ───────────────────────────────────────────────────
local function doGearScan(forceSend)
    setStatus(true)
    updateScans()

    local found = scanEverything(GEAR_ITEMS)
    clearList(gearScroll)

    if not next(found) then
        showEmpty(gearScroll, gearLayout, "  No gear items detected in game")
        setStatus(false)
        return
    end

    local i = 0
    for name, data in pairs(found) do
        addItemRow(gearScroll, gearLayout, name, data.rarity, data.price, i)
        i = i + 1
    end

    -- Build change key
    local keys = {}
    for name in pairs(found) do table.insert(keys, name) end
    table.sort(keys)
    local key = "gear:" .. table.concat(keys, ",")

    if forceSend or key ~= lastKey then
        lastKey = key
        local ok = sendToDiscord(found, "Gear")
        if ok then
            gearScanBtn.Text = "✅ Sent!"
            task.delay(2, function() gearScanBtn.Text = "🔍  Scan Now" end)
        end
    end
    setStatus(autoScan)
end

-- ── Scan + display for Egg ────────────────────────────────────────────────────
local function doEggScan(forceSend)
    setStatus(true)
    updateScans()

    local found = scanEverything(EGG_ITEMS)
    clearList(eggScroll)

    if not next(found) then
        showEmpty(eggScroll, eggLayout, "  No egg items detected in game")
        setStatus(false)
        return
    end

    local i = 0
    for name, data in pairs(found) do
        addItemRow(eggScroll, eggLayout, name, data.rarity, data.price, i)
        i = i + 1
    end

    local keys = {}
    for name in pairs(found) do table.insert(keys, name) end
    table.sort(keys)
    local key = "egg:" .. table.concat(keys, ",")

    if forceSend or key ~= lastKey then
        lastKey = key
        local ok = sendToDiscord(found, "Egg")
        if ok then
            eggScanBtn.Text = "✅ Sent!"
            task.delay(2, function() eggScanBtn.Text = "🔍  Scan Now" end)
        end
    end
    setStatus(autoScan)
end

-- ── Button wiring ─────────────────────────────────────────────────────────────
gearScanBtn.MouseButton1Click:Connect(function()
    gearScanBtn.Text = "⏳ Scanning..."
    task.spawn(function() doGearScan(false) end)
end)

gearSendBtn.MouseButton1Click:Connect(function()
    gearSendBtn.Text = "⏳ Sending..."
    task.spawn(function() doGearScan(true) end)
    task.delay(2, function() gearSendBtn.Text = "📤  Force Send to Discord" end)
end)

eggScanBtn.MouseButton1Click:Connect(function()
    eggScanBtn.Text = "⏳ Scanning..."
    task.spawn(function() doEggScan(false) end)
end)

eggSendBtn.MouseButton1Click:Connect(function()
    eggSendBtn.Text = "⏳ Sending..."
    task.spawn(function() doEggScan(true) end)
    task.delay(2, function() eggSendBtn.Text = "📤  Force Send to Discord" end)
end)

-- Auto scan toggles
gearAutoBtn.MouseButton1Click:Connect(function()
    autoScan = getGearToggle()
    if autoScan then
        setStatus(true)
        scanThread = task.spawn(function()
            while autoScan do
                doGearScan(false)
                task.wait(15)
            end
        end)
    else
        autoScan = false
        setStatus(false)
    end
end)

eggAutoBtn.MouseButton1Click:Connect(function()
    autoScan = getEggToggle()
    if autoScan then
        setStatus(true)
        scanThread = task.spawn(function()
            while autoScan do
                doEggScan(false)
                task.wait(15)
            end
        end)
    else
        autoScan = false
        setStatus(false)
    end
end)

-- Settings buttons
testBtn.MouseButton1Click:Connect(function()
    testBtn.Text = "⏳ Testing..."
    local ok, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({
            embeds = {{
                title       = "✅ BARF Stock Hub — Webhook Test",
                description = "Webhook is connected and working!",
                color       = 3066993,
                footer      = {text = "BARF Stock Hub"},
            }}
        }), Enum.HttpContentType.ApplicationJson, false)
    end)
    task.delay(1.5, function()
        testBtn.Text = ok and "✅ Webhook Works!" or "❌ Failed!"
        task.delay(2, function() testBtn.Text = "🧪  Test Webhook" end)
    end)
end)

clearBtn.MouseButton1Click:Connect(function()
    showEmpty(gearScroll, gearLayout, "  Cleared.")
    showEmpty(eggScroll,  eggLayout,  "  Cleared.")
end)

-- ── Drag to move ──────────────────────────────────────────────────────────────
do
    local drag, dragStart, winStart
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dragStart = i.Position
            winStart  = Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Win.Position = UDim2.new(
                winStart.X.Scale, winStart.X.Offset + d.X,
                winStart.Y.Scale, winStart.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
    end)
end

print("[BARF Stock Hub] ✅ Loaded! Use the Gear Shop or Egg Shop tabs.")
