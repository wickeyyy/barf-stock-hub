-- ╔═══════════════════════════════════════════════════════════════╗
-- ║         BARF Stock Hub v3                                    ║
-- ║         Gear Shop & Egg Shop Notifier                       ║
-- ║         Paste your webhook inside the GUI                   ║
-- ╚═══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local lp               = Players.LocalPlayer
local pg               = lp:WaitForChild("PlayerGui")

if pg:FindFirstChild("BARFStockHub") then pg:FindFirstChild("BARFStockHub"):Destroy() end

-- ── Webhook (set via GUI) ─────────────────────────────────────────────────────
local WEBHOOK_URL = ""

-- ── Real item names from game ─────────────────────────────────────────────────
local GEAR_ITEMS = {
    -- Fertilizers
    "Normal Fertilizer", "Strong Fertilizer", "Super Fertilizer",
    "Prismatic Fertilizer", "Mythic Fertilizer",
    -- Sprays
    "Normal Spray", "Acid Spray", "Wet Spray", "Frozen Spray",
    "Autumn Spray", "Radioactive Spray", "Fire Spray", "Void Spray",
    "Rainbow Spray", "Bubblegum Spray", "Cosmic Spray",
    -- Pet Treats
    "Normal Pet Treat", "Strong Pet Treat", "Super Pet Treat",
}

local EGG_ITEMS = {
    "Common Egg", "Uncommon Egg", "Rare Egg", "Epic Egg",
    "Legendary Egg", "Mythical Egg", "Event Egg", "Bug Egg",
    "Rainbow Egg", "Cosmic Egg", "Void Egg", "Crystal Egg",
    "Prismatic Egg", "Star Egg", "Golden Egg", "Green Egg", "Blue Egg",
}

-- Rarity guessed from item name keywords
local function guessRarity(name)
    local n = name:lower()
    if n:find("mythic") or n:find("void") or n:find("cosmic") then return "Mythical"
    elseif n:find("legendary") or n:find("rainbow") or n:find("prismatic") then return "Legendary"
    elseif n:find("epic") or n:find("bubblegum") or n:find("fire") then return "Epic"
    elseif n:find("rare") or n:find("super") or n:find("frozen") or n:find("radioactive") then return "Rare"
    elseif n:find("uncommon") or n:find("strong") or n:find("wet") or n:find("autumn") then return "Uncommon"
    else return "Common" end
end

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
local RARE_TIERS = {Epic=true, Legendary=true, Mythical=true, Event=true}

-- ── Theme ─────────────────────────────────────────────────────────────────────
local C = {
    BG      = Color3.fromRGB(15,  15,  20),
    Panel   = Color3.fromRGB(22,  22,  30),
    Card    = Color3.fromRGB(28,  28,  40),
    Sidebar = Color3.fromRGB(18,  18,  26),
    Accent  = Color3.fromRGB(88,  68,  220),
    Green   = Color3.fromRGB(50,  200, 100),
    Red     = Color3.fromRGB(210, 60,  60),
    Text    = Color3.fromRGB(235, 235, 255),
    Sub     = Color3.fromRGB(130, 130, 165),
    Border  = Color3.fromRGB(45,  45,  65),
}

-- ── Root ──────────────────────────────────────────────────────────────────────
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "BARFStockHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = pg

local Win = Instance.new("Frame")
Win.Size             = UDim2.new(0, 460, 0, 400)
Win.Position         = UDim2.new(0.5,-230,0.5,-200)
Win.BackgroundColor3 = C.BG
Win.BorderSizePixel  = 0
Win.ClipsDescendants = true
Win.Parent           = ScreenGui
Instance.new("UICorner", Win).CornerRadius = UDim.new(0,10)
local ws = Instance.new("UIStroke", Win)
ws.Color = C.Border ws.Thickness = 1.5

-- ── Top bar ───────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1,0,0,40)
TopBar.BackgroundColor3 = C.Panel
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 10
TopBar.Parent           = Win

