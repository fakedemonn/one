local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Live config your builder feature scripts read from
local BuilderConfig = {
    Enabled        = false,
    LogCaptured    = false,
    AnimationID    = '',
    AnimationName  = '',
    Distance       = 85,
    Delay          = 0.15,
    DodgeDirection = 'None',
    Hitbox         = Vector3.new(11, 10, 30.5),
    MSD            = 3,
    IMOD           = 85,
    RepeatCount    = 1,
    RepeatDelay    = 0.35,
    EffectsEnabled = false,
    EffectType     = 'None',
    EffectAsset    = '',
    ShowHitboxSim  = false,
    LiveInfoLogger = false,
}
getgenv().BuilderConfig = BuilderConfig

local Window = Library:CreateWindow({
    Title        = 'Builder',
    Center       = true,
    AutoShow     = true,
    TabPadding   = 8,
    MenuFadeTime = 0.2,
})

local Tabs = {
    Builder       = Window:AddTab('Builder'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ════════════════════════════════════════════════════════════
-- ANIMATION BUILDER (left)
-- ════════════════════════════════════════════════════════════
local AnimGroup = Tabs.Builder:AddLeftGroupbox('Animation Builder')

AnimGroup:AddToggle('EnableBuilder', {
    Text = 'Enable Auto-Animation-Logger', Default = false,
    Callback = function(v) BuilderConfig.Enabled = v end,
})

AnimGroup:AddToggle('LogCaptured', {
    Text = 'Log Already Captured Animations', Default = false,
    Callback = function(v) BuilderConfig.LogCaptured = v end,
})

AnimGroup:AddInput('AnimationID', {
    Text = 'Animation ID', Default = '', Placeholder = 'e.g. 145128166',
    Callback = function(v) BuilderConfig.AnimationID = v end,
})

AnimGroup:AddInput('AnimationName', {
    Text = 'Animation Name', Default = '', Placeholder = 'e.g. Katana Light 1',
    Callback = function(v) BuilderConfig.AnimationName = v end,
})

AnimGroup:AddSlider('Distance', {
    Text = 'Distance', Default = 85, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) BuilderConfig.Distance = v end,
})

AnimGroup:AddSlider('Delay', {
    Text = 'Delay (seconds)', Default = 0.15, Min = 0, Max = 5, Rounding = 2, Suffix = 's',
    Callback = function(v) BuilderConfig.Delay = v end,
})

AnimGroup:AddDropdown('DodgeDirection', {
    Values = { 'None', 'Forward', 'Backward', 'Left', 'Right' }, Default = 1,
    Text = 'Dodge Direction',
    Callback = function(v) BuilderConfig.DodgeDirection = v end,
})

AnimGroup:AddSlider('HitboxX', {
    Text = 'Hitbox X', Default = 11, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(v, BuilderConfig.Hitbox.Y, BuilderConfig.Hitbox.Z)
    end,
})

AnimGroup:AddSlider('HitboxY', {
    Text = 'Hitbox Y', Default = 10, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(BuilderConfig.Hitbox.X, v, BuilderConfig.Hitbox.Z)
    end,
})

AnimGroup:AddSlider('HitboxZ', {
    Text = 'Hitbox Z', Default = 30.5, Min = 0, Max = 500, Rounding = 1,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(BuilderConfig.Hitbox.X, BuilderConfig.Hitbox.Y, v)
    end,
})

AnimGroup:AddSlider('MSD', {
    Text = 'MSD (Forward Offset)', Default = 3, Min = 0, Max = 50, Rounding = 0,
    Callback = function(v) BuilderConfig.MSD = v end,
})

AnimGroup:AddSlider('IMOD', {
    Text = 'IMOD (Max Distance)', Default = 85, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v) BuilderConfig.IMOD = v end,
})

AnimGroup:AddSlider('RepeatCount', {
    Text = 'Repeat', Default = 1, Min = 1, Max = 20, Rounding = 0,
    Callback = function(v) BuilderConfig.RepeatCount = v end,
})

AnimGroup:AddSlider('RepeatDelay', {
    Text = 'Repeat Delay (s)', Default = 0.35, Min = 0, Max = 5, Rounding = 2, Suffix = 's',
    Callback = function(v) BuilderConfig.RepeatDelay = v end,
})

-- ════════════════════════════════════════════════════════════
-- EFFECT BUILDER (left, below)
-- ════════════════════════════════════════════════════════════
local EffectGroup = Tabs.Builder:AddLeftGroupbox('Effect Builder')

EffectGroup:AddToggle('EnableEffects', {
    Text = 'Enable Effects', Default = false,
    Callback = function(v) BuilderConfig.EffectsEnabled = v end,
})

