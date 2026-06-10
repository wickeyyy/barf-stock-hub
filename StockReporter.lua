-- ╔═══════════════════════════════════════════════════════════════╗
-- ║         BARF Stock Hub v4                                    ║
-- ║         Gear Shop & Egg Shop Notifier                       ║
-- ╚═══════════════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")
local lp               = Players.LocalPlayer
local pg               = lp:WaitForChild("PlayerGui")

if pg:FindFirstChild("BARFStockHub") then pg:FindFirstChild("BARFStockHub"):Destroy() end

-- ── Webhook ───────────────────────────────────────────────────────────────────
local WEBHOOK_URL = ""

-- ── Known real item names (from actual game screenshots) ─────────────────────
local GEAR_NAMES = {
    "Normal Fertilizer","Strong Fertilizer","Super Fertilizer",
    "Prismatic Fertilizer","Mythic Fertilizer",
    "Acid Spray","Wet Spray","Frozen Spray","Autumn Spray",
    "Radioactive Spray","Fire Spray","Void Spray","Rainbow Spray",
    "Bubblegum Spray","Cosmic Spray","Normal Spray",
    "Normal Pet Treat","Strong Pet Treat","Super Pet Treat",
}

local EGG_NAMES = {
    "Common Egg","Uncommon Egg","Rare Egg","Epic Egg",
    "Legendary Egg","Mythical Egg","Event Egg","Bug Egg",
    "Rainbow Egg","Cosmic Egg","Void Egg","Crystal Egg",
    "Prismatic Egg","Star Egg","Golden Egg","Green Egg","Blue Egg",
}

local function guessRarity(n)
    n = n:lower()
    if n:find("mythic") or n:find("void") or n:find("cosmic") then return "Mythical"
    elseif n:find("legendary") or n:find("rainbow") or n:find("prismatic") then return "Legendary"
    elseif n:find("epic") or n:find("bubblegum") or n:find("fire") then return "Epic"
    elseif n:find("rare") or n:find("super") or n:find("frozen") or n:find("radioactive") then return "Rare"
    elseif n:find("uncommon") or n:find("strong") or n:find("wet") or n:find("autumn") then return "Uncommon"
    else return "Common" end
end

local RC = {
    Common=Color3.fromRGB(180,180,180), Uncommon=Color3.fromRGB(60,200,100),
    Rare=Color3.fromRGB(80,150,255),    Epic=Color3.fromRGB(180,100,255),
    Legendary=Color3.fromRGB(255,200,50), Mythical=Color3.fromRGB(255,80,80),
    Event=Color3.fromRGB(255,120,200),
}
local RE = {Common="⚪",Uncommon="🟢",Rare="🔵",Epic="🟣",Legendary="🟡",Mythical="🔴",Event="🌸"}
local RI = {Common=9934743,Uncommon=3066993,Rare=3447003,Epic=10181046,Legendary=16750592,Mythical=15158332,Event=16711935}
local RARE = {Epic=true,Legendary=true,Mythical=true,Event=true}

-- ── Theme ─────────────────────────────────────────────────────────────────────
local C = {
    BG=Color3.fromRGB(15,15,20),     Panel=Color3.fromRGB(22,22,30),
    Card=Color3.fromRGB(28,28,40),   Sidebar=Color3.fromRGB(18,18,26),
    Accent=Color3.fromRGB(88,68,220),Green=Color3.fromRGB(50,200,100),
    Red=Color3.fromRGB(210,60,60),   Text=Color3.fromRGB(235,235,255),
    Sub=Color3.fromRGB(130,130,165), Border=Color3.fromRGB(45,45,65),
}

-- ── GUI Root ──────────────────────────────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name="BARFStockHub" sg.ResetOnSpawn=false
sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling sg.Parent=pg

local Win = Instance.new("Frame",sg)
Win.Size=UDim2.new(0,460,0,400) Win.Position=UDim2.new(0.5,-230,0.5,-200)
Win.BackgroundColor3=C.BG Win.BorderSizePixel=0 Win.ClipsDescendants=true
Instance.new("UICorner",Win).CornerRadius=UDim.new(0,10)
local ws=Instance.new("UIStroke",Win) ws.Color=C.Border ws.Thickness=1.5

