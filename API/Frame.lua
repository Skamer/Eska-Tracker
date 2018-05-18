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



class "Frame" (function(_ENV)
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
    new = Ceil(new)
    old = Ceil(old)

    if frame then
      frame:SetHeight(new)
    end
    return OnHeightChanged(self, new, old)
  end

  local function UpdateWidth(self, new, old)
    local frame = self:GetFrameContainer()
    -- Ceil the values
    new = Ceil(new)
    old = Ceil(old)

    if frame then
      frame:SetWidth(new)
    end

    return OnWidthChanged(self, new, old)
  end

  local function UpdateLayout(self)
    self:Layout()
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




  -- SkinCache
    -- |- elementID -- Completed -> "text-align" ->

  -- EnableThemeCache()

  -- DisableThemeCache()
  --SkinAll("quest.name", flags, )
  --SkinAll(flags, "quest.name") -- ALL


  --Theme:MustSkinFrame(idCheck, frame)

  --EQT.Frame:SkinAll
  --EQT.Frame:ReloadAll()
  --EQT.Frame:HandleOption()

  --EQT.Block:SkinAll()
  --EQT.Block:ReloadAll()
  --EQT.Block:HandleOption()

  --EQT.Frame:ReloadAll(framesList)


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
