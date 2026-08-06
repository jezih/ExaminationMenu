local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_PLACE = 125927821145949
if game.PlaceId ~= TARGET_PLACE then
    print("wrong game")
    notify("Wrong Game", "This script only works in Mine a Mountain", 4)
    return
end

if not _G.__oreEspFilter then
    _G.__oreEspFilter = true
    local origPrint = print
    _G.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = tostring(select(i, ...))
        end
        local msg = table.concat(parts, " ")
        if msg:find("InputBegan") or msg:find("IB key") then return end
        origPrint(...)
    end
end

local state = _G.oreEsp
if state then
    state.stop()
    _G.oreEsp = nil
    print("ore ESP off")
    return
end

local lp = Players.LocalPlayer
local Things = game.Workspace:FindFirstChild("Things")
local Crystals = Things and Things:FindFirstChild("Crystals")
if not Crystals then print("no Crystals folder"); return end

local RANGE = 350
local POOL = 64
local TOGGLE = Enum.KeyCode.G.Value
local enabled = true
local running = true
local lastToggle = 0
local nodes = {}
local pool = {}
local conn
local keyConn
local hud

local tierColor = {}
for _, c in ipairs(Crystals:GetChildren()) do
    local t = c:GetAttribute("Tier")
    if t and not tierColor[t] then
        tierColor[t] = Color3.fromRGB(
            c:GetAttribute("TierColorR") or 255,
            c:GetAttribute("TierColorG") or 255,
            c:GetAttribute("TierColorB") or 255)
    end
    local seen = 0
    for _ in pairs(tierColor) do seen = seen + 1 end
    if seen >= 5 then break end
end

hud = Drawing.new("Text")
hud.Size = 14
hud.Position = Vector2.new(10, 8)
hud.Outline = true

local function setHud()
    if enabled then
        hud.Text = "ORE ESP: ON"
        hud.Color = Color3.fromRGB(120, 255, 120)
    else
        hud.Text = "ORE ESP: OFF"
        hud.Color = Color3.fromRGB(255, 120, 120)
    end
end
setHud()

local function toggle()
    local now = tick()
    if now - lastToggle < 0.2 then return end
    lastToggle = now
    enabled = not enabled
    setHud()
end

for i = 1, POOL do
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Visible = false
    local tag = Drawing.new("Text")
    tag.Size = 12
    tag.Center = true
    tag.Outline = true
    tag.Visible = false
    pool[i] = { box = box, tag = tag }
end

task.spawn(function()
    while running do
        local out = {}
        local char = lp.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local myPos = root and root.Position
        for _, c in ipairs(Crystals:GetChildren()) do
            local pos = c.Position
            if myPos then
                local d = (pos - myPos).Magnitude
                if d > RANGE + 60 then continue end
            end
            local tier = c:GetAttribute("Tier")
            out[#out + 1] = {
                pos = pos,
                h = (c.Size.Y or 3) + 2,
                name = tostring(c:GetAttribute("CrystalName")),
                value = tostring(c:GetAttribute("Value") or ""),
                color = tierColor[tier] or Color3.fromRGB(255, 255, 255),
            }
        end
        nodes = out
        task.wait(0.8)
    end
end)

task.spawn(function()
    local was = false
    while running do
        local down = false
        local ok, d = pcall(function() return UIS:IsKeyDown(TOGGLE) end)
        if ok then down = d end
        if down and not was then toggle() end
        was = down
        task.wait(0.1)
    end
end)

conn = RunService.RenderStepped:Connect(function()
    if not enabled then
        for i = 1, POOL do
            pool[i].box.Visible = false
            pool[i].tag.Visible = false
        end
        return
    end
    local list = nodes
    local n = 0
    for i = 1, #list do
        if n >= POOL then break end
        local e = list[i]
        local half = e.h * 0.5
        local top, v1 = WorldToScreen(e.pos + Vector3.new(0, half, 0))
        local bot, v2 = WorldToScreen(e.pos - Vector3.new(0, half, 0))
        if v1 and v2 then
            n = n + 1
            local d = pool[n]
            local h = bot.Y - top.Y
            local w = h * 0.8
            d.box.Position = Vector2.new(top.X - w * 0.5, top.Y)
            d.box.Size = Vector2.new(w, h)
            d.box.Color = e.color
            d.box.Visible = true
            d.tag.Text = e.name .. " " .. e.value
            d.tag.Position = Vector2.new(top.X, top.Y - 14)
            d.tag.Color = e.color
            d.tag.Visible = true
        end
    end
    for i = n + 1, POOL do
        pool[i].box.Visible = false
        pool[i].tag.Visible = false
    end
end)

keyConn = UIS.InputBegan:Connect(function(input)
    if input.KeyCode == TOGGLE then toggle() end
end)

local function stop()
    if not running then return end
    running = false
    if conn then conn:Disconnect() end
    if keyConn then keyConn:Disconnect() end
    if hud then hud:Remove() end
    for i = 1, POOL do
        pool[i].box:Remove()
        pool[i].tag:Remove()
    end
end

_G.oreEsp = { stop = stop }
notify("Ore ESP, G TO TOGGLE", 3)