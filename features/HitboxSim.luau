local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.Part = nil
M.Conn = nil

function M:ShowFor(timing)
    if M.Part then M.Part:Destroy() end
    local part = Instance.new("Part")
    part.Size = Vector3.new(timing.hitbox.X, timing.hitbox.Y, timing.hitbox.Z)
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 0.5
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Material = Enum.Material.Neon
    local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root then part.CFrame = root.CFrame * CFrame.new(0, 0, -(timing.hso or 0)) end
    part.Parent = workspace
    M.Part = part
    task.delay(3, function() if part then part:Destroy() end end)
end

function M:SetEnabled(v)
    M.Enabled = v
    if not v and M.Part then M.Part:Destroy(); M.Part = nil end
end

getgenv().HitboxSimModule = M
return M
