local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Scoreboard = require(ReplicatedStorage.Core.UI.Scoreboard)
local Hotbar = require(ReplicatedStorage.Core.UI.Hotbar)
local Sidebar = require(ReplicatedStorage.Core.UI.Sidebar)
local Inventory = require(ReplicatedStorage.Core.UI.Inventory)

local PlayGUI = require(ReplicatedStorage.Core.UI.PlayGUI)
local NavBar = require(ReplicatedStorage.Core.UI.NavBar)
local Settings = require(ReplicatedStorage.Core.UI.Settings)

local function App()
	local activeWindow, setActiveWindow = React.useState(nil)
	local isInGame, setIsInGame = React.useState(false)
	local screenScale, setScreenScale = React.useState(1)

	React.useEffect(function()
		local camera = workspace.CurrentCamera
		local function updateScale()
			local viewportSize = camera.ViewportSize
			-- Target 1920x1080 as base resolution
			local scale = math.min(viewportSize.X / 1920, viewportSize.Y / 1080)
			setScreenScale(math.max(scale, 0.4)) -- Lowered for mobile
		end

		updateScale()
		local connection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)
		return function()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local player = Players.LocalPlayer
		local function updateState()
			local gid = player:GetAttribute("GameId")
			setIsInGame(gid ~= nil)
			if gid ~= nil then
				setActiveWindow(nil)
			end
		end

		updateState()
		local connection = player:GetAttributeChangedSignal("GameId"):Connect(updateState)

		return function()
			connection:Disconnect()
		end
	end, {})

	React.useEffect(function()
		local camera = workspace.CurrentCamera
		local blur = Lighting:FindFirstChild("MenuBlur")
		if not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "MenuBlur"
			blur.Size = 0
			blur.Parent = Lighting
		end

		local targetFOV = activeWindow and 50 or 70
		local targetBlur = activeWindow and 20 or 0

		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		TweenService:Create(camera, tweenInfo, { FieldOfView = targetFOV }):Play()
		TweenService:Create(blur, tweenInfo, { Size = targetBlur }):Play()

		return function() end
	end, { activeWindow })

	local menuWindows = {
		PlayGUI = (not isInGame) and React.createElement(PlayGUI, {
			visible = activeWindow == "Play",
			onClose = function()
				setActiveWindow(nil)
			end,
			onModeSelect = function(mode)
				print("Selected Game Mode:", mode)
				setActiveWindow(nil)
			end,
		}) or nil,

		Inventory = Inventory.Component and React.createElement(Inventory.Component, {
			visible = activeWindow == "Inventory",
			onClose = function()
				setActiveWindow(nil)
			end,
		}) or nil,

		Settings = React.createElement(Settings, {
			visible = activeWindow == "Settings",
			onClose = function()
				setActiveWindow(nil)
			end,
		}),
	}

	return React.createElement(React.Fragment, nil, {
		Scoreboard = Scoreboard.Component and React.createElement(Scoreboard.Component) or nil,
		Hotbar = Hotbar.Component and React.createElement(Hotbar.Component) or nil,

		Sidebar = (Sidebar.Component and not isInGame) and React.createElement(Sidebar.Component, {
			currentWindow = activeWindow,
			setWindow = setActiveWindow,
		}) or nil,

		NavBar = (not isInGame and activeWindow == nil) and React.createElement(NavBar, {
			visible = true,
			onPlayClick = function()
				setActiveWindow("Play")
			end,
		}) or nil,

		Menus = activeWindow and React.createElement("ScreenGui", {
			DisplayOrder = 20,
			IgnoreGuiInset = true,
		}, {
			Scale = React.createElement("UIScale", {
				Scale = screenScale,
			}),
			Container = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Active = false,
			}, {
				Content = React.createElement(React.Fragment, nil, menuWindows),
			}),
		}) or nil,
	})
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local root = ReactRoblox.createRoot(playerGui)
root:render(React.createElement(App))

print("MountUI: All UI components mounted successfully")