-- Topbar
local TB=Instance.new("Frame",Win)
TB.Size=UDim2.new(1,0,0,40) TB.BackgroundColor3=C.Panel TB.BorderSizePixel=0 TB.ZIndex=10
local tdot=Instance.new("Frame",TB)
tdot.Size=UDim2.new(0,10,0,10) tdot.Position=UDim2.new(0,14,0.5,-5)
tdot.BackgroundColor3=C.Accent tdot.BorderSizePixel=0
Instance.new("UICorner",tdot).CornerRadius=UDim.new(1,0)
local function tl(txt,sz,col,x,y)
    local l=Instance.new("TextLabel",TB)
    l.Size=UDim2.new(0,250,0,sz+4) l.Position=UDim2.new(0,x,0,y)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=col
    l.TextSize=sz l.Font=Enum.Font.GothamBold l.TextXAlignment=Enum.TextXAlignment.Left
end
tl("BARF Stock Hub",14,C.Text,30,5)
tl("Gear Shop & Egg Shop Notifier",10,C.Sub,30,22)

local function topBtn(xo,bg,txt)
    local b=Instance.new("TextButton",TB)
    b.Size=UDim2.new(0,26,0,26) b.Position=UDim2.new(1,xo,0.5,-13)
    b.BackgroundColor3=bg b.Text=txt b.TextColor3=Color3.new(1,1,1)
    b.TextSize=13 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0 b.ZIndex=11
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
    return b
end
topBtn(-10,C.Red,"✕").MouseButton1Click:Connect(function() sg:Destroy() end)
local minBtn=topBtn(-42,C.Accent,"−")

local Body=Instance.new("Frame",Win)
Body.Size=UDim2.new(1,0,1,-40) Body.Position=UDim2.new(0,0,0,40) Body.BackgroundTransparency=1
local isMin=false
minBtn.MouseButton1Click:Connect(function()
    isMin=not isMin Body.Visible=not isMin
    TweenService:Create(Win,TweenInfo.new(0.2),{Size=isMin and UDim2.new(0,460,0,40) or UDim2.new(0,460,0,400)}):Play()
end)

-- Sidebar
local SB=Instance.new("Frame",Body)
SB.Size=UDim2.new(0,110,1,0) SB.BackgroundColor3=C.Sidebar SB.BorderSizePixel=0
local sbl=Instance.new("UIListLayout",SB) sbl.Padding=UDim.new(0,4) sbl.SortOrder=Enum.SortOrder.LayoutOrder
Instance.new("UIPadding",SB).PaddingTop=UDim.new(0,8)

local function sideTab(lbl,icon,order)
    local b=Instance.new("TextButton",SB)
    b.Size=UDim2.new(1,-8,0,38) b.BackgroundColor3=C.Card b.Text="" b.BorderSizePixel=0 b.LayoutOrder=order
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    local i=Instance.new("TextLabel",b)
    i.Size=UDim2.new(0,26,1,0) i.Position=UDim2.new(0,6,0,0) i.BackgroundTransparency=1
    i.Text=icon i.TextSize=18 i.Font=Enum.Font.Gotham i.TextColor3=C.Text
    local t=Instance.new("TextLabel",b)
    t.Size=UDim2.new(1,-36,1,0) t.Position=UDim2.new(0,36,0,0) t.BackgroundTransparency=1
    t.Text=lbl t.TextSize=11 t.Font=Enum.Font.GothamBold t.TextColor3=C.Sub
    t.TextXAlignment=Enum.TextXAlignment.Left
    return b,t
end

local gTab,gTabL = sideTab("Gear Shop","⚙️",1)
local eTab,eTabL = sideTab("Egg Shop","🥚",2)
local wTab,wTabL = sideTab("Webhook","🔗",3)

