--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.API.ActionBar"                            ""
--============================================================================--
namespace                     "EKT"
--============================================================================--

__Recyclable__()
class "ActionButton" (function(_ENV)
  inherit "Frame"
  _ActionButtonCache = setmetatable({}, { __mode = "k"})

  __WidgetEvent__()
  event "OnClick"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------

  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { String, Variable.Rest() }
  function BindAction(self, actionID, ...)
    self.actionArgs = { ... }
  end

  function Reset(self)
    self:SetParent()
    self:ClearAllPoints()
    self:Hide()

    self.id       = nil
    self.order    = nil
    self.category = nil
    self.action   = nil
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"       { TYPE = Number + String }
  property "order"    { TYPE = Number, DEFAULT = 100}
  property "category" { TYPE = String, DEFAULT = "Common" }
  property "action"   { TYPE = String }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { Table }
  function ActionButton(self, frame)
    self.frame = frame

    _ActionButtonCache[self] = true
  end

  __Arguments__ { }
  function ActionButton(self)
    This(self, CreateFrame("Button"))
  end
end)


class "ActionBar" (function(_ENV)
  inherit "BorderFrame"
  _ActionBarCache = setmetatable({}, { __mode = "k"} )

  __WidgetEvent__()
  event "OnMouseDown"

  __WidgetEvent__()
  event "OnMouseUp"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateID(self, new)
    -- Build name from id
    local name = new
    -- Upper the first letter of each word
    name = API:UpperFirstOfEach(name)

    self.name = name
  end

  local function UpdateProps(self, new, old, prop)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "actionbars", self.id) then
      if prop == "buttonCount" then
        Database:SetValue("button-count", new)
      elseif prop == "buttonSize" then
        Database:SetValue("button-size", new)
      elseif prop == "buttonSpacing" then
        Database:SetValue("button-spacing", new)
      elseif prop == "directionGrowth" then
        Database:SetValue("direction-growth", new)
      end
    end
    self:Layout()
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Optional(Number), Variable.Optional(Number), Variable.Optional(Boolean, true) }
  function SetPosition(self, x, y, saveInDB)
    self:ClearAllPoints()

    if x and y then
      -- Ceil values for avoiding some position issues
      x = math.ceil(x)
      y = math.ceil(y)

      self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)
      self.xPos = x
      self.yPos = y
    else
      self:SetPoint("CENTER", UIParent, "CENTER")
    end

    if saveInDB then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "actionbars", self.id) then
        Database:SetValue("xPos", x)
        Database:SetValue("yPos", y)
      end
    end
  end


  __Arguments__ { String + Number }
  function GetButton(self, id)
    for index, button in self.buttons:GetIterator() do
      if type(button.id) == type(id) then
        if button.id == id then
          return button
        end
      end
    end
  end

  __Arguments__ { String + Number }
  function HasButton(self, id)
    local item = GetButton(self, id)
    if item then
      return true
    else
      return false
    end
  end

  function AddButton(self, button)
    self.buttons:Insert(button)

    button:SetParent(self)

    self:Layout()
  end

  __Arguments__ { String }
  function AddButtonCategory(self, categoryID)
    if not self:HasButtonCategory(categoryID) then
      self.categories:Insert(categoryID)
      self:Layout()
    end
  end

  __Arguments__ { String }
  function RemoveButtonCategory(self, categoryID)
    if self:HasButtonCategory(categoryID) then
      self.categories:Remove(categoryID)
    end
  end

  __Arguments__ { String }
  function HasButtonCategory(self, categoryID)
    for index, category in self.categories:GetIterator() do
      if categoryID == category then
        return true
      end
    end

    return false
  end

  __NoCombat__()
  function OnLayout(self)
    local previousFrame
    for index, obj in ActionBars:GetButtons(self.categories):ToList():Sort("x,y=>x.order<y.order"):GetIterator() do
      obj:Hide()
      obj:ClearAllPoints()
      obj:SetParent(self)
      obj.height = self.buttonSize
      obj.width = self.buttonSize

      if index <= self.buttonCount then
        if self.directionGrowth == "RIGHT" then
          if index == 1 then
            obj:SetPoint("TOPLEFT", self.borderWidth, -self.borderWidth)
            obj:SetPoint("BOTTOMLEFT", self.borderWidth, self.borderWidth)
          else
            obj:SetPoint("TOPLEFT", previousFrame, "TOPRIGHT", self.buttonSpacing, 0)
            obj:SetPoint("BOTTOMLEFT", previousFrame, "BOTTOMRIGHT")
          end
        elseif self.directionGrowth == "LEFT" then
          if index == 1 then
            obj:SetPoint("TOPRIGHT", -self.borderWidth, -self.borderWidth)
            obj:SetPoint("BOTTOMRIGHT", -self.borderWidth, self.borderWidth)
          else
            obj:SetPoint("TOPRIGHT", previousFrame, "TOPLEFT", -self.buttonSpacing, 0)
            obj:SetPoint("BOTTOMRIGHT", previousFrame, "BOTTOMLEFT")
          end
        elseif self.directionGrowth == "DOWN" then
          if index == 1 then
            obj:SetPoint("TOPLEFT", self.borderWidth, -self.borderWidth)
            obj:SetPoint("TOPRIGHT", -self.borderWidth, 0)
          else
            obj:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -self.buttonSpacing)
            obj:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT", 0)
          end
        elseif self.directionGrowth == "UP" then
          if index == 1 then
            obj:SetPoint("BOTTOMLEFT", self.borderWidth, self.borderWidth)
            obj:SetPoint("BOTTOMRIGHT", -self.borderWidth, 0)
          else
            obj:SetPoint("BOTTOMLEFT", previousFrame, "TOPLEFT", 0, self.buttonSpacing)
            obj:SetPoint("BOTTOMRIGHT", previousFrame, "TOPRIGHT", 0)
          end
        end
        obj:Show()
      end
      previousFrame = obj.frame
    end

    self:CalculateSize()
  end

  __NoCombat__()
  function CalculateSize(self)
    if self.directionGrowth == "RIGHT" or self.directionGrowth == "LEFT" then
      self.height = self.buttonSize + self.borderWidth * 2
      self.width  = self.buttonSize * self.buttonCount + self.buttonSpacing * (self.buttonCount - 1) + self.borderWidth * 2
    elseif self.directionGrowth == "UP" or self.directionGrowth == "DOWN" then
      self.height = self.buttonSize * self.buttonCount + self.buttonSpacing * (self.buttonCount - 1) + self.borderWidth * 2
      self.width  = self.buttonSize + self.borderWidth * 2
    end
  end

  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function OnSkin(self, flags, target)
    super.OnSkin(self, flags, target)

    if Theme:NeedSkin(self.frame, target) then
      Theme:SkinFrame(self.frame, flags)
      self:SkinBorder(self.frame, flags)
    end
  end

  --- Init the frame (register frames in the theme system and skin them)
  function Init(self)
    local prefix = self:GetClassPrefix()

    Theme:RegisterFrame(prefix.."."..self.id..".frame", self.frame, prefix..".frame")

    Theme:SkinFrame(self.frame)
    self:SkinBorder(self.frame) -- Don't forget to skin border, feature brought by BorderFrame
  end

  function LoadPropsFromDatabase(self)
    -- Load the properties contained in the profile
    Profiles:PrepareDatabase()

    local locked, trackerAnchored, relativePosition, buttonSize, buttonCount, buttonSpacing, directionGrowth, xPos, yPos, show
    if Database:SelectTable(false, "actionbars", self.id) then
      locked                    = Database:GetValue("locked")
      relativePosition          = Database:GetValue("relative-position")
      buttonSize                = Database:GetValue("button-size")
      buttonSpacing             = Database:GetValue("button-spacing")
      buttonCount               = Database:GetValue("button-count")
      directionGrowth           = Database:GetValue("direction-growth")
      show                      = Database:GetValue("show")
      xPos                      = Database:GetValue("xPos")
      yPos                      = Database:GetValue("yPos")
    end

    if show == nil then
      show = true
    end

    if show and not self:IsShown() then
      self:Show()
    elseif not show and self:IsShown() then
      self:Hide()
    end


    self.locked               = locked
    self.trackerAnchored      = trackerAnchored
    self.relativePosition     = relativePosition
    self.buttonSize           = buttonSize
    self.buttonCount          = buttonCount
    self.directionGrowth      = directionGrowth
    self:SetPosition(xPos, yPos, false)
  end

  __Static__() function GetIDFromName(self, name)
    return name:lower()
  end


  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"       { TYPE = String, DEFAULT = "", HANDLER = UpdateID }
  property "name"     { TYPE = String }
  property "xPos"     { TYPE = Number, DEFAULT = 0 }
  property "yPos"     { TYPE = Number, DEFAULT = 0 }
  property "locked"   { TYPE = Boolean, DEFAULT = false }
  property "buttonSize" { TYPE = Number, DEFAULT = 24, HANDLER = UpdateProps }
  property "buttonCount" { TYPE = Number, DEFAULT = 12, HANDLER = UpdateProps }
  property "buttonSpacing" { TYPE = Number, DEFAULT = 2, HANDLER = UpdateProps }
  property "directionGrowth" { TYPE = String, DEFAULT = "RIGHT", HANDLER = UpdateProps}
  __Static__() property "_prefix" { DEFAULT = "action-bar" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { String }
  function ActionBar(self, id)
    local name = string.format("EskaTracker-%sActionBar", id)
    self.id = id

    -- Call our super constructor
    super(self, CreateFrame("Frame", name, UIParent), true)

    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 1, 0, 1)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)
    self:SetParent(UIParent)
    self:SetPoint("CENTER")
    self:GetFrameContainer():EnableMouse(not self.locked)
    self:GetFrameContainer():SetMovable(not self.locked)
    self:GetFrameContainer():SetHeight(50)
    self:GetFrameContainer():SetWidth(300)

    self.OnMouseDown = function(_, button)
      if button == "LeftButton" and not self.locked then
        self:GetFrameContainer():StartMoving()
      end
    end

    self.OnMouseUp = function(_, button)
      if button == "LeftButton" and not self.locked then
        self:GetFrameContainer():StopMovingOrSizing()

        local xPos = self:GetFrameContainer():GetLeft()
        local yPos = self:GetFrameContainer():GetBottom()

        self:SetPosition(xPos, yPos)

        self:GetFrameContainer():SetUserPlaced(false)
      end
    end

    self.buttons = Array[ActionButton]()
    self.categories = List()

    self.OnBorderWidthChanged = self.OnBorderWidthChanged + function(self) self:Layout() end

    Init(self)
  end
