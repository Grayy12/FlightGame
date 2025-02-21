local FlightHandler = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunServiceStepped = game:GetService("RunService").Stepped

local localPlayer = Players.LocalPlayer
local CurrentCamera: Camera = workspace.CurrentCamera
local Assets = ReplicatedStorage:WaitForChild("Assets")

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = true
rayParams.FilterDescendantsInstances = {
	workspace.Terrain,
}

local waterRayParams = RaycastParams.new()
waterRayParams.FilterType = Enum.RaycastFilterType.Include
waterRayParams.FilterDescendantsInstances = {
	workspace.Terrain,
}

local waterFlyOver: ParticleEmitter = Assets:WaitForChild("WaterFlyOver")

function FlightHandler.Start()
	FlightHandler.isFlying = false
	localPlayer:SetAttribute("MaxSpeed", 750)

	localPlayer.CharacterAdded:Connect(function(char)
		local hum = char:FindFirstChildOfClass("Humanoid")

		hum.Died:Connect(function()
			FlightHandler.isFlying = false
		end)
	end)
end

local function initializeFlightComponents(character, humanoid, hrp)
	local lowerTorsoRoot = humanoid.RigType == Enum.HumanoidRigType.R15 and character:WaitForChild("LowerTorso"):WaitForChild("Root") or hrp:WaitForChild("RootJoint")

	local components = {
		ccFOV = CurrentCamera.FieldOfView,
		lowerTorsoRoot = lowerTorsoRoot,
		lowerTorsoRootC0 = lowerTorsoRoot.C0,
	}

	return components
end

local function createFlightAttachments(humanoid: Humanoid, hrp: BasePart)
	local hrpAttachment = Instance.new("Attachment")
	local AlignPosition = Instance.new("AlignPosition")
	local AlignOrientation = Instance.new("AlignOrientation")

	hrpAttachment.Parent = hrp

	AlignPosition.Name = "Flight"
	AlignPosition.ApplyAtCenterOfMass = false
	AlignPosition.Attachment0 = hrpAttachment
	AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment
	AlignPosition.Responsiveness = 10
	AlignPosition.MaxForce = 1000000000000000
	AlignPosition.Parent = hrp

	AlignOrientation.MaxTorque = 1000000000000000
	AlignOrientation.Attachment0 = hrpAttachment
	AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	AlignOrientation.CFrame = CFrame.new(hrp.Position, hrp.Position - Vector3.new(0, 1, 0))
	AlignOrientation.Parent = hrp

	if humanoid.FloorMaterial == Enum.Material.Air then
		AlignPosition.Position = hrp.Position + hrp.AssemblyLinearVelocity * 0.3
	else
		AlignPosition.Position = hrp.Position + Vector3.new(0, 10, 0)
	end

	return {
		hrpAttachment = hrpAttachment,
		AlignPosition = AlignPosition,
		AlignOrientation = AlignOrientation,
		initialVelocity = humanoid.FloorMaterial == Enum.Material.Air and hrp.AssemblyLinearVelocity.Magnitude or 0,
	}
end

local function calculateMovementValues(hrp, moveDirection)
	local localMoveDirection = hrp.CFrame:VectorToObjectSpace(moveDirection)
	local localVelocity = hrp.CFrame:VectorToObjectSpace(hrp.Velocity) * 0.02

	local velocityVector = Vector3.new(math.clamp(math.abs(localVelocity.X), 0, math.huge), 0, math.clamp(math.abs(localVelocity.Z), 0, math.huge))

	local xMovement = localMoveDirection.X * velocityVector.X
	local zMovement = localMoveDirection.Z * velocityVector.Z

	return {
		clampedXMovement = math.clamp(xMovement, -0.6, 0.6),
		clampedZMovement = math.clamp(zMovement, -3, 3),
	}
end

local function updateCharacterRotation(humanoid, lowerTorsoRoot, lowerTorsoRootC0, clampedXMovement, clampedZMovement, deltaTime)
	local rotationAngles = humanoid.RigType == Enum.HumanoidRigType.R15 and { clampedZMovement / 3, 0, -clampedXMovement } or { -clampedZMovement, -clampedXMovement, 0 }

	lowerTorsoRoot.C0 = lowerTorsoRoot.C0:Lerp(lowerTorsoRootC0 * CFrame.Angles(unpack(rotationAngles)), 0.5 * deltaTime)
end

local function calculateFlightSpeed(moveDirection, currentFlightSpeed, maxSpeed, deltaTime)
	local acceleration = maxSpeed / 2.2857142857142856

	if moveDirection.Magnitude == 0 then
		local dtsecs = 60 * deltaTime
		return currentFlightSpeed + (0 - currentFlightSpeed) * dtsecs
	else
		local acceleratedFlightSpeed = currentFlightSpeed + deltaTime * acceleration
		return math.clamp(acceleratedFlightSpeed, 15, math.max(maxSpeed, 15))
	end
end