-- Sidebar status box
local ss=Instance.new("Frame",SB)
ss.Size=UDim2.new(1,-8,0,70) ss.BackgroundColor3=C.Card ss.BorderSizePixel=0 ss.LayoutOrder=10
Instance.new("UICorner",ss).CornerRadius=UDim.new(0,7)
local ssDot=Instance.new("Frame",ss)
ssDot.Size=UDim2.new(0,8,0,8) ssDot.Position=UDim2.new(0,8,0,8)
ssDot.BackgroundColor3=C.Red ssDot.BorderSizePixel=0
Instance.new("UICorner",ssDot).CornerRadius=UDim.new(1,0)
local function ssl(txt,sz,y)
    local l=Instance.new("TextLabel",ss)
    l.Size=UDim2.new(1,-8,0,14) l.Position=UDim2.new(0,8,0,y)
    l.BackgroundTransparency=1 l.Text=txt l.TextColor3=C.Sub
    l.TextSize=sz l.Font=Enum.Font.Gotham l.TextXAlignment=Enum.TextXAlignment.Left
    return l
end
local ssLbl  = ssl("Idle",11,20)
local ssScan = ssl("Scans: 0",10,36)
local ssTime = ssl("Next: --",9,50)

-- Content
local CT=Instance.new("Frame",Body)
CT.Size=UDim2.new(1,-118,1,-8) CT.Position=UDim2.new(0,114,0,4) CT.BackgroundTransparency=1

local function page()
    local f=Instance.new("Frame",CT)
    f.Size=UDim2.new(1,0,1,0) f.BackgroundTransparency=1 f.Visible=false
    return f
end
local function hdr(p,txt,y)
    local l=Instance.new("TextLabel",p)
    l.Size=UDim2.new(1,0,0,16) l.Position=UDim2.new(0,0,0,y) l.BackgroundTransparency=1
    l.Text=txt l.TextColor3=C.Sub l.TextSize=10 l.Font=Enum.Font.GothamBold
    l.TextXAlignment=Enum.TextXAlignment.Left
end
local function abtn(p,txt,y,bg)
    local b=Instance.new("TextButton",p)
    b.Size=UDim2.new(1,0,0,32) b.Position=UDim2.new(0,0,0,y)
    b.BackgroundColor3=bg or C.Accent b.Text=txt b.TextColor3=Color3.new(1,1,1)
    b.TextSize=12 b.Font=Enum.Font.GothamBold b.BorderSizePixel=0
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,7)
    return b
end
local function mklist(p,y,h)
    local bg=Instance.new("Frame",p)
    bg.Size=UDim2.new(1,0,0,h) bg.Position=UDim2.new(0,0,0,y)
    bg.BackgroundColor3=C.Card bg.BorderSizePixel=0 bg.ClipsDescendants=true
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,8)
    Instance.new("UIStroke",bg).Color=C.Border
    local sc=Instance.new("ScrollingFrame",bg)
    sc.Size=UDim2.new(1,-4,1,-6) sc.Position=UDim2.new(0,2,0,3)
    sc.BackgroundTransparency=1 sc.BorderSizePixel=0
    sc.ScrollBarThickness=2 sc.ScrollBarImageColor3=C.Accent
    local lay=Instance.new("UIListLayout",sc)
    lay.Padding=UDim.new(0,3) lay.SortOrder=Enum.SortOrder.LayoutOrder
    return sc,lay
