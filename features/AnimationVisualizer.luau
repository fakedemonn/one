-- [Roblox | Luau | Animation Visualizer — renders hitbox parts + previews animations]
-- Shows a neon box at your character for the selected timing's hitbox
-- Can also load an animation into a ViewportFrame for frame-by-frame preview

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.HitboxPart = nil
M.PreviewPart = nil
M.Conn = nil

-- ── SHOW HITBOX FOR A TIMING ──
function M:ShowFor(timing)
    if M.HitboxPart then M.HitboxPart:Destroy(); M.HitboxPart = nil end

    local part = Instance.new("Part")
    part.Name = "BuilderHitboxPreview"
    part.Size = Vector3.new(timing.hitbox.X, timing.hitbox.Y, timing.hitbox.Z)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.4
    part.Color = Color3.fromRGB(255, 50, 50)
    part.Material = Enum.Material.Neon

    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then
        part.CFrame = root.CFrame * CFrame.new(0, 0, -(timing.hso or 0))
    end

    -- Wireframe edges
    local box = Instance.new("BoxHandleAdornment")
    box.Adornee = part
    box.Size = part.Size
    box.Color3 = Color3.fromRGB(255, 255, 0)
    box.Transparency = 0
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Parent = part

    part.Parent = workspace
    M.HitboxPart = part

    -- Auto-remove after 5 seconds
    task.delay(5, function()
        if part and part.Parent then part:Destroy() end
        if M.HitboxPart == part then M.HitboxPart = nil end
    end)

    return part
end

-- ── CONTINUOUS HITBOX FOLLOW (stays on your character while moving) ──
function M:StartFollow(timing)
    M:StopFollow()
    M:ShowFor(timing)

    M.Conn = RunService.RenderStepped:Connect(function()
        if not M.HitboxPart or not M.HitboxPart.Parent then
            M:StopFollow()
            return
        end
        local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if root then
            M.HitboxPart.CFrame = root.CFrame * CFrame.new(0, 0, -(timing.hso or 0))
        end
    end)
end

function M:StopFollow()
    if M.Conn then M.Conn:Disconnect(); M.Conn = nil end
    if M.HitboxPart then M.HitboxPart:Destroy(); M.HitboxPart = nil end
end

-- ── PREVIEW ANIMATION (loads into workspace for visual playback) ──
function M:PreviewAnimation(animationId)
    if M.PreviewPart then M.PreviewPart:Destroy(); M.PreviewPart = nil end

    local char = LP.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return nil end

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(animationId)

    local track = animator:LoadAnimation(animation)
    track:Play(0.1, 1, 1)
    track.Looped = true

    M.PreviewPart = track -- store track so we can stop it later
    return track
end

function M:StopPreview()
    if M.PreviewPart and typeof(M.PreviewPart) == "Instance" then
        pcall(function() M.PreviewPart:Stop() end)
    end
    M.PreviewPart = nil
end

-- ── ENABLE/DISABLE ──
function M:SetEnabled(v)
    M.Enabled = v
    if not v then
        M:StopFollow()
        M:StopPreview()
    end
end

getgenv().HitboxSimModule = M
getgenv().AnimationVisualizerModule = M
return M