local function updateCameraEffects(character, humanoid, hrp, ccFOV)
	local hrpSpeed = hrp.AssemblyLinearVelocity.Magnitude
	local maxSpeed = math.max(localPlayer:GetAttribute("MaxSpeed"), hrpSpeed)
	local normalizedSpeed = hrpSpeed / maxSpeed
	local clampedSpeedRatio = math.clamp(math.abs(normalizedSpeed), 0, 1)

	local minFOV = ccFOV * 0.8
	local maxFOV = ccFOV * 1.25
	local targetFOV = minFOV + (maxFOV - minFOV) * clampedSpeedRatio
	local currentFOV = CurrentCamera.FieldOfView

	CurrentCamera.FieldOfView = currentFOV + (math.clamp(targetFOV, minFOV, maxFOV) - currentFOV) * 0.1

	local hrpAssemblyLinearVelocityUnit = hrp.AssemblyLinearVelocity == Vector3.new(0, 0, 0) and Vector3.new(0, 0, 0) or hrp.AssemblyLinearVelocity.Unit

	return hrpAssemblyLinearVelocityUnit, clampedSpeedRatio
end

local function cleanupFlight(humanoid, attachments, components)
	humanoid.PlatformStand = false

	for _, attachment in pairs(attachments) do
		if attachment and typeof(attachment) == "Instance" then
			attachment:Destroy()
		end
	end

	TweenService:Create(CurrentCamera, TweenInfo.new(0.3), {
		FieldOfView = components.ccFOV,
	}):Play()

	TweenService:Create(humanoid, TweenInfo.new(0.3), {
		CameraOffset = Vector3.new(0, 0, 0),
	}):Play()

	TweenService:Create(components.lowerTorsoRoot, TweenInfo.new(0.3), {
		C0 = components.lowerTorsoRootC0,
	}):Play()
end

local function isInWater()
	local char = localPlayer.Character
	local head: BasePart? = char and char:FindFirstChild("Head")
	if not head then
		return false
	end

	local min = head.Position - (0.25 * head.Size)
	local max = head.Position + (0.25 * head.Size)
	local region = Region3.new(min, max):ExpandToGrid(4)

	local materials = workspace.Terrain:ReadVoxels(region, 4)

	for x = 1, #materials do
		for y = 1, #materials[x] do
			for z = 1, #materials[x][y] do
				if materials[x][y][z] == Enum.Material.Water then
					print("IN Water")
					return true
				end
			end
		end
	end

	return false
end

-- Add this after the other local functions, before FlightHandler.ToggleFly
local function createWaterRipple(position, hrp: BasePart)
	local hrpVelo = hrp.AssemblyLinearVelocity
	local posAdd = Vector3.new(hrpVelo.X, 0, hrpVelo.Z) * 0.12 + Vector3.new(0, 0.3, 0)

	local ripple = Instance.new("Part")
	ripple.Size = Vector3.new(1, 0.1, 1)
	ripple.Transparency = 1
	ripple.Anchored = true
	ripple.CanCollide = false
	ripple.CFrame = CFrame.new(position + posAdd)
	ripple.Parent = workspace:WaitForChild("Debris")

	local particleAccel = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z) * hrpVelo.Magnitude

	local particle = waterFlyOver:Clone()
	particle.Parent = ripple
	particle.Acceleration = particleAccel
	print("particleAccel", particleAccel)

	game:GetService("Debris"):AddItem(ripple, 0.5)
end

