--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio               "EskaTracker.API.Frame"                            ""
--============================================================================--
namespace "EKT"
--============================================================================--
Ceil = math.ceil
--============================================================================--
class "__WidgetEvent__" (function(_ENV)
    local function handler (delegate, owner, eventname)
        if delegate:IsEmpty() then
            owner:GetFrameContainer():SetScript(eventname, nil)
        else
            if owner:GetFrameContainer():GetScript(eventname) == nil then
                owner:GetFrameContainer():SetScript(eventname, function(self, ...)
                    -- Call the delegate directly
                    delegate(owner, ...)
                end)
            end
        end
    end

    function __WidgetEvent__(self)
        __EventChangeHandler__(handler)
    end
end)

__Abstract__()
class "BaseObject" (function(_ENV)
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  enum "MessageDirection" {
    "PARENTS",
    "CHILDREN"
  }


  __Default__(1)
  enum "ConsumeType" {
    ForAll = 1,
    OnlyForItsChildren = 2
  }

  __Arguments__ { BaseObject }
  function AddChildObject(self, object)
    if not self._childrenObject then
      self._childrenObject = setmetatable({}, { __mode = "k"} )
    end

    self._childrenObject[object] = true

    object:__SetParentObject(self)
  end

  __Arguments__ { BaseObject }
  function RemoveChildObject(self, obj)
    if self._childrenObject then
      self._childrenObject[obj] = nil
      obj:__SetParentObject()
    end
  end

  function RemoveChildObjects(self)
    if self._childrenObject then
      for child in pairs(self._childrenObject) do
        child:__SetParentObject(nil)
        self._childrenObject[child] = nil
      end
    end
  end

  function GetChildObjects(self)
    return self._childrenObject
  end



  __Arguments__ { Variable.Optional(BaseObject) }
  function SetParentObject(self, obj)
    local parent = self:GetParentObject()
    if parent and (not obj or parent ~= obj) then
      parent:RemoveChildObject(self)
    end

    if obj then
      obj:AddChildObject(self)
    end
  end

  __Arguments__ { Variable.Optional(BaseObject) }
  function __SetParentObject(self, obj)
    self._parentObject = obj
  end

  function GetParentObject(self)
    return self._parentObject
  end

  --- Send a message for children or parents?
  __Arguments__ { String, MessageDirection, Variable.Rest() }
  function SendMessage(self, direction, msg, ...)
    if direction == "PARENTS" then
      self:SendMessageToParents(self, msg, ...)
    elseif direction == "CHILDREN" then
      self:SendMessageToChildren(self, msg, ...)
    end
  end

  --- Send a message for parents
  __Arguments__ { String, Variable.Rest() }
  function SendMessageToParents(self, msg, ...)
    local parent    = self:GetParentObject()
    local continue  = true
    while parent and continue do
      continue  = not parent:OnChildMessage(msg, ...)
      parent    = parent:GetParentObject()
    end
  end


  --- Send a message for its children
  __Arguments__ { String, Variable.Rest() }
  function SendMessageToChildren(self, msg, ...)
    if self._childrenObject then
      for obj in pairs(self._childrenObject) do
        obj:OnParentMessage(msg, ...)
        obj:SendMessageToChildren(msg, ...)
      end
    end
  end

  --- May be overloaded for answering to children message.
  -- Returning true will consume the message (will no longer be dispatched)
  __Arguments__ { String, Variable.Rest() }
  function OnChildMessage(self, msg, ...) end

  --- May be overloaded for answering to parent message.
  -- Returning true will consume the message (will no longer be dispatched)
  __Arguments__ { String, Variable.Rest() }
  function OnParentMessage(self, msg, ...)  end


  --- Send a request to parents which needs to be confirmed by them.
  -- If the request has been confirmed, OnConfirmedRequest will be called.
  __Arguments__ { String, Variable.Rest() }
  function SendRequest(self, msg, ...)
    local parent = self:GetParentObject()
    local continue = true
    while parent and continue do
      continue = not parent:OnChildRequest(self, msg, ...)
      parent   = parent:GetParentObject()
    end
  end

  --- This method may be overloaded for confirming the child requests
  __Arguments__ { BaseObject, String, Variable.Rest() }
  function OnChildRequest(self, child, msg, ...) end

  --- This method may be overloaded for answering to requests have been confirmed
  __Arguments__ { String, Variable.Rest() }
  function OnConfirmedRequest(self, child, msg, ...) end
end)


struct "IdleCountdownInfo" (function(_ENV)
  member "countdown" { TYPE = Number, REQUIRE = true }
  member "duration"  { TYPE = Number, REQUIRE = true }
  member "applyToChildren" { TYPE = Boolean, DEFAULT = false }
end)


