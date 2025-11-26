-- Fitur ReportConfig By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local ReportConfig = {}

-- Settings
ReportConfig.Settings = {
	BotName = "Game Moderation System",
	MinMessageLength = 5,
	MaxMessageLength = 500,
	ReportCooldown = 60,
	DebugMode = false,
}

-- WEBHOOK CONFIGURATION
-- Ganti dengan URL Webhooks kalian.
-- CONTOH:
-- Moderation : URL Channel Moderation (Rusuh dan Cheater)
-- Bug Report : URL Channel Bug Report (Laporan Bug)
-- Feedback : URL Channel Feedback (Laporan Saran)

ReportConfig.Webhooks = {
	["Moderation"] = {
		URL = "https://discord.com/api/webhooks/1440304584676606083/KYREcsiBvzzUJMLLbMTHsFzFu7grCN9khk_9-oeu0LYM8Q-f_vALjwAa3O2LeBSXJZ7p",
		Color = 0xFF0000,
		Categories = {"rusuh", "cheater"}
	},
	["BugReport"] = {
		URL = "https://discord.com/api/webhooks/1439598887831732394/pQy1D_I09MFVPFvIWK_iwm6JkVMZD6Zru91PNjXtPZPXMPo1qF7pObu_FXHo-K2yowsQ",
		Color = 0xFF7F00,
		Categories = {"bug"}
	},
	["Feedback"] = {
		URL = "https://discord.com/api/webhooks/1441727334158696588/6MKyaoV-EWci6eY47duG4I9DfcD-okcQu-31H1r2FXec5HjNy7ccGK0hu8rGtOlhZ8o6",
		Color = 0x00FF00,
		Categories = {"saran"}
	}
}

function ReportConfig.GetWebhookForCategory(categoryText)
	local categoryLower = string.lower(categoryText)

	for webhookName, webhookData in pairs(ReportConfig.Webhooks) do
		for _, keyword in ipairs(webhookData.Categories) do
			if string.find(categoryLower, keyword) then
				return webhookData.URL, webhookData.Color
			end
		end
	end

	return ReportConfig.Webhooks["Moderation"].URL, 0xAAAAAA
end

ReportConfig.UICategories = {
	"rusuh",    -- Untuk button yang ada kata "rusuh"
	"cheater",  -- Untuk button yang ada kata "cheater"
	"bug",      -- Untuk button yang ada kata "bug"
	"saran",    -- Untuk button yang ada kata "saran"
}

ReportConfig.CategoryNames = {
	rusuh = "🔴 RUSUH / TOXIC",
	cheater = "⚠️ CHEATER",
	bug = "🐛 BUG / ERROR",
	saran = "💡 SARAN / FEEDBACK",
}

function ReportConfig:IsValidCategory(category)
	for _, validCat in ipairs(self.UICategories) do
		if validCat == category then
			return true
		end
	end
	return false
end

function ReportConfig:GetCategoryDisplayName(category)
	return self.CategoryNames[category] or category:upper()
end

return ReportConfig