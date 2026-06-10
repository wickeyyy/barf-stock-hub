-- ╔═══════════════════════════════════════════════════════════════╗
-- ║         BARF Stock Hub v5                                    ║
-- ║         Manual Stock Reporter + Discord Notifier            ║
-- ╚═══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local lp               = Players.LocalPlayer
local pg               = lp:WaitForChild("PlayerGui")

if pg:FindFirstChild("BARFStockHub") then pg:FindFirstChild("BARFStockHub"):Destroy() end

local WEBHOOK_URL = ""

-- ── Item databases ────────────────────────────────────────────────────────────
-- Gear items sorted by price (cheapest first)
local GEAR_LIST = {
    {name="Normal Fertilizer",   price="$500K",  rarity="Common"},
    {name="Acid Spray",          price="$1M",    rarity="Common"},
    {name="Normal Pet Treat",    price="$1M",    rarity="Common"},
    {name="Wet Spray",           price="$10M",   rarity="Uncommon"},
    {name="Strong Fertilizer",   price="$50M",   rarity="Uncommon"},
    {name="Strong Pet Treat",    price="$75M",   rarity="Uncommon"},
    {name="Frozen Spray",        price="$750M",  rarity="Rare"},
    {name="Autumn Spray",        price="$1B",    rarity="Uncommon"},
    {name="Radioactive Spray",   price="$100B",  rarity="Rare"},
    {name="Super Pet Treat",     price="$20B",   rarity="Rare"},
    {name="Super Fertilizer",    price="$15B",   rarity="Rare"},
    {name="Void Spray",          price="$10B",   rarity="Mythical"},
    {name="Rainbow Spray",       price="$1T",    rarity="Legendary"},
    {name="Fire Spray",          price="$1qd",   rarity="Epic"},
    {name="Prismatic Fertilizer",price="$25T",   rarity="Epic"},
    {name="Cosmic Spray",        price="$25T",   rarity="Mythical"},
    {name="Bubblegum Spray",     price="$250T",  rarity="Epic"},
    {name="Mythic Fertilizer",   price="???",    rarity="Mythical"},
}

-- Seed items sorted cheapest first
local SEED_LIST = {
    {name="Carrot Seed",          price="$10",    rarity="Common"},
    {name="Strawberry Seed",      price="$25",    rarity="Common"},
    {name="Blueberry Seed",       price="$50",    rarity="Common"},
    {name="Orange Seed",          price="$75",    rarity="Common"},
    {name="Tomato Seed",          price="$100",   rarity="Common"},
    {name="Watermelon Seed",      price="$200",   rarity="Uncommon"},
    {name="Corn Seed",            price="$250",   rarity="Uncommon"},
    {name="Pumpkin Seed",         price="$500",   rarity="Uncommon"},
    {name="Golden Apple Seed",    price="$1K",    rarity="Rare"},
    {name="Dragon Fruit Seed",    price="$5K",    rarity="Rare"},
    {name="Cactus Seed",          price="$10K",   rarity="Rare"},
    {name="Rainbow Tulip Seed",   price="$50K",   rarity="Epic"},
    {name="Crystal Seed",         price="$100K",  rarity="Epic"},
    {name="Elder Strawberry Seed",price="$500K",  rarity="Legendary"},
    {name="Cosmic Rose Seed",     price="$1M",    rarity="Mythical"},
    {name="Void Seed",            price="$5M",    rarity="Mythical"},
    {name="Spring Onion Seed",    price="???",    rarity="Legendary"},
    {name="Beanstalk Seed",       price="???",    rarity="Epic"},
}

-- Egg slots (5 fixed slots)
local EGG_LIST = {
    {name="Common Egg",    price="$25M",  rarity="Common"},
    {name="Uncommon Egg",  price="$100M", rarity="Uncommon"},
    {name="Rare Egg",      price="$25B",  rarity="Rare"},
    {name="Epic Egg",      price="$10T",  rarity="Epic"},
    {name="Legendary Egg", price="$1qd",  rarity="Legendary"},
    {name="Mythical Egg",  price="$???",  rarity="Mythical"},
    {name="Event Egg",     price="$???",  rarity="Event"},
    {name="Bug Egg",       price="$???",  rarity="Event"},
    {name="Rainbow Egg",   price="$???",  rarity="Mythical"},
    {name="Cosmic Egg",    price="$???",  rarity="Mythical"},
    {name="Void Egg",      price="$???",  rarity="Mythical"},
    {name="Crystal Egg",   price="$???",  rarity="Rare"},
}

