-- Fitur MusicModule By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local MusicConfig = {}

MusicConfig.Settings = {
	DefaultVolume = 0.3, -- Volume awal (0 hingga 1)
	SoundPartName = "MusicSource", 
	SoundParent = game:GetService("Workspace"),
	MaxRetries = 3,
	RetryDelay = 2,
	DebugMode = false, 
}

-- CARA PENGGUNAAN:
-- 1. Tambah Audio ID di sini
-- 2. Nama HARUS SAMA dengan nama Frame/Button di ScrollingFrame
-- 3. Format: ["NamaButton"] = { Name = "Judul", Artist = "Artist", AssetId = "ID" }
--
-- CONTOH:
-- Kalau di ScrollingFrame ada Tombol bernama "Tabol Bale"
-- Maka di sini tulis: ["Tabol Bale"] = { ... }

MusicConfig.Playlist = {
	["Tarot"] = {
		Name = "Tarot",
		Artist = "Unknown Artist",
		AssetId = "114733339924542",
	},
	["Tabola Bale"] = {
		Name = "Tabola Bale", 
		Artist = "Unknown Artist",
		AssetId = "104207837699519",
	},
	["Cincin"] = {
		Name = "Cincin",
		Artist = "Unknown Artist",
		AssetId = "116704380846444", 
	},
	-- Tambahkan lagu lainnya di sini:
	-- ["NamaFrameAnda"] = {
	--     Name = "Judul Lagu",
	--     Artist = "Nama Artist",
	--     AssetId = "AssetIdAudio",
	-- },
}

MusicConfig.InitialSongIndex = nil 

function MusicConfig.GetSongByName(frameName)
	return MusicConfig.Playlist[frameName]
end

function MusicConfig.GetAllSongs()
	return MusicConfig.Playlist
end

function MusicConfig.ValidatePlaylist()
	local validCount = 0
	local invalidSongs = {}

	for frameName, song in pairs(MusicConfig.Playlist) do
		local issues = {}

		if not song.Name or song.Name == "" then
			table.insert(issues, "Missing Name")
		end
		if not song.Artist or song.Artist == "" then
			table.insert(issues, "Missing Artist")
		end
		if not song.AssetId or song.AssetId == "" then
			table.insert(issues, "Missing AssetId")
		end

		if #issues > 0 then
			table.insert(invalidSongs, {
				FrameName = frameName,
				Issues = issues
			})
		else
			validCount = validCount + 1
		end
	end

	if #invalidSongs > 0 then
		warn("[MusicConfig] ⚠️ Found invalid songs:")
		for _, invalid in ipairs(invalidSongs) do
			warn(string.format("  Frame '%s':", invalid.FrameName))
			for _, issue in ipairs(invalid.Issues) do
				warn("    ❌ " .. issue)
			end
		end
	end

	local totalSongs = 0
	for _ in pairs(MusicConfig.Playlist) do
		totalSongs = totalSongs + 1
	end

	if MusicConfig.Settings.DebugMode then
		print(string.format("[MusicConfig] ✅ Valid: %d/%d songs", validCount, totalSongs))
	end

	return validCount == totalSongs, invalidSongs
end

return MusicConfig