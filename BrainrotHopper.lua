-- ╔══════════════════════════════════════════════════════════════╗
-- ║           BRAINROT HOPPER — Rutas Reales del Juego         ║
-- ║  workspace.Plots > AnimalPodiums > animales reales         ║
-- ╚══════════════════════════════════════════════════════════════╝

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local UserInput       = game:GetService("UserInputService")
local LocalPlayer     = Players.LocalPlayer
local PLACE_ID        = game.PlaceId

-- ── DATOS DE RARIDAD ─────────────────────────────────────────
local RARITY_VALUE = {
    ["OG"]           = 999999999,
    ["Brainrot God"] = 100000000,
    ["Secret"]       = 10000000,
    ["Mythic"]       = 1000000,
    ["Legendary"]    = 100000,
    ["Epic"]         = 10000,
    ["Rare"]         = 1000,
    ["Uncommon"]     = 100,
    ["Common"]       = 10,
}

local RARITY_COLOR = {
    ["OG"]           = Color3.fromRGB(255, 255, 255),
    ["Brainrot God"] = Color3.fromRGB(255, 30,  30),
    ["Secret"]       = Color3.fromRGB(255, 140,  0),
    ["Mythic"]       = Color3.fromRGB(180,  0, 255),
    ["Legendary"]    = Color3.fromRGB(255, 200,  0),
    ["Epic"]         = Color3.fromRGB(100,  80, 255),
    ["Rare"]         = Color3.fromRGB(30,  140, 255),
    ["Uncommon"]     = Color3.fromRGB(40,  200,  90),
    ["Common"]       = Color3.fromRGB(160, 160, 160),
}

local RARITY_LABEL = {
    ["OG"]           = "✨ OG",
    ["Brainrot God"] = "👑 BRAINROT GOD",
    ["Secret"]       = "🔥 SECRET",
    ["Mythic"]       = "💜 MYTHIC",
    ["Legendary"]    = "⭐ LEGENDARY",
    ["Epic"]         = "💎 EPIC",
    ["Rare"]         = "🔵 RARE",
    ["Uncommon"]     = "🟢 UNCOMMON",
    ["Common"]       = "⬜ COMMON",
}

local function formatMoney(n)
    if n >= 1e9 then return string.format("$%.1fB", n/1e9)
    elseif n >= 1e6 then return string.format("$%.1fM", n/1e6)
    elseif n >= 1e3 then return string.format("$%.1fK", n/1e3)
    else return "$"..tostring(math.floor(n)) end
end

