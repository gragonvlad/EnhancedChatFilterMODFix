-- ECF
local addonName, ecf = ...
ecf[1] = {} -- Config
ecf[2] = {} -- Locales
ecf[3] = {} -- Globals
ecf[4] = {} -- AC
ecf.init = {}
local C, L = unpack(ecf)

-- Lua
local ipairs = ipairs
-- WoW
local InterfaceOptionsFrame_OpenToCategory, ShowFriends = InterfaceOptionsFrame_OpenToCategory, ShowFriends
local LibStub = LibStub

-- GLOBALS: SLASH_ECF1

--method run on /ecf
local function ECFOpen()
	InterfaceOptionsFrame_OpenToCategory(addonName)
end
SlashCmdList.ECF = ECFOpen
SLASH_ECF1 = "/ecf"

--MinimapIcon
local ecfLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
	type = "data source",
	text = addonName,
	icon = "Interface\\Icons\\Trade_Archaeology_Orc_BloodText",
	OnClick = ECFOpen,
	OnTooltipShow = function(tooltip) tooltip:AddLine(L["ClickToOpenConfig"]) end
})

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self,event,name)
	if name == addonName then
		self:UnregisterEvent(event)
		for _,f in ipairs(ecf.init) do f() end
		LibStub("LibDBIcon-1.0"):Register(addonName, ecfLDB, C.db.minimap)
		ShowFriends()
	end
end)

--Disable profanityFilter
if GetCVar("profanityFilter")~="0" then SetCVar("profanityFilter", "0") end