end)

class "ButtonCategory" (function(_ENV)
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateActionBar(self, new, old)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "button-categories", self.id) then
      Database:SetValue("action-bar", new)
    end

    if new then
      local newActionBar = ActionBars:Get(new)
      if newActionBar then
        newActionBar:AddButtonCategory(self.id)
        newActionBar:Layout()
      end
      end

    if old then
      local oldActionBar = ActionBars:Get(old)
      if oldActionBar then
        oldActionBar:RemoveButtonCategory(self.id)
        oldActionBar:Layout()
      end

      if new == nil then
        for _, button in ActionBars:GetButtons(self.id):GetIterator() do
          button:ClearAllPoints()
          button:SetParent()
          button:Hide()
        end
      end
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function LoadPropsFromDatabase(self)
    Profiles:PrepareDatabase()
    if Database:SelectTable(false, "button-categories", self.id) then
      self.actionBar = Database:GetValue("action-bar")
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id" { TYPE = String }
  property "name" { TYPE = String, DEFAULT = "" }
  property "actionBar" { TYPE = String, HANDLER = UpdateActionBar }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Rest() }
  function ButtonCategory(self, id, name)
    self.id   = id
    self.name = name
  end
end)


class "ActionBars" (function(_ENV)
  _ACTION_BARS = Dictionary()
  _BUTTON_CATEGORIES = Dictionary()
  _BUTTONS = Array[ActionButton]()
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, String, Variable.Optional(Boolean, true) }
  __Static__() function New(self, id, createTable)
    if not self:Get(id) then
      local actionBar = ActionBar(id)
      self:Register(actionBar, false)

      if createTable then
        Database:SelectRoot()
        if Database:SelectTable(true, "list", "actionbar") then
          Database:SetValue(id, true)
        end
      end


      return actionBar
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, id)
    for _, actionBar in self:GetIterator() do
      if actionBar.id == id then
        return actionBar
      end
    end
  end

  __Arguments__ { ClassType, ActionBar, Variable.Optional(Boolean, true)}
  __Static__() function Register(self, actionBar, needCheck)
    if needCheck and self:Get(actionBar.id) then
      return
    end

    _ACTION_BARS[actionBar.id] = actionBar

    for categoryID, category in ActionBars:IterateButtonCategories() do
      if category.actionBar and actionBar.id == category.actionBar then
        actionBar:AddButtonCategory(categoryID)
      end
    end

    Scorpio.FireSystemEvent("EKT_ACTION_BAR_REGISTERED", actionBar)
  end

  __Arguments__ { ClassType }
  __Static__() function GetIterator()
    return _ACTION_BARS:GetIterator()
  end


  __Arguments__ { ClassType, String }
  __Static__() function Delete(self, id)
    local actionBar = self:Get(id)
    if actionBar then
      actionBar:Hide()
      _ACTION_BARS[id] = nil

      Database:SelectRoot()
      if Database:SelectTable(false, "list", "actionbar") then
        Database:SetValue(id, nil)
      end

      Scorpio.FireSystemEvent("EKT_ACTION_BAR_DELETED", actionBar)
    end
  end

  __Arguments__ { ClassType, ActionButton, Category }
  function AddButton(self, button, category)
    button.category = category
    self:AddButton(button)
  end

  __Arguments__ { ClassType, ActionButton }
  __Static__() function AddButton(self, button)
    _BUTTONS:Insert(button)

    local category = _BUTTON_CATEGORIES[button.category]
    if category.actionBar then
      local actionBar = self:Get(category.actionBar)
      if actionBar then
        actionBar:Layout()
      end
    end

  end

  __Arguments__ {  ClassType, String + Number, String }
  __Static__() function GetButton(self, id, categoryID)
    for index, button in _BUTTONS:Filter(function(button) return button.category == categoryID end):GetIterator() do
      if button.id == id then
        return button
      end
    end
  end

  __Arguments__ { ClassType, String + Number , String }
  __Static__() function HasButton(self, id, categoryID)
    local button = self:GetButton(id, categoryID)
    if button then
      return true
    else
      return false
    end
  end

  __Arguments__ { ClassType, String + Number, String }
  __Static__() function RemoveButton(self, id, categoryID)
    local button = self:GetButton(id, categoryID)

    if not button then
      return
    end

    _BUTTONS:Remove(button)
    button:Recycle()

    local category = self:GetButtonCategory(categoryID)
    if category and category.actionBar then
      local actionBar = self:Get(category.actionBar)
      if actionBar then
        actionBar:Layout()
      end
    end
  end

  __Arguments__ { ClassType, List }
  __Static__() function GetButtons(self, categories)
    return _BUTTONS:Filter(function(button) return categories:Contains(button.category) end)
  end

  __Arguments__ { ClassType, Variable.Rest(String) }
  __Static__() function GetButtons(self, ...)
    return self:GetButtons(List(...))
  end

  __Arguments__ { ClassType, ButtonCategory }
  __Static__() function RegisterButtonCategory(self, category)
    _BUTTON_CATEGORIES[category.id] = category
    category:LoadPropsFromDatabase()

    Scorpio.FireSystemEvent("EKT_BUTTON_CATEGORY_REGISTERED", category)
  end

  __Arguments__ { ClassType, String, String }
  __Static__() function RegisterButtonCategory(self, categoryID, categoryName)
    self:RegisterButtonCategory(ButtonCategory(categoryID, categoryName))
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetButtonCategory(self, id)
    return _BUTTON_CATEGORIES[id]
  end

  __Arguments__ { ClassType }
  __Static__() function IterateButtonCategories()
    return _BUTTON_CATEGORIES:GetIterator()
  end