local dot = Instance.new("Frame", TopBar)
dot.Size=UDim2.new(0,10,0,10) dot.Position=UDim2.new(0,14,0.5,-5)
dot.BackgroundColor3=C.Accent dot.BorderSizePixel=0
Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)

local function topLabel(txt, size, col, xOff, yOff, w)
    local l = Instance.new("TextLabel", TopBar)
    l.Size=UDim2.new(0,w or 220,0,size+4) l.Position=UDim2.new(0,xOff,0,yOff)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=col
    l.TextSize=size l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end
topLabel("BARF Stock Hub", 14, C.Text, 30, 6)
topLabel("Gear Shop & Egg Shop Notifier", 10, C.Sub, 30, 22)

local function makeTopBtn(xOff, bg, txt)
    local b=Instance.new("TextButton",TopBar)
    b.Size=UDim2.new(0,26,0,26) b.Position=UDim2.new(1,xOff,0.5,-13)
    b.BackgroundColor3=bg b.Text=txt b.TextColor3=Color3.new(1,1,1)
    b.TextSize=13 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.ZIndex=11
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
local CloseBtn = makeTopBtn(-10, C.Red, "✕")
local MinBtn   = makeTopBtn(-42, C.Accent, "−")
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

local Body = Instance.new("Frame", Win)
Body.Size=UDim2.new(1,0,1,-40) Body.Position=UDim2.new(0,0,0,40)
Body.BackgroundTransparency=1

local isMin = false
MinBtn.MouseButton1Click:Connect(function()
    isMin = not isMin
    Body.Visible = not isMin
    TweenService:Create(Win,TweenInfo.new(0.2),{
        Size=isMin and UDim2.new(0,460,0,40) or UDim2.new(0,460,0,400)
    }):Play()
end)

-- ── Sidebar ───────────────────────────────────────────────────────────────────
local Sidebar = Instance.new("Frame", Body)
Sidebar.Size=UDim2.new(0,110,1,0)
Sidebar.BackgroundColor3=C.Sidebar Sidebar.BorderSizePixel=0
local sl=Instance.new("UIListLayout",Sidebar)
sl.Padding=UDim.new(0,4) sl.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",Sidebar).PaddingTop=UDim.new(0,8)

local function makeSideTab(lbl, icon, order)
    local btn=Instance.new("TextButton",Sidebar)
    btn.Size=UDim2.new(1,-8,0,38) btn.BackgroundColor3=C.Card
    btn.Text="" btn.BorderSizePixel=0 btn.LayoutOrder=order
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,7)
    local i=Instance.new("TextLabel",btn)
    i.Size=UDim2.new(0,26,1,0) i.Position=UDim2.new(0,6,0,0)
    i.BackgroundTransparency=1 i.Text=icon i.TextSize=18
    i.Font=Enum.Font.Gotham i.TextColor3=C.Text
    local t=Instance.new("TextLabel",btn)
    t.Size=UDim2.new(1,-36,1,0) t.Position=UDim2.new(0,36,0,0)
    t.BackgroundTransparency=1 t.Text=lbl t.TextSize=11
    t.Font=Enum.Font.GothamBold t.TextColor3=C.Sub
    t.TextXAlignment=Enum.TextXAlignment.Left
    return btn, t
end

local gearTabBtn, gearTabLbl = makeSideTab("Gear Shop","⚙️",1)
local eggTabBtn,  eggTabLbl  = makeSideTab("Egg Shop", "🥚",2)
local wbTabBtn,   wbTabLbl   = makeSideTab("Webhook",  "🔗",3)

-- Sidebar status
local sideStatus = Instance.new("Frame", Sidebar)
sideStatus.Size=UDim2.new(1,-8,0,58) sideStatus.BackgroundColor3=C.Card
sideStatus.BorderSizePixel=0 sideStatus.LayoutOrder=10
Instance.new("UICorner",sideStatus).CornerRadius=UDim.new(0,7)

