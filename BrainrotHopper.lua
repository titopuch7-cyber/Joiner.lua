-- =============================================
-- GROK BRAINROT HOPPER - Versión Auto-Execute para Delta
-- Se ejecuta automáticamente cada vez que entras a un servidor
-- =============================================

local TS = game:GetService("TeleportService")
local HS = game:GetService("HttpService")
local WS = workspace
local SG = game:GetService("StarterGui")
local Players = game:GetService("Players")

local PLACE_ID = 109983668079237
local WEBHOOK = "https://discord.com/api/webhooks/1490801764817961152/XoDEkrwep6hS76a6eBfkDkkSW6R2-lxPjhQQUsRI9lVVu0ZutXVD9OwgdurFw9Bm9MKT"

local TARGETS = {50000000, 100000000, 250000000, 500000000}
local MAX_TIME = 12

-- Anti-duplicado
if getgenv().GrokAutoExecScout then return end
getgenv().GrokAutoExecScout = true

local function notify(title, text)
    SG:SetCore("SendNotification", {Title = title, Text = text, Duration = 8})
    print("[" .. os.date("%H:%M:%S") .. "] " .. title .. " → " .. text)
end

local function findBrainrot()
    for _, obj in ipairs(WS:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("brain") or n:find("drop") or n:find("cerberus") or n:find("dragon") or 
           n:find("foxini") or n:find("hotspot") or n:find("lantern") then
            
            local val = nil
            if obj:FindFirstChild("Value") and typeof(obj.Value.Value) == "number" then 
                val = obj.Value.Value
            elseif obj:FindFirstChild("BrainValue") then 
                val = obj.BrainValue.Value
            elseif obj:FindFirstChild("Price") then 
                val = obj.Price.Value
            elseif obj:GetAttribute("Value") then 
                val = obj:GetAttribute("Value")
            end
            
            if val and typeof(val) == "number" then
                for _, t in ipairs(TARGETS) do
                    if val >= t then
                        return {name = obj.Name, value = val}
                    end
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
    notify("🔄 HOPPEANDO", "Cambiando a nuevo servidor...")
    pcall(function()
        TS:Teleport(PLACE_ID)
    end)
end

local function checkServer()
    repeat task.wait(0.5) until game:IsLoaded()
    task.wait(3.5)

    local brain = findBrainrot()
    if brain then
        local m = math.floor(brain.value / 1000000)
        notify("🎉 ¡BRAINROT BUENO!", brain.name .. " $" .. m .. "M")
        sendToDiscord(brain, #Players:GetPlayers())
        notify("✅ Servidor bueno", "Scout detenido aquí")
    else
        hop()
    end
end

-- ====================== INICIO ======================
notify("🚀 Grok Hopper (Auto-Execute)", "Iniciado correctamente - Buscando 50M+")
checkServer()

-- Hop forzado cada MAX_TIME segundos
task.spawn(function()
    while true do
        task.wait(MAX_TIME)
        if not findBrainrot() then
            hop()
        end
    end
end)

print("✅ Grok Hopper Auto-Execute cargado correctamente")
