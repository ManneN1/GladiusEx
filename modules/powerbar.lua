local GladiusEx = _G.GladiusEx
local L = LibStub("AceLocale-3.0"):GetLocale("GladiusEx")
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType

local PowerBar = GladiusEx:NewGladiusExModule("PowerBar", true, {
	powerBarAttachTo = "HealthBar",

	powerBarHeight = 15,
	powerBarAdjustWidth = true,
	powerBarWidth = 200,

	powerBarInverse = false,
	powerBarDefaultColor = true,
	powerBarColor = { r = 1, g = 1, b = 1, a = 1 },
	powerBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
	powerBarTexture = "Minimalist",

	powerBarOffsetX = 0,
	powerBarOffsetY = 0,

	powerBarAnchor = "TOPLEFT",
	powerBarRelativePoint = "BOTTOMLEFT",
})

function PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_POWER_FREQUENT", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_MAXPOWER", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_CONNECTION", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_POWER_BAR_SHOW", "UpdatePowerEvent")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE","UpdatePowerEvent")
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED","UpdateColor")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UpdateColor")


	LSM = GladiusEx.LSM

	-- set frame type
	if (GladiusEx.db.healthBarAttachTo == "Frame" or strfind(self.db.powerBarRelativePoint, "BOTTOM")) then
		self.isBar = true
	else
		self.isBar = false
	end

	if (not self.frame) then
		self.frame = {}
	end
end

function PowerBar:OnDisable()
	self:UnregisterAllEvents()

	for unit in pairs(self.frame) do
		self.frame[unit]:SetAlpha(0)
	end
end

function PowerBar:GetAttachTo()
	return self.db.powerBarAttachTo
end

function PowerBar:GetModuleAttachPoints()
	return {
		["PowerBar"] = L["PowerBar"],
	}
end

function PowerBar:GetAttachFrame(unit)
	if not self.frame[unit] then
		self:CreateBar(unit)
	end

	return self.frame[unit]
end

function PowerBar:UpdateColor(event, unit)
	if not GladiusEx:IsHandledUnit(unit) then return end

	local powerType = UnitPowerType(unit)

	-- update bar color
	if self.db.powerBarDefaultColor then
		local color = self:GetBarColor(powerType)
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
	end

	self:UpdatePower(event, unit)
end

function PowerBar:UpdatePowerEvent(event, unit)
	local power, maxPower = UnitPower(unit), UnitPowerMax(unit)
	self:UpdatePower(unit, power, maxPower)
end

function PowerBar:UpdatePower(unit, power, maxPower)
	if (not self.frame[unit]) then return end

	-- update min max values
	self.frame[unit]:SetMinMaxValues(0, maxPower)

	-- inverse bar
	if self.db.powerBarInverse then
		self.frame[unit]:SetValue(maxPower - power)
	else
		self.frame[unit]:SetValue(power)
	end
end

function PowerBar:CreateBar(unit)
	local button = GladiusEx.buttons[unit]
	if (not button) then return end

	-- create bar + text
	self.frame[unit] = CreateFrame("STATUSBAR", "GladiusEx" .. self:GetName() .. unit, button)
	self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. unit .. "Background", "BACKGROUND")
	self.frame[unit].highlight = self.frame[unit]:CreateTexture("GladiusEx" .. self:GetName() .. "Highlight" .. unit, "OVERLAY")
end

