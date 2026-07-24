notify("The tab can be found in the UI [ INSERT ]", "<3", 5)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GAME_ID = 3730079862

print("Game ID:", game.GameId)

if game.GameId ~= GAME_ID then
    return
end


local soundId = ""
local selectedPlayer = nil


local function cleanSoundId(id)
    id = tostring(id)

    return id:gsub("rbxassetid://", "")
end


local function getCharacter(player)
    if not player then
        return nil
    end

    return player.Character or player.CharacterAdded:Wait()
end


local function getPlayerNames()
    local names = {}

    for _, player in ipairs(Players:GetPlayers()) do
        table.insert(names, player.Name)
    end

    table.sort(names)

    return names
end


local soundPresets = {
    ["Skype Call"] = "104071059652477",
    ["Wet Fart"] = "110012848572836",
    ["L4D2 Hunter Scream"] = "139005512098246",
    ["Phone Call"] = "139364267074866",
    ["Call Me a GOODBOY"] = "137328940118239",
    ["Burp"] = "98335542425016",
    ["Bark Fart"] = "119447356569253",
    ["Doorbell"] = "99311007530211",
    ["SMB Get the door"] = "111008640023286",
    ["Jellybeans"] = "111533356761353",
    ["FAHHH"] = "120385128207517",
    ["IM SPONGEBOB"] = "91754532443101",
    ["float"] = "9061674082",
    ["foghorn"] = "130802578468469",
    ["random sound"] = "15379495916",
    ["SpringtrapLaugh"] = "105656677298662",
    ["MAMBO"] = "95010515443370",
    ["random bs go"] = "86197280562656",
    ["Stalker Scream From Garry's Mod"] = "121393698511464",
    ["I dont feel so good"] = "90558775084399",
    ["J*bs?"] = "115503829240813"

}


UI.AddTab("Examination", function(tab)

    local sound = tab:Section("Sound Player", "Left")


    local soundInput = sound:InputText(
        "sound_id",
        "Sound ID",
        "",
        function(text)
            soundId = cleanSoundId(text)
        end
    )


    sound:Combo(
        "sound_presets",
        "Preset Sounds",
        {
            "Skype Call",
            "Wet Fart",
            "L4D2 Hunter Scream",
            "Phone Call",
            "Call Me a GOODBOY",
            "Burp",
            "Bark Fart",
            "Doorbell",
            "SMB Get the door",
            "Jellybeans",
            "FAHHH",
            "IM SPONGEBOB",
            "float",
            "foghorn",
            "random sound",
            "SpringtrapLaugh",
            "MAMBO",
            "random bs go",
            "Stalker Scream from Garry's Mod",
            "I dont feel so good",
            "J*bs?"
        },
        0,
        function(index, text)

            local id = soundPresets[text]

            if id then
                soundId = id
                soundInput:SetValue(id)
            end

        end
    )


    local playerCombo = sound:Combo(
        "target_player",
        "Target Player",
        getPlayerNames(),
        0,
        function(index, text)

            selectedPlayer = Players:FindFirstChild(text)

            if selectedPlayer then
                print("Selected:", selectedPlayer.Name)
            end

        end
    )


    sound:Button("Refresh Players", function()

        playerCombo:Clear()

        for _, name in ipairs(getPlayerNames()) do
            playerCombo:Add(name)
        end

    end)


    sound:Button("Play Sound", function()

        if not selectedPlayer then
            warn("No player selected")
            return
        end


        if soundId == "" then
            warn("No sound ID")
            return
        end


        local character = getCharacter(selectedPlayer)

        if not character then
            warn("Character missing")
            return
        end


        local remote = ReplicatedStorage:FindFirstChild("CoughSound")

        if not remote then
            warn("CoughSound missing")
            return
        end


        pcall(function()
            remote:FireServer(
                "rbxassetid://" .. soundId,
                character
            )
        end)

    end)



    local viral = tab:Section("Viral Control", "Right")


    viral:Button("Turn into Viral", function()

        local events = ReplicatedStorage:FindFirstChild("Events")

        if not events then
            warn("Events folder missing")
            return
        end


        local remote = events:FindFirstChild("TachyonDialogue")

        if not remote then
            warn("TachyonDialogue missing")
            return
        end


        pcall(function()
            remote:InvokeServer("handover")
        end)


        notify(
            "If you wish to turn into a viral again, please rejoin.",
            "WARNING",
            5
        )

    end)

end)