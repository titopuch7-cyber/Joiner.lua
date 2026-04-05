-- ╔══════════════════════════════════════════════════════════════╗
-- ║        STEAL A BRAINROT — Aurora-Style Server Hopper        ║
-- ║   Salta servidores hasta encontrar brainrots con buen Gen   ║
-- ╚══════════════════════════════════════════════════════════════╝

local cg = game:GetService("CoreGui")
if cg:FindFirstChild("SAB_AuroraHopper") then
    cg.SAB_AuroraHopper:Destroy()
end
_G.SAB_HOPPER_ACTIVE = false
task.wait(0.1)

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local UIS             = game:GetService("UserInputService")
local LP              = Players.LocalPlayer
local PLACE_ID        = game.PlaceId

local RARITY = {
    { name = "Common",       minGen = 0,            color = Color3.fromRGB(160,160,160) },
    { name = "Uncommon",     minGen = 500,           color = Color3.fromRGB(40, 200, 90)  },
    { name = "Rare",         minGen = 2000,          color = Color3.fromRGB(30, 140,255)  },
    { name = "Epic",         minGen = 10000,         color = Color3.fromRGB(130, 80,255)  },
    { name = "Legendary",    minGen = 50000,         color = Color3.fromRGB(255,200,  0)  },
    { name = "Mythic",       minGen = 500000,        color = Color3.fromRGB(200, 30,255)  },
    { name = "Secret",       minGen = 5000000,       color = Color3.fromRGB(255,120,  0)  },
    { name = "Brainrot God", minGen = 50000000,      color = Color3.fromRGB(255, 30, 80)  },
    { name = "OG",           minGen = 500000000,     color = Color3.fromRGB(255,255,255)  },
}

local PRESETS = {
    { label = "500M",  threshold = 500000000   },
    { label = "1B",    threshold = 1000000000  },
    { label = "2B",    threshold = 2000000000  },
    { label = "5B",    threshold = 5000000000  },
    { label = "10B",   threshold = 10000000000 },
    { label = "50B",   threshold = 50000000000 },
    { label = "100B",  threshold = 100000000000},
}

local selectedPreset = 2

local function getRarityName(gen)
    local best = "Common"
    for _, r in ipairs(RARITY) do
        if gen >= r.minGen then best = r.name end
    end
    return best
end

local function getRarityColor(gen)
    local col = RARITY[1].color
    for _, r in ipairs(RARITY) do
        if gen >= r.minGen then col = r.color end
    end
    return col
end

local function fmtNum(n)
    if n >= 1e12 then return string.format("%.1fT", n/1e12)
    elseif n >= 1e9  then return string.format("%.1fB", n/1e9)
    elseif n >= 1e6  then return string.format("%.1fM", n/1e6)
    elseif n >= 1e3  then return string.format("%.1fK", n/1e3)
    else return tostring(math.floor(n)) end
end

local GEN_ATTRS = {
    "Income","income","GenPerSec","Gen",
    "CashPerSecond","MoneyPerSecond","GenerationPerSecond",
    "IncomePerSecond","Cash","Multiplier","INCOME","CASH",
}

local function parseV(v)
    if type(v) == "number" then return math.abs(v) end
    if type(v) == "string" then
        local s = v:upper():gsub(",","")
        local n = tonumber(s:match("[%d%.]+")) or 0
        local m = s:find("T") and 1e12
               or s:find("B") and 1e9
               or s:find("M") and 1e6
               or s:find("K") and 1e3
               or 1
        return n * m
    end
    return 0
end

local function getGen(obj)
    for _, a in ipairs(GEN_ATTRS) do
        local ok, v = pcall(function() return obj:GetAttribute(a) end)
        if ok and v ~= nil then
            local n = parseV(v)
            if n > 0 then return n end
        end
    end
    for _, c in ipairs(obj:GetChildren()) do
        local ln = c.Name:lower()
        if (ln:find("income") or ln:find("gen") or ln:find("cash") or ln:find("money"))
           and (c:IsA("NumberValue") or c:IsA("IntValue") or c:IsA("StringValue")) then
            local n = parseV(c.Value)
            if n > 0 then return n end
        end
    end
    return 0
