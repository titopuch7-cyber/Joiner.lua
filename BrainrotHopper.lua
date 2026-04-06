-- =============================================
-- GROK AURORA SCOUT + MENÚ - Versión GitHub (Delta)
-- URL: https://raw.githubusercontent.com/titopuch7-cyber/Joiner.lua/refs/heads/main/BrainrotHopper.lua
-- =============================================

local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local WS = workspace
local SG = game:GetService("StarterGui")
local Players = game:GetService("Players")

local PLACE_ID = 109983668079237
local WEBHOOK = "https://discord.com/api/webhooks/1490801764817961152/XoDEkrwep6hS76a6eBfkDkkSW6R2-lxPjhQQUsRI9lVVu0ZutXVD9OwgdurFw9Bm9MKT"

local TARGETS = {50000000, 100000000, 250000000, 500000000}
local MAX_TIME = 13

-- Anti-duplicado
if getgenv().GrokGitHubScout then return end
getgenv().GrokGitHubScout = true

-- Auto-reinicio con TU URL REAL (esto es lo importante)
queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/titopuch7-cyber/Joiner.lua/refs/heads/main/BrainrotHopper.lua'))()")

-- ============== MENÚ GUI ==============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 340, 0, 300)
Frame.Position = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Frame.BorderSizePixel = 0
Frame.Parent = ScreenGui

Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 50)
Title.BackgroundTransparency = 1
Title.Text = "🚀 GROK SCOUT - GitHub"
Title.TextColor3 = Color3.fromRGB(0, 255, 120)
Title.TextScaled = true
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 35)
Status.Position = UDim2.new(0, 10, 0, 60)
Status.BackgroundTransparency = 1
Status.Text = "Estado: Cargando desde GitHub..."
Status.TextColor3 = Color3.fromRGB(255, 220, 0)
Status.TextScaled = true
Status.Font = Enum.Font.Gotham
Status.Parent = Frame

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, -20, 0, 25)
TimeLabel.Position = UDim2.new(0, 10, 0, 100)
TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "Tiempo en servidor: 0s"
TimeLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TimeLabel.TextScaled = true
TimeLabel.Parent = Frame

local LastAction = Instance.new("TextLabel")
LastAction.Size = UDim2.new(1, -20, 0, 25)
LastAction.Position = UDim2.new(0, 10, 0, 130)
LastAction.BackgroundTransparency = 1
LastAction.Text = "Última acción: Iniciado desde GitHub"
LastAction.TextColor3 = Color3.fromRGB(200, 200, 200)
LastAction.TextScaled = true
LastAction.Parent = Frame

-- Botones
local function createBtn(text, y, color, func)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 40)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.MouseButton1Click:Connect(func)
end

createBtn("🔄 Hop Ahora", 170, Color3.fromRGB(0, 100, 255), function() hop() end)
createBtn("❌ Cerrar Menú", 220, Color3.fromRGB(180, 40, 40), function() ScreenGui:Destroy() end)

-- ============== FUNCIONES ==============
local function notify(title, text)
    SG:SetCore("SendNotification", {Title = title, Text = text, Duration = 7})
    print("[" .. os.date("%H:%M:%S") .. "] " .. title .. " → " .. text)
end

local function updateStatus(txt, col)
    Status.Text = "Estado: " .. txt
    Status.TextColor3 = col or Color3.fromRGB(255, 220, 0)
end

local function findBrainrot()
    for _, obj in ipairs(WS:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("brain") or n:find("drop") or n:find("cerberus") or n:find("dragon") or 
           n:find("foxini") or n:find("hotspot") or n:find("lantern") then
            local val = nil
            if obj:FindFirstChild("Value") and typeof(obj.Value.Value) == "number" then val = obj.Value.Value
            elseif obj:FindFirstChild("BrainValue") then val = obj.BrainValue.Value
            elseif obj:FindFirstChild("Price") then val = obj.Price.Value
            elseif obj:GetAttribute("Value") then val = obj:GetAttribute("Value")
            end
            if val and typeof(val) == "number" then
                for _, t in ipairs(TARGETS) do
                    if val >= t then return {name = obj.Name, value = val} end
                end
            end
        end
    end
    return nil
end

local function sendToDiscord(info, count)
    local m = math.floor(info.value / 1000000)
    local data = {
        content = "**🚨 GROK AURORA FINDER**",
        embeds = {{
            title = "💎 BEST ENCONTRADO",
            description = info.name .. " **[$" .. m .. "M/s]**",
            color = 65280,
            fields = {
                {name = "Jugadores", value = count .. "/8", inline = true},
                {name = "Precio", value = "$" .. m .. "M/s", inline = true},
                {name = "JobId", value = "```" .. game.JobId .. "```", inline = false}
            }
        }}
    }
    pcall(function()
        HS:PostAsync(WEBHOOK, HS:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
end

local function hop()
    updateStatus("Hoppeando...", Color3.fromRGB(255, 80, 80))
    LastAction.Text = "Última acción: Hop manual"
    pcall(function() TS:Teleport(PLACE_ID) end)
end

local function checkServer()
    repeat task.wait(0.5) until game:IsLoaded()
    task.wait(3.5)

    local brain = findBrainrot()
    if brain then
        local m = math.floor(brain.value / 1000000)
        updateStatus("¡BRAINROT BUENO!", Color3.fromRGB(0, 255, 100))
        LastAction.Text = "Brainrot $" .. m .. "M encontrado"
        sendToDiscord(brain, #Players:GetPlayers())
        notify("🎉 ¡BRAINROT BUENO!", brain.name .. " $" .. m .. "M")
    else
        updateStatus("Buscando... (Hop en " .. MAX_TIME .. "s)", Color3.fromRGB(255, 255, 100))
    end
end

-- ============== INICIO ==============
notify("🚀 Grok Scout GitHub", "Cargado correctamente desde tu repo")
updateStatus("Iniciado correctamente", Color3.fromRGB(0, 255, 150))
LastAction.Text = "Última acción: Cargado desde GitHub"

checkServer()

local startTime = tick()
task.spawn(function()
    while true do
        task.wait(1)
        local elapsed = math.floor(tick() - startTime)
        TimeLabel.Text = "Tiempo en servidor: " .. elapsed .. "s"
        
        if elapsed >= MAX_TIME then
            if not findBrainrot() then
                hop()
                startTime = tick()
            end
        end
    end
end)

Players.LocalPlayer.CharacterAdded:Connect(function()
    task.wait(3)
    startTime = tick()
    checkServer()
end)

print("✅ Menú cargado desde GitHub. Ahora prueba hoppear.")