local sideDot=Instance.new("Frame",sideStatus)
sideDot.Size=UDim2.new(0,8,0,8) sideDot.Position=UDim2.new(0,8,0,8)
sideDot.BackgroundColor3=C.Red sideDot.BorderSizePixel=0
Instance.new("UICorner",sideDot).CornerRadius=UDim.new(1,0)

local function sideLabel(txt, size, yp)
    local l=Instance.new("TextLabel",sideStatus)
    l.Size=UDim2.new(1,-8,0,14) l.Position=UDim2.new(0,8,0,yp)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=C.Sub
    l.TextSize=size l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end
local sideStatusLbl = sideLabel("Inactive", 11, 20)
local sideScanLbl   = sideLabel("Scans: 0", 10, 34)
local sideTimeLbl   = sideLabel("Last: --",  9, 46)

-- ── Content ───────────────────────────────────────────────────────────────────
local Content = Instance.new("Frame", Body)
Content.Size=UDim2.new(1,-118,1,-8)
Content.Position=UDim2.new(0,114,0,4)
Content.BackgroundTransparency=1

local function makePage()
    local f=Instance.new("Frame",Content)
    f.Size=UDim2.new(1,0,1,0)
    f.BackgroundTransparency=1 f.Visible=false
    return f
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function hdr(parent, txt, y)
    local l=Instance.new("TextLabel",parent)
    l.Size=UDim2.new(1,0,0,16) l.Position=UDim2.new(0,0,0,y)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=C.Sub
    l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end

local function actionBtn(parent, txt, y, bg)
    local b=Instance.new("TextButton",parent)
    b.Size=UDim2.new(1,0,0,34) b.Position=UDim2.new(0,0,0,y)
    b.BackgroundColor3=bg or C.Accent b.Text=txt
    b.TextColor3=Color3.new(1,1,1) b.TextSize=12
    b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end

local function makeList(parent, y, h)
    local bg=Instance.new("Frame",parent)
    bg.Size=UDim2.new(1,0,0,h) bg.Position=UDim2.new(0,0,0,y)
    bg.BackgroundColor3=C.Card bg.BorderSizePixel=0 bg.ClipsDescendants=true
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
    local st=Instance.new("UIStroke",bg) st.Color=C.Border st.Thickness=1
    local sc=Instance.new("ScrollingFrame",bg)
    sc.Size=UDim2.new(1,-4,1,-6) sc.Position=UDim2.new(0,2,0,3)
    sc.BackgroundTransparency=1 sc.BorderSizePixel=0
    sc.ScrollBarThickness=2 sc.ScrollBarImageColor3=C.Accent
    local lay=Instance.new("UIListLayout",sc)
    lay.Padding=UDim.new(0,3) lay.SortOrder=Enum.SortOrder.LayoutOrder
    return sc, lay
end

local function clearList(sc)
    for _,c in ipairs(sc:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end

local function addRow(sc, lay, name, rarity, price, desc, stock)
    local rarity = rarity or "Common"
    local col = RARITY_COLOR3[rarity] or C.Sub
    local emoji = RARITY_EMOJI[rarity] or "⚪"

    local row=Instance.new("Frame",sc)
    row.Size=UDim2.new(1,-4,0,44) row.BackgroundColor3=C.Panel
    row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)

    local nameLbl=Instance.new("TextLabel",row)
    nameLbl.Size=UDim2.new(1,-70,0,18) nameLbl.Position=UDim2.new(0,8,0,4)
    nameLbl.BackgroundTransparency=1
    nameLbl.Text=emoji.."  "..name
    nameLbl.TextColor3=col nameLbl.TextSize=12
    nameLbl.Font=Enum.Font.GothamBold
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left

    local descLbl=Instance.new("TextLabel",row)
    descLbl.Size=UDim2.new(1,-70,0,14) descLbl.Position=UDim2.new(0,8,0,24)
    descLbl.BackgroundTransparency=1
    descLbl.Text=desc or ""
    descLbl.TextColor3=C.Sub descLbl.TextSize=9
    descLbl.Font=Enum.Font.Gotham
    descLbl.TextXAlignment=Enum.TextXAlignment.Left

    -- Rarity badge
    local badge=Instance.new("TextLabel",row)
    badge.Size=UDim2.new(0,58,0,16) badge.Position=UDim2.new(1,-64,0,4)
    badge.BackgroundColor3=C.BG badge.Text=rarity
    badge.TextColor3=col badge.TextSize=9
    badge.Font=Enum.Font.GothamBold
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,4)

    -- Price
    local priceLbl=Instance.new("TextLabel",row)
    priceLbl.Size=UDim2.new(0,58,0,14) priceLbl.Position=UDim2.new(1,-64,0,24)
    priceLbl.BackgroundTransparency=1
    priceLbl.Text=price or ""
    priceLbl.TextColor3=Color3.fromRGB(100,220,100)
    priceLbl.TextSize=9 priceLbl.Font=Enum.Font.GothamBold
    priceLbl.TextXAlignment=Enum.TextXAlignment.Right

    sc.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+6)
    return row
