-- Fitur EmoteLocal By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local FiturModules = ReplicatedStorage:WaitForChild("FiturModules")
local EmoteConfig = require(FiturModules:WaitForChild("EmoteConfig"))

local RemoteFitur = ReplicatedStorage:WaitForChild("RemoteFitur")
local PlayEmote = RemoteFitur:WaitForChild("PlayEmote")

local emoteUI = nil 
local currentEmoteId = nil 
local lastEmoteTime = 0
local isDragging = false
local dragStart = Vector2.zero
local frameStart = UDim2.new()
local dragFrame = nil 
local dragConnection = nil 
local savedUIPosition = nil 

local EmoteUIManager = {}

function EmoteUIManager.resetPosition(emoteFrame)
	if emoteFrame then
		emoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)

		local viewportSize = workspace.CurrentCamera.ViewportSize
		local aspectRatio = viewportSize.X / viewportSize.Y
		local isMobile = viewportSize.X < 800 or (UserInputService.TouchEnabled and not UserInputService.MouseEnabled)

		if isMobile then
			emoteFrame.Position = UDim2.new(0.5, 0, 0.68, 0)
		else
			emoteFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
		end

		savedUIPosition = emoteFrame.Position

		if EmoteConfig.Settings.DebugMode then
			print("[EmoteClient] UI positioned for:", isMobile and "MOBILE" or "DESKTOP", "at Y:", emoteFrame.Position.Y.Scale)
		end
	end
end

function EmoteUIManager.init()
	if not emoteUI then
		warn("[EmoteClient] EmoteUI not found")
		return false
	end

	local emoteFrame = emoteUI:FindFirstChild("Frame")
	if not emoteFrame then
		warn("[EmoteClient] Frame not found in EmoteUI")
		return false
	end

	emoteFrame.AnchorPoint = Vector2.new(0.5, 0.5)

	if savedUIPosition then
		local pos = savedUIPosition
		if pos.X.Scale < 0 or pos.X.Scale > 1 or pos.Y.Scale < 0 or pos.Y.Scale > 1 then
			EmoteUIManager.resetPosition(emoteFrame)
		else
			emoteFrame.Position = savedUIPosition
		end
	else
		EmoteUIManager.resetPosition(emoteFrame)
	end

	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if not savedUIPosition or not isDragging then
			task.wait(0.1)
			EmoteUIManager.resetPosition(emoteFrame)
		end
	end)

	EmoteUIManager.dancePanel = emoteFrame:FindFirstChild("DanceList")
	EmoteUIManager.emotePanel = emoteFrame:FindFirstChild("EmoteList")

	local dragTarget = emoteFrame:FindFirstChild("Frame") 
	if dragTarget then
		EmoteUIManager.danceTabButton = dragTarget:FindFirstChild("Dance") 
		EmoteUIManager.emoteTabButton = dragTarget:FindFirstChild("Emote")
	end

	EmoteUIManager.closeButton = emoteFrame:FindFirstChild("ClosePanel")

	if not EmoteUIManager.dancePanel or not EmoteUIManager.emotePanel then
		warn("[EmoteClient] DanceList or EmoteList not found")
		return false
	end

	EmoteUIManager.setupTabButtons()
	EmoteUIManager.setupCloseButton()
	EmoteUIManager.setupEmoteButtons()

    if dragTarget then
		EmoteUIManager.setupDraggability(dragTarget, emoteFrame) 
	else
		EmoteUIManager.setupDraggability(emoteFrame, emoteFrame)
	end
	EmoteUIManager.switchPanel("Dance")

	if EmoteConfig.Settings.DebugMode then
		print("[EmoteClient] UI Manager initialized successfully")
	end

	return true
end

function EmoteUIManager.setupTabButtons()
	local danceBtn = EmoteUIManager.danceTabButton
	local emoteBtn = EmoteUIManager.emoteTabButton

	if danceBtn and danceBtn:IsA("TextButton") then
		if danceBtn.Text == "" or danceBtn.Text == "Dance" then 
			danceBtn.Text = "DANCE" 
		end
		danceBtn.Activated:Connect(function() 
			EmoteUIManager.switchPanel("Dance") 
		end)
	end

	if emoteBtn and emoteBtn:IsA("TextButton") then
		if emoteBtn.Text == "" or emoteBtn.Text == "Emote" then 
			emoteBtn.Text = "EMOTE" 
		end
		emoteBtn.Activated:Connect(function() 
			EmoteUIManager.switchPanel("Emote") 
		end)
	end
end

function EmoteUIManager.setupCloseButton()
	if EmoteUIManager.closeButton then
		if EmoteUIManager.closeButton:IsA("TextButton") or EmoteUIManager.closeButton:IsA("ImageButton") then
			EmoteUIManager.closeButton.Activated:Connect(function()
				emoteUI.Enabled = false
			end)
		end
	end
end

function EmoteUIManager.switchPanel(panelName)
	if not EmoteUIManager.dancePanel or not EmoteUIManager.emotePanel then return end

	EmoteUIManager.dancePanel.Visible = false
	EmoteUIManager.emotePanel.Visible = false

	if panelName == "Dance" then
		EmoteUIManager.dancePanel.Visible = true
	elseif panelName == "Emote" then
		EmoteUIManager.emotePanel.Visible = true
	end

	EmoteUIManager.updateTabVisuals(panelName)
end

