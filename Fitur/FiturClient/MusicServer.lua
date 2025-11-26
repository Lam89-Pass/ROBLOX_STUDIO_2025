-- Fitur MusicServer By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.

--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local FiturModules = ReplicatedStorage:WaitForChild("FiturModules")
local MusicConfig = require(FiturModules:WaitForChild("MusicConfig"))

local SoundContainer = Workspace
local SoundPart = SoundContainer:FindFirstChild(MusicConfig.Settings.SoundPartName)

if not SoundPart then
	SoundPart = Instance.new("Sound")
	SoundPart.Name = MusicConfig.Settings.SoundPartName
	SoundPart.Parent = SoundContainer

	if MusicConfig.Settings.DebugMode then
		print("[MusicServer] Created new Sound object:", MusicConfig.Settings.SoundPartName)
	end
else
	if MusicConfig.Settings.DebugMode then
		print("[MusicServer] Found existing Sound object:", MusicConfig.Settings.SoundPartName)
	end
end

SoundPart.Volume = MusicConfig.Settings.DefaultVolume
SoundPart.Looped = false
SoundPart.PlayOnRemove = false
SoundPart.RollOffMode = Enum.RollOffMode.Inverse
SoundPart.RollOffMaxDistance = 10000
SoundPart.RollOffMinDistance = 10

if SoundPart.IsPlaying then
	SoundPart:Stop()
end

local CurrentSongName = nil
local CurrentSongData = nil
local isLoadingSong = false
local PlaylistFrameNames = {}

for frameName, _ in pairs(MusicConfig.GetAllSongs()) do
	table.insert(PlaylistFrameNames, frameName)
end
table.sort(PlaylistFrameNames)