end

local function showEmpty(sc, lay, msg)
    clearList(sc)
    local l=Instance.new("TextLabel",sc)
    l.Size=UDim2.new(1,0,0,30) l.BackgroundTransparency=1
    l.Text=msg l.TextColor3=C.Sub l.TextSize=11
    l.Font=Enum.Font.Gotham
    sc.CanvasSize=UDim2.new(0,0,0,30)
end

-- ════════════════════════════════════════════════════════════════════
-- PAGE 1: GEAR SHOP
-- ════════════════════════════════════════════════════════════════════
local GearPage = makePage()
hdr(GearPage, "  GEAR SHOP — Current Stock", 0)
local gearSc, gearLay = makeList(GearPage, 18, 190)
local gearScanBtn = actionBtn(GearPage, "🔍  Scan Gear Shop", 216, C.Accent)
local gearSendBtn = actionBtn(GearPage, "📤  Force Send to Discord", 256, C.Panel)
local gearSendStroke=Instance.new("UIStroke",gearSendBtn)
gearSendStroke.Color=C.Accent gearSendStroke.Thickness=1.5

local gearAutoRow=Instance.new("Frame",GearPage)
gearAutoRow.Size=UDim2.new(1,0,0,34) gearAutoRow.Position=UDim2.new(0,0,0,298)
gearAutoRow.BackgroundColor3=C.Card gearAutoRow.BorderSizePixel=0
Instance.new("UICorner",gearAutoRow).CornerRadius=UDim.new(0,7)
local gearAutoLbl=Instance.new("TextLabel",gearAutoRow)
gearAutoLbl.Size=UDim2.new(1,-100,1,0) gearAutoLbl.Position=UDim2.new(0,10,0,0)
gearAutoLbl.BackgroundTransparency=1 gearAutoLbl.Text="Auto-Scan (every 15s)"
gearAutoLbl.TextColor3=C.Text gearAutoLbl.TextSize=12
gearAutoLbl.Font=Enum.Font.GothamBold
gearAutoLbl.TextXAlignment=Enum.TextXAlignment.Left
local gearToggleBtn=Instance.new("TextButton",gearAutoRow)
gearToggleBtn.Size=UDim2.new(0,70,0,24) gearToggleBtn.Position=UDim2.new(1,-78,0.5,-12)
gearToggleBtn.BackgroundColor3=C.Border gearToggleBtn.Text="OFF"
gearToggleBtn.TextColor3=C.Sub gearToggleBtn.TextSize=12
gearToggleBtn.Font=Enum.Font.GothamBold gearToggleBtn.BorderSizePixel=0
Instance.new("UICorner",gearToggleBtn).CornerRadius=UDim.new(0,5)

-- ════════════════════════════════════════════════════════════════════
-- PAGE 2: EGG SHOP
-- ════════════════════════════════════════════════════════════════════
local EggPage = makePage()
hdr(EggPage, "  EGG SHOP — Current Stock", 0)
local eggSc, eggLay = makeList(EggPage, 18, 190)
local eggScanBtn = actionBtn(EggPage, "🔍  Scan Egg Shop", 216, C.Accent)
local eggSendBtn = actionBtn(EggPage, "📤  Force Send to Discord", 256, C.Panel)
local eggSendStroke=Instance.new("UIStroke",eggSendBtn)
eggSendStroke.Color=C.Accent eggSendStroke.Thickness=1.5

