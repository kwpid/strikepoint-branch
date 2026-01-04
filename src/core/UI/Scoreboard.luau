local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Enum = Enum
local Color3 = Color3

local Scoreboard = {}

local function formatTime(seconds, isOvertime)
	local min = math.floor(math.abs(seconds) / 60)
	local sec = math.abs(seconds) % 60
	if isOvertime then
		return string.format("+%d:%02d", min, sec)
	else
		return string.format("%d:%02d", min, sec)
	end
end

function Scoreboard.UpdateBoard(player, boardInfo, color)
	if not boardInfo then
		return
	end
	local surface = boardInfo:FindFirstChild("SurfaceGui")
	if surface and surface:FindFirstChild("Frame") then
		local frame = surface.Frame
		frame.PlayerName.Text = player.DisplayName
		if boardInfo.Parent and boardInfo.Parent:FindFirstChild("Union") then
			boardInfo.Parent.Union.Color = color
		end
		task.spawn(function()
			local content = Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
			frame.PlayerIcon.Image = content
		end)
	end
end

function Scoreboard.UpdateLobbyBoard(board, player)
	local surface = board:FindFirstChild("SurfaceGui")
	if not surface then
		return
	end
	local frame = surface:FindFirstChild("Frame")
	if not frame then
		return
	end

	if player then
		frame.PlayerName.Text = player.DisplayName
		if board.Parent and board.Parent:FindFirstChild("Union") then
			board.Parent.Union.Color = Color3.new(0, 1, 0)
		end
		task.spawn(function()
			frame.PlayerIcon.Image = Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
	else
		frame.PlayerName.Text = "Waiting..."
		if board.Parent and board.Parent:FindFirstChild("Union") then
			board.Parent.Union.Color = Color3.new(1, 1, 1)
		end
		frame.PlayerIcon.Image = "rbxassetid://9319891706"
	end
end

function Scoreboard.FormatTime(seconds, isOvertime)
	return formatTime(seconds, isOvertime)
end

if RunService:IsServer() then
	local RemoteEventsFolder = ReplicatedStorage:FindFirstChild("Ball_Events")
	if not RemoteEventsFolder then
		RemoteEventsFolder = Instance.new("Folder")
		RemoteEventsFolder.Name = "Ball_Events"
		RemoteEventsFolder.Parent = ReplicatedStorage
	end

	local ScoreboardEvent = RemoteEventsFolder:FindFirstChild("ScoreboardEvent")
	if not ScoreboardEvent then
		ScoreboardEvent = Instance.new("RemoteEvent")
		ScoreboardEvent.Name = "ScoreboardEvent"
		ScoreboardEvent.Parent = RemoteEventsFolder
	end

	local function fire(player, action, data)
		if player then
			ScoreboardEvent:FireClient(player, action, data)
		end
	end

	function Scoreboard.SetGameUIVisibility(players, visible, initialTimeText)
		for _, p in ipairs(players) do
			fire(p, "SetGameUIVisibility", { visible = visible, initialTimeText = initialTimeText })
		end
	end

	function Scoreboard.UpdateScoreUI(players, scores)
		for _, p in ipairs(players) do
			fire(p, "UpdateScoreUI", { scores = scores })
		end
	end

	function Scoreboard.UpdateClockUI(players, timeText)
		for _, p in ipairs(players) do
			fire(p, "UpdateClockUI", { timeText = timeText })
		end
	end

	function Scoreboard.SetCountdownText(players, txt)
		for _, p in ipairs(players) do
			fire(p, "SetCountdownText", { text = txt })
		end
	end

	function Scoreboard.ShowGoalUI(players, playerName)
		for _, p in ipairs(players) do
			fire(p, "ShowGoalUI", { playerName = playerName })
		end
	end

	function Scoreboard.UpdateStatusText(lobbyRef, msg)
		local mainSurf = lobbyRef.MainBoard:FindFirstChild("SurfaceGui")
		if mainSurf and mainSurf:FindFirstChild("Frame") then
			local status = mainSurf.Frame:FindFirstChild("Status")
			if status then
				status.Text = msg
			else
				local lbl = mainSurf.Frame:FindFirstChild("PlayerName")
					or mainSurf.Frame:FindFirstChildOfClass("TextLabel")
				if lbl then
					lbl.Text = msg
				end
			end
		end
	end
else
	local React = require(ReplicatedStorage.Packages.React)
	local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

	local root = nil
	local clientState = {
		visible = false,
		clockText = "0:00",
		scores = { red = 0, blue = 0 },
		countdownText = "",
		goalMessage = nil,
	}

	local callbacks = {}
	local function subscribe(callback)
		table.insert(callbacks, callback)
		return function()
			for i, cb in ipairs(callbacks) do
				if cb == callback then
					table.remove(callbacks, i)
					break
				end
			end
		end
	end

	local function emit()
		for _, cb in ipairs(callbacks) do
			cb(clientState)
		end
	end

	local RemoteEventsFolder = ReplicatedStorage:WaitForChild("Ball_Events", 10)
	local ScoreboardEvent = RemoteEventsFolder:WaitForChild("ScoreboardEvent")

	local TICK_SOUND_ID = "rbxassetid://114182879076763"
	local GO_SOUND_ID = "rbxassetid://70630733010083"
	local tickSound = nil
	local goSound = nil

	ScoreboardEvent.OnClientEvent:Connect(function(action, data)
		if action == "SetGameUIVisibility" then
			clientState.visible = data.visible
			if data.initialTimeText then
				clientState.clockText = data.initialTimeText
			end
		elseif action == "UpdateScoreUI" then
			clientState.scores = data.scores
		elseif action == "UpdateClockUI" then
			clientState.clockText = data.timeText
		elseif action == "SetCountdownText" then
			if data.text ~= "" and data.text ~= clientState.countdownText then
				if data.text == "GO!" then
					if not goSound then
						goSound = Instance.new("Sound")
						goSound.SoundId = GO_SOUND_ID
						goSound.Parent = game:GetService("SoundService")
					end
					goSound:Play()
				elseif tonumber(data.text) then
					if not tickSound then
						tickSound = Instance.new("Sound")
						tickSound.SoundId = TICK_SOUND_ID
						tickSound.Parent = game:GetService("SoundService")
					end
					tickSound:Play()
				end
			end
			clientState.countdownText = data.text
		elseif action == "ShowGoalUI" then
			clientState.goalMessage = (data.playerName or "Someone") .. " SCORED!"
			task.delay(3, function()
				if clientState.goalMessage == ((data.playerName or "Someone") .. " SCORED!") then
					clientState.goalMessage = nil
					emit()
				end
			end)
		end
		emit()
	end)

	local function GameScoreboard(props)
		if not props.visible then
			return nil
		end

		return React.createElement("ScreenGui", {
			Name = "GameGUI",
			ResetOnSpawn = false,
		}, {
			GameScreen = React.createElement("Frame", {
				Name = "GameScreen",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Active = false,
			}, {
				RedScore = React.createElement("Frame", {
					Name = "Red",
					Position = UDim2.fromScale(0.35, 0.05),
					Size = UDim2.fromScale(0.08, 0.05),
					BackgroundColor3 = Color3.fromRGB(255, 60, 60),
				}, {
					Constraint = React.createElement("UIScale", { Scale = 1 }), -- Placeholder for consistency
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(150, 60),
						MinSize = Vector2.new(60, 30),
					}),
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Score = React.createElement("TextLabel", {
						Name = "RedScore",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = tostring(props.scores.red),
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
					}),
				}),

				BlueScore = React.createElement("Frame", {
					Name = "Blue",
					Position = UDim2.fromScale(0.65, 0.05), -- Adjusted for symmetry
					AnchorPoint = Vector2.new(1, 0), -- Anchor right
					Size = UDim2.fromScale(0.08, 0.05),
					BackgroundColor3 = Color3.fromRGB(60, 60, 255),
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(150, 60),
						MinSize = Vector2.new(60, 30),
					}),
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Score = React.createElement("TextLabel", {
						Name = "BlueScore",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = tostring(props.scores.blue),
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
					}),
				}),

				Clock = React.createElement("Frame", {
					Name = "Clock",
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.05),
					Size = UDim2.fromScale(0.12, 0.06),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(200, 80),
						MinSize = Vector2.new(80, 40),
					}),
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					Text = React.createElement("TextLabel", {
						Name = "ClockText",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = props.clockText,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Font = Enum.Font.GothamBold,
					}),
				}),

				Countdown = (props.countdownText ~= "") and React.createElement("Frame", {
					Name = "Countdown",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.4),
					Size = UDim2.fromScale(0.3, 0.15),
					BackgroundTransparency = 1,
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(500, 200),
						MinSize = Vector2.new(150, 60),
					}),
					Text = React.createElement("TextLabel", {
						Name = "TextLabel",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = props.countdownText,
						TextColor3 = Color3.fromRGB(255, 255, 0),
						TextScaled = true,
						Font = Enum.Font.LuckiestGuy,
						TextStrokeTransparency = 0,
					}),
				}),

				GoalPopup = props.goalMessage and React.createElement("Frame", {
					Name = "Goal",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.3),
					Size = UDim2.fromScale(0.4, 0.15),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.5,
				}, {
					SizeConstraint = React.createElement("UISizeConstraint", {
						MaxSize = Vector2.new(600, 200),
						MinSize = Vector2.new(200, 60),
					}),
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
					Text = React.createElement("TextLabel", {
						Name = "TextLabel",
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = props.goalMessage,
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						Font = Enum.Font.FredokaOne,
					}),
				}),
			}),
		})
	end

	local function AppContainer()
		local state, setState = React.useState(clientState)

		React.useEffect(function()
			local player = Players.LocalPlayer

			local function syncVisibility()
				local inGame = player:GetAttribute("GameId") ~= nil
				if inGame ~= clientState.visible then
					clientState.visible = inGame
					if inGame == false then
						clientState.countdownText = ""
						clientState.goalMessage = nil
					end
					emit()
				end
			end

			syncVisibility()
			local attrConn = player:GetAttributeChangedSignal("GameId"):Connect(syncVisibility)

			local unsubscribe = subscribe(function(newState)
				setState(table.clone(newState))
			end)

			return function()
				attrConn:Disconnect()
				unsubscribe()
			end
		end, {})

		return React.createElement(GameScoreboard, state)
	end

	Scoreboard.Component = AppContainer

	function Scoreboard.Mount()
		local player = Players.LocalPlayer
		local playerGui = player:WaitForChild("PlayerGui")

		if not root then
			root = ReactRoblox.createRoot(playerGui)
		end
		root:render(React.createElement(AppContainer))
	end
end

return Scoreboard