-- ══════════════════════════════════════════════════════════════
-- LEER BRAINROTS REALES
-- Estructura confirmada del juego:
--   workspace.Plots[plot].AnimalPodiums[podium]
--     └── Animal (Model) con atributo "Rarity" o StringValue "Rarity"
-- ══════════════════════════════════════════════════════════════
local function leerBrainrots()
    local found = {}
    local seen  = {}

    local function getRarity(obj)
        -- Atributos directos
        for _, name in ipairs({"Rarity","rarity","AnimalRarity","Type","PetRarity"}) do
            local v = obj:GetAttribute(name)
            if v and RARITY_VALUE[v] then return v end
        end
        -- StringValue / IntValue hijos
        for _, child in ipairs(obj:GetChildren()) do
            if child.Name:lower():find("rarity") or child.Name:lower():find("type") then
                if child:IsA("StringValue") and RARITY_VALUE[child.Value] then
                    return child.Value
                end
            end
        end
        -- Buscar un nivel más adentro (Model > Part > StringValue)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Model") or child:IsA("Part") or child:IsA("Folder") then
                for _, sv in ipairs(child:GetChildren()) do
                    if (sv.Name:lower():find("rarity") or sv.Name:lower():find("type"))
                       and sv:IsA("StringValue") and RARITY_VALUE[sv.Value] then
                        return sv.Value
                    end
                end
            end
        end
        return nil
    end

    local function getGen(obj)
        for _, name in ipairs({"Generation","GenPerSec","MoneyPerSecond","Income","GenerationPerSecond","Gen"}) do
            local v = obj:GetAttribute(name)
            if v then
                if type(v) == "number" then return v end
                if type(v) == "string" then
                    local n = tonumber(v:match("[%d%.]+")) or 0
                    local m = v:find("T") and 1e12 or v:find("B") and 1e9
                           or v:find("M") and 1e6  or v:find("K") and 1e3 or 1
                    return n * m
                end
            end
        end
        for _, child in ipairs(obj:GetChildren()) do
            local low = child.Name:lower()
            if (low:find("gen") or low:find("income") or low:find("money"))
               and (child:IsA("NumberValue") or child:IsA("IntValue")) then
                return child.Value
            end
        end
        return nil
    end

    local function add(name, rarity, gen)
        if not name or name == "" then return end
        local key = name..(rarity or "")
        if seen[key] then return end
        seen[key] = true
        table.insert(found, {
            name      = name,
            rarity    = rarity or "Common",
            value     = RARITY_VALUE[rarity or "Common"] or 10,
            genPerSec = gen,
        })
    end

    -- ── RUTA PRINCIPAL: workspace.Plots ──────────────────────
    local ok1 = pcall(function()
        local Plots = workspace:WaitForChild("Plots", 3)
        for _, plot in ipairs(Plots:GetChildren()) do
            -- AnimalPodiums
            local podiums = plot:FindFirstChild("AnimalPodiums")
            if podiums then
                for _, podium in ipairs(podiums:GetChildren()) do
                    -- El animal puede estar directo o en hijo
                    local animal = podium:FindFirstChildOfClass("Model")
                               or podium:FindFirstChild("Animal")
                               or podium:FindFirstChild("Brainrot")
                    if animal then
                        local r = getRarity(animal) or getRarity(podium)
                        add(animal.Name, r, getGen(animal) or getGen(podium))
                    else
                        local r = getRarity(podium)
                        if r then add(podium.Name, r, getGen(podium)) end
                    end
                end
            end
            -- Alternativas: Animals, Brainrots, Pets directo en el plot
            for _, folder in ipairs({"Animals","Brainrots","Pets","AnimalFolder","Podiums"}) do
                local f = plot:FindFirstChild(folder)
                if f then
                    for _, obj in ipairs(f:GetChildren()) do
                        local r = getRarity(obj)
                        add(obj.Name, r, getGen(obj))
                    end
                end
            end
        end
    end)

    -- ── RUTA 2: workspace genérica si Plots no funcionó ──────
    if #found == 0 then
        pcall(function()
            local function scan(parent, depth)
                if depth > 5 then return end
                for _, obj in ipairs(parent:GetChildren()) do
                    local r = getRarity(obj)
                    if r then
                        add(obj.Name, r, getGen(obj))
                    elseif obj:IsA("Folder") or obj:IsA("Model") then
                        scan(obj, depth + 1)
                    end
                end
            end
            scan(workspace, 0)
        end)
    end

    -- ── RUTA 3: ReplicatedStorage ─────────────────────────────
    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        for _, fname in ipairs({"Datas","Animals","Brainrots","ServerData","Data"}) do
            local f = rs:FindFirstChild(fname)
            if f then
                local animals = f:FindFirstChild("Animals") or f
                for _, obj in ipairs(animals:GetChildren()) do
                    local r = getRarity(obj)
                    if r then add(obj.Name, r, getGen(obj)) end
                end
            end
        end
    end)

    table.sort(found, function(a,b) return a.value > b.value end)
    return found
end

-- ══════════════════════════════════════════════════════════════
-- UI
-- ══════════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = "BrainrotHopper"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService("CoreGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 500, 0, 640)
Main.Position = UDim2.new(0.5, -250, 0.5, -320)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 18)
local Stroke = Instance.new("UIStroke", Main)
Stroke.Color = Color3.fromRGB(255, 140, 0)
Stroke.Thickness = 2

local BgGrad = Instance.new("UIGradient", Main)
BgGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 12, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 14)),
})
BgGrad.Rotation = 135

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 70)
Header.BackgroundColor3 = Color3.fromRGB(20, 12, 35)
Header.BorderSizePixel = 0
Header.Parent = Main
local HGrad = Instance.new("UIGradient", Header)
HGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 0)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 30, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 10, 50)),
})
HGrad.Rotation = 90

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -60, 0, 36)
TitleLbl.Position = UDim2.new(0, 16, 0, 8)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "🧠  BRAINROT HOPPER"
TitleLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLbl.TextSize = 22
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.Parent = Header

