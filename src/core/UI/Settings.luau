local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function Settings(props)
	if not props.visible then
		return nil
	end

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = 10,
	}, {
		Container = React.createElement("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
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

			Content = React.createElement("Frame", {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Active = false,
			}, {
				Header = React.createElement("TextLabel", {
					Text = "SETTINGS",
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
					[React.Event.Activated] = props.onClose,
				}, {
					Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),
				}),

				MainArea = React.createElement("Frame", {
					Size = UDim2.fromScale(0.8, 0.7),
					Position = UDim2.fromScale(0.5, 0.55),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
				}, {
					PlaceholderText = React.createElement("TextLabel", {
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = "SETTINGS COMING SOON",
						Font = Enum.Font.GothamBold,
						TextSize = 32,
						TextColor3 = Color3.fromRGB(100, 100, 100),
					}),
				}),
			}),
		}),
	})
end

return Settings
