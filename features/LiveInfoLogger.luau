local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local UserInputService = game:GetService("UserInputService")
local LP = Players.LocalPlayer

local M = {}
M.Enabled = false
M.Rows = {}
M.Conns = {}
M.PlayerConn = nil

local gui = Instance.new("ScreenGui")
gui.Name = "InfoLoggerUI"
gui.ResetOnSpawn = false
pcall(function() gui.Parent = gethui() end)
if not gui.Parent then gui.Parent = game.CoreGui end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 470, 0, 260)
frame.Position = UDim2.new(0.55, 0, 0.12, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 20, 14)
frame.BorderColor3 = Color3.fromRGB(190, 150, 60)
frame.Visible = false
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 22)
title.BackgroundTransparency = 1
title.Text = "Info Logger   0 entries"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(230, 190, 90)
title.TextSize = 14
title.Font = Enum.Font.Code
title.Parent = frame

local clearBtn = Instance.new("TextButton")
clearBtn.Size = UDim2.new(0, 44, 0, 18)
clearBtn.Position = UDim2.new(1, -48, 0, 2)
clearBtn.Text = "Clear"
clearBtn.TextSize = 12
clearBtn.Font = Enum.Font.Code
clearBtn.BackgroundColor3 = Color3.fromRGB(40, 36, 26)
clearBtn.BorderColor3 = Color3.fromRGB(190, 150, 60)
clearBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
clearBtn.Parent = frame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, -8, 0, 16)
header.Position = UDim2.new(0, 4, 0, 24)
header.BackgroundTransparency = 1
header.Parent = frame

for _, c in ipairs({ {"Time",0,0.13}, {"Animation",0.13,0.36}, {"ID",0.49,0.22}, {"Enemy",0.71,0.15}, {"Dist",0.86,0.07}, {"Status",0.93,0.07} }) do
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(c[3], 0, 1, 0)
    l.Position = UDim2.new(c[2], 0, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = c[1]
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextColor3 = Color3.fromRGB(190, 150, 60)
    l.TextSize = 12
    l.Font = Enum.Font.Code
    l.Parent = header
end

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -46)
scroll.Position = UDim2.new(0, 4, 0, 42)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 3
scroll.Parent = frame

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 1)
layout.Parent = scroll

do
    local dragging, start = false, nil
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; start = i.Position - frame.AbsolutePosition
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = UDim2.fromOffset(i.Position.X - start.X, i.Position.Y - start.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

local function inList(id)
    local AP = getgenv().AutoParryModule
    if not AP then return false end
    for _, t in pairs(AP.Timings) do
        if t._id == id then return true end
    end
    return false
end

local function addRow(name, id, dist)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 15)
    row.BackgroundTransparency = 1
    row.Parent = scroll

    local function cell(frac, pos, text, color)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(frac, 0, 1, 0)
        l.Position = UDim2.new(pos, 0, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.TextColor3 = color or Color3.fromRGB(220, 220, 220)
        l.TextSize = 11
        l.Font = Enum.Font.Code
        l.Parent = row
        return l
    end

    cell(0.13, 0, os.date("%H:%M:%S"))
    local animLabel = cell(0.36, 0.13, "...")
    cell(0.22, 0.49, id, Color3.fromRGB(140, 160, 255))
    cell(0.15, 0.71, name)
    cell(0.07, 0.86, tostring(math.floor(dist)))
    local known = inList(id)
    cell(0.07, 0.93, known and "OK" or "NEW", known and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 90, 90))

    task.spawn(function()
        pcall(function()
            local info = MarketplaceService:GetProductInfo(tonumber(id))
            if info and info.Name and animLabel.Parent then animLabel.Text = info.Name end
        end)
    end)

    table.insert(M.Rows, 1, row)
    if #M.Rows > 30 then table.remove(M.Rows):Destroy() end
    scroll.CanvasSize = UDim2.new(0, 0, 0, #M.Rows * 16)
    title.Text = ("Info Logger   %d entries"):format(#M.Rows)
end

clearBtn.MouseButton1Click:Connect(function()
    for _, r in ipairs(M.Rows) do r:Destroy() end
    M.Rows = {}
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    title.Text = "Info Logger   0 entries"
end)

local function hookChar(player)
    if player == LP then return end
    local function onChar(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        M.Conns[player] = hum.AnimationPlayed:Connect(function(track)
            if not M.Enabled then return end
            local id = tostring(track.Animation and track.Animation.AnimationId or ""):match("(%d+)$") or ""
            if id == "" then return end
            local my = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            local their = char:FindFirstChild("HumanoidRootPart")
            local dist = (my and their) and (my.Position - their.Position).Magnitude or 0
            addRow(player.Name, id, dist)
        end)
    end
    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

function M:SetEnabled(v)
    M.Enabled = v
    frame.Visible = v
    if v then
        for _, p in ipairs(Players:GetPlayers()) do hookChar(p) end
        M.PlayerConn = Players.PlayerAdded:Connect(hookChar)
    else
        for _, c in pairs(M.Conns) do pcall(function() c:Disconnect() end) end
        M.Conns = {}
        if M.PlayerConn then M.PlayerConn:Disconnect(); M.PlayerConn = nil end
    end
end

getgenv().InfoLoggerUI = M
return M