class "Frame" (function(_ENV)
  inherit "BaseObject"

  _FrameCache = setmetatable({}, { __mode = "k"})
  event "OnWidthChanged"
  event "OnHeightChanged"

  __WidgetEvent__()
  event "OnSizeChanged"

  __WidgetEvent__()
  event "OnEnter"

  __WidgetEvent__()
  event "OnLeave"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  --- --------------------------------------------------------------------------
  local function UpdateHeight(self, new, old)
    local frame = self:GetFrameContainer()
    -- Ceil the values
    new = math.floor(new+0.5)
    old = math.floor(old+0.5)


    if frame then
      frame:SetHeight(new)
    end
    return OnHeightChanged(self, new, old)
  end

  local function UpdateWidth(self, new, old)
    local frame = self:GetFrameContainer()
    -- Ceil the values
    new = math.floor(new+0.5)
    old = math.floor(old+0.5)

    if frame then
      frame:SetWidth(new)
    end

    return OnWidthChanged(self, new, old)
  end

  local function UpdateLayout(self)
    self:Layout()
  end


  local function UpdateIdleModeProps(self, new, old, prop)
    if prop == "idleModeEnabled" then
      self:OnIdleModeEnabledChange(new)
    elseif prop == "idleModeTimer" then
      self:OnIdleModeTimerChange(new)
    elseif prop == "idleModeAlpha" then
      self:OnIdleModeAlphaChange(new)
    elseif prop == "isInIdleMode" then
      self:OnIdleModeChange(new)
      local ignoreChildren = (self.idleModeType == "basic-type") and true or false
      if new then
        self:OnEnterIdleMode(ignoreChildren)
      else
        self:OnLeaveIdleMode(ignoreChildren)
      end
    elseif prop == "inactivityTimer" then
      self:OnInactivityTimerChange(new)
    elseif prop == "idleModeType" then
      self:OnIdleModeTypeChange(new)
    end
  end
  ------------------------------------------------------------------------------
  --                    Comm Methods                                          --
  ------------------------------------------------------------------------------
  __Arguments__ { String , Variable.Rest() }
  function OnConfirmedRequest(self, msg, ...)
    if msg == "GET_IDLE_MODE_INFO" then
      self:OnRetrieveIdleModeInfo(...)
      self:SendMessageToChildren("GET_IDLE_MODE_INFO", ...)
    end
  end

  __Arguments__ { String, Variable.Rest() }
  function OnChildMessage(self, msg, ...)
    if msg == "WAKE_UP" then
      local ownerTimer, timer = ...
      self:AddIdleCountdown(ownerTimer, IdleCountdownInfo(timer, timer))
      self:OnWakeUp()
    elseif msg == "REMOVE_IDLE_COUNTDOWN" then
      local ownerTimer = ...
      self:RemoveIdleCountdown(ownerTimer)
    end
  end

  function OnRetrieveIdleModeInfo(self, enabled, timer, alpha, type)
    if type == "basic-type" then
      self.idleModeTimer = nil
    else
      self.idleModeTimer = timer
    end

    self.idleModeEnabled = enabled
    self.idleModeAlpha = alpha
    self.idleModeType  = type
  end

  __Arguments__ { String, Variable.Rest() }
  function OnParentMessage(self, msg, ...)
    if msg == "GET_IDLE_MODE_INFO" then
      self:OnRetrieveIdleModeInfo(...)
    elseif msg == "REFRESH_IDLE_MODE_ALPHA" then
      if self.isInIdleMode then
        self:SetEffectiveAlpha(self.idleModeAlpha)
      end
    elseif msg == "CHANGE_IDLE_MODE_ALPHA" then
      local alpha = ...
      self.idleModeAlpha = alpha
    elseif msg == "CHANGE_IDLE_MODE_TIMER" then
      local timer = ...
      self.idleModeTimer = timer
    elseif msg == "CHANGE_IDLE_MODE_ENABLED" then
      local enabled = ...
      self.idleModeEnabled = enabled
    elseif msg == "WAKE_UP" then
      local ownerTimer, timer = ...
      self:AddIdleCountdown(ownerTimer, IdleCountdownInfo(timer, timer))
      self:OnWakeUp()
    elseif msg == "LEAVE_IDLE_MODE_TEMPORARLY" then
      self:LeaveTemporalyIdleMode()
    elseif msg == "ENTER_IDLE_MODE_FROM_TEMPORALY" then
      self:EnterInIdleModeFromTemporarly()
    elseif msg == "ADD_IDLE_COUNTDOWN" then
      local ownerTimer, timer, applyToChildren = ...
      self:AddIdleCountdown(ownerTimer, IdleCountdownInfo(timer, timer), applyToChildren)
    elseif msg == "REMOVE_IDLE_COUNTDOWN" then
      local ownerTimer, applyToChildren = ...
      self:RemoveIdleCountdown(ownerTimer, applyToChildren)
    elseif msg == "SET_EFFECTIVE_ALPHA" then
      local alpha = ...
      self:SetEffectiveAlpha(alpha)
    end
  end

  __Arguments__ { BaseObject }
  function RemoveChildObject(self, object)
    super.RemoveChildObject(self, object)

    self:SendMessageToParents("UNREGISTER_FRAME", object)
  end

  __Arguments__ { BaseObject }
  function AddChildObject(self, object)
    super.AddChildObject(self, object)

    if object.idleCountdowns then
      for owner, info in pairs(object.idleCountdowns) do
        self:AddIdleCountdown(owner, IdleCountdownInfo(info.countdown, info.duration))
        self:SendMessageToParents("ADD_IDLE_COUNTDOWN", owner, info.countdown)
      end
    end

    if self.idleCountdowns then
      for owner, info in pairs(self.idleCountdowns) do
        -- It's important to check the owner is well the parent, to avoid propagate
        -- the countdowns which have been added previously.
        if owner == self and info.applyToChildren then
          object:AddIdleCountdown(owner, IdleCountdownInfo(info.countdown, info.duration), true)
        end
      end
    end

    self:SendMessageToParents("REGISTER_FRAME", object)
  end
  ------------------------------------------------------------------------------
  --                        Size Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { Number }
  function SetWidth(self, width)
    self.width = width
    return self
  end

  __Arguments__ { Number }
  function SetHeight(self, height)
    self.height = height
    return self
  end

  __Arguments__ { Number, Number }
  function SetSize(self, width, height)
    self.width = width
    self.height = height
    return self
  end

  function GetValidParentWidth(self)
    local frame = self:GetFrameContainer()
    local parent = frame:GetParent()
    while(parent) do
      width = Ceil(parent:GetWidth())
      if width and width > 0 then
        return width
      end
      parent = parent:GetParent()
    end
  end

  function GetValidParentHeight(self)
    local frame = self:GetFrameContainer()
    local parent = frame:GetParent()
    while(parent) do
      height = Ceil(parent:GetHeight())
      if height and height > 0 then
        return height
      end
      parent = parent:GetParent()
    end
  end
  ------------------------------------------------------------------------------
  --                        SetPoint Methods                                  --
  ------------------------------------------------------------------------------
  -- It's highly advised to use these functions for anchoring frames

  __Arguments__ { String, Frame, String, Variable.Optional(Number), Variable.Optional(Number) }
  function SetPoint(self, point, relativeTo, relativePoint, xOffset, yOffset)
    SetPoint(self, point, relativeTo:GetFrameContainer(), relativePoint, xOffset, yOffset)
  end

  __Arguments__ { String, Table, String, Variable.Optional(Number), Variable.Optional(Number) }
  function SetPoint(self, point, relativeTo, relativePoint, xOffset, yOffset)
    if self:GetFrameContainer():IsProtected() or relativeTo:IsProtected() then
      NoCombat(function() self:GetFrameContainer():SetPoint(point, relativeTo, relativePoint, xOffset, yOffset) end)
    else
      self:GetFrameContainer():SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)
    end
  end

  __Arguments__ { String, Variable.Optional(Number, 0), Variable.Optional(Number, 0)}
  function SetPoint(self, point, offsetX, offsetY)
    if self:GetFrameContainer():IsProtected() then
      NoCombat(function() self:GetFrameContainer():SetPoint(point, offsetX, offsetY) end)
    else
      self:GetFrameContainer():SetPoint(point, offsetX, offsetY)
    end
  end

  function ClearAllPoints(self)
    if self:GetFrameContainer():IsProtected() then
      NoCombat(function() self:GetFrameContainer():ClearAllPoints() end)
    else
      self:GetFrameContainer():ClearAllPoints()
    end
  end
  ------------------------------------------------------------------------------
  --                 Visibility Methods                                       --
  ------------------------------------------------------------------------------
  --- Ask to the object to be shown.
  -- This is a safe method that can be called in combat even for proected frame, and multiples times.
  -- If the frame is protected, the frame will be shown when the player will be going out of combat.
  function Show(self)
    if self:GetFrameContainer():IsProtected() then
      NoCombat(function() self:ForceShow() end)
    else
      self:ForceShow()
    end
  end

  --- Ask to the object to be hidden.
  -- This is a safe method that can be called in combat even for protected frame and multiples times.
  -- If the frame is protected, the frame will be hidden when the player will be going out of combat.
  function Hide(self)
    if self:GetFrameContainer():IsProtected() then
      NoCombat(function() self:ForceHide() end)
    else
      self:ForceHide()
    end
  end

  --- Force the object to be shown.
  -- This method is not safe, so take care when you call it (e.g, check if the frame is protected)
  function ForceShow(self)
    self:OnShow()
  end

  --- Force the object to be hidden.
  -- This method  is not safe, so take care when you call it (e.g, check if the frame protected)
  function ForceHide(self)
    self:OnHide()
  end

  function OnShow(self)
    self:GetFrameContainer():Show()
  end

  function OnHide(self)
    self:GetFrameContainer():Hide()
  end

  --- Whether if the object is shown
  function IsShown(self)
    return self:GetFrameContainer():IsShown()
  end

  --- Toggle the object.
  -- This function uses 'Show' and 'Hide' methods, so this is safe method.
  function Toggle(self)
    if self:IsShown() then
      self:Hide()
    else
      self:Show()
    end
  end

  function ForceToggle(self)
    if self:IsShown() then
      self:ForceHide()
    else
      self:ForceShow()
    end
  end

  --- Request the object to be drawn.
  -- The object will be shown and layout its frame.
  -- The method uses 'Show' and 'Layout' so it's safe to use even in combat.
  function Draw(self)
    if not self._pendingDraw then
      self._pendingDraw = true
      Scorpio.Delay(0.25, function()
        local aborted = false
        if Interface.IsSubType(getmetatable(self), IReusable) and self.isReusable then
          aborted = true
        end

        if not aborted then
          self:ForceDraw()
        end

        self._pendingDraw = false
      end)
    end
  end

  --- Force the object to be drawn
  -- This function is not safe, so take care when you use it (e.g, if the frame is protected and the player is in combat).
  function ForceDraw(self)
    self:ForceShow()
    self:ForceLayout()
    self._needDraw = false
  end

  __Arguments__ { Number }
  function SetAlpha(self, alpha)
    self:GetFrameContainer():SetAlpha(alpha)
  end

  __Arguments__ { Number }
  function SetEffectiveAlpha(self, alpha)
    if not self:GetParentObject() then
      self:SetAlpha(alpha)
    else
      local parentAlpha = self:GetFrameContainer():GetEffectiveAlpha()
      local alphaToUse

      if parentAlpha == 0 then
        alphaToUse = 1
      else
        alphaToUse = alpha / parentAlpha
      end

      if alphaToUse >= 1 then
        self:SetAlpha(1)
      else
        self:SetAlpha(alphaToUse)
      end
    end
  end
  ------------------------------------------------------------------------------
  --                    Idle Mode Methods                                     --
  ------------------------------------------------------------------------------

  __Arguments__ { Variable.Optional(Boolean, false)}
  function OnEnterIdleMode(self, ignoreChildren)
    self:RefreshIdleModeAlpha(ignoreChildren)
  end

  __Arguments__ { Variable.Optional(Boolean, false) }
  function RefreshIdleModeAlpha(self, ignoreChildren)
    if not self.idleModeEnabled then
      return
    end

    if self.isInIdleMode then
      self:SetEffectiveAlpha(self.idleModeAlpha)
    else
      self:SetAlpha(1.0)
    end

    if not ignoreChildren then
      local childrens = self:GetChildObjects()
      if childrens then
        for child in pairs(childrens) do
          if child.RefreshIdleModeAlpha then
            child:RefreshIdleModeAlpha()
          end
        end
      end
    end
  end

  __Arguments__ { Variable.Optional(Boolean, false ) }
  function OnLeaveIdleMode(self, ignoreChildren)
    self:RefreshIdleModeAlpha(ignoreChildren)
  end

  function LeaveTemporalyIdleMode(self)
    self.idleModePaused = true
    self:SetAlpha(1.0)
  end

  function EnterInIdleModeFromTemporarly(self)
    self.idleModePaused = false
    if self.isInIdleMode and self.idleModeEnabled then
      self:SetEffectiveAlpha(self.idleModeAlpha)
    end
  end

  function OnIdleModeChange(self, value)
    if not self.hover then
      self:Skin()
    end
  end

  __Arguments__ { Boolean }
  function OnIdleModeEnabledChange(self, enabled)
    if not enabled then
      -- Remove the transparency
      self:SetAlpha(1.0)
      -- Clear all timers
      self:ClearIdleCountdowns()
      -- Set the idle mode to false without triggered the handler system
      self.__isInIdleMode = false
    end
  end

  __Arguments__ { Number }
  function OnIdleModeAlphaChange(self, alpha)
    if self.isInIdleMode then
      self:SetEffectiveAlpha(alpha, true)
    end
  end

  __Arguments__ { Number }
  function OnIdleModeTimerChange(self, timer) end

  __Arguments__ { Number }
  function OnInactivityTimerChange(self, timer) end

  __Arguments__ { String }
  function OnIdleModeTypeChange(self, type)
    if type == "basic-type" then
      self:SetAlpha(1.0)
    end
  end

  __Arguments__ { Variable.Optional(Boolean, false), Variable.Optional(Number, 0) }
  function WakeUp(self, wakeUpChildren, timer)
    timer = (timer == 0) and self.idleModeTimer or timer

    self:AddIdleCountdown(self, IdleCountdownInfo(timer, timer, wakeUpChildren))
    self:OnWakeUp()

    if wakeUpChildren then
      self:SendMessageToChildren("WAKE_UP", self, timer)
    end

    self:SendMessageToParents("WAKE_UP", self, timer)
  end

  __Arguments__ { Variable.Optional(Boolean, false) }
  function WakeUpPermanently(self, wakeUpChildren)
    self:WakeUp(wakeUpChildren, -1)
  end

  function OnWakeUp(self)
    self.isInIdleMode     = false
    self._inactivityTimer = nil
  end

  __Arguments__ { Variable.Optional(Boolean, false) }
  function Idle(self, applyToChildren)
    self:RemoveIdleCountdown(self, applyToChildren)
    self:SendMessageToParents("REMOVE_IDLE_COUNTDOWN", self)
  end

  __Arguments__ { BaseObject, IdleCountdownInfo, Variable.Optional(Boolean, false) }
  function AddIdleCountdown(self, owner, countdownInfo, applyToChildren)
    if not self.idleCountdowns then
      self.idleCountdowns = Dictionary()
    end

    self.idleCountdowns[owner] = countdownInfo

    if applyToChildren and self._childrenObject then
      for child in pairs(self._childrenObject) do
        child:AddIdleCountdown(owner, IdleCountdownInfo(countdownInfo.countdown, countdownInfo.duration), applyToChildren)
      end
    end
  end

  __Arguments__  { BaseObject, Variable.Optional(Boolean, false) }
  function RemoveIdleCountdown(self, owner, applyToChildren)
    if self.idleCountdowns then
      self.idleCountdowns[owner] = nil
    end

    if applyToChildren and self._childrenObject then
      for child in pairs(self._childrenObject) do
        child:RemoveIdleCountdown(owner, applyToChildren)
      end
    end
  end

  __Arguments__ { Variable.Optional(Boolean, false) }
  function ClearIdleCountdowns(self, applyToChildren)
    if self.idleCountdowns then
      for k in pairs(self.idleCountdowns) do
        self.idleCountdowns[k] = nil
      end
    end

    if applyToChildren and self._childrenObject then
      for child in pairs(self._childrenObject) do
        child:ClearIdleCountdowns(applyToChildren)
      end
    end
  end


  __Arguments__ { Number }
  function UpdateIdleCountdowns(self, diff)
    if self.idleCountdowns then
      for owner, info in self.idleCountdowns:GetIterator() do
        if info.duration ~= -1 then
          local final = math.max(0, info.countdown-diff)
          if final == 0 then
            self.idleCountdowns[owner] = nil
          else
            info.countdown = final
          end
        end
      end
    end
  end

  function GetEffectiveIdleCountdown(self)
    local maximum = 0
    if self.idleCountdowns then
      for owner, info in self.idleCountdowns:GetIterator() do
        if info.duration == -1 then
          maximum = info.countdown
          return info.countdown
        else
          if info.countdown > maximum then
            maximum = info.countdown
          end
        end
      end
    end
    return maximum
  end

  function PrintIdleCountdowns(self)
    print("-----------------------")
    print("--", class.GetObjectClass(self), "--")
    local index = 1
    if self.idleCountdowns then
      for owner, info in self.idleCountdowns:GetIterator() do
        print(index, class.GetObjectClass(owner), info.countdown, info.duration, info.applyToChildren)
        index = index + 1
      end
    end
    print("----------------------")
  end
  ------------------------------------------------------------------------------
  --                    SetParent Methods                                     --
  ------------------------------------------------------------------------------
  -- Set the frame's parent
  __Arguments__ { Frame }
  function SetParent(self, parent)
    SetParent(self, parent:GetFrameContainer())
  end

  __Arguments__ { Variable.Optional(Table) }
  function SetParent(self, parent)
    if self:GetFrameContainer():IsProtected() then
      NoCombat(function() self:OnParent(parent) end)
    else
      self:OnParent(parent)
    end
  end

  __Arguments__ { Variable.Optional(Table) }
  function OnParent(self, parent)
    -- Uninstall our obj if it's alreayd register for the layout system
    local oldParent = self:GetFrameContainer():GetParent()
    if oldParent and oldParent._ekt_objects then
      oldParent._ekt_objects[self] = nil
    end

    -- Install Layout part
    if parent then
      if not parent._ekt_objects then
        parent._ekt_objects = setmetatable({}, { mode = "k" })

        parent:HookScript("OnSizeChanged", function(f, width, height)
          if f._ekt_objects then
            for obj in pairs(f._ekt_objects) do
              if f:GetWidth() ~= Ceil(width) then
                obj:OnParentWidthChanged(Ceil(width))
              end

              if f:GetHeight() ~= Ceil(height) then
                obj:OnParentHeightChanged(Ceil(height))
              end
            end
          end
        end)
      end
      parent._ekt_objects[self] = true
    end
    self:GetFrameContainer():SetParent(parent)
  end
  ------------------------------------------------------------------------------
  --                   Layout Methods                                         --
  ------------------------------------------------------------------------------
  --- Select Layout that is adapted for the width avalaible.
  -- This function may be overrided if the frame need layout system.
  __Arguments__ { Number }
  function SelectLayout(self, width)
    self.layout = nil
  end

  --- This function may be overrided, and is called when the object does its layout.
  __Arguments__ { Variable.Optional(String, "") }
  function OnLayout(self, layoutName) end

  --- Ask to the object to layout its frame.
  -- This function is safe and be called multiple time in short time, resulting to one call.
  function Layout(self, layout)
    if not self._pendingLayout then
      self._pendingLayout = true
      Scorpio.Delay(0.1, function()
        local aborted = false
        if Interface.IsSubType(getmetatable(self), IReusable) and self.isReusable then
          self._needDoLayout = true
          aborted = true
        end

        if not aborted then
          self:ForceLayout()
        end
        self._pendingLayout = false
      end)
    end
  end

  --- This function will be called when the width of parent is changed
  -- During this moment, we check if the layout may be changed
  -- The function can be overrided, if the frame must be notified by this changed
  -- for doing its own stuffs.
  __Arguments__ { Number }
  function OnParentWidthChanged(self, width)
    self:SelectLayout(width)
  end

  --- This method will be called when the height of parent is changed.
  -- WARNING: Not enter in an infinite loop in changing the height
  __Arguments__ { Number }
  function OnParentHeightChanged(self, height)
    if not self._firstParentHeightChangedOccured then
      self:UpdateTextHeight()
      self._firstParentHeightChangedOccured = true
    end
  end

  --- This method will update the fonstring height, this is called by
  -- OnParentHeightChanged with a check for avoiding an infinite loop.
  -- Put here, your fonstrings height operations if you want something that is correct
  -- for their loading
  function UpdateTextHeight(self) end

  --- Force the object to layout its frames.
  function ForceLayout(self, layout)
    self:OnLayout(layout and layout or self.layout)
    self._needDoLayout = false
  end

  --- Whether the compact mode is enabled
  function CompactModeEnabled(self)
    return Options:Get("compact-mode-enabled")
  end
  ------------------------------------------------------------------------------
  --                   Skin Methods                                           --
  ------------------------------------------------------------------------------
  function Layout(self, layout)
    if not self._pendingLayout then
      self._pendingLayout = true
      Scorpio.Delay(0.1, function()
        local aborted = false
        if Interface.IsSubType(getmetatable(self), IReusable) and self.isReusable then
          self._needDoLayout = true
          aborted = true
        end

        if not aborted then
          self:ForceLayout()
        end
        self._pendingLayout = false
      end)
    end
  end

  --- Request the object to be skinned.
  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function Skin(self, flags, target)
    if not self._pendingSkin then
      self._pendingSkin = true
      Scorpio.Delay(0.1, function()
        local aborted = false
        if Interface.IsSubType(getmetatable(self), IReusable) and self.isReusable then
          self._needSkin = true
          aborted = true
        end

        if not aborted then
          self:ForceSkin(flags, target)
        end

        self._pendingSkin = false
      end)
    end
  end

  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function ForceSkin(self, flags, target)
    self:OnSkin(flags, target)
    self._needSkin = false
  end

  --- This function is called when the object needs to be skinned
  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function OnSkin(self, flags, target) end


  --- Returns the call prefix (static property '__prefix' )
  function GetClassPrefix(self)
    return Class.GetObjectClass(self)._prefix
  end
  ------------------------------------------------------------------------------
  --                   Option Methods                                         --
  ------------------------------------------------------------------------------
  --- Say if the option given is registered by frames, and must be alerted when
  --  the option is changed
  __Arguments__ { String }
  function IsRegisteredOption(self, option)
    return false
  end

  --- This function is called when an option event is triggered.
  -- This is called by 'HandleOption', 'LoadOption' and when the option has changed.
  __Arguments__ { String, Variable.Optional(), Variable.Optional() }
  function OnOption(self, option, newValue, oldValue) end


  __Arguments__ { String, Variable.Optional(), Variable.Optional() }
  function HandleOption(self, option, newValue, oldValue)
    self:OnOption(option, newValue, oldValue)
  end

  __Arguments__{ String }
  function LoadOption(self, option)
    local value = Options:Get(option)
    self:HandleOption(option, value)
  end

  __Arguments__ { String }
  function AddPendingOption(self, option)
    if not self._pendingOptionList then
      self._pendingOptionList = {}
    end

    self._pendingOptionList[option] = true
  end

  function ProcessPendingOption(self)
    if not self._pendingOptionList then
      return
    end

    for option in pairs(self._pendingOptionList) do
      local value = Options:Get(option)
      self:OnOptionChanged(option, value)
    end

    self._pendingOptionList = nil
  end
  ------------------------------------------------------------------------------
  --                    Reset & Recycle Methos                                --
  ------------------------------------------------------------------------------
  function Reset(self)
    self:OnReset()
  end

  function OnReset(self)
    self.isInIdleMode     = nil
    self.idleModeType     = nil
    self.idleModeTimer    = nil
    self.idleModeAlpha    = nil
    self.idleModeType     = nil
    self.alpha            = nil
    self.hover            = nil
  end

  function OnRecycle(self)
    -- Make some stuff
    self:Hide()
    self:ClearAllPoints()
    self:SetParent()
    self:SetParentObject()
    self:ClearIdleCountdowns()
    self:SetAlpha(1)

    -- Remove event handlers
    self.OnHeightChanged = nil
    self.OnWidthChanged  = nil

    -- Reset properties
    self:Reset()
  end
  ------------------------------------------------------------------------------
  --                   Other Methods                                          --
  ------------------------------------------------------------------------------
  -- Return the frame which must be used for anchor/show features
  -- May be overrided to change the frame
  function GetFrameContainer(self)
    return self.frame
  end

  -- Returns the current state. Nil if there is no state.
  -- This method may be overrided if the frame uses states.
  function GetCurrentState(self)
    return nil
  end

  -- Build and return the current in function if it's hover or not.
  __Arguments__ { String, Variable.Optional(Boolean)}
  function BuildState(self, state, hover)
    if hover == nil then
      hover = self.hover
    end

    if hover then
      return string.format("hover,%s", state)
    else
      return state
    end
  end


  -- This function is called when the object has been created, and we must
  -- init the frames (e.g, register theme in the theme system and skin them)
  -- This function must always be called of this way from constructor: This.Init()
  function Init(self) end

  --- Ask to the object to be reloaded
  function Reload(self)
    self:OnReload()
  end

  --- This function is called when the object must be reloaded
  function OnReload(self) end

  --- This function is called when the context menu must be parepared (add action, link to frame)
  function PrepareContextMenu(self) end

  -- This function is called when the hover state has changed
  __Arguments__ { Boolean }
  function OnHover(self, hover)
    self.idleModePaused = hover
    self:ForceSkin()
  end
  ------------------------------------------------------------------------------
  --                   Static Functions                                       --
  ------------------------------------------------------------------------------
  --- Broadcast the options to the frames
  __Arguments__ { ClassType, String, Variable.Optional(), Variable.Optional(), Variable.Optional(Table) }
  __Static__() function BroadcastOption(class, option, newValue, oldValue, objectList)
    local objects = objectList and objectList or _FrameCache
    for obj in pairs(objects) do
      if obj:IsRegisteredOption(option) then
        if not obj.isReusable then
          obj:OnOption(option, newValue, oldValue)
        else
          obj:AddPendingOption(option)
        end
      end
    end
  end

  --- Reskin all frames in calling their Skin method
  __Arguments__ { ClassType, Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String, "ALL"), Variable.Optional(Table) }
  __Static__() function SkinAll(class, flags, target, objectList)
    local objects = objectList and objectList or _FrameCache
    -- TODO: Add Theme:EnableCaching
    for obj in pairs(objects) do
      obj:Skin(flags, target)
    end
    -- TODO: Add Theme:DisableCaching
  end

  --- Reload all frames in calling their OnReload method
  __Arguments__ { ClassType, Variable.Optional(Table) }
  __Static__() function ReloadAll(class, objectList)
    local objects = objectList and objectList or _FrameCache
    for obj in pairs(objects) do
      obj:Reload()
    end
  end

  function NotifyScriptToParents(self, script)
    self:SendMessageToParents(script)
  end


  __Async__()
  __Static__() function StartUpdateLoop(self)
    while true do
      for obj in pairs(_FrameCache) do
        local frame = obj:GetFrameContainer()
        obj.hover = frame and frame:IsMouseOver() or false
      end

      Delay(0.1)
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "frame" { TYPE = Table }
  property "width" { TYPE = Number, HANDLER = UpdateWidth, DEFAULT = 0 }
  property "height" { TYPE = Number, HANDLER = UpdateHeight, DEFAULT = 0 }
  property "baseHeight" { TYPE = Number, DEFAULT = 0 }
  property "baseWidth" { TYPE = Number, DEFAULT = 0 }
  property "relWidth" { TYPE = Number }
  property "layout" { TYPE = String, DEFAULT = "", UpdateLayout }
  property "_pendingDraw" { TYPE = Boolean, DEFAULT = false }
  property "_pendingSkin" { TYPE = Boolean, DEFAULT = false }
  property "_pendingLayout" { TYPE = Boolean, DEFAULT = false }
  property "_pendingOption" { TYPE = Boolean, DEFAULT = false }
  property "_needDraw" { TYPE = Boolean, DEFAULT = false }
  property "_needSkin"{ TYPE = Boolean, DEFAULT = false }
  property "_needDoLayout" { TYPE = Boolean, DEFAULT = false }
  property "isInIdleMode" { TYPE = Boolean, FIELD = "__isInIdleMode", DEFAULT = false, HANDLER = UpdateIdleModeProps }
  property "idleModeEnabled" { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateIdleModeProps }
  property "idleModePaused" { TYPE = Boolean, DEFAULT = false}
  property "idleModeTimer"  { TYPE = Number, DEFAULT = function(self) return self.inactivityTimer end }
  property "idleModeAlpha"  { TYPE = Number, DEFAULT = 0.35, HANDLER = UpdateIdleModeProps }
  property "idleModeType"   { TYPE = String, DEFAULT = "basic-type", HANDLER = UpdateIdleModeProps }
  property "alpha"          { TYPE = Number, DEFAULT = 0.50 }
  property "inactivityTimer" { TYPE = Number, DEFAULT = 4, HANDLER = UpdateIdleModeProps }
  property "hover"           { TYPE = Boolean, DEFAULT = false, HANDLER = function(self, new) self:OnHover(new) end}

  __Static__() property "idleModeTimerLaunched" { TYPE = Boolean, DEFAULT = false }


  __Arguments__ {}
  function Frame(self)
    _FrameCache[self] = true
  end

  __Arguments__ { Table }
  function Frame(self, frame)
    this(self)

    self.frame = frame
  end

