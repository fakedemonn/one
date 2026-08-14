local repo     = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local featRepo = 'https://raw.githubusercontent.com/fakedemonn/one/main/features/'

local Library      = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager  = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local function loadFeature(file)
    local ok, mod = pcall(function()
        return loadstring(game:HttpGet(featRepo .. file))()
    end)
    if not ok or type(mod) ~= 'table' then
        warn('[Builder] failed to load: ' .. file)
        return nil
    end
    return mod
end

local AnimationBuilder    = loadFeature('AnimationBuilder.luau')
local AutoParry           = loadFeature('AutoParry.luau')
local EffectBuilder       = loadFeature('EffectBuilder.luau')
local HitboxSim           = loadFeature('HitboxSim.luau')
local LiveInfoLogger      = loadFeature('LiveInfoLogger.luau')
local AnimationVisualizer = loadFeature('AnimationVisualizer.luau')

local function callMod(mod, method, ...)
    if mod and type(mod[method]) == 'function' then
        return mod[method](mod, ...)
    end
end

local BuilderConfig = {
    Enabled = false, LogCaptured = false,
    AnimationID = '', AnimationName = '',
    Distance = 85, Delay = 0.15, DodgeDirection = 'None',
    Hitbox = Vector3.new(11, 10, 30.5),
    MSD = 3, IMOD = 85, RepeatCount = 1, RepeatDelay = 0.35,
    EffectsEnabled = false, EffectType = 'None', EffectAsset = '',
    ShowHitboxSim = false, LiveInfoLogger = false,
}
getgenv().BuilderConfig = BuilderConfig

local Window = Library:CreateWindow({
    Title = 'Builder', Center = true, AutoShow = true,
    TabPadding = 8, MenuFadeTime = 0.2,
})

local Tabs = {
    Builder         = Window:AddTab('Builder'),
    ['UI Settings'] = Window:AddTab('UI Settings'),
}

-- ══ ANIMATION BUILDER (left) ══
local AnimGroup = Tabs.Builder:AddLeftGroupbox('Animation Builder')

AnimGroup:AddToggle('EnableBuilder', {
    Text = 'Enable Auto-Parry', Default = false,
    Callback = function(v)
        BuilderConfig.Enabled = v
        callMod(AnimationBuilder, 'SetEnabled', v)
        callMod(AutoParry, 'SetEnabled', v)
    end,
})

AnimGroup:AddToggle('LogCaptured', {
    Text = 'Log Already Captured Animations', Default = false,
    Callback = function(v)
        BuilderConfig.LogCaptured = v
        callMod(AnimationBuilder, 'SetLogCaptured', v)
    end,
})

AnimGroup:AddInput('AnimationID', {
    Text = 'Animation ID', Default = '', Placeholder = 'e.g. 145128166',
    Callback = function(v)
        BuilderConfig.AnimationID = v
        callMod(AnimationBuilder, 'SetAnimationID', v)
    end,
})

AnimGroup:AddInput('AnimationName', {
    Text = 'Animation Name', Default = '', Placeholder = 'e.g. Katana Light 1',
    Callback = function(v)
        BuilderConfig.AnimationName = v
        callMod(AnimationBuilder, 'SetAnimationName', v)
    end,
})

AnimGroup:AddSlider('Distance', {
    Text = 'Distance', Default = 85, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v)
        BuilderConfig.Distance = v
        callMod(AnimationBuilder, 'SetDistance', v)
    end,
})

AnimGroup:AddSlider('Delay', {
    Text = 'Delay (seconds)', Default = 0.15, Min = 0, Max = 5, Rounding = 2, Suffix = 's',
    Callback = function(v)
        BuilderConfig.Delay = v
        callMod(AnimationBuilder, 'SetDelay', v)
    end,
})

AnimGroup:AddDropdown('DodgeDirection', {
    Values = { 'None', 'Forward', 'Backward', 'Left', 'Right' }, Default = 1,
    Text = 'Dodge Direction',
    Callback = function(v)
        BuilderConfig.DodgeDirection = v
        callMod(AnimationBuilder, 'SetDodgeDirection', v)
    end,
})

AnimGroup:AddSlider('HitboxX', {
    Text = 'Hitbox X', Default = 11, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(v, BuilderConfig.Hitbox.Y, BuilderConfig.Hitbox.Z)
        callMod(AnimationBuilder, 'SetHitbox', BuilderConfig.Hitbox)
    end,
})

