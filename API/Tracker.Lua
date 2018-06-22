--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                    "EskaTracker.API.Tracker"                          ""
--============================================================================--
namespace                  "EKT"
--============================================================================--
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

    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("width", new)
    end
  end

  local function OnHeightChanged(self, new, old)
    -- Update the scroll bar visibility
    self:UpdateScrollbarVisibility()

    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("height", new)
    end
  end

  local function UpdateLock(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("locked", new)
    end

    --self:GetFrameContainer():EnableMouse(true)
    self:GetFrameContainer():SetMovable(not new)
  end

  __Arguments__ { Number }
  function OnInactivityTimerChange(self, timer)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("inactivity-timer", timer)
    end

    self:AddIdleTimer(self, timer)
    self:SendMessageToChildren("CHANGE_IDLE_MODE_TIMER", new)
    self:SendMessageToChildren("ADD_IDLE_TIMER", self, timer)
  end

  __Arguments__ { Number }
  function OnIdleModeAlphaChange(self, alpha)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("idle-mode-alpha", alpha)
    end

    if self.isInIdleMode then
      self:SetAlpha(alpha)
    else
      self:SetAlpha(1)
    end
    self:SendMessageToChildren("CHANGE_IDLE_MODE_ALPHA", alpha)
  end

  __Arguments__ { String }
  function OnIdleModeTypeChange(self, type)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("idle-mode-type", type)
    end

    self:SendMessageToChildren("GET_IDLE_MODE_INFO", self.idleModeEnabled, self.idleModeTimer, self.idleModeAlpha, self.idleModeType)
  end

  __Arguments__ { BaseObject, String, Variable.Rest() }
  function OnChildRequest(self, child, msg, ...)
    if msg == "GET_IDLE_MODE_INFO" then
      child:OnConfirmedRequest(msg, self.idleModeEnabled, self.idleModeTimer, self.idleModeAlpha, self.idleModeType)
    end
  end

  local function UpdateShowScrollbar(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      if new then
        Database:SetValue("showScrollbar", true)
      else
        Database:SetValue("showScrollbar", nil)
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

  local function PrepareNotifications(self, useNotifications)
    if useNotifications then
      --[[Notifications().OnHeightChanged = function(_, new, old)
        self.contentHeight = self.contentHeight + (new - old)
        if new == 0 then
          Notifications():Hide()
        elseif old == 0 then
          Notifications():Show()
        end
      end--]]
      self.OnNotificationHeightHandler = function(_, new, old)
        self.contentHeight = self.contentHeight + (new - old)
      end
      Notifications().OnHeightChanged = Notifications().OnHeightChanged + self.OnNotificationHeightHandler
    else
        if self.OnNotificationHeightHandler then
          Notifications().OnHeightChanged = Notifications().OnHeightChanged - self.OnNotificationHeightHandler
        end
    end
    self:Layout()
  end

  function EnableNotifications(self)
    self.OnNotificationHeightHandler = function(_, new, old)
      self.contentHeight = self.contentHeight + (new - old)
    end

    Notifications().OnHeightChanged = Notifications().OnHeightChanged + self.OnNotificationHeightHandler

    Notifications():ClearAllPoints()
    Notifications():SetParent(self.content)
    Notifications():SetPoint("TOP")
    Notifications():SetPoint("LEFT")
    Notifications():SetPoint("RIGHT")

    self.displayNotifications = true

    self:Layout()

    Notifications():CalculateHeight()
  end


  function DisableNotifications(self)
    if self.OnNotificationHeightHandler then
      Notifications().OnHeightChanged = Notifications().OnHeightChanged - self.OnNotificationHeightHandler
    end

    Notifications():ClearAllPoints()
    Notifications():SetParent()

    self.displayNotifications = false

    self:Layout()
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
  --                        Comm. Methods                                     --
  ------------------------------------------------------------------------------
  __Arguments__ { BaseObject }
  function AddChildObject(self, object)
    super.AddChildObject(self, object)

    self:RegisterContainedFrame(object)
  end

  function RegisterContainedFrame(self, frame)
    if not self._frameContained then
      self._frameContained = setmetatable({}, { __mode = "k"})
    end

    self._frameContained[frame] = true

    frame:OnRetrieveIdleModeInfo(self.idleModeEnabled, self.idleModeTimer, self.idleModeAlpha, self.idleModeType)

    local subChildren = frame:GetChildObjects()
    if subChildren then
      for subChild in pairs(subChildren) do
        self:RegisterContainedFrame(subChild)
      end
    end
  end

  function UnregisterContainedFrame(self, frame)
    if self._frameContained then
      self._frameContained[frame] = nil
      local subChildren = frame:GetChildObjects()
      if subChildren then
        for subChild in pairs(subChildren) do
          self:UnregisterContainedFrame(subChild)
        end
      end
    end

    frame.idleModeType    = nil
    frame.idleModeTimer   = nil
    frame.idleModeEnabled = nil
    frame.idleModeAlpha   = nil
  end

  __Arguments__ { String, Variable.Rest() }
  function OnChildMessage(self, msg, ...)
    if msg == "REGISTER_FRAME" then
      local obj = ...
      self:RegisterContainedFrame(obj)
    elseif msg == "UNREGISTER_FRAME" then
      local obj = ...
      self:UnregisterContainedFrame(obj)
    elseif msg == "ADD_IDLE_TIMER" then
      local ownerTimer, timer = ...
      self:AddIdleTimer(ownerTimer, timer)
    elseif msg == "REMOVE_IDLE_TIMER" then
      local ownerTimer = ...
      self:RemoveIdleTimer(ownerTimer)
      if self.idleModeType == "basic-type" then
        self:SendMessageToChildren("REMOVE_IDLE_TIMER", ownerTimer)
      end
    elseif msg == "ADD_IDLE_COUNTDOWN" then
      local ownerTimer, timer, applyToChildren = ...
      self:AddIdleCountdown(ownerTimer, IdleCountdownInfo(timer, timer))
    elseif msg == "REMOVE_IDLE_COUNTDOWN" then
      local ownerTimer, applyToChildren = ...
      self:RemoveIdleCountdown(ownerTimer, applyToChildren)
    elseif msg == "WAKE_UP" then
      local ownerTimer, timer = ...
      self:AddIdleCountdown(ownerTimer, IdleCountdownInfo(timer, timer))
      self:OnWakeUp()
    end
  end
  ------------------------------------------------------------------------------
  --                        Idle. Methods                                     --
  ------------------------------------------------------------------------------
  __Arguments__ { Boolean }
  function OnIdleModeEnabledChange(self, enabled)
    -- 1. Save the change in the database
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("idle-mode-enabled", enabled)
    end


    -- 2. Notify the children
    self:SendMessageToChildren("CHANGE_IDLE_MODE_ENABLED", enabled)

    -- 3. Start the timers if enabled/ Remove the timer and transparency if disabled
    if enabled then
      self:AddIdleTimer(self, self.idleModeTimer)
      self:SendMessageToChildren("WAKE_UP", self, self.idleModeTimer)

      self.__isInIdleMode = false
      self:StartInactivityTimers()
    else
      -- Remove the transparency
      self:SetAlpha(1.0)
      -- Clear all Timers
      self:ClearIdleTimers()
      -- Set the idle mode to false without triggered the handler system
      self.__isInIdleMode = false
    end
  end

  function LeaveTemporalyIdleMode(self)
    self.idleModePaused = true
    self:SetAlpha(1.0)
  end

  function EnterInIdleModeFromTemporarly(self)
    self.idleModePaused = false
    if self.isInIdleMode and self.idleModeEnabled then
      self:SetAlpha(self.idleModeAlpha)
    end
  end

  __Async__()
  function StartInactivityTimers(self)
    if self._inactivityTimerStarted then
      return
    end

    self._inactivityTimerStarted = true
    local updateRate = 0.1

    while self.idleModeEnabled do
      Delay(updateRate)

      if not self.isInIdleMode and not self.idleModePaused then
        local trackerTimerToUse = self:GetEffectiveIdleCountdown()
        if trackerTimerToUse == -1 then
          self.isInIdleMode = false
        elseif trackerTimerToUse <= 0 then
          self.isInIdleMode = true
        end

        self:UpdateIdleCountdowns(updateRate)

        if self._frameContained then
          for obj in pairs(self._frameContained) do
            if not obj.isInIdleMode and not self.idleModePaused  then
              local timerToUse = (self.idleModeType == "basic-type") and trackerTimerToUse or obj:GetEffectiveIdleCountdown()
              if timerToUse == -1 then
                obj.isInIdleMode = false
              elseif timerToUse <= 0 then
                obj.isInIdleMode = true
              end

              obj:UpdateIdleCountdowns(updateRate)
            end
          end
        end
      end
    end

    self._inactivityTimerStarted = nil
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

      -- Add Block in the child object list for message broacast system and IWakeUpTracker
      self:AddChildObject(block)
    end

    self:Layout()
  end

  __Arguments__ { Block }
  function RemoveBlock(self, block)
    block = self.blocks:Remove(block)
    block:ClearAllPoints()
    block:SetParent()
    block:Hide()
    block.OnHeightChanged = nil
    block.OnOrderChanged  = nil
    self:RemoveChildObject(block)

    self:Layout()

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

  function LoadPropsFromDatabase(self)
    -- Load the properties contained in the profile
    Profiles:PrepareDatabase()

    local height, width, locked, showScrollbar, xPos, yPos, show
    local idleModeAlpha, inactivityTimer, idleModeEnabled, idleModeType
    if Database:SelectTable(false, "trackers", self.id) then
      height                        = Database:GetValue("height")
      width                         = Database:GetValue("width")
      locked                        = Database:GetValue("locked")
      showScrollbar                 = Database:GetValue("showScrollbar")
      xPos                          = Database:GetValue("xPos")
      yPos                          = Database:GetValue("yPos")
      show                          = Database:GetValue("show")
      idleModeAlpha                 = Database:GetValue("idle-mode-alpha")
      inactivityTimer               = Database:GetValue("inactivity-timer")
      idleModeType                  = Database:GetValue("idle-mode-type")
      idleModeEnabled               = Database:GetValue("idle-mode-enabled")
    end

    if show == nil or show ~= false then
      show = true
    end

    if show and not self:IsShown() then
      self:Show()
    elseif not show and self:IsShown() then
      self:Hide()
    end


    -- Assign the values
    self.height                       = height or 300
    self.width                        = width or 325
    self.locked                       = locked
    self.showScrollbar                = showScrollbar
    self.idleModeAlpha                = idleModeAlpha
    self.inactivityTimer              = inactivityTimer
    self.idleModeType                 = idleModeType
    self.idleModeEnabled              = idleModeEnabled
    self:SetPosition(xPos, yPos, false)
  end

  function OnHide(self)
    super.OnHide(self)

    Profiles:PrepareDatabase()
    if Database:SelectTable("trackers", self.id) then
      Database:SetValue("show", false)
    end
  end

  function OnShow(self)
    super.OnShow(self)

    Profiles:PrepareDatabase()
    if Database:SelectTable(false, "trackers", self.id) then
      Database:SetValue("show", nil)
    end
  end

  __Static__() function GetIDFromName(self, name)
    return name:lower()
  end

  __Arguments__ { Boolean }
  function OnHover(self, hover)
    super.OnHover(self, hover)

    if hover then
      self:LeaveTemporalyIdleMode()
      if self.idleModeType ~= "basic-type" then
        self:SendMessageToChildren("LEAVE_IDLE_MODE_TEMPORARLY")
      end
    else
      self:EnterInIdleModeFromTemporarly()
      if self.idleModeType ~= "basic-type" then
        self:SendMessageToChildren("ENTER_IDLE_MODE_FROM_TEMPORALY")
      end
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"                           { TYPE = String, DEFAULT = "", HANDLER = UpdateID }
  property "name"                         { TYPE = String }
  property "xPos"                         { TYPE = Number, DEFAULT = 0 }
  property "yPos"                         { TYPE = Number, DEFAULT = 0 }
  property "locked"                       { TYPE = Boolean, DEFAULT = false,  HANDLER = UpdateLock }
  property "contentHeight"                { TYPE = Number, DEFAULT = 50, HANDLER = SetContentHeight }
  property "displayNotifications"         { TYPE = Boolean, DEFAULT = false }
  property "showScrollbar"                { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateShowScrollbar }
  --- Locations
  property "inRaid"               { TYPE = Boolean, DEFAULT = false }
  property "inKeystone"           { TYPE = Boolean, DEFAULT = false }
  __Static__() property "_prefix"  { DEFAULT = "tracker"}
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
      tracker:LoadPropsFromDatabase()
  end

  Scorpio.FireSystemEvent("EKT_TRACKERS_LOADED")
end

__SystemEvent__()
function EKT_PROFILE_CHANGED()
  -- Update props contained in the new profils
  for _, tracker in Trackers:GetIterator() do
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
