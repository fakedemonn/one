local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.Track = nil
M.Paused = false
M.CurrentId = ""

local function notify(t)
    pcall(function()
        StarterGui:SetCore("SendNotification", { Title = "Visualizer", Text = t, Duration = 3 })
    end)
end

local gui = Instance.new("ScreenGui")
gui.Name = "VisualizerUI"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then gui.Parent = game.CoreGui end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 440, 0, 340)
frame.Position = UDim2.new(0.1, 0, 0.15, 0)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
frame.BorderColor3 = Color3.fromRGB(235, 235, 235)
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 0, 20)
title.BackgroundTransparency = 1
title.Text = "Animation Visualizer & Editor"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 13
title.Font = Enum.Font.Code
title.Parent = frame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 18, 0, 18)
closeBtn.Position = UDim2.new(1, -22, 0, 1)
closeBtn.Text = "X"
closeBtn.TextSize = 12
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.BorderColor3 = Color3.fromRGB(90, 90, 90)
closeBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
closeBtn.Parent = frame

do
    local dragging, start = false, nil
    title.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; start = inp.Position - frame.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = UDim2.fromOffset(inp.Position.X - start.X, inp.Position.Y - start.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local idBox = Instance.new("TextBox")
idBox.Size = UDim2.new(1, -16, 0, 20)
idBox.Position = UDim2.new(0, 8, 0, 22)
idBox.PlaceholderText = "rbxassetid://"
idBox.Text = ""
idBox.TextSize = 12
idBox.Font = Enum.Font.Code
idBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
idBox.BorderColor3 = Color3.fromRGB(90, 90, 90)
idBox.TextColor3 = Color3.fromRGB(240, 240, 240)
idBox.Parent = frame

local viewport = Instance.new("ViewportFrame")
viewport.Size = UDim2.new(0.46, -12, 1, -140)
viewport.Position = UDim2.new(0, 8, 0, 48)
viewport.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
viewport.BorderColor3 = Color3.fromRGB(90, 90, 90)
viewport.Parent = frame

local worldModel = Instance.new("WorldModel")
worldModel.Parent = viewport

local cam = Instance.new("Camera")
cam.CameraType = Enum.CameraType.Scriptable
cam.FieldOfView = 70
cam.Parent = viewport
viewport.CurrentCamera = cam

local playBtn = Instance.new("TextButton")
playBtn.Size = UDim2.new(0.46, -12, 0, 22)
playBtn.Position = UDim2.new(0, 8, 1, -88)
playBtn.Text = "Play"
playBtn.TextSize = 12
playBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
playBtn.BorderColor3 = Color3.fromRGB(90, 90, 90)
playBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
playBtn.Parent = frame

local sliderText = Instance.new("TextLabel")
sliderText.Size = UDim2.new(0.46, -12, 0, 18)
sliderText.Position = UDim2.new(0, 8, 1, -64)
sliderText.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
sliderText.BorderColor3 = Color3.fromRGB(90, 90, 90)
sliderText.Text = "0.000 / 0.000 (0ms)"
sliderText.TextColor3 = Color3.fromRGB(20, 20, 20)
sliderText.TextSize = 11
sliderText.Font = Enum.Font.Code
sliderText.Parent = frame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0.46, -12, 0, 16)
statusLabel.Position = UDim2.new(0, 8, 1, -44)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Not in parry list"
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Code
statusLabel.Parent = frame

local qTitle = Instance.new("TextLabel")
qTitle.Size = UDim2.new(0.5, -16, 0, 18)
qTitle.Position = UDim2.new(0.5, 8, 0, 46)
qTitle.BackgroundTransparency = 1
qTitle.Text = "Quick Edit Timing"
qTitle.TextXAlignment = Enum.TextXAlignment.Left
qTitle.TextColor3 = Color3.fromRGB(240, 240, 240)
qTitle.TextSize = 12
qTitle.Font = Enum.Font.Code
qTitle.Parent = frame

local boxes = {}
local rows = {
    { "Delay (s):",  "Delay",  "0.15" },
    { "Hitbox X:",   "HBX",    "11" },
    { "Hitbox Y:",   "HBY",    "10" },
    { "Hitbox Z:",   "HBZ",    "30.5" },
    { "HSO:",        "HSO",    "0" },
    { "Max Dist:",   "IMOD",   "85" },
    { "Repeat:",     "REP",    "1" },
    { "Rep Delay:",  "RPD",    "0.35" },
    { "Dodge Dir:",  "DODGE",  "None" },
}

for i, r in ipairs(rows) do
    local y = 66 + (i - 1) * 22
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 86, 0, 18)
    l.Position = UDim2.new(0.5, 8, 0, y)
    l.BackgroundTransparency = 1
    l.Text = r[1]
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(240, 240, 240)
    l.TextSize = 11
    l.Font = Enum.Font.Code
    l.Parent = frame

    local b = Instance.new("TextBox")
    b.Size = UDim2.new(0.5, -106, 0, 18)
    b.Position = UDim2.new(0.5, 96, 0, y)
    b.Text = r[3]
    b.TextSize = 11
    b.Font = Enum.Font.Code
    b.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    b.BorderColor3 = Color3.fromRGB(90, 90, 90)
    b.TextColor3 = Color3.fromRGB(240, 240, 240)
    b.Parent = frame
    boxes[r[2]] = b