if MusicConfig.Settings.DebugMode then
	print("[MusicServer] Loaded playlist with", #PlaylistFrameNames, "songs")
end

local function playSongByName(frameName, retryCount)
	retryCount = retryCount or 0

	if isLoadingSong then
		if MusicConfig.Settings.DebugMode then
			warn("[MusicServer] Already loading a song, skipping")
		end
		return false
	end

	local songData = MusicConfig.GetSongByName(frameName)
	if not songData then
		warn("[MusicServer] Song not found:", frameName)
		return false
	end

	isLoadingSong = true
	CurrentSongName = frameName
	CurrentSongData = songData

	if SoundPart.IsPlaying then
		SoundPart:Stop()
	end

	local assetId = tostring(songData.AssetId):gsub("%s+", "")
	SoundPart.SoundId = "rbxassetid://" .. assetId

	if MusicConfig.Settings.DebugMode then
		print(string.format("[MusicServer] Loading: %s - %s (ID: %s)", songData.Name, songData.Artist, assetId))
	end

	local startTime = tick()
	local timeout = 20

	while not SoundPart.IsLoaded and (tick() - startTime) < timeout do
		task.wait(0.1)
	end

	if not SoundPart.IsLoaded then
		warn(string.format("[MusicServer] Failed to load song: %s (Attempt %d/%d)", frameName, retryCount + 1, MusicConfig.Settings.MaxRetries))
		isLoadingSong = false

		if retryCount < MusicConfig.Settings.MaxRetries then
			task.wait(MusicConfig.Settings.RetryDelay)
			return playSongByName(frameName, retryCount + 1)
		else
			warn("[MusicServer] Max retries reached, skipping to next song")
			local currentIndex = table.find(PlaylistFrameNames, frameName)
			if currentIndex then
				local nextIndex = currentIndex + 1
				if nextIndex > #PlaylistFrameNames then
					nextIndex = 1
				end
				task.wait(1)
				return playSongByName(PlaylistFrameNames[nextIndex], 0)
			end
		end

		return false
	end

	local playSuccess = pcall(function()
		SoundPart:Play()
	end)

	isLoadingSong = false

	if playSuccess then
		if MusicConfig.Settings.DebugMode then
			print(string.format("[MusicServer] ✅ Now playing: %s - %s", songData.Name, songData.Artist))
		end
		return true
	else
		warn("[MusicServer] Failed to play sound:", frameName)
		return false
	end
end

SoundPart.Ended:Connect(function()
	if MusicConfig.Settings.DebugMode then
		print("[MusicServer] Song ended, playing next...")
	end

	if not CurrentSongName then
		playSongByName(PlaylistFrameNames[1])
		return
	end

	local currentIndex = table.find(PlaylistFrameNames, CurrentSongName)
	if currentIndex then
		local nextIndex = currentIndex + 1
		if nextIndex > #PlaylistFrameNames then
			nextIndex = 1
		end
		task.wait(0.5)
		playSongByName(PlaylistFrameNames[nextIndex])
	end
end)

function GetCurrentStatus()
	if not CurrentSongData then
		return {
			Name = "No Song",
			Artist = "N/A",
			AssetId = "0",
			IsPlaying = false,
			TimePosition = 0,
			TimeLength = 0,
			Volume = MusicConfig.Settings.DefaultVolume,
			IsLoaded = false,
		}
	end

	return {
		Name = CurrentSongData.Name,
		Artist = CurrentSongData.Artist,
		AssetId = CurrentSongData.AssetId,
		IsPlaying = SoundPart.IsPlaying,
		TimePosition = SoundPart.TimePosition,
		TimeLength = SoundPart.TimeLength,
		Volume = SoundPart.Volume,
		IsLoaded = SoundPart.IsLoaded,
	}
end

function PlaySongByName(frameName)
	playSongByName(frameName)
end

function PauseResume()
	if SoundPart.IsPlaying then
		SoundPart:Pause()
		if MusicConfig.Settings.DebugMode then
			print("[MusicServer] Paused")
		end
	else
		SoundPart:Play()
		if MusicConfig.Settings.DebugMode then
			print("[MusicServer] Resumed")
		end
	end
end

function SetVolume(newVolume)
	newVolume = math.clamp(newVolume, 0, 1)
	SoundPart.Volume = newVolume

	if MusicConfig.Settings.DebugMode then
		print("[MusicServer] Volume set to:", newVolume)
	end
end

function Seek(timePosition)
	if not SoundPart.IsLoaded or SoundPart.TimeLength == 0 then
		return
	end

	local newTime = math.clamp(timePosition, 0, SoundPart.TimeLength)
	SoundPart.TimePosition = newTime

	if MusicConfig.Settings.DebugMode then
		print("[MusicServer] Seeked to:", newTime)
	end
end

function PlayNext()
	if not CurrentSongName then
		playSongByName(PlaylistFrameNames[1])
		return
	end

	local currentIndex = table.find(PlaylistFrameNames, CurrentSongName)
	if currentIndex then
		local nextIndex = currentIndex + 1
		if nextIndex > #PlaylistFrameNames then
			nextIndex = 1
		end
		playSongByName(PlaylistFrameNames[nextIndex])
	end
end

function PlayPrevious()
	if not CurrentSongName then
		playSongByName(PlaylistFrameNames[#PlaylistFrameNames])
		return
	end

	local currentIndex = table.find(PlaylistFrameNames, CurrentSongName)
	if currentIndex then
		local prevIndex = currentIndex - 1
		if prevIndex < 1 then
			prevIndex = #PlaylistFrameNames
		end
		playSongByName(PlaylistFrameNames[prevIndex])
	end
end

_G.MusicPlayer = {
	PlayByName = PlaySongByName,
	PauseResume = PauseResume,
	SetVolume = SetVolume,
	Seek = Seek,
	Next = PlayNext,
	Previous = PlayPrevious,
	GetStatus = GetCurrentStatus,
	GetSoundPart = function() return SoundPart end,
	GetCurrentSongData = function() return CurrentSongData end,
	GetPlaylistNames = function() return PlaylistFrameNames end,
}

MusicConfig.ValidatePlaylist()
task.wait(2)

if #PlaylistFrameNames > 0 then
	print("[MusicServer] 🎵 Music system initialized successfully!")
	playSongByName(PlaylistFrameNames[1])
else
	warn("[MusicServer] ⚠️ No songs in playlist!")
end