end)


class "FrameRow" (function(_ENV)
  inherit "Frame"
  ------------------------------------------------------------------------------
  --                         Methods                                          --
  ------------------------------------------------------------------------------
  __Arguments__ { Frame }
  function AddFrame(self, frame)
    frame:SetParent(self)
    self.frames:Insert(frame)

    frame.OnHeightChanged = function()
      self:Layout()
    end

    self:Layout()
  end

  __Arguments__ { Frame }
  function RemoveFrame(self, frame)
    if self.frames:Remove(frame) then
      frame:SetParent()
      frame:ClearAllPoints()
      frame:Hide()
      frame.OnHeightChanged = nil

      self:Layout()
    end
  end

  function OnLayout(self)
  if self.layout and self.layout == "Flow" then
      self:ApplyLayoutFlow()
    else
      self:ApplyLayoutList()
    end
  end

  -- NOTE: We need to override the function in order to avoid self.layout is reset
  __Arguments__ { Number}
  function SelectLayout(self, width)
    return self.layout
  end
  ------------------------------------------------------------------------------
  --                     Flow Layout part                                     --
  ------------------------------------------------------------------------------
  function ApplyLayoutFlow(self)
    local width         = self.frame:GetWidth() > 0 and self.frame:GetWidth() or self:GetValidParentWidth()
    local widthUsable   = width - self.offsetX * 2
    local centeredFrame = self.alignment and self.alignment == "CENTER"
    -- Row variables
    local rowWidth      = 0
    local startNewRow   = true
    local rowHeight     = 0
    local offsetY       = self.offsetY
    local rowFirstObj -- use in order to center frames


    for index, obj in self.frames:GetIterator() do
      -- Do init stuff for objects
      obj:ClearAllPoints()
      obj:Show()
      -- Calculate the width if there is a relative width
      if obj.relWidth then
        obj.width = obj.relWidth * widthUsable
      end

      -- Specific stuffs for the first object
      if index == 1 then
        rowFirstObj = obj
        startNewRow = false

        -- Set position
        obj:SetPoint("TOP", 0, -offsetY)
        obj:SetPoint("LEFT", self.offsetX, 0)
      else
        -- First, check if there is enought space for next object
        if rowWidth + obj.width >= widthUsable then
          startNewRow = true

          offsetY   = offsetY + rowHeight + self.verticalSpacing
          rowHeight = 0
        end

        -- must we start a new row ?
        if startNewRow then
          -- Center the frames of the previous row
          if centeredFrame then
            -- REVIEW the formula may be wrong
            rowFirstObj:SetPoint("LEFT", ((widthUsable - rowWidth) / 2) + self.offsetX, 0)
          end

          obj:SetPoint("TOP", 0, -offsetY)
          obj:SetPoint("LEFT", self.offsetX)

          startNewRow = false
          rowWidth    = 0
          rowFirstObj = obj
        else
          obj:SetPoint("LEFT", previousFrame, "RIGHT", self.horizontalSpacing, 0)
        end
      end

      rowWidth      = rowWidth + obj.width + self.horizontalSpacing -- Important to include the spacing here
      rowHeight     = max(rowHeight, obj.height)
      previousFrame = obj.frame
    end

    -- Center the last row if needed
    if centeredFrame then
      rowFirstObj:SetPoint("LEFT", ((widthUsable - rowWidth) / 2) + self.offsetX)
    end

    self:CalculateFlowLayoutHeight()
  end

  function CalculateFlowLayoutHeight(self)
    local height = self.baseHeight

    local width       = self.frame:GetWidth() > 0 and self.frame:GetWidth() or self:GetValidParentWidth()
    local widthUsable = width - self.offsetX + 2
    -- Row variables
    local rowWidth    = 0
    local startNewRow = true
    local rowHeight   = 0
    local rowsHeight  = 0

    for index, obj in self.frames:GetIterator() do
      if obj.relWidth then
        obj.width = obj.relWidth * widthUsable
      end

      if index == 1 then
        startNewRow = false
      else
        if rowWidth + obj.width >= widthUsable then
          startNewRow = true
        end

        if startNewRow then
          rowsHeight = rowsHeight + rowHeight + self.verticalSpacing
          rowHeight  = 0
          rowWidth   = 0
          startNewRow = false
        end
      end

      rowWidth  = rowWidth + obj.width + self.horizontalSpacing
      rowHeight = max(rowHeight, obj.height)
    end

    rowsHeight = rowsHeight + rowHeight

    height = rowsHeight + (2 * self.offsetY)

    self.height = height
  end
  ------------------------------------------------------------------------------
  --                     List Layout part                                     --
  ------------------------------------------------------------------------------
  function ApplyLayoutList(self)
    local width = self.frame:GetWidth() > 0 and self.frame:GetWidth() or self:GetValidParentWidth()
    local widthUsable = width - self.offsetX * 2
    local mustCenteredFrame = (self.alignment and self.alignment == "CENTER")
    local previousFrame

    for index, frame in self.frames:GetIterator() do
      frame:ClearAllPoints()
      frame:Show()

      if frame.relWidth then
        frame.width = frame.relWidth * widthUsable
      end

      if index == 1 then
          frame:SetPoint("TOP", 0, -self.offsetY)

          if not mustCenteredFrame then
            frame:SetPoint("LEFT", self.offsetX)
          end
      else
        frame:SetPoint("TOP", previousFrame, "BOTTOM", 0, -self.verticalSpacing)

        if not mustCenteredFrame then
          frame:SetPoint("LEFT", offsetX)
        end
      end

      previousFrame = frame
    end

    self:CalculateListLayoutHeight()
  end


  function CalculateListLayoutHeight(self)
    local height = self.baseHeight + self.offsetY * 2

    for index, frame in self.frames:GetIterator() do
      height = height + frame.height

      if index > 1 then
        height = height + self.verticalSpacing
      end
    end

    self.height = height
  end


  function CalculateHeight(self)
    if self.layout and self.layout == "Flow" then
      self:CalculateFlowLayoutHeight()
    else
      self:CalculateListLayoutHeight()
    end
  end

  --- If the parent width has changed, we need to re-layout frames to update
  -- their width
  __Arguments__ { Number }
  function OnParentWidthChanged(self, width)
    super.OnParentWidthChanged(self, width)

    self:Layout()
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "alignment"          { TYPE = String, DEFAULT = "CENTER"}
  property "horizontalSpacing"  { TYPE = Number, DEFAULT = 2 }
  property "verticalSpacing"    { TYPE = Number, DEFAULT = 2}
  property "offsetY"            { TYPE = Number, DEFAULT = 2 }
  property "offsetX"            { TYPE = Number, DEFAULT = 2}
  ---------------------------------------------- --------------------------------
  --                         Constructor                                      --
  ------------------------------------------------------------------------------
  function FrameRow(self)
    super(self, CreateFrame("Frame"))

    self.frames = List()

    self.height     =  0
    self.baseHeight =  self.height
  end
end)

function OnLoad(self)
  Frame.StartUpdateLoop()
end