local RC={Common=Color3.fromRGB(180,180,180),Uncommon=Color3.fromRGB(60,200,100),
    Rare=Color3.fromRGB(80,150,255),Epic=Color3.fromRGB(180,100,255),
    Legendary=Color3.fromRGB(255,200,50),Mythical=Color3.fromRGB(255,80,80),
    Event=Color3.fromRGB(255,120,200)}
local RE={Common="⚪",Uncommon="🟢",Rare="🔵",Epic="🟣",Legendary="🟡",Mythical="🔴",Event="🌸"}
local RI={Common=9934743,Uncommon=3066993,Rare=3447003,Epic=10181046,Legendary=16750592,Mythical=15158332,Event=16711935}
local RARE={Epic=true,Legendary=true,Mythical=true,Event=true}

-- ── Theme ─────────────────────────────────────────────────────────────────────
local C={BG=Color3.fromRGB(15,15,20),Panel=Color3.fromRGB(22,22,30),
    Card=Color3.fromRGB(28,28,40),Sidebar=Color3.fromRGB(18,18,26),
    Accent=Color3.fromRGB(88,68,220),Green=Color3.fromRGB(50,200,100),
    Red=Color3.fromRGB(210,60,60),Text=Color3.fromRGB(235,235,255),
    Sub=Color3.fromRGB(130,130,165),Border=Color3.fromRGB(45,45,65)}

-- ── GUI Root ──────────────────────────────────────────────────────────────────
local sg=Instance.new("ScreenGui",pg)
sg.Name="BARFStockHub" sg.ResetOnSpawn=false sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling

local Win=Instance.new("Frame",sg)
Win.Size=UDim2.new(0,480,0,440) Win.Position=UDim2.new(0.5,-240,0.5,-220)
Win.BackgroundColor3=C.BG Win.BorderSizePixel=0 Win.ClipsDescendants=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,10)
local ws=Instance.new("UIStroke",Win) ws.Color=C.Border ws.Thickness=1.5

-- Topbar
local TB=Instance.new("Frame",Win)
TB.Size=UDim2.new(1,0,0,40) TB.BackgroundColor3=C.Panel TB.BorderSizePixel=0 TB.ZIndex=10
local td=Instance.new("Frame",TB)
td.Size=UDim2.new(0,10,0,10) td.Position=UDim2.new(0,14,0.5,-5)
td.BackgroundColor3=C.Accent td.BorderSizePixel=0
Instance.new("UICorner",td).CornerRadius=UDim.new(1,0)
local function tl(t,sz,col,x,y)
    local l=Instance.new("TextLabel",TB) l.Size=UDim2.new(0,260,0,sz+4)
    l.Position=UDim2.new(0,x,0,y) l.BackgroundTransparency=1 l.Text=t
    l.TextColor3=col l.TextSize=sz l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
end
tl("BARF Stock Hub",14,C.Text,30,5) tl("Manual Stock Reporter",10,C.Sub,30,22)

local function topBtn(xo,bg,t)
    local b=Instance.new("TextButton",TB) b.Size=UDim2.new(0,26,0,26)
    b.Position=UDim2.new(1,xo,0.5,-13) b.BackgroundColor3=bg b.Text=t
    b.TextColor3=Color3.new(1,1,1) b.TextSize=13 b.Font=Enum.Font.GothamBold
    b.BorderSizePixel=0 b.ZIndex=11
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5) return b
end
topBtn(-10,C.Red,"✕").MouseButton1Click:Connect(function() sg:Destroy() end)
local minBtn=topBtn(-42,C.Accent,"−")
local Body=Instance.new("Frame",Win)
Body.Size=UDim2.new(1,0,1,-40) Body.Position=UDim2.new(0,0,0,40) Body.BackgroundTransparency=1
local isMin=false
minBtn.MouseButton1Click:Connect(function()
    isMin=not isMin Body.Visible=not isMin
    TweenService:Create(Win,TweenInfo.new(0.2),{Size=isMin and UDim2.new(0,480,0,40) or UDim2.new(0,480,0,440)}):Play()
end)

