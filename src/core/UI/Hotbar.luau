local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

if RunService:IsServer() then
	return {}
end

local React = require(ReplicatedStorage.Packages.React)
-- local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

local Config = require(ReplicatedStorage.Game.BallConfig)
local AbilityManager = require(ReplicatedStorage.Core.AssetManager.Abilities.AbilityManager)

local Hotbar = {}

local PARRY_ICON = "rbxthumb://type=Asset&id=1173894779&w=420&h=420"
local DASH_ICON = "rbxthumb://type=Asset&id=119044613674072&w=420&h=420"

local function HotbarUI(props)
	local parryCooldown, setParryCooldown = React.useState(nil)
	local dashCooldown, setDashCooldown = React.useState(nil)

	local abilityImage, setAbilityImage = React.useState("rbxassetid://0")
	local isLocked, setIsLocked = React.useState(false)

	local parryRef = React.useRef(nil)
	local dashRef = React.useRef(nil)

	React.useEffect(function()
		local player = Players.LocalPlayer
		local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)

		local swingEvent = RemoteEventsFolder:WaitForChild("SwingEvent")
		local parryCooldownEvent = RemoteEventsFolder:FindFirstChild("ParryCooldownEvent")
		local dashCooldownEvent = RemoteEventsFolder:FindFirstChild("DashCooldownEvent")

		local parryConn
		if parryCooldownEvent then
			parryConn = parryCooldownEvent.OnClientEvent:Connect(function(duration)
				setParryCooldown({
					duration = duration,
					id = HttpService:GenerateGUID(false),
				})
			end)
		end

		local dashConn
		if dashCooldownEvent then
			dashConn = dashCooldownEvent.OnClientEvent:Connect(function(duration)
				setDashCooldown({
					duration = duration,
					id = HttpService:GenerateGUID(false),
				})
			end)
		end

		local function updateAbilityImage()
			local char = player.Character
			if not char then
				return
			end

			local abilityName = char:GetAttribute("EquippedAbility") or "Quad"
			local abilityData = AbilityManager.GetAbility(abilityName)

			if abilityData and abilityData.Config and abilityData.Config.ImageId then
				setAbilityImage(abilityData.Config.ImageId)
			end
		end

		local charConn
		local attrConn
		if player.Character then
			updateAbilityImage()
			attrConn = player.Character:GetAttributeChangedSignal("EquippedAbility"):Connect(updateAbilityImage)
		end

		charConn = player.CharacterAdded:Connect(function(char)
			if attrConn then
				attrConn:Disconnect()
			end
			task.wait(0.1)
			updateAbilityImage()
			attrConn = char:GetAttributeChangedSignal("EquippedAbility"):Connect(updateAbilityImage)
		end)

		local function updateLockedState()
			local char = player.Character
			if char then
				setIsLocked(char:GetAttribute("FeaturesLocked") or false)
			end
		end

		local lockedConn
		if player.Character then
			updateLockedState()
			lockedConn = player.Character:GetAttributeChangedSignal("FeaturesLocked"):Connect(updateLockedState)
		end

		local charLockedConn = player.CharacterAdded:Connect(function(char)
			if lockedConn then
				lockedConn:Disconnect()
			end
			task.wait(0.1)
			updateLockedState()
			lockedConn = char:GetAttributeChangedSignal("FeaturesLocked"):Connect(updateLockedState)
		end)

		return function()
			if parryConn then
				parryConn:Disconnect()
			end
			if dashConn then
				dashConn:Disconnect()
			end
			if charConn then
				charConn:Disconnect()
			end
			if attrConn then
				attrConn:Disconnect()
			end
			if lockedConn then
				lockedConn:Disconnect()
			end
			if charLockedConn then
				charLockedConn:Disconnect()
			end
		end
	end, {})

	React.useEffect(function()
		if parryCooldown and parryRef.current then
			local frame = parryRef.current
			frame.Size = UDim2.fromScale(1, 1)

			local tween = TweenService:Create(frame, TweenInfo.new(parryCooldown.duration, Enum.EasingStyle.Linear), {
				Size = UDim2.fromScale(1, 0),
			})
			tween:Play()
		end
	end, { parryCooldown })

	React.useEffect(function()
		if dashCooldown and dashRef.current then
			local frame = dashRef.current
			frame.Size = UDim2.fromScale(1, 1)

			local tween = TweenService:Create(frame, TweenInfo.new(dashCooldown.duration, Enum.EasingStyle.Linear), {
				Size = UDim2.fromScale(1, 0),
			})
			tween:Play()
		end
	end, { dashCooldown })

	local function onParry()
		-- local player = Players.LocalPlayer
		local camera = workspace.CurrentCamera
		local direction = camera.CFrame.LookVector
		local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)
		local swingEvent = RemoteEventsFolder:WaitForChild("SwingEvent")
		swingEvent:FireServer(direction)
	end

	local function onDash()
		local player = Players.LocalPlayer
		local char = player.Character
		if char then
			char:SetAttribute("DashTrigger", true)
		end
	end

	local function onAbility()
		--placeholder
	end

	local function getAssetUrl(id)
		if not id or id == "" or id == 0 then
			return ""
		end

		if type(id) == "number" then
			return "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
		elseif type(id) == "string" then
			if string.find(id, "rbxassetid://") or string.find(id, "rbxthumb://") then
				return id
			elseif string.match(id, "^%d+$") then
				return "rbxthumb://type=Asset&id=" .. id .. "&w=420&h=420"
			end
		end
		return id
	end

	return React.createElement("ScreenGui", {
		Name = "Hotbar",
		ResetOnSpawn = false,
		DisplayOrder = 1, -- Stay below NavBar
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		Container = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.3, 0.1), -- Responsive
			BackgroundTransparency = 1,
			Active = false,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(600, 100),
				MinSize = Vector2.new(200, 40),
			}),

			Layout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),

			LeaveFreeplay = React.createElement("TextButton", {
				Name = "LeaveFreeplay",
				LayoutOrder = 0,
				Size = UDim2.fromOffset(150, 35),
				Position = UDim2.new(0.5, 0, 0, -50),
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(192, 57, 43),
				Text = "LEAVE FREEPLAY",
				Font = Enum.Font.GothamBold,
				TextSize = 14,
				TextColor3 = Color3.new(1, 1, 1),
				Visible = (Players.LocalPlayer:GetAttribute("GameId") ~= nil and string.find(
					Players.LocalPlayer:GetAttribute("GameId"),
					"freeplay"
				) ~= nil),
				[React.Event.Activated] = function()
					local RemoteEventsFolder = ReplicatedStorage:FindFirstChild(Config.Paths.REMOTE_EVENTS_FOLDER)
					local leaveEvent = RemoteEventsFolder and RemoteEventsFolder:FindFirstChild("LeaveFreeplayEvent")
					if leaveEvent then
						leaveEvent:FireServer()
					end
				end,
			}, {
				React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				React.createElement("UIStroke", {
					Color = Color3.new(1, 1, 1),
					Thickness = 1,
					Transparency = 0.5,
				}),
			}),

			Parry = React.createElement("ImageButton", {
				Name = "Parry",
				LayoutOrder = 1,
				Size = UDim2.fromScale(0.3, 1), -- Fill Height, 1/3 Width (roughly)
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Image = PARRY_ICON,
				[React.Event.MouseButton1Click] = onParry,
			}, {
				React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
				}),
				React.createElement("UIAspectRatioConstraint", { AspectRatio = 1 }), -- Keep Square
				Progress = React.createElement("Frame", {
					ref = parryRef,
					Name = "progress",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromScale(1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
				}),
			}),

			Ability = React.createElement("ImageButton", {
				Name = "Ability",
				LayoutOrder = 2,
				Size = UDim2.fromScale(0.3, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Image = getAssetUrl(abilityImage),
				[React.Event.MouseButton1Click] = onAbility,
			}, {
				React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
				}),
				React.createElement("UIAspectRatioConstraint", { AspectRatio = 1 }), -- Keep Square
				Locked = isLocked and React.createElement("TextLabel", {
					Name = "locked",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 0, 0),
					TextScaled = true,
					Font = Enum.Font.GothamBold,
				}),
			}),

			Dash = React.createElement("ImageButton", {
				Name = "Dash",
				LayoutOrder = 3,
				Size = UDim2.fromScale(0.3, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Image = DASH_ICON,
				[React.Event.MouseButton1Click] = onDash,
			}, {
				React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				React.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
				}),
				React.createElement("UIAspectRatioConstraint", { AspectRatio = 1 }), -- Keep Square
				Progress = React.createElement("Frame", {
					ref = dashRef,
					Name = "progress",
					AnchorPoint = Vector2.new(0, 1),
					Position = UDim2.fromScale(0, 1),
					Size = UDim2.fromScale(1, 0),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.6,
					BorderSizePixel = 0,
				}),
				Locked = isLocked and React.createElement("TextLabel", {
					Name = "locked",
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "X",
					TextColor3 = Color3.fromRGB(255, 0, 0),
					TextScaled = true,
					Font = Enum.Font.GothamBold,
				}),
			}),
		}),
	})
end

Hotbar.Component = HotbarUI

return Hotbar
