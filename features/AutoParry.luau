-- [Roblox | Luau | Universal Auto-Parry — capture, save, parry in any game]
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local FOLDER = "Builder/timings"
if not isfolder(FOLDER) then makefolder(FOLDER) end

local M = {}
M.Timings = {}
M.Enabled = false
M.CaptureMode = false
M.LogMode = false
M.ParryKey = Enum.KeyCode.Q
M.ParryMethod = "keypress"   -- "keypress" | "remote"
M.ParryRemote = nil
M._capturedID = ""
M.Connections = {}
M.PlayerConn = nil

local function notify(text, dur)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Auto Parry", Text = text, Duration = dur or 3 })
    end)
end

-- ── STORAGE (local files only) ──
local function path(name) return FOLDER .. "/" .. name .. ".json" end

function M.Save(t) writefile(path(t.name), HttpService:JSONEncode(t)) end

function M.LoadAll()
    M.Timings = {}
    if not isfolder(FOLDER) then return end
    for _, f in ipairs(listfiles(FOLDER)) do
        local ok, d = pcall(function() return HttpService:JSONDecode(readfile(f)) end)
        if ok and d and d._id then M.Timings[d._id] = d end
    end
end

function M.ClearAll()
    if isfolder(FOLDER) then
        for _, f in ipairs(listfiles(FOLDER)) do pcall(function() delfile(f) end) end
    end
    M.Timings = {}
end

function M.RemoveByName(name)
    for id, t in pairs(M.Timings) do
        if t.name == name then
            if isfile(path(name)) then delfile(path(name)) end
            M.Timings[id] = nil
            return id
        end
    end
    return nil
end

function M.Count() local c = 0 for _ in pairs(M.Timings) do c = c + 1 end return c end

-- ── PARRY TRIGGER ──
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

-- remote sniff: press your parry manually once and it grabs the remote
local sniffing = false
local oldNC
oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if sniffing and not checkcaller() and getnamecallmethod() == "FireServer"
        and typeof(self) == "Instance" and self:IsA("RemoteEvent") then
        sniffing = false
        M.ParryMethod = "remote"
        M.ParryRemote = self
        notify("Parry remote bound: " .. self:GetFullName(), 4)
    end
    return oldNC(self, ...)
end))

function M:SniffRemote()
    sniffing = true
    notify("Sniffing — press your parry key manually once.", 4)
end

-- ── CORE ──
local function inRange(range, char)
    local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local their = char and char:FindFirstChild("HumanoidRootPart")
    if not my or not their then return false end
    return (my.Position - their.Position).Magnitude <= (range or 100)
end

local function onAnimationPlayed(track, char, player)
    local anim = track and track.Animation
    local id = anim and tostring(anim.AnimationId):match("(%d+)$") or nil
    if not id then return end

    if M.LogMode then
        notify(("%s → %s"):format(player.Name, id), 2)
    end

    if M.CaptureMode then
        M.CaptureMode = false
        M._capturedID = id
        notify("Captured: " .. id .. " — now hit Create Timing.", 5)
        return
    end

    if not M.Enabled then return end
    local t = M.Timings[id]
    if not t then return end
    if not inRange(t.range, char) then return end

    task.delay(t.delay or 0, function()
        if M.Enabled then fireParry() end
    end)
end

local function hookCharacter(player)
    if player == LP then return end
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        M.Connections[player] = hum.AnimationPlayed:Connect(function(track)
            onAnimationPlayed(track, char, player)
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

for _, p in ipairs(Players:GetPlayers()) do hookCharacter(p) end
M.PlayerConn = Players.PlayerAdded:Connect(hookCharacter)

-- ── API ──
function M:SetEnabled(v)
    M.Enabled = v
    notify(v and ("Auto-parry ON (%d timings)"):format(M:Count()) or "Auto-parry OFF", 2)
end

function M:SetCapture(v)
    M.CaptureMode = v
    if v then notify("Capture armed — let an enemy swing at you.", 3) end
end

function M:SetLog(v) M.LogMode = v end

function M:Create(name, id, delay, range)
    if not id or id == "" then return nil end
    name = (name and name ~= "") and name or ("Parry_" .. id)
    if M.Timings[id] then return nil end
    local t = { name = name, _id = id, delay = delay or 0, range = range or 100 }
    M.Timings[id] = t
    M.Save(t)
    return t
end

M.LoadAll()
getgenv().AutoParryModule = M
return M
