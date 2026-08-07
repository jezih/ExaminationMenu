-- Mine a Mountain ESP (Crystals / Boulders / Veins) - Obsidian
-- v11: always-hide fix (no frozen markers), bomb-material-only veins, pcall-guarded loop

local oldCleanup = _G.__MaM_ESP_Cleanup
if oldCleanup then pcall(oldCleanup) end
_G.__MaM_ESP_Cleanup = nil

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/Library.lua"))()
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Terrain = workspace.Terrain

local BombMaterials = require(game:GetService("ReplicatedStorage").Modules.BombMaterials)

local Window = Library:CreateWindow({ Name = "Mine a Mountain ESP" })
local Toggles = Library.Toggles
local Options = Library.Options

local MainTab = Window:AddTab({ Name = "Main" })
local GeneralBox = MainTab:AddLeftGroupbox("General")
GeneralBox:AddToggle("Enabled", { Text = "Enabled", Default = true })
GeneralBox:AddSlider("MaxMarkers", { Text = "Max Markers", Default = 100, Min = 10, Max = 300, Suffix = " markers" })

local CrystalsBox = MainTab:AddRightGroupbox("Crystals")
CrystalsBox:AddToggle("Crystals", { Text = "Show Crystals", Default = true })
CrystalsBox:AddSlider("CrystalTierMax", { Text = "Max Tier", Default = 6, Min = 1, Max = 6, Suffix = "" })

local BouldersBox = MainTab:AddRightGroupbox("Boulders")
BouldersBox:AddToggle("Boulders", { Text = "Show Boulders", Default = true })

local VeinsBox = MainTab:AddRightGroupbox("Veins")
VeinsBox:AddToggle("Veins", { Text = "Show Veins", Default = true })
VeinsBox:AddSlider("VeinRange", { Text = "Range", Default = 60, Min = 10, Max = 60, Suffix = " studs" })

local TIER_COLORS = {
    [1] = Color3.fromRGB(222, 184, 135),
    [2] = Color3.fromRGB(135, 206, 250),
    [3] = Color3.fromRGB(0, 200, 180),
    [4] = Color3.fromRGB(170, 100, 220),
    [5] = Color3.fromRGB(255, 160, 210),
    [6] = Color3.fromRGB(255, 110, 200),
}
local BOMB_TIER_COLORS = {
    [1] = Color3.fromRGB(160, 160, 160),
    [2] = Color3.fromRGB(120, 220, 255),
    [3] = Color3.fromRGB(80, 200, 255),
    [4] = Color3.fromRGB(255, 140, 60),
    [5] = Color3.fromRGB(200, 180, 255),
    [6] = Color3.fromRGB(160, 255, 90),
    [7] = Color3.fromRGB(255, 255, 120),
    [8] = Color3.fromRGB(255, 90, 90),
    [9] = Color3.fromRGB(255, 60, 200),
}
local BOULDER_COLORS = {
    Mossite = Color3.fromRGB(110, 200, 120),
    Voltite = Color3.fromRGB(120, 140, 255),
    Nocturnite = Color3.fromRGB(140, 80, 200),
    Gildrite = Color3.fromRGB(255, 210, 80),
    Rimeveil = Color3.fromRGB(170, 220, 255),
}

local function formatValue(v)
    v = math.floor(v)
    local s = tostring(v)
    local out, c = {}, 0
    for i = #s, 1, -1 do
        c = c + 1
        table.insert(out, 1, s:sub(i, i))
        if c % 3 == 0 and i > 1 then table.insert(out, 1, ",") end
    end
    return table.concat(out)
end

local crystalCache, boulderCache, veinCache = {}, {}, {}
local lastScan = 0

