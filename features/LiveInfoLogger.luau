-- [Roblox | Luau | Live Info Logger — hooks AnimationPlayed on all players, logs IDs]
-- Shows animation IDs as they play in real-time via notifications + internal log table

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.Connections = {}
M.PlayerConn = nil
M.Log = {}           -- list of { player, animId, time }
M.MaxEntries = 100   -- max log entries before oldest gets removed
M.NotifyOnLog = true -- show notification for each detected animation

local function addEntry(playerName, animId)
    local entry = {
        player = playerName,
        animId = animId,
        time = os.clock(),
    }
    table.insert(M.Log, 1, entry)
    if #M.Log > M.MaxEntries then
        table.remove(M.Log, #M.Log)
    end
    if M.NotifyOnLog then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Anim Logger",
                Text = ("%s → %s"):format(playerName, animId),
                Duration = 2,
            })
        end)
    end
end

local function hookCharacter(player)
    if player == LP then return end
    local function onChar(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        local conn = humanoid.AnimationPlayed:Connect(function(track)
            if not M.Enabled then return end
            local animId = tostring(track.Animation.AnimationId):match("(%d+)$") or "unknown"
            addEntry(player.Name, animId)
        end)
        M.Connections[player] = conn
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local function start()
    for _, p in ipairs(Players:GetPlayers()) do hookCharacter(p) end
    M.PlayerConn = Players.PlayerAdded:Connect(hookCharacter)
end

local function stop()
    for _, conn in pairs(M.Connections) do pcall(function() conn:Disconnect() end) end
    M.Connections = {}
    if M.PlayerConn then M.PlayerConn:Disconnect(); M.PlayerConn = nil end
end

function M:SetEnabled(v)
    M.Enabled = v
    if v then start() else stop() end
end

function M:GetLog()
    return M.Log
end

function M:ClearLog()
    M.Log = {}
end

function M:GetLastEntry()
    return M.Log[1]
end

getgenv().LiveInfoLoggerModule = M
return M
