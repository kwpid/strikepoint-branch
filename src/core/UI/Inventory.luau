local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return {}
end

local React = require(ReplicatedStorage.Packages.React)

local SwordManager = require(ReplicatedStorage.Core.AssetManager.Swords.SwordManager)
local AbilityManager = require(ReplicatedStorage.Core.AssetManager.Abilities.AbilityManager)
local GoalManager = require(ReplicatedStorage.Core.AssetManager.Goals.GoalManager)

local RARITY_COLORS = {
	Common = Color3.fromRGB(255, 255, 255),
	Uncommon = Color3.fromRGB(100, 255, 100),
	Rare = Color3.fromRGB(80, 150, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
}

local RARITY_RANK = {
	Common = 1,
	Uncommon = 2,
	Rare = 3,
	Epic = 4,
	Legendary = 5,
}

local Inventory = {}

local function InventoryUI(props)
	local visible = props.visible
	local onClose = props.onClose

	local currentTab, setCurrentTab = React.useState("Swords")
	local inventory, setInventory = React.useState({})
	local equippedItems, setEquippedItems = React.useState({})
	local selectedItem, setSelectedItem = React.useState(nil)

	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents", 10)
	local equipItemEvent = remoteEvents and remoteEvents:WaitForChild("EquipItemEvent", 10)

	React.useEffect(function()
		if not visible then
			return
		end

		if not remoteEvents then
			return
		end

		local getInventoryFunc = remoteEvents:WaitForChild("GetInventoryFunction", 10)
		local getEquippedFunc = remoteEvents:WaitForChild("GetEquippedItemsFunction", 10)
		local inventoryUpdatedEvent = remoteEvents:WaitForChild("InventoryUpdatedEvent", 10)

		local function refreshInventory()
			local success, invData = pcall(function()
				return getInventoryFunc:InvokeServer()
			end)
			if success and invData then
				setInventory(invData)
			end

			local successEq, eqData = pcall(function()
				return getEquippedFunc:InvokeServer()
			end)
			if successEq and eqData then
				local equipped = {}
				for _, name in ipairs(eqData) do
					equipped[name] = true
				end
				setEquippedItems(equipped)
			end
		end

		refreshInventory()

		local conn = inventoryUpdatedEvent.OnClientEvent:Connect(refreshInventory)

		return function()
			conn:Disconnect()
		end
	end, { visible })

	local filteredItems = React.useMemo(function()
		local filtered = {}
		for _, item in ipairs(inventory) do
			local itemType = item.Type or "Sword"
			if
				(currentTab == "Swords" and itemType == "Sword")
				or (currentTab == "Abilities" and itemType == "Ability")
				or (currentTab == "Goals" and itemType == "Goal")
			then
				local enrichedItem = table.clone(item)
				local details
				if itemType == "Sword" then
					details = SwordManager.GetSword(item.Name)
				elseif itemType == "Ability" then
					details = AbilityManager.GetAbility(item.Name)
				elseif itemType == "Goal" then
					details = GoalManager.GetGoal(item.Name)
				end

				if details then
					enrichedItem.ImageId = details.ImageId or (details.Config and details.Config.ImageId)
					enrichedItem.Desc = details.Desc or (details.Config and details.Config.Desc) or "No description."
					enrichedItem.Rarity = details.Rarity or (details.Config and details.Config.Rarity) or "Common"
				else
					enrichedItem.Desc = "Item details not found."
					enrichedItem.Rarity = "Common"
				end

				table.insert(filtered, enrichedItem)
			end
		end

		table.sort(filtered, function(a, b)
			local aEquipped = equippedItems[a.Name] or false
			local bEquipped = equippedItems[b.Name] or false

			if aEquipped ~= bEquipped then
				return aEquipped
			end

			local rankA = RARITY_RANK[a.Rarity] or 1
			local rankB = RARITY_RANK[b.Rarity] or 1
			if rankA ~= rankB then
				return rankA > rankB
			end

			return a.Name < b.Name
		end)

		return filtered
	end, { inventory, currentTab, equippedItems })

	if not visible then
		return nil
	end

	local function onEquip()
		if selectedItem and equipItemEvent then
			equipItemEvent:FireServer(selectedItem.Name)
		end
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

	local function TabButton(tabProps)
		local isHovered, setIsHovered = React.useState(false)
		local isSelected = currentTab == tabProps.Name

		return React.createElement("TextButton", {
			Size = UDim2.fromOffset(150, 40),
			BackgroundColor3 = isSelected and Color3.fromRGB(80, 80, 80) or Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = isSelected and 0 or 0.3,
			Text = string.upper(tabProps.Name),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			AutoButtonColor = false,
			[React.Event.MouseEnter] = function()
				setIsHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setIsHovered(false)
			end,
			[React.Event.Activated] = tabProps.OnClick,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
			Stroke = React.createElement("UIStroke", {
				Thickness = 2,
				Color = isSelected and Color3.new(1, 1, 1) or Color3.new(0.4, 0.4, 0.4),
				Transparency = (isSelected or isHovered) and 0 or 0.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
		})
	end

	local function ItemCard(cardProps)
		local isHovered, setIsHovered = React.useState(false)
		local isSelected = selectedItem and selectedItem.Name == cardProps.Item.Name
		local isEquipped = equippedItems[cardProps.Item.Name]
		local rarityColor = RARITY_COLORS[cardProps.Item.Rarity] or RARITY_COLORS.Common

		return React.createElement("ImageButton", {
			Size = UDim2.fromOffset(120, 120),
			BackgroundColor3 = isSelected and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			[React.Event.MouseEnter] = function()
				setIsHovered(true)
			end,
			[React.Event.MouseLeave] = function()
				setIsHovered(false)
			end,
			[React.Event.Activated] = function()
				setSelectedItem(cardProps.Item)
			end,
		}, {
			Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),

			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
					ColorSequenceKeypoint.new(1, Color3.new(0.7, 0.7, 0.7)),
				}),
				Rotation = 90,
			}),

			Stroke = React.createElement("UIStroke", {
				Thickness = isSelected and 3 or 2,
				Color = rarityColor,
				Transparency = (isSelected or isHovered) and 0 or 0.3,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),

			Icon = React.createElement("ImageLabel", {
				Size = UDim2.fromScale(0.7, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.45),
				BackgroundTransparency = 1,
				Image = getAssetUrl(cardProps.Item.ImageId),
			}),

			NameLabel = React.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 25),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 0.4,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Text = cardProps.Item.Name,
				Font = Enum.Font.GothamBold,
				TextSize = 12,
				TextColor3 = Color3.new(1, 1, 1),
				ZIndex = 2,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
			}),

			EquippedTag = isEquipped and React.createElement("Frame", {
				Size = UDim2.fromOffset(20, 20),
				Position = UDim2.new(1, -5, 0, 5),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(46, 204, 113),
				ZIndex = 3,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Check = React.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "\226\156\147",
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 14,
					Font = Enum.Font.GothamBlack,
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
			Active = false,
		}, {
			Overlay = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.4,
			}),

			BackButton = React.createElement("TextButton", {
				Size = UDim2.fromOffset(120, 50),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -30, 0, 30),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				Text = "BACK \226\134\146",
				Font = Enum.Font.GothamBold,
				TextSize = 20,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				AutoButtonColor = true,
				[React.Event.Activated] = onClose,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			}),

			Header = React.createElement("TextLabel", {
				Text = "INVENTORY",
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
				Size = UDim2.fromScale(0.85, 0.7),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
			}, {
				TabsContainer = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 50),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 15),
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
					}),

					SwordsTab = React.createElement(TabButton, {
						Name = "Swords",
						OnClick = function()
							setCurrentTab("Swords")
							setSelectedItem(nil)
						end,
					}),
					AbilitiesTab = React.createElement(TabButton, {
						Name = "Abilities",
						OnClick = function()
							setCurrentTab("Abilities")
							setSelectedItem(nil)
						end,
					}),
					GoalsTab = React.createElement(TabButton, {
						Name = "Goals",
						OnClick = function()
							setCurrentTab("Goals")
							setSelectedItem(nil)
						end,
					}),
				}),

				HorizontalSplit = React.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, -70),
					Position = UDim2.fromOffset(0, 70),
					BackgroundTransparency = 1,
				}, {
					Layout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 30),
					}),

					ItemsSection = React.createElement("Frame", {
						Size = UDim2.new(0.65, -15, 1, 0),
						BackgroundColor3 = Color3.fromRGB(15, 15, 15),
						BackgroundTransparency = 0.4,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Stroke = React.createElement(
							"UIStroke",
							{ Thickness = 1, Color = Color3.new(1, 1, 1), Transparency = 0.9 }
						),

						ItemsList = React.createElement("ScrollingFrame", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							ScrollBarThickness = 4,
							CanvasSize = UDim2.fromScale(0, 0),
							AutomaticCanvasSize = Enum.AutomaticSize.Y,
							ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
						}, {
							GridLayout = React.createElement("UIGridLayout", {
								CellSize = UDim2.fromOffset(120, 120),
								CellPadding = UDim2.fromOffset(20, 20),
							}),
							Padding = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 20),
								PaddingTop = UDim.new(0, 20),
								PaddingRight = UDim.new(0, 20),
								PaddingBottom = UDim.new(0, 20),
							}),

							Items = React.createElement(
								React.Fragment,
								nil,
								(function()
									local items = {}
									for i, item in ipairs(filteredItems) do
										items["Item_" .. i] = React.createElement(ItemCard, { Item = item })
									end
									return items
								end)()
							),
						}),
					}),

					DetailsPanel = React.createElement("Frame", {
						Size = UDim2.new(0.35, -15, 1, 0),
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						BackgroundTransparency = 0.2,
					}, {
						Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Stroke = React.createElement(
							"UIStroke",
							{ Thickness = 2, Color = Color3.new(1, 1, 1), Transparency = 0.8 }
						),

						Inner = selectedItem and React.createElement(React.Fragment, nil, {
							Padding = React.createElement("UIPadding", {
								PaddingTop = UDim.new(0, 20),
								PaddingBottom = UDim.new(0, 20),
								PaddingLeft = UDim.new(0, 20),
								PaddingRight = UDim.new(0, 20),
							}),

							Title = React.createElement("TextLabel", {
								Size = UDim2.new(1, 0, 0, 30),
								BackgroundTransparency = 1,
								Text = selectedItem.Name,
								Font = Enum.Font.GothamBlack,
								TextSize = 24,
								TextColor3 = Color3.new(1, 1, 1),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							Rarity = React.createElement("TextLabel", {
								Size = UDim2.new(1, 0, 0, 20),
								Position = UDim2.fromOffset(0, 35),
								BackgroundTransparency = 1,
								Text = string.upper(selectedItem.Rarity or "Common"),
								Font = Enum.Font.GothamBold,
								TextSize = 14,
								TextColor3 = RARITY_COLORS[selectedItem.Rarity] or Color3.new(1, 1, 1),
								TextXAlignment = Enum.TextXAlignment.Left,
							}),

							Preview = React.createElement("ImageLabel", {
								Size = UDim2.fromScale(0.8, 0.4),
								Position = UDim2.fromScale(0.5, 0.45),
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundTransparency = 1,
								Image = getAssetUrl(selectedItem.ImageId),
								ScaleType = Enum.ScaleType.Fit,
							}),

							Desc = React.createElement("TextLabel", {
								Size = UDim2.new(1, 0, 0, 60),
								Position = UDim2.fromScale(0, 0.7),
								BackgroundTransparency = 1,
								Text = selectedItem.Desc or "No description.",
								Font = Enum.Font.Gotham,
								TextSize = 14,
								TextColor3 = Color3.fromRGB(200, 200, 200),
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Top,
							}),

							EquipButton = React.createElement("TextButton", {
								Size = UDim2.new(1, 0, 0, 50),
								AnchorPoint = Vector2.new(0.5, 1),
								Position = UDim2.fromScale(0.5, 1),
								BackgroundColor3 = equippedItems[selectedItem.Name] and Color3.fromRGB(100, 100, 100)
									or Color3.fromRGB(46, 204, 113),
								Text = equippedItems[selectedItem.Name] and "EQUIPPED" or "EQUIP",
								Font = Enum.Font.GothamBlack,
								TextSize = 20,
								TextColor3 = Color3.new(1, 1, 1),
								[React.Event.Activated] = onEquip,
							}, {
								Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
								Gradient = not equippedItems[selectedItem.Name]
										and React.createElement("UIGradient", {
											Color = ColorSequence.new({
												ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
												ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 174, 96)),
											}),
											Rotation = 90,
										})
									or nil,
							}),
						}) or React.createElement("TextLabel", {
							Size = UDim2.fromScale(1, 1),
							BackgroundTransparency = 1,
							Text = "SELECT AN ITEM",
							Font = Enum.Font.GothamBold,
							TextSize = 18,
							TextColor3 = Color3.fromRGB(150, 150, 150),
						}),
					}),
				}),
			}),
		}),
	})
end

Inventory.Component = InventoryUI

return Inventory
