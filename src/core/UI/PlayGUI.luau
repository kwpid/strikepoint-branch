local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local MapManager = require(ReplicatedStorage.Core.MatchHandler.MapManager)

local function PlayGUI(props)
	if not props.visible then
		return nil
	end

	local selectedMode, setSelectedMode = React.useState(nil)

	local function ModeCard(cardProps)
		local isHovered, setIsHovered = React.useState(false)
		local buttonRef = React.useRef(nil)

		local baseSize, hoverSize
		if cardProps.RectangleCard then
			baseSize = UDim2.fromOffset(220, 180)
			hoverSize = UDim2.fromOffset(235, 195)
		elseif cardProps.SmallCard then
			baseSize = UDim2.fromOffset(180, 135)
			hoverSize = UDim2.fromOffset(190, 145)
		else
			baseSize = UDim2.fromOffset(260, 360)
			hoverSize = UDim2.fromOffset(280, 380)
		end

		React.useEffect(function()
			if not buttonRef.current then
				return
			end

			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

			if isHovered then
				local scaleTween = TweenService:Create(buttonRef.current, tweenInfo, {
					Size = hoverSize,
					Rotation = 3,
				})
				scaleTween:Play()
			else
				local scaleTween = TweenService:Create(buttonRef.current, tweenInfo, {
					Size = baseSize,
					Rotation = 0,
				})
				scaleTween:Play()
			end
		end, { isHovered })

		return React.createElement("ImageButton", {
			Size = baseSize,
			BackgroundColor3 = cardProps.Color,
			BackgroundTransparency = 0,
			LayoutOrder = cardProps.Order,
			AutoButtonColor = false,
			BorderSizePixel = 0,
			ref = buttonRef,
			[React.Event.MouseEnter] = function()
				setIsHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setIsHovered(false)
			end,
			[React.Event.Activated] = cardProps.OnClick,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),

			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.6, 0.6)),
				}),
				Rotation = 90,
			}),

			TitleContainer = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, cardProps.SmallCard and 50 or (cardProps.RectangleCard and 60 or 80)),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),

				Label = React.createElement("TextLabel", {
					Size = UDim2.new(1, -20, 1, 0),
					Position = UDim2.fromOffset(15, 0),
					BackgroundTransparency = 1,
					Text = string.upper(cardProps.Mode),
					Font = Enum.Font.GothamBlack,
					TextSize = cardProps.SmallCard and 18 or (cardProps.RectangleCard and 22 or 28),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
			}),

			Stroke = React.createElement("UIStroke", {
				Thickness = 3,
				Color = cardProps.Color,
				Transparency = 0.4,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),

			Icon = React.createElement("ImageLabel", {
				Size = UDim2.fromOffset(100, 100),
				Position = UDim2.fromScale(0.5, 0.4),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = cardProps.Icon or "",
				Visible = cardProps.Icon ~= nil,
			}),
		})
	end

	local function MainMenu()
		return React.createElement(React.Fragment, nil, {
			Header = React.createElement("TextLabel", {
				Text = "PLAY",
				Font = Enum.Font.GothamBlack,
				TextSize = 80,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0.9,
				Size = UDim2.new(1, -100, 0, 120),
				Position = UDim2.fromOffset(50, 20),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Content = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 0.6),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.55),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 30),
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),

				Casual = React.createElement(ModeCard, {
					Mode = "Casual",
					Color = Color3.fromRGB(52, 152, 219),
					Order = 1,
					OnClick = function()
						setSelectedMode("Casual")
					end,
				}),

				Ranked = React.createElement(ModeCard, {
					Mode = "Ranked",
					Color = Color3.fromRGB(241, 196, 15),
					Order = 2,
					OnClick = function()
						if props.onModeSelect then
							props.onModeSelect("Ranked")
						end
					end,
				}),

				Freeplay = React.createElement(ModeCard, {
					Mode = "Freeplay",
					Color = Color3.fromRGB(155, 89, 182),
					Order = 3,
					OnClick = function()
						setSelectedMode("Freeplay")
					end,
				}),
			}),
		})
	end

	local function CasualSubmenu()
		return React.createElement(React.Fragment, nil, {
			BackButton = React.createElement("TextButton", {
				Size = UDim2.fromOffset(120, 50),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -30, 0, 30),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Text = "BACK →",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = true,
				[React.Event.Activated] = function()
					setSelectedMode(nil)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),

			Header = React.createElement("TextLabel", {
				Text = "CASUAL",
				Font = Enum.Font.GothamBlack,
				TextSize = 80,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0.9,
				Size = UDim2.new(1, -100, 0, 120),
				Position = UDim2.fromOffset(50, 20),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			ELOLabel = React.createElement("TextLabel", {
				Text = "ELO: 600",
				Font = Enum.Font.GothamBold,
				TextSize = 24,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Size = UDim2.fromOffset(200, 40),
				Position = UDim2.fromOffset(50, 110),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Content = React.createElement("Frame", {
				Size = UDim2.fromScale(0.9, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.55),
				BackgroundTransparency = 1,
			}, {
				MainModes = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 380),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 30),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Mode1v1 = React.createElement(ModeCard, {
						Mode = "1v1",
						Color = Color3.fromRGB(52, 152, 219),
						Order = 1,
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-1v1")
							end
						end,
					}),

					Mode2v2 = React.createElement(ModeCard, {
						Mode = "2v2",
						Color = Color3.fromRGB(46, 204, 113),
						Order = 2,
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-2v2")
							end
						end,
					}),

					Mode3v3 = React.createElement(ModeCard, {
						Mode = "3v3",
						Color = Color3.fromRGB(231, 76, 60),
						Order = 3,
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-3v3")
							end
						end,
					}),
				}),

				ExtraModes = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 140),
					Position = UDim2.fromOffset(0, 210),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 20),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),

					Heatseeker = React.createElement(ModeCard, {
						Mode = "Heatseeker",
						Color = Color3.fromRGB(230, 126, 34),
						Order = 1,
						SmallCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-Heatseeker")
							end
						end,
					}),

					RandomAbility = React.createElement(ModeCard, {
						Mode = "Random Ability",
						Color = Color3.fromRGB(155, 89, 182),
						Order = 2,
						SmallCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-RandomAbility")
							end
						end,
					}),

					Hoops = React.createElement(ModeCard, {
						Mode = "Hoops",
						Color = Color3.fromRGB(52, 73, 94),
						Order = 3,
						SmallCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Casual-Hoops")
							end
						end,
					}),
				}),
			}),
		})
	end

	local function FreeplaySubmenu()
		local availableMaps = MapManager.Get1v1Maps()
		local selectedMapIndex, setSelectedMapIndex = React.useState(1)

		if #availableMaps == 0 then
			return React.createElement("TextLabel", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "No maps available",
				Font = Enum.Font.GothamBold,
				TextSize = 32,
				TextColor3 = Color3.fromRGB(255, 255, 255),
			})
		end

		local currentMap = availableMaps[selectedMapIndex]
		local mapImage = MapManager.GetMapImage(currentMap)

		return React.createElement(React.Fragment, nil, {
			BackButton = React.createElement("TextButton", {
				Size = UDim2.fromOffset(120, 50),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -30, 0, 30),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Text = "BACK →",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = true,
				[React.Event.Activated] = function()
					setSelectedMode(nil)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),

			Header = React.createElement("TextLabel", {
				Text = "FREEPLAY",
				Font = Enum.Font.GothamBlack,
				TextSize = 80,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0.9,
				Size = UDim2.new(1, -100, 0, 120),
				Position = UDim2.fromOffset(50, 20),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Content = React.createElement("Frame", {
				Size = UDim2.fromScale(0.6, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.55),
				BackgroundTransparency = 1,
			}, {
				MapName = React.createElement("TextLabel", {
					Text = currentMap,
					Font = Enum.Font.GothamBold,
					TextSize = 36,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(1, 0, 0, 50),
					Position = UDim2.fromOffset(0, 0),
					BackgroundTransparency = 1,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),

				MapImageContainer = React.createElement("Frame", {
					Size = UDim2.fromOffset(400, 300),
					Position = UDim2.new(0.5, 0, 0, 70),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderSizePixel = 0,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),

					MapImage = React.createElement("ImageLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Image = mapImage,
						ScaleType = Enum.ScaleType.Fit,
					}),

					LeftArrow = React.createElement("TextButton", {
						Size = UDim2.fromOffset(60, 60),
						Position = UDim2.new(0, -80, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(50, 50, 50),
						Text = "◀",
						Font = Enum.Font.GothamBold,
						TextSize = 32,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						AutoButtonColor = true,
						[React.Event.Activated] = function()
							local newIndex = selectedMapIndex - 1
							if newIndex < 1 then
								newIndex = #availableMaps
							end
							setSelectedMapIndex(newIndex)
						end,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					}),

					RightArrow = React.createElement("TextButton", {
						Size = UDim2.fromOffset(60, 60),
						Position = UDim2.new(1, 80, 0.5, 0),
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(50, 50, 50),
						Text = "▶",
						Font = Enum.Font.GothamBold,
						TextSize = 32,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						AutoButtonColor = true,
						[React.Event.Activated] = function()
							local newIndex = selectedMapIndex + 1
							if newIndex > #availableMaps then
								newIndex = 1
							end
							setSelectedMapIndex(newIndex)
						end,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					}),
				}),

				AcceptButton = React.createElement("TextButton", {
					Size = UDim2.fromOffset(200, 60),
					Position = UDim2.new(0.5, 0, 0, 420),
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(46, 204, 113),
					Text = "ACCEPT",
					Font = Enum.Font.GothamBlack,
					TextSize = 28,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					AutoButtonColor = true,
					[React.Event.Activated] = function()
						print("PlayGUI: ACCEPT button clicked, current map:", currentMap)
						local remoteEvents = ReplicatedStorage:FindFirstChild("Ball_Events")
						if not remoteEvents then
							warn("PlayGUI: RemoteEvents folder NOT found!")
							return
						end
						local enterFreeplayEvent = remoteEvents:FindFirstChild("EnterFreeplayEvent")
						if not enterFreeplayEvent then
							warn("PlayGUI: EnterFreeplayEvent NOT found in RemoteEvents!")
							return
						end
						print("PlayGUI: Firing EnterFreeplayEvent...")
						enterFreeplayEvent:FireServer(currentMap)
					end,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),
			}),
		})
	end

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
	}, {
		Container = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
		}, {
			Overlay = React.createElement("TextButton", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 0,
				[React.Event.Activated] = props.onClose,
			}),

			Content = selectedMode == "Casual" and React.createElement(CasualSubmenu)
				or selectedMode == "Freeplay" and React.createElement(FreeplaySubmenu)
				or React.createElement(MainMenu),
		}),
	})
end

return PlayGUI