end

local function scanServer()
    local found = {}
    local seen  = {}

    local function add(name, gen, path)
        local key = name .. math.floor(gen)
        if seen[key] then return end
        seen[key] = true
        table.insert(found, { name=name, gen=gen, path=path or "" })
    end

    pcall(function()
        local plots = workspace:FindFirstChild("Plots")
        if plots then
            for _, plot in ipairs(plots:GetChildren()) do
                local pods = plot:FindFirstChild("AnimalPodiums")
                          or plot:FindFirstChild("Podiums")
                          or plot:FindFirstChild("Animals")
                if pods then
                    for _, pod in ipairs(pods:GetChildren()) do
                        local g = getGen(pod)
                        if g > 0 then add(pod.Name, g, "Plots") end
                        for _, c in ipairs(pod:GetChildren()) do
                            if c:IsA("Model") then
                                local g2 = getGen(c)
                                if g2 > 0 then add(c.Name, g2, "Plots/pod") end
                            end
                        end
                    end
                else
                    for _, c in ipairs(plot:GetChildren()) do
                        if c:IsA("Model") then
                            local g = getGen(c)
                            if g > 0 then add(c.Name, g, "Plot/"..plot.Name) end
                        end
                    end
                end
            end
        end
    end)

    if #found == 0 then
        pcall(function()
            for _, p in ipairs(Players:GetPlayers()) do
                local ls = p:FindFirstChild("leaderstats")
                if ls then
                    for _, s in ipairs(ls:GetChildren()) do
                        local ln = s.Name:lower()
                        if ln:find("income") or ln:find("gen") or ln:find("cash") then
                            local n = parseV(s.Value)
                            if n > 0 then add(p.Name, n, "leaderstat") end
                        end
                    end
                end
                for _, a in ipairs(GEN_ATTRS) do
                    local ok, v = pcall(function() return p:GetAttribute(a) end)
                    if ok and v ~= nil then
                        local n = parseV(v)
                        if n > 0 then add(p.Name.."_attr", n, "player_attr") end
                    end
                end
            end
        end)
    end

    if #found == 0 then
        local function deep(parent, depth, label)
            if depth > 5 then return end
            for _, obj in ipairs(parent:GetChildren()) do
                local ln = obj.Name:lower()
                if ln ~= "camera" and ln ~= "terrain" then
                    local g = getGen(obj)
                    if g > 0 then add(obj.Name, g, label) end
                    if obj:IsA("Model") or obj:IsA("Folder") then
                        deep(obj, depth+1, label or obj.Name)
                    end
                end
            end
        end
        pcall(deep, workspace, 0, "ws")
        pcall(deep, game:GetService("ReplicatedStorage"), 0, "rs")
    end

    table.sort(found, function(a,b) return a.gen > b.gen end)
    local total = 0
    for _, b in ipairs(found) do total = total + b.gen end
    return found, total
end

local serverQueue  = {}
local nextCursor   = nil
local fetchedPages = 0

local function fetchServers()
    local url = ("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&sortOrder=Desc&excludeFullGames=true"):format(PLACE_ID)
    if nextCursor and nextCursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(nextCursor)
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url, true))
    end)
    if ok and data and data.data then
        for _, s in ipairs(data.data) do
            if s.id ~= game.JobId and s.playing then
                table.insert(serverQueue, s.id)
            end
        end
        nextCursor   = data.nextPageCursor
        fetchedPages = fetchedPages + 1
        return #data.data
    end
    return 0
end

local function nextServer()
    if #serverQueue < 10 then
        pcall(fetchServers)
        task.wait(0.5)
    end
    if #serverQueue == 0 then return nil end
    return table.remove(serverQueue, 1)
