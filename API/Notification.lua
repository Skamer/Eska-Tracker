--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio              "EskaTracker.API.Notification"                           ""
--============================================================================--
namespace                            "EKT"
--============================================================================--
__Recyclable__()
class "NotificationButton" (function(_ENV)
  inherit "Frame"
  ------------------------------------------------------------------------------
  --                         Events                                           --
  ------------------------------------------------------------------------------
  __WidgetEvent__()
  event "OnClick"
  ------------------------------------------------------------------------------
  --                         Handlers                                         --
  ------------------------------------------------------------------------------
  local function UpdateText(self, new)
    self.frame.text:SetText(new)
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"       { TYPE = String, DEFAULT = "yes" }
  property "text"     { TYPE = String, DEFAULT = "", HANDLER = UpdateText }
  property "icon"     { TYPE = String }
  ------------------------------------------------------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  __Arguments__ {}
  function NotificationButton(self)
    super(self, CreateFrame("Button"))

    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(1, 0, 0, 0.75)
    self.frame:RegisterForClicks("LeftButtonUp")

    local text = self.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetAllPoints()
    text:SetText("")
    self.frame.text = text

    self.height = 16
    self.width  = 75
    self.relWidth = 0.4
  end

  __Arguments__ { String, String, Variable.Optional(String) }
  function NotificationButton(self, id, text, icon)
    this(self)

    self.id   = id
    self.text = text
    self.icon = icon
  end
end)

class "BaseNotification" (function(_ENV)
  inherit "Frame"
  ------------------------------------------------------------------------------
  --                         Events                                           --
  ------------------------------------------------------------------------------
  --- Fire when the notification is finished, and must be removed from
  --  notifications frame
  event "OnFinished"

  --- Fire when duration is elpased.
  event "OnDurationElapsed"
  ------------------------------------------------------------------------------
  --                         Handlers                                         --
  ------------------------------------------------------------------------------
  local function UpdateProps(self, new, old, prop)
    if prop == "elapsedTime" then
      if new >= self.duration and not self.elapsed then
        self.elapsed = true
        self:OnDurationElapsed()
      end
    elseif prop == "duration" then
      if self.elapsedTime >= new and not self.elapsed then
        self.elapsed = true
        self:OnDurationElapsed()
      end
    elseif prop == "finished" then
      self:OnFinished()
    elseif prop == "text" then
      self:SetText(new)
    elseif prop == "title" then
      self:SetTitle(new)
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function SetColor(self, r, g, b)
    self.frame:SetBackdropColor(r, g, b, 0.65)
    return self
  end

  __Arguments__ { String }
  function SetTitle(self, title)
    if self.frame.title then
      self.frame.title:SetText(title)
    end
  end

  __Arguments__ { String }
  function SetText(self, text)
    if self.frame.text then
      self.frame.text:SetText(text)
    end
  end

  __Static__() function Success()
    return Notification():SetColor(0, 148/255, 0)
  end

  __Static__() function Warn()
    return Notification():SetColor(1.0, 106/255, 0)
  end

  __Static__() function Critical()
    return Notification():SetColor(1.0, 0, 0)
  end

  __Static__() function Info()
    return Notification():SetColor(0, 1, 1)
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id"           { TYPE = String + Number }
  property "title"        { TYPE = String, HANDLER = UpdateProps }
  property "text"         { TYPE = String, HANDLER = UpdateProps }
  property "icon"         { TYPE = String + Number }
  property "category"     { TYPE = Category }
  property "duration"     { TYPE = Number, DEFAULT = 7 }
  property "elapsedTime"  { TYPE = Number, DEFAULT = 0, HANDLER = UpdateProps }
  property "interactive"  { TYPE = Boolean, DEFAULT = false }
  property "paused"       { TYPE = Boolean, DEFAULT = false }
  property "finished"     { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateProps }
  property "elapsed"      { TYPE = Boolean, DEFAULT = false }
  ------------------------------------------------------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Rest() }
  function BaseNotification(self, ...)
    super(self, ...)

    self.OnDurationElapsed = function() self.finished = true end
  end