local eggAutoRow=Instance.new("Frame",EggPage)
eggAutoRow.Size=UDim2.new(1,0,0,34) eggAutoRow.Position=UDim2.new(0,0,0,298)
eggAutoRow.BackgroundColor3=C.Card eggAutoRow.BorderSizePixel=0
Instance.new("UICorner",eggAutoRow).CornerRadius=UDim.new(0,7)
local eggAutoLbl=Instance.new("TextLabel",eggAutoRow)
eggAutoLbl.Size=UDim2.new(1,-100,1,0) eggAutoLbl.Position=UDim2.new(0,10,0,0)
eggAutoLbl.BackgroundTransparency=1 eggAutoLbl.Text="Auto-Scan (every 15s)"
eggAutoLbl.TextColor3=C.Text eggAutoLbl.TextSize=12
eggAutoLbl.Font=Enum.Font.GothamBold
eggAutoLbl.TextXAlignment=Enum.TextXAlignment.Left
local eggToggleBtn=Instance.new("TextButton",eggAutoRow)
eggToggleBtn.Size=UDim2.new(0,70,0,24) eggToggleBtn.Position=UDim2.new(1,-78,0.5,-12)
eggToggleBtn.BackgroundColor3=C.Border eggToggleBtn.Text="OFF"
eggToggleBtn.TextColor3=C.Sub eggToggleBtn.TextSize=12
eggToggleBtn.Font=Enum.Font.GothamBold eggToggleBtn.BorderSizePixel=0
Instance.new("UICorner",eggToggleBtn).CornerRadius=UDim.new(0,5)

-- ════════════════════════════════════════════════════════════════════
-- PAGE 3: WEBHOOK
-- ════════════════════════════════════════════════════════════════════
local WbPage = makePage()
hdr(WbPage, "  DISCORD WEBHOOK", 0)

local wbCard=Instance.new("Frame",WbPage)
wbCard.Size=UDim2.new(1,0,0,100) wbCard.Position=UDim2.new(0,0,0,18)
wbCard.BackgroundColor3=C.Card wbCard.BorderSizePixel=0
Instance.new("UICorner",wbCard).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",wbCard).Color=C.Border

local wbHint=Instance.new("TextLabel",wbCard)
wbHint.Size=UDim2.new(1,-16,0,20) wbHint.Position=UDim2.new(0,8,0,6)
wbHint.BackgroundTransparency=1
wbHint.Text="Paste your Discord Webhook URL:"
wbHint.TextColor3=C.Sub wbHint.TextSize=11
wbHint.Font=Enum.Font.GothamBold
wbHint.TextXAlignment=Enum.TextXAlignment.Left

local wbBox=Instance.new("TextBox",wbCard)
wbBox.Size=UDim2.new(1,-16,0,36) wbBox.Position=UDim2.new(0,8,0,30)
wbBox.BackgroundColor3=C.BG
wbBox.Text="" wbBox.PlaceholderText="https://discord.com/api/webhooks/..."
wbBox.TextColor3=C.Text wbBox.PlaceholderColor3=C.Sub
wbBox.TextSize=10 wbBox.Font=Enum.Font.Gotham
wbBox.TextXAlignment=Enum.TextXAlignment.Left
wbBox.ClearTextOnFocus=false wbBox.BorderSizePixel=0
Instance.new("UICorner",wbBox).CornerRadius=UDim.new(0,5)
Instance.new("UIPadding",wbBox).PaddingLeft=UDim.new(0,6)

local wbSaveBtn=actionBtn(wbCard,"💾  Save Webhook",66,C.Green)
wbSaveBtn.Size=UDim2.new(1,-16,0,26)
wbSaveBtn.Position=UDim2.new(0,8,0,68)
wbSaveBtn.TextSize=11

