-- Modified from AceGUIWidget-MultiLineEditBox, just delete the button
local Type, Version = "ECFTextBox", 1
local AceGUI = LibStub("AceGUI-3.0")

-- Lua APIs
local pairs = pairs

-- WoW APIs
local CreateFrame, IsAddOnLoaded, SquareButton_SetIcon = CreateFrame, IsAddOnLoaded, SquareButton_SetIcon
local _G = _G

--------------- Support functions ---------------

local function Layout(self)
	self:SetHeight(self.numlines * 14 + 19 + self.labelHeight)

	if self.labelHeight == 0 then
		self.scrollBar:SetPoint("TOP", self.frame, "TOP", 0, -23)
	else
		self.scrollBar:SetPoint("TOP", self.label, "BOTTOM", 0, -19)
	end

	self.scrollBar:SetPoint("BOTTOM", self.frame, "BOTTOM", 0, 21)
	self.scrollBG:SetPoint("BOTTOMLEFT", 0, 4)
end

--------------- Scripts ---------------

local function OnCursorChanged(self, _, y, _, cursorHeight)	-- EditBox
	self, y = self.obj.scrollFrame, -y
	local offset = self:GetVerticalScroll()
	if y < offset then
		self:SetVerticalScroll(y)
	else
		y = y + cursorHeight - self:GetHeight()
		if y > offset then
			self:SetVerticalScroll(y)
		end
	end
end

local function OnEditFocusLost(self)						-- EditBox
	self:HighlightText(0, 0)
	self.obj:Fire("OnEditFocusLost")
end

local function OnEnter(self)								-- EditBox / ScrollFrame
	self = self.obj
	if not self.entered then
		self.entered = true
		self:Fire("OnEnter")
	end
end

local function OnLeave(self)								-- EditBox / ScrollFrame
	self = self.obj
	if self.entered then
		self.entered = nil
		self:Fire("OnLeave")
	end
end

local function OnMouseUp(self)								-- ScrollFrame
	self = self.obj.editBox
	self:SetFocus()
	self:SetCursorPosition(self:GetNumLetters())
end

local function OnSizeChanged(self, width)					-- ScrollFrame
	self.obj.editBox:SetWidth(width)
end

local function OnTextChanged(self, userInput)				-- EditBox
	if userInput then
		self = self.obj
		self:Fire("OnTextChanged", self.editBox:GetText())
	end
end

local function OnTextSet(self)								-- EditBox
	self:HighlightText(0, 0)
	self:SetCursorPosition(self:GetNumLetters())
	self:SetCursorPosition(0)
end

local function OnVerticalScroll(self, offset)				-- ScrollFrame
	local editBox = self.obj.editBox
	editBox:SetHitRectInsets(0, 0, offset, editBox:GetHeight() - offset - self:GetHeight())
end

local function OnShowFocus(frame)
	frame.obj.editBox:SetFocus()
	frame:SetScript("OnShow", nil)
end

local function OnEditFocusGained(frame)
	AceGUI:SetFocus(frame.obj)
	frame.obj:Fire("OnEditFocusGained")
end

--------------- Methods ---------------

