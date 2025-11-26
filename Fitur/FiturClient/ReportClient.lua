-- Fitur ReportLocal By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FiturModules = ReplicatedStorage:WaitForChild("FiturModules")
local ReportConfig = require(FiturModules:WaitForChild("ReportConfig"))

local RemoteFitur = ReplicatedStorage:WaitForChild("RemoteFitur")
local SendReport = RemoteFitur:WaitForChild("SendReport")

local reportUI = PlayerGui:WaitForChild("ReportUI")

local UIState = {
	selectedCategory = nil,
	selectedPlayerId = nil,
	selectedPlayerName = nil,
	isOnCooldown = false,
	cooldownEndTime = 0
}

local ReportUIManager = {}
local R = {} 
local DragSystem = {}

function DragSystem.makeDraggable(frame)
	local UserInputService = game:GetService("UserInputService")

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y

		frame.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			frame:SetAttribute("WasDragged", true)

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

function ReportUIManager.init()
	local frame = reportUI:FindFirstChild("Frame")
	if not frame then 
		warn("[ReportClient] Frame not found in ReportUI")
		return false 
	end

	R.closeButton = frame:FindFirstChild("ClosePanel")
	R.sendButton = frame:FindFirstChild("Kirim")
	R.categoryButton = frame:FindFirstChild("Pilih Kategori")
	R.playerButton = frame:FindFirstChild("Pilih Pemain")
	R.messageBox = frame:FindFirstChild("pesan")
	R.categoryListFrame = frame:FindFirstChild("ListKategori")
	R.playerListFrame = frame:FindFirstChild("ListPemain")
	R.mainFrame = frame

	DragSystem.makeDraggable(frame)

	if not R.sendButton or not R.messageBox then 
		warn("[ReportClient] Essential UI elements missing")
		return false 
	end

	if R.playerListFrame then
		R.playerScrollFrame = R.playerListFrame:FindFirstChild("ScrollingFrame")
		if not R.playerScrollFrame then
			R.playerScrollFrame = R.playerListFrame
			R.playerListFrame.ClipsDescendants = false
		end
	end

	ReportUIManager.setupCategoryButtons()
	ReportUIManager.setupPlayerList()
	ReportUIManager.setupControls()

	Players.PlayerAdded:Connect(function()
		task.wait(0.5)
		ReportUIManager.setupPlayerList()
	end)

	Players.PlayerRemoving:Connect(function()
		task.wait(0.5)
		ReportUIManager.setupPlayerList()
	end)

	if ReportConfig.Settings.DebugMode then
		print("[ReportClient] Initialized successfully")
	end

	return true
end

