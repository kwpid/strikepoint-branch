local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local Sidebar = {}

function Sidebar.Component(props)
	local setWindow = props.setWindow
	local currentWindow = props.currentWindow

	return React.createElement("ScreenGui", {
		Name = "Sidebar",
		ResetOnSpawn = false,
		DisplayOrder = 10,
	}, {
		InventoryButton = React.createElement("ImageButton", {
			Name = "InventoryButton",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 20, 0.5, 0),
			Size = UDim2.fromOffset(60, 60),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.6,
			Image = "rbxthumb://type=Asset&id=116644575251072&w=420&h=420",
			ImageColor3 = Color3.fromRGB(255, 255, 255),
			[React.Event.MouseButton1Click] = function()
				if currentWindow == "Inventory" then
					setWindow(nil)
				else
					setWindow("Inventory")
				end
			end,
		}, {
			React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
			React.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 2,
			}),
		}),
	})
end

return Sidebar