function PowerBar:Update(unit)
	local testing = GladiusEx:IsTesting(unit)

	-- get unit powerType
	local powerType
	if (not testing) then
		powerType = UnitPowerType(unit)
	else
		powerType = GladiusEx.testing[unit].powerType
	end

	-- create power bar
	if (not self.frame[unit]) then
		self:CreateBar(unit)
	end

	-- set bar type
	local parent = GladiusEx:GetAttachFrame(unit, self.db.powerBarAttachTo)

	if (GladiusEx.db.healthBarAttachTo == "Frame" or strfind(self.db.powerBarRelativePoint, "BOTTOM")) then
		self.isBar = true
	else
		self.isBar = false
	end

	-- update power bar
	self.frame[unit]:ClearAllPoints()

	local width = self.db.powerBarAdjustWidth and GladiusEx.db.barWidth or self.db.powerBarWidth

	-- add width of the widget if attached to an widget
	if (GladiusEx.db.healthBarAttachTo ~= "Frame" and not strfind(self.db.powerBarRelativePoint, "BOTTOM") and self.db.powerBarAdjustWidth) then
		if (not GladiusEx:GetModule(self.db.powerBarAttachTo).frame[unit]) then
			GladiusEx:GetModule(self.db.powerBarAttachTo):Update(unit)
		end

		width = width + GladiusEx:GetModule(self.db.powerBarAttachTo).frame[unit]:GetWidth()
	end

	self.frame[unit]:SetHeight(self.db.powerBarHeight)
	self.frame[unit]:SetWidth(width)

	self.frame[unit]:SetPoint(self.db.powerBarAnchor, parent, self.db.powerBarRelativePoint, self.db.powerBarOffsetX, self.db.powerBarOffsetY)
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, self.db.powerBarTexture))

	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
	self.frame[unit]:GetStatusBarTexture():SetVertTile(false)

	-- update power bar background
	self.frame[unit].background:ClearAllPoints()
	self.frame[unit].background:SetAllPoints(self.frame[unit])

	self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
	self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())

	self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, self.db.powerBarTexture))

	self.frame[unit].background:SetVertexColor(self.db.powerBarBackgroundColor.r, self.db.powerBarBackgroundColor.g,
		self.db.powerBarBackgroundColor.b, self.db.powerBarBackgroundColor.a)

	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
	self.frame[unit].background:SetVertTile(false)

	-- set color
	if (not self.db.powerBarDefaultColor) then
		local color = self.db.powerBarColor
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
	else
		local color = self:GetBarColor(powerType)
		self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
	end

	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	self.frame[unit].highlight:SetBlendMode("ADD")
	self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
	self.frame[unit].highlight:SetAlpha(0)

	-- hide frame
	self.frame[unit]:SetAlpha(0)
end

function PowerBar:GetBarColor(powerType)
	return PowerBarColor[powerType]
end

function PowerBar:GetBarHeight()
	return self.db.powerBarHeight
end

function PowerBar:Show(unit)
	-- show frame
	self.frame[unit]:SetAlpha(1)

	if (not GladiusEx:IsTesting()) then
		self:UNIT_POWER("UNIT_POWER", unit)
	end
end

function PowerBar:Reset(unit)
	-- reset bar
	self.frame[unit]:SetMinMaxValues(0, 1)
	self.frame[unit]:SetValue(1)

	-- hide
	self.frame[unit]:SetAlpha(0)
end

function PowerBar:Test(unit)
	-- set test values
	local maxPower, power

	-- power type
	local powerType = GladiusEx.testing[unit].powerType

	maxPower = GladiusEx.testing[unit].maxPower
	power = GladiusEx.testing[unit].power

	self:UpdatePower(unit, power, maxPower)
end