end)

class "Notification" (function(_ENV)
  inherit "BaseNotification"
  ------------------------------------------------------------------------------
  --                         Methods                                          --
  ------------------------------------------------------------------------------
  __Async__()
  function FadeOff(self)
    local start = GetTime()
    self._pendingFadeOff = true
    while not self.frame:IsMouseOver() do
        local alpha = (GetTime() - start) / 3
        if alpha < 1 then
          self:SetAlpha(1 - alpha)
          Next()
        else
          self:SetAlpha(0)
          self.finished = true
          break
        end
    end
  end
  ------------------------------------------------------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  function Notification(self)
    self.frame = CreateFrame("Frame")
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 148/255, 1, 0.65)
    -- Fade off system
    self.frame:SetScript("OnEnter", function() self:SetAlpha(1) end)
    self.frame:SetScript("OnLeave", function()
      if self._pendingFadeOff then
        self._pendingFadeOff = nil
        self:FadeOff()
      end
    end)

    local fIcon = CreateFrame("Frame", nil, self.frame)
    fIcon:SetBackdrop(_Backdrops.Common)
    fIcon:SetBackdropColor(0, 0, 0, 0.9)
    fIcon:SetWidth(20)
    fIcon:SetHeight(20)
    fIcon:SetPoint("TOPLEFT", 1, -2)
    self.frame.ficon = fIcon

    local icon = fIcon:CreateTexture(nil, "OVERLAY")
    icon:SetSize( 15 * 0.5, 33 * 0.5)
    icon:SetPoint("CENTER")
    icon:SetTexture([[Interface\QuestFrame\AutoQuest-Parts]])
    icon:SetTexCoord(0.13476563, 0.17187500, 0.01562500, 0.53125000)
    self.frame.icon = icon

    local headerFrame = CreateFrame("Frame", nil, self.frame)
    headerFrame:SetBackdrop(_Backdrops.Common)
    headerFrame:SetBackdropColor(1, 1, 1, 0.15)
    headerFrame:SetPoint("TOP", 0, -2)
    headerFrame:SetPoint("LEFT", fIcon, "RIGHT")
    headerFrame:SetPoint("RIGHT", -1, 0)
    headerFrame:SetHeight(14)
    self.frame.header = headerFrame

    local fontName = _LibSharedMedia:Fetch("font", "PT Sans Bold")
    local fontSub = _LibSharedMedia:Fetch("font", "PT Sans Narrow Bold")


    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:GetFontObject():SetShadowOffset(0.5, 0)
    title:GetFontObject():SetShadowColor(0, 0, 0, 0.4)
    title:SetPoint("LEFT", 10, 0)
    title:SetPoint("RIGHT")
    title:SetPoint("TOP")
    title:SetFont(fontName, 11)
    title:SetHeight(14)
    title:SetTextColor(1, 216/255, 0)
    title:SetText("Notification title ! ")
    self.frame.title = title


    local content = CreateFrame("Frame", nil, self.frame)
    content:SetPoint("LEFT", 1, 0)
    content:SetPoint("RIGHT", -1, 0)
    content:SetPoint("BOTTOM", 0, 1)
    content:SetPoint("TOP", headerFrame, "BOTTOM", 0, -1)
    content:SetBackdrop(_Backdrops.Common)
    content:SetBackdropColor(0, 0, 0, 0.15)
    self.frame.content = content

    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("TOP", 0, -2)
    text:SetPoint("BOTTOM")
    text:SetPoint("RIGHT")
    text:SetPoint("LEFT", fIcon:GetWidth() + 4, 0)
    text:SetJustifyH("LEFT")
    text:SetFont(fontName, 10)
    text:SetText("This is a notification text")
    self.frame.text = text

    self.height = 40
    self.OnDurationElapsed = function() self:FadeOff() end

  end
