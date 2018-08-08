--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                    "EskaTracker.API.Tracker"                          ""
--============================================================================--
namespace                  "EKT"
--============================================================================--
struct "IdleCountdownInfo" (function(_ENV)
  member "countdown" { TYPE = Number, REQUIRE = true }
  member "duration"  { TYPE = Number }
  member "paused"    { TYPE = Boolean, DEFAULT = false}

  function __init(self)
    if self.duration == nil then
      self.duration = self.countdown
    end
  end
end)

class "DisplayRule" ( function(_ENV)
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "ifValue" { TYPE = Stirng, DEFAULT = "" }
  property "condValue" { TYPE = Boolean  }
  property "thenValue" { TYPE = String }
  property "continue" { TYPE = Boolean, DEFAULT = true }
  ------------------------------------------------------------------------------
  --                          Meta-Methods                                    --
  ------------------------------------------------------------------------------
  function __call(self)
    if not self.handler and self.ifValue ~= "" then
      local status = StatusFunctions:Get(self.ifValue)
      if status then
        self.handler = status.func
      end
    end

    if not self.handler then
      return nil
    end

    return self.handler()
  end
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function DisplayRule(self, ifValue, condValue, thenValue, continue)
    self.ifValue = ifValue
    self.condValue = condValue
    self.thenValue = thenValue
    self.continue = continue
  end

end)