local function rebuildCache(force)
    local now = os.clock()
    if not force and now - lastScan < 0.5 then return end
    lastScan = now

    crystalCache = {}
    local cF = workspace:FindFirstChild("Things") and workspace.Things:FindFirstChild("Crystals")
    if cF then
        local maxTier = Options.CrystalTierMax.Value
        for _, crystal in ipairs(cF:GetChildren()) do
            local tierS = crystal.Name:match("T(%d)")
            local tier = tierS and tonumber(tierS) or 1
            if tier <= maxTier then
                local cname = crystal:GetAttribute("CrystalName") or crystal.Name
                local value = crystal:GetAttribute("Value") or 0
                table.insert(crystalCache, {
                    Pos = crystal.Position,
                    Label = cname .. " $" .. formatValue(value),
                    Color = TIER_COLORS[tier] or TIER_COLORS[1],
                    Tier = tier,
                })
            end
        end
        table.sort(crystalCache, function(a, b) return a.Tier > b.Tier end)
    end

    boulderCache = {}
    local bF = workspace:FindFirstChild("MountainDecorations") and workspace.MountainDecorations:FindFirstChild("Boulders")
    if bF then
        local seen = {}
        for _, model in ipairs(bF:GetChildren()) do
            local center = model:FindFirstChild("Center")
            local point = center and center.WorldPosition
            if not point then
                point = model:GetBoundingBox()
            end
            if typeof(point) == "Vector3" then
                seen[model.Name] = (seen[model.Name] or 0) + 1
                table.insert(boulderCache, {
                    Pos = point,
                    Name = model.Name .. " #" .. seen[model.Name],
                    Color = BOULDER_COLORS[model.Name] or Color3.fromRGB(255, 120, 120),
                })
            end
        end
    end

    veinCache = {}
    if Toggles.Veins.Value then
        local radius = Options.VeinRange.Value
        local res = 4
        local camPos = Camera.CFrame.Position
        local min = camPos - Vector3.new(radius, radius, radius)
        local region = Region3.new(min, camPos + Vector3.new(radius, radius, radius))
        local mats = Terrain:ReadVoxels(region, res)
        local n = #mats
        for x = 1, n do
            local rowY = mats[x]
            for y = 1, #rowY do
                local colZ = rowY[y]
                for z = 1, #colZ do
                    local mat = colZ[z]
                    if BombMaterials.isBombMaterial(mat) then
                        local info = BombMaterials.infoFor(mat)
                        local tier = info and info.tier or 1
                        table.insert(veinCache, {
                            Pos = min + Vector3.new((x - 1) * res, (y - 1) * res, (z - 1) * res),
                            Name = info and info.matName or "Vein",
                            Color = BOMB_TIER_COLORS[tier] or Color3.fromRGB(120, 255, 120),
                        })
                        if #veinCache >= 200 then break end
                    end
                end
                if #veinCache >= 200 then break end
            end
            if #veinCache >= 200 then break end
        end
    end
end

-- drawing pool (only grows, markers hidden every frame)
local lines, texts = {}, {}
local poolN = 0
local function allocPool(n)
    if n > poolN then
        for i = poolN + 1, n do
            lines[i] = Drawing.new("Line")
            lines[i].Thickness = 1
            lines[i].Transparency = 1
            texts[i] = Drawing.new("Text")
            texts[i].Size = 13
            texts[i].Center = true
            texts[i].Outline = true
        end
        poolN = n
    end
end

local function hideAll()
    for i = 1, poolN do
        if lines[i] then
            lines[i].Visible = false
            texts[i].Visible = false
        end
    end
end

local renderConn
local cleaning = false

local function cleanup()
    if cleaning then return end
    cleaning = true
    if renderConn then renderConn:Disconnect() renderConn = nil end
    hideAll()
    for i = 1, poolN do
        pcall(function() lines[i]:Remove() end)
        pcall(function() texts[i]:Remove() end)
    end
    lines, texts, poolN = {}, {}, 0
    _G.__MaM_ESP_Cleanup = nil
    print("[ESP] cleaned")
end
_G.__MaM_ESP_Cleanup = cleanup

renderConn = RunService.RenderStepped:Connect(function()
    if cleaning then return end

    local ok, err = pcall(function()
        -- ALWAYS hide all markers first, regardless of toggles
        hideAll()

        if not Toggles.Enabled.Value then return end

        rebuildCache(false)

        local maxMarkers = Options.MaxMarkers.Value
        if maxMarkers > poolN then allocPool(maxMarkers) end

        local count = 0
        local function tryRender(pos, name, color)
            if not pos or count >= maxMarkers then return end
            local screen, onScreen = Camera:WorldToScreenPoint(pos)
            if not onScreen then return end
            local line, txt = lines[count + 1], texts[count + 1]
            line.From = Vector2.new(screen.X, screen.Y)
            line.To = Vector2.new(screen.X, screen.Y - 30)
            line.Color = color
            line.Visible = true
            txt.Text = name
            txt.Color = color
            txt.Position = Vector2.new(screen.X, screen.Y - 48)
            txt.Visible = true
            count = count + 1
        end

        if Toggles.Boulders.Value then
            for i = 1, #boulderCache do
                local b = boulderCache[i]
                tryRender(b.Pos, b.Name, b.Color)
            end
        end
        if Toggles.Veins.Value then
            for i = 1, #veinCache do
                local v = veinCache[i]
                tryRender(v.Pos, v.Name, v.Color)
            end
        end
        if Toggles.Crystals.Value then
            for i = 1, #crystalCache do
                local c = crystalCache[i]
                tryRender(c.Pos, c.Label, c.Color)
            end
        end
    end)
    if not ok then
        warn("[ESP] render error:", err)
    end
end)

Library:OnUnload(function()
    cleanup()
end)

print("[ESP] v11 loaded")