function ReportUIManager.setupCategoryButtons()
	if not R.categoryListFrame then return end

	local categoryButtons = {}

	for _, child in ipairs(R.categoryListFrame:GetDescendants()) do
		if child:IsA("TextButton") then
			local btnName = string.lower(child.Name)

			for _, validCategory in ipairs(ReportConfig.UICategories) do
				if string.find(btnName, validCategory) then
					table.insert(categoryButtons, {
						button = child,
						categoryName = validCategory
					})
					break
				end
			end
		end
	end

	if #categoryButtons == 0 then 
		warn("[ReportClient] No category buttons found")
		return 
	end

	for _, btnData in ipairs(categoryButtons) do
		local btn = btnData.button
		local categoryName = btnData.categoryName

		btn.Activated:Connect(function()
			ReportUIManager.selectCategory(categoryName)
			if R.categoryListFrame then
				R.categoryListFrame.Visible = false
			end
		end)

		local originalColor = btn.BackgroundColor3
		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(
				math.min(originalColor.R * 255 + 30, 255),
				math.min(originalColor.G * 255 + 30, 255),
				math.min(originalColor.B * 255 + 30, 255)
			)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = originalColor
		end)
	end

	if ReportConfig.Settings.DebugMode then
		print("[ReportClient] Setup", #categoryButtons, "category buttons")
	end
end

function ReportUIManager.setupControls()
	if R.closeButton then
		R.closeButton.Activated:Connect(function()
			ReportUIManager.closeUI()
		end)
	end

	R.sendButton.Activated:Connect(function()
		ReportUIManager.handleSend()
	end)

	if R.categoryButton and R.categoryListFrame then
		R.categoryListFrame.Visible = false
		R.categoryButton.Activated:Connect(function()
			R.categoryListFrame.Visible = not R.categoryListFrame.Visible
			if R.playerListFrame then
				R.playerListFrame.Visible = false
			end
		end)
	end

	if R.playerButton and R.playerListFrame then
		R.playerListFrame.Visible = false
		R.playerButton.Activated:Connect(function()
			local newVisible = not R.playerListFrame.Visible
			R.playerListFrame.Visible = newVisible
			if R.categoryListFrame then
				R.categoryListFrame.Visible = false
			end
			if newVisible then
				ReportUIManager.setupPlayerList()
			end
		end)
	end

	R.messageBox:GetPropertyChangedSignal("Text"):Connect(function()
		if string.len(R.messageBox.Text) > ReportConfig.Settings.MaxMessageLength then
			R.messageBox.Text = string.sub(R.messageBox.Text, 1, ReportConfig.Settings.MaxMessageLength)
		end
	end)
end

function ReportUIManager.setupPlayerList()
	if not R.playerScrollFrame then return end

	local listLayout = R.playerScrollFrame:FindFirstChildOfClass("UIListLayout")
	if not listLayout then
		listLayout = Instance.new("UIListLayout")
		listLayout.Parent = R.playerScrollFrame
		listLayout.Padding = UDim.new(0, 3)
		listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	end

	for _, child in ipairs(R.playerScrollFrame:GetChildren()) do
		if child:IsA("TextButton") and child.Name:find("PlayerBtn") then 
			child:Destroy()
		end
	end

	local players = Players:GetPlayers()
	table.sort(players, function(a, b) return a.Name < b.Name end)

	local isMobile = game:GetService("UserInputService").TouchEnabled and 
		not game:GetService("UserInputService").KeyboardEnabled

	local buttonHeight = isMobile and 32 or 36
	local textSize = isMobile and 12 or 14

	for i, p in ipairs(players) do
		if not p or not p.Parent then continue end

		local btn = Instance.new("TextButton")
		btn.Name = "PlayerBtn_" .. p.UserId
		btn.Size = UDim2.new(1, -8, 0, buttonHeight)
		btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.TextSize = textSize
		btn.Font = Enum.Font.GothamBold
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.LayoutOrder = i
		btn.Parent = R.playerScrollFrame

		local displayText = "  " .. p.Name
		if p.UserId == Player.UserId then
			displayText = "⭐ " .. p.Name .. " (Anda)"
		end
		btn.Text = displayText

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 4)
		corner.Parent = btn

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 6)
		padding.Parent = btn

		local playerName = p.Name
		local playerId = p.UserId
		btn.Activated:Connect(function()
			ReportUIManager.selectPlayer(playerName, playerId)
			if R.playerListFrame then
				R.playerListFrame.Visible = false
			end
		end)

		btn.MouseEnter:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
		end)
		btn.MouseLeave:Connect(function()
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end)
	end

	if R.playerScrollFrame:IsA("ScrollingFrame") then
		task.wait(0.1)
		R.playerScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end

	if ReportConfig.Settings.DebugMode then
		print("[ReportClient] Setup", #players, "player buttons")
	end
end

function ReportUIManager.selectCategory(categoryName)
	UIState.selectedCategory = categoryName

	if R.categoryButton then
		local displayText = categoryName:upper()

		if categoryName == "rusuh" then
			displayText = "🔴 RUSUH / TOXIC"
		elseif categoryName == "cheater" then
			displayText = "⚠️ CHEATER"
		elseif categoryName == "bug" then
			displayText = "🐛 BUG / ERROR"
		elseif categoryName == "saran" then
			displayText = "💡 SARAN / FEEDBACK"
		end

		R.categoryButton.Text = displayText
	end

	if ReportConfig.Settings.DebugMode then
		print("[ReportClient] Selected category:", categoryName)
	end
end

function ReportUIManager.selectPlayer(playerName, playerId)
	UIState.selectedPlayerId = playerId
	UIState.selectedPlayerName = playerName

	if R.playerButton then
		if playerId == Player.UserId then
			R.playerButton.Text = playerName .. " (Anda)"
		else
			R.playerButton.Text = playerName
		end
	end

	if ReportConfig.Settings.DebugMode then
		print("[ReportClient] Selected player:", playerName, playerId)
	end
end

function ReportUIManager.handleSend()
	if UIState.isOnCooldown then
		local timeLeft = math.ceil(UIState.cooldownEndTime - os.clock())
		ReportUIManager.showNotification("⏰ Tunggu " .. timeLeft .. " detik", Color3.fromRGB(255, 200, 0))
		return
	end

	if not UIState.selectedCategory then
		ReportUIManager.showNotification("⚠️ Pilih kategori!", Color3.fromRGB(255, 100, 100))
		return
	end

	if not UIState.selectedPlayerId then
		ReportUIManager.showNotification("⚠️ Pilih pemain!", Color3.fromRGB(255, 100, 100))
		return
	end

	local message = R.messageBox.Text
	local messageLength = string.len(message)

	if messageLength < ReportConfig.Settings.MinMessageLength then
		ReportUIManager.showNotification(
			"⚠️ Minimal " .. ReportConfig.Settings.MinMessageLength .. " karakter!", 
			Color3.fromRGB(255, 100, 100)
		)
		return
	end

	local success, err = pcall(function()
		SendReport:FireServer(
			UIState.selectedCategory,
			UIState.selectedPlayerId,
			message
		)
	end)

	if success then
		UIState.isOnCooldown = true
		UIState.cooldownEndTime = os.clock() + ReportConfig.Settings.ReportCooldown

		task.delay(ReportConfig.Settings.ReportCooldown, function()
			UIState.isOnCooldown = false
		end)

		ReportUIManager.resetUI()
		ReportUIManager.closeUI()
		ReportUIManager.showNotification("✅ Laporan terkirim!", Color3.fromRGB(100, 255, 100))

		if ReportConfig.Settings.DebugMode then
			print("[ReportClient] Report sent successfully")
		end
	else
		warn("[ReportClient] Failed to send report:", err)
		ReportUIManager.showNotification("❌ Gagal kirim!", Color3.fromRGB(255, 100, 100))
	end
end

function ReportUIManager.resetUI()
	R.messageBox.Text = ""
	if R.categoryButton then R.categoryButton.Text = "Pilih Kategori" end
	if R.playerButton then R.playerButton.Text = "Pilih Pemain" end
	UIState.selectedCategory = nil
	UIState.selectedPlayerId = nil
	UIState.selectedPlayerName = nil
end

function ReportUIManager.closeUI()
	reportUI.Enabled = false
	if R.categoryListFrame then R.categoryListFrame.Visible = false end
	if R.playerListFrame then R.playerListFrame.Visible = false end
end

function ReportUIManager.showNotification(text, color)
	local oldNotif = PlayerGui:FindFirstChild("ReportNotification")
	if oldNotif then oldNotif:Destroy() end

	local notif = Instance.new("ScreenGui")
	notif.Name = "ReportNotification"
	notif.ResetOnSpawn = false
	notif.DisplayOrder = 999
	notif.Parent = PlayerGui

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 320, 0, 70)
	frame.Position = UDim2.new(0.5, -160, 0, -80)
	frame.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
	frame.BorderSizePixel = 0
	frame.Parent = notif

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -30, 1, 0)
	label.Position = UDim2.new(0, 15, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextWrapped = true
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = frame

	frame:TweenPosition(
		UDim2.new(0.5, -160, 0, 30), 
		Enum.EasingDirection.Out, 
		Enum.EasingStyle.Back, 
		0.5, 
		true
	)

	task.delay(3, function()
		if notif and notif.Parent then
			frame:TweenPosition(
				UDim2.new(0.5, -160, 0, -80), 
				Enum.EasingDirection.In, 
				Enum.EasingStyle.Back, 
				0.4, 
				true, 
				function()
					notif:Destroy()
				end
			)
		end
	end)
end

local function onCharacterAdded()
	if not reportUI:GetAttribute("Initialized") then
		task.wait(1)
		if ReportUIManager.init() then
			reportUI:SetAttribute("Initialized", true)
			print("✅ [ReportClient] Report system initialized successfully!")
		else
			warn("❌ [ReportClient] Failed to initialize report system")
		end
	end
end

Player.CharacterAdded:Connect(onCharacterAdded)
if Player.Character then 
	onCharacterAdded() 
end