local methods = {
	["OnAcquire"] = function(self)
		self.editBox:SetText("")
		self:SetDisabled(false)
		self:SetWidth(200)
		self:SetNumLines()
		self.entered = nil
		self:SetMaxLetters(0)
	end,

	["OnRelease"] = function(self)
		self:ClearFocus()
	end,

	["SetDisabled"] = function(self, disabled)
		local editBox = self.editBox
		if disabled then
			editBox:ClearFocus()
			editBox:EnableMouse(false)
			editBox:SetTextColor(0.5, 0.5, 0.5)
			self.label:SetTextColor(0.5, 0.5, 0.5)
			self.scrollFrame:EnableMouse(false)
		else
			editBox:EnableMouse(true)
			editBox:SetTextColor(1, 1, 1)
			self.label:SetTextColor(1, 0.82, 0)
			self.scrollFrame:EnableMouse(true)
		end
	end,

	["SetLabel"] = function(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			if self.labelHeight ~= 10 then
				self.labelHeight = 10
				self.label:Show()
			end
		elseif self.labelHeight ~= 0 then
			self.labelHeight = 0
			self.label:Hide()
		end
		Layout(self)
	end,

	["SetNumLines"] = function(self, value)
		if not value or value < 4 then
			value = 4
		end
		self.numlines = value
		Layout(self)
	end,

	["SetText"] = function(self, text)
		self.editBox:SetText(text)
	end,

	["GetText"] = function(self)
		return self.editBox:GetText()
	end,

	["SetMaxLetters"] = function (self, num)
		self.editBox:SetMaxLetters(num or 0)
	end,

	["ClearFocus"] = function(self)
		self.editBox:ClearFocus()
		self.frame:SetScript("OnShow", nil)
	end,

	["SetFocus"] = function(self)
		self.editBox:SetFocus()
		if not self.frame:IsShown() then
			self.frame:SetScript("OnShow", OnShowFocus)
		end
	end,

	["HighlightText"] = function(self, from, to)
		self.editBox:HighlightText(from, to)
	end,

	["GetCursorPosition"] = function(self)
		return self.editBox:GetCursorPosition()
	end,

	["SetCursorPosition"] = function(self, ...)
		return self.editBox:SetCursorPosition(...)
	end,

}

--------------- Constructor ---------------

local backdrop = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 16,
	insets = { left = 4, right = 3, top = 4, bottom = 3 }
}

