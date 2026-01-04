local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local React = require(ReplicatedStorage.Packages.React)

local _player = Players.LocalPlayer
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
			baseSize = UDim2.fromOffset(250, 180) -- Slightly wider for Elo
			hoverSize = UDim2.fromOffset(265, 195)
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
			BackgroundTransparency = 0.2, -- More transparent for premium feel
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
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),

			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0.6, 0.6, 0.6)),
				}),
				Rotation = 90,
			}),

			TitleContainer = React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, cardProps.SmallCard and 50 or (cardProps.RectangleCard and 65 or 80)),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),

				Label = React.createElement("TextLabel", {
					Size = UDim2.new(1, -20, 0, cardProps.Elo and 30 or 50),
					Position = UDim2.fromOffset(15, 5),
					BackgroundTransparency = 1,
					Text = cardProps.Mode,
					Font = Enum.Font.GothamBlack,
					TextSize = cardProps.SmallCard and 18 or (cardProps.RectangleCard and 24 or 28),
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				EloLabel = cardProps.Elo and React.createElement("TextLabel", {
					Size = UDim2.new(1, -20, 0, 20),
					Position = UDim2.fromOffset(15, 35),
					BackgroundTransparency = 1,
					Text = tostring(cardProps.Elo or 0),
					Font = Enum.Font.GothamMedium,
					TextSize = 16,
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextXAlignment = Enum.TextXAlignment.Left,
				}) or nil,
			}),

			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = cardProps.Color,
				Transparency = 0.4,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),

			RankIcon = cardProps.RankIcon and React.createElement("ImageLabel", {
				Size = UDim2.fromOffset(70, 70),
				Position = UDim2.fromScale(0.85, 0.8),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = cardProps.RankIcon,
				ZIndex = 2,
			}) or nil,

			Icon = React.createElement("ImageLabel", {
				Size = UDim2.fromOffset(100, 100),
				Position = UDim2.fromScale(0.5, 0.45),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = cardProps.Icon or "rbxassetid://16164239850", -- Placeholder icon
				ImageTransparency = 0.8,
				Visible = true,
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
						setSelectedMode("Ranked")
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

	local function RankedSubmenu()
		return React.createElement(React.Fragment, nil, {
			Header = React.createElement("TextLabel", {
				Text = "COMPETITIVE",
				Font = Enum.Font.GothamBlack,
				TextSize = 80,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0.9,
				Size = UDim2.new(1, -100, 0, 120),
				Position = UDim2.fromOffset(50, 20),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			TopBar = React.createElement("Frame", {
				Size = UDim2.new(1, -60, 0, 100),
				Position = UDim2.fromOffset(30, 20),
				BackgroundTransparency = 1,
				ZIndex = 2,
			}, {
				SeasonInfo = React.createElement("Frame", {
					Size = UDim2.fromOffset(300, 40),
					Position = UDim2.fromOffset(20, 90),
					BackgroundTransparency = 1,
				}, {
					Subtitle = React.createElement("TextLabel", {
						Text = "SEASON 1 | 24D 10H LEFT",
						Font = Enum.Font.GothamBold,
						TextSize = 18,
						TextColor3 = Color3.fromRGB(52, 152, 219),
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
				}),

				Buttons = React.createElement("Frame", {
					Size = UDim2.new(0, 280, 0, 50),
					Position = UDim2.new(1, 0, 0, 10),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 10),
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						SortOrder = Enum.SortOrder.LayoutOrder, -- Added SortOrder
					}),

					Leaderboards = React.createElement("TextButton", {
						Size = UDim2.fromOffset(150, 50),
						BackgroundColor3 = Color3.fromRGB(60, 60, 60),
						Text = "LEADERBOARDS",
						Font = Enum.Font.GothamBold,
						TextSize = 14,
						TextColor3 = Color3.new(1, 1, 1),
						LayoutOrder = 1, -- First item (left)
						[React.Event.Activated] = function()
							setSelectedMode("Leaderboard")
						end,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
						Stroke = React.createElement(
							"UIStroke",
							{ Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.8 }
						),
					}),

					Back = React.createElement("TextButton", {
						Size = UDim2.fromOffset(100, 50),
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						Text = "BACK →",
						Font = Enum.Font.GothamBold,
						TextSize = 18,
						TextColor3 = Color3.new(1, 1, 1),
						LayoutOrder = 2, -- Second item (right)
						[React.Event.Activated] = function()
							setSelectedMode(nil)
						end,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					}),
				}),
			}),

			Content = React.createElement("Frame", {
				Size = UDim2.fromScale(0.9, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.55),
				BackgroundTransparency = 1,
			}, {
				Modes = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 250),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 30),
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),

					Mode1v1 = React.createElement(ModeCard, {
						Mode = "1v1",
						Elo = 882,
						RankIcon = "rbxassetid://16164239850", -- Placeholder
						Color = Color3.fromRGB(52, 152, 219),
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Ranked-1v1")
							end
						end,
					}),

					Mode2v2 = React.createElement(ModeCard, {
						Mode = "2v2",
						Elo = 1315,
						RankIcon = "rbxassetid://16164239850", -- Placeholder
						Color = Color3.fromRGB(155, 89, 182),
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Ranked-2v2")
							end
						end,
					}),

					Mode3v3 = React.createElement(ModeCard, {
						Mode = "3v3",
						Elo = 1141,
						RankIcon = "rbxassetid://16164239850", -- Placeholder
						Color = Color3.fromRGB(231, 76, 60),
						RectangleCard = true,
						OnClick = function()
							if props.onModeSelect then
								props.onModeSelect("Ranked-3v3")
							end
						end,
					}),
				}),

				RewardProgress = React.createElement("Frame", {
					Size = UDim2.new(0.6, 0, 0, 100),
					Position = UDim2.new(0.5, 0, 1, -20),
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
				}, {
					Icon = React.createElement("ImageLabel", {
						Size = UDim2.fromOffset(60, 60),
						Position = UDim2.new(0, 0, 0.5, 0),
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundTransparency = 1,
						Image = "rbxassetid://16164239850", -- Reward level icon
					}),
					Title = React.createElement("TextLabel", {
						Text = "BRONZE",
						Font = Enum.Font.GothamBlack,
						TextSize = 24,
						TextColor3 = Color3.fromRGB(205, 127, 50),
						Size = UDim2.new(0.4, 0, 0, 30),
						Position = UDim2.fromOffset(70, 15),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Subtitle = React.createElement("TextLabel", {
						Text = "SEASON REWARD LEVEL",
						Font = Enum.Font.GothamMedium,
						TextSize = 14,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						Size = UDim2.new(0.4, 0, 0, 20),
						Position = UDim2.fromOffset(70, 45),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Wins = React.createElement("TextLabel", {
						Text = "2 / 10 WINS",
						Font = Enum.Font.GothamBold,
						TextSize = 20,
						TextColor3 = Color3.new(1, 1, 1),
						Size = UDim2.new(0.4, 0, 0, 30),
						Position = UDim2.new(1, 0, 0, 15),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
					ProgressBarBg = React.createElement("Frame", {
						Size = UDim2.new(1, -70, 0, 12),
						Position = UDim2.fromOffset(70, 75),
						BackgroundColor3 = Color3.fromRGB(40, 40, 40),
						BorderSizePixel = 0,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Fill = React.createElement("Frame", {
							Size = UDim2.fromScale(0.2, 1),
							BackgroundColor3 = Color3.fromRGB(205, 127, 50),
							BorderSizePixel = 0,
						}, {
							Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
						}),
					}),
					AdvanceText = React.createElement("TextLabel", {
						Text = "AT SILVER RANK TO ADVANCE",
						Font = Enum.Font.GothamMedium,
						TextSize = 12,
						TextColor3 = Color3.fromRGB(150, 150, 150),
						Size = UDim2.new(1, -70, 0, 20),
						Position = UDim2.fromOffset(70, 90),
						BackgroundTransparency = 1,
						TextXAlignment = Enum.TextXAlignment.Right,
					}),
				}),
			}),
		})
	end

	local function LeaderboardSubmenu()
		local activeTab, setActiveTab = React.useState("1v1")

		local function Tab(tabProps)
			local isActive = activeTab == tabProps.Name
			return React.createElement("TextButton", {
				Size = UDim2.fromOffset(120, 40),
				BackgroundColor3 = isActive and Color3.fromRGB(52, 152, 219) or Color3.fromRGB(40, 40, 40),
				Text = tabProps.Name,
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextColor3 = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(150, 150, 150),
				[React.Event.Activated] = function()
					setActiveTab(tabProps.Name)
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Stroke = React.createElement("UIStroke", {
					Thickness = 2,
					Color = isActive and Color3.new(1, 1, 1) or Color3.fromRGB(60, 60, 60),
					Transparency = isActive and 0.5 or 0.8,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
			})
		end

		local function LeaderboardEntry(entryProps)
			return React.createElement("Frame", {
				Size = UDim2.new(1, -20, 0, 60),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BackgroundTransparency = 0.2,
				LayoutOrder = entryProps.Rank, -- Use Rank as LayoutOrder
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				Stroke = React.createElement("UIStroke", {
					Thickness = 1,
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.9,
				}),

				RankLabel = React.createElement("TextLabel", {
					Size = UDim2.fromOffset(50, 60),
					Position = UDim2.fromOffset(10, 0),
					BackgroundTransparency = 1,
					Text = "#" .. entryProps.Rank,
					Font = Enum.Font.GothamBlack,
					TextSize = 20,
					TextColor3 = entryProps.Rank <= 3 and Color3.fromRGB(241, 196, 15) or Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				Avatar = React.createElement("ImageLabel", {
					Size = UDim2.fromOffset(40, 40),
					Position = UDim2.fromOffset(70, 10),
					BackgroundTransparency = 1,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. entryProps.UserId .. "&w=48&h=48",
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				}),

				PlayerName = React.createElement("TextLabel", {
					Size = UDim2.new(0.5, -120, 1, 0),
					Position = UDim2.fromOffset(120, 0),
					BackgroundTransparency = 1,
					Text = entryProps.DisplayName or entryProps.Username,
					Font = Enum.Font.GothamBold,
					TextSize = 18,
					TextColor3 = Color3.new(1, 1, 1),
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				EloLabel = React.createElement("TextLabel", {
					Size = UDim2.new(0.3, 0, 1, 0),
					Position = UDim2.fromScale(1, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
					Text = tostring(entryProps.Elo) .. " ELO",
					Font = Enum.Font.GothamMedium,
					TextSize = 18,
					TextColor3 = Color3.fromRGB(52, 152, 219),
					TextXAlignment = Enum.TextXAlignment.Right,
				}),
			})
		end

		local entries = {}
		for i = 1, 100 do
			table.insert(
				entries,
				React.createElement(LeaderboardEntry, {
					Rank = i,
					UserId = 1,
					Username = "Player_" .. i,
					DisplayName = "Player " .. i,
					Elo = 2000 - (i * 10),
				})
			)
		end

		return React.createElement(React.Fragment, nil, {
			Header = React.createElement("TextLabel", {
				Text = "LEADERBOARDS",
				Font = Enum.Font.GothamBlack,
				TextSize = 80,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextTransparency = 0.9,
				Size = UDim2.new(1, -100, 0, 120),
				Position = UDim2.fromOffset(50, 20),
				BackgroundTransparency = 1,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			BackButton = React.createElement("TextButton", {
				Size = UDim2.fromOffset(120, 50),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -30, 0, 30),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Text = "BACK →",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				[React.Event.Activated] = function()
					setSelectedMode("Ranked")
				end,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),

			TabsBar = React.createElement("Frame", {
				Size = UDim2.new(0, 400, 0, 50),
				Position = UDim2.fromOffset(50, 120),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 10),
				}),
				Tab1v1 = React.createElement(Tab, { Name = "1v1" }),
				Tab2v2 = React.createElement(Tab, { Name = "2v2" }),
				Tab3v3 = React.createElement(Tab, { Name = "3v3" }),
			}),

			ListContainer = React.createElement("ScrollingFrame", {
				Size = UDim2.new(0.9, 0, 0.65, 0),
				Position = UDim2.fromScale(0.5, 0.58),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
				CanvasSize = UDim2.new(0, 0, 0, 65 * 100),
			}, {
				Layout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 5),
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				unpack(entries),
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
				Position = UDim2.fromScale(0.5, 0.45),
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
			Active = false,
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
				or selectedMode == "Ranked" and React.createElement(RankedSubmenu)
				or selectedMode == "Leaderboard" and React.createElement(LeaderboardSubmenu)
				or selectedMode == "Freeplay" and React.createElement(FreeplaySubmenu)
				or React.createElement(MainMenu),
		}),
	})
end

return PlayGUI
