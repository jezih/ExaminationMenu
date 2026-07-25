notify("The tab can be found in the UI [ INSERT ]", "<3", 5)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local infoTarget
local infoSound
local infoPlayers
local infoStatus

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
    ["Stalker"] = "121393698511464",
    ["I dont feel so good"] = "90558775084399",
    ["J*bs?"] = "115503829240813",
    ["Metal Pipe"] = "139668725303708",
    ["Discord PING"] = "135272730546427",
    ["Discord JOIN"] = "130010281028004",
    ["Discord LEAVE"] = "96334570383985",
    ["Discord CALL"] = "4814018992",
    ["Whatsapp Whistle"] = "116421256176747",
    ["IPHONE RINGTONE"] = "589932864",
    ["Nokia Ringtone"] = "109992720088622",
    ["miku calling"] = "8247775255",
    ["miku"] = "117698935878433",
    ["goku?"] = "5612259294", 
    ["JESUS IS HERE"] = "107601479110503"

}

local presetCategories = {

    ["Farts and Burps"] = {
        "Wet Fart",
        "Bark Fart",
        "Burp"
    },

    ["Notifications"] = {
        "Discord PING",
        "Discord JOIN",
        "Discord LEAVE",
        "Discord CALL",
        "miku calling",
        "Skype Call",
        "Phone Call",
        "Whatsapp Whistle",
        "IPHONE RINGTONE",
        "Nokia Ringtone"
    },

    ["Memes"] = {
        "Call Me a GOODBOY",
        "JESUS IS HERE",
        "MAMBO",
        "Doorbell",
        "SMB Get the door",
        "float",
        "foghorn",
        "random sound",
        "miku",
        "goku?",
        "FAHHH",
        "Metal Pipe"
    },

    ["Games"] = {
        "L4D2 Hunter Scream",
        "SpringtrapLaugh",
        "J*bs?",
        "I dont feel so good",
        "Stalker"
    },

	["Misc"] = {
        "Jellybeans",
        "IM SPONGEBOB",
        "random bs go"
	}
}


UI.AddTab("Examination", function(tab)

    task.spawn(function()
        while true do
    
            if infoTarget then
                infoTarget:SetValue(
                    selectedPlayer and selectedPlayer.Name or "None"
                )
            end
    
    
            if infoSound then
                infoSound:SetValue(
                    soundId ~= "" and soundId or "None"
                )
            end
    
    
            if infoPlayers then
                infoPlayers:SetValue(
                    tostring(#Players:GetPlayers())
                )
            end
    
    
            if infoStatus then
    
                local status = "Waiting"
    
                if selectedPlayer and soundId ~= "" then
                    status = "Ready"
                elseif selectedPlayer then
                    status = "Select Sound"
                elseif soundId ~= "" then
                    status = "Select Player"
                end
    
                infoStatus:SetValue(status)
            end
    
    
            task.wait(0.5)
        end
    end)

    local sound = tab:Section("Sound Player", "Left")
    local soundInput = sound:InputText(
        "sound_id",
        "Sound ID",
        "",
        function(text)
            soundId = cleanSoundId(text)
        end
    )
    local categoryNames = {}

    for category, _ in pairs(presetCategories) do
        table.insert(categoryNames, category)
    end
    
    table.sort(categoryNames)
    
    
    local currentCategory = "Farts and Burps"
    local presetCombo


    local function updatePresetList()

        if not presetCombo then
            return
        end
    
        presetCombo:Clear()
    
        local presets = presetCategories[currentCategory]
    
        if not presets then
            return
        end
    
        for _, preset in ipairs(presets) do
            presetCombo:Add(preset)
        end
    end
    
    
    sound:Combo(
        "sound_category",
        "Category",
        categoryNames,
        0,
        function(index, category)

            currentCategory = category
            updatePresetList()
        
        end
    )
    
    
    presetCombo = sound:Combo(
        "sound_presets",
        "Preset Sounds",
        presetCategories["Farts and Burps"],
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

	local nsgiver = tab:Section("MUST HAVE THE BADGES[I THINK]", "Right")

    nsgiver:Button("Gain the Nightstalker 'Regalia'", function()
        game.ReplicatedStorage.Events.NSVariantSelect:FireServer("Regalia")
    end)

    nsgiver:Button("Gain the Nightstalker 'Default'", function()
        game.ReplicatedStorage.Events.NSVariantSelect:FireServer("Default")
    end)


    local info = tab:Section("Information", "Right")

    info:Text("EXAMINATION")
    info:Text("Version: v1.4")
    
    infoTarget = info:InputText(
        "info_target",
        "Target",
        "None"
    )
    
    infoSound = info:InputText(
        "info_sound",
        "Sound ID",
        "None"
    )
    
    infoPlayers = info:InputText(
        "info_players",
        "Players",
        "0"
    )
    
    infoStatus = info:InputText(
        "info_status",
        "Status",
        "Idle"
    )
end)