end

local gui = Instance.new("ScreenGui")
gui.Name = "SAB_AuroraHopper"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = cg

local W, H = 400, 520
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, W, 0, H)
Main.Position = UDim2.new(0.5,-W/2, 0.5,-H/2)
Main.BackgroundColor3 = Color3.fromRGB(9, 7, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,16)

local outerStroke = Instance.new("UIStroke", Main)
outerStroke.Color = Color3.fromRGB(255,80,30)
outerStroke.Thickness = 2

do
    local g = Instance.new("UIGradient", Main)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 9, 28)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6,  5, 12)),
    })
    g.Rotation = 120
end

local TBar = Instance.new("Frame")
TBar.Size = UDim2.new(1,0,0,56)
TBar.BackgroundColor3 = Color3.fromRGB(18,10,32)
TBar.BorderSizePixel = 0
TBar.Parent = Main
do
    local g = Instance.new("UIGradient", TBar)
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 70, 20)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(150, 30,180)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(9,   7, 16)),
    })
    g.Rotation = 90
end

local function lbl(parent, text, size, pos, ts, col, font, xa)
    local l = Instance.new("TextLabel")
    l.Size=size; l.Position=pos; l.BackgroundTransparency=1
    l.Text=text; l.TextSize=ts
    l.TextColor3=col or Color3.fromRGB(255,255,255)
    l.Font=font or Enum.Font.GothamBold
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.Parent=parent; return l
end

lbl(TBar,"🔥  SAB AURORA HOPPER",
    UDim2.new(1,-48,0,30),UDim2.new(0,14,0,5),
    17,Color3.fromRGB(255,255,255))
lbl(TBar,"Steal a Brainrot  •  Server Hopper por Gen/s",
    UDim2.new(1,-48,0,16),UDim2.new(0,14,0,36),
    10,Color3.fromRGB(255,160,80),Enum.Font.Gotham)

local xBtn = Instance.new("TextButton")
xBtn.Size=UDim2.new(0,28,0,28); xBtn.Position=UDim2.new(1,-38,0,14)
xBtn.BackgroundColor3=Color3.fromRGB(180,25,50); xBtn.Text="✕"
xBtn.TextColor3=Color3.fromRGB(255,255,255); xBtn.TextSize=14
xBtn.Font=Enum.Font.GothamBold; xBtn.BorderSizePixel=0; xBtn.Parent=TBar
Instance.new("UICorner",xBtn).CornerRadius=UDim.new(0,8)
xBtn.MouseButton1Click:Connect(function()
    _G.SAB_HOPPER_ACTIVE = false
    gui:Destroy()
end)

local SP = Instance.new("Frame")
SP.Size=UDim2.new(1,-20,0,80); SP.Position=UDim2.new(0,10,0,64)
SP.BackgroundColor3=Color3.fromRGB(14,11,24); SP.BorderSizePixel=0; SP.Parent=Main
Instance.new("UICorner",SP).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",SP).Color=Color3.fromRGB(45,35,72)

local statusLbl = lbl(SP,"⏳ Inicializando...",
    UDim2.new(1,-12,0,20),UDim2.new(0,10,0,6),
    12,Color3.fromRGB(200,185,255))

local genLbl = lbl(SP,"💰 Gen actual: —",
    UDim2.new(0.5,0,0,18),UDim2.new(0,10,0,30),
    11,Color3.fromRGB(80,220,100),Enum.Font.Gotham)

local hopLbl = lbl(SP,"🔄 Saltos: 0",
    UDim2.new(0.5,0,0,18),UDim2.new(0.5,0,0,30),
    11,Color3.fromRGB(160,140,220),Enum.Font.Gotham)

local bestFoundLbl = lbl(SP,"🏆 Mejor encontrado: —",
    UDim2.new(1,-12,0,18),UDim2.new(0,10,0,52),
    10,Color3.fromRGB(255,200,60),Enum.Font.Gotham)

