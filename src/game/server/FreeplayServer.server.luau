print("FreeplayServer: Script starting...")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("FreeplayServer: Requiring MatchManager...")
local MatchManager = require(ReplicatedStorage.Core.MatchHandler.MatchManager)
print("FreeplayServer: Requiring MapManager...")
local MapManager = require(ReplicatedStorage.Core.MatchHandler.MapManager)
print("FreeplayServer: Requires completed.")

local remoteEvents = ReplicatedStorage:WaitForChild("Ball_Events", 5)
if not remoteEvents then
	warn("FreeplayServer: RemoteEvents folder NOT found!")
	return
end

local enterFreeplayEvent = remoteEvents:WaitForChild("EnterFreeplayEvent", 5)
if not enterFreeplayEvent then
	warn("FreeplayServer: EnterFreeplayEvent NOT found in RemoteEvents!")
end

local activeFreeplaySessions = {}

local function createFreeplaySession(player, mapName)
	print(`Creating freeplay session for {player.Name} on map {mapName}`)

	if activeFreeplaySessions[player.UserId] then
		warn(`Player {player.Name} already has an active freeplay session`)
		return
	end

	local mapsFolder = ReplicatedStorage:FindFirstChild("Maps")
	if not mapsFolder then
		warn("Maps folder not found")
		return
	end

	local oneV1Folder = mapsFolder:FindFirstChild("1v1")
	if not oneV1Folder then
		warn("1v1 maps folder not found")
		return
	end

	local mapModel = oneV1Folder:FindFirstChild(mapName)
	if not mapModel then
		warn(`Map {mapName} not found in 1v1 folder`)
		return
	end

	local gameId = `freeplay_{player.UserId}_{os.time()}`

	local GamesFolder = workspace:FindFirstChild("Games")
	if not GamesFolder then
		GamesFolder = Instance.new("Folder")
		GamesFolder.Name = "Games"
		GamesFolder.Parent = workspace
	end

	local gameContainer = Instance.new("Folder")
	gameContainer.Name = "Freeplay_" .. gameId
	gameContainer.Parent = GamesFolder

	local arena = mapModel:Clone()
	arena.Name = "Arena_" .. gameId

	local offsetIndex = #GamesFolder:GetChildren()
	local offsetPos = Vector3.new(offsetIndex * 2500, 0, 0)
	arena:PivotTo(arena:GetPivot() + offsetPos)
	arena.Parent = gameContainer

	local spawnPoint = arena:FindFirstChild("T1") or arena:FindFirstChild("Plate1")
	if not spawnPoint then
		warn(`No spawn point found in map {mapName}`)
		gameContainer:Destroy()
		return
	end

	-- Disable Map Zones in Freeplay
	local bounds = arena:FindFirstChild("Bounds")
	if bounds then
		for _, child in ipairs(bounds:GetChildren()) do
			if child.Name:find("Zone") then
				child:Destroy()
			end
		end
	end

	-- Spawn Ball at Center
	local ballSpawn = arena:FindFirstChild("BallSpawn")
	if ballSpawn then
		local resetBallEvent = remoteEvents:WaitForChild("ResetBall", 5)
		if resetBallEvent then
			print(`FreeplayServer: Firing ResetBall for center spawn at {ballSpawn.Position}`)
			resetBallEvent:Fire(ballSpawn.Position, gameId, arena)
		else
			warn("FreeplayServer: ResetBall event not found in RemoteEvents!")
		end
	end

	player:SetAttribute("GameId", gameId)
	activeFreeplaySessions[player.UserId] = {
		gameId = gameId,
		container = gameContainer,
		arena = arena,
	}

	task.wait(0.2)

	local character = player.Character
	if character then
		-- Force-Equip Sword attribute so SwordServer handles it
		-- Force-Equip Sword attribute so SwordServer handles it
		local equippedSword = "DefaultSword"
		if _G.DataService then
			equippedSword = _G.DataService.GetEquippedSword(player)
		end

		-- DIAGNOSTIC: Check if sword model exists
		local swordsFolder = ReplicatedStorage:FindFirstChild("Core")
			and ReplicatedStorage.Core:FindFirstChild("AssetManager")
			and ReplicatedStorage.Core.AssetManager:FindFirstChild("Swords")
		if swordsFolder then
			local model = swordsFolder:FindFirstChild(equippedSword)
			if model then
				print(`FreeplayServer: Found sword model {equippedSword} in AssetManager`)
			else
				warn(
					`FreeplayServer: Sword model {equippedSword} NOT found in AssetManager! Available:`,
					table.concat(swordsFolder:GetChildren(), ", ")
				)
			end
		else
			warn("FreeplayServer: AssetManager/Swords folder NOT found!")
		end

		character:SetAttribute("EquippedSword", equippedSword)
		print(`FreeplayServer: Set EquippedSword attribute to {equippedSword} for {player.Name}`)

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			humanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 5, 0)
			print(`FreeplayServer: Teleported {player.Name} to spawn point`)
		end
	end

	player:SetAttribute("Team", "red")
	print(`Freeplay session {gameId} created for {player.Name} in workspace`)
end

local leaveFreeplayEvent = remoteEvents:WaitForChild("LeaveFreeplayEvent", 5)
if not leaveFreeplayEvent then
	leaveFreeplayEvent = Instance.new("RemoteEvent")
	leaveFreeplayEvent.Name = "LeaveFreeplayEvent"
	leaveFreeplayEvent.Parent = remoteEvents
end

leaveFreeplayEvent.OnServerEvent:Connect(function(player)
	local session = activeFreeplaySessions[player.UserId]
	if session then
		print(`FreeplayServer: {player.Name} is leaving freeplay`)
		if session.container then
			session.container:Destroy()
		end
		activeFreeplaySessions[player.UserId] = nil
		player:SetAttribute("GameId", nil)
		player:SetAttribute("Team", nil)

		local teamService = game:GetService("Teams")
		local lobbyTeam = teamService:FindFirstChild("Lobby")
		if lobbyTeam then
			player.Team = lobbyTeam
		end

		-- Teleport back to spawn if needed, or character reset
		player:LoadCharacter()
	end
end)

if enterFreeplayEvent then
	enterFreeplayEvent.OnServerEvent:Connect(function(player, mapName)
		print(`FreeplayServer: Received EnterFreeplayEvent from {player.Name} for map {mapName}`)
		print(
			`FreeplayServer: Event Instance: {enterFreeplayEvent:GetFullName()} (Parent: {enterFreeplayEvent.Parent.Name})`
		)
		if not mapName or type(mapName) ~= "string" then
			warn(`Invalid map name from {player.Name}`)
			return
		end

		createFreeplaySession(player, mapName)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	local session = activeFreeplaySessions[player.UserId]
	if session then
		if session.container then
			session.container:Destroy()
		end
		activeFreeplaySessions[player.UserId] = nil
		print(`Cleaned up freeplay session for {player.Name}`)
	end
end)

print("FreeplayServer loaded")