local wbStatus=Instance.new("TextLabel",WbPage)
wbStatus.Size=UDim2.new(1,0,0,20) wbStatus.Position=UDim2.new(0,0,0,124)
wbStatus.BackgroundTransparency=1 wbStatus.Text=""
wbStatus.TextColor3=C.Sub wbStatus.TextSize=11
wbStatus.Font=Enum.Font.GothamBold
wbStatus.TextXAlignment=Enum.TextXAlignment.Left

local testBtn=actionBtn(WbPage,"🧪  Test Webhook",148,C.Panel)
local testStroke=Instance.new("UIStroke",testBtn)
testStroke.Color=C.Accent testStroke.Thickness=1.5

local wbInfo=Instance.new("TextLabel",WbPage)
wbInfo.Size=UDim2.new(1,0,0,60) wbInfo.Position=UDim2.new(0,0,0,192)
wbInfo.BackgroundTransparency=1
wbInfo.Text="How to get webhook:\n1. Discord → Channel Settings\n2. Integrations → Webhooks\n3. New Webhook → Copy URL"
wbInfo.TextColor3=C.Sub wbInfo.TextSize=10
wbInfo.Font=Enum.Font.Gotham
wbInfo.TextXAlignment=Enum.TextXAlignment.Left
wbInfo.TextWrapped=true

-- ── Tab switching ─────────────────────────────────────────────────────────────
local allPages = {Gear=GearPage, Egg=EggPage, Webhook=WbPage}
local allTabBtns = {Gear=gearTabBtn, Egg=eggTabBtn, Webhook=wbTabBtn}
local allTabLbls = {Gear=gearTabLbl, Egg=eggTabLbl, Webhook=wbTabLbl}

local function switchTab(name)
    for k,p in pairs(allPages) do
        p.Visible=(k==name)
        TweenService:Create(allTabBtns[k],TweenInfo.new(0.15),{
            BackgroundColor3=(k==name) and C.Accent or C.Card
        }):Play()
        allTabLbls[k].TextColor3=(k==name) and C.Text or C.Sub
    end
end
gearTabBtn.MouseButton1Click:Connect(function() switchTab("Gear") end)
eggTabBtn.MouseButton1Click:Connect(function()  switchTab("Egg")  end)
wbTabBtn.MouseButton1Click:Connect(function()   switchTab("Webhook") end)
switchTab("Gear")

-- ── Status helpers ────────────────────────────────────────────────────────────
local totalScans = 0
local function setStatus(on)
    sideDot.BackgroundColor3 = on and C.Green or C.Red
    sideStatusLbl.Text = on and "Scanning..." or "Idle"
    sideStatusLbl.TextColor3 = on and C.Green or C.Sub
end
local function bumpScans()
    totalScans+=1
    sideScanLbl.Text="Scans: "..totalScans
    sideTimeLbl.Text="Last: "..os.date("%H:%M:%S")
end

-- ── Core scanner ─────────────────────────────────────────────────────────────
-- Reads all TextLabels from the game and matches against item list
local function scanForItems(itemList)
    local found = {}

    local function check(text, parent)
        if not text or #text < 3 then return end
        for _, itemName in ipairs(itemList) do
            if text == itemName then
                if not found[itemName] then
                    -- Try to grab price and description from siblings
                    local price, desc, stock = nil, nil, nil
                    if parent then
                        for _, sib in ipairs(parent:GetDescendants()) do
                            if sib:IsA("TextLabel") or sib:IsA("TextButton") then
                                local t = sib.Text or ""
                                -- Price pattern: $500K, $1M, $10B, $1T, $1qd
                                if t:match("^%$[%d%.]+[KMBTqd]") then price = t end
                                -- Stock pattern: Stock: 0
                                if t:match("Stock:") then stock = t end
                                -- Description (has spaces, not a name or price)
                                if #t > 10 and not t:match("^%$") and not t:match("Stock:")
                                    and t ~= itemName and not t:match("^BUY") then
                                    desc = t
                                end
                            end
                        end
                    end
                    found[itemName] = {price=price, desc=desc, stock=stock}
                end
            end
        end
    end

    -- Scan all GUI descendants
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            check(obj.Text or "", obj.Parent)
        end
    end
    -- Scan workspace too
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            check(obj.Text or "", obj.Parent)
        end
    end

    return found