lbl(Main,"UMBRAL MÍNIMO (Gen/s para quedarse):",
    UDim2.new(1,-20,0,14),UDim2.new(0,10,0,154),
    9,Color3.fromRGB(255,110,50))

local pRow = Instance.new("Frame")
pRow.Size=UDim2.new(1,-20,0,30); pRow.Position=UDim2.new(0,10,0,170)
pRow.BackgroundTransparency=1; pRow.Parent=Main
local pl = Instance.new("UIListLayout",pRow)
pl.FillDirection=Enum.FillDirection.Horizontal; pl.Padding=UDim.new(0,4)

local presetBtns = {}
local thresholdDisplayLbl

local function refreshPresets()
    for i, btn in ipairs(presetBtns) do
        local sel = (i == selectedPreset)
        btn.BackgroundColor3 = sel and Color3.fromRGB(255,100,30) or Color3.fromRGB(26,20,40)
        btn.TextColor3 = sel and Color3.fromRGB(0,0,0) or Color3.fromRGB(150,130,190)
    end
end

local function updateThresholdDisplay()
    local t = PRESETS[selectedPreset].threshold
    thresholdDisplayLbl.Text = "→ Saltar si Gen/s < "..fmtNum(t).."/s  ("..getRarityName(t)..")"
    thresholdDisplayLbl.TextColor3 = getRarityColor(t)
end

for i, p in ipairs(PRESETS) do
    local b = Instance.new("TextButton")
    b.Size=UDim2.new(0,46,1,0); b.BackgroundColor3=Color3.fromRGB(26,20,40)
    b.Text=p.label; b.TextColor3=Color3.fromRGB(150,130,190)
    b.TextSize=10; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.Parent=pRow
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    table.insert(presetBtns, b)
    b.MouseButton1Click:Connect(function()
        selectedPreset=i; refreshPresets(); updateThresholdDisplay()
    end)
end
refreshPresets()

thresholdDisplayLbl = lbl(Main,"",
    UDim2.new(1,-20,0,14),UDim2.new(0,10,0,204),
    9,Color3.fromRGB(120,100,160),Enum.Font.Gotham)
updateThresholdDisplay()

lbl(Main,"BRAINROTS EN ESTE SERVIDOR  (mayor Gen/s primero):",
    UDim2.new(1,-20,0,13),UDim2.new(0,10,0,222),
    9,Color3.fromRGB(255,110,50))

local scrl = Instance.new("ScrollingFrame")
scrl.Size=UDim2.new(1,-20,0,190); scrl.Position=UDim2.new(0,10,0,237)
scrl.BackgroundColor3=Color3.fromRGB(11,8,20); scrl.BorderSizePixel=0
scrl.ScrollBarThickness=3; scrl.ScrollBarImageColor3=Color3.fromRGB(255,100,30)
scrl.CanvasSize=UDim2.new(0,0,0,0); scrl.Parent=Main
Instance.new("UICorner",scrl).CornerRadius=UDim.new(0,10)
Instance.new("UIStroke",scrl).Color=Color3.fromRGB(36,28,58)
Instance.new("UIListLayout",scrl).Padding=UDim.new(0,3)
local spad=Instance.new("UIPadding",scrl)
spad.PaddingTop=UDim.new(0,5); spad.PaddingLeft=UDim.new(0,5); spad.PaddingRight=UDim.new(0,5)

local function mkBtn(text, col, size, pos)
    local b=Instance.new("TextButton")
    b.Size=size; b.Position=pos; b.BackgroundColor3=col
    b.Text=text; b.TextColor3=Color3.fromRGB(255,255,255)
    b.TextSize=12; b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.Parent=Main
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
    return b
end

