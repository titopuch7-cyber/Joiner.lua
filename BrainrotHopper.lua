-- ╔══════════════════════════════════════════════════════════════╗
-- ║           BRAINROT HOPPER — Server Scanner Real            ║
-- ║  Salta de servidor en servidor leyendo brainrots reales    ║
-- ╚══════════════════════════════════════════════════════════════╝
-- Ejecuta desde dentro de Steal a Brainrot con tu executor

local Players         = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService     = game:GetService("HttpService")
local RunService      = game:GetService("RunService")
local UserInput       = game:GetService("UserInputService")
local LocalPlayer     = Players.LocalPlayer
local PLACE_ID        = game.PlaceId

-- ── RARIDADES ────────────────────────────────────────────────
-- Precio aproximado en el juego (para calcular valor del lobby)
local RARITY_VALUE = {
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
    else return "$"..tostring(n) end
end

-- ── LEER BRAINROTS DEL SERVIDOR ACTUAL ──────────────────────
local function leerBrainrots()
    local found = {}

    -- Buscar en todas las estructuras posibles del juego
    local searchRoots = {
        workspace,
        game:GetService("ReplicatedStorage"),
    }

    local function scanFolder(folder, depth)
        if depth > 6 then return end
        for _, obj in ipairs(folder:GetChildren()) do
            -- Buscar atributos de raridad directamente
            local rarity = obj:GetAttribute("Rarity")
                        or obj:GetAttribute("rarity")
                        or obj:GetAttribute("PetRarity")

            -- Buscar StringValues dentro
            if not rarity then
                local rv = obj:FindFirstChild("Rarity") or obj:FindFirstChild("rarity")
                if rv and rv:IsA("StringValue") then
                    rarity = rv.Value
                end
            end

            -- Buscar por nombre de carpeta (algunos juegos usan carpetas por raridad)
            if not rarity and RARITY_VALUE[obj.Name] then
                rarity = obj.Name
            end

            -- Buscar gen/sec
            local genPerSec = obj:GetAttribute("Generation")
                           or obj:GetAttribute("GenPerSec")
                           or obj:GetAttribute("MoneyPerSecond")
                           or obj:GetAttribute("Income")

            if genPerSec and type(genPerSec) == "string" then
                local num = tonumber(genPerSec:match("[%d%.]+"))
                local mult = genPerSec:find("T") and 1e12
                          or genPerSec:find("B") and 1e9
                          or genPerSec:find("M") and 1e6
                          or genPerSec:find("K") and 1e3
                          or 1
                genPerSec = num and (num * mult) or nil
            end

            if rarity and RARITY_VALUE[rarity] then
                table.insert(found, {
                    name      = obj.Name,
                    rarity    = rarity,
                    value     = RARITY_VALUE[rarity],
                    genPerSec = genPerSec,
                    instance  = obj,
                })
            else
                -- Seguir buscando dentro
                if obj:IsA("Folder") or obj:IsA("Model") or obj:IsA("Configuration") then
                    scanFolder(obj, depth + 1)
                end
            end
        end
    end

    for _, root in ipairs(searchRoots) do
        pcall(scanFolder, root, 0)
    end

    -- Quitar duplicados por nombre
    local seen = {}
    local unique = {}
    for _, b in ipairs(found) do
        local key = b.name .. b.rarity
        if not seen[key] then
            seen[key] = true
            table.insert(unique, b)
        end
    end

    -- Ordenar por valor descendente
    table.sort(unique, function(a, b) return a.value > b.value end)
    return unique
end

-- ── UI ───────────────────────────────────────────────────────
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

-- Degradado de fondo
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
SubLbl.Text = "Lee los brainrots REALES de este servidor"
SubLbl.TextColor3 = Color3.fromRGB(255, 180, 80)
SubLbl.TextSize = 12
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

-- Panel de info del servidor actual
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
ServerLbl.Text = "📍 Servidor actual: " .. string.sub(game.JobId, 1, 20) .. "..."
ServerLbl.TextColor3 = Color3.fromRGB(180, 160, 220)
ServerLbl.TextSize = 12
ServerLbl.Font = Enum.Font.Gotham
ServerLbl.TextXAlignment = Enum.TextXAlignment.Left
ServerLbl.Parent = InfoPanel

local ValueLbl = Instance.new("TextLabel")
ValueLbl.Size = UDim2.new(0.5, -12, 0, 24)
ValueLbl.Position = UDim2.new(0, 12, 0, 32)
ValueLbl.BackgroundTransparency = 1
ValueLbl.Text = "💰 Valor total: escaneando..."
ValueLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
ValueLbl.TextSize = 13
ValueLbl.Font = Enum.Font.GothamBold
ValueLbl.TextXAlignment = Enum.TextXAlignment.Left
ValueLbl.Parent = InfoPanel

local CountLbl = Instance.new("TextLabel")
CountLbl.Size = UDim2.new(0.5, -12, 0, 24)
CountLbl.Position = UDim2.new(0.5, 0, 0, 32)
CountLbl.BackgroundTransparency = 1
CountLbl.Text = "🧠 Brainrots: —"
CountLbl.TextColor3 = Color3.fromRGB(200, 160, 255)
CountLbl.TextSize = 13
CountLbl.Font = Enum.Font.GothamBold
CountLbl.TextXAlignment = Enum.TextXAlignment.Left
CountLbl.Parent = InfoPanel

-- Separador con label
local SepLbl = Instance.new("TextLabel")
SepLbl.Size = UDim2.new(1, -24, 0, 18)
SepLbl.Position = UDim2.new(0, 12, 0, 158)
SepLbl.BackgroundTransparency = 1
SepLbl.Text = "BRAINROTS EN ESTE SERVIDOR  (ordenados por valor)"
SepLbl.TextColor3 = Color3.fromRGB(255, 140, 0)
SepLbl.TextSize = 10
SepLbl.Font = Enum.Font.GothamBold
SepLbl.TextXAlignment = Enum.TextXAlignment.Left
SepLbl.Parent = Main

-- Lista scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -24, 1, -326)
Scroll.Position = UDim2.new(0, 12, 0, 178)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.ScrollBarImageColor3 = Color3.fromRGB(255, 140, 0)
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.Parent = Main

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0, 6)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Panel inferior: botones de acción
local BottomPanel = Instance.new("Frame")
BottomPanel.Size = UDim2.new(1, -24, 0, 110)
BottomPanel.Position = UDim2.new(0, 12, 1, -120)
BottomPanel.BackgroundColor3 = Color3.fromRGB(15, 12, 25)
BottomPanel.BorderSizePixel = 0
BottomPanel.Parent = Main
Instance.new("UICorner", BottomPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", BottomPanel).Color = Color3.fromRGB(50, 40, 80)

-- Filtro de raridad mínima
local FilterLbl = Instance.new("TextLabel")
FilterLbl.Size = UDim2.new(1, -12, 0, 18)
FilterLbl.Position = UDim2.new(0, 12, 0, 8)
FilterLbl.BackgroundTransparency = 1
FilterLbl.Text = "FILTRO: saltar auto si NO hay al menos..."
FilterLbl.TextColor3 = Color3.fromRGB(140, 120, 180)
FilterLbl.TextSize = 10
FilterLbl.Font = Enum.Font.GothamBold
FilterLbl.TextXAlignment = Enum.TextXAlignment.Left
FilterLbl.Parent = BottomPanel

local rarityOptions = {"Common","Uncommon","Rare","Epic","Legendary","Mythic","Secret","Brainrot God"}
local selectedRarity = "Epic"
local rarityBtns = {}

local rarityRow = Instance.new("Frame")
rarityRow.Size = UDim2.new(1, -12, 0, 28)
rarityRow.Position = UDim2.new(0, 6, 0, 28)
rarityRow.BackgroundTransparency = 1
rarityRow.Parent = BottomPanel

local rarityLayout = Instance.new("UIListLayout", rarityRow)
rarityLayout.FillDirection = Enum.FillDirection.Horizontal
rarityLayout.Padding = UDim.new(0, 4)

local function updateRarityBtns()
    local targetIdx = table.find(rarityOptions, selectedRarity) or 1
    for i, btn in ipairs(rarityBtns) do
        if i == targetIdx then
            btn.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
            btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        else
            btn.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
            btn.TextColor3 = Color3.fromRGB(160, 140, 200)
        end
    end
end

for i, r in ipairs(rarityOptions) do
    local short = r == "Brainrot God" and "GOD"
              or r == "Uncommon" and "UC"
              or r == "Legendary" and "LEG"
              or r:sub(1,3):upper()
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 28, 55)
    btn.Text = short
    btn.TextColor3 = Color3.fromRGB(160, 140, 200)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    btn.Parent = rarityRow
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(rarityBtns, btn)
    btn.MouseButton1Click:Connect(function()
        selectedRarity = r
        updateRarityBtns()
    end)
