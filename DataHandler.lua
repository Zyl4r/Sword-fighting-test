local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerData = DataStoreService:GetDataStore("PlayerData")

local DataHandler = {}
local Sessions = {} --Sessions table that will store every player in the game

local initialData = { --If player data doesn't exists, then the script will use this table as the data
	Wins = 0,
	Kills = 0
}

--Setup the player data and player leaderstats folder.
local function setup(player: Player)
	local success, data = pcall(function()
		return PlayerData:GetAsync("Player_".. player.UserId)
	end)
	
	if success then
		--Creates the leaderstats folder and its values
		local leaderstatsFolder = Instance.new("Folder")
		leaderstatsFolder.Name = "leaderstats"
		
		local winsCount = Instance.new("NumberValue")
		winsCount.Name = "Wins"
		winsCount.Parent = leaderstatsFolder
		
		local killsCount = Instance.new("NumberValue")
		killsCount.Name = "Kills"
		killsCount.Parent = leaderstatsFolder
		
		if data then
			Sessions[player.UserId] = data --If player has any data, set their current session data to the last session data
		else
			Sessions[player.UserId] = initialData --Else, sets it to the initial data
		end
		
		leaderstatsFolder.Parent = player --Parent the leaderstats folder to the player
	else
		player:Kick("Failed to load data, please rejoin.") --If anything went wrong, kick the player to prevent data loss
	end
	
end

--Loads player data from DataStore and sets their leaderstats values.
function DataHandler.LoadData(player: Player)
	setup(player) --Setups player data
	
	for key, value in Sessions[player.UserId] do
		player.leaderstats[key].Value = value --Sets their leaderstats values to the data values
	end
end

--Update the player's session key.
function DataHandler.UpdateSession(player: Player , key: string, callback)
	local session = Sessions[player.UserId]
	
	local newData = callback(session[key]) --Value returned from the function
	
	session[key] = newData --Sets the player session key to the value returned from newData
end

--Saves the player data with :SetAsync.
function DataHandler.SaveData(player: Player)
	local success, updatedData = pcall(function()
		PlayerData:SetAsync("Player_".. player.UserId, Sessions[player.UserId])
	end)
	
	if not success then
		print("Error saving player data.")
	end
end

game:BindToClose(function()
	task.wait(2) --Waits two seconds before the server shutsdown to save all the players data
end)

game.Players.PlayerRemoving:Connect(function(player)
	Sessions[player.UserId] = nil --Remove player who left from the sessions table
end)

return DataHandler
