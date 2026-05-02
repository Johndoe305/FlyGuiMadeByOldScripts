--[[=====================================================
    Fly Gui / Made By Old Scripts
=======================================================]]

--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

--// PLAYER
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--// CONFIG
local CONFIG = {
	DEFAULT_STRENGTH = 10000,
	DEFAULT_HEIGHT = 0,
	BASE_WALK_SPEED = 16,

	MAX_STRENGTH = 10000,
	MAX_HEIGHT = 50
}

--// STATE
local State = {
	Enabled = false,
	BodyPosition = nil,
	Connection = nil
}

--=====================================================
-- UTIL (ANTI INPUT BREAK + HARD CLAMP)
--=====================================================

local function getCharacter()
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")

	return char, hrp, hum
end

-- 🔥 BLOQUEIO REAL (não deixa passar nem 1 frame inválido)
local function safeNumber(textbox, max, fallback)

	local n = tonumber(textbox.Text)

	if not n or n < 0 or n > max then
		textbox.Text = tostring(fallback)
		return fallback
	end

	return math.floor(n)
end

--=====================================================
-- UI CREATION (NÃO ALTERADO VISUALMENTE)
--=====================================================

local gui = Instance.new("ScreenGui")
gui.Name = "BodyPosProHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 260, 0, 240)
main.Position = UDim2.new(0.5, -130, 0.5, -120)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Parent = main
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "Fly Gui (Anti cheat No Detect)"
title.TextColor3 = Color3.fromRGB(0, 255, 150)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

local container = Instance.new("Frame")
container.Parent = main
container.Size = UDim2.new(1, -20, 1, -45)
container.Position = UDim2.new(0, 10, 0, 40)
container.BackgroundTransparency = 1

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 8)
layout.Parent = container

-- INPUT BUILDER
local function createInput(labelText, defaultValue)

	local label = Instance.new("TextLabel")
	label.Parent = container
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(200, 200, 200)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Size = UDim2.new(1, 0, 0, 15)

	local box = Instance.new("TextBox")
	box.Parent = container
	box.Size = UDim2.new(1, 0, 0, 30)
	box.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	box.TextColor3 = Color3.fromRGB(255, 255, 255)
	box.ClearTextOnFocus = false
	box.Text = tostring(defaultValue)
	box.Font = Enum.Font.Gotham
	box.TextSize = 14

	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	return box
end

local speedInput = createInput("FORCE (SPEED)", CONFIG.DEFAULT_STRENGTH)
local heightInput = createInput("HEIGHT (Y)", CONFIG.DEFAULT_HEIGHT)

--=====================================================
-- 🔥 FIX CRÍTICO: BLOQUEIO REAL DE INPUT
--=====================================================

speedInput.FocusLost:Connect(function()
	local v = tonumber(speedInput.Text)
	if not v or v > CONFIG.MAX_STRENGTH or v < 0 then
		speedInput.Text = tostring(CONFIG.DEFAULT_STRENGTH)
	end
end)

heightInput.FocusLost:Connect(function()
	local v = tonumber(heightInput.Text)
	if not v or v > CONFIG.MAX_HEIGHT or v < 0 then
		heightInput.Text = tostring(CONFIG.DEFAULT_HEIGHT)
	end
end)

-- BUTTON
local toggleBtn = Instance.new("TextButton")
toggleBtn.Parent = container
toggleBtn.Size = UDim2.new(1, 0, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
toggleBtn.Text = "Activate Fly"
toggleBtn.TextColor3 = Color3.fromRGB(15, 15, 15)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16

Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

--=====================================================
-- DRAG FIX (PC + MOBILE)
--=====================================================

do
	local dragging = false
	local dragStart
	local startPos

	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = main.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart

			main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--=====================================================
-- CORE LOGIC
--=====================================================

local function startSystem()

	local _, hrp, hum = getCharacter()
	if not hrp or not hum then return end

	hum.WalkSpeed = CONFIG.BASE_WALK_SPEED
	hum:ChangeState(Enum.HumanoidStateType.Physics)

	State.BodyPosition = Instance.new("BodyPosition")
	State.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	State.BodyPosition.Parent = hrp

	State.Connection = RunService.Heartbeat:Connect(function()

		if not State.Enabled then return end

		local _, charHrp, charHum = getCharacter()
		if not charHrp or not charHum then return end

		-- 🔥 VALIDAÇÃO FORTE (ANTI EXPLOIT INPUT)
		local strength = safeNumber(speedInput, CONFIG.MAX_STRENGTH, CONFIG.DEFAULT_STRENGTH)
		local height = safeNumber(heightInput, CONFIG.MAX_HEIGHT, CONFIG.DEFAULT_HEIGHT)

		State.BodyPosition.P = strength

		local moveDir = charHum.MoveDirection
		local target = charHrp.Position

		if moveDir.Magnitude > 0 then
			target = charHrp.Position + (moveDir * 50)
		end

		State.BodyPosition.Position = Vector3.new(
			target.X,
			charHrp.Position.Y + height,
			target.Z
		)
	end)
end

local function stopSystem()

	State.Enabled = false

	if State.Connection then
		State.Connection:Disconnect()
	end

	if State.BodyPosition then
		State.BodyPosition:Destroy()
	end

	local _, _, hum = getCharacter()
	if hum then
		hum.WalkSpeed = CONFIG.BASE_WALK_SPEED
		hum:ChangeState(Enum.HumanoidStateType.Running)
	end
end

--=====================================================
-- TOGGLE
--=====================================================

toggleBtn.MouseButton1Click:Connect(function()

	State.Enabled = not State.Enabled

	if State.Enabled then
		toggleBtn.Text = "Disable Fly"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
		startSystem()
	else
		toggleBtn.Text = "Activate Fly"
		toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
		stopSystem()
	end
end)
