-- [Roblox | Luau | Animation Visualizer & Editor window — universal]
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
title.Text = "Animation Visual
