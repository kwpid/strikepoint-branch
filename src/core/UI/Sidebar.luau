local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local Sidebar = {}

local function SidebarButton(props)
	local isHovered, setIsHovered = React.useState(false)

	return React.createElement("ImageButton", {
		Name = props.Name,
		Size = UDim2.fromScale(1, 1), -- Fill Grid Cell
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.6,
		Image = props.Image,
		ImageColor3 = Color3.fromRGB(255, 255, 255),
		Rotation = isHovered and props.HoverRotation or 0,
		[React.Event.MouseEnter] = function()
			setIsHovered(true)
		end,
		[React.Event.MouseLeave] = function()
			setIsHovered(false)
		end,
		[React.Event.MouseButton1Click] = props.OnClick,
	}, {
		React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
		React.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 2,
		}),
		React.createElement("UIScale", {
			Scale = isHovered and 1.1 or 1,
		}),
		React.createElement("UIAspectRatioConstraint", {
			AspectRatio = 1,
		}),
	})
end

function Sidebar.Component(props)
	local setWindow = props.setWindow
	local currentWindow = props.currentWindow

	local showInventory = currentWindow == nil
	local showSettings = currentWindow == nil

	return React.createElement("ScreenGui", {
		Name = "Sidebar",
		ResetOnSpawn = false,
		DisplayOrder = 100,
	}, {
		Container = React.createElement("Frame", {
			Size = UDim2.fromScale(0.08, 0.2), -- Responsive
			Position = UDim2.new(0.02, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundTransparency = 1,
			Active = false,
		}, {
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(150, 300),
				MinSize = Vector2.new(60, 100),
			}),
			Layout = React.createElement("UIGridLayout", {
				CellSize = UDim2.fromOffset(60, 60), -- Fixed sizing for buttons is ok with scale management
				CellPadding = UDim2.fromOffset(10, 10),
				FillDirection = Enum.FillDirection.Horizontal,
				StartCorner = Enum.StartCorner.TopLeft,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),

			-- Inventory Button slot
			InventoryButton = showInventory and React.createElement(SidebarButton, {
				Name = "InventoryButton",
				Image = "rbxthumb://type=Asset&id=116644575251072&w=420&h=420",
				HoverRotation = -5,
				LayoutOrder = 1,
				OnClick = function()
					if currentWindow == "Inventory" then
						setWindow(nil)
					else
						setWindow("Inventory")
					end
				end,
			}) or React.createElement("Frame", {
				LayoutOrder = 1,
				BackgroundTransparency = 1,
			}),

			SettingsButton = showSettings and React.createElement(SidebarButton, {
				Name = "SettingsButton",
				Image = "rbxthumb://type=Asset&id=98516868574997&w=420&h=420",
				HoverRotation = 5,
				LayoutOrder = 2,
				OnClick = function()
					if currentWindow == "Settings" then
						setWindow(nil)
					else
						setWindow("Settings")
					end
				end,
			}) or React.createElement("Frame", {
				LayoutOrder = 2,
				BackgroundTransparency = 1,
			}),
		}),
	})
end

return Sidebar