end
local function clrList(sc)
    for _,c in ipairs(sc:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
end
local function addRow(sc,lay,name,rarity,price,desc)
    local col=RC[rarity] or C.Sub
    local row=Instance.new("Frame",sc)
    row.Size=UDim2.new(1,-4,0,44) row.BackgroundColor3=C.Panel row.BorderSizePixel=0
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,5)
    local nl=Instance.new("TextLabel",row)
    nl.Size=UDim2.new(1,-70,0,18) nl.Position=UDim2.new(0,8,0,4)
    nl.BackgroundTransparency=1 nl.Text=(RE[rarity] or "⚪").."  "..name
    nl.TextColor3=col nl.TextSize=12 nl.Font=Enum.Font.GothamBold nl.TextXAlignment=Enum.TextXAlignment.Left
    local dl=Instance.new("TextLabel",row)
    dl.Size=UDim2.new(1,-70,0,14) dl.Position=UDim2.new(0,8,0,26)
    dl.BackgroundTransparency=1 dl.Text=desc or "" dl.TextColor3=C.Sub
    dl.TextSize=9 dl.Font=Enum.Font.Gotham dl.TextXAlignment=Enum.TextXAlignment.Left
    local badge=Instance.new("TextLabel",row)
    badge.Size=UDim2.new(0,60,0,16) badge.Position=UDim2.new(1,-66,0,4)
    badge.BackgroundColor3=C.BG badge.Text=rarity badge.TextColor3=col
    badge.TextSize=9 badge.Font=Enum.Font.GothamBold
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,4)
    local pl=Instance.new("TextLabel",row)
    pl.Size=UDim2.new(0,60,0,14) pl.Position=UDim2.new(1,-66,0,24)
    pl.BackgroundTransparency=1 pl.Text=price or "" pl.TextColor3=Color3.fromRGB(100,220,100)
    pl.TextSize=10 pl.Font=Enum.Font.GothamBold pl.TextXAlignment=Enum.TextXAlignment.Right
    sc.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+6)
end
local function empty(sc,msg)
    clrList(sc)
    local l=Instance.new("TextLabel",sc)
    l.Size=UDim2.new(1,0,0,30) l.BackgroundTransparency=1
    l.Text=msg l.TextColor3=C.Sub l.TextSize=11 l.Font=Enum.Font.Gotham
    sc.CanvasSize=UDim2.new(0,0,0,30)
end

-- ── PAGES ─────────────────────────────────────────────────────────────────────
-- Gear page
local GP=page()
hdr(GP,"  GEAR SHOP — Live Stock",0)
local gSc,gLay=mklist(GP,18,192)
local gScanBtn=abtn(GP,"🔍  Scan Gear Shop",218,C.Accent)
local gSendBtn=abtn(GP,"📤  Force Send to Discord",256,C.Panel)
Instance.new("UIStroke",gSendBtn).Color=C.Accent
local gAutoRow=Instance.new("Frame",GP)
gAutoRow.Size=UDim2.new(1,0,0,32) gAutoRow.Position=UDim2.new(0,0,0,294)
gAutoRow.BackgroundColor3=C.Card gAutoRow.BorderSizePixel=0
Instance.new("UICorner",gAutoRow).CornerRadius=UDim.new(0,7)
local gAutoL=Instance.new("TextLabel",gAutoRow)
gAutoL.Size=UDim2.new(1,-90,1,0) gAutoL.Position=UDim2.new(0,10,0,0)
gAutoL.BackgroundTransparency=1 gAutoL.Text="Auto-send on restock (:00,:05,:10...)"
gAutoL.TextColor3=C.Text gAutoL.TextSize=11 gAutoL.Font=Enum.Font.GothamBold
gAutoL.TextXAlignment=Enum.TextXAlignment.Left
local gToggle=Instance.new("TextButton",gAutoRow)
gToggle.Size=UDim2.new(0,60,0,22) gToggle.Position=UDim2.new(1,-68,0.5,-11)
gToggle.BackgroundColor3=C.Border gToggle.Text="OFF"
gToggle.TextColor3=C.Sub gToggle.TextSize=12 gToggle.Font=Enum.Font.GothamBold gToggle.BorderSizePixel=0
Instance.new("UICorner",gToggle).CornerRadius=UDim.new(0,5)
local gNextLbl=Instance.new("TextLabel",GP)
gNextLbl.Size=UDim2.new(1,0,0,14) gNextLbl.Position=UDim2.new(0,0,0,332)
gNextLbl.BackgroundTransparency=1 gNextLbl.Text="Next restock: --"
gNextLbl.TextColor3=C.Sub gNextLbl.TextSize=10 gNextLbl.Font=Enum.Font.Gotham
gNextLbl.TextXAlignment=Enum.TextXAlignment.Left