end
updateRarityBtns()

-- Botones principales
local ScanBtn = Instance.new("TextButton")
ScanBtn.Size = UDim2.new(0.48, -4, 0, 36)
ScanBtn.Position = UDim2.new(0, 8, 0, 66)
ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)
ScanBtn.Text = "🔍  ESCANEAR ESTE SERVER"
ScanBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ScanBtn.TextSize = 12
ScanBtn.Font = Enum.Font.GothamBold
ScanBtn.BorderSizePixel = 0
ScanBtn.Parent = BottomPanel
Instance.new("UICorner", ScanBtn).CornerRadius = UDim.new(0, 10)

local HopBtn = Instance.new("TextButton")
HopBtn.Size = UDim2.new(0.48, -4, 0, 36)
HopBtn.Position = UDim2.new(0.52, -4, 0, 66)
HopBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 100)
HopBtn.Text = "⏭  SALTAR AL SIGUIENTE"
HopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HopBtn.TextSize = 12
HopBtn.Font = Enum.Font.GothamBold
HopBtn.BorderSizePixel = 0
HopBtn.Parent = BottomPanel
Instance.new("UICorner", HopBtn).CornerRadius = UDim.new(0, 10)

-- ── HACER DRAGGABLE ──────────────────────────────────────────
do
    local drag, ds, sp
    Header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            drag=true; ds=i.Position; sp=Main.Position
        end
    end)
    Header.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UserInput.InputChanged:Connect(function(i)
        if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - ds
            Main.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
end

-- ── RENDERIZAR LISTA DE BRAINROTS ────────────────────────────
local function limpiarScroll()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    Scroll.CanvasSize = UDim2.new(0,0,0,0)
end

local function renderBrainrots(brainrots)
    limpiarScroll()

    if #brainrots == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, -8, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "😕  No se encontraron brainrots en este servidor\n(puede que el juego use otra estructura interna)"
        empty.TextColor3 = Color3.fromRGB(120, 100, 160)
        empty.TextSize = 13
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.LayoutOrder = 1
        empty.Parent = Scroll
        Scroll.CanvasSize = UDim2.new(0,0,0,70)
        return
    end

    for i, b in ipairs(brainrots) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 52)
        row.BackgroundColor3 = Color3.fromRGB(20, 16, 32)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.Parent = Scroll
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 10)

        -- Barra de color de raridad a la izquierda
        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(0, 5, 1, -10)
        bar.Position = UDim2.new(0, 6, 0, 5)
        bar.BackgroundColor3 = RARITY_COLOR[b.rarity] or Color3.fromRGB(100,100,100)
        bar.BorderSizePixel = 0
        bar.Parent = row
        Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 3)

        -- Número
        local numLbl = Instance.new("TextLabel")
        numLbl.Size = UDim2.new(0, 24, 1, 0)
        numLbl.Position = UDim2.new(0, 14, 0, 0)
        numLbl.BackgroundTransparency = 1
        numLbl.Text = "#"..i
        numLbl.TextColor3 = Color3.fromRGB(90, 80, 120)
        numLbl.TextSize = 11
        numLbl.Font = Enum.Font.GothamBold
        numLbl.Parent = row

        -- Nombre
        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(0.45, 0, 0, 26)
        nameLbl.Position = UDim2.new(0, 42, 0, 6)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = b.name
        nameLbl.TextColor3 = Color3.fromRGB(240, 230, 255)
        nameLbl.TextSize = 13
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = row

        -- Raridad chip
        local chip = Instance.new("TextLabel")
        chip.Size = UDim2.new(0, 0, 0, 18)
        chip.AutomaticSize = Enum.AutomaticSize.X
        chip.Position = UDim2.new(0, 42, 0, 32)
        chip.BackgroundColor3 = RARITY_COLOR[b.rarity] or Color3.fromRGB(80,80,80)
        chip.BackgroundTransparency = 0.5
        chip.Text = "  " .. (RARITY_LABEL[b.rarity] or b.rarity) .. "  "
        chip.TextColor3 = Color3.fromRGB(255,255,255)
        chip.TextSize = 10
        chip.Font = Enum.Font.GothamBold
        chip.BorderSizePixel = 0
        chip.Parent = row
        Instance.new("UICorner", chip).CornerRadius = UDim.new(0, 5)

        -- Valor
        local valLbl = Instance.new("TextLabel")
        valLbl.Size = UDim2.new(0, 90, 0, 22)
        valLbl.Position = UDim2.new(1, -100, 0, 6)
        valLbl.BackgroundTransparency = 1
        valLbl.Text = formatMoney(b.value)
        valLbl.TextColor3 = Color3.fromRGB(80, 220, 120)
        valLbl.TextSize = 15
        valLbl.Font = Enum.Font.GothamBold
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent = row

        -- Gen/sec si disponible
        if b.genPerSec then
            local genLbl = Instance.new("TextLabel")
            genLbl.Size = UDim2.new(0, 90, 0, 16)
            genLbl.Position = UDim2.new(1, -100, 0, 28)
            genLbl.BackgroundTransparency = 1
            genLbl.Text = formatMoney(b.genPerSec) .. "/s"
            genLbl.TextColor3 = Color3.fromRGB(255, 200, 60)
            genLbl.TextSize = 11
            genLbl.Font = Enum.Font.Gotham
            genLbl.TextXAlignment = Enum.TextXAlignment.Right
            genLbl.Parent = row
        end
    end

    Scroll.CanvasSize = UDim2.new(0, 0, 0, #brainrots * 58)
end

-- ── ESCANEAR ─────────────────────────────────────────────────
local function escanear()
    ScanBtn.Text = "⏳  Escaneando..."
    ScanBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 0)

    local brainrots = leerBrainrots()

    -- Calcular valor total
    local totalValue = 0
    for _, b in ipairs(brainrots) do
        totalValue = totalValue + b.value
    end

    ValueLbl.Text = "💰 Valor total: " .. formatMoney(totalValue)
    CountLbl.Text = "🧠 Brainrots: " .. #brainrots

    renderBrainrots(brainrots)

    ScanBtn.Text = "🔍  ESCANEAR ESTE SERVER"
    ScanBtn.BackgroundColor3 = Color3.fromRGB(255, 130, 0)

    -- Auto-check: ¿hay alguno de la raridad seleccionada o mejor?
    local minValue = RARITY_VALUE[selectedRarity] or 0
    local hasBueno = false
    for _, b in ipairs(brainrots) do
        if b.value >= minValue then
            hasBueno = true
            break
        end
    end

    return brainrots, hasBueno
