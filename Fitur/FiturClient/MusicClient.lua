-- Fitur MusicLocal By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.

--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local FiturModules = ReplicatedStorage:WaitForChild("FiturModules")
local MusicConfig = require(FiturModules:WaitForChild("MusicConfig"))

local musicUI = nil
local currentVolume = MusicConfig.Settings.DefaultVolume
local progressConnection = nil
local statusUpdateConnection = nil
local lastKnownSongName = nil
local MusicPlayer = nil

local function waitForMusicPlayer()
	local timeout = 10
	local elapsed = 0

	while not _G.MusicPlayer and elapsed < timeout do
		task.wait(0.1)
		elapsed = elapsed + 0.1
	end

	if _G.MusicPlayer then
		MusicPlayer = _G.MusicPlayer
		if MusicConfig.Settings.DebugMode then
			print("[MusicClient] Connected to MusicPlayer API")
		end
	else
		warn("[MusicClient] Failed to connect to MusicPlayer API")
	end
end

waitForMusicPlayer()

local MusicUIManager = {}

local isSeeking = false
local isVolumeChanging = false

local function formatTime(seconds)
	seconds = math.max(0, seconds)
	return string.format("%02d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

function MusicUIManager.init()
	local musicFrame = musicUI:FindFirstChild("Frame")
	if not musicFrame then
		warn("[MusicClient] Frame not found in MusicUI")
		return false
	end

	MusicUIManager.closeButton = musicFrame:FindFirstChild("ClosePanel")
	MusicUIManager.nextButton = musicFrame:FindFirstChild("Next")
	MusicUIManager.prevButton = musicFrame:FindFirstChild("Previous")
	MusicUIManager.volumeSlider = musicFrame:FindFirstChild("VolumeProgres")

	MusicUIManager.pauseButton = musicFrame:FindFirstChild("Pause")
	MusicUIManager.playButton = musicFrame:FindFirstChild("Play")

	MusicUIManager.titleText = musicFrame:FindFirstChild("Judul")
	MusicUIManager.artistText = musicFrame:FindFirstChild("Cover")

	MusicUIManager.progressBar = musicFrame:FindFirstChild("MusicProgress")
	MusicUIManager.timePositionText = musicFrame:FindFirstChild("TimeTextProgresan")
	MusicUIManager.timeLengthText = musicFrame:FindFirstChild("TimeTextAkhir")

	MusicUIManager.playlistToggleButton = musicFrame:FindFirstChild("Playlist")
	MusicUIManager.playlistFrame = musicUI:FindFirstChild("PlayList")

	MusicUIManager.setupDragging(musicFrame)
	if MusicUIManager.playlistFrame then
		MusicUIManager.setupDragging(MusicUIManager.playlistFrame)
	end

	MusicUIManager.setupControls()
	MusicUIManager.setupSeeking()
	MusicUIManager.connectPlaylistButtons()

	musicUI:GetPropertyChangedSignal("Enabled"):Connect(MusicUIManager.onUIEnabledChanged)

	if MusicConfig.Settings.DebugMode then
		print("[MusicClient] UI Manager initialized successfully")
	end

	return true
end

function MusicUIManager.setupDragging(frame)
	if not frame then return end

	local dragging = false
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

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

function MusicUIManager.connectPlaylistButtons()
	if not MusicUIManager.playlistFrame then
		if MusicConfig.Settings.DebugMode then
			warn("[MusicClient] PlayList frame not found")
		end
		return
	end

	local scrollingFrame = MusicUIManager.playlistFrame:FindFirstChild("ScrollingFrame")
	if not scrollingFrame then
		local playlistInnerFrame = MusicUIManager.playlistFrame:FindFirstChild("Frame")
		if playlistInnerFrame then
			scrollingFrame = playlistInnerFrame:FindFirstChild("ScrollingFrame")
		end
	end

	if not scrollingFrame then
		warn("[MusicClient] ScrollingFrame not found in PlayList")
		return
	end

	local buttonCount = 0

	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") or child:IsA("TextButton") then
			local frameName = child.Name
			local songData = MusicConfig.GetSongByName(frameName)

			if songData then
				local button = child:FindFirstChildWhichIsA("TextButton")
				if not button and child:IsA("TextButton") then
					button = child
				end

				if button then
					button.Activated:Connect(function()
						if not MusicPlayer then
							warn("[MusicClient] MusicPlayer not available")
							return
						end

						local success, err = pcall(function()
							MusicPlayer.PlayByName(frameName)
						end)

						if not success then
							warn("[MusicClient] Failed to play song:", err)
						end

						if child:IsA("Frame") then
							child.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
							task.wait(0.2)
							child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						end
					end)

					button.MouseEnter:Connect(function()
						if child:IsA("Frame") then
							child.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
						end
					end)

					button.MouseLeave:Connect(function()
						if child:IsA("Frame") then
							child.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
						end
					end)

					buttonCount = buttonCount + 1
				end
			else
				warn("[MusicClient] No song data found for button:", frameName)
			end
		end
	end

	if MusicConfig.Settings.DebugMode then
		print("[MusicClient] Connected", buttonCount, "playlist buttons")
	end
end

function MusicUIManager.updatePlayPauseIcon(isPlaying)
	if not MusicUIManager.pauseButton or not MusicUIManager.playButton then return end

	MusicUIManager.pauseButton.Visible = isPlaying
	MusicUIManager.playButton.Visible = not isPlaying
end

function MusicUIManager.updateUI(status)
	if not status then return end

	if MusicUIManager.titleText and status.Name then
		MusicUIManager.titleText.Text = status.Name
	end
	if MusicUIManager.artistText and status.Artist then
		MusicUIManager.artistText.Text = status.Artist
	end

	if not isVolumeChanging then
		currentVolume = status.Volume
		local volumeFill = MusicUIManager.volumeSlider and MusicUIManager.volumeSlider:FindFirstChild("Fill")
		if volumeFill then
			volumeFill.Size = UDim2.new(status.Volume, 0, 1, 0)
		end
	end

	MusicUIManager.updatePlayPauseIcon(status.IsPlaying)
	MusicUIManager.startProgressTracking()
end

function MusicUIManager.updateProgress()
	if isSeeking then return end
	if not MusicPlayer then return end

	local soundPart = MusicPlayer.GetSoundPart()
	if not soundPart or not soundPart:IsA("Sound") or not soundPart.IsLoaded then return end

	local currentPosition = soundPart.TimePosition
	local currentLength = soundPart.TimeLength

	if MusicUIManager.progressBar then
		local progressFill = MusicUIManager.progressBar:FindFirstChild("Fill")
		if progressFill and currentLength > 0 then
			progressFill.Size = UDim2.new(currentPosition / currentLength, 0, 1, 0)
		end
	end

	if MusicUIManager.timePositionText then
		MusicUIManager.timePositionText.Text = formatTime(currentPosition)
	end

	if MusicUIManager.timeLengthText then
		MusicUIManager.timeLengthText.Text = formatTime(currentLength)
	end

	MusicUIManager.updatePlayPauseIcon(soundPart.IsPlaying)
end

function MusicUIManager.startProgressTracking()
	if progressConnection then
		progressConnection:Disconnect()
	end

	progressConnection = RunService.Heartbeat:Connect(MusicUIManager.updateProgress)
end

function MusicUIManager.startAutoStatusUpdate()
	if statusUpdateConnection then
		statusUpdateConnection:Disconnect()
	end

	statusUpdateConnection = RunService.Heartbeat:Connect(function()
		if not musicUI or not musicUI.Enabled or not MusicPlayer then
			return
		end

		local status = MusicPlayer.GetStatus()
		if status then
			if status.Name and lastKnownSongName ~= status.Name then
				lastKnownSongName = status.Name
				MusicUIManager.updateUI(status)
			end

			if not isVolumeChanging then
				local volumeFill = MusicUIManager.volumeSlider and MusicUIManager.volumeSlider:FindFirstChild("Fill")
				if volumeFill and status.Volume then
					volumeFill.Size = UDim2.new(status.Volume, 0, 1, 0)
				end
			end

			if status.IsPlaying ~= nil then
				MusicUIManager.updatePlayPauseIcon(status.IsPlaying)
			end
		end
	end)
end

function MusicUIManager.onUIEnabledChanged()
	if musicUI.Enabled then
		if MusicPlayer then
			local status = MusicPlayer.GetStatus()
			if status then
				lastKnownSongName = status.Name
				MusicUIManager.updateUI(status)
				MusicUIManager.startAutoStatusUpdate()
			end
		end
	else
		if progressConnection then
			progressConnection:Disconnect()
			progressConnection = nil
		end
		if statusUpdateConnection then
			statusUpdateConnection:Disconnect()
			statusUpdateConnection = nil
		end
	end
end

function MusicUIManager.setupSeeking()
	local progressBar = MusicUIManager.progressBar
	if not progressBar then return end

	local function handleSeek(input)
		if not MusicPlayer then return end

		local soundPart = MusicPlayer.GetSoundPart()
		if not soundPart or not soundPart:IsA("Sound") or not soundPart.IsLoaded or soundPart.TimeLength == 0 then
			return
		end

		local mouseX = input.Position.X
		local absoluteX = progressBar.AbsolutePosition.X
		local width = progressBar.AbsoluteSize.X

		local seekRatio = math.clamp((mouseX - absoluteX) / width, 0, 1)
		local newTimePosition = seekRatio * soundPart.TimeLength

		local success, err = pcall(function()
			MusicPlayer.Seek(newTimePosition)
		end)

		if not success then
			warn("[MusicClient] Seek failed:", err)
		end

		local progressFill = progressBar:FindFirstChild("Fill")
		if progressFill then
			progressFill.Size = UDim2.new(seekRatio, 0, 1, 0)
		end
		if MusicUIManager.timePositionText then
			MusicUIManager.timePositionText.Text = formatTime(newTimePosition)
		end
	end

	progressBar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			isSeeking = true
			handleSeek(input)
		end
	end)

	progressBar.InputChanged:Connect(function(input)
		if isSeeking and (input.UserInputType == Enum.UserInputType.MouseMovement or 
			input.UserInputType == Enum.UserInputType.Touch) then
			handleSeek(input)
		end
	end)

	progressBar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or 
			input.UserInputType == Enum.UserInputType.Touch then
			isSeeking = false
		end
	end)
