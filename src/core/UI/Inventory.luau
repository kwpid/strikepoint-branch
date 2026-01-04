local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return {}
end

local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)

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

local ITEM_BG_IMAGE = "rbxthumb://type=Asset&id=107503485424120&w=420&h=420"

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

		-- Sorting Logic
		table.sort(filtered, function(a, b)
			local aEquipped = equippedItems[a.Name] or false
			local bEquipped = equippedItems[b.Name] or false

			-- Priority 1: Equipped
			if aEquipped ~= bEquipped then
				return aEquipped -- true comes first
			end

			-- Priority 2: Rarity
			local rankA = RARITY_RANK[a.Rarity] or 1
			local rankB = RARITY_RANK[b.Rarity] or 1
			if rankA ~= rankB then
				return rankA > rankB -- Highest rarity first
			end

			-- Priority 3: Name
			return a.Name < b.Name
		end)

		return filtered
	end, { inventory, currentTab, equippedItems }) -- Added equippedItems to dependency array

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

	return React.createElement("ScreenGui", {
		Name = "InventoryGUI",
		ResetOnSpawn = false,
	}, {
		MainFrame = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			BackgroundColor3 = Color3.fromRGB(10, 10, 10),
			BackgroundTransparency = 0.1,
		}, {
			React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
			React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 2,
			}),

			CloseButton = React.createElement("TextButton", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 10),
				Size = UDim2.fromOffset(30, 30),
				Text = "X",
				BackgroundColor3 = Color3.fromRGB(200, 50, 50),
				TextColor3 = Color3.new(1, 1, 1),
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				ZIndex = 10,
				[React.Event.MouseButton1Click] = function()
					if onClose then
						onClose()
					end
				end,
			}, {
				React.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
			}),

			Tabs = React.createElement("Frame", {
				Size = UDim2.new(1, -40, 0, 50),
				Position = UDim2.fromOffset(20, 10),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 5),
				}),

				SwordsTab = React.createElement("TextButton", {
					Size = UDim2.fromOffset(100, 40),
					Text = "Swords",
					BackgroundColor3 = currentTab == "Swords" and Color3.fromRGB(30, 30, 30)
						or Color3.fromRGB(15, 15, 15),
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					[React.Event.MouseButton1Click] = function()
						setCurrentTab("Swords")
						setSelectedItem(nil)
					end,
				}, {
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					currentTab == "Swords" and React.createElement("UIStroke", {
						Color = Color3.new(1, 1, 1),
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				AbilitiesTab = React.createElement("TextButton", {
					Size = UDim2.fromOffset(100, 40),
					Text = "Abilities",
					BackgroundColor3 = currentTab == "Abilities" and Color3.fromRGB(30, 30, 30)
						or Color3.fromRGB(15, 15, 15),
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					[React.Event.MouseButton1Click] = function()
						setCurrentTab("Abilities")
						setSelectedItem(nil)
					end,
				}, {
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					currentTab == "Abilities" and React.createElement("UIStroke", {
						Color = Color3.new(1, 1, 1),
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),

				GoalsTab = React.createElement("TextButton", {
					Size = UDim2.fromOffset(100, 40),
					Text = "Goals",
					BackgroundColor3 = currentTab == "Goals" and Color3.fromRGB(30, 30, 30)
						or Color3.fromRGB(15, 15, 15),
					TextColor3 = Color3.new(1, 1, 1),
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					[React.Event.MouseButton1Click] = function()
						setCurrentTab("Goals")
						setSelectedItem(nil)
					end,
				}, {
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
					currentTab == "Goals" and React.createElement("UIStroke", {
						Color = Color3.new(1, 1, 1),
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					}),
				}),
			}),

			-- content area
			Content = React.createElement("Frame", {
				Position = UDim2.fromOffset(20, 70),
				Size = UDim2.new(1, -40, 1, -90),
				BackgroundTransparency = 1,
			}, {
				Layout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 20),
				}),

				-- LEFT PANEL: items grid
				LeftPanel = React.createElement("ScrollingFrame", {
					Size = UDim2.new(0.6, 0, 1, 0),
					BackgroundTransparency = 1,
					ScrollBarThickness = 6,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(0, 0, 0, 0),
				}, {
					Padding = React.createElement("UIPadding", {
						PaddingTop = UDim.new(0, 10),
						PaddingBottom = UDim.new(0, 10),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
					}),
					GridLayout = React.createElement("UIGridLayout", {
						CellSize = UDim2.fromOffset(100, 100),
						CellPadding = UDim2.fromOffset(15, 15),
					}),

					React.createElement(
						React.Fragment,
						nil,
						(function()
							local elements = {}
							for i, item in ipairs(filteredItems) do
								local isEquipped = equippedItems[item.Name]
								local isSelected = selectedItem and selectedItem.Name == item.Name
								local rarityColor = RARITY_COLORS[item.Rarity] or RARITY_COLORS.Common

								elements[item.Name .. i] = React.createElement("ImageButton", {
									Name = item.Name,
									BackgroundColor3 = isSelected and Color3.fromRGB(80, 80, 80)
										or Color3.fromRGB(20, 20, 20),
									Image = ITEM_BG_IMAGE,
									[React.Event.MouseButton1Click] = function()
										setSelectedItem(item)
									end,
								}, {
									React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
									React.createElement("UIStroke", {
										Color = rarityColor, -- Use Rarity Color
										Thickness = isEquipped and 3 or 1,
									}),

									-- Item Icon sorted higher in ZIndex than button image
									Icon = React.createElement("ImageLabel", {
										Size = UDim2.fromScale(0.8, 0.8), -- Made slightly smaller to fit nicely in center
										AnchorPoint = Vector2.new(0.5, 0.5),
										Position = UDim2.fromScale(0.5, 0.5),
										BackgroundTransparency = 1,
										Image = getAssetUrl(item.ImageId),
										ZIndex = 2,
									}),

									NameLabel = React.createElement("TextLabel", {
										Size = UDim2.new(1, 0, 0, 20),
										Position = UDim2.fromScale(0, 1),
										AnchorPoint = Vector2.new(0, 1),
										BackgroundTransparency = 0.5,
										BackgroundColor3 = Color3.fromRGB(0, 0, 0),
										Text = item.Name,
										TextColor3 = Color3.new(1, 1, 1),
										TextSize = 12,
										Font = Enum.Font.Gotham,
										ZIndex = 3,
									}, { React.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) }),

									EquippedTag = isEquipped and React.createElement("ImageLabel", {
										Size = UDim2.fromOffset(20, 20),
										Position = UDim2.fromScale(1, 0),
										AnchorPoint = Vector2.new(1, 0),
										BackgroundTransparency = 1,
										Image = "rbxassetid://13778235213",
										ImageColor3 = Color3.fromRGB(100, 255, 100),
										ZIndex = 4,
									}),
								})
							end
							return elements
						end)()
					),
				}),

				-- RIGHT PANEL: item details
				RightPanel = React.createElement("Frame", {
					Size = UDim2.new(0.4, -20, 1, 0),
					BackgroundColor3 = Color3.fromRGB(20, 20, 20),
					BackgroundTransparency = 0.5,
				}, {
					React.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),

					Content = selectedItem and React.createElement(React.Fragment, nil, {
						Title = React.createElement("TextLabel", {
							Size = UDim2.new(1, -20, 0, 40),
							Position = UDim2.fromOffset(10, 10),
							BackgroundTransparency = 1,
							Text = selectedItem.Name,
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.GothamBold,
							TextSize = 24,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),

						ImagePreview = React.createElement("ImageLabel", {
							Size = UDim2.fromOffset(150, 150),
							Position = UDim2.new(0.5, 0, 0, 60),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							Image = getAssetUrl(selectedItem.ImageId),
						}),

						Desc = React.createElement("TextLabel", {
							Size = UDim2.new(1, -20, 0, 100),
							Position = UDim2.new(0.5, 0, 0, 220),
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundTransparency = 1,
							Text = selectedItem.Desc or "No description.",
							TextColor3 = Color3.fromRGB(200, 200, 200),
							Font = Enum.Font.Gotham,
							TextSize = 14,
							TextWrapped = true,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Top,
						}),

						EquipButton = React.createElement("TextButton", {
							Size = UDim2.new(1, -40, 0, 50),
							Position = UDim2.new(0.5, 0, 1, -20),
							AnchorPoint = Vector2.new(0.5, 1),
							BackgroundColor3 = equippedItems[selectedItem.Name] and Color3.fromRGB(100, 100, 100)
								or Color3.fromRGB(50, 200, 50),
							Text = equippedItems[selectedItem.Name] and "Equipped" or "Equip",
							TextColor3 = Color3.new(1, 1, 1),
							Font = Enum.Font.GothamBold,
							TextSize = 20,
							[React.Event.MouseButton1Click] = onEquip,
						}, { React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }) }),
					}) or React.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "Select an item to view details",
						TextColor3 = Color3.fromRGB(150, 150, 150),
						Font = Enum.Font.Gotham,
						TextSize = 18,
					}),
				}),
			}),
		}),
	})
end

Inventory.Component = InventoryUI

return Inventory