-- Sidebar
local SB=Instance.new("Frame",Body)
SB.Size=UDim2.new(0,110,1,0) SB.BackgroundColor3=C.Sidebar SB.BorderSizePixel=0
local sbl=Instance.new("UIListLayout",SB) sbl.Padding=UDim.new(0,4) sbl.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",SB).PaddingTop=UDim.new(0,8)

local function sideTab(lbl,icon,order)
    local b=Instance.new("TextButton",SB) b.Size=UDim2.new(1,-8,0,38)
    b.BackgroundColor3=C.Card b.Text="" b.BorderSizePixel=0 b.LayoutOrder=order
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    local i=Instance.new("TextLabel",b) i.Size=UDim2.new(0,26,1,0) i.Position=UDim2.new(0,6,0,0)
    i.BackgroundTransparency=1 i.Text=icon i.TextSize=16 i.Font=Enum.Font.Gotham i.TextColor3=C.Text
    local t=Instance.new("TextLabel",b) t.Size=UDim2.new(1,-36,1,0) t.Position=UDim2.new(0,36,0,0)
    t.BackgroundTransparency=1 t.Text=lbl t.TextSize=11 t.Font=Enum.Font.GothamBold t.TextColor3=C.Sub
    t.TextXAlignment=Enum.TextXAlignment.Left return b,t
end

local gTab,gTabL=sideTab("Gear Shop","⚙️",1)
local sTab,sTabL=sideTab("Seed Shop","🌱",2)
local eTab,eTabL=sideTab("Egg Shop","🥚",3)
local wTab,wTabL=sideTab("Webhook","🔗",4)

-- Timer in sidebar
local timerCard=Instance.new("Frame",SB)
timerCard.Size=UDim2.new(1,-8,0,54) timerCard.BackgroundColor3=C.Card
timerCard.BorderSizePixel=0 timerCard.LayoutOrder=10
Instance.new("UICorner",timerCard).CornerRadius=UDim.new(0,7)
local timerDot=Instance.new("Frame",timerCard)
timerDot.Size=UDim2.new(0,8,0,8) timerDot.Position=UDim2.new(0,8,0,8)
timerDot.BackgroundColor3=C.Accent timerDot.BorderSizePixel=0
Instance.new("UICorner",timerDot).CornerRadius=UDim.new(1,0)
local function ssl(t,sz,y)
    local l=Instance.new("TextLabel",timerCard) l.Size=UDim2.new(1,-8,0,14)
    l.Position=UDim2.new(0,8,0,y) l.BackgroundTransparency=1 l.Text=t
    l.TextColor3=C.Sub l.TextSize=sz l.Font=Enum.Font.Gotham
    l.TextXAlignment=Enum.TextXAlignment.Left return l
end
local timerLbl=ssl("Next: --",11,20)
local timerSub=ssl("Auto: OFF",9,36)

-- Content
local CT=Instance.new("Frame",Body)
CT.Size=UDim2.new(1,-118,1,-8) CT.Position=UDim2.new(0,114,0,4) CT.BackgroundTransparency=1

local function makePage()
    local f=Instance.new("Frame",CT) f.Size=UDim2.new(1,0,1,0)
    f.BackgroundTransparency=1 f.Visible=false return f
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function hdr(p,t,y)
    local l=Instance.new("TextLabel",p) l.Size=UDim2.new(1,0,0,14)
    l.Position=UDim2.new(0,0,0,y) l.BackgroundTransparency=1 l.Text=t
    l.TextColor3=C.Sub l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
end
local function abtn(p,t,y,bg,h)
    local b=Instance.new("TextButton",p) b.Size=UDim2.new(1,0,0,h or 32)
    b.Position=UDim2.new(0,0,0,y) b.BackgroundColor3=bg or C.Accent b.Text=t
    b.TextColor3=Color3.new(1,1,1) b.TextSize=12 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7) return b
