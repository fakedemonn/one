local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.Connections = {}

-- CONFIGURE FOR YOUR GAME
M.ParryKey = Enum.KeyCode.Q
M.ParryMethod = "keypress"   -- "keypress" or "remote"
M.ParryRemote = nil           -- set RemoteEvent if using "remote"

local function fireParry()
    if M.ParryMethod == "remote" and M.ParryRemote then
        pcall(function() M.ParryRemote:FireServer() end)
    else
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, M.ParryKey, false, game)
            task.delay(0.05, function()
                VirtualInputManager:SendKeyEvent(false, M.ParryKey, false, game)
            end)
        end)
    end
end

local function inRange(timing, otherChar)
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local theirRoot = otherChar and otherChar:FindFirstChild("HumanoidRootPart")
    if not myRoot or not theirRoot then return false end
    local dist = (myRoot.Position - theirRoot.Position).Magnitude
    return dist >= (timing.imdd or 0) and dist <= (timing.imxd or 1000)
end

local function onAnimationPlayed(track, character, player)
    if not M.Enabled or player == LP then return end
    local animId = tostring(track.Animation.AnimationId):match("(%d+)$") or ""
    if animId == "" then return end

    local AB = getgenv().AnimationBuilderModule
    if not AB then return end

    for _, timing in pairs(AB.Timings) do
        if timing._id ~= animId then continue end
        if not inRange(timing, character) then continue end

        local parryAction = nil
        for _, action in ipairs(timing.actions) do
            if action._type == "Parry" then parryAction = action; break end
        end
        if not parryAction then continue end

        task.delay((parryAction._when or 0) / 1000, function()
            if M.Enabled then fireParry() end
        end)

        if timing.rpue and timing._rpd and timing._rpd > 0 then
            task.delay((timing._rsd or 0) / 1000, function()
                for i = 1, 10 do
                    if not M.Enabled then break end
                    task.wait(timing._rpd / 1000)
                    fireParry()
                end
            end)
        end
        break
    end
end

local function hookCharacter(player)
    local function onChar(character)
        local humanoid = character:WaitForChild("Humanoid", 10)
        if not humanoid then return end
        M.Connections[player] = humanoid.AnimationPlayed:Connect(function(track)
            onAnimationPlayed(track, character, player)
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local function start()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP then hookCharacter(p) end
    end
    M.PlayerConn = Players.PlayerAdded:Connect(function(p)
        if p ~= LP then hookCharacter(p) end
    end)
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

getgenv().AutoParryModule = M
return M
