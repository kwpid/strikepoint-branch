local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)

local function NavBar(props)
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
		}, {
			PlayButton = React.createElement("ImageButton", {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -110),
				Size = UDim2.fromOffset(200, 60),
				BackgroundColor3 = Color3.fromRGB(15, 110, 55),
				BackgroundTransparency = 0,
				BorderSizePixel = 0,
				AutoButtonColor = true,
				[React.Event.Activated] = props.onPlayClick,
			}, {
				Corner = React.createElement("UICorner", { CornerRadius = UDim.new(0, 8) }),

				Gradient = React.createElement("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(39, 174, 96)),
					}),
					Rotation = 90,
				}),

				Label = React.createElement("TextLabel", {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Text = "PLAY",
					Font = Enum.Font.GothamBlack,
					TextSize = 36,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextStrokeTransparency = 0.8,
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				}),

				Stroke = React.createElement("UIStroke", {
					Thickness = 2,
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),

				Glow = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1.4, 1.8),
					BackgroundTransparency = 1,
					Image = "rbxassetid://16164239850",
					ImageColor3 = Color3.fromRGB(46, 204, 113),
					ImageTransparency = 0.6,
					ZIndex = 0,
				}),
			}),
		}),
	})
end

return NavBar