end

function MusicUIManager.setupControls()
	if MusicUIManager.pauseButton then
		MusicUIManager.pauseButton.Activated:Connect(function()
			if MusicPlayer then
				pcall(function()
					MusicPlayer.PauseResume()
				end)
			end
		end)
	end

	if MusicUIManager.playButton then
		MusicUIManager.playButton.Activated:Connect(function()
			if MusicPlayer then
				pcall(function()
					MusicPlayer.PauseResume()
				end)
			end
		end)
	end

	if MusicUIManager.nextButton then
		MusicUIManager.nextButton.Activated:Connect(function()
			if MusicPlayer then
				pcall(function()
					MusicPlayer.Next()
				end)
			end
		end)
	end

	if MusicUIManager.prevButton then
		MusicUIManager.prevButton.Activated:Connect(function()
			if MusicPlayer then
				pcall(function()
					MusicPlayer.Previous()
				end)
			end
		end)
	end

	if MusicUIManager.closeButton then
		MusicUIManager.closeButton.Activated:Connect(function()
			musicUI.Enabled = false
		end)
	end

	if MusicUIManager.playlistToggleButton and MusicUIManager.playlistFrame then
		MusicUIManager.playlistFrame.Visible = false

		MusicUIManager.playlistToggleButton.Activated:Connect(function()
			MusicUIManager.playlistFrame.Visible = not MusicUIManager.playlistFrame.Visible
		end)
	end

	local slider = MusicUIManager.volumeSlider
	if slider and slider:IsA("Frame") then
		local volumeFill = slider:FindFirstChild("Fill")
		if volumeFill then
			local function handleVolumeChange(input)
				isVolumeChanging = true

				local mouseX = input.Position.X
				local absoluteX = slider.AbsolutePosition.X
				local width = slider.AbsoluteSize.X

				local newVolume = math.clamp((mouseX - absoluteX) / width, 0, 1)

				volumeFill.Size = UDim2.new(newVolume, 0, 1, 0)
				currentVolume = newVolume

				if MusicPlayer then
					pcall(function()
						MusicPlayer.SetVolume(newVolume)
					end)
				end
			end

			slider.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or
					input.UserInputType == Enum.UserInputType.Touch then
					handleVolumeChange(input)
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if isVolumeChanging and (input.UserInputType == Enum.UserInputType.MouseMovement or
					input.UserInputType == Enum.UserInputType.Touch) then
					handleVolumeChange(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or
					input.UserInputType == Enum.UserInputType.Touch then
					isVolumeChanging = false
				end
			end)
		end
	end
end

local function initializeMusicSystem()
	local newMusicUI = PlayerGui:WaitForChild("MusicUI", 10)
	if not newMusicUI then
		warn("[MusicClient] ❌ MusicUI failed to load")
		return false
	end

	musicUI = newMusicUI

	if newMusicUI:GetAttribute("ClientInitialized") then
		if MusicConfig.Settings.DebugMode then
			print("[MusicClient] Already initialized")
		end
		return true
	end

	local success = MusicUIManager.init()

	if success then
		newMusicUI:SetAttribute("ClientInitialized", true)
		print("[MusicClient] 🎵 Music UI initialized successfully!")
	else
		warn("[MusicClient] Failed to initialize music UI")
	end

	return success
end

local function onCharacterAdded(character)
	task.wait(0.5)

	local success = initializeMusicSystem()

	if success and musicUI then
		musicUI.Enabled = false
	end
end

Player.CharacterAdded:Connect(onCharacterAdded)

if Player.Character then
	onCharacterAdded(Player.Character)
end