Class "Tracker" (function(_ENV)
  inherit "BorderFrame"
  _TrackerCache = setmetatable({}, { __mode = "k"})

  __WidgetEvent__()
  event "OnMouseDown"

  __WidgetEvent__()
  event "OnMouseUp"

  event "OnMove"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  ------------------------------------------------------------------------------
  local function SetContentHeight(self, new, old)
    -- Update the content Size
    self.content:SetHeight(new)

    -- Update the scroll bar visibility
    self:UpdateScrollbarVisibility()
  end

  local function OnWidthChanged(self, new, old)
    self:Layout()

    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("width", new)
      end
    end
  end

  local function OnHeightChanged(self, new, old)
    -- Update the scroll bar visibility
    self:UpdateScrollbarVisibility()

    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("height", new)
      end
    end
  end

  local function UpdateLock(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("locked", new)
      end
    end

    --self:GetFrameContainer():EnableMouse(true)
    self:GetFrameContainer():SetMovable(not new)
  end


  local function UpdateShowScrollbar(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        if new then
          Database:SetValue("showScrollbar", true)
        else
          Database:SetValue("showScrollbar", nil)
        end
      end
    end

    -- Update the scroll bar visibility
    self:UpdateScrollbarVisibility()
  end

  local function UpdateID(self, new)
    -- Build name from id
    local name = new
    -- Upper the first letter of each word
    name = API:UpperFirstOfEach(name)

    self.name = name
  end

  function EnableNotifications(self)
    self.OnNotificationHeightHandler = function(_, new, old)
      self.contentHeight = self.contentHeight + (new - old)
      self:Layout()
    end

    self.OnNotificationAddedHandler = function(notifications)
      self:AddIdleCountdown(notifications, nil, true)
    end

    self.OnNotificationRemovedHandler = function(notifications)
      if notifications.notificationCount == 0 then
        self:ResumeIdleCountdown(notifications)
      end
    end

    Notifications().OnHeightChanged = Notifications().OnHeightChanged + self.OnNotificationHeightHandler
    Notifications().OnNotificationAdded = Notifications().OnNotificationAdded + self.OnNotificationAddedHandler
    Notifications().OnNotificationRemoved = Notifications().OnNotificationRemoved + self.OnNotificationRemovedHandler

    Notifications():ClearAllPoints()
    Notifications():SetParent(self.content)
    Notifications():SetPoint("TOP")
    Notifications():SetPoint("LEFT")
    Notifications():SetPoint("RIGHT")

    self.displayNotifications = true

    self:Layout()

    Notifications():CalculateHeight()

    if Notifications().notificationCount > 0 then
      self:AddIdleCountdown(Notifications(), nil, true)
    end
  end


  function DisableNotifications(self)
    if self.OnNotificationHeightHandler then
      Notifications().OnHeightChanged = Notifications().OnHeightChanged - self.OnNotificationHeightHandler
    end

    if self.OnNotificationAddedHandler then
      Notifications().OnNotificationAdded = Notifications().OnNotificationAdded - self.OnNotificationAddedHandler
    end

    if self.OnNotificationRemovedHandler then
      Notifications().OnNotificationRemoved = Notifications().OnNotificationRemoved - self.OnNotificationRemovedHandler
    end

    Notifications():ClearAllPoints()
    Notifications():SetParent()

    self.displayNotifications = false

    self:Layout()

    self:ResumeIdleCountdown(Notifications())
  end


  local function Tracker_OnScrollRangeChanged(self, xrange, yrange)
    local name = self:GetName();
    local scrollbar = self.ScrollBar or _G[name.."ScrollBar"];
    if ( not yrange ) then
      yrange = self:GetVerticalScrollRange();
    end

    -- Accounting for very small ranges
    yrange = floor(yrange);

    local value = min(scrollbar:GetValue(), yrange);
    scrollbar:SetMinMaxValues(0, yrange);
    scrollbar:SetValue(value);

    local scrollDownButton = scrollbar.ScrollDownButton or _G[scrollbar:GetName().."ScrollDownButton"];
    local scrollUpButton = scrollbar.ScrollUpButton or _G[scrollbar:GetName().."ScrollUpButton"];
    local thumbTexture = scrollbar.ThumbTexture or _G[scrollbar:GetName().."ThumbTexture"];

    if ( yrange == 0 ) then
      if ( self.scrollBarHideable ) then
        scrollbar:Hide();
        scrollDownButton:Hide();
        scrollUpButton:Hide();
        thumbTexture:Hide();
      else
        scrollDownButton:Disable();
        scrollUpButton:Disable();
        scrollDownButton:Show();
        scrollUpButton:Show();
        if ( not self.noScrollThumb ) then
          thumbTexture:Show();
        end
      end
    else
      scrollDownButton:Show();
      scrollUpButton:Show();
      --scrollbar:Show();
      if ( not self.noScrollThumb ) then
        thumbTexture:Show();
      end
      -- The 0.005 is to account for precision errors
      if ( yrange - value > 0.005 ) then
        scrollDownButton:Enable();
      else
        scrollDownButton:Disable();
      end
    end

    -- Hide/show scrollframe borders
    local top = self.Top or name and _G[name.."Top"];
    local bottom = self.Bottom or name and _G[name.."Bottom"];
    local middle = self.Middle or name and _G[name.."Middle"];
    if ( top and bottom and self.scrollBarHideable ) then
      if ( self:GetVerticalScrollRange() == 0 ) then
        top:Hide();
        bottom:Hide();
      else
        top:Show();
        bottom:Show();
      end
    end
    if ( middle and self.scrollBarHideable ) then
      if ( self:GetVerticalScrollRange() == 0 ) then
        middle:Hide();
      else
        middle:Show();
      end
    end
  end
  ------------------------------------------------------------------------------
  --                        Idle. Methods                                     --
  ------------------------------------------------------------------------------
  local function IsInIdleModeChanged(self, new)
    if new then
      self:SetAlpha(self.idleModeAlpha)
    else
      self:SetAlpha(1.0)
    end
  end

  local function InactivityTimerChanged(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("inactivity-timer", new)
      end
    end

    if self.idleCountdowns then
      for id, info in pairs(self.idleCountdowns) do
        if id == self and info.countdown > new then
          info.countdown = new
        end
      end
    end
  end

  local function IdleModeEnabledChanged(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("idle-mode-enabled", new)
      end
    end

    if new then
      --self:AddIdleCountdown(self, self.inactivityTimer)
      --self:StartInactivityTimer()

      IdleMode:AddCountdown(self, self)
      IdleMode:EnableForTracker(self)
    else
      --self:ClearIdleCountdowns()
      IdleMode:DisableForTracker(self)
    end
      --self.isInIdleMode = false
  end

  local function IdleModeAlphaChanged(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("idle-mode-alpha", new)
      end
    end

    if self.isInIdleMode then
      self:SetAlpha(new)
    end
  end

  function OnWakeUp(self)
    self.isInIdleMode = false
    --self:StartInactivityTimer()
  end


  __Arguments__ { Any, Number, Variable.Optional(Number), Variable.Optional(Boolean) }
  function AddIdleCountdown(self, id, countdown, duration, paused)
    self:AddIdleCountdown(id, IdleCountdownInfo(countdown, duration, paused))
  end

  __Arguments__ { Any, IdleCountdownInfo }
  function AddIdleCountdown(self, id, countdownInfo)
    if not self.idleCountdowns then
      self.idleCountdowns = Dictionary()
    end

    self.idleCountdowns[id] = countdownInfo
  end


  __Arguments__ { Variable.Optional(Any), Variable.Optional(Number), Variable.Optional(Boolean) }
  function AddIdleCountdown(self, id, duration, paused)
    id = id or self
    IdleMode:AddCountdown(self, id, duration, paused)
  end

  __Arguments__ { Variable.Optional(Any) }
  function ResumeIdleCountdown(self, id)
    id = id or self

    IdleMode:ResumeCountdown(self, id)
  end

  __Arguments__ { Variable.Optional(Any) }
  function PauseIdleCountdown(self, id)
    id = id or self

    IdleMode:PauseCountdown(self, id)
  end

  __Arguments__ { Boolean }
  function OnHover(self, hover)
    super.OnHover(self, hover)

    if hover then
      IdleMode:AddCountdown(self, "hover", 3, true)
    else
      IdleMode:ResumeCountdown(self, "hover")
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function UpdateScrollbarVisibility(self)
    -- Check if the scrollbar is needed or not
    local parentHeight = self.scrollFrame:GetHeight()
    local isNeeded     = self.contentHeight >= parentHeight
    -- Check if a change has occured for avoiding useless layout
    local wasShown = self.scrollbar:IsShown()
    local isShown
    if isNeeded and self.showScrollbar then
      self.scrollbar:Show()
      isShown = true
    else
      self.scrollbar:Hide()
      isShown = false
    end

    if wasShown ~= isShown then
      self:ForceLayout()
      Scorpio.FireSystemEvent("EKT_SCROLLBAR_VISIBILITY_CHANGED", self.id)
    end
  end

  function OnLayout(self)
    self.content:ClearAllPoints()
    self.content:SetPoint("TOP")
    self.content:SetPoint("LEFT")

    if self.scrollbar:IsShown() then
      self.content:SetWidth(API:Round(self.frame:GetWidth() - self.scrollbar:GetWidth()))
    else
      self.content:SetWidth(API:Round(self.frame:GetWidth()))
    end

    local displayNotifications = self.displayNotifications and Notifications():IsShown()

    local previousFrame
    for index, obj in self.blocks:Sort("x,y=>x.order<y.order"):GetIterator() do
      obj:Hide()
      obj:ClearAllPoints()

      if index == 1 then
        if displayNotifications then
          obj:SetPoint("TOP", Notifications(), "BOTTOM")
        else
          obj:SetPoint("TOP")
        end
        obj:SetPoint("LEFT")
        obj:SetPoint("RIGHT")
      else
        obj:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -4)
        obj:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
      end

      previousFrame = obj.frame
      obj:Show()
    end

    self:CalculateHeight()
  end

  function CalculateHeight(self)
    local height = 0

    for index, obj in self.blocks:GetIterator() do
      if index == 1 then
        height = obj.height
      else
        height = height + 4 + obj.height
      end
    end

    self.contentHeight = height
  end


  __Arguments__ { Variable.Optional(Number), Variable.Optional(Number), Variable.Optional(Boolean, true) }
  function SetPosition(self, x, y, saveInDB)

    self:ClearAllPoints()

    if x and y then
      -- Ceil the values for avoiding some position issue
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
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("xPos", x)
        Database:SetValue("yPos", y)
      end
    end
  end


  __Arguments__ { Block }
  function AddBlock(self, block)
    if not self.blocks:Contains(block) then
      self.blocks:Insert(block)
      block:SetParent(self.content)

      block.OnHeightChanged = function(block, new, old)
        self.contentHeight = self.contentHeight + (new - old)
      end

      block.OnOrderChanged = function(block, new, old)
        self:Layout()
      end

    end

    self:Layout()
  end

  __Arguments__ { Block }
  function RemoveBlock(self, block)
    self.blocks:Remove(block)
    block:Hide()
    block.OnHeightChanged = nil
    block.OnOrderChanged  = nil

    self:ForceLayout()

    return block
  end

  __Arguments__ { String }
  function RemoveBlockByCategoryID(self, bCategoryID)
    local block = self:GetBlockByCategoryID(bCategoryID)
    return RemoveBlock(self, block)
  end

  function GetBlockByCategoryID(self, bCategoryID)
    for index, block in self.blocks:GetIterator() do
      if bCategoryID == API:GetDefaultValueFromObj(block, "category") then
        return block
      end
    end
  end

  function GetBlocks(self)
    return self.blocks
  end

  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function OnSkin(self, flags, target)
    -- Call our super 'OnSkin'
    super.OnSkin(self, flags, target)
    -- Get the current state
    local state = self:GetCurrentState()

    if Theme:NeedSkin(self.frame, target) then
      Theme:SkinFrame(self.frame, flags, state)
      self:SkinBorder(self.frame, flags, state)
    end

    if Theme:NeedSkin(self.scrollbar, target) then
      Theme:SkinFrame(self.scrollbar, flags, state)
    end

    if Theme:NeedSkin(self.scrollbar.thumb, target) then
      Theme:SkinTexture(self.scrollbar.thumb, flags, state)
    end

  end

  function GetCurrentState(self)
    if self.isInIdleMode and self.idleModeEnabled and not self.idleModePaused then
      return "idle"
    end
  end

  --- Init the frame (register frames in the theme system and skin them)
  function Init(self)
    local prefix = self:GetClassPrefix()

    Theme:RegisterFrame(prefix.."."..self.id..".frame", self.frame, prefix..".frame")
    Theme:RegisterFrame(prefix.."."..self.id..".scrollbar", self.scrollbar, prefix..".scrollbar")
    Theme:RegisterTexture(prefix.."."..self.id..".scrollbar.thumb", self.scrollbar.thumb, prefix..".scrollbar.thumb")

    Theme:SkinFrame(self.frame)
    self:SkinBorder(self.frame) -- Don't forget to skin border, feature brought by BorderFrame
    Theme:SkinFrame(self.scrollbar)
    Theme:SkinTexture(self.scrollbar.thumb)

    self:SetPosition(nil, nil, false)

  end

  __Arguments__ { DisplayRule, Variable.Optional(Boolean, false) }
  function AddDisplayRule(self, rule, silent)
    self.displayRules:Insert(rule)

    if not self.dbReadOnly then
      self:SaveDisplayRules()
    end

    if not silent then
      Scorpio.FireSystemEvent("EKT_TRACKER_DISPLAY_RULE_ADDED")
    end
  end

  __Arguments__ { DisplayRule, Variable.Optional(Boolean, false) }
  function RemoveDisplayRule(self, rule, silent)
    self.displayRules:Remove(rule)

    if not self.dbReadOnly then
      self:SaveDisplayRules()
    end

    if not silent then
      Scorpio.FireSystemEvent("EKT_TRACKER_DISPLAY_RULE_REMOVED", rule)
    end
  end


  function LoadDisplayRules(self)
    -- Database Read Only for avoiding the properties writing during the loading.
    self.dbReadOnly = true

    -- Load the properties value contained in the profile
    Profiles:PrepareDatabase()

    if Database:SelectTable(false, "trackers", self.id, "display-rules") then
      for index, rule in Database:IterateTable() do
        self:AddDisplayRule(DisplayRule(rule.ifValue, rule.condValue, rule.thenValue, rule.continue), true)
      end
    end

    -- remove the read only mode for Database
    self.dbReadOnly = false
  end

  function SaveDisplayRules(self)
    if not self.dbReadOnly then
      -- Prepare the database
      Profiles:PrepareDatabase()

      if Database:SelectTable("trackers", self.id) then
        Database:SetValue("display-rules", {})
        if Database:SelectTable("display-rules") then
          for index, rule in self.displayRules:GetIterator() do
            Database:SetValue(index, {
              ifValue = rule.ifValue,
              condValue = rule.condValue,
              thenValue = rule.thenValue,
              continue = rule.continue,
            })
          end
        end
      end
    end
  end

  __Arguments__ { DisplayRule }
  function SaveDisplayRule(self, rule)
    if not self.dbReadOnly then

      local ruleIndex = self.displayRules:IndexOf(rule)

      -- Prepare the database
      Profiles:PrepareDatabase()

      if Database:SelectTable("trackers", self.id, "display-rules") then
        Database:SetValue(ruleIndex, {
          ifValue = rule.ifValue,
          condValue = rule.condValue,
          thenValue = rule.thenValue,
          continue = rule.continue,
        })
      end
    end
  end

  __Arguments__ { Number }
  function SaveDisplayRule(self, index)
    self:SaveDisplayRule(self.displayRules[index])
  end

  function GetDisplayRules(self)
    return self.displayRules
  end

  function UpDisplayRuleOrder(self, rule)
    local ruleIndex = self.displayRules:IndexOf(rule)

    if not ruleIndex and ruleIndex == 1 then
      return
    end

    -- Get the rule which will be replaced
    local replacedRule = self.displayRules[ruleIndex-1]

    if not replacedRule then
      return
    end

    self.displayRules[ruleIndex-1] = rule
    self.displayRules[ruleIndex] = replacedRule

    self:SaveDisplayRules()

    Scorpio.FireSystemEvent("EKT_TRACKER_DISPLAY_RULE_ORDER_CHANGED", self)
  end

  function DownDisplayRuleOrder(self, rule)
    local ruleIndex = self.displayRules:IndexOf(rule)

    if not ruleIndex and ruleIndex == self.displayRules.Count then
      return
    end

    -- Get the rule which will be replaced
    local replacedRule = self.displayRules[ruleIndex+1]

    if not replacedRule then
      return
    end

    self.displayRules[ruleIndex+1] = rule
    self.displayRules[ruleIndex] = replacedRule

    self:SaveDisplayRules()

    Scorpio.FireSystemEvent("EKT_TRACKER_DISPLAY_RULE_ORDER_CHANGED", self)
  end

  function LoadPropsFromDatabase(self)
    -- Database Read Only for avoiding the properties writing during the loading.
    self.dbReadOnly = true

    -- Load the properties value contained in the profile
    Profiles:PrepareDatabase()

    if Database:SelectTable(false, "trackers", self.id) then
      self.height               = Database:GetValue("height") or 325
      self.width                = Database:GetValue("width") or 300
      self.locked               = Database:GetValue("locked")
      self.enabled              = Database:GetValue("enabled")
      self.showScrollbar        = Database:GetValue("showScrollbar")
      self.idleModeAlpha        = Database:GetValue("idle-mode-alpha")
      self.inactivityTimer      = Database:GetValue("inactivity-timer")
      self.idleModeEnabled      = Database:GetValue("idle-mode-enabled")
      self.displayRulesType     = Database:GetValue("display-rules-type")
      self.displayMacro         = Database:GetValue("display-macro")
      self.displayFunction      = Database:GetValue("display-function")
      self.defaultDisplayState  = Database:GetValue("default-display-state")
      self:SetPosition(Database:GetValue("xPos"), Database:GetValue("yPos"), false)
    end

    self:RunDisplayRulesTicker()

    -- remove the read only mode for Database
    self.dbReadOnly = false
  end

  __Static__() function GetIDFromName(self, name)
    return name:lower()
  end

  local function UpdateEnabled(self, new)
    if not self.dbReadOnly then
      Profiles:PrepareDatabase()
      if Database:SelectTable(false, "trackers", self.id)  then
        Database:SetValue("enabled", new)
      end
    end

    if new then
      self:RunDisplayRulesTicker()
    else
      self:Hide()
    end
  end

  local function UpdateDisplayProps(self, new, old, prop)
    Profiles:PrepareDatabase()
    if Database:SelectTable("trackers", self.id) then
      local id
      if prop == "displayRulesType" then
        id = "display-rules-type"
      elseif prop == "displayFunction" then
        id = "display-function"
        self:BuildDisplayFunctionCache()
      elseif prop == "displayMacro" then
        id = "display-macro"
      elseif prop == "defaultDisplayState" then
        id = "default-display-state"
      end

      if id and not self.dbReadOnly then
        Database:SetValue(id, new)
      end
    end
  end

  function GetDisplayByFunction(self)
    local show
    if self.displayFunctionCache then
      show = self.displayFunctionCache()
    end

    if show == nil then
      show = self.defaultDisplayState
    end

    return show
  end

  function GetDisplayByMacro(self)
    local show
    local result = SecureCmdOptionParse(self.displayMacro)
    if result then
      if result == "show" then
        show = true
      elseif result == "hide" then
        show = false
      end
    end

    if show == nil then
      show = self.defaultDisplayState
    end

    return show
  end

  function GetDisplayByPredefined(self)
    for _, rule in self.displayRules:GetIterator() do
      local statusValue = rule()
      local isChecked
      if statusValue == nil then
        isChecked = false
      else
        isChecked = (statusValue == rule.condValue)
      end

      if isChecked then
        if rule.thenValue == "hide-tracker" then
          return false
        elseif rule.thenValue == "show-tracker" then
          return true
        end
      end

      if not rule.continue then
        if self.defaultDisplayState == "hide" then
          return false
        elseif self.defaultDisplayState == "show" then
          return true
        end
      end
    end

    if self.defaultDisplayState == "hide" then
      return false
    elseif self.defaultDisplayState == "show" then
      return true
    end
  end

  __Async__()
  function RunDisplayRulesTicker(self)
    if not self.__displayRulesTickerRunning then
      self.__displayRulesTickerRunning = true
      while self.enabled do
        local show
        if self.displayRulesType == "function-type" then
          show = self:GetDisplayByFunction()
        elseif self.displayRulesType == "macro-type" then
          show = self:GetDisplayByMacro()
        elseif self.displayRulesType == "predefined-type" then
          show = self:GetDisplayByPredefined()
        end

        if show then
          self:ForceShow()
        else
          self:ForceHide()
        end

        Delay(0.1)
      end
    end
    self.__displayRulesTickerRunning = nil
  end

  function BuildDisplayFunctionCache(self)
    self.displayFunctionCache = assert(loadstring("return " .. self.displayFunction))()
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"                           { TYPE = String, DEFAULT = "", HANDLER = UpdateID }
  property "name"                         { TYPE = String }
  property "enabled"                      { TYPE = Boolean, DEFAULT = true, HANDLER = UpdateEnabled }
  property "xPos"                         { TYPE = Number, DEFAULT = 0 }
  property "yPos"                         { TYPE = Number, DEFAULT = 0 }
  property "locked"                       { TYPE = Boolean, DEFAULT = false,  HANDLER = UpdateLock }
  property "contentHeight"                { TYPE = Number, DEFAULT = 50, HANDLER = SetContentHeight }
  property "displayNotifications"         { TYPE = Boolean, DEFAULT = false }
  property "showScrollbar"                { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateShowScrollbar }
  property "isInIdleMode"                 { TYPE = Boolean, DEFAULT = false, HANDLER = IsInIdleModeChanged }
  property "inactivityTimer"              { TYPE = Number, DEFAULT = 20, HANDLER = InactivityTimerChanged }
  property "idleModeEnabled"              { TYPE = Boolean, DEFAULT = false, HANDLER = IdleModeEnabledChanged }
  property "idleModeAlpha"                { TYPE = Number, DEFAULT = 0.35, HANDLER = IdleModeAlphaChanged }
  --- Display conditionals
  property "defaultDisplayState"          { TYPE = String, DEFAULT = "show", HANDLER = UpdateDisplayProps }
  property "displayRulesType"             { TYPE = String, DEFAULT = "predefined-type", HANDLER = UpdateDisplayProps }
  property "displayMacro"                 { TYPE = String, DEFAULT = "show", HANDLER = UpdateDisplayProps }
  property "displayFunction"              { TYPE = String, DEFAULT = [[function() return true end]],  FIELD = "__displayFunction", HANDLER = UpdateDisplayProps }

  __Static__() property "_prefix"         { DEFAULT = "tracker"}
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { String }
  function Tracker(self, id)
    local name = string.format("EskaTracker-%s", id)
    self.id = id
    self.width = 300
    self.height = 325

    -- Call our super constructor
    super(self, CreateFrame("Frame", name, UIParent))

    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 1, 0, 1)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)
    self:SetParent(UIParent)
    self:GetFrameContainer():SetClampedToScreen(true)
    self:GetFrameContainer():SetFrameStrata("LOW")
    self:GetFrameContainer():SetHeight(200)
    self:GetFrameContainer():SetWidth(200)
    self:SetPoint("CENTER")
    --self:GetFrameContainer():EnableMouse(not self.locked)
    self:GetFrameContainer():SetMovable(not self.locked)

    self.OnMouseDown = function(_, button)
      if button == "LeftButton" and not self.locked then
        self:GetFrameContainer():StartMoving()
        self:OnMove()
      end
    end

    self.OnMouseUp = function(_, button)
      if button == "LeftButton" and not self.locked then
        self:GetFrameContainer():StopMovingOrSizing()
        self:OnMove()

        local xPos = self:GetFrameContainer():GetLeft()
        local yPos = self:GetFrameContainer():GetBottom()
        self:SetPosition(xPos, yPos)

        self:GetFrameContainer():SetUserPlaced(false)
      end
    end

    local scrollFrameName = string.format("%s%s", name, "ScrollFrame")
    local scrollFrame     = CreateFrame("ScrollFrame", name, self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP")
    scrollFrame:SetPoint("LEFT")
    scrollFrame:SetPoint("RIGHT")
    scrollFrame:SetPoint("BOTTOM")
    scrollFrame:SetBackdropBorderColor(0, 0, 0, 0)
    scrollFrame:SetScript("OnScrollRangeChanged", Tracker_OnScrollRangeChanged)
    scrollFrame:SetClipsChildren(true)

    -- Hide the scroll bar and its buttons
    local scrollbarName = scrollFrame:GetName()
    local scrollbar = _G[scrollFrame:GetName().."ScrollBar"];
    local scrollupbutton = _G[scrollbar:GetName().."ScrollUpButton"]
    local scrolldownbutton = _G[scrollbarName.."ScrollBarScrollDownButton"]

    scrollbar:Hide()
    scrollupbutton:Hide()
    scrollupbutton:ClearAllPoints()
    scrolldownbutton:Hide()
    scrolldownbutton:ClearAllPoints()

    -- customize the scroll bar
    scrollbar:SetBackdrop(_Backdrops.Common)
    scrollbar:ClearAllPoints()
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT")
    scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT")
    scrollbar:SetWidth(6)
    -- customize the scroll bar thumb
    local thumb = scrollbar:GetThumbTexture()
    thumb:SetTexture(_Backdrops.Common.bgFile)
    thumb:SetHeight(40)
    thumb:SetWidth(8)

    local contentName = string.format("%s%s", name, "ContentFrame")
    local content = CreateFrame("Frame", contentName)
    scrollFrame:SetScrollChild(content)
    content:SetParent(scrollFrame)
    content:SetPoint("LEFT")
    content:SetPoint("RIGHT", scrollbar, "LEFT")
    content:SetPoint("TOP")
    content:SetHeight(self.contentHeight)
    content:SetBackdrop(_Backdrops.Common)
    content:SetBackdropColor(0, 1, 0, 0)

    self.content = content
    self.scrollFrame = scrollFrame
    self.scrollbar = scrollbar
    self.scrollbar.thumb = thumb

    -- Register the tracker in the cache
    _TrackerCache[self] = true

    Init(self)

    self.OnHeightChanged = OnHeightChanged
    self.OnWidthChanged = OnWidthChanged
    self.OnBorderWidthChanged = function(new, old)
      self:UpdateScrollbarVisibility()

      Scorpio.FireSystemEvent("EKT_TRACKER_CONTENT_SIZE_CHANGED", self.id, new)
    end

    self.blocks = Array[Block]()
    self.displayRules = Array[DisplayRule]()
  end

end)

class "Trackers" (function(_ENV)
  _TRACKERS = Dictionary()
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, String, Variable.Optional(Boolean, false) }
  __Static__() function New(self, id, createTable)
    if not self:Get(id) then
      local tracker = Tracker(id)
      self:Register(tracker, false)

      if createTable then
        Database:SelectRoot()
        if Database:SelectTable(true, "list", "tracker") then
          Database:SetValue(id, true)
        end
      end

      return tracker
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, id)
    for _, tracker in self:GetIterator() do
      if tracker.id == id then
        return tracker
      end
    end
  end

  __Arguments__ { ClassType, Tracker, Variable.Optional(Boolean, true)}
  __Static__() function Register(self, tracker, needCheck)
    if needCheck and self:Get(tracker.id) then
      return
    end

    _TRACKERS[tracker.id] = tracker

    Scorpio.FireSystemEvent("EKT_TRACKER_REGISTERED", tracker)
  end

  __Arguments__ { ClassType }
  __Static__() function GetIterator()
    return _TRACKERS:GetIterator()
  end

  __Arguments__ { ClassType, String }
  __Static__() function Delete(self, id)
    local tracker = self:Get(id)
    if tracker then
      tracker:Hide()
      _TRACKERS[id] = nil

      Database:SelectRoot()
      if Database:SelectTable(false, "list", "tracker") then
        Database:SetValue(id, nil)
      end

      Scorpio.FireSystemEvent("EKT_TRACKER_DELETED", tracker)
    end
  end

  __Static__() function UnregisterAll()
    for index, tracker in pairs(_TRACKERS) do
      tracker:Hide()
      _TRACKERS[index] = nil
    end
  end

  __Static__() function Print()
    print("--------------")
    print("-- TRACKERS --")
    print("--------------")
    for index, tracker in pairs(_TRACKERS) do
      print(index)
    end
    print("---------------")
  end

  __Arguments__ { ClassType, String, String }
  __Static__() function TransferBlock(self, categoryID, destTrackerID)
    -- Is there a source tracker ?

    local srcTracker = self:GetTrackerByBlockCategoryID(categoryID)

    if srcTracker and srcTracker.id == destTrackerID then
      return
    end

    local block
    if srcTracker then
      block = srcTracker:RemoveBlockByCategoryID(categoryID)
    else
      -- Get the category
      local category = Blocks:GetCategory(categoryID)
      local selected = category:TryToGetValidBlock()
      if selected then
        block = Block:GetCached(selected)
      end
    end

    local destTracker = Trackers:Get(destTrackerID)
    if destTracker and block then
      destTracker:AddBlock(block)
    end
  end



  __Static__() function GetTrackerByBlockCategoryID(self, blockCategoryID)
    for _, tracker in self:GetIterator() do
      for _, block in tracker:GetBlocks():GetIterator() do
        if block.category == blockCategoryID then
          return tracker
        end
      end
    end
  end
end)


function OnLoad(self)
  -- We need to have at least a tracker
  local mainTracker = Trackers:New("main")

  -- Register trackers created by the user (use Global)
  Database:SelectRoot()
  if Database:SelectTable(false, "list", "tracker") then
    for id in Database:IterateTable() do
      if not Trackers:Get(id) then
        Trackers:New(id)
      end
    end
  end

  -- Load the properties contained in the profile
  for _, tracker in Trackers:GetIterator() do
      tracker:LoadDisplayRules()
      tracker:LoadPropsFromDatabase()
  end

  Scorpio.FireSystemEvent("EKT_TRACKERS_LOADED")
end

__SystemEvent__()
function EKT_PROFILE_CHANGED()
  -- Update props contained in the new profils
  for _, tracker in Trackers:GetIterator() do
      tracker:LoadDisplayRules()
      tracker:LoadPropsFromDatabase()
  end


  for id, category in Blocks:IterateCategories() do
    Trackers:TransferBlock(id, category.tracker)
  end
end

__SystemEvent__()
function EKT_COPY_PROFILE_PROCESS(sourceDB, destDB, destProfile)
  if sourceDB["trackers"] then
    for trackerID, trackerDB in pairs(sourceDB["trackers"]) do
      if not destDB["trackers"] then
        destDB["trackers"] = {}
      end
      if (Profiles:IsGlobal(destProfile) and destDB["trackers"][trackerID]) or not Profiles:IsGlobal(destProfile) then
        destDB["trackers"][trackerID] = trackerDB
      end
    end
  end
end
