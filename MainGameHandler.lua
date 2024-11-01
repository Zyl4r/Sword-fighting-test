local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local DataHandler = require(ServerStorage.Content.DataModules.DataHandler)

local arenaPlayers = {} --Table that tells how many players are in arena

Players.PlayerAdded:Connect(function(player)
	setAllPlayersText("Waiting for players...")
	
	player.CharacterAdded:Connect(function(character)
		character.Parent = workspace.LobbyPlayers
	end)
	
	DataHandler.LoadData(player)
	
	if #Players:GetPlayers() == 2 then --If the number of players in-game is equals to two, then start intermission
		intermission(20, 2)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	DataHandler.SaveData(player) --Saves player data for the last time and removes the player from the session table
	
	if arenaPlayers and table.find(arenaPlayers, player.Character) then
		table.remove(arenaPlayers, table.find(arenaPlayers, player.Character)) --If arenaPlayers is not nil and the player who left is in the table, remove him from the array
	end
end)

--Disconnects all the connections in the table passed as the argument, if it exists.
function disconnectAll(tab: {[any]: RBXScriptConnection})
	for _, connection in tab do
		connection:Disconnect()
	end
end

--Sets all players TextLabel text to the argument passed.
function setAllPlayersText(text: string)
	for _, player in Players:GetPlayers() do
		player.PlayerGui:WaitForChild("TopText").Canva.TextLabel.Text = text
	end
end

--Returns a spawn based on the index argument.
function getRandomSpawn(index: number): BasePart
	local spawns = {} --Creates an array that adds all the spawns to it
	
	for _, part in workspace.Arena.Spawns:GetChildren() do
		if part.Name == "Part" then
			table.insert(spawns, part) --Insert the spawn to the table
		end
	end
	
	local result = spawns[index]
	spawns = nil --Sets the table to nil to prevent memory leak
	
	return result --Returns the random spawn based on the math.random() index
end

--Counts down a timer until it reaches 0 and then start the match.
function intermission(intermissionTime: number, minimumPlayers: number)
	while intermissionTime > 0 do
		setAllPlayersText("Intermission: ".. intermissionTime)
		
		if #Players:GetPlayers() >= minimumPlayers then
			intermissionTime -= 1
			task.wait(1)
		else
			setAllPlayersText("Waiting for players...")
			break
		end
	end
	
	startMatch(300)
end

--Starts the match connection all the humanoids to a .Died event, spawning them randomly around the map.
function startMatch(timer: number)
	local humanoidDiedConnections = {}
	arenaPlayers = {} --Sets arenaPlayers to a table again
	
	for _, player in Players:GetPlayers() do
		local randomSpawn = getRandomSpawn(math.random(1, #workspace.Arena.Spawns:GetChildren())) --Gets a random spawn
		
		player.Character.PrimaryPart.CFrame = randomSpawn.CFrame * CFrame.new(0, 1, 0)
		ServerStorage.Content.Tools.ClassicSword:Clone().Parent = player.Character
		player.Character.Parent = workspace.ArenaPlayers
		table.insert(arenaPlayers, player.Character) --Inserts the player's character into the arenaPlayers array
		
		humanoidDiedConnections[player.Name] = player.Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
			local creatorTag = player.Character.Humanoid:FindFirstChild("creator") --Gets who killed the player
			local killerLeaderstats = creatorTag.Value:FindFirstChild("leaderstats")
			
			if creatorTag and creatorTag.Value then
				killerLeaderstats.Kills.Value += 1
				
				DataHandler.UpdateSession(creatorTag.Value, "Kills", function(currentKills)
					return currentKills + 1 --Adds a kill to player data
				end)
			end
			
			table.remove(arenaPlayers, table.find(arenaPlayers, player.Character)) --Removes player from the arena
			humanoidDiedConnections[player.Name]:Disconnect() --Disconnects player's Humanoid.Died event
			humanoidDiedConnections[player.Name] = nil --Removes the player from the dictionary
		end)
	end
	
	while timer > 0 do
		setAllPlayersText("Timer: ".. timer)
		
		if #workspace.ArenaPlayers:GetChildren() > 1 then
			timer -= 1
			task.wait(1)
		else
			disconnectAll(humanoidDiedConnections) --Disconnects all humanoidDiedConnections that are left in the dictionary
			endMatch(arenaPlayers[1]) --The "arenaPlayers[1]" is the last player standing in the table
			arenaPlayers = nil --Sets the array to nil to prevent memory leak
			humanoidDiedConnections = nil --Sets the dictionary to nil to prevent memory leak
			break
		end
	end
end

--Ends the match and gives a win to the player based on the character passed as an argument.
function endMatch(character: Model)
	local leaderstats = Players:GetPlayerFromCharacter(character).leaderstats
	
	setAllPlayersText(character.Name.. " won the round!")
	leaderstats.Wins.Value += 1
	DataHandler.UpdateSession(Players:GetPlayerFromCharacter(character), "Wins", function(currentWins)
		return currentWins + 1 --Adds a win to the player's data
	end)
	task.wait(3)
	character:FindFirstChildOfClass("Humanoid").Health = 0 --Sends the player to the lobby again
	intermission(20, 2) --Start intermission once again
end