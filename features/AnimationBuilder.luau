local HttpService = game:GetService("HttpService")

local FOLDER = "Builder/timings"
if not isfolder(FOLDER) then makefolder(FOLDER) end

local M = {}
M.Timings = {}
M.Selected = nil

local function newTiming()
    return {
        name = "", _id = "", tag = "Undefined",
        imdd = 0, imxd = 1000, punishable = 0.6, after = 0.1,
        duih = false, hitbox = { X = 0, Y = 0, Z = 0 },
        fhb = true, hso = 0, bfht = 0.3,
        ndfb = false, nvfb = false, nbfb = false,
        umoa = false, smn = false, smod = "N/A", srpn = false,
        rpue = false, _rsd = 0, _rpd = 0,
        ha = false, iae = false, ieae = false, mat = 2000,
        phd = false, phds = 0.5, pfh = false, pfht = 0.15, dp = false,
        actions = {},
    }
end

local function timingPath(name) return FOLDER .. "/" .. name .. ".json" end

function M.SaveTiming(t) writefile(timingPath(t.name), HttpService:JSONEncode(t)) end

function M.LoadAll()
    M.Timings = {}
    if not isfolder(FOLDER) then return end
    for _, file in ipairs(listfiles(FOLDER)) do
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
        if ok and data and data.name then M.Timings[data.name] = data end
    end
end

function M.DeleteTiming(name)
    if isfile(timingPath(name)) then delfile(timingPath(name)) end
    M.Timings[name] = nil
    if M.Selected == name then M.Selected = nil end
end

function M.GetSelected()
    if not M.Selected then return nil end
    return M.Timings[M.Selected]
end

-- Setters (called by UI)
function M:SetEnabled(v) M.Enabled = v end
function M:SetLogCaptured(v) M.LogCaptured = v end
function M:SetAnimationID(v) M._pendingID = v end
function M:SetAnimationName(v) M._pendingName = v end
function M:SetDistance(v) M._pendingDist = v end
function M:SetDelay(v) M._pendingDelay = v end
function M:SetDodgeDirection(v) M._pendingDodge = v end
function M:SetHitbox(vec) M._pendingHitbox = vec end
function M:SetMSD(v) M._pendingMSD = v end
function M:SetIMOD(v) M._pendingIMOD = v end
function M:SetRepeat(v) M._pendingRepeat = v end
function M:SetRepeatDelay(v) M._pendingRepeatDelay = v end
function M:SetLiveLogger(v) M.LiveLogger = v end

function M:CreateTiming()
    local cfg = getgenv().BuilderConfig
    local name = cfg.AnimationName
    if not name or name == "" then return end
    if M.Timings[name] then return end

    local t = newTiming()
    t.name = name
    t._id = cfg.AnimationID
    t.imxd = cfg.IMOD
    t.imdd = cfg.MSD
    t.hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z }
    t.actions = {{
        name = "AutoParry", _type = "Parry",
        _when = math.floor(cfg.Delay * 1000),
        hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z },
    }}

    M.Timings[name] = t
    M.SaveTiming(t)
    M.Selected = name
end

function M:UpdateTiming()
    local t = M.GetSelected()
    if not t then return end
    local cfg = getgenv().BuilderConfig
    t._id = cfg.AnimationID
    t.imxd = cfg.IMOD
    t.imdd = cfg.MSD
    t.hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z }
    if t.actions[1] then
        t.actions[1]._when = math.floor(cfg.Delay * 1000)
        t.actions[1].hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z }
    end
    M.SaveTiming(t)
end

function M:RemoveTiming()
    if not M.Selected then return end
    M.DeleteTiming(M.Selected)
end

function M:Preview()
    local t = M.GetSelected()
    if not t then return end
    local HS = getgenv().HitboxSimModule
    if HS and HS.ShowFor then HS:ShowFor(t) end
end

function M:Visualize()
    local t = M.GetSelected()
    if not t then return end
    local HS = getgenv().HitboxSimModule
    if HS and HS.ShowFor then HS:ShowFor(t) end
end

function M:OpenLogger() M.LoggerOpen = true end

M.LoadAll()
getgenv().AnimationBuilderModule = M
return M