local SubLbl = Instance.new("TextLabel")
SubLbl.Size = UDim2.new(1, -60, 0, 20)
SubLbl.Position = UDim2.new(0, 16, 0, 46)
SubLbl.BackgroundTransparency = 1
SubLbl.Text = "Brainrots reales • workspace.Plots > AnimalPodiums"
SubLbl.TextColor3 = Color3.fromRGB(255, 180, 80)
SubLbl.TextSize = 11
SubLbl.Font = Enum.Font.Gotham
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 34, 0, 34)
CloseBtn.Position = UDim2.new(1, -44, 0, 18)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255,255,255)
CloseBtn.TextSize = 15
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Info panel
local InfoPanel = Instance.new("Frame")
InfoPanel.Size = UDim2.new(1, -24, 0, 72)
InfoPanel.Position = UDim2.new(0, 12, 0, 78)
InfoPanel.BackgroundColor3 = Color3.fromRGB(18, 14, 30)
InfoPanel.BorderSizePixel = 0
InfoPanel.Parent = Main
Instance.new("UICorner", InfoPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", InfoPanel).Color = Color3.fromRGB(60, 50, 90)

local ServerLbl = Instance.new("TextLabel")
ServerLbl.Size = UDim2.new(1, -12, 0, 22)
ServerLbl.Position = UDim2.new(0, 12, 0, 8)
ServerLbl.BackgroundTransparency = 1
ServerLbl.Text = "📍 " .. string.sub(game.JobId, 1, 30) .. "..."
ServerLbl.TextColor3 = Color3.fromRGB(180, 160, 220)
ServerLbl.TextSize = 11
ServerLbl.Font = Enum.Font.Code
ServerLbl.TextXAlignment = Enum.TextXAlignment.Left
ServerLbl.Parent = InfoPanel

local ValueLbl = Instance.new("TextLabel")
ValueLbl.Size = UDim2.new(0.5, 0, 0, 26)
ValueLbl.Position = UDim2.new(0, 12, 0, 36)
ValueLbl.BackgroundTransparency = 1
ValueLbl.Text = "💰 Valor: —"
ValueLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
ValueLbl.TextSize = 14
ValueLbl.Font = Enum.Font.GothamBold
ValueLbl.TextXAlignment = Enum.TextXAlignment.Left
ValueLbl.Parent = InfoPanel

local CountLbl = Instance.new("TextLabel")
CountLbl.Size = UDim2.new(0.5, 0, 0, 26)
CountLbl.Position = UDim2.new(0.5, 0, 0, 36)
CountLbl.BackgroundTransparency = 1
CountLbl.Text = "🧠 Brainrots: —"
CountLbl.TextColor3 = Color3.fromRGB(200, 160, 255)
CountLbl.TextSize = 14
CountLbl.Font = Enum.Font.GothamBold
CountLbl.TextXAlignment = Enum.TextXAlignment.Left
CountLbl.Parent = InfoPanel

-- Sep
local SepLbl = Instance.new("TextLabel")
SepLbl.Size = UDim2.new(1, -24, 0, 18)
SepLbl.Position = UDim2.new(0, 12, 0, 158)
SepLbl.BackgroundTransparency = 1
SepLbl.Text = "BRAINROTS EN ESTE SERVIDOR  (mayor valor primero)"
SepLbl.TextColor3 = Color3.fromRGB(255, 140, 0)
SepLbl.TextSize = 10
SepLbl.Font = Enum.Font.GothamBold
SepLbl.TextXAlignment = Enum.TextXAlignment.Left
SepLbl.Parent = Main

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -326)
Scroll.Position = UDim2.new(0, 12, 0, 178)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 140, 0)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main
Instance.new("UIListLayout", Scroll).Padding = UDim.new(0, 6)