end

-- ── Webhook sender ────────────────────────────────────────────────────────────
local function sendWebhook(found, shopName)
    if WEBHOOK_URL == "" then
        wbStatus.Text = "⚠️ No webhook set! Go to Webhook tab."
        switchTab("Webhook")
        return false
    end
    if not next(found) then return false end

    local lines = {}
    local hasRare = false
    local topColor = RARITY_INT.Common
    local tierOrder = {"Mythical","Legendary","Epic","Event","Rare","Uncommon","Common"}

    -- Sort by rarity
    local items = {}
    for name, data in pairs(found) do
        local rarity = guessRarity(name)
        if RARE_TIERS[rarity] then hasRare = true end
        table.insert(items, {name=name, rarity=rarity, price=data.price, desc=data.desc, stock=data.stock})
    end

    for _, tier in ipairs(tierOrder) do
        for _, item in ipairs(items) do
            if item.rarity == tier then topColor = RARITY_INT[tier] break end
        end
        if topColor ~= RARITY_INT.Common then break end
    end

    for _, item in ipairs(items) do
        local emoji = RARITY_EMOJI[item.rarity] or "⚪"
        local priceStr = item.price and (" · "..item.price) or ""
        local descStr = item.desc and ("\n  *"..item.desc.."*") or ""
        table.insert(lines, emoji.." **"..item.name.."** `"..item.rarity.."`"..priceStr..descStr)
    end

    local ok, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({
            content = hasRare and "🚨 **Rare item in stock!**" or nil,
            embeds = {{
                title = (shopName=="Egg" and "🥚" or "⚙️").." Build a Ring Farm — "..shopName.." Shop",
                description = "Live stock from in-game scan!",
                color = topColor,
                fields = {{
                    name  = shopName.." Shop Items",
                    value = #lines>0 and table.concat(lines,"\n") or "_Nothing found_",
                    inline= false,
                }},
                footer    = {text="BARF Stock Hub • Live Scan"},
                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        }), Enum.HttpContentType.ApplicationJson, false)
    end)

    return ok
end

-- ── Display found items ───────────────────────────────────────────────────────
local function displayItems(sc, lay, found)
    clearList(sc)
    if not next(found) then
        showEmpty(sc, lay, "  No items detected. Open the shop in-game!")
        return
    end
    local i=0
    for name, data in pairs(found) do
        local rarity = guessRarity(name)
        addRow(sc, lay, name, rarity, data.price, data.desc, data.stock)
        i+=1
    end
end

-- ── Gear scan logic ───────────────────────────────────────────────────────────
local lastGearKey = ""
local gearAuto = false
local gearThread = nil

local function doGearScan(force)
    setStatus(true) bumpScans()
    local found = scanForItems(GEAR_ITEMS)
    displayItems(gearSc, gearLay, found)

    local keys={} for n in pairs(found) do table.insert(keys,n) end
    table.sort(keys)
    local key=table.concat(keys,",")

    if (force or key~=lastGearKey) and key~="" then
        lastGearKey=key
        local ok = sendWebhook(found, "Gear")
        if ok then
            gearScanBtn.Text="✅ Sent to Discord!"
            task.delay(2, function() gearScanBtn.Text="🔍  Scan Gear Shop" end)
        end
    end
    setStatus(gearAuto)
end

-- ── Egg scan logic ────────────────────────────────────────────────────────────
local lastEggKey = ""
local eggAuto = false
local eggThread = nil