-- Egg page
local EP=page()
hdr(EP,"  EGG SHOP — Live Stock",0)
local eSc,eLay=mklist(EP,18,192)
local eScanBtn=abtn(EP,"🔍  Scan Egg Shop",218,C.Accent)
local eSendBtn=abtn(EP,"📤  Force Send to Discord",256,C.Panel)
Instance.new("UIStroke",eSendBtn).Color=C.Accent
local eAutoRow=Instance.new("Frame",EP)
eAutoRow.Size=UDim2.new(1,0,0,32) eAutoRow.Position=UDim2.new(0,0,0,294)
eAutoRow.BackgroundColor3=C.Card eAutoRow.BorderSizePixel=0
Instance.new("UICorner",eAutoRow).CornerRadius=UDim.new(0,7)
local eAutoL=Instance.new("TextLabel",eAutoRow)
eAutoL.Size=UDim2.new(1,-90,1,0) eAutoL.Position=UDim2.new(0,10,0,0)
eAutoL.BackgroundTransparency=1 eAutoL.Text="Auto-send on restock (:00,:05,:10...)"
eAutoL.TextColor3=C.Text eAutoL.TextSize=11 eAutoL.Font=Enum.Font.GothamBold
eAutoL.TextXAlignment=Enum.TextXAlignment.Left
local eToggle=Instance.new("TextButton",eAutoRow)
eToggle.Size=UDim2.new(0,60,0,22) eToggle.Position=UDim2.new(1,-68,0.5,-11)
eToggle.BackgroundColor3=C.Border eToggle.Text="OFF"
eToggle.TextColor3=C.Sub eToggle.TextSize=12 eToggle.Font=Enum.Font.GothamBold eToggle.BorderSizePixel=0
Instance.new("UICorner",eToggle).CornerRadius=UDim.new(0,5)

-- Webhook page
local WP=page()
hdr(WP,"  DISCORD WEBHOOK",0)
local wCard=Instance.new("Frame",WP)
wCard.Size=UDim2.new(1,0,0,96) wCard.Position=UDim2.new(0,0,0,18)
wCard.BackgroundColor3=C.Card wCard.BorderSizePixel=0
Instance.new("UICorner",wCard).CornerRadius=UDim.new(0,8)
Instance.new("UIStroke",wCard).Color=C.Border
local wHint=Instance.new("TextLabel",wCard)
wHint.Size=UDim2.new(1,-16,0,18) wHint.Position=UDim2.new(0,8,0,6)
wHint.BackgroundTransparency=1 wHint.Text="Paste your Discord Webhook URL:"
wHint.TextColor3=C.Sub wHint.TextSize=11 wHint.Font=Enum.Font.GothamBold
wHint.TextXAlignment=Enum.TextXAlignment.Left
local wBox=Instance.new("TextBox",wCard)
wBox.Size=UDim2.new(1,-16,0,32) wBox.Position=UDim2.new(0,8,0,26)
wBox.BackgroundColor3=C.BG wBox.Text="" wBox.PlaceholderText="https://discord.com/api/webhooks/..."
wBox.TextColor3=C.Text wBox.PlaceholderColor3=C.Sub wBox.TextSize=9
wBox.Font=Enum.Font.Gotham wBox.TextXAlignment=Enum.TextXAlignment.Left
wBox.ClearTextOnFocus=false wBox.BorderSizePixel=0
Instance.new("UICorner",wBox).CornerRadius=UDim.new(0,5)
Instance.new("UIPadding",wBox).PaddingLeft=UDim.new(0,6)
local wSave=abtn(wCard,"💾  Save Webhook",62,C.Green)
wSave.Size=UDim2.new(1,-16,0,26) wSave.Position=UDim2.new(0,8,0,64) wSave.TextSize=11
local wStatus=Instance.new("TextLabel",WP)
wStatus.Size=UDim2.new(1,0,0,18) wStatus.Position=UDim2.new(0,0,0,120)
wStatus.BackgroundTransparency=1 wStatus.Text="No webhook saved yet."
wStatus.TextColor3=C.Sub wStatus.TextSize=11 wStatus.Font=Enum.Font.GothamBold
wStatus.TextXAlignment=Enum.TextXAlignment.Left
local wTest=abtn(WP,"🧪  Test Webhook",144,C.Panel)
Instance.new("UIStroke",wTest).Color=C.Accent
local wInfo=Instance.new("TextLabel",WP)
wInfo.Size=UDim2.new(1,0,0,70) wInfo.Position=UDim2.new(0,0,0,184)
wInfo.BackgroundTransparency=1
wInfo.Text="How to get webhook URL:\n1. Discord → your channel → ⚙️ Edit Channel\n2. Integrations → Webhooks → New Webhook\n3. Copy Webhook URL → paste above"
wInfo.TextColor3=C.Sub wInfo.TextSize=10 wInfo.Font=Enum.Font.Gotham
wInfo.TextXAlignment=Enum.TextXAlignment.Left wInfo.TextWrapped=true