function EmoteUIManager.updateTabVisuals(activeTab)
	local activeColor = Color3.fromRGB(200, 100, 200)
	local inactiveColor = Color3.fromRGB(150, 80, 150)
	local activeText = Color3.fromRGB(255, 255, 255)
	local inactiveText = Color3.fromRGB(200, 200, 200)

	local danceBtn = EmoteUIManager.danceTabButton
	if danceBtn and danceBtn:IsA("TextButton") then
		danceBtn.BackgroundColor3 = (activeTab == "Dance") and activeColor or inactiveColor
		danceBtn.TextColor3 = (activeTab == "Dance") and activeText or inactiveText
	end

	local emoteBtn = EmoteUIManager.emoteTabButton
	if emoteBtn and emoteBtn:IsA("TextButton") then
		emoteBtn.BackgroundColor3 = (activeTab == "Emote") and activeColor or inactiveColor
		emoteBtn.TextColor3 = (activeTab == "Emote") and activeText or inactiveText
	end
end

function EmoteUIManager.setupEmoteButtons()
	local totalButtons = 0

	if EmoteUIManager.dancePanel then
		local count = EmoteUIManager.setupPanelButtons(EmoteUIManager.dancePanel, "Dance")
		totalButtons = totalButtons + count
	end

	if EmoteUIManager.emotePanel then
		local count = EmoteUIManager.setupPanelButtons(EmoteUIManager.emotePanel, "Emote")
		totalButtons = totalButtons + count
	end

	if EmoteConfig.Settings.DebugMode then
		print("[EmoteClient] Total buttons setup:", totalButtons)
	end
end

function EmoteUIManager.setupPanelButtons(panel, category)
	local buttonCount = 0

	for _, child in ipairs(panel:GetChildren()) do
		if (child:IsA("TextButton") or child:IsA("ImageButton")) then 
			local buttonName = child.Name
			local animationId = EmoteConfig:GetAnimationId(buttonName)

			if animationId then
				child.Activated:Connect(function()
					EmoteUIManager.playEmote(buttonName, animationId)
				end)
				buttonCount = buttonCount + 1

				if EmoteConfig.Settings.DebugMode then
					print("[EmoteClient] Button setup:", buttonName, "->", animationId)
				end
			else
				warn("[EmoteClient] No animation found for button:", buttonName)
			end
		end
	end

	return buttonCount
end

function EmoteUIManager.playEmote(emoteName, animationId)
	local currentTime = tick()
	if currentTime - lastEmoteTime < EmoteConfig.Settings.EmoteCooldown then
		if EmoteConfig.Settings.DebugMode then
			print("[EmoteClient] Cooldown active")
		end
		return
	end
	lastEmoteTime = currentTime

	local actionId = animationId

	if currentEmoteId == animationId then
		actionId = nil 
	end

	currentEmoteId = actionId 

	PlayEmote:FireServer(actionId) 

	if EmoteConfig.Settings.DebugMode then
		print("[EmoteClient] Playing emote:", emoteName, actionId or "STOP")
	end

	if EmoteConfig.Settings.AutoCloseUI then
		emoteUI.Enabled = false
	end
end

local function startDrag(input)
	if not dragFrame then return end
	isDragging = true
	dragStart = input.Position
	frameStart = dragFrame.Position
end

local function doDrag(input)
	if not isDragging or not dragFrame then return end

	local delta = input.Position - dragStart
	local viewport = dragFrame.Parent.AbsoluteSize

	local newXScale = frameStart.X.Scale + (delta.X / viewport.X)
	local newYScale = frameStart.Y.Scale + (delta.Y / viewport.Y)

    newXScale = math.clamp(newXScale, 0.1, 0.9)
	newYScale = math.clamp(newYScale, 0.1, 0.9)

	dragFrame.Position = UDim2.new(newXScale, 0, newYScale, 0)

	savedUIPosition = dragFrame.Position
end

local function endDrag()
	if isDragging then
		isDragging = false
	end
end

function EmoteUIManager.setupDraggability(detectFrame, targetFrameToMove)
	if dragConnection then
		dragConnection:Disconnect()
		dragConnection = nil
	end

	dragFrame = targetFrameToMove 

	detectFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			startDrag(input)
		end
	end)

	dragConnection = UserInputService.InputChanged:Connect(function(input)
		if isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			doDrag(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)
end

local function initializeEmoteSystem()
	local newEmoteUI = PlayerGui:WaitForChild("EmoteUI", 10)
	if not newEmoteUI then
		warn("[EmoteClient] EmoteUI not found in PlayerGui")
		return false
	end

	emoteUI = newEmoteUI 

	if newEmoteUI:GetAttribute("ClientInitialized") then
		if EmoteConfig.Settings.DebugMode then
			print("[EmoteClient] Already initialized")
		end
		return true
	end

	local success = EmoteUIManager.init()

	if success then
		newEmoteUI:GetPropertyChangedSignal("Enabled"):Connect(function()
			if newEmoteUI.Enabled then
				task.wait(0.05)
				pcall(function()
					EmoteUIManager.switchPanel("Dance")
				end)
			end
		end)

		newEmoteUI:SetAttribute("ClientInitialized", true)
		print("[EmoteClient] 🎭 Emote system initialized successfully!")
	else
		warn("[EmoteClient] Failed to initialize emote system")
	end

	return success
end

local function onCharacterAdded(character)
	currentEmoteId = nil
	lastEmoteTime = 0
	isDragging = false
	savedUIPosition = nil

	task.wait(0.5) 

	local success = initializeEmoteSystem()

	if success then
		if emoteUI then
			emoteUI.Enabled = false
		end
	end
end

Player.CharacterAdded:Connect(onCharacterAdded)

if Player.Character then
	onCharacterAdded(Player.Character)
end