-- Bottom panel
local BottomPanel = Instance.new("Frame")
BottomPanel.Size = UDim2.new(1, -24, 0, 110)
BottomPanel.Position = UDim2.new(0, 12, 1, -120)
BottomPanel.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
BottomPanel.BorderSizePixel = 0
BottomPanel.Parent = Main
Instance.new("UICorner", BottomPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", BottomPanel).Color = Color3.fromRGB(50, 40, 80)

local FilterLbl = Instance.new("TextLabel")
FilterLbl.Size = UDim2.new(1, -12, 0, 18)
FilterLbl.Position = UDim2.new(0, 12, 0, 8)
FilterLbl.BackgroundTransparency = 1
FilterLbl.Text = "SALTAR AUTO si NO hay al menos rareza:"
FilterLbl.TextColor3 = Color3.fromRGB(140, 120, 180)
FilterLbl.TextSize = 10
FilterLbl.Font = Enum.Font.GothamBold
FilterLbl.TextXAlignment = Enum.TextXAlignment.Left
FilterLbl.Parent = BottomPanel

local rarityOptions = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret","Brainrot God","OG"}
local selectedRarity = "Legendary"
local rarityBtns = {}

local rarityRow = Instance.new("Frame")
rarityRow.Size = UDim2.new(1, -12, 0, 28)
rarityRow.Position = UDim2.new(0, 6, 0, 28)
rarityRow.BackgroundTransparency = 1
rarityRow.Parent = BottomPanel
local rl = Instance.new("UIListLayout", rarityRow)
rl.FillDirection = Enum.FillDirection.Horizontal
rl.Padding = UDim.new(0, 3)

local shortNames = {
    ["Common"]="COM",["Uncommon"]="UC",["Rare"]="RARE",
    ["Epic"]="EPIC",["Legendary"]="LEG",["Mythic"]="MYT",
    ["Secret"]="SEC",["Brainrot God"]="GOD",["OG"]="OG"
}

local function updateRarityBtns()
    local ti = table.find(rarityOptions, selectedRarity) or 1
    for i, btn in ipairs(rarityBtns) do
        btn.BackgroundColor3 = (i == ti) and Color3.fromRGB(255,140,0) or Color3.fromRGB(35,28,55)
        btn.TextColor3 = (i == ti) and Color3.fromRGB(0,0,0) or Color3.fromRGB(160,140,200)
    end
end

for i, r in ipairs(rarityOptions) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 44, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35,28,55)
    btn.Text = shortNames[r] or r:sub(1,3):upper()
    btn.TextColor3 = Color3.fromRGB(160,140,200)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = rarityRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(rarityBtns, btn)
    btn.MouseButton1Click:Connect(function() selectedRarity = r; updateRarityBtns() end)
end
updateRarityBtns()

local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0.48, -4, 0, 36)
ScanBtn.Position = UDim2.new(0, 8, 0, 66)
ScanBtn.BackgroundColor3 = Color3.fromRGB(255,130,0)
ScanBtn.Text = "🔍  ESCANEAR"
ScanBtn.TextColor3 = Color3.fromRGB(0,0,0)
ScanBtn.TextSize = 13
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 0
ScanBtn.Parent = BottomPanel
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 10)

local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(0.48, -4, 0, 36)
HopBtn.Position = UDim2.new(0.52, -4, 0, 66)
HopBtn.BackgroundColor3 = Color3.fromRGB(40,180,100)
HopBtn.Text = "⏭  SALTAR SERVER"
HopBtn.TextColor3 = Color3.fromRGB(255,255,255)
HopBtn.TextSize = 13
HopBtn.Font = Enum.Font.GothamBold
HopBtn.BorderSizePixel = 0
HopBtn.Parent = BottomPanel
Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0, 10)

-- Draggable
do
    local drag, ds, sp
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=true;ds=i.Position;sp=Main.Position end
    end)
    Header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInput.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d=i.Position-ds
            Main.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- Render
local function limpiarScroll()
    for _, c in ipairs(Scroll:GetChildren()) do
        if not c:IsA("UIListLayout") then c:Destroy() end
    end
    Scroll.CanvasSize = UDim2.new(0,0,0,0)
end