end
local function mklist(p,y,h)
    local bg=Instance.new("Frame",p) bg.Size=UDim2.new(1,0,0,h)
    bg.Position=UDim2.new(0,0,0,y) bg.BackgroundColor3=C.Card
    bg.BorderSizePixel=0 bg.ClipsDescendants=true
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",bg).Color=C.Border
    local sc=Instance.new("ScrollingFrame",bg)
    sc.Size=UDim2.new(1,-4,1,-4) sc.Position=UDim2.new(0,2,0,2)
    sc.BackgroundTransparency=1 sc.BorderSizePixel=0
    sc.ScrollBarThickness=2 sc.ScrollBarImageColor3=C.Accent
    local lay=Instance.new("UIListLayout",sc)
    lay.Padding=UDim.new(0,2) lay.SortOrder=Enum.SortOrder.LayoutOrder
    return sc,lay
end

-- Checkbox row for selecting items
local function makeCheckRow(parent, item, index, checkedTable, onChange)
    local rarity=item.rarity or "Common"
    local col=RC[rarity] or C.Sub
    local row=Instance.new("Frame",parent)
    row.Size=UDim2.new(1,-4,0,28) row.BackgroundTransparency=1
    row.LayoutOrder=index row.BorderSizePixel=0

    local check=Instance.new("TextButton",row)
    check.Size=UDim2.new(0,20,0,20) check.Position=UDim2.new(0,2,0.5,-10)
    check.BackgroundColor3=C.Border check.Text="" check.BorderSizePixel=0
    Instance.new("UICorner",check).CornerRadius=UDim.new(0,4)

    local checkMark=Instance.new("TextLabel",check)
    checkMark.Size=UDim2.new(1,0,1,0) checkMark.BackgroundTransparency=1
    checkMark.Text="" checkMark.TextColor3=Color3.new(1,1,1)
    checkMark.TextSize=14 checkMark.Font=Enum.Font.GothamBold

    local nameLbl=Instance.new("TextLabel",row)
    nameLbl.Size=UDim2.new(1,-120,1,0) nameLbl.Position=UDim2.new(0,28,0,0)
    nameLbl.BackgroundTransparency=1 nameLbl.Text=(RE[rarity] or "⚪").." "..item.name
    nameLbl.TextColor3=col nameLbl.TextSize=11 nameLbl.Font=Enum.Font.GothamBold
    nameLbl.TextXAlignment=Enum.TextXAlignment.Left

    local priceLbl=Instance.new("TextLabel",row)
    priceLbl.Size=UDim2.new(0,55,1,0) priceLbl.Position=UDim2.new(1,-58,0,0)
    priceLbl.BackgroundTransparency=1 priceLbl.Text=item.price or ""
    priceLbl.TextColor3=Color3.fromRGB(100,220,100) priceLbl.TextSize=10
    priceLbl.Font=Enum.Font.GothamBold priceLbl.TextXAlignment=Enum.TextXAlignment.Right

    local checked=false
    local function setCheck(v)
        checked=v checkedTable[item.name]=v
        check.BackgroundColor3=v and C.Green or C.Border
        checkMark.Text=v and "✓" or ""
        if onChange then onChange() end
    end
    check.MouseButton1Click:Connect(function() setCheck(not checked) end)
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then setCheck(not checked) end
    end)
    return row, setCheck
end

-- ── HTTP via coroutine ────────────────────────────────────────────────────────
local function httpPost(url,body)
    local ok,err=false,"timeout"
    local done=false
    coroutine.wrap(function()
        ok,err=pcall(function()
            HttpService:PostAsync(url,body,Enum.HttpContentType.ApplicationJson,false)
        end)
        done=true
    end)()
    local t=0
    while not done and t<6 do RunService.Heartbeat:Wait() t=t+0.05 end
    return ok,err
end