function FlightHandler.ToggleFly()
	FlightHandler.isFlying = not FlightHandler.isFlying
	if not FlightHandler.isFlying then
		return
	end

	local character = localPlayer.Character
	if not (character and character:FindFirstChild("Humanoid") and character.PrimaryPart) then
		return
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character.PrimaryPart

	local components = initializeFlightComponents(character, humanoid, hrp)
	local attachments = createFlightAttachments(humanoid, hrp)

	humanoid.PlatformStand = true
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	local cameraOffsetMultiplier = 0.5
	local currentFlightSpeed = math.max(20, attachments.initialVelocity)

	while FlightHandler.isFlying do
		if not character then
			FlightHandler.isFlying = false
			break
		end

		local _, deltaTime = RunServiceStepped:Wait()
		local cameraCFrame = CurrentCamera.CFrame
		local moveDirection = humanoid.MoveDirection

		local movementValues = calculateMovementValues(hrp, moveDirection)
		updateCharacterRotation(humanoid, components.lowerTorsoRoot, components.lowerTorsoRootC0, movementValues.clampedXMovement, movementValues.clampedZMovement, deltaTime)

		local hrpAssemblyLinearVelocityUnit, clampedSpeedRatio = updateCameraEffects(character, humanoid, hrp, components.ccFOV)

		currentFlightSpeed = calculateFlightSpeed(moveDirection, currentFlightSpeed, localPlayer:GetAttribute("MaxSpeed"), deltaTime)

		-- Movement logic remains the same as it's already well-structured
		local movementMultiplier = (deltaTime * currentFlightSpeed)
		local movementDistance = Vector3.new()

		local lookAlongDirection = cameraCFrame.LookVector == Vector3.new(0, 0, 0) and hrp.CFrame.LookVector or cameraCFrame.LookVector
		local cameraCFRight = cameraCFrame.RightVector
		local cameraCFUp = cameraCFrame.UpVector
		local forwardMovement = moveDirection:Dot(lookAlongDirection)
		local rightMovement = moveDirection:Dot(cameraCFRight)

		if math.abs(rightMovement) > 0.1 and math.abs(forwardMovement) > 0.1 then
			if forwardMovement < -0.1 then
				movementDistance = movementDistance + lookAlongDirection * -0.2 * movementMultiplier
			elseif forwardMovement > 0.1 then
				movementDistance = movementDistance + lookAlongDirection * 0.5 * movementMultiplier
			end
			if rightMovement < -0.1 then
				movementDistance = movementDistance + cameraCFRight * -0.5 * movementMultiplier
			elseif rightMovement > 0.1 then
				movementDistance = movementDistance + cameraCFRight * 0.5 * movementMultiplier
			end
		else
			if forwardMovement < -0.1 then
				movementDistance = movementDistance + lookAlongDirection * -0.3 * movementMultiplier
			elseif forwardMovement > 0.1 then
				movementDistance = movementDistance + lookAlongDirection * movementMultiplier
			end
			if rightMovement < -0.1 then
				movementDistance = movementDistance + cameraCFRight * -0.2 * movementMultiplier
			elseif rightMovement > 0.1 then
				movementDistance = movementDistance + cameraCFRight * 0.2 * movementMultiplier
			end
		end

		if humanoid.Jump then
			movementDistance = movementDistance + cameraCFUp * 0.2 * (movementMultiplier > 0.2 and movementMultiplier or localPlayer:GetAttribute("MaxSpeed") * 0.02)
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			movementDistance = movementDistance + cameraCFUp * -0.2 * (movementMultiplier > 0.2 and movementMultiplier or localPlayer:GetAttribute("MaxSpeed") * 0.02)
		end

		attachments.AlignPosition.Position = attachments.AlignPosition.Position + movementDistance * (isInWater() and 1 - math.clamp(((localPlayer:GetAttribute("MaxSpeed") - 80) / 270) * 0.25 + 0.35, 0.35, 0.6) or 1)

		-- Water Ripples
		local waterRaycast = workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), waterRayParams)
		if waterRaycast and waterRaycast.Material == Enum.Material.Water then
			if waterRaycast.Distance < 10 and hrp.AssemblyLinearVelocity.Magnitude > 20 then
				if tick() % 0.2 < 0.1 then
					createWaterRipple(waterRaycast.Position, hrp)
				end
			end
		end

		local distanceToTarget = (hrp.Position - attachments.AlignPosition.Position).Magnitude
		local directionToTarget = attachments.AlignPosition.Position - hrp.Position
		local normalizedDirection = directionToTarget == Vector3.new(0, 0, 0) and Vector3.new(0, 0, 0) or directionToTarget.Unit

		if workspace:Raycast(hrp.Position, normalizedDirection * distanceToTarget, rayParams) then
			attachments.AlignPosition.Position = attachments.AlignPosition.Position:Lerp(hrp.Position, 0.15)
		end

		if forwardMovement >= 0.1 or forwardMovement <= -0.1 then
			attachments.AlignOrientation.CFrame = CFrame.lookAlong(hrp.Position, lookAlongDirection, Vector3.new(0, 1, 0)) * CFrame.Angles(math.rad(forwardMovement <= -0.1 and 80 or -80), math.rad(forwardMovement <= -0.1 and 180 or 0), 0)
		elseif hrp.AssemblyLinearVelocity.Magnitude >= 1.2 then
			attachments.AlignOrientation.CFrame = CFrame.lookAlong(hrp.Position, lookAlongDirection, Vector3.new(0, 1, 0))
		else
			attachments.AlignOrientation.CFrame = CFrame.lookAlong(hrp.Position, hrp.CFrame.LookVector, Vector3.new(0, 1, 0))
		end

		cameraOffsetMultiplier = cameraOffsetMultiplier + (clampedSpeedRatio - cameraOffsetMultiplier) * 0.05
		local desiredCameraOffset = (hrp.AssemblyLinearVelocity.Magnitude > 0 and hrpAssemblyLinearVelocityUnit and hrpAssemblyLinearVelocityUnit or hrp.CFrame.LookVector) * cameraOffsetMultiplier * 4
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(desiredCameraOffset / 1.5, 0.03)
	end

	cleanupFlight(humanoid, attachments, components)
end

UserInputService.InputBegan:Connect(function(input, gamepro)
	if gamepro then
		return
	end
	if input.KeyCode == Enum.KeyCode.F then
		FlightHandler.ToggleFly()
	end
end)

return FlightHandler
