local AceGUI = LibStub("AceGUI-3.0")

-- Lua APIs
local min, max, floor = math.min, math.max, math.floor
local select, pairs, ipairs, type = select, pairs, ipairs, type
local tsort = table.sort

-- WoW APIs
local PlaySound = PlaySound
local UIParent, CreateFrame = UIParent, CreateFrame
local _G = _G

-- Global vars/functions that we don't upvalue since they might get hooked, or upgraded
-- List them here for Mikk's FindGlobals script
-- GLOBALS: CLOSE

local function fixlevels(parent,...)
	local i = 1
	local child = select(i, ...)
	while child do
		child:SetFrameLevel(parent:GetFrameLevel()+1)
		fixlevels(child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

local function fixstrata(strata, parent, ...)
	local i = 1
	local child = select(i, ...)
	parent:SetFrameStrata(strata)
	while child do
		fixstrata(strata, child, child:GetChildren())
		i = i + 1
		child = select(i, ...)
	end
end

do
	local widgetType = "EKT-Dropdown"
	local widgetVersion = 1


	--[[ UI event handler ]]--
	local function Control_OnEnter(this)
		this.obj.button:LockHighlight()
		this.obj:Fire("OnEnter")
	end

	local function Control_OnLeave(this)
		this.obj.button:UnlockHighlight()
		this.obj:Fire("OnLeave")
	end

	local function Dropdown_OnHide(this)
		local self = this.obj
		if self.open then
			self.pullout:Close()
		end
	end

	local function Dropdown_TogglePullout(this)
		local self = this.obj
		PlaySound(856) -- SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
		if self.open then
			self.open = nil
			self.pullout:Close()
			AceGUI:ClearFocus()
		else
			self.open = true
			self.pullout:SetWidth(self.pulloutWidth or self.frame:GetWidth())
			self.pullout:Open("TOPLEFT", self.frame, "BOTTOMLEFT", 0, self.label:IsShown() and -2 or 0)
			AceGUI:SetFocus(self)
		end
	end

	local function OnPulloutOpen(this)
		local self = this.userdata.obj
		local value = self.value

		for i, item in this:IterateItems() do
			if item.SetValue then
				item:SetValue(item.userdata.value == value)
			end
		end

		self.open = true
		self:Fire("OnOpened")
	end

	local function OnPulloutClose(this)
		local self = this.userdata.obj
		self.open = nil
		self:Fire("OnClosed")
	end

	local function OnItemValueChanged(this, event, checked)
		local self = this.userdata.obj

		if checked then
				self:SetValue(this.userdata.value)
				self:Fire("OnValueChanged", this.userdata.value)
		else
				this:SetValue(true)
		end
		if self.open then
				self.pullout:Close()
		end
	end

	local function OnAcquire(self)
		local pullout = AceGUI:Create("Dropdown-Pullout")
		self.pullout = pullout
		pullout.userdata.obj = self
		pullout:SetCallback("OnClose", OnPulloutClose)
		pullout:SetCallback("OnOpen", OnPulloutOpen)
		self.pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		fixlevels(self.pullout.frame, self.pullout.frame:GetChildren())

		self:SetHeight(44)
		self:SetWidth(200)
		self:SetLabel()
		self:SetPulloutWidth(nil)

		self.categoryPullouts = {}
		self.categoryItems = {}
		self.items = {}
	end

	local function OnRelease(self)
		if self.open then
			self.pullout:Close()
		end

		AceGUI:Release(self.pullout)
		self.pullout = nil

		self:SetText("")
		self:SetDisabled(false)

		self.value = nil
		self.open  = nil
		self.hasClose = nil

		self.frame:ClearAllPoints()
		self.frame:Hide()
	end



	local function CreatePullout(self)
		local pullout = AceGUI:Create("Dropdown-Pullout")
		pullout.userdata.obj = self
		pullout:SetCallback("OnClose", OnPulloutClose)
		pullout:SetCallback("OnOpen", OnPulloutOpen)
		pullout.frame:SetFrameLevel(self.frame:GetFrameLevel() + 1)
		fixlevels(pullout.frame, pullout.frame:GetChildren())

		return pullout
	end

	local function SetDisabled(self, disabled)
		self.disabled = disabled
		if disabled then
			self.text:SetTextColor(0.5,0.5,0.5)
			self.button:Disable()
			self.button_cover:Disable()
			self.label:SetTextColor(0.5,0.5,0.5)
		else
			self.button:Enable()
			self.button_cover:Enable()
			self.label:SetTextColor(1,.82,0)
			self.text:SetTextColor(1,1,1)
		end
	end

	-- exported
	local function SetText(self, text)
		self.text:SetText(text or "")
	end

	-- exported
	local function SetLabel(self, text)
		if text and text ~= "" then
			self.label:SetText(text)
			self.label:Show()
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,-14)
			self:SetHeight(40)
			self.alignoffset = 26
		else
			self.label:SetText("")
			self.label:Hide()
			self.dropdown:SetPoint("TOPLEFT",self.frame,"TOPLEFT",-15,0)
			self:SetHeight(26)
			self.alignoffset = 12
		end
	end

	-- exported
	local function SetValue(self, value)
		if self.items then
			self:SetText(self.items[value] or "")
		end
		self.value = value
	end

	-- exported
	--[[local function AddItem(self, value, text, category)
		if category then
			if not self.categoryPullouts[category] then
				local pullout = CreatePullout(self)
				local menuItem = AceGUI:Create("Dropdown-Item-Menu")
				menuItem:SetText(category)
				menuItem.userdata.obj = self
				menuItem:SetMenu(pullout)

				self.items[category] = menuItem
				self.pullout:AddItem(menuItem)

				self.categoryPullouts[category] = pullout
			end
		end

		local item = AceGUI:Create("Dropdown-Item-Execute")
		item:SetText(text)
		item.userdata.obj = self
		item.userdata.value = value

		if category then
			self.categoryPullouts[category]:AddItem(item)
		else
			self.pullout:AddItem(item)
		end
	end--]]

	local function AddItem(self, value, text, category)
		local item = AceGUI:Create("Dropdown-Item-Toggle")
		item:SetText(text)
		item.userdata.obj = self
		item.userdata.value = value
		item:SetCallback("OnValueChanged", OnItemValueChanged)

		if category then
			local pullout = self.categoryPullouts[category]
			if not pullout then
				pullout = CreatePullout(self)
				self.categoryPullouts[category] = pullout

				local menuItem = AceGUI:Create("Dropdown-Item-Menu")
				menuItem:SetText(string.format("|cff00E8FF%s|r", category))
				menuItem.userdata.obj = self
				menuItem:SetMenu(pullout)
				self.pullout:AddItem(menuItem)
			end
			pullout:AddItem(item)
		else
			self.pullout:AddItem(item)
		end

		self.items[value] = text
	end


	-- exported
	local function GetValue(self)
		return self.value
	end

	local function SetPulloutWidth(self, width)
		self.pulloutWidth = width
	end

	--[[ Constructor ]]--
	local function Constructor()
		local count = AceGUI:GetNextWidgetNum(widgetType)
		local frame = CreateFrame("Frame", nil, UIParent)
		local dropdown = CreateFrame("Frame", "AceGUI30EKTDropDown"..count, frame, "UIDropDownMenuTemplate")

		local self = {}
		self.type = widgetType
		self.frame = frame
		self.dropdown = dropdown
		self.count = count
		frame.obj = self
		dropdown.obj = self


		self.OnRelease   = OnRelease
		self.OnAcquire   = OnAcquire

		self.SetText = SetText
		self.SetLabel = SetLabel
		self.SetValue = SetValue
		self.GetValue = GetValue
		self.AddItem  = AddItem
		self.SetPulloutWidth = SetPulloutWidth
		self.SetDisabled = SetDisabled


		self.alignoffset = 26

		frame:SetScript("OnHide",Dropdown_OnHide)

		dropdown:ClearAllPoints()
		dropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",-15,0)
		dropdown:SetPoint("BOTTOMRIGHT",frame,"BOTTOMRIGHT",17,0)
		dropdown:SetScript("OnHide", nil)

		local left = _G[dropdown:GetName() .. "Left"]
		local middle = _G[dropdown:GetName() .. "Middle"]
		local right = _G[dropdown:GetName() .. "Right"]

		middle:ClearAllPoints()
		right:ClearAllPoints()

		middle:SetPoint("LEFT", left, "RIGHT", 0, 0)
		middle:SetPoint("RIGHT", right, "LEFT", 0, 0)
		right:SetPoint("TOPRIGHT", dropdown, "TOPRIGHT", 0, 17)

		local button = _G[dropdown:GetName() .. "Button"]
		self.button = button
		button.obj = self
		button:SetScript("OnEnter",Control_OnEnter)
		button:SetScript("OnLeave",Control_OnLeave)
		button:SetScript("OnClick",Dropdown_TogglePullout)

		local button_cover = CreateFrame("BUTTON",nil,self.frame)
		self.button_cover = button_cover
		button_cover.obj = self
		button_cover:SetPoint("TOPLEFT",self.frame,"BOTTOMLEFT",0,25)
		button_cover:SetPoint("BOTTOMRIGHT",self.frame,"BOTTOMRIGHT")
		button_cover:SetScript("OnEnter",Control_OnEnter)
		button_cover:SetScript("OnLeave",Control_OnLeave)
		button_cover:SetScript("OnClick",Dropdown_TogglePullout)

		local text = _G[dropdown:GetName() .. "Text"]
		self.text = text
		text.obj = self
		text:ClearAllPoints()
		text:SetPoint("RIGHT", right, "RIGHT" ,-43, 2)
		text:SetPoint("LEFT", left, "LEFT", 25, 2)

		local label = frame:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
		label:SetPoint("TOPLEFT",frame,"TOPLEFT",0,0)
		label:SetPoint("TOPRIGHT",frame,"TOPRIGHT",0,0)
		label:SetJustifyH("LEFT")
		label:SetHeight(18)
		label:Hide()
		self.label = label

		AceGUI:RegisterAsWidget(self)
		return self
	end

	AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