-- ── Send webhook ──────────────────────────────────────────────────────────────
local function sendWebhook(selectedItems, shopName, allList)
    if WEBHOOK_URL=="" then return false,"no webhook" end
    local lines={} local hasRare=false local topColor=RI.Common
    local tierOrder={"Mythical","Legendary","Epic","Event","Rare","Uncommon","Common"}

    -- Filter to only selected, keep original sort order (cheapest first)
    local items={}
    for _,item in ipairs(allList) do
        if selectedItems[item.name] then
            table.insert(items,item)
            if RARE[item.rarity] then hasRare=true end
        end
    end

    if #items==0 then return false,"nothing selected" end

    for _,tier in ipairs(tierOrder) do
        for _,it in ipairs(items) do
            if it.rarity==tier then topColor=RI[tier] or topColor break end
        end
        if topColor~=RI.Common then break end
    end

    for _,it in ipairs(items) do
        local emoji=RE[it.rarity] or "⚪"
        table.insert(lines,emoji.." **"..it.name.."** `"..it.rarity.."` · "..it.price)
    end

    local icons={Gear="⚙️",Seed="🌱",Egg="🥚"}
    local payload=HttpService:JSONEncode({
        content=hasRare and "🚨 **Rare item in stock!**" or nil,
        embeds={{
            title=(icons[shopName] or "📦").." BARF — "..shopName.." Shop Stock",
            description="Stock updated · "..os.date("%H:%M"),
            color=topColor,
            fields={{
                name="Available Items ("..#items..")",
                value=table.concat(lines,"\n"),
                inline=false
            }},
            footer={text="BARF Stock Hub • Manual Report"},
            timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })
    return httpPost(WEBHOOK_URL,payload)
end

-- ── GEAR PAGE ─────────────────────────────────────────────────────────────────
local GP=makePage()
hdr(GP,"  GEAR SHOP — tick what's available",0)
local gSc,gLay=mklist(GP,16,270)
local gChecked={}
local gSendBtn=abtn(GP,"📤  Send Gear Stock to Discord",292,C.Accent)
local gClearBtn=abtn(GP,"🗑  Clear All",330,C.Panel,26)
Instance.new("UIStroke",gClearBtn).Color=C.Red

-- Populate gear checkboxes
for i,item in ipairs(GEAR_LIST) do
    makeCheckRow(gSc,item,i,gChecked,nil)
end
gSc.CanvasSize=UDim2.new(0,0,0,#GEAR_LIST*30+4)

gSendBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        gSendBtn.Text="⚠️ Set webhook first!"
        task.delay(2,function() gSendBtn.Text="📤  Send Gear Stock to Discord" end) return
    end
    gSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        local ok=sendWebhook(gChecked,"Gear",GEAR_LIST)
        gSendBtn.Text=ok and "✅ Sent!" or "❌ Failed"
        task.delay(2,function() gSendBtn.Text="📤  Send Gear Stock to Discord" end)
    end)
end)
gClearBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(gSc:GetChildren()) do
        if c:IsA("Frame") then
            local cb=c:FindFirstChildOfClass("TextButton")
            if cb then
                cb.BackgroundColor3=C.Border
                local cm=cb:FindFirstChildOfClass("TextLabel")
                if cm then cm.Text="" end
            end
        end
    end
    for k in pairs(gChecked) do gChecked[k]=false end
end)

-- ── SEED PAGE ─────────────────────────────────────────────────────────────────
local SP=makePage()
hdr(SP,"  SEED SHOP — tick what's available (cheapest→expensive)",0)
local sSc,sLay=mklist(SP,16,270)
local sChecked={}
local sSendBtn=abtn(SP,"📤  Send Seed Stock to Discord",292,C.Accent)
local sClearBtn=abtn(SP,"🗑  Clear All",330,C.Panel,26)
Instance.new("UIStroke",sClearBtn).Color=C.Red

for i,item in ipairs(SEED_LIST) do
    makeCheckRow(sSc,item,i,sChecked,nil)
end
sSc.CanvasSize=UDim2.new(0,0,0,#SEED_LIST*30+4)

sSendBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        sSendBtn.Text="⚠️ Set webhook first!"
        task.delay(2,function() sSendBtn.Text="📤  Send Seed Stock to Discord" end) return
    end
    sSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        local ok=sendWebhook(sChecked,"Seed",SEED_LIST)
        sSendBtn.Text=ok and "✅ Sent!" or "❌ Failed"
        task.delay(2,function() sSendBtn.Text="📤  Send Seed Stock to Discord" end)
    end)