local function doEggScan(force)
    setStatus(true) bumpScans()
    local found = scanForItems(EGG_ITEMS)
    displayItems(eggSc, eggLay, found)

    local keys={} for n in pairs(found) do table.insert(keys,n) end
    table.sort(keys)
    local key=table.concat(keys,",")

    if (force or key~=lastEggKey) and key~="" then
        lastEggKey=key
        local ok = sendWebhook(found, "Egg")
        if ok then
            eggScanBtn.Text="✅ Sent to Discord!"
            task.delay(2, function() eggScanBtn.Text="🔍  Scan Egg Shop" end)
        end
    end
    setStatus(eggAuto)
end

-- ── Toggle helpers ────────────────────────────────────────────────────────────
local function setToggleBtn(btn, state)
    btn.Text = state and "ON" or "OFF"
    btn.BackgroundColor3 = state and C.Green or C.Border
    btn.TextColor3 = state and Color3.new(1,1,1) or C.Sub
end

-- ── Button wiring ─────────────────────────────────────────────────────────────
gearScanBtn.MouseButton1Click:Connect(function()
    gearScanBtn.Text="⏳ Scanning..."
    task.spawn(function() doGearScan(false) end)
end)
gearSendBtn.MouseButton1Click:Connect(function()
    gearSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        doGearScan(true)
        task.delay(2, function() gearSendBtn.Text="📤  Force Send to Discord" end)
    end)
end)
gearToggleBtn.MouseButton1Click:Connect(function()
    gearAuto = not gearAuto
    setToggleBtn(gearToggleBtn, gearAuto)
    if gearAuto then
        gearThread = task.spawn(function()
            while gearAuto do doGearScan(false) task.wait(15) end
        end)
    end
end)

eggScanBtn.MouseButton1Click:Connect(function()
    eggScanBtn.Text="⏳ Scanning..."
    task.spawn(function() doEggScan(false) end)
end)
eggSendBtn.MouseButton1Click:Connect(function()
    eggSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        doEggScan(true)
        task.delay(2, function() eggSendBtn.Text="📤  Force Send to Discord" end)
    end)
end)
eggToggleBtn.MouseButton1Click:Connect(function()
    eggAuto = not eggAuto
    setToggleBtn(eggToggleBtn, eggAuto)
    if eggAuto then
        eggThread = task.spawn(function()
            while eggAuto do doEggScan(false) task.wait(15) end
        end)
    end
end)

-- ── Webhook page buttons ──────────────────────────────────────────────────────
wbSaveBtn.MouseButton1Click:Connect(function()
    local url = wbBox.Text:gsub("%s+","")
    if url:find("discord.com/api/webhooks/") then
        WEBHOOK_URL = url
        wbStatus.Text = "✅ Webhook saved!"
        wbStatus.TextColor3 = C.Green
        sideDot.BackgroundColor3 = C.Accent
    else
        wbStatus.Text = "❌ Invalid URL. Must be a Discord webhook."
        wbStatus.TextColor3 = C.Red
    end
end)

testBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        wbStatus.Text="⚠️ Save a webhook first!"
        wbStatus.TextColor3=C.Red
        return
    end
    testBtn.Text="⏳ Testing..."
    local ok,err=pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, HttpService:JSONEncode({
            embeds={{
                title="✅ BARF Stock Hub — Webhook Test",
                description="Your webhook is connected and working!",
                color=3066993,
                footer={text="BARF Stock Hub"},
            }}
        }), Enum.HttpContentType.ApplicationJson, false)
    end)
    task.delay(1, function()
        testBtn.Text = ok and "✅ Webhook Works!" or "❌ Failed — check URL"
        wbStatus.Text = ok and "✅ Connected!" or "❌ Error: "..tostring(err)
        wbStatus.TextColor3 = ok and C.Green or C.Red
        task.delay(3, function() testBtn.Text="🧪  Test Webhook" end)
    end)
end)

-- ── Drag ─────────────────────────────────────────────────────────────────────
do
    local drag, ds, ws2
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            drag=true ds=i.Position ws2=Win.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Win.Position=UDim2.new(ws2.X.Scale,ws2.X.Offset+d.X,ws2.Y.Scale,ws2.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

print("[BARF Stock Hub v3] ✅ Loaded! Set your webhook in the Webhook tab first.")
