-- Fitur EmoteModule By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local EmoteConfig = {}

EmoteConfig.Emotes = {
	-- DANCE CATEGORY
	Dance = {
		{
			Name = "Aura Farm",
			DisplayName = "🕺 Aura Farm Dance",
			AnimationId = "109429734463303",
			Category = "Dance"
		},
		{
			Name = "Belly",
			DisplayName = "💃 Belly Dance",
			AnimationId = "109429734463303",
			Category = "Dance"
		},
		-- Tambahkan dance lain di sini
		-- {
		-- 	Name = "Dance2", -- Nama ini HARUS SAMA dengan nama TextButton di DanceList
		-- 	DisplayName = "Nama Dance", -- Nama yang ditampilkan di UI
		-- 	AnimationId = "Masukan Id Dance Disini",
		-- 	Category = "Dance"
		-- },
	},

	-- EMOTE CATEGORY
	Emote = {
		{
			Name = "Kawai1", 
			DisplayName = "👋 Kawai Wave",
			AnimationId = "10714369325",
			Category = "Emote"
		},
		{
			Name = "Kawai2",
			DisplayName = "😊 Kawai Smile",
			AnimationId = "10714369325",
			Category = "Emote"
		},
		-- Tambahkan emote lain di sini
		-- {
		-- 	Name = "Emote2",  -- Nama ini HARUS SAMA dengan nama TextButton di EmoteList
		-- 	DisplayName = "Nama Emote", -- Nama yang ditampilkan di UI
		-- 	AnimationId = "Masukan Id Emote Disini",
		-- 	Category = "Emote"
		-- },
	}
}

EmoteConfig.Settings = {
	EmoteCooldown = 1,
	AutoCloseUI = false,
	FadeTime = 0.1, 
	AnimationPriority = Enum.AnimationPriority.Action2,
	DebugMode = true,
}

function EmoteConfig:GetAnimationId(emoteName)
	for _, emote in ipairs(self.Emotes.Dance) do
		if emote.Name == emoteName then
			return emote.AnimationId
		end
	end

	for _, emote in ipairs(self.Emotes.Emote) do
		if emote.Name == emoteName then
			return emote.AnimationId
		end
	end

	return nil
end

function EmoteConfig:PrintAllEmotes()
	if self.Settings.DebugMode then
		print("=== All Emotes ===")
		for category, emotes in pairs(self.Emotes) do
			print("Category:", category)
			for _, emote in ipairs(emotes) do
				print("  -", emote.Name, emote.AnimationId)
			end
		end
	end
end

return EmoteConfig