-- ── Tab switching ─────────────────────────────────────────────────────────────
local tabs={Gear={GP,gTab,gTabL},Egg={EP,eTab,eTabL},Webhook={WP,wTab,wTabL}}
local function switchTab(n)
    for k,v in pairs(tabs) do
        v[1].Visible=(k==n)
        TweenService:Create(v[2],TweenInfo.new(0.15),{BackgroundColor3=(k==n) and C.Accent or C.Card}):Play()
        v[3].TextColor3=(k==n) and C.Text or C.Sub
    end
end
gTab.MouseButton1Click:Connect(function() switchTab("Gear") end)
eTab.MouseButton1Click:Connect(function() switchTab("Egg") end)
wTab.MouseButton1Click:Connect(function() switchTab("Webhook") end)
switchTab("Gear")

-- ── Status ────────────────────────────────────────────────────────────────────
local totalScans=0
local function setStatus(on,txt)
    ssDot.BackgroundColor3=on and C.Green or C.Red
    ssLbl.Text=txt or (on and "Active" or "Idle")
    ssLbl.TextColor3=on and C.Green or C.Sub
end
local function bump()
    totalScans+=1
    ssScan.Text="Scans: "..totalScans
end

-- ── HTTP via coroutine (fixes Delta blocked thread) ───────────────────────────
local function httpPost(url, body)
    local result = {ok=false, err="timeout"}
    local done = false
    coroutine.wrap(function()
        local s,e = pcall(function()
            HttpService:PostAsync(url, body, Enum.HttpContentType.ApplicationJson, false)
        end)
        result.ok=s result.err=e done=true
    end)()
    local t=0
    while not done and t<6 do RunService.Heartbeat:Wait() t+=0.05 end
    return result.ok, result.err
end