end)
sClearBtn.MouseButton1Click:Connect(function()
    for _,c in ipairs(sSc:GetChildren()) do
        if c:IsA("Frame") then
            local cb=c:FindFirstChildOfClass("TextButton")
            if cb then
                cb.BackgroundColor3=C.Border
                local cm=cb:FindFirstChildOfClass("TextLabel")
                if cm then cm.Text="" end
            end
        end
    end
    for k in pairs(sChecked) do sChecked[k]=false end
end)

-- ── EGG PAGE ──────────────────────────────────────────────────────────────────
local EP=makePage()
hdr(EP,"  EGG SHOP — 5 slots (pick what's in each slot)",0)

-- 5 egg slot dropdowns
local eggSlots={nil,nil,nil,nil,nil} -- stores selected egg name per slot
local eggOptions={"(empty)"}
for _,e in ipairs(EGG_LIST) do table.insert(eggOptions,e.name) end

local function getEggRarity(name)
    for _,e in ipairs(EGG_LIST) do
        if e.name==name then return e.rarity,e.price end
    end
    return "Common","???"
end

local slotFrames={}
for slot=1,5 do
    local sf=Instance.new("Frame",EP)
    sf.Size=UDim2.new(1,0,0,48)
    sf.Position=UDim2.new(0,0,0,16+(slot-1)*52)
    sf.BackgroundColor3=C.Card sf.BorderSizePixel=0
    Instance.new("UICorner",sf).CornerRadius=UDim.new(0,7)
    Instance.new("UIStroke",sf).Color=C.Border

    local slotLbl=Instance.new("TextLabel",sf)
    slotLbl.Size=UDim2.new(0,50,1,0) slotLbl.Position=UDim2.new(0,8,0,0)
    slotLbl.BackgroundTransparency=1 slotLbl.Text="Slot "..slot
    slotLbl.TextColor3=C.Sub slotLbl.TextSize=11 slotLbl.Font=Enum.Font.GothamBold
    slotLbl.TextXAlignment=Enum.TextXAlignment.Left

    -- Cycle button (click to go through egg options)
    local idx=1
    local eggBtn=Instance.new("TextButton",sf)
    eggBtn.Size=UDim2.new(1,-68,0,30) eggBtn.Position=UDim2.new(0,58,0.5,-15)
    eggBtn.BackgroundColor3=C.Panel eggBtn.Text="(empty)"
    eggBtn.TextColor3=C.Sub eggBtn.TextSize=11 eggBtn.Font=Enum.Font.GothamBold
    eggBtn.BorderSizePixel=0
    Instance.new("UICorner",eggBtn).CornerRadius=UDim.new(0,5)
    Instance.new("UIStroke",eggBtn).Color=C.Border

    local arrowBtn=Instance.new("TextButton",sf)
    arrowBtn.Size=UDim2.new(0,30,0,30) arrowBtn.Position=UDim2.new(1,-38,0.5,-15)
    arrowBtn.BackgroundColor3=C.Accent arrowBtn.Text="▶"
    arrowBtn.TextColor3=Color3.new(1,1,1) arrowBtn.TextSize=12
    arrowBtn.Font=Enum.Font.GothamBold arrowBtn.BorderSizePixel=0
    Instance.new("UICorner",arrowBtn).CornerRadius=UDim.new(0,5)

    local function updateSlot()
        local name=eggOptions[idx]
        eggSlots[slot]=name~="(empty)" and name or nil
        if name=="(empty)" then
            eggBtn.Text="(empty)" eggBtn.TextColor3=C.Sub
            eggBtn.BackgroundColor3=C.Panel
        else
            local r,_=getEggRarity(name)
            local col=RC[r] or C.Sub
            eggBtn.Text=(RE[r] or "⚪").." "..name
            eggBtn.TextColor3=col
            eggBtn.BackgroundColor3=C.BG
        end
    end

    arrowBtn.MouseButton1Click:Connect(function()
        idx=idx%#eggOptions+1 updateSlot()
    end)
    eggBtn.MouseButton1Click:Connect(function()
        idx=idx%#eggOptions+1 updateSlot()
    end)

    table.insert(slotFrames,sf)
end

local eSendBtn=abtn(EP,"📤  Send Egg Stock to Discord",282,C.Accent)
local eClearBtn=abtn(EP,"🗑  Clear All Slots",320,C.Panel,26)
Instance.new("UIStroke",eClearBtn).Color=C.Red