AnimGroup:AddSlider('HitboxY', {
    Text = 'Hitbox Y', Default = 10, Min = 0, Max = 100, Rounding = 0,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(BuilderConfig.Hitbox.X, v, BuilderConfig.Hitbox.Z)
        callMod(AnimationBuilder, 'SetHitbox', BuilderConfig.Hitbox)
    end,
})

AnimGroup:AddSlider('HitboxZ', {
    Text = 'Hitbox Z', Default = 30.5, Min = 0, Max = 500, Rounding = 1,
    Callback = function(v)
        BuilderConfig.Hitbox = Vector3.new(BuilderConfig.Hitbox.X, BuilderConfig.Hitbox.Y, v)
        callMod(AnimationBuilder, 'SetHitbox', BuilderConfig.Hitbox)
    end,
})

AnimGroup:AddSlider('MSD', {
    Text = 'MSD (Forward Offset)', Default = 3, Min = 0, Max = 50, Rounding = 0,
    Callback = function(v)
        BuilderConfig.MSD = v
        callMod(AnimationBuilder, 'SetMSD', v)
    end,
})

AnimGroup:AddSlider('IMOD', {
    Text = 'IMOD (Max Distance)', Default = 85, Min = 0, Max = 500, Rounding = 0,
    Callback = function(v)
        BuilderConfig.IMOD = v
        callMod(AnimationBuilder, 'SetIMOD', v)
    end,
})

AnimGroup:AddSlider('RepeatCount', {
    Text = 'Repeat', Default = 1, Min = 1, Max = 20, Rounding = 0,
    Callback = function(v)
        BuilderConfig.RepeatCount = v
        callMod(AnimationBuilder, 'SetRepeat', v)
    end,
})

AnimGroup:AddSlider('RepeatDelay', {
    Text = 'Repeat Delay (s)', Default = 0.35, Min = 0, Max = 5, Rounding = 2, Suffix = 's',
    Callback = function(v)
        BuilderConfig.RepeatDelay = v
        callMod(AnimationBuilder, 'SetRepeatDelay', v)
    end,
})

-- ══ EFFECT BUILDER (left, below) ══
local EffectGroup = Tabs.Builder:AddLeftGroupbox('Effect Builder')

EffectGroup:AddToggle('EnableEffects', {
    Text = 'Enable Effects', Default = false,
    Callback = function(v)
        BuilderConfig.EffectsEnabled = v
        callMod(EffectBuilder, 'SetEnabled', v)
    end,
})

EffectGroup:AddDropdown('EffectType', {
    Values = { 'None', 'Particle', 'Sound', 'Trail', 'Beam' }, Default = 1,
    Text = 'Effect Type',
    Callback = function(v)
        BuilderConfig.EffectType = v
        callMod(EffectBuilder, 'SetEffectType', v)
    end,
})

EffectGroup:AddInput('EffectAsset', {
    Text = 'Effect Asset ID', Default = '', Placeholder = 'Asset ID...',
    Callback = function(v)
        BuilderConfig.EffectAsset = v
        callMod(EffectBuilder, 'SetEffectAsset', v)
    end,
})

-- ══ PREVIEW / ACTIONS (right) ══
local PreviewGroup = Tabs.Builder:AddRightGroupbox('Preview / Actions')

PreviewGroup:AddButton({
    Text = 'Animation Visualizer',
    Func = function()
        local AB = getgenv().AnimationBuilderModule
        local t = AB and AB:GetSelected()
        if not t then Library:Notify('Create or select a timing first.', 3) return end
        callMod(AnimationVisualizer, 'ShowFor', t)
        Library:Notify('Visualizing hitbox: ' .. t.name, 3)
    end,
})

PreviewGroup:AddToggle('LiveInfoLogger', {
    Text = 'Live Info Logger', Default = false,
    Callback = function(v)
        BuilderConfig.LiveInfoLogger = v
        callMod(LiveInfoLogger, 'SetEnabled', v)
        callMod(AnimationBuilder, 'SetLiveLogger', v)
        Library:Notify(v and 'Live logger ON — IDs show as notifications' or 'Live logger OFF', 2)
    end,
})

PreviewGroup:AddButton({
    Text = 'Open Animation Logger',
    Func = function()
        callMod(AnimationBuilder, 'OpenLogger')
        callMod(LiveInfoLogger, 'SetEnabled', true)
        Toggles.LiveInfoLogger:SetValue(true)
        Library:Notify('Animation logger active — watching all players.', 3)
    end,
})