end

-- ── OBTENER SIGUIENTE SERVIDOR ───────────────────────────────
local serverQueue = {}
local queueCursor = nil
local queueLoaded = false

local function cargarServidores()
    local ok, data = pcall(function()
        local url = "https://games.roblox.com/v1/games/"..PLACE_ID
                  .."/servers/Public?limit=100"
                  ..(queueCursor and ("&cursor="..queueCursor) or "")
        return HttpService:JSONDecode(game:HttpGet(url, true))
    end)
    if ok and data then
        for _, s in ipairs(data.data or {}) do
            if s.id ~= game.JobId then
                table.insert(serverQueue, s.id)
            end
        end
        queueCursor = data.nextPageCursor
    end
    queueLoaded = true
end

local function siguienteServidor()
    if #serverQueue == 0 then
        cargarServidores()
        task.wait(1)
    end
    if #serverQueue == 0 then
        warn("No hay más servidores disponibles")
        return
    end
    local nextId = table.remove(serverQueue, 1)
    HopBtn.Text = "⏳  Saltando..."
    HopBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    TeleportService:TeleportToPlaceInstance(PLACE_ID, nextId, LocalPlayer)
end

-- ── BOTONES ──────────────────────────────────────────────────
ScanBtn.MouseButton1Click:Connect(function()
    task.spawn(escanear)
end)

HopBtn.MouseButton1Click:Connect(function()
    task.spawn(siguienteServidor)
end)

-- ── ESCANEO AUTOMÁTICO AL CARGAR ─────────────────────────────
task.delay(2, function()
    -- Esperar a que el juego cargue bien
    task.spawn(function()
        cargarServidores()  -- precargar cola de servidores
    end)
    escanear()
end)

-- Notificación
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🧠 Brainrot Hopper";
    Text = "Cargado! Escaneando servidor actual...";
    Duration = 3;
})

print("✅ BrainrotHopper listo")
