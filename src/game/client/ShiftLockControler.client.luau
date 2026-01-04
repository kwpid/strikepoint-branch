local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local isLocked = false
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

local function updateCharacter(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")
end

player.CharacterAdded:Connect(updateCharacter)

local function toggleShiftLock()
	isLocked = not isLocked

	if isLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

UserInputService.InputBegan:Connect(function(input, gpe)
	if gpe then
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftControl then
		toggleShiftLock()
	end
end)

RunService.RenderStepped:Connect(function()
	if isLocked and character and rootPart and humanoid and humanoid.Health > 0 then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		local lookVector = camera.CFrame.LookVector
		local targetRotation = math.atan2(-lookVector.X, -lookVector.Z)
		rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, targetRotation, 0)

		humanoid.AutoRotate = false
	elseif character and humanoid then
		if not isLocked then
			humanoid.AutoRotate = true
		end
	end
end)


print("Shift-Lock Controller (CTRL) initialized")
