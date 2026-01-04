local BallPhysics = {}
local Config = require(script.Parent.BallConfig)

function BallPhysics.new(initialPosition)
	local self = {
		position = initialPosition or Vector3.new(0, 10, 0),
		velocity = Vector3.new(0, 0, 0),
		isMoving = false,
		hitCount = 0,
		lastHitter = "None",
		bounceCount = 0,
		color = Color3.new(1, 1, 1),
		transparency = 0,
	}

	setmetatable(self, { __index = BallPhysics })
	return self
end

function BallPhysics:applyHit(direction, customSpeed, hitterName)
	self.hitCount = self.hitCount + 1
	if hitterName then
		self.lastHitter = hitterName
	end

	self.bounceCount = 0

	local speed
	if customSpeed then
		speed = customSpeed
	else
		if self.hitCount == 1 then
			speed = Config.Physics.START_SPEED
		else
			speed = Config.Physics.START_SPEED + (self.hitCount - 1) * Config.Physics.SPEED_INCREMENT
		end
	end

	speed = math.min(speed, Config.Physics.MAX_SPEED)

	if not direction or direction.Magnitude < 0.001 then
		self.velocity = Vector3.zero
		return 0
	end

	self.velocity = direction.Unit * speed

	-- NaN Safety
	if self.velocity.X ~= self.velocity.X then
		self.velocity = Vector3.zero
	end

	self.isMoving = true

	return speed
end

function BallPhysics:update(dt, raycastFunc, groundHeight, radius, onCollision)
	local remainingDt = dt
	local safetyLoop = 0

	while remainingDt > 0.0001 and safetyLoop < 4 do
		safetyLoop = safetyLoop + 1
		local currentSpeed = self.velocity.Magnitude

		if currentSpeed < Config.Physics.GRAVITY_THRESHOLD then
			local gravityForce = Config.Physics.GRAVITY * remainingDt * 60
			self.velocity = self.velocity - Vector3.new(0, gravityForce, 0)
		end

		local postGravitySpeed = self.velocity.Magnitude
		if postGravitySpeed < Config.Physics.MIN_SPEED then
			local hSpeed = Vector3.new(self.velocity.X, 0, self.velocity.Z).Magnitude
			local vSpeed = math.abs(self.velocity.Y)
			if hSpeed < 0.5 and vSpeed < 0.1 then
				self.velocity = Vector3.zero
				self.isMoving = false
				return false
			end
		end

		if not self.isMoving then
			break
		end

		local moveVector = self.velocity * remainingDt
		local moveDist = moveVector.Magnitude
		local nextPos = self.position + moveVector

		local bounceHeight = groundHeight + Config.Physics.FLOAT_HEIGHT
		local crossedFloor = (nextPos.Y <= bounceHeight) and (self.velocity.Y < 0)

		if crossedFloor then
			local distToFloor = self.position.Y - bounceHeight
			local timeToImpact = 0
			if math.abs(self.velocity.Y) > 0.001 then
				timeToImpact = distToFloor / math.abs(self.velocity.Y)
			end
			timeToImpact = math.clamp(timeToImpact, 0, remainingDt)

			self.position = self.position + (self.velocity * timeToImpact)
			remainingDt = remainingDt - timeToImpact

			local impactAngle = math.deg(math.asin(math.abs(self.velocity.Unit.Y)))
			local shouldBounce = (impactAngle >= Config.Physics.MIN_BOUNCE_ANGLE)
				and (currentSpeed >= Config.Physics.MIN_BOUNCE_SPEED)
				and (self.bounceCount < Config.Physics.MAX_BOUNCES)

			if shouldBounce then
				self.velocity = Vector3.new(self.velocity.X, math.abs(self.velocity.Y), self.velocity.Z)
					* Config.Physics.GROUND_BOUNCE_ENERGY_LOSS
				self.bounceCount = self.bounceCount + 1
			else
				self.velocity = Vector3.new(self.velocity.X, 0, self.velocity.Z)
				local slideMove = self.velocity * remainingDt
				local nextSlidePos =
					Vector3.new(self.position.X + slideMove.X, bounceHeight, self.position.Z + slideMove.Z)

				if raycastFunc then
					local collision = raycastFunc(self.position, nextSlidePos)
					if collision then
						local hitNormal = collision.Normal
						local hitPos = collision.Position

						self.position = hitPos + (hitNormal * 0.1)
						local reflected = self.velocity - 2 * self.velocity:Dot(hitNormal) * hitNormal
						self.velocity = reflected * Config.Physics.BOUNCE_ENERGY_LOSS

						remainingDt = 0
					else
						self.position = nextSlidePos
						remainingDt = 0
					end
				else
					self.position = nextSlidePos
					remainingDt = 0
				end
				self.bounceCount = 0
			end

			if onCollision then
				onCollision(nil, math.abs(self.velocity.Y))
			end
			-- break removed
		else
			if raycastFunc then
				local collision = raycastFunc(self.position, nextPos)
				if collision then
					local hitNormal = collision.Normal
					local hitPos = collision.Position

					local distToHit = (hitPos - self.position).Magnitude
					local fraction = 1
					if moveDist > 0.001 then
						fraction = distToHit / moveDist
					end
					local timeToHit = remainingDt * fraction

					self.position = hitPos + (hitNormal * 0.1)
					remainingDt = remainingDt - timeToHit

					local reflected = self.velocity - 2 * self.velocity:Dot(hitNormal) * hitNormal
					self.velocity = reflected * Config.Physics.BOUNCE_ENERGY_LOSS

					if self.position.Y < bounceHeight then
						self.position = Vector3.new(self.position.X, bounceHeight, self.position.Z)
					end

					if onCollision then
						onCollision(collision, math.abs(self.velocity:Dot(hitNormal)))
					end
				else
					self.position = nextPos
					remainingDt = 0
				end
			else
				self.position = nextPos
				remainingDt = 0
			end
		end

		if self.position.Magnitude > 100000 or self.position.X ~= self.position.X then
			self.velocity = -self.velocity * 0.5
			self.position = Vector3.new(0, 50, 0)
		end
	end

	self.velocity = self.velocity * (Config.Physics.DECELERATION ^ (dt * 60))

	return true
end

function BallPhysics:enforceFloatHeight(groundHeight)
	local targetHeight = groundHeight + Config.Physics.FLOAT_HEIGHT

	if self.position.Y < targetHeight then
		self.position = Vector3.new(self.position.X, targetHeight, self.position.Z)

		if self.velocity.Y < 0 then
			self.velocity = Vector3.new(self.velocity.X, 0, self.velocity.Z)
		end
	end
end

function BallPhysics:getSpeed()
	return self.velocity.Magnitude
end

function BallPhysics:getSpeedPercent()
	return math.clamp(self:getSpeed() / Config.Physics.MAX_SPEED, 0, 1)
end

function BallPhysics:serialize()
	return {
		position = self.position,
		velocity = self.velocity,
		isMoving = self.isMoving,
		hitCount = self.hitCount,
		color = self.color,
		transparency = self.transparency or 0,
		lastHitter = self.lastHitter or "None",
	}
end

function BallPhysics:deserialize(data)
	self.position = data.position
	self.velocity = data.velocity
	self.isMoving = data.isMoving
	self.hitCount = data.hitCount
	self.lastHitter = data.lastHitter or "None"
	self.transparency = data.transparency or 0
	if data.color then
		self.color = data.color
	end
end

return BallPhysics