-- ── Scanner: reads ACTUAL game GUI for item cards ────────────────────────────
-- Each shop item in BARF has a frame containing: name label, price ($...), 
-- description text, and "Stock: N" label. We find frames that contain a 
-- matching item name and extract the other fields from the same frame.
local function scanShop(nameList)
    local found = {}
    local nameSet = {}
    for _,n in ipairs(nameList) do nameSet[n]=true end

    -- Walk every GUI frame looking for one whose descendants contain a known item name
    local function searchObj(obj, depth)
        if depth > 10 then return end
        -- Check if this object's text matches an item name
        if (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
            local txt = obj.Text or ""
            if nameSet[txt] and not found[txt] then
                -- Found item name! Now grab price, desc, stock from parent frame
                local parent = obj.Parent
                local price,desc,stock = nil,nil,nil
                if parent then
                    for _,sib in ipairs(parent:GetDescendants()) do
                        if sib ~= obj and (sib:IsA("TextLabel") or sib:IsA("TextButton")) then
                            local t = sib.Text or ""
                            if t:match("^%$") then price=t
                            elseif t:match("^Stock:") then stock=t
                            elseif #t>8 and not t:match("^BUY") and t~=txt then desc=t end
                        end
                    end
                end
                found[txt]={price=price,desc=desc,stock=stock}
            end
        end
        for _,c in ipairs(obj:GetChildren()) do searchObj(c,depth+1) end
    end

    -- Search PlayerGui
    for _,g in ipairs(pg:GetChildren()) do searchObj(g,0) end
    -- Search workspace (for BillboardGui/SurfaceGui shop signs)
    for _,g in ipairs(workspace:GetDescendants()) do
        if g:IsA("BillboardGui") or g:IsA("SurfaceGui") or g:IsA("ScreenGui") then
            searchObj(g,0)
        end
    end

    return found
end

-- ── Build & send webhook ──────────────────────────────────────────────────────
local function sendWebhook(found, shopName)
    if WEBHOOK_URL=="" then
        wStatus.Text="⚠️ No webhook! Go to Webhook tab."
        wStatus.TextColor3=C.Red
        switchTab("Webhook")
        return false
    end
    if not next(found) then return false end

    local items,hasRare,topColor={},false,RI.Common
    local order={"Mythical","Legendary","Epic","Event","Rare","Uncommon","Common"}

    for name,data in pairs(found) do
        local r=guessRarity(name)
        if RARE[r] then hasRare=true end
        table.insert(items,{name=name,r=r,price=data.price,desc=data.desc})
    end
    for _,tier in ipairs(order) do
        for _,it in ipairs(items) do
            if it.r==tier then topColor=RI[tier] or topColor break end
        end
        if topColor~=RI.Common then break end
    end

    local lines={}
    for _,it in ipairs(items) do
        local p=it.price and (" · "..it.price) or ""
        local d=it.desc and ("\n  *"..it.desc.."*") or ""
        table.insert(lines,(RE[it.r] or "⚪").." **"..it.name.."** `"..it.r.."`"..p..d)
    end

    local payload=HttpService:JSONEncode({
        content=hasRare and "🚨 **Rare item in stock!**" or nil,
        embeds={{
            title=(shopName=="Egg" and "🥚" or "⚙️").." BARF — "..shopName.." Shop Stock",
            description="Live stock · "..os.date("%H:%M"),
            color=topColor,
            fields={{name=shopName.." Items",value=#lines>0 and table.concat(lines,"\n") or "_Empty_",inline=false}},
            footer={text="BARF Stock Hub • Live"},
            timestamp=os.date("!%Y-%m-%dT%H:%M:%SZ"),
        }}
    })

    local ok,err=httpPost(WEBHOOK_URL,payload)
    return ok,err
end

-- ── Display ───────────────────────────────────────────────────────────────────
local function display(sc,lay,found)
    clrList(sc)
    if not next(found) then
        empty(sc,"  Open the shop in-game, then scan!")
        return
    end
    for name,data in pairs(found) do
        addRow(sc,lay,name,guessRarity(name),data.price,data.desc)
    end
end

-- ── Scan + send ───────────────────────────────────────────────────────────────
local lastGKey,lastEKey="",""
local gAutoOn,eAutoOn=false,false

local function doGear(force)
    setStatus(true,"Scanning...") bump()
    local found=scanShop(GEAR_NAMES)
    display(gSc,gLay,found)
    local keys={} for n in pairs(found) do table.insert(keys,n) end
    table.sort(keys) local key=table.concat(keys,",")
    if (force or key~=lastGKey) and key~="" then
        lastGKey=key
        local ok,err=sendWebhook(found,"Gear")
        if ok then
            gScanBtn.Text="✅ Sent!"
            task.delay(2,function() gScanBtn.Text="🔍  Scan Gear Shop" end)
        else
            gScanBtn.Text="❌ Failed"
            task.delay(2,function() gScanBtn.Text="🔍  Scan Gear Shop" end)
        end
    end
    setStatus(gAutoOn or eAutoOn)
end

local function doEgg(force)
    setStatus(true,"Scanning...") bump()
    local found=scanShop(EGG_NAMES)
    display(eSc,eLay,found)
    local keys={} for n in pairs(found) do table.insert(keys,n) end
    table.sort(keys) local key=table.concat(keys,",")
    if (force or key~=lastEKey) and key~="" then
        lastEKey=key
        local ok=sendWebhook(found,"Egg")
        if ok then
            eScanBtn.Text="✅ Sent!"
            task.delay(2,function() eScanBtn.Text="🔍  Scan Egg Shop" end)
        end
    end
    setStatus(gAutoOn or eAutoOn)
end

-- ── 5-minute restock timer ────────────────────────────────────────────────────
-- Fires at exactly :00, :05, :10, :15, :20, :25, :30, :35, :40, :45, :50, :55
task.spawn(function()
    while true do
        local now=os.time()
        local sec=now%300  -- seconds past last 5-min mark
        local wait=300-sec -- seconds until next 5-min mark
        -- Update countdown every second
        task.spawn(function()
            for i=wait,1,-1 do
                local m=math.floor(i/60)
                local s=i%60
                local txt=string.format("Next: %d:%02d",m,s)
                ssTime.Text=txt
                gNextLbl.Text="Next restock in: "..txt:sub(7)
                task.wait(1)
            end
        end)
        task.wait(wait)
        -- It's restock time!
        ssTime.Text="Next: Restocking!"
        if gAutoOn then
            task.spawn(function() doGear(true) end)
        end
        if eAutoOn then
            task.spawn(function() doEgg(true) end)
        end
        task.wait(1) -- small buffer before next cycle
    end
end)

-- ── Toggle buttons ────────────────────────────────────────────────────────────
local function setToggle(btn,state)
    btn.Text=state and "ON" or "OFF"
    btn.BackgroundColor3=state and C.Green or C.Border
    btn.TextColor3=state and Color3.new(1,1,1) or C.Sub
end

gToggle.MouseButton1Click:Connect(function()
    gAutoOn=not gAutoOn setToggle(gToggle,gAutoOn)
    setStatus(gAutoOn or eAutoOn, gAutoOn and "Auto ON" or "Idle")
end)
eToggle.MouseButton1Click:Connect(function()
    eAutoOn=not eAutoOn setToggle(eToggle,eAutoOn)
    setStatus(gAutoOn or eAutoOn, eAutoOn and "Auto ON" or "Idle")
end)

-- ── Manual buttons ────────────────────────────────────────────────────────────
gScanBtn.MouseButton1Click:Connect(function()
    gScanBtn.Text="⏳ Scanning..."
    task.spawn(function() doGear(false) end)
end)
gSendBtn.MouseButton1Click:Connect(function()
    gSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        doGear(true)
        task.delay(2,function() gSendBtn.Text="📤  Force Send to Discord" end)
    end)
end)
eScanBtn.MouseButton1Click:Connect(function()
    eScanBtn.Text="⏳ Scanning..."
    task.spawn(function() doEgg(false) end)
end)
eSendBtn.MouseButton1Click:Connect(function()
    eSendBtn.Text="⏳ Sending..."
    task.spawn(function()
        doEgg(true)
        task.delay(2,function() eSendBtn.Text="📤  Force Send to Discord" end)
    end)
end)

-- ── Webhook buttons ───────────────────────────────────────────────────────────
wSave.MouseButton1Click:Connect(function()
    local url=wBox.Text:gsub("%s+","")
    if url:find("discord.com/api/webhooks/") then
        WEBHOOK_URL=url
        wStatus.Text="✅ Webhook saved!"
        wStatus.TextColor3=C.Green
    else
        wStatus.Text="❌ Invalid — must be a Discord webhook URL"
        wStatus.TextColor3=C.Red
    end
end)

wTest.MouseButton1Click:Connect(function()
    if WEBHOOK_URL=="" then
        wStatus.Text="⚠️ Save a webhook first!" wStatus.TextColor3=C.Red return
    end
    wTest.Text="⏳ Testing..."
    task.spawn(function()
        local ok,err=httpPost(WEBHOOK_URL,HttpService:JSONEncode({
            embeds={{title="✅ BARF Stock Hub — Test",description="Webhook is working!",color=3066993,footer={text="BARF Stock Hub"}}}
        }))
        wTest.Text=ok and "✅ Works!" or "❌ Failed"
        wStatus.Text=ok and "✅ Connected!" or "❌ Error: "..tostring(err)
        wStatus.TextColor3=ok and C.Green or C.Red
        task.delay(3,function() wTest.Text="🧪  Test Webhook" end)
    end)
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

print("[BARF Stock Hub v4] Loaded! Go to Webhook tab first.")
