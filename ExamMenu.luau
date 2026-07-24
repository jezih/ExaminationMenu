local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))() or INSui

local gameVerification = game.GameId
print("Game ID: "..gameVerification)

if gameVerification ~= 3730079862 then return end

local win = Lib:CreateWindow({ 
    title = "Examination", 
    size = Vector2.new(500, 325) 
})

local tab = win:Tab("Main", "eye")
local sec = tab:Section("Sound Player", "Full")
local sec2 = tab:Section("Viral Control", "Full")

local soundId = ""

sec:Textbox("Sound ID:", "", function(text)
    soundId = "rbxassetid://"..text
end)

local function getPlayerNames()
    local names = {}

    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        table.insert(names, player.Name)
    end

    return names
end

local selectedPlayer = nil
local selectedCharacter = nil

sec:Dropdown("Target player:", {}, function()
    return getPlayerNames()
end, false, function(v)
    selectedPlayer = game:GetService("Players"):FindFirstChild(v[1])

    if selectedPlayer then
        selectedCharacter = selectedPlayer.Character or selectedPlayer.CharacterAdded:Wait()
        print("Player:", selectedPlayer.Name)
        print("Character:", selectedCharacter)
    end
end)

sec:Button("Play Sound", function()
    print("Character:", selectedCharacter)
	game.ReplicatedStorage.CoughSound:FireServer(soundId, selectedCharacter)
end)

sec2:Button("Turn into Viral", function()
	notify("If you wish to turn into a viral again, please rejoin.", "WARNING", 5)
	game.ReplicatedStorage.Events.TachyonDialogue:InvokeServer("handover")
end)