local scanBtn = mkBtn("🔍 SCAN",     Color3.fromRGB(30,120,255),   UDim2.new(0,110,0,36), UDim2.new(0,10, 1,-46))
local hopBtn  = mkBtn("⏭ SALTAR",   Color3.fromRGB(40,165,80),    UDim2.new(0,110,0,36), UDim2.new(0,128,1,-46))
local autoBtn = mkBtn("🤖 AUTO: OFF",Color3.fromRGB(140,25,185),   UDim2.new(0,132,0,36), UDim2.new(0,248,1,-46))

do
    local drag,ds,sp2
    TBar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp2=Main.Position
        end
    end)
    TBar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=false
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement
                  or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            Main.Position=UDim2.new(sp2.X.Scale,sp2.X.Offset+d.X,sp2.Y.Scale,sp2.Y.Offset+d.Y)
        end
    end)
end

local function clearList()
    for _, c in ipairs(scrl:GetChildren()) do
        if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
    end
    scrl.CanvasSize=UDim2.new(0,0,0,0)
end

local function renderList(list, totalGen)
    clearList()
    if #list == 0 then
        local el=Instance.new("TextLabel")
        el.Size=UDim2.new(1,-10,0,60); el.BackgroundTransparency=1
        el.Text="😕  Sin datos Gen/s detectados.\nEl juego puede no replicar esto al cliente."
        el.TextColor3=Color3.fromRGB(90,75,128); el.TextSize=11
        el.Font=Enum.Font.Gotham; el.TextWrapped=true; el.LayoutOrder=1; el.Parent=scrl
        scrl.CanvasSize=UDim2.new(0,0,0,70)
        return
    end
    for i, b in ipairs(list) do
        local col = getRarityColor(b.gen)
        local rar = getRarityName(b.gen)
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,0,0,40); row.BackgroundColor3=Color3.fromRGB(17,13,28)
        row.BorderSizePixel=0; row.LayoutOrder=i; row.Parent=scrl
        Instance.new("UICorner",row).CornerRadius=UDim.new(0,8)
        local st=Instance.new("UIStroke",row); st.Color=col; st.Thickness=1; st.Transparency=0.5
        local bar=Instance.new("Frame")
        bar.Size=UDim2.new(0,4,1,-8); bar.Position=UDim2.new(0,4,0,4)
        bar.BackgroundColor3=col; bar.BorderSizePixel=0; bar.Parent=row
        Instance.new("UICorner",bar).CornerRadius=UDim.new(0,3)
        lbl(row, b.name,
            UDim2.new(0.55,0,0,20),UDim2.new(0,13,0,3),
            12,Color3.fromRGB(230,218,255),Enum.Font.GothamBold)
        local chip=Instance.new("TextLabel")
        chip.Size=UDim2.new(0,0,0,15); chip.AutomaticSize=Enum.AutomaticSize.X
        chip.Position=UDim2.new(0,13,0,23); chip.BackgroundColor3=col
        chip.BackgroundTransparency=0.5; chip.Text="  "..rar.."  "
        chip.TextColor3=Color3.fromRGB(255,255,255); chip.TextSize=9
        chip.Font=Enum.Font.GothamBold; chip.BorderSizePixel=0; chip.Parent=row
        Instance.new("UICorner",chip).CornerRadius=UDim.new(0,4)
        lbl(row, fmtNum(b.gen).."/s",
            UDim2.new(0.38,0,1,0),UDim2.new(0.62,-2,0,0),
            13,Color3.fromRGB(80,220,100),Enum.Font.GothamBold,
            Enum.TextXAlignment.Right)
    end
    scrl.CanvasSize=UDim2.new(0,0,0,#list*44+10)
    genLbl.Text = "💰 Total Gen/s: "..fmtNum(totalGen).."/s"
    genLbl.TextColor3 = getRarityColor(totalGen)
end

local hopCount    = 0
local bestEverGen = 0
local autoActive  = false

local function doScan()
    statusLbl.Text = "🔍 Escaneando Gen/s..."
    statusLbl.TextColor3 = Color3.fromRGB(100,190,255)
    task.wait(0.1)
    local list, total = scanServer()
    renderList(list, total)
    local threshold = PRESETS[selectedPreset].threshold
    local good = total >= threshold
    if total > bestEverGen then
        bestEverGen = total
        bestFoundLbl.Text = "🏆 Mejor: "..fmtNum(bestEverGen).."/s  ("..getRarityName(bestEverGen)..")"
        bestFoundLbl.TextColor3 = getRarityColor(bestEverGen)
    end
    if good then
        statusLbl.Text = "✅ ¡BUENO!  "..fmtNum(total).."/s ≥ "..fmtNum(threshold)
        statusLbl.TextColor3 = Color3.fromRGB(80,230,100)
    elseif total > 0 then
        statusLbl.Text = "❌ "..fmtNum(total).."/s  (necesito "..fmtNum(threshold)..")"
        statusLbl.TextColor3 = Color3.fromRGB(255,90,90)
    else
        statusLbl.Text = "⚠️ Sin datos Gen/s detectados"
        statusLbl.TextColor3 = Color3.fromRGB(255,170,50)
    end
    return good, total
end

local function doHop()
    local id = nextServer()
    if not id then
        statusLbl.Text = "📡 Cargando servidores..."
        statusLbl.TextColor3 = Color3.fromRGB(255,190,60)
        pcall(fetchServers)
        id = nextServer()
    end
    if not id then
        statusLbl.Text = "⚠️ Sin servidores — reintentando..."
        statusLbl.TextColor3 = Color3.fromRGB(255,150,50)
        return false
    end
    hopCount = hopCount + 1
    hopLbl.Text = "🔄 Saltos: "..hopCount
    statusLbl.Text = "⏭ Saltando... ("..hopCount.." saltos)"
    statusLbl.TextColor3 = Color3.fromRGB(255,200,60)
    pcall(function()
        TeleportService:TeleportToPlaceInstance(PLACE_ID, id, LP)
    end)
    return true
end

local function stopAuto()
    autoActive = false
    _G.SAB_HOPPER_ACTIVE = false
    autoBtn.Text = "🤖 AUTO: OFF"
    autoBtn.BackgroundColor3 = Color3.fromRGB(140,25,185)
end

local function startAuto()
    if autoActive then return end
    autoActive = true
    _G.SAB_HOPPER_ACTIVE = true
    autoBtn.Text = "🛑 DETENER"
    autoBtn.BackgroundColor3 = Color3.fromRGB(210,35,55)

    task.spawn(function()
        statusLbl.Text = "📡 Cargando servidores..."
        pcall(fetchServers)
        task.wait(1)
        if not game:IsLoaded() then game.Loaded:Wait() end
        task.wait(5)

        while autoActive and _G.SAB_HOPPER_ACTIVE do
            local good, total = doScan()
            if good then
                for t = 15, 1, -1 do
                    if not autoActive then break end
                    statusLbl.Text = "✅ ¡QUEDÁNDOME!  "..fmtNum(total).."/s — reconfirmando en "..t.."s"
                    task.wait(1)
                end
                if not autoActive then break end
                local still_good = doScan()
                if not still_good then
                    task.wait(1); doHop(); task.wait(8)
                else
                    task.wait(25)
                end
            else
                task.wait(1.5)
                if not autoActive then break end
                doHop()
                task.wait(8)
            end
        end
    end)
end

scanBtn.MouseButton1Click:Connect(function() task.spawn(doScan) end)
hopBtn.MouseButton1Click:Connect(function()  task.spawn(doHop)  end)
autoBtn.MouseButton1Click:Connect(function()
    if autoActive then stopAuto() else startAuto() end
end)

-- AUTO arranca solo al entrar al lobby
task.delay(3, function()
    pcall(fetchServers)
    startAuto()
end)

pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",{
        Title="🔥 SAB Aurora Hopper";
        Text="Cargado. AUTO arrancando en 3s... Umbral: 1B/s";
        Duration=4;
    })
end)

print("✅ SAB_AuroraHopper — listo")