local function Constructor()
	local frame = CreateFrame("Frame", nil, UIParent)
	frame:Hide()

	local widgetNum = AceGUI:GetNextWidgetNum(Type)

	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4)
	label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -4)
	label:SetJustifyH("LEFT")
	label:SetText(ACCEPT)
	label:SetHeight(10)

	local scrollBG = CreateFrame("Frame", nil, frame)
	scrollBG:SetBackdrop(backdrop)
	scrollBG:SetBackdropColor(0, 0, 0)
	scrollBG:SetBackdropBorderColor(0.4, 0.4, 0.4)

	local scrollFrame = CreateFrame("ScrollFrame", ("%s%dScrollFrame"):format(Type, widgetNum), frame, "UIPanelScrollFrameTemplate")

	local scrollBar = _G[scrollFrame:GetName() .. "ScrollBar"]
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOP", label, "BOTTOM", 0, -19)
	scrollBar:SetPoint("RIGHT", frame, "RIGHT")

	scrollBG:SetPoint("TOPRIGHT", scrollBar, "TOPLEFT", 0, 19)

	scrollFrame:SetPoint("TOPLEFT", scrollBG, "TOPLEFT", 5, -6)
	scrollFrame:SetPoint("BOTTOMRIGHT", scrollBG, "BOTTOMRIGHT", -4, 4)
	scrollFrame:SetScript("OnEnter", OnEnter)
	scrollFrame:SetScript("OnLeave", OnLeave)
	scrollFrame:SetScript("OnMouseUp", OnMouseUp)
	scrollFrame:SetScript("OnSizeChanged", OnSizeChanged)
	scrollFrame:HookScript("OnVerticalScroll", OnVerticalScroll)

	local editBox = CreateFrame("EditBox", ("%s%dEdit"):format(Type, widgetNum), scrollFrame)
	editBox:SetAllPoints()
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetMultiLine(true)
	editBox:EnableMouse(true)
	editBox:SetAutoFocus(false)
	editBox:SetCountInvisibleLetters(false)
	editBox:SetScript("OnCursorChanged", OnCursorChanged)
	editBox:SetScript("OnEditFocusLost", OnEditFocusLost)
	editBox:SetScript("OnEnter", OnEnter)
	editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
	editBox:SetScript("OnLeave", OnLeave)
	editBox:SetScript("OnTextChanged", OnTextChanged)
	editBox:SetScript("OnTextSet", OnTextSet)
	editBox:SetScript("OnEditFocusGained", OnEditFocusGained)

	scrollFrame:SetScrollChild(editBox)

	local widget = {
		editBox     = editBox,
		frame       = frame,
		label       = label,
		labelHeight = 10,
		numlines    = 4,
		scrollBar   = scrollBar,
		scrollBG    = scrollBG,
		scrollFrame = scrollFrame,
		type        = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	editBox.obj, scrollFrame.obj = widget, widget

	return AceGUI:RegisterAsWidget(widget)
end

local function ConstructorHook()
	local widget = Constructor()
	if IsAddOnLoaded("ElvUI") then -- ElvUI Skin, code stolen from ElvUI
		local S = _G["ElvUI"][1]["Skins"]
		local frame = widget.scrollBar
		local name = frame:GetName()
		if _G[name.."ScrollUpButton"] and _G[name.."ScrollDownButton"] then
			local scrollUpWidth, scrollUpHeight = _G[name.."ScrollUpButton"]:GetWidth(), _G[name.."ScrollUpButton"]:GetHeight()
			local scrollDownWidth, scrollDownHeight = _G[name.."ScrollDownButton"]:GetWidth(), _G[name.."ScrollDownButton"]:GetHeight()

			_G[name.."ScrollUpButton"]:StripTextures()
			if not _G[name.."ScrollUpButton"].icon then
				S:HandleNextPrevButton(_G[name.."ScrollUpButton"])
				SquareButton_SetIcon(_G[name.."ScrollUpButton"], 'UP')
				_G[name.."ScrollUpButton"]:Size(scrollUpWidth, scrollUpHeight) --Set size back to what it originally was
			end

			_G[name.."ScrollDownButton"]:StripTextures()
			if not _G[name.."ScrollDownButton"].icon then
				S:HandleNextPrevButton(_G[name.."ScrollDownButton"])
				SquareButton_SetIcon(_G[name.."ScrollDownButton"], 'DOWN')
				_G[name.."ScrollDownButton"]:Size(scrollDownWidth, scrollDownHeight) --Set size back to what it originally was
			end

			if not frame.trackbg then
				frame.trackbg = CreateFrame("Frame", nil, frame)
				frame.trackbg:Point("TOPLEFT", _G[name.."ScrollUpButton"], "BOTTOMLEFT", 0, -1)
				frame.trackbg:Point("BOTTOMRIGHT", _G[name.."ScrollDownButton"], "TOPRIGHT", 0, 1)
				frame.trackbg:SetTemplate("Transparent")
			end

			if frame:GetThumbTexture() then
				frame:GetThumbTexture():SetTexture(nil)
				if not frame.thumbbg then
					frame.thumbbg = CreateFrame("Frame", nil, frame)
					frame.thumbbg:Point("TOPLEFT", frame:GetThumbTexture(), "TOPLEFT", 2, -3)
					frame.thumbbg:Point("BOTTOMRIGHT", frame:GetThumbTexture(), "BOTTOMRIGHT", -2, 3)
					frame.thumbbg:SetTemplate("Default", true, true)
					frame.thumbbg.backdropTexture:SetVertexColor(0.6, 0.6, 0.6)
					if frame.trackbg then
						frame.thumbbg:SetFrameLevel(frame.trackbg:GetFrameLevel())
					end
				end
			end
		end
		frame:Point("RIGHT", widget.frame, "RIGHT", 0 -4)
		if not widget.scrollBG.template then
			widget.scrollBG:SetTemplate('Default')
		end
		widget.scrollBG:Point("TOPRIGHT", frame, "TOPLEFT", -2, 19)
		widget.scrollFrame:Point("BOTTOMRIGHT", widget.scrollBG, "BOTTOMRIGHT", -4, 8)
	end
	return widget
end

AceGUI:RegisterWidgetType(Type, ConstructorHook, Version)