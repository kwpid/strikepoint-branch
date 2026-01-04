local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local Config = require(ReplicatedStorage.Game.BallConfig)
local RemoteEventsFolder = ReplicatedStorage:WaitForChild(Config.Paths.REMOTE_EVENTS_FOLDER)
local AbilityManager = require(ReplicatedStorage.Core.AssetManager.Abilities.AbilityManager)
local doubleJumpEvent = RemoteEventsFolder:WaitForChild("DoubleJumpEvent")
local jumpEffectTemplate = ReplicatedStorage:WaitForChild("JumpEffect")

local character = nil
local humanoid = nil
local rootPart = nil
local attrConn = nil
local stateConn = nil

local jumpCount = 0
local maxJumps = 2
local lastJumpTime = 0
local TIME_BETWEEN_JUMPS = 0.2

local function updateAbilities()
	if not character then
		return
	end
	local abilityName = character:GetAttribute("EquippedAbility")
	if abilityName then
		local ability = AbilityManager.GetAbility(abilityName)
		if ability and ability.Config.MaxJumps then
			maxJumps = ability.Config.MaxJumps
		else
			maxJumps = 2
		end
	else
		maxJumps = 2
	end
	-- print("JumpClient: efficient jumps set to", maxJumps)
end

local function playDoubleJumpEffect(targetCFrame)
	if not jumpEffectTemplate then
		return
	end
	local effectPart = jumpEffectTemplate:Clone()
	effectPart.CFrame = targetCFrame * CFrame.new(0, -2.5, 0) * CFrame.Angles(0, 0, math.rad(90))
	effectPart.Transparency = 1
	effectPart.Parent = workspace

	-- fade in
	local fadeInInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local fadeInGoal = { Transparency = 0.5 }
	local fadeInTween = TweenService:Create(effectPart, fadeInInfo, fadeInGoal)

	-- fade out
	local fadeOutInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local fadeOutGoal = { Transparency = 1 }
	local fadeOutTween = TweenService:Create(effectPart, fadeOutInfo, fadeOutGoal)

	fadeInTween:Play()
	fadeInTween.Completed:Connect(function()
		fadeOutTween:Play()
	end)

	Debris:AddItem(effectPart, 1)
end

local function setupCharacter(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	rootPart = character:WaitForChild("HumanoidRootPart")

	if attrConn then
		attrConn:Disconnect()
	end
	if stateConn then
		stateConn:Disconnect()
	end

	attrConn = character:GetAttributeChangedSignal("EquippedAbility"):Connect(updateAbilities)
	updateAbilities()

	stateConn = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.Running then
			jumpCount = 0
		elseif newState == Enum.HumanoidStateType.Jumping then
			lastJumpTime = tick()
			jumpCount = jumpCount + 1
		end
	end)
end

player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

local function attemptDoubleJump()
	if not character or not humanoid or not rootPart then
		return
	end
	if character:GetAttribute("FeaturesLocked") then
		return
	end

	local state = humanoid:GetState()
	local isAirborne = (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping)

	if not isAirborne then
		return
	end
	if jumpCount >= maxJumps then
		return
	end

	if (tick() - lastJumpTime) < TIME_BETWEEN_JUMPS then
		return
	end

	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

	playDoubleJumpEffect(rootPart.CFrame)
	doubleJumpEvent:FireServer()
end

UserInputService.JumpRequest:Connect(function()
	attemptDoubleJump()
end)

doubleJumpEvent.OnClientEvent:Connect(function(otherPlayer)
	if otherPlayer ~= player then
		local otherChar = otherPlayer.Character
		if otherChar then
			local otherRoot = otherChar:FindFirstChild("HumanoidRootPart")
			if otherRoot then
				playDoubleJumpEffect(otherRoot.CFrame)
			end
		end
	end
end)