end

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.5, -16, 0, 24)
saveBtn.Position = UDim2.new(0.5, 8, 1, -40)
saveBtn.Text = "Save & Apply"
saveBtn.TextSize = 12
saveBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 240)
saveBtn.BorderColor3 = Color3.fromRGB(90, 90, 90)
saveBtn.TextColor3 = Color3.fromRGB(20, 20, 20)
saveBtn.Parent = frame

local function inParryList(id)
    local AP = getgenv().AutoParryModule
    if not AP then return false end
    for _, t in pairs(AP.Timings) do
        if t._id == id then return true end
    end
    return false
end

local function loadPreview(id)
    for _, d in ipairs(worldModel:GetChildren()) do d:Destroy() end
    if M.Track then pcall(function() M.Track:Stop() end); M.Track = nil end

    local char = LP.Character
    if not char then notify("No character to preview with.") return end
    local clone = char:Clone()
    for _, s in ipairs(clone:GetDescendants()) do
        if s:IsA("LocalScript") or s:IsA("Script") then s:Destroy() end
    end
    clone.Parent = worldModel
    local root = clone:FindFirstChild("HumanoidRootPart")
    if root then
        clone.PrimaryPart = root
        clone:PivotTo(CFrame.new(0, 0, 0))
    end

    local animator = clone:FindFirstChildOfClass("Animator")
    if not animator then
        local hum = clone:FindFirstChildOfClass("Humanoid")
        animator = hum and hum:FindFirstChildOfClass("Animator")
    end
    if not animator then statusLabel.Text = "No Animator found" return end

    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://" .. id
    local track = animator:LoadAnimation(anim)
    track:Play(0, 100, 0)
    track.Priority = Enum.AnimationPriority.Action
    track.Looped = true
    M.Track = track
    M.Paused = false
    playBtn.Text = "Pause"

    local primary = root or clone:FindFirstChildWhichIsA("BasePart")
    if primary then
        local _, bbs = clone:GetBoundingBox()
        cam.CFrame = CFrame.lookAt(primary.Position - Vector3.new(0, 0, bbs.Magnitude), primary.Position)
    end

    statusLabel.Text = inParryList(id) and "In parry list" or "Not in parry list"
end

idBox.FocusLost:Connect(function(enter)
    if not enter then return end
    M.CurrentId = idBox.Text:match("(%d+)") or ""
    if M.CurrentId ~= "" then loadPreview(M.CurrentId) end
end)

playBtn.MouseButton1Click:Connect(function()
    M.Paused = not M.Paused
    playBtn.Text = M.Paused and "Play" or "Pause"
end)

closeBtn.MouseButton1Click:Connect(function()
    M:SetEnabled(false)
end)

saveBtn.MouseButton1Click:Connect(function()
    local AP = getgenv().AutoParryModule
    if not AP then notify("AutoParry not loaded.") return end
    if M.CurrentId == "" then notify("Load an animation ID first.") return end

    local c = getgenv().BuilderConfig or {}
    c.AnimationID = M.CurrentId
    c.Delay      = tonumber(boxes.Delay.Text) or c.Delay
    c.Hitbox     = Vector3.new(tonumber(boxes.HBX.Text) or 11, tonumber(boxes.HBY.Text) or 10, tonumber(boxes.HBZ.Text) or 30.5)
    c.MSD        = tonumber(boxes.HSO.Text) or c.MSD
    c.IMOD       = tonumber(boxes.IMOD.Text) or c.IMOD
    c.RepeatCount = tonumber(boxes.REP.Text) or c.RepeatCount
    c.RepeatDelay = tonumber(boxes.RPD.Text) or c.RepeatDelay
    c.DodgeDirection = boxes.DODGE.Text ~= "" and boxes.DODGE.Text or c.DodgeDirection

    local t
    if AP.Selected and AP.Timings[AP.Selected] then
        t = AP:UpdateTiming()
    else
        if not c.AnimationName or c.AnimationName == "" then
            c.AnimationName = "ID_" .. M.CurrentId
        end
        t = AP:CreateTiming()
    end

    if t then
        notify("Saved & applied: " .. t.name)
        statusLabel.Text = "In parry list"
    else
        notify("Save failed.")
    end
end)

RunService.RenderStepped:Connect(function()
    if not M.Enabled or not M.Track then return end
    M.Track:AdjustSpeed(M.Paused and 0 or 1)
    sliderText.Text = ("%.3f / %.3f (%dms)"):format(
        M.Track.TimePosition, M.Track.Length, M.Track.TimePosition * 1000
    )
end)

function M:SetEnabled(v)
    M.Enabled = v
    frame.Visible = v
end

getgenv().AnimationVisualizerModule = M
getgenv().VisualizerUI = M
return M
