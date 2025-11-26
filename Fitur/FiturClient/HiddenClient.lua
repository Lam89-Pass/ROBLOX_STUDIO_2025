-- HiddenClient By.KDS (Kalyndeus Studio)
-- Developer : Kalyndeus Studio
-- Letakkan di: StarterPlayer > StarterPlayerScripts > FiturClient > HiddenClient

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

local hideTitleActive = false
local hideUIActive = false
local originalStates = {}

local function makeDraggable(frame)
	local dragToggle = nil
	local dragSpeed = 0
	local dragStart = nil
	local startPos = nil

	local function updateInput(input)
		local delta = input.Position - dragStart
		local position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		frame.Position = position
	end

	frame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragToggle = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragToggle = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragToggle then
				updateInput(input)
			end
		end
	end)
end

local function togglePlayerTitle()
	hideTitleActive = not hideTitleActive

	local character = Player.Character
	if not character then 
		return false
	end

	for _, obj in pairs(character:GetDescendants()) do
		local isTitle = false

		if obj:IsA("BillboardGui") then
			isTitle = true
		elseif obj.Name:lower():find("title") or 
			obj.Name:lower():find("name") or
			obj.Name:lower():find("tag") then
			isTitle = true
		end

		if isTitle then
			if not originalStates[obj] then
				originalStates[obj] = obj.Enabled or true
			end

			obj.Enabled = not hideTitleActive
		end
	end

	if hideTitleActive then
		character.DescendantAdded:Connect(function(obj)
			if hideTitleActive and obj:IsA("BillboardGui") then
				task.wait(0.05)
				obj.Enabled = false
			end
		end)
	end

	return hideTitleActive
end

local function toggleAllUI()
	hideUIActive = not hideUIActive

	local protected = {"TopBar", "HiddenUI", "Chat"}

	if hideUIActive then
		for _, ui in pairs(PlayerGui:GetChildren()) do
			if not ui:IsA("ScreenGui") then continue end

			local isProtected = false
			for _, name in ipairs(protected) do
				if ui.Name == name then
					isProtected = true
					break
				end
			end

			if not isProtected then
				originalStates[ui] = ui.Enabled

				ui.Enabled = false
			end
		end
	else
		for _, ui in pairs(PlayerGui:GetChildren()) do
			if not ui:IsA("ScreenGui") then continue end

			local isProtected = false
			for _, name in ipairs(protected) do
				if ui.Name == name then
					isProtected = true
					break
				end
			end

			if not isProtected and originalStates[ui] ~= nil then
				ui.Enabled = originalStates[ui]
			end
		end

		originalStates = {}
	end

	return hideUIActive
end

local function makeResponsive(frame)
	local function updateSize()
		local viewportSize = workspace.CurrentCamera.ViewportSize
		local isMobile = viewportSize.X < 600 or UserInputService.TouchEnabled

		if isMobile then
			frame.Size = UDim2.new(0, 280, 0, 140)
			frame.Position = UDim2.new(0.5, 0, 0.4, 0)
			frame.AnchorPoint = Vector2.new(0.5, 0.5)

			for _, child in pairs(frame:GetDescendants()) do
				if child:IsA("TextButton") then
					if child.TextSize then
						child.TextSize = 16
					end

					if child.Name == "hideUI" or child.Name == "hideTitle" or child.Name == "HideUI" or child.Name == "HideTitle" then
						child.Size = UDim2.new(child.Size.X.Scale, child.Size.X.Offset, 0, 35)
					end
				elseif child:IsA("TextLabel") then
					if child.TextSize and child.TextSize > 16 then
						child.TextSize = 14
					end
				end
			end
		else
			for _, child in pairs(frame:GetDescendants()) do
				if child:IsA("TextButton") then
					if child.TextSize then
					end
				end
			end
		end
	end

	updateSize()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateSize)
end

local function setupHiddenUI()
	local hiddenUI = PlayerGui:WaitForChild("HiddenUI", 10)
	if not hiddenUI then 
		warn("⚠️ HiddenUI tidak ditemukan di PlayerGui!")
		return 
	end

	local frame = hiddenUI:FindFirstChild("Frame")
	if not frame then 
		warn("⚠️ Frame tidak ditemukan di HiddenUI!")
		return 
	end

	makeResponsive(frame)

	makeDraggable(frame)

	local closeBtn = frame:FindFirstChild("ClosePanel") or frame:FindFirstChild("closePanel")
	if closeBtn and closeBtn:IsA("TextButton") then
		closeBtn.MouseButton1Click:Connect(function()
			if hideUIActive then
				toggleAllUI() 

				local hideUIBtn = frame:FindFirstChild("hideUI") or 
					frame:FindFirstChild("HideUI") or
					frame:FindFirstChild("hideui")
				if hideUIBtn then
					hideUIBtn.Text = "Hide UI"
				end
			end

			hiddenUI.Enabled = false
		end)
	end

	local hideTitleBtn = frame:FindFirstChild("hideTitle") or 
		frame:FindFirstChild("HideTitle") or
		frame:FindFirstChild("hidetitle")

	if hideTitleBtn and hideTitleBtn:IsA("TextButton") then
		hideTitleBtn.Text = "Hide Title"

		hideTitleBtn.MouseButton1Click:Connect(function()
			local state = togglePlayerTitle()
			hideTitleBtn.Text = state and "✓ Title Hidden" or "Hide Title"
		end)
	else
		warn("⚠️ Hide Title button tidak ditemukan!")
	end

	local hideUIBtn = frame:FindFirstChild("hideUI") or 
		frame:FindFirstChild("HideUI") or
		frame:FindFirstChild("hideui")

	if hideUIBtn and hideUIBtn:IsA("TextButton") then
		hideUIBtn.Text = "Hide UI"

		hideUIBtn.MouseButton1Click:Connect(function()
			local state = toggleAllUI()
			hideUIBtn.Text = state and "✓ UI Hidden" or "Hide UI"
		end)
	else
		warn("⚠️ Hide UI button tidak ditemukan!")
	end

	print("✅ HiddenClient initialized successfully!")
end

task.wait(2)
setupHiddenUI()

Player.CharacterAdded:Connect(function()
	hideTitleActive = false
	hideUIActive = false
	originalStates = {}
	task.wait(2)
	setupHiddenUI()
end)