function PowerBar:GetOptions()
	return {
		general = {
			type = "group",
			name = L["General"],
			order = 1,
			args = {
				bar = {
					type = "group",
					name = L["Bar"],
					desc = L["Bar settings"],
					inline = true,
					order = 1,
					args = {
						powerBarDefaultColor = {
							type = "toggle",
							name = L["Default color"],
							desc = L["Toggle default color"],
							disabled = function() return not self:IsEnabled() end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							hidden = function() return not GladiusEx.db.advancedOptions end,
							order = 7,
						},
						powerBarColor = {
							type = "color",
							name = L["Color"],
							desc = L["Color of the power bar"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db, info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db, info, r, g, b, a) end,
							disabled = function() return self.db.powerBarDefaultColor or not self:IsEnabled() end,
							order = 10,
						},
						powerBarBackgroundColor = {
							type = "color",
							name = L["Background color"],
							desc = L["Color of the power bar background"],
							hasAlpha = true,
							get = function(info) return GladiusEx:GetColorOption(self.db, info) end,
							set = function(info, r, g, b, a) return GladiusEx:SetColorOption(self.db, info, r, g, b, a) end,
							disabled = function() return not self:IsEnabled() end,
							hidden = function() return not GladiusEx.db.advancedOptions end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						powerBarInverse = {
							type = "toggle",
							name = L["Inverse"],
							desc = L["Invert the bar colors"],
							disabled = function() return not self:IsEnabled() end,
							hidden = function() return not GladiusEx.db.advancedOptions end,
							order = 20,
						},
						powerBarTexture = {
							type = "select",
							name = L["Texture"],
							desc = L["Texture of the power bar"],
							dialogControl = "LSM30_Statusbar",
							values = AceGUIWidgetLSMlists.statusbar,
							disabled = function() return not self:IsEnabled() end,
							order = 25,
						},
					},
				},
				size = {
					type = "group",
					name = L["Size"],
					desc = L["Size settings"],
					inline = true,
					order = 2,
					args = {
						powerBarAdjustWidth = {
							type = "toggle",
							name = L["Adjust width"],
							desc = L["Adjust bar width to the frame width"],
							disabled = function() return not self:IsEnabled() end,
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 13,
						},
						powerBarWidth = {
							type = "range",
							name = L["Width"],
							desc = L["Width of the bar"],
							min = 10, max = 500, step = 1,
							disabled = function() return self.db.powerBarAdjustWidth or not self:IsEnabled() end,
							order = 15,
						},
						powerBarHeight = {
							type = "range",
							name = L["Height"],
							desc = L["Height of the power bar"],
							min = 10, max = 200, step = 1,
							disabled = function() return not self:IsEnabled() end,
							order = 20,
						},
					},
				},
				position = {
					type = "group",
					name = L["Position"],
					desc = L["Position settings"],
					inline = true,
					hidden = function() return not GladiusEx.db.advancedOptions end,
					order = 3,
					args = {
						powerBarAttachTo = {
							type = "select",
							name = L["Attach to"],
							desc = L["Attach to the given frame"],
							values = function() return PowerBar:GetAttachPoints() end,
							set = function(info, value)
								local key = info.arg or info[#info]

								if (strfind(self.db.powerBarRelativePoint, "BOTTOM")) then
									self.isBar = true
								else
									self.isBar = false
								end

								self.db[key] = value
								GladiusEx:UpdateFrames()
							end,
							disabled = function() return not self:IsEnabled() end,
							width = "double",
							order = 5,
						},
						sep = {
							type = "description",
							name = "",
							width = "full",
							order = 7,
						},
						powerBarAnchor = {
							type = "select",
							name = L["Anchor"],
							desc = L["Anchor of the frame"],
							values = function() return GladiusEx:GetPositions() end,
							disabled = function() return not self:IsEnabled() end,
							order = 10,
						},
						powerBarRelativePoint = {
							type = "select",
							name = L["Relative point"],
							desc = L["Relative point of the frame"],
							values = function() return GladiusEx:GetPositions() end,
							disabled = function() return not self:IsEnabled() end,
							order = 15,
						},
						sep2 = {
							type = "description",
							name = "",
							width = "full",
							order = 17,
						},
						powerBarOffsetX = {
							type = "range",
							name = L["Offset X"],
							desc = L["X offset of the frame"],
							min = -100, max = 100, step = 1,
							disabled = function() return  not self:IsEnabled() end,
							order = 20,
						},
						powerBarOffsetY = {
							type = "range",
							name = L["Offset Y"],
							desc = L["X offset of the frame"],
							disabled = function() return not self:IsEnabled() end,
							min = -100, max = 100, step = 1,
							order = 25,
						},
					},
				},
			},
		},
	}
end
