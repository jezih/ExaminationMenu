local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TARGET_PLACE = 125927821145949
if game.PlaceId ~= TARGET_PLACE then
    print("wrong game")
    notify("Wrong Game", "This script only works in Mine a Mountain", 4)
    return
end

if not _G.__oreEspFilter and not _G.__espPrintFilter then
    _G.__oreEspFilter = true
    _G.__espPrintFilter = true
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

local lp = Players.LocalPlayer

if _G.oreEsp then _G.oreEsp.stop(); _G.oreEsp = nil end
if _G.boulderEsp then _G.boulderEsp.stop(); _G.boulderEsp = nil end
if _G.espUI then _G.espUI.stop(); _G.espUI = nil end

-- ============================================================
-- MY UI LIB (Drawing-based): window + toggle + dropdown
-- ============================================================
local DrawUI = {}
DrawUI.controls = {}
DrawUI.allObjs = {}
DrawUI.w = 230
DrawUI.x = 0
DrawUI.y = 0
DrawUI.titleText = "MENU"
DrawUI.visible = true
DrawUI.dirty = true
DrawUI.rows = {}
DrawUI.drag = nil
DrawUI.running = true
local ROW_H = 22
local TITLE_H = 26
local PAD = 6

local function newSquare(color, transparency, filled)
    local d = Drawing.new("Square")
    d.Color = color or Color3.fromRGB(24, 24, 24)
    d.Transparency = transparency or 0
    d.Filled = filled ~= false
    d.Thickness = 1
    d.Visible = false
    DrawUI.allObjs[#DrawUI.allObjs + 1] = d
    return d
end

local function newText(txt, size, color, center)
    local d = Drawing.new("Text")
    d.Text = txt or ""
    d.Size = size or 13
    d.Color = color or Color3.fromRGB(235, 235, 235)
    d.Center = center or false
    d.Outline = true
    d.Visible = false
    DrawUI.allObjs[#DrawUI.allObjs + 1] = d
    return d
end

function DrawUI.toggle(id, label, default)
    local ctl = {
        type = "toggle",
        id = id,
        label = label,
        value = default and true or false,
        rowBg = newSquare(Color3.fromRGB(32, 32, 32), 0, true),
        labelTxt = newText(label, 13, Color3.fromRGB(230, 230, 230), false),
        box = newSquare(Color3.fromRGB(110, 110, 110), 0, true),
        stateTxt = newText("ON", 13, Color3.fromRGB(120, 255, 120), false),
    }
    DrawUI.controls[#DrawUI.controls + 1] = ctl
    DrawUI.dirty = true
    return ctl
end

function DrawUI.dropdown(id, label, options, defaultIdx)
    local idx = 1
    if defaultIdx and defaultIdx >= 1 and defaultIdx <= #options then idx = defaultIdx end
    local ctl = {
        type = "dropdown",
        id = id,
        label = label,
        options = options,
        value = idx,
        open = false,
        rowBg = newSquare(Color3.fromRGB(32, 32, 32), 0, true),
        labelTxt = newText(label, 13, Color3.fromRGB(230, 230, 230), false),
        selTxt = newText(options[idx], 13, Color3.fromRGB(255, 255, 255), false),
        arrow = newText("v", 12, Color3.fromRGB(200, 200, 200), true),
        optBgs = {},
        optTexts = {},
    }
    for i = 1, #options do
        ctl.optBgs[i] = newSquare(Color3.fromRGB(26, 26, 26), 0, true)
        ctl.optTexts[i] = newText(options[i], 13, Color3.fromRGB(215, 215, 215), false)
    end
    DrawUI.controls[#DrawUI.controls + 1] = ctl
    DrawUI.dirty = true
    return ctl
end

function DrawUI.val(id, default)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id then return ctl.value end
    end
    return default
end

function DrawUI.option(id, defaultText)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id and ctl.type == "dropdown" then
            return ctl.options[ctl.value] or defaultText
        end
    end
    return defaultText
end

function DrawUI.set(id, v)
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.id == id then
            if ctl.type == "toggle" then
                ctl.value = v and true or false
            elseif ctl.type == "dropdown" then
                if type(v) == "number" and v >= 1 and v <= #ctl.options then ctl.value = v end
            end
            DrawUI.draw()
            return
        end
    end
end

function DrawUI.draw()
    for _, o in ipairs(DrawUI.allObjs) do o.Visible = false end
    if not DrawUI.running or not DrawUI.bg then return end
    if not DrawUI.visible then
        DrawUI.reopenBg.Position = Vector2.new(DrawUI.x, DrawUI.y)
        DrawUI.reopenBg.Size = Vector2.new(60, 18)
        DrawUI.reopenBg.Visible = true
        DrawUI.reopenBorder.Position = Vector2.new(DrawUI.x, DrawUI.y)
        DrawUI.reopenBorder.Size = Vector2.new(60, 18)
        DrawUI.reopenBorder.Visible = true
        DrawUI.reopenTxt.Position = Vector2.new(DrawUI.x + 30, DrawUI.y + 9)
        DrawUI.reopenTxt.Visible = true
        DrawUI.rows = { { kind = "reopen", x = DrawUI.x, y = DrawUI.y, w = 60, h = 18 } }
        DrawUI.dirty = false
        return
    end
    local x, y, w = DrawUI.x, DrawUI.y, DrawUI.w
    local rows = {}
    DrawUI.bg.Position = Vector2.new(x, y)
    DrawUI.bg.Size = Vector2.new(w, TITLE_H)
    DrawUI.bg.Visible = true
    DrawUI.title.Position = Vector2.new(x + w * 0.5, y + TITLE_H * 0.5)
    DrawUI.title.Text = DrawUI.titleText
    DrawUI.title.Visible = true
    DrawUI.closeX.Position = Vector2.new(x + w - 14, y + TITLE_H * 0.5)
    DrawUI.closeX.Visible = true
    rows[#rows + 1] = { kind = "close", x = x + w - 26, y = y, w = 26, h = TITLE_H }
    rows[#rows + 1] = { kind = "title", x = x, y = y, w = w - 26, h = TITLE_H }
    y = y + TITLE_H
    for _, ctl in ipairs(DrawUI.controls) do
        if ctl.type == "toggle" then
            ctl.rowBg.Position = Vector2.new(x, y)
            ctl.rowBg.Size = Vector2.new(w, ROW_H)
            ctl.rowBg.Visible = true
            ctl.labelTxt.Position = Vector2.new(x + PAD + 4, y + ROW_H * 0.5 - 7)
            ctl.labelTxt.Text = ctl.label
            ctl.labelTxt.Visible = true
            ctl.box.Position = Vector2.new(x + w - 30, y + ROW_H * 0.5 - 7)
            ctl.box.Size = Vector2.new(14, 14)
            ctl.box.Color = ctl.value and Color3.fromRGB(90, 220, 120) or Color3.fromRGB(110, 110, 110)
            ctl.box.Filled = ctl.value
            ctl.box.Visible = true
            ctl.stateTxt.Text = ctl.value and "ON" or "OFF"
            ctl.stateTxt.Color = ctl.value and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(255, 110, 110)
            ctl.stateTxt.Position = Vector2.new(x + w - 58, y + ROW_H * 0.5 - 7)
            ctl.stateTxt.Visible = true
            rows[#rows + 1] = { kind = "toggle", ctl = ctl, x = x, y = y, w = w, h = ROW_H }
            y = y + ROW_H
        else
            ctl.rowBg.Position = Vector2.new(x, y)
            ctl.rowBg.Size = Vector2.new(w, ROW_H)
            ctl.rowBg.Visible = true
            ctl.labelTxt.Position = Vector2.new(x + PAD + 4, y + ROW_H * 0.5 - 7)
            ctl.labelTxt.Text = ctl.label
            ctl.labelTxt.Visible = true
            ctl.selTxt.Text = ctl.options[ctl.value] or ""
            ctl.selTxt.Position = Vector2.new(x + w - 58, y + ROW_H * 0.5 - 7)
            ctl.selTxt.Visible = true
            ctl.arrow.Text = ctl.open and "^" or "v"
            ctl.arrow.Position = Vector2.new(x + w - 16, y + ROW_H * 0.5 - 7)
            ctl.arrow.Visible = true
            rows[#rows + 1] = { kind = "dropdown", ctl = ctl, x = x, y = y, w = w, h = ROW_H }
            y = y + ROW_H
            if ctl.open then
                for i = 1, #ctl.options do
                    local oy = y + (i - 1) * ROW_H
                    local bg = ctl.optBgs[i]
                    bg.Position = Vector2.new(x + 8, oy)
                    bg.Size = Vector2.new(w - 8, ROW_H)
                    bg.Color = (i == ctl.value) and Color3.fromRGB(46, 80, 56) or Color3.fromRGB(26, 26, 26)
                    bg.Visible = true
                    local ot = ctl.optTexts[i]
                    ot.Position = Vector2.new(x + 18, oy + ROW_H * 0.5 - 7)
                    ot.Visible = true
                    rows[#rows + 1] = { kind = "opt", ctl = ctl, idx = i, x = x + 8, y = oy, w = w - 8, h = ROW_H }
                end
                y = y + #ctl.options * ROW_H
            end
        end
    end
    DrawUI.bg.Size = Vector2.new(w, y - DrawUI.y)
    DrawUI.rows = rows
    DrawUI.dirty = false
end

function DrawUI.init(title)
    DrawUI.titleText = title
    DrawUI.bg = newSquare(Color3.fromRGB(16, 16, 16), 0.25, true)
    DrawUI.title = newText(title, 14, Color3.fromRGB(255, 255, 255), true)
    DrawUI.closeX = newText("X", 14, Color3.fromRGB(255, 90, 90), true)
    DrawUI.reopenTxt = newText("MENU", 13, Color3.fromRGB(255, 255, 255), true)
    DrawUI.reopenBg = newSquare(Color3.fromRGB(30, 30, 30), 0.15, true)
    DrawUI.reopenBorder = newSquare(Color3.fromRGB(90, 220, 120), 0, false)
    DrawUI.reopenBorder.Thickness = 1.5
    local cam = workspace:FindFirstChild("Camera")
    local vp = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    DrawUI.x = (vp.X - DrawUI.w) * 0.5
    DrawUI.y = (vp.Y - 160) * 0.5
    DrawUI.dirty = true
end

function DrawUI.handleClick(mx, my)
    if not DrawUI.running or not DrawUI.rows then return end
    for _, r in ipairs(DrawUI.rows) do
        if mx >= r.x and mx <= r.x + r.w and my >= r.y and my <= r.y + r.h then
            if r.kind == "reopen" then
                DrawUI.visible = true
                DrawUI.draw()
            elseif r.kind == "close" then
                DrawUI.visible = false
                DrawUI.draw()
            elseif r.kind == "title" then
                DrawUI.drag = { ox = mx - DrawUI.x, oy = my - DrawUI.y }
            elseif r.kind == "toggle" then
                r.ctl.value = not r.ctl.value
                DrawUI.draw()
            elseif r.kind == "dropdown" then
                r.ctl.open = not r.ctl.open
                DrawUI.draw()
            elseif r.kind == "opt" then
                r.ctl.value = r.idx
                r.ctl.open = false
                DrawUI.draw()
            end
            return
        end
    end
end

task.spawn(function()
    local lastDown = false
    while DrawUI.running do
        local down = false
        pcall(function() down = ismouse1pressed() end)
        if DrawUI.drag then
            if down then
                local m = lp:GetMouse()
                if m then
                    DrawUI.x = m.X - DrawUI.drag.ox
                    DrawUI.y = m.Y - DrawUI.drag.oy
                    DrawUI.draw()
                end
            else
                DrawUI.drag = nil
            end
        end
        if down and not lastDown then
            local m = lp:GetMouse()
            if m then DrawUI.handleClick(m.X, m.Y) end
        end
        lastDown = down
        task.wait(0.05)
    end
end)

task.spawn(function()
    while DrawUI.running do
        if DrawUI.dirty then
            DrawUI.draw()
            DrawUI.dirty = false
        end
        task.wait(0.1)
    end
end)

-- ===== BUILD MENU =====
DrawUI.init("Mine a Mountain ESP")
DrawUI.toggle("ore_enabled", "Ore ESP", true)
DrawUI.toggle("boulder_enabled", "Boulder ESP", true)
DrawUI.dropdown("ore_range", "Ore Range", { "200", "350", "500", "750", "1000" }, 2)
DrawUI.dropdown("boulder_range", "Boulder Range", { "200", "350", "500", "750", "1000" }, 2)
DrawUI.dropdown("ore_rarity", "Ore Rarity", { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic" }, 1)

local menuKeyConn
local function stopUI()
    DrawUI.running = false
    if menuKeyConn then menuKeyConn:Disconnect() end
    for _, o in ipairs(DrawUI.allObjs) do
        pcall(function() o:Remove() end)
    end
end
_G.espUI = { stop = stopUI }

-- ===== CRYSTAL ESP =====
do
    local POOL = 64
    local nodes = {}
    local pool = {}
    local conn
    local running = true
    local tierColor = {}
    local tierColorReady = false

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
            local Things = game.Workspace:FindFirstChild("Things")
            local Crystals = Things and Things:FindFirstChild("Crystals")
            if Crystals and DrawUI.val("ore_enabled", true) then
                local range = tonumber(DrawUI.option("ore_range", "350")) or 350
                local filter = DrawUI.option("ore_rarity", "All")
                if not tierColorReady then
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
                        if seen >= 6 then break end
                    end
                    tierColorReady = true
                end
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myPos = root and root.Position
                for _, c in ipairs(Crystals:GetChildren()) do
                    local pos = c.Position
                    if myPos then
                        local d = (pos - myPos).Magnitude
                        if d > range + 60 then continue end
                    end
                    if filter ~= "All" then
                        local tn = c:GetAttribute("TierName")
                        if tostring(tn or "") ~= filter then continue end
                    end
                    local cname = c:GetAttribute("CrystalName")
                    local tier = c:GetAttribute("Tier")
                    local r = c:GetAttribute("TierColorR")
                    local g = c:GetAttribute("TierColorG")
                    local b = c:GetAttribute("TierColorB")
                    out[#out + 1] = {
                        pos = pos,
                        h = (c.Size.Y or 3) + 2,
                        name = (cname and cname ~= "" and tostring(cname)) or c.Name,
                        value = tostring(c:GetAttribute("Value") or ""),
                        color = tierColor[tier] or Color3.fromRGB(r or 255, g or 255, b or 255),
                    }
                end
            end
            nodes = out
            task.wait(0.8)
        end
    end)

    conn = RunService.RenderStepped:Connect(function()
        if not DrawUI.val("ore_enabled", true) then
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

    local function stop()
        if not running then return end
        running = false
        if conn then conn:Disconnect() end
        for i = 1, POOL do
            pool[i].box:Remove()
            pool[i].tag:Remove()
        end
    end

    _G.oreEsp = { stop = stop }
end

-- ===== BOULDER ESP =====
do
    local POOL = 32
    local nodes = {}
    local pool = {}
    local conn
    local running = true

    local rarityColor = {
        Common = Color3.fromRGB(180, 210, 150),
        Uncommon = Color3.fromRGB(120, 220, 255),
        Rare = Color3.fromRGB(255, 220, 120),
        Epic = Color3.fromRGB(210, 150, 255),
        Legendary = Color3.fromRGB(255, 150, 90),
        Mythic = Color3.fromRGB(255, 90, 90),
    }

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
            local MD = game.Workspace:FindFirstChild("MountainDecorations")
            local B = MD and MD:FindFirstChild("Boulders")
            if not B then
                B = game.Workspace:FindFirstChild("BoulderTest")
            end
            if B and DrawUI.val("boulder_enabled", true) then
                local range = tonumber(DrawUI.option("boulder_range", "350")) or 350
                local char = lp.Character
                local root = char and char:FindFirstChild("HumanoidRootPart")
                local myPos = root and root.Position
                for _, b in ipairs(B:GetChildren()) do
                    local name = b:GetAttribute("BoulderName")
                    if not name then continue end
                    local minX, minY, minZ = math.huge, math.huge, math.huge
                    local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge
                    local n = 0
                    for _, p in ipairs(b:GetChildren()) do
                        local cn = p.ClassName
                        if cn == "MeshPart" or cn == "Part" then
                            local pos = p.Position
                            if pos.X < minX then minX = pos.X end
                            if pos.Y < minY then minY = pos.Y end
                            if pos.Z < minZ then minZ = pos.Z end
                            if pos.X > maxX then maxX = pos.X end
                            if pos.Y > maxY then maxY = pos.Y end
                            if pos.Z > maxZ then maxZ = pos.Z end
                            n = n + 1
                        end
                    end
                    if n == 0 then
                        local primary = b.PrimaryPart
                        if not primary then continue end
                        local pos = primary.Position
                        local s = primary.Size
                        minX, maxX = pos.X - s.X * 0.5, pos.X + s.X * 0.5
                        minY, maxY = pos.Y - s.Y * 0.5, pos.Y + s.Y * 0.5
                        minZ, maxZ = pos.Z - s.Z * 0.5, pos.Z + s.Z * 0.5
                    end
                    local cx = (minX + maxX) * 0.5
                    local cy = (minY + maxY) * 0.5
                    local cz = (minZ + maxZ) * 0.5
                    local h = maxY - minY
                    if myPos then
                        local d = (Vector3.new(cx, cy, cz) - myPos).Magnitude
                        if d > range + 60 then continue end
                    end
                    local rarity = b:GetAttribute("Rarity")
                    local rarityTxt = rarity and tostring(rarity) or ""
                    out[#out + 1] = {
                        pos = Vector3.new(cx, cy, cz),
                        h = h,
                        name = tostring(name),
                        rarity = rarityTxt,
                        color = rarityColor[rarityTxt] or Color3.fromRGB(255, 225, 160),
                    }
                end
            end
            nodes = out
            task.wait(0.8)
        end
    end)

    conn = RunService.RenderStepped:Connect(function()
        if not DrawUI.val("boulder_enabled", true) then
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
            local half = e.h * 0.5 + 1
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
                d.tag.Text = e.rarity ~= "" and (e.name .. " (" .. e.rarity .. ")") or e.name
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

    local function stop()
        if not running then return end
        running = false
        if conn then conn:Disconnect() end
        for i = 1, POOL do
            pool[i].box:Remove()
            pool[i].tag:Remove()
        end
    end

    _G.boulderEsp = { stop = stop }
end

menuKeyConn = UIS.InputBegan:Connect(function(input)
    if input and input.KeyCode == 0x23 then
        DrawUI.visible = not DrawUI.visible
        DrawUI.draw()
    end
end)

notify("Enjoy <3", "", 4)
