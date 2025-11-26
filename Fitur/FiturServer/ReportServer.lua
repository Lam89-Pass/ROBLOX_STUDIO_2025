-- Fitur ReportServer By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReportConfig = require(ReplicatedStorage:WaitForChild("FiturModules"):WaitForChild("ReportConfig"))
local RemoteFitur = ReplicatedStorage:FindFirstChild("RemoteFitur")
if not RemoteFitur then
	RemoteFitur = Instance.new("Folder")
	RemoteFitur.Name = "RemoteFitur"
	RemoteFitur.Parent = ReplicatedStorage
end

local SendReport = RemoteFitur:FindFirstChild("SendReport")
if not SendReport then
	SendReport = Instance.new("RemoteEvent")
	SendReport.Name = "SendReport"
	SendReport.Parent = RemoteFitur
end

local lastReportTime = {}
local reportCount = {}

local function sanitizeInput(text)
	if typeof(text) ~= "string" then return "" end
	text = string.gsub(text, "[%c]", "")
	text = string.gsub(text, "[\"]", "'")
	return text
end

local function sendToDiscord(reporterName, reporterId, category, reportedPlayerName, message)
	local webhookURL, embedColor = ReportConfig.GetWebhookForCategory(category)

	if not webhookURL or webhookURL == "" or webhookURL:find("YOUR_") then
		warn("⚠️ Webhook URL untuk kategori", category, "belum diatur!")
		return false
	end

	reporterName = sanitizeInput(reporterName)
	category = sanitizeInput(category)
	reportedPlayerName = sanitizeInput(reportedPlayerName)
	message = sanitizeInput(message)

	local timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")

	local categoryIcon = "📋"
	local categoryDisplay = category:upper()

	if category == "rusuh" then
		categoryIcon = "🔴"
		categoryDisplay = "RUSUH / TOXIC"
	elseif category == "cheater" then
		categoryIcon = "⚠️"
		categoryDisplay = "CHEATER / EXPLOITER"
	elseif category == "bug" then
		categoryIcon = "🐛"
		categoryDisplay = "BUG / ERROR"
	elseif category == "saran" then
		categoryIcon = "💡"
		categoryDisplay = "SARAN / FEEDBACK"
	end

	local embed = {
		title = categoryIcon .. " LAPORAN BARU - " .. categoryDisplay,
		color = embedColor,
		timestamp = timestamp,
		fields = {
			{
				name = "👤 Pelapor / Reporter",
				value = string.format("**%s**\nUser ID: `%d`", reporterName, reporterId),
				inline = true
			},
			{
				name = "📋 Kategori / Category",
				value = "**" .. categoryDisplay .. "**",
				inline = true
			},
			{
				name = "🎯 Target Pemain / Target Player",
				value = reportedPlayerName,
				inline = false
			},
			{
				name = "💬 Pesan / Message",
				value = "```" .. message .. "```",
				inline = false
			},
			{
				name = "🔗 Server Info",
				value = string.format(
					"Place ID: `%s`\nJob ID: `%s`\n[Join Server](https://www.roblox.com/games/%s/)",
					game.PlaceId,
					game.JobId,
					game.PlaceId
				),
				inline = false
			}
		},
		footer = {
			text = "Server Time • " .. os.date("%d/%m/%Y %H:%M:%S"),
			icon_url = "https://www.roblox.com/favicon.ico"
		}
	}

	local data = {
		username = ReportConfig.Settings.BotName,
		avatar_url = "https://www.roblox.com/favicon.ico",
		embeds = {embed}
	}

	local success, response = pcall(function()
		return HttpService:PostAsync(
			webhookURL, 
			HttpService:JSONEncode(data),
			Enum.HttpContentType.ApplicationJson,
			false
		)
	end)

	if not success then
		warn("⚠️ Gagal mengirim ke Discord:", response)
	end

	return success
end

SendReport.OnServerEvent:Connect(function(player, category, reportedUserId, message)
	if not player or not player.Parent then return end

	local userId = player.UserId

	reportCount[userId] = (reportCount[userId] or 0) + 1
	if reportCount[userId] > 5 then
		task.delay(300, function()
			reportCount[userId] = 0
		end)
		return
	end

	if lastReportTime[userId] and (os.time() - lastReportTime[userId] < ReportConfig.Settings.ReportCooldown) then
		return
	end

	if typeof(category) ~= "string" or category == "" then return end
	if typeof(reportedUserId) ~= "number" then return end
	if typeof(message) ~= "string" then return end

	local messageLength = string.len(message)
	if messageLength < ReportConfig.Settings.MinMessageLength then return end

	if messageLength > ReportConfig.Settings.MaxMessageLength then
		message = string.sub(message, 1, ReportConfig.Settings.MaxMessageLength) .. "..."
	end

	local validCategory = false
	for _, validCat in ipairs(ReportConfig.UICategories) do
		if string.lower(category) == validCat then
			validCategory = true
			break
		end
	end

	if not validCategory then return end

	local reportedPlayerName
	local reportedPlayer = Players:GetPlayerByUserId(reportedUserId)

	if reportedPlayer then
		reportedPlayerName = string.format("**%s**\nUser ID: `%d`", reportedPlayer.Name, reportedUserId)
	else
		if reportedUserId == userId then
			reportedPlayerName = string.format("**Self-Report**\nReporter: %s (ID: `%d`)", player.Name, userId)
		else
			reportedPlayerName = string.format("**Player Tidak Ditemukan**\nUser ID: `%d`\n*(Mungkin sudah keluar)*", reportedUserId)
		end
	end

	local sent = sendToDiscord(player.Name, userId, category, reportedPlayerName, message)

	if sent then
		lastReportTime[userId] = os.time()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	local userId = player.UserId
	lastReportTime[userId] = nil
	reportCount[userId] = nil
end)

if not HttpService.HttpEnabled then
	warn("⚠️ HttpService.HttpEnabled = false. Enable HttpEnabled di Game Settings!")
end

print("✅ ReportServer initialized successfully!")