local function renderBrainrots(brainrots)
    limpiarScroll()
    if #brainrots == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,-8,0,90)
        empty.BackgroundTransparency = 1
        empty.Text = "😕  No se detectaron brainrots.\n\nAbre la consola F9 y ejecuta:\nprint(workspace.Plots)\npara ver la estructura."
        empty.TextColor3 = Color3.fromRGB(120,100,160)
        empty.TextSize = 12
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.LayoutOrder = 1
        empty.Parent = Scroll
        Scroll.CanvasSize = UDim2.new(0,0,0,100)
        return
    end
    for i, b in ipairs(brainrots) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1,-8,0,54)
        row.BackgroundColor3 = Color3.fromRGB(20,16,32)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = Scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,10)

        local stroke = Instance.new("UIStroke", row)
        stroke.Color = RARITY_COLOR[b.rarity] or Color3.fromRGB(60,50,90)
        stroke.Thickness = b.value >= 1000000 and 2 or 1
        stroke.Transparency = b.value >= 1000000 and 0 or 0.65

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0,5,1,-10)
        bar.Position = UDim2.new(0,6,0,5)
        bar.BackgroundColor3 = RARITY_COLOR[b.rarity] or Color3.fromRGB(100,100,100)
        bar.BorderSizePixel = 0
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)

        local numLbl = Instance.new("TextLabel")
        numLbl.Size = UDim2.new(0,24,1,0)
        numLbl.Position = UDim2.new(0,14,0,0)
        numLbl.BackgroundTransparency = 1
        numLbl.Text = "#"..i
        numLbl.TextColor3 = Color3.fromRGB(90,80,120)
        numLbl.TextSize = 11
        numLbl.Font = Enum.Font.GothamBold
        numLbl.Parent = row

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.52,0,0,24)
        nameLbl.Position = UDim2.new(0,42,0,5)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = b.name
        nameLbl.TextColor3 = Color3.fromRGB(240,230,255)
        nameLbl.TextSize = 13
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row

        local chip = Instance.new("TextLabel")
        chip.Size = UDim2.new(0,0,0,17)
        chip.AutomaticSize = Enum.AutomaticSize.X
        chip.Position = UDim2.new(0,42,0,33)
        chip.BackgroundColor3 = RARITY_COLOR[b.rarity] or Color3.fromRGB(80,80,80)
        chip.BackgroundTransparency = 0.45
        chip.Text = "  "..(RARITY_LABEL[b.rarity] or b.rarity).."  "
        chip.TextColor3 = Color3.fromRGB(255,255,255)
        chip.TextSize = 10
        chip.Font = Enum.Font.GothamBold
        chip.BorderSizePixel = 0
        chip.Parent = row
        Instance.new("UICorner", chip).CornerRadius = UDim.new(0,5)

        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0,90,0,22)
        valLbl.Position = UDim2.new(1,-100,0,6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = formatMoney(b.value)
        valLbl.TextColor3 = Color3.fromRGB(80,220,120)
        valLbl.TextSize = 15
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        if b.genPerSec then
            local genLbl = Instance.new("TextLabel")
            genLbl.Size = UDim2.new(0,90,0,16)
            genLbl.Position = UDim2.new(1,-100,0,30)
            genLbl.BackgroundTransparency = 1
            genLbl.Text = formatMoney(b.genPerSec).."/s"
            genLbl.TextColor3 = Color3.fromRGB(255,200,60)
            genLbl.TextSize = 11
            genLbl.Font = Enum.Font.Gotham
            genLbl.TextXAlignment = Enum.TextXAlignment.Right
            genLbl.Parent = row
        end
    end
    Scroll.CanvasSize = UDim2.new(0,0,0,#brainrots*60)
end

-- Escanear
local function escanear()
    ScanBtn.Text = "⏳  Escaneando..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(100,60,0)
    local brainrots = leerBrainrots()
    local total = 0
    for _, b in ipairs(brainrots) do total = total + b.value end
    ValueLbl.Text = "💰 Valor: "..formatMoney(total)
    CountLbl.Text = "🧠 Brainrots: "..#brainrots
    renderBrainrots(brainrots)
    ScanBtn.Text = "🔍  ESCANEAR"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(255,130,0)
    local minVal = RARITY_VALUE[selectedRarity] or 0
    for _, b in ipairs(brainrots) do
        if b.value >= minVal then return brainrots, true end
    end
    return brainrots, false
end

-- Cola servidores
local serverQueue = {}
local queueCursor = nil

local function cargarServidores()
    local ok, data = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..PLACE_ID
                  .."/servers/Public?limit=100"
                  ..(queueCursor and ("&cursor="..queueCursor) or "")
        return HttpService:JSONDecode(game:HttpGet(url, true))
    end)
    if ok and data then
        for _, s in ipairs(data.data or {}) do
            if s.id ~= game.JobId then table.insert(serverQueue, s.id) end
        end
        queueCursor = data.nextPageCursor
    end
end

local function siguienteServidor()
    if #serverQueue == 0 then cargarServidores(); task.wait(1) end
    if #serverQueue == 0 then
        HopBtn.Text = "❌ Sin servidores"
        task.wait(2)
        HopBtn.Text = "⏭  SALTAR SERVER"
        HopBtn.BackgroundColor3 = Color3.fromRGB(40,180,100)
        return
    end
    local nextId = table.remove(serverQueue, 1)
    HopBtn.Text = "⏳  Saltando..."
    HopBtn.BackgroundColor3 = Color3.fromRGB(60,60,60)
    TeleportService:TeleportToPlaceInstance(PLACE_ID, nextId, LocalPlayer)
end

ScanBtn.MouseButton1Click:Connect(function() task.spawn(escanear) end)
HopBtn.MouseButton1Click:Connect(function() task.spawn(siguienteServidor) end)

task.delay(2.5, function()
    task.spawn(cargarServidores)
    escanear()
end)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🧠 Brainrot Hopper v2";
    Text = "Escaneando brainrots reales del servidor...";
    Duration = 3;
})
print("✅ BrainrotHopper v2 — workspace.Plots > AnimalPodiums")