PreviewGroup:AddButton({
    Text = 'Preview Entry',
    Func = function()
        local AB = getgenv().AnimationBuilderModule
        local t = AB and AB:GetSelected()
        if not t then Library:Notify('No timing selected.', 3) return end
        Library:Notify(("ID=%s | HB=%d,%d,%d | Actions=%d"):format(
            t._id, t.hitbox.X, t.hitbox.Y, t.hitbox.Z, #t.actions
        ), 5)
    end,
})

PreviewGroup:AddButton({
    Text = 'Create New Timing',
    Func = function()
        local t = callMod(AnimationBuilder, 'CreateTiming')
        if t then
            Library:Notify('Created: ' .. t.name .. ' (auto-parry enabled)', 4)
        else
            Library:Notify('Enter an Animation Name first (or it already exists).', 3)
        end
    end,
})

PreviewGroup:AddButton({
    Text = 'Update Selected Timing', DoubleClick = true,
    Func = function()
        local t = callMod(AnimationBuilder, 'UpdateTiming')
        if t then Library:Notify('Updated: ' .. t.name, 3)
        else Library:Notify('Select a timing first.', 3) end
    end,
})

PreviewGroup:AddButton({
    Text = 'Remove Selected Timing', DoubleClick = true,
    Func = function()
        local name = callMod(AnimationBuilder, 'RemoveTiming')
        if name then Library:Notify('Removed: ' .. name, 3)
        else Library:Notify('Select a timing first.', 3) end
    end,
})

local TimingCountLabel = PreviewGroup:AddLabel('Saved timings: 0')

PreviewGroup:AddButton({
    Text = 'Refresh List',
    Func = function()
        callMod(AnimationBuilder, 'LoadAll')
        local AB = getgenv().AnimationBuilderModule
        TimingCountLabel:SetText('Saved timings: ' .. tostring(AB and AB:Count() or 0))
        Library:Notify('Timing list refreshed.', 2)
    end,
})

-- ══ CONFIG MANAGER (right, below) ══
local ConfigGroup = Tabs.Builder:AddRightGroupbox('Config Manager')

ConfigGroup:AddLabel('Config Name')
ConfigGroup:AddInput('ConfigName', { Text = 'Config Name', Default = 'MySetup', Placeholder = 'Name...' })
ConfigGroup:AddLabel('Saved Configs')
ConfigGroup:AddDropdown('ConfigList', { Values = {}, AllowNull = true, Text = 'Saved Configs' })

local function refreshConfigList()
    local list = (SaveManager.ListConfigs and SaveManager:ListConfigs()) or {}
    Options.ConfigList:SetValues(list)
end

ConfigGroup:AddButton({ Text = 'Save Config', Func = function()
    local name = Options.ConfigName.Value
    if not name or name == '' then Library:Notify('Enter a config name first.', 3) return end
    SaveManager:Save(name); refreshConfigList(); Library:Notify('Saved: ' .. name, 3)
end })

ConfigGroup:AddButton({ Text = 'Load Config', DoubleClick = true, Func = function()
    local sel = Options.ConfigList.Value
    if not sel or sel == '' then Library:Notify('Select a config first.', 3) return end
    SaveManager:Load(sel); Library:Notify('Loaded: ' .. tostring(sel), 3)
end })

ConfigGroup:AddButton({ Text = 'Delete Config', DoubleClick = true, Func = function()
    local sel = Options.ConfigList.Value
    if not sel or sel == '' then return end
    SaveManager:Delete(sel); refreshConfigList(); Library:Notify('Deleted: ' .. tostring(sel), 3)
end })

ConfigGroup:AddButton({ Text = 'Refresh List', Func = refreshConfigList })
ConfigGroup:AddLabel('Configs save all builder overrides.', true)

-- ══ HITBOX SIMULATION (right, below) ══
local SimGroup = Tabs.Builder:AddRightGroupbox('Hitbox Simulation')

SimGroup:AddToggle('ShowHitboxSim', {
    Text = 'Show Hitbox Simulation', Default = false,
    Callback = function(v)
        BuilderConfig.ShowHitboxSim = v
        callMod(HitboxSim, 'SetEnabled', v)
        callMod(AnimationVisualizer, 'SetEnabled', v)
    end,
})

-- ═
