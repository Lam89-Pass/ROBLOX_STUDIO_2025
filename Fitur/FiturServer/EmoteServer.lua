-- Fitur EmoteServer By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RemoteFitur = ReplicatedStorage:WaitForChild("RemoteFitur")
local PlayEmote = RemoteFitur:WaitForChild("PlayEmote")

local FiturModules = ReplicatedStorage:WaitForChild("FiturModules")
local EmoteConfig = require(FiturModules:WaitForChild("EmoteConfig"))

local playerEmotes = {}

PlayEmote.OnServerEvent:Connect(function(player, animationId)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local prevTrack = playerEmotes[player] and playerEmotes[player].Track
	if prevTrack and prevTrack.IsPlaying then
		prevTrack:Stop(EmoteConfig.Settings.FadeTime)
		prevTrack:Destroy()
		playerEmotes[player] = nil
	end

	if not animationId then
		if EmoteConfig.Settings.DebugMode then
			print("[EmoteServer] Stopped emote for", player.Name)
		end
		return 
	end

	if typeof(animationId) ~= "string" or not animationId:match("^%d+$") then
		warn("[EmoteServer] Invalid animation ID:", animationId)
		return
	end

	local animObject = Instance.new("Animation")
	animObject.AnimationId = "rbxassetid://" .. animationId

	local success, animTrack = pcall(function()
		return animator:LoadAnimation(animObject)
	end)

	if success and animTrack then
		animTrack.Priority = EmoteConfig.Settings.AnimationPriority
		animTrack:Play(EmoteConfig.Settings.FadeTime, 1, 1)

		playerEmotes[player] = {
			Track = animTrack,
			AnimationId = animationId
		}

		animTrack.Stopped:Once(function()
			if playerEmotes[player] and playerEmotes[player].Track == animTrack then
				playerEmotes[player] = nil
			end
			animTrack:Destroy()
		end)

		if EmoteConfig.Settings.DebugMode then
			print("[EmoteServer] Playing animation:", animationId, "for", player.Name)
		end
	else
		warn("[EmoteServer] Failed to load animation:", animationId)
	end

	animObject:Destroy()
end)

Players.PlayerRemoving:Connect(function(player)
	local prevTrack = playerEmotes[player] and playerEmotes[player].Track
	if prevTrack then
		prevTrack:Stop()
		prevTrack:Destroy()
	end
	playerEmotes[player] = nil
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		local prevTrack = playerEmotes[player] and playerEmotes[player].Track
		if prevTrack then
			prevTrack:Stop()
			prevTrack:Destroy()
		end
		playerEmotes[player] = nil
	end)
end)

print("[EmoteServer] 🎭 Emote system initialized successfully!")

if EmoteConfig.Settings.DebugMode then
	EmoteConfig:PrintAllEmotes()
end