end)


class "InteractiveNotification" (function(_ENV)
  inherit "BaseNotification"
  ------------------------------------------------------------------------------
  --                         Events                                           --
  ------------------------------------------------------------------------------
  --- Fire when the player has confirmed its anwser
  --- (e.g, clicking on the 'ok' button)
  event "OnConfirmedAnswer"

  --- Fired when the player has clicked the frame
  __WidgetEvent__()
  event "OnClick"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function OnClickHandler(self)
    Notifications():Remove(self)
  end
  ------------------------------------------------------------------------------
  --                         Methods                                          --
  ------------------------------------------------------------------------------
  function AddButton(self, button)
    -- Create the button row frame
    if not self.buttonRow then
      self.buttonRow = FrameRow()
      self.buttonRow:SetParent(self)
      self.buttonRow:SetPoint("TOP", self.frame.content, "BOTTOM")
      self.buttonRow:SetPoint("LEFT")
      self.buttonRow:SetPoint("RIGHT")
    end

    self.buttonRow:AddFrame(button)
    self.buttonRow.OnHeightChanged = function(_, new, old)
      self.height = self.height + (new - old)
    end

    button.OnClick = function()
      self:OnConfirmedAnswer(button.id, button)
    end

    self:Layout()

    return self
  end

  function GetButtonRow(self)
    return self.buttonRow
  end

  __Arguments__ { String }
  function SetText(self, text)
    super.SetText(self, text)
    self:CalculateHeight()
  end

  function CalculateHeight(self)
    local height = self.baseHeight

    -- Important ! This is needed to update the text box height
    self.frame.text:SetHeight(0)

    local textHeight = self.frame.text:GetHeight()

    local diff = (textHeight + 22) - self.baseHeight
    if diff < 0 then diff = 0 end
    height = height + diff

    self.height = height
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "interactive"        { TYPE = Boolean, DEFAULT = true }
  -- Buttons Settings
  --- The spacing between each button (x positio)
  property "buttonsOffsetY"      { TYPE = Number, DEFAULT = 2}
  property "buttonsOffsetX"      { TYPE = Number, DEFAULT = 5}
  property "buttonsXSpacing"     { TYPE = Number, DEFAULT = 10 }
  property "buttonsYSpacing"     { TYPE = Number, DEFAULT = 2  }
  property "buttonsLayout"       { TYPE = String, DEFAULT = "Flow" } -- Flow or List
  property "buttonsCentered"     { TYPE = Boolean, DEFAULT = true }
  property "buttonsAutoSize"     { TYPE = Boolean, DEFAULT = true }
  ------------------------------------------------------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  function InteractiveNotification(self)
    super(self, CreateFrame("Button"))

    --self.frame = CreateFrame("Button")
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 148/255, 1, 0.65)
    self.frame:RegisterForClicks("LeftButtonUp")
    --[[self.frame:SetScript("OnClick", function()

    end)--]]

    local fIcon = CreateFrame("Frame", nil, self.frame)
    fIcon:SetBackdrop(_Backdrops.Common)
    fIcon:SetBackdropColor(0, 0, 0, 0.9)
    fIcon:SetWidth(20)
    fIcon:SetHeight(20)
    fIcon:SetPoint("TOPLEFT", 1, -2)
    self.frame.ficon = fIcon

    local icon = fIcon:CreateTexture(nil, "OVERLAY")
    icon:SetSize( 15 * 0.5, 33 * 0.5)
    icon:SetPoint("CENTER")
    icon:SetTexture([[Interface\QuestFrame\AutoQuest-Parts]])
    icon:SetTexCoord(0.13476563, 0.17187500, 0.01562500, 0.53125000)
    self.frame.icon = icon

    local headerFrame = CreateFrame("Frame", nil, self.frame)
    headerFrame:SetBackdrop(_Backdrops.Common)
    headerFrame:SetBackdropColor(1, 1, 1, 0.15)
    headerFrame:SetPoint("TOP", 0, -2)
    headerFrame:SetPoint("LEFT", fIcon, "RIGHT")
    headerFrame:SetPoint("RIGHT", -1, 0)
    headerFrame:SetHeight(14)
    self.frame.header = headerFrame

    local fontName = _LibSharedMedia:Fetch("font", "PT Sans Bold")
    local fontSub = _LibSharedMedia:Fetch("font", "PT Sans Narrow Bold")


    local title = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:GetFontObject():SetShadowOffset(0.5, 0)
    title:GetFontObject():SetShadowColor(0, 0, 0, 0.4)
    title:SetPoint("LEFT", 10, 0)
    title:SetPoint("RIGHT")
    title:SetPoint("TOP")
    title:SetFont(fontName, 11)
    title:SetHeight(14)
    title:SetTextColor(1, 216/255, 0)
    title:SetText("Notification title ! ")
    self.frame.title = title


    local content = CreateFrame("Frame", nil, self.frame)
    content:SetPoint("LEFT", 1, 0)
    content:SetPoint("RIGHT", -1, 0)
    content:SetPoint("BOTTOM")
    content:SetPoint("TOP", headerFrame, "BOTTOM", 0, -1)
    content:SetBackdrop(_Backdrops.Common)
    content:SetBackdropColor(0, 0, 0, 0.15)
    content:HookScript("OnSizeChanged", function() self:CalculateHeight() end)
    self.frame.content = content

    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetFont(fontName, 10)
    text:SetPoint("LEFT", fIcon:GetWidth(), 0)
    text:SetPoint("RIGHT")
    text:SetPoint("TOP", 0, -2)
    text:SetJustifyH("LEFT")
    text:SetText("This is a notification text")
    text:SetWordWrap(true)
    text:SetNonSpaceWrap(false)
    self.frame.text = text

    self.height = 20
    self.baseHeight = self.height

    self.buttons = List()

    self.OnClick = OnClickHandler
  end
