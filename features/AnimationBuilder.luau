local HttpService = game:GetService("HttpService")

local FOLDER = "Builder/timings"
if not isfolder(FOLDER) then makefolder(FOLDER) end

-- YOUR GitHub timings (read-only, ships to everyone)
local GIT_TIMINGS = "https://raw.githubusercontent.com/fakedemonn/one/main/timings/"
local GIT_LIST_URL = "https://api.github.com/repos/fakedemonn/one/contents/timings"

local M = {}
M.GitTimings = {}   -- your curated list (from GitHub)
M.LocalTimings = {} -- user's own (from their folder)
M.Selected = nil
M.Enabled = false
M.LogCaptured = false
M.LiveLogger = false
M.LoggerOpen = false

-- Combined view: what auto-parry actually checks
function M.AllTimings()
    local all = {}
    for k, v in pairs(M.GitTimings) do all[k] = v end
    for k, v in pairs(M.LocalTimings) do all[k] = v end -- local overrides git if same name
    return all
end
-- keep old code that reads M.Timings working:
setmetatable(M, {
    __index = function(t, k)
        if k == "Timings" then return M.AllTimings() end
        return rawget(M, k)
    end
})

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

-- ── LOAD FROM GITHUB (your list) ──
function M.LoadFromGit()
    M.GitTimings = {}
    local ok, list = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(GIT_LIST_URL))
    end)
    if not ok or type(list) ~= "table" then return end
    for _, entry in ipairs(list) do
        if entry.name and entry.download_url and entry.name:match("%.json$") then
            local sok, data = pcall(function()
                return HttpService:JSONDecode(game:HttpGet(entry.download_url))
            end)
            if sok and data and data.name then
                M.GitTimings[data.name] = data
            end
        end
    end
end

-- ── LOAD FROM LOCAL (user's own) ──
function M.LoadLocal()
    M.LocalTimings = {}
    if not isfolder(FOLDER) then return end
    for _, file in ipairs(listfiles(FOLDER)) do
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(file)) end)
        if ok and data and data.name then M.LocalTimings[data.name] = data end
    end
end

function M.LoadAll()
    M.LoadFromGit()
    M.LoadLocal()
end

-- ── SAVE / DELETE (local only — never touches GitHub) ──
function M.SaveTiming(t) writefile(timingPath(t.name), HttpService:JSONEncode(t)) end

function M.DeleteTiming(name)
    if isfile(timingPath(name)) then delfile(timingPath(name)) end
    M.LocalTimings[name] = nil
    if M.Selected == name then M.Selected = nil end
end

function M.ClearAll()
    local count = 0
    if isfolder(FOLDER) then
        for _, file in ipairs(listfiles(FOLDER)) do
            pcall(function() delfile(file) end); count = count + 1
        end
    end
    M.LocalTimings = {}
    M.Selected = nil
    return count
end

function M.GetSelected()
    if not M.Selected then return nil end
    return M.AllTimings()[M.Selected]
end

function M.Count()
    local c = 0
    for _ in pairs(M.AllTimings()) do c = c + 1 end
    return c
end

function M.IsGit(name) return M.GitTimings[name] ~= nil end

-- ── SETTERS ──
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

-- ── CREATE / UPDATE / REMOVE (local only) ──
function M:CreateTiming()
    local cfg = getgenv().BuilderConfig
    local name = cfg.AnimationName
    if not name or name == "" then return nil end
    if M.GitTimings[name] then return nil end      -- can't overwrite a GitHub timing
    if M.LocalTimings[name] then return nil end

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

    M.LocalTimings[name] = t
    M.SaveTiming(t)
    M.Selected = name
    return t
end

function M:UpdateTiming()
    local t = M.GetSelected()
    if not t then return nil end
    if M.IsGit(t.name) then return nil end   -- GitHub timings are read-only
    local cfg = getgenv().BuilderConfig
    t._id = cfg.AnimationID
    t.imxd = cfg.IMOD
    t.imdd = cfg.MSD
    t.hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z }
    if t.actions[1] then
        t.actions[1]._when = math.floor(cfg.Delay * 1000)
        t.actions[1].hitbox = { X = cfg.Hitbox.X, Y = cfg.Hitbox.Y, Z = cfg.Hitbox.Z }
    end
    M.LocalTimings[t.name] = t
    M.SaveTiming(t)
    return t
end

function M:RemoveTiming()
    if not M.Selected then return nil end
    if M.IsGit(M.Selected) then return nil end  -- can't delete a GitHub timing
    local name = M.Selected
    M.DeleteTiming(name)
    return name
end

function M:Preview() return M.GetSelected() end

function M:Visualize()
    local t = M.GetSelected()
    if not t then return nil end
    local HS = getgenv().HitboxSimModule or getgenv().AnimationVisualizerModule
    if HS and HS.ShowFor then HS:ShowFor(t) end
    return t
end

function M:OpenLogger() M.LoggerOpen = true; M.LiveLogger = true end

-- Load both on start
M.LoadAll()

getgenv().AnimationBuilderModule = M
return M
