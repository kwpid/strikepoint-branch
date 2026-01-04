local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local character = nil

local function onCharAdded(newChar)
	character = newChar
end
player.CharacterAdded:Connect(onCharAdded)
if player.Character then
	character = player.Character
end

local FADED_TRANSPARENCY = 0.8
local fadingParts = {}

function updateTransparency()
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end

	local ignoreList = { character }
	local obstructingParts = camera:GetPartsObscuringTarget({ head.Position }, ignoreList)

	local currentFrameObstructing = {}

	for _, part in ipairs(obstructingParts) do
		if part.Name == "Main" and part:IsA("BasePart") then
			currentFrameObstructing[part] = true

			if not fadingParts[part] then
				fadingParts[part] = part.Transparency
				part.Transparency = FADED_TRANSPARENCY
			end
		end
	end

	for part, originalTransparency in pairs(fadingParts) do
		if not currentFrameObstructing[part] then
			part.Transparency = originalTransparency
			fadingParts[part] = nil
		end
	end
end

RunService.RenderStepped:Connect(updateTransparency)

-- Goal Transparency Logic
local function checkGoals(folder)
	for _, gameFolder in ipairs(folder:GetChildren()) do
		local goals = gameFolder:FindFirstChild("Goals", true)
		if goals then
			for _, goal in ipairs(goals:GetChildren()) do
				for _, part in ipairs(goal:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end

				goal.DescendantAdded:Connect(function(part)
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end)
			end
		end
	end
end

local GamesFolder = workspace:FindFirstChild("Games")
if GamesFolder then
	checkGoals(GamesFolder)
	GamesFolder.ChildAdded:Connect(function(child)
		task.wait(0.1) -- wait for children to replicate
		local goals = child:FindFirstChild("Goals", true)
		if goals then
			for _, goal in ipairs(goals:GetChildren()) do
				for _, part in ipairs(goal:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end
				goal.DescendantAdded:Connect(function(part)
					if part:IsA("BasePart") then
						part.Transparency = 1
					end
				end)
			end
		end
	end)
else
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Games" then
			GamesFolder = child
			checkGoals(child)
			child.ChildAdded:Connect(function(gameFolder)
				task.wait(0.1)
				local goals = gameFolder:FindFirstChild("Goals", true)
				if goals then
					for _, goal in ipairs(goals:GetChildren()) do
						for _, part in ipairs(goal:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Transparency = 1
							end
						end
					end
				end
			end)
		end
	end)
end