EffectGroup:AddDropdown('EffectType', {
    Values = { 'None', 'Particle', 'Sound', 'Trail', 'Beam' }, Default = 1,
    Text = 'Effect Type',
    Callback = function(v) BuilderConfig.EffectType = v end,
})

EffectGroup:AddInput('EffectAsset', {
    Text = 'Effect Asset ID', Default = '', Placeholder = 'Asset ID...',
    Callback = function(v) BuilderConfig.EffectAsset = v end,
})

-- ════════════════════════════════════════════════════════════
-- PREVIEW / ACTIONS (right)
-- ════════════════════════════════════════════════════════════
local PreviewGroup = Tabs.Builder:AddRightGroupbox('Preview / Actions')

PreviewGroup:AddButton({ Text = 'Animation Visualizer', Func = function() end })

PreviewGroup:AddToggle('LiveInfoLogger', {
    Text = 'Live Info Logger', Default = false,
    Callback = function(v) BuilderConfig.LiveInfoLogger = v end,
})

PreviewGroup:AddButton({ Text = 'Open Animation Logger',  Func = function() end })
PreviewGroup:AddButton({ Text = 'Preview Entry',          Func = function() end })
PreviewGroup:AddButton({ Text = 'Create New Timing',      Func = function() end })
PreviewGroup:AddButton({ Text = 'Update Selected Timing', Func = function() end, DoubleClick = true })
PreviewGroup:AddButton({ Text = 'Remove Selected Timing', Func = function() end, DoubleClick = true })
PreviewGroup:AddLabel('Current parity list: 0 entries')

-- ════════════════════════════════════════════════════════════
-- CONFIG MANAGER (right, below)
-- ════════════════════════════════════════════════════════════
local ConfigGroup = Tabs.Builder:AddRightGroupbox('Config Manager')

ConfigGroup:AddLabel('Config Name')
ConfigGroup:AddInput('ConfigName', {
    Text = 'Config Name', Default = 'MySetup', Placeholder = 'Name...',
})

ConfigGroup:AddLabel('Saved Configs')
ConfigGroup:AddDropdown('ConfigList', {
    Values = {}, AllowNull = true, Text = 'Saved Configs',
})

local function refreshConfigList()
    local list = (SaveManager.ListConfigs and SaveManager:ListConfigs()) or {}
    Options.ConfigList:SetValues(list)
end

ConfigGroup:AddButton({
    Text = 'Save Config',
    Func = function()
        local name = Options.ConfigName.Value
        if not name or name == '' then Library:Notify('Enter a config name first.', 3); return end
        SaveManager:Save(name)
        refreshConfigList()
        Library:Notify('Saved: ' .. name, 3)
    end,
})

ConfigGroup:AddButton({
    Text = 'Load Config', DoubleClick = true,
    Func = function()
        local sel = Options.ConfigList.Value
        if not sel or sel == '' then Library:Notify('Select a config first.', 3); return end
        SaveManager:Load(sel)
        Library:Notify('Loaded: ' .. tostring(sel), 3)
    end,
})

ConfigGroup:AddButton({
    Text = 'Delete Config', DoubleClick = true,
    Func = function()
        local sel = Options.ConfigList.Value
        if not sel or sel == '' then return end
        SaveManager:Delete(sel)
        refreshConfigList()
        Library:Notify('Deleted: ' .. tostring(sel), 3)
    end,
})

ConfigGroup:AddButton({ Text = 'Refresh List', Func = refreshConfigList })
ConfigGroup:AddLabel('Configs save all builder overrides, blacklist, and logger filters.', true)

-- ════════════════════════════════════════════════════════════
-- HITBOX SIMULATION (right, below)
-- ════════════════════════════════════════════════════════════
local SimGroup = Tabs.Builder:AddRightGroupbox('Hitbox Simulation')

SimGroup:AddToggle('ShowHitboxSim', {
    Text = 'Show Hitbox Simulation', Default = false,
    Callback = function(v) BuilderConfig.ShowHitboxSim = v end,
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

Library:SetWatermarkVisibility(true)

local FrameTimer   = tick()
local FrameCounter = 0
local FPS          = 60

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS          = FrameCounter
        FrameTimer   = tick()
        FrameCounter = 0
    end
    Library:SetWatermark(('Builder | %s fps | %s ms'):format(
        math.floor(FPS),
        math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
    ))
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    BuilderConfig.Enabled = false
    Library.Unloaded = true
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('Builder')
SaveManager:SetFolder('Builder/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])

refreshConfigList()
SaveManager:LoadAutoloadConfig()
