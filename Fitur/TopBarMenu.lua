-- Fitur TopBarMenuClient By.KDS (Kalyndeus Studio).
-- Developer : Kalyndeus Studio.
-- Dilarang menghapus nama KDS.
-- Dilarang menjual script ini.
--TERIMA KASIH SUDAH BEKERJASAMA DENGAN KDS, SEMOGA SUKSES DALAM MENGEMBANGKAN GAME ANDA.

local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local function getUIReferences()
	return {
		music = PlayerGui:FindFirstChild("MusicUI"),
		emote = PlayerGui:FindFirstChild("EmoteUI"),
		hidden = PlayerGui:FindFirstChild("HiddenUI"),
		report = PlayerGui:FindFirstChild("ReportUI"),
	}
end

local function toggleUI(targetName)
	local refs = getUIReferences()
	local targetUI = refs[targetName]

	if not targetUI or not targetUI:IsA("ScreenGui") then
		warn("[TopBarMenu] UI not found:", targetName)
		return
	end

	local newState = not targetUI.Enabled

	for uiName, ui in pairs(refs) do
		if uiName ~= targetName and ui and ui:IsA("ScreenGui") then
			ui.Enabled = false
		end
	end

	targetUI.Enabled = newState
end

local mainIcon = Icon.new()
	:setLabel("Menu")
	:modifyTheme({"Menu", "MaxIcons", 4})

local musicIcon = Icon.new()
	:setLabel("🎵 Music")

local emoteIcon = Icon.new()
	:setLabel("💃 Emote")

local hiddenIcon = Icon.new()
	:setLabel("👁️ Hidden")

local reportIcon = Icon.new()
	:setLabel("🚨 Report")

mainIcon:setMenu({
	musicIcon,
	emoteIcon,
	hiddenIcon,
	reportIcon,
})

musicIcon.selected:Connect(function()
	toggleUI("music")
end)

emoteIcon.selected:Connect(function()
	toggleUI("emote")
end)

hiddenIcon.selected:Connect(function()
	toggleUI("hidden")
end)

reportIcon.selected:Connect(function()
	toggleUI("report")
end)

print("✅ [TopBarMenu] Main menu loaded successfully!")