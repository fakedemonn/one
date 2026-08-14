local repo     = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local featRepo = 'https://raw.githubusercontent.com/fakedemonn/one/main/features/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- ════════════════════════════════════════════════════════════
-- LOAD FEATURES
-- ════════════════════════════════════════════════════════════
local function loadFeature(file)
    local ok, mod = pcall(function()
        return loadstring(game:HttpGet(featRepo .. file))()
    end)
    if not ok or type(mod) ~= 'table' then
        warn('[Builder] failed: ' .. file)
        return nil
    end
    return mod
end

local AutoParry           = loadFeature('AutoParry.luau')
local InfoLoggerUI        = loadFeature('LiveInfoLogger.luau')
local AnimationVisualizer = loadFeature('AnimationVisualizer.luau')

local function callMod(mod, method, ...)
    if mod and type(mod[method]) == 'function' then
        return mod[method](mod, ...)
    end
end

-- ════════════════════════════════════════════════════════════
-- UI
-- ════════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = 'Auto Parry', Center = true, AutoShow = true,
    TabPadding = 8, MenuFadeTime = 0.2,
})

local Tabs = {
    Parry           = Window:AddTab('Auto Parry'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ── BUILDER (left) ──
local BuildGroup = Tabs.Parry:AddLeftGroupbox('Builder')

BuildGroup:AddToggle('EnableAutoParry', {
    Text = 'Enable Auto-Parry', Default = false,
    Callback = function(v) callMod(AutoParry, 'SetEnabled', v) end,
})

BuildGroup:AddToggle('CaptureMode', {
    Text = 'Capture Next Attack', Default = false,
    Callback = function(v) callMod(AutoParry, 'SetCapture', v) end,
})

BuildGroup:AddToggle('LogIDs', {
    Text = 'Live ID Logger', Default = false,
    Callback = function(v) callMod(AutoParry, 'SetLog', v) end,
})

BuildGroup:AddInput('AnimationID', {
    Text = 'Animation ID', Default = '', Placeholder = 'or use capture',
})

BuildGroup:AddInput('TimingName', {
    Text = 'Name', Default = '', Placeholder = 'e.g. Katana M1',
})

BuildGroup:AddSlider('ParryDelay', {
    Text = 'Parry Delay (s)', Default = 0, Min = 0, Max = 1, Rounding = 2, Suffix = 's',
})

BuildGroup:AddSlider('ParryRange', {
    Text = 'Range (studs)', Default = 100, Min = 10, Max = 300, Rounding = 0,
})

BuildGroup:AddButton({
    Text = 'Create Timing',
    Func = function()
        if not AutoParry then Library:Notify('AutoParry failed to load.', 3) return end
        local id = Options.AnimationID.Value
        if not id or id == "" then id = AutoParry._capturedID end
        local t = AutoParry:Create(Options.TimingName.Value, id,
            Options.ParryDelay.Value, Options.ParryRange.Value)
        if t then
            CountLabel:SetText('Saved timings: ' .. AutoParry:Count())
            refreshList()
            Library:Notify('Created: ' .. t.name, 3)
        else
            Library:Notify('No ID (capture first) or already exists.', 3)
        end
    end,
})

-- ── SAVED LIST (left, below) ──
local ListGroup = Tabs.Parry:AddLeftGroupbox('Saved Timings')

local CountLabel = ListGroup:AddLabel('Saved timings: 0')

ListGroup:AddDropdown('TimingList', {
    Values = {}, AllowNull = true, Text = 'Saved timings',
})

local function refreshList()
    if not AutoParry then return end
    local names = {}
    for _, t in pairs(AutoParry.Timings) do names[#names + 1] = t.name end
    table.sort(names)
    Options.TimingList:SetValues(names)
end

ListGroup:AddButton({
    Text = 'Remove Selected', DoubleClick = true,
    Func = function()
        local sel = Options.TimingList.Value
        if not sel or sel == "" then Library:Notify('Select one first.', 2) return end
        callMod(AutoParry, 'RemoveByName', sel)
        CountLabel:SetText('Saved timings: ' .. (AutoParry and AutoParry:Count() or 0))
        refreshList()
        Library:Notify('Removed: ' .. sel, 2)
    end,
})

ListGroup:AddButton({
    Text = 'Clear All', DoubleClick = true,
    Func = function()
        callMod(AutoParry, 'ClearAll')
        CountLabel:SetText('Saved timings: 0')
        refreshList()
        Library:Notify('All timings wiped.', 2)
    end,
})

ListGroup:AddButton({
    Text = 'Refresh',
    Func = function()
        callMod(AutoParry, 'LoadAll')
        refreshList()
        CountLabel:SetText('Saved timings: ' .. (AutoParry and AutoParry:Count() or 0))
    end,
})

-- ── VISUALIZER / LOGGER (right) ──
local ViewGroup = Tabs.Parry:AddRightGroupbox('Visualizer & Logger')

ViewGroup:AddButton({
    Text = 'Animation Visualizer',
    Func = function() callMod(AnimationVisualizer, 'SetEnabled', true) end,
    Tooltip = 'Opens 3D preview + Quick Edit Timing window',
})

ViewGroup:AddButton({
    Text = 'Info Logger',
    Func = function() callMod(InfoLoggerUI, 'SetEnabled', true) end,
    Tooltip = 'Opens live animation ID table (Time/Animation/ID/Enemy/Dist/Status)',
})

-- ── PARRY TRIGGER (right, below) ──
local TrigGroup = Tabs.Parry:AddRightGroupbox('Parry Trigger')

TrigGroup:AddDropdown('ParryMethod', {
    Values = { 'keypress', 'remote' }, Default = 1, Text = 'Method',
    Callback = function(v) if AutoParry then AutoParry.ParryMethod = v end end,
})

TrigGroup:AddLabel('Parry key'):AddKeyPicker('ParryKey', {
    Default = 'Q', NoUI = false, Text = 'Parry key',
})

Options.ParryKey:OnChanged(function()
    local ok, kc = pcall(function() return Enum.KeyCode[Options.ParryKey.Value] end)
    if ok and AutoParry then AutoParry.ParryKey = kc end
end)

TrigGroup:AddButton({
    Text = 'Sniff Parry Remote',
    Func = function()
        callMod(AutoParry, 'SniffRemote')
        Options.ParryMethod:SetValue('remote')
    end,
    Tooltip = 'Press this, then press your parry key once in-game. It grabs the remote automatically.',
})

-- ════════════════════════════════════════════════════════════
-- UI SETTINGS
-- ════════════════════════════════════════════════════════════
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'End', NoUI = true, Text = 'Menu keybind',
})
Library.ToggleKeybind = Options.MenuKeybind

Library:OnUnload(function()
    if AutoParry then AutoParry.Enabled = false end
    callMod(InfoLoggerUI, 'SetEnabled', false)
    callMod(AnimationVisualizer, 'SetEnabled', false)
    Library.Unloaded = true
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind', 'ParryKey' })
ThemeManager:SetFolder('AutoParry')
SaveManager:SetFolder('AutoParry/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

refreshList()
CountLabel:SetText('Saved timings: ' .. (AutoParry and AutoParry:Count() or 0))
SaveManager:LoadAutoloadConfig()