eSendBtn.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        eSendBtn.Text="⚠️ Set webhook first!"
        task.delay(2,function() eSendBtn.Text="📤  Send Egg Stock to Discord" end) return
    end
    -- Build lines from filled slots
    local lines={} local hasRare=false local topColor=RI.Common
    local tierOrder={"Mythical","Legendary","Epic","Event","Rare","Uncommon","Common"}
    for i,name in ipairs(eggSlots) do
        if name then
            local r,price=getEggRarity(name)
            if RARE[r] then hasRare=true end
            for _,tier in ipairs(tierOrder) do
                if r==tier then topColor=RI[tier] or topColor break end
            end
            table.insert(lines,"**Slot "..i.."** · "..(RE[r] or "⚪").." **"..name.."** `"..r.."` · "..price)
        end
    end
    if #lines==0 then
        eSendBtn.Text="⚠️ No eggs selected!" task.delay(2,function() eSendBtn.Text="📤  Send Egg Stock to Discord" end) return
    end
    eSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        local payload=HttpService:JSONEncode({
            content=hasRare and "🚨 **Rare egg in stock!**" or nil,
            embeds={{
                title="🥚 BARF — Egg Shop Stock",
                description="Egg shop updated · "..os.date("%H:%M"),
                color=topColor,
                fields={{name="Egg Slots ("..#lines.."/5)",value=table.concat(lines,"\n"),inline=false}},
                footer={text="BARF Stock Hub • Manual Report"},
                timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
            }}
        })
        local ok=httpPost(WEBHOOK_URL,payload)
        eSendBtn.Text=ok and "✅ Sent!" or "❌ Failed"
        task.delay(2,function() eSendBtn.Text="📤  Send Egg Stock to Discord" end)
    end)
end)
eClearBtn.MouseButton1Click:Connect(function()
    for i=1,5 do
        eggSlots[i]=nil
        local sf=slotFrames[i]
        if sf then
            local eb=sf:FindFirstChildOfClass("TextButton")
            if eb then eb.Text="(empty)" eb.TextColor3=C.Sub eb.BackgroundColor3=C.Panel end
        end
    end
end)

-- ── WEBHOOK PAGE ──────────────────────────────────────────────────────────────
local WP=makePage()
hdr(WP,"  DISCORD WEBHOOK",0)
local wCard=Instance.new("Frame",WP) wCard.Size=UDim2.new(1,0,0,96)
wCard.Position=UDim2.new(0,0,0,16) wCard.BackgroundColor3=C.Card wCard.BorderSizePixel=0
Instance.new("UICorner",wCard).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",wCard).Color=C.Border
local wHint=Instance.new("TextLabel",wCard) wHint.Size=UDim2.new(1,-16,0,18)
wHint.Position=UDim2.new(0,8,0,6) wHint.BackgroundTransparency=1
wHint.Text="Paste your Discord Webhook URL:" wHint.TextColor3=C.Sub
wHint.TextSize=11 wHint.Font=Enum.Font.GothamBold wHint.TextXAlignment=Enum.TextXAlignment.Left
local wBox=Instance.new("TextBox",wCard) wBox.Size=UDim2.new(1,-16,0,32)
wBox.Position=UDim2.new(0,8,0,26) wBox.BackgroundColor3=C.BG wBox.Text=""
wBox.PlaceholderText="https://discord.com/api/webhooks/..." wBox.TextColor3=C.Text
wBox.PlaceholderColor3=C.Sub wBox.TextSize=9 wBox.Font=Enum.Font.Gotham
wBox.TextXAlignment=Enum.TextXAlignment.Left wBox.ClearTextOnFocus=false wBox.BorderSizePixel=0
Instance.new("UICorner",wBox).CornerRadius=UDim.new(0,5)
Instance.new("UIPadding",wBox).PaddingLeft=UDim.new(0,6)
local wSave=abtn(wCard,"💾  Save Webhook",62,C.Green,26)
wSave.Size=UDim2.new(1,-16,0,26) wSave.Position=UDim2.new(0,8,0,64) wSave.TextSize=11
local wStatus=Instance.new("TextLabel",WP) wStatus.Size=UDim2.new(1,0,0,18)
wStatus.Position=UDim2.new(0,0,0,118) wStatus.BackgroundTransparency=1
wStatus.Text="No webhook saved." wStatus.TextColor3=C.Sub
wStatus.TextSize=11 wStatus.Font=Enum.Font.GothamBold wStatus.TextXAlignment=Enum.TextXAlignment.Left
local wTest=abtn(WP,"🧪  Test Webhook",140,C.Panel)
Instance.new("UIStroke",wTest).Color=C.Accent
local wInfo=Instance.new("TextLabel",WP) wInfo.Size=UDim2.new(1,0,0,80)
wInfo.Position=UDim2.new(0,0,0,180) wInfo.BackgroundTransparency=1
wInfo.Text="How to get a webhook URL:\n1. Open Discord → go to your stock channel\n2. Click ⚙️ Edit Channel → Integrations\n3. Webhooks → New Webhook → Copy Webhook URL\n4. Paste it above and click Save"
wInfo.TextColor3=C.Sub wInfo.TextSize=10 wInfo.Font=Enum.Font.Gotham
wInfo.TextXAlignment=Enum.TextXAlignment.Left wInfo.TextWrapped=true