end)


--------------------------------------------------------------------------------
--                        Attribute __Recyclable__                            --
--  __Recyclable__ will register the class targeted in the ObjectManger and   --
-- will defined aditional property and method                                 --
-- obj._isUsed -> will say if the object is currently used                    --
-- obj:Recycle() -> will recycle the object, calling the Reset method, and    --
-- push it in the reycable pool.                                              --
--------------------------------------------------------------------------------
class "Notifications" (function(_ENV)
  inherit "Frame"
  _Obj = nil
  ------------------------------------------------------------------------------
  --                         Methods                                          --
  ------------------------------------------------------------------------------
  __Arguments__ { BaseNotification }
  function Add(self, notification)
    self.notifications:Insert(notification)
    notification:SetParent(self)

    notification.OnFinished = function(obj) self:Remove(obj) end
    notification.OnHeightChanged = function(notification, new, old)
      self.height = self.height + (new - old)
    end

    self:Draw()
  end

  __Arguments__ { Number + String }
  function Get(self, id)
    for index, notification in self.notifications:GetIterator() do
      if type(notification.id) == type(id) then
        if notification.id == id then
          return notification
        end
      end
    end
  end

  __Arguments__ { BaseNotification }
  function Remove(self, notification )
    self.notifications:Remove(notification)
    notification:SetParent()
    notification:ClearAllPoints()
    notification:Hide()
    notification.OnFinished = nil
    notification.OnHeightChanged = nil
    self:Layout()

    if self.notifications.Count == 0 then
      -- TODO: Add ResumeIdleCountdown
    end
  end

  __Arguments__ { Number + String }
  function Remove(self, id)
    local notification = self:Get(id)
    if notification then
      self:Remove(notification)
    end
  end

  function OnLayout(self)
    local previousFrame
    for index, notification in self.notifications:GetIterator() do
      notification:Hide()
      notification:ClearAllPoints()

      if index == 1 then
        notification:SetPoint("TOP")
        notification:SetPoint("LEFT")
        notification:SetPoint("RIGHT")
      else
        notification:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, -5)
        notification:SetPoint("TOPRIGHT", previousFrame, "BOTTOMRIGHT")
      end
      previousFrame = notification.frame
      notification:Show()
    end

    self:CalculateHeight()

  end

  function CalculateHeight(self)
    local height = self.baseHeight
    for index, notification in self.notifications:GetIterator() do
      local offset = index > 1 and 5 or 0
      height = height + notification.height + offset
    end

    self.height = height
  end

  __Async__()
  function UpdateNotifications(self, delta)
    if not self.notificationsPaused then
      for index, notification in self.notifications:Sort("a,b=>a.elapsedTime<b.elapsedTime"):GetIterator() do
        if not notification.paused and not notification.interactive then
          notification.elapsedTime = notification.elapsedTime + delta
        end
      end
    end
  end



  __Arguments__ { String }
  function IsRegisteredSetting(self, option)
    if option == "link-notifications-to-a-tracker" or option == "tracker-used-for-notifications" then
      return true
    end

    return super.IsRegisteredSetting(self, option)
  end

  function GetTrackerUsed(self)
    for _, tracker in Trackers:GetIterator() do
      if tracker.displayNotifications then
        return tracker
      end
    end
  end

  __Arguments__ { String, Variable.Optional(), Variable.Optional() }
  function OnSetting(self, option, new, old)
    if option == "tracker-used-for-notifications" then
      if Settings:Get("link-notifications-to-a-tracker") then
        local oldTracker = self:GetTrackerUsed()
        if oldTracker and oldTracker.id ~= new then
          oldTracker:DisableNotifications()
        end

        if not oldTracker or oldTracker.id ~= new then
          local tracker = Trackers:Get(new)
          if tracker then
            tracker:EnableNotifications()
          end
        end
      end
    elseif option == "link-notifications-to-a-tracker" then
      local trackerUsed = Settings:Get("tracker-used-for-notifications")
      local tracker = Trackers:Get(trackerUsed)

      if new and tracker then
        tracker:EnableNotifications()
      else
        if tracker then
          tracker:DisableNotifications()
        end
        self:SetParent(UIParent)
        self:SetPoint("CENTER")
      end
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "notificationsPaused" { TYPE = Boolean, DEFAULT = false }
  ------------------------------------------------------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  function Notifications(self)
    super(self)

    self.frame = CreateFrame("Frame", nil, UIParent)
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 0, 0, 0)
    self.frame:SetScript("OnUpdate", function(_, delta) self:UpdateNotifications(delta) end)

    self.baseHeight = 0
    self.height     = self.baseHeight
    self.width      = 225

    self.notifications = List()

    self.OnHeightChanged = function(self, new, old)
      if new == 0 then
        self:Hide()
      else
        self:Show()
      end
    end

    self:Hide()

    _Obj = self
  end
  ------------------------------------------------------------------------------
  --                      Meta-Methods                                        --
  ------------------------------------------------------------------------------
  function __exist(self)
    return _Obj
  end
end)


function OnLoad(self)
  Settings:Register("link-notifications-to-a-tracker", true)
  Settings:Register("tracker-used-for-notifications", "main")
end

__SystemEvent__()
function EKT_PROFILES_LOADED()
  Notifications():LoadSetting("link-notifications-to-a-tracker")
  Notifications():LoadSetting("tracker-used-for-notifications")
end

__SystemEvent__()
function EKT_TRACKER_REGISTERED(tracker)
  local trackerLinked = Settings:Get("link-notifications-to-a-tracker")
  if trackerLinked then
    local trackerUsed = Settings:Get("tracker-used-for-notifications")
    if trackerUsed == tracker.id then
      Notifications():HandleSetting("tracker-used-for-notifications", trackerUsed)
    end
  end
end