end)

__Recyclable__()
class "ItemButton" (function(_ENV)
  _ItemButtonCache = setmetatable({}, { __mode = "k"})
  inherit "ActionButton"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateProps(self, new, old, prop)
    if prop == "texture" then
      self.frame.texture:SetTexture(new)
    elseif prop == "link" then
      self:SetItemAttribute(new)
      if new then
        self.frame:SetScript("OnEnter", function(btn)
          GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
          GameTooltip:SetHyperlink(new)
          GameTooltip:Show()
        end)
      else
        self.frame:SetScript("OnEnter", nil)
      end
    end
  end

  __NoCombat__()
  function SetItemAttribute(self, itemLink)
    self.frame:SetAttribute("type", "item")
    self.frame:SetAttribute("item", itemLink)
  end

  function SetCooldown(self, start, duration)
    self.frame.cooldown:SetCooldown(start, duration)
  end

  __Async__()
  function UpdateRange(self)
    local frame = self.frame
    while frame:IsShown() do
      if self.__link and IsItemInRange(self.__link, "target") == false then
        frame.texture:SetVertexColor(1, 0, 0)
      else
        frame.texture:SetVertexColor(1, 1, 1)
      end
      Delay(0.1)
    end
  end

  __Static__() function GetIterator()
    return pairs(_ItemButtonCache)
  end

  function Reset(self)
    super.Reset(self)

    self.link     = nil
    self.texture  = nil
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "link" { HANDLER = UpdateProps }
  property "texture" { HANDLER = UpdateProps }
  __Static__() property "index" { TYPE = Number, DEFAULT = 1}

  function ItemButton(self)
    local name = "EKT-ItemButton"..ItemButton.index
    super(self, CreateFrame("Button", name, nil, "SecureActionButtonTemplate"))

    local texture = self.frame:CreateTexture()
    texture:SetAllPoints()
    texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    self.frame.texture = texture

    local cooldown = CreateFrame("Cooldown", string.format("%sCooldown", name), self.frame, "CooldownFrameTemplate")
    cooldown:SetAllPoints()
    self.frame.cooldown = cooldown


    ItemButton.index = ItemButton.index + 1

    self.frame:SetScript("OnLeave", function(btn) GameTooltip:Hide() end)
    self.frame:SetScript("OnShow", function(btn) UpdateRange(self) end)

    _ItemButtonCache[self] = true
  end
end)



function OnLoad(self)
  -- Register action bar created by the user
  Database:SelectRoot()
  if Database:SelectTable(false, "list", "actionbar") then
    for id in Database:IterateTable() do
      ActionBars:New(id)
    end
  end

  for _, actionBar in ActionBars:GetIterator() do
    actionBar:LoadPropsFromDatabase()
  end

  for categoryID, category in ActionBars:IterateButtonCategories() do
    category:LoadPropsFromDatabase()
  end

  Scorpio.FireSystemEvent("EKT_ACTION_BARS_LOADED")
end


__SystemEvent__()
function BAG_UPDATE_COOLDOWN(...)
  for itemButton in ItemButton:GetIterator() do
    local questID = itemButton.id
    if questID then
      local start, duration, enable = GetQuestLogSpecialItemCooldown(GetQuestLogIndexByID(questID))
      if start then
        CooldownFrame_Set(itemButton.frame.cooldown, start, duration, enable)
        if duration > 0 and enable == 0 then
          itemButton.frame.texture:SetVertexColor(0.4, 0.4, 0.4)
        else
          itemButton.frame.texture:SetVertexColor(1, 1, 1)
        end
      end
    end
  end
end