wSave.MouseButton1Click:Connect(function()
    local url=wBox.Text:gsub("%s+","")
    if url:find("discord.com/api/webhooks/") then
        WEBHOOK_URL=url wStatus.Text="✅ Webhook saved!" wStatus.TextColor3=C.Green
    else
        wStatus.Text="❌ Invalid — must be a Discord webhook URL" wStatus.TextColor3=C.Red
    end
end)
wTest.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then wStatus.Text="⚠️ Save a webhook first!" wStatus.TextColor3=C.Red return end
    wTest.Text="⏳ Testing..."
    task.spawn(function()
        local ok,err=httpPost(WEBHOOK_URL,HttpService:JSONEncode({
            embeds={{title="✅ BARF Stock Hub — Test",description="Webhook working!",color=3066993,footer={text="BARF Stock Hub"}}}
        }))
        wTest.Text=ok and "✅ Works!" or "❌ Failed"
        wStatus.Text=ok and "✅ Connected!" or "❌ "..tostring(err)
        wStatus.TextColor3=ok and C.Green or C.Red
        task.delay(3,function() wTest.Text="🧪  Test Webhook" end)
    end)
end)

-- ── Tab switching ─────────────────────────────────────────────────────────────
local tabs={Gear={GP,gTab,gTabL},Seed={SP,sTab,sTabL},Egg={EP,eTab,eTabL},Webhook={WP,wTab,wTabL}}
local function switchTab(n)
    for k,v in pairs(tabs) do
        v[1].Visible=(k==n)
        TweenService:Create(v[2],TweenInfo.new(0.15),{BackgroundColor3=(k==n) and C.Accent or C.Card}):Play()
        v[3].TextColor3=(k==n) and C.Text or C.Sub
    end
end
gTab.MouseButton1Click:Connect(function() switchTab("Gear") end)
sTab.MouseButton1Click:Connect(function() switchTab("Seed") end)
eTab.MouseButton1Click:Connect(function() switchTab("Egg")  end)
wTab.MouseButton1Click:Connect(function() switchTab("Webhook") end)
switchTab("Gear")

-- ── 5-minute restock countdown ────────────────────────────────────────────────
task.spawn(function()
    while true do
        local now=os.time()
        local sec=now%300
        local wait=300-sec
        for i=wait,1,-1 do
            local m=math.floor(i/60) local s=i%60
            timerLbl.Text=string.format("Next: %d:%02d",m,s)
            task.wait(1)
        end
        timerLbl.Text="🔄 Restocking!"
        timerDot.BackgroundColor3=C.Green
        task.wait(8)
        timerDot.BackgroundColor3=C.Accent
    end
end)

-- ── Drag ─────────────────────────────────────────────────────────────────────
do
    local drag,ds,wp
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true ds=i.Position wp=Win.Position end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Win.Position=UDim2.new(wp.X.Scale,wp.X.Offset+d.X,wp.Y.Scale,wp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
end

print("[BARF Stock Hub v5] Loaded!")
