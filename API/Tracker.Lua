-- ========================================================================== --
-- 										    EskaQuestTracker                                    --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio             "EskaTracker.API.Tracker"                            ""
-- ========================================================================== --
namespace "EKT"
-- ========================================================================== --
Ceil = math.ceil
--============================================================================--
class "Tracker" (function(_ENV)
  inherit "BorderFrame"

  _TrackerCache = setmetatable( {}, { __mode = "k"} )
  event "OnHeightChanged"
  event "OnWidthChanged"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  ------------------------------------------------------------------------------


  local function SetContentHeight(self, new, old)
    -- Update the content size
    self.content:SetHeight(new)
    -- Update the scroll bar visibility
    self:UpdateScrollbarVisibility()
  end

  local function UpdateProps(self, new, old, prop)

  end

  local function UpdateWidth(self, new, old)
    local frame = self:GetFrameContainer()
    -- Ceil the values
    new = Ceil(new)
    old = Ceil(old)

    if frame then
      frame:SetWidth(new)
    end

    -- Update the Database
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("width", new)
    end

    return OnWidthChanged(self, new, old)
  end

  local function UpdateHeight(self, new, old)
    local frame = self:GetFrameContainer()
    -- Ceil the values
    new = Ceil(new)
    old = Ceil(old)

    if frame then
      frame:SetHeight(new)
    end

    -- Update the Database
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("height", new)
    end

    return OnHeightChanged(self, new, old)
  end

  local function UpdateLock(self, new)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("locked", locked)
    end

    self:GetFrameContainer():EnableMouse(not new)
    self:GetFrameContainer():SetMovable(not new)

  end

  local function UpdateID(self, new)
    -- Build name from id
    local name = new
    -- Remove '-tracker'
    name = name:gsub("(-tracker)$", "")
    -- Upper the first letter of each word
    name = API:UpperFirstOfEach(name)

    self.name = name
  end

  local function PrepareNotifications(self, useNotifications)
    if useNotifications then
      Notifications().OnHeightChanged = function(_, new, old)
        self.contentHeight = self.contentHeight + (new - old)
        if new == 0 then
          Notifications():Hide()
        elseif old == 0 then
          Notifications():Show()
        end
      end

      self:Layout()
    end
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
  --                             Methods                                      --
  ------------------------------------------------------------------------------

  --[[
  function GetXPos()
    return self.__xPos
  end

  function GetYPos()
    return self.__yPos
  end

  function SetXPos(self, x)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("xPos", x)
    end

    self.__xPos = xPos
  end

  function SetYPos(self, y)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("yPos", y)
    end

    self.__yPos = yPos
  end

  function GetWidth()
    return self.__width
  end

  function GetHeight()
    return self.__height
  end


  function SetWidth(self, width)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("width", width)
    end

    print("SetWidth", width)
  end

  function SetHeight(self, height)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("height", height)
    end

    self.__height = height
  end

  --]]

  __Arguments__ { Number, Number, Variable.Optional(Boolean, true) }
  function SetPosition(self, x, y, saveInDB)
    self.xPos = x
    self.yPos = y

    self:ClearAllPoints()
    self:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y)

    if saveInDB then
      Database:SelectRoot()
      if Database:SelectTable(true, "trackers", self.id) then
        Database:SetValue("xPos", x)
        Database:SetValue("yPos", y)
      end
    end
  end

  function SetLocked(self, locked)
    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      Database:SetValue("locked", locked)
    end

    self.__locked = locked
  end

  function IsLocked(self)
    return self.__locked
  end --]]

  function UpdateScrollbarVisibility(self)
    -- Check if the scrollbar is needed or not
    local parentHeight = self.scrollFrame:GetHeight()
    local isNeeded = self.contentHeight >= parentHeight

    -- Options:Get("tracker-show-scrollbar")
    if isNeeded and Options:Get("tracker-show-scrollbar") then
      self.scrollbar:Show()
    else
      self.scrollbar:Hide()
    end

    self:Layout()

    --self:ForceLayout()
    Scorpio.FireSystemEvent("EQT_SCROLLBAR_VISIBILITY_CHANDED")
  end

  function OnLayout(self)
    self.content:ClearAllPoints()
    self.content:SetPoint("TOP")
    self.content:SetPoint("LEFT")
    if self.scrollbar:IsShown() then
      --self.scrollFrame:SetPoint("RIGHT", self.scrollbar, "LEFT")
      self.content:SetWidth(self:GetFrameContainer():GetWidth() - 2 * self.borderWidth - self.scrollbar:GetWidth())
    else
      --self.scrollFrame:SetPoint("RIGHT")
      self.content:SetWidth(self:GetFrameContainer():GetWidth() - 2 * self.borderWidth)
    end

    local mustDisplayNotifications = self.displayNotifications and Notifications():IsShown()

    if mustDisplayNotifications then
      Notifications():ClearAllPoints()
      Notifications():SetParent(self.content)
      Notifications():SetPoint("TOP")
      Notifications():SetPoint("LEFT")
      Notifications():SetPoint("RIGHT")
    end

    local previousBlock
    for index, obj in self.blocks:GetIterator() do
      obj:ClearAllPoints()

      if index == 1 then
        if mustDisplayNotifications  then
          obj:SetPoint("TOP", Notifications(), "BOTTOM")
        else
          obj:SetPoint("TOP")
        end
        obj:SetPoint("LEFT")
        obj:SetPoint("RIGHT")
      else
        obj:SetPoint("TOPLEFT", previousBlock.frame, "BOTTOMLEFT", 0, -4)
        obj:SetPoint("TOPRIGHT", previousBlock.frame, "BOTTOMRIGHT")
      end

      previousBlock = obj
    end

    self:CalculateHeight()
  end

  function CalculateHeight(self)
    local height = 0
    if self.displayNotifications then
      height = height + Notifications().height
    end

    for index, obj in self.blocks:GetIterator() do
      height = obj.height

      if index > 1 then
        height = height + 4
      end
    end

    self.contentHeight = height
  end

  function Load(self)
    local xPos, yPos, width, height, locked

    Database:SelectRoot()
    if Database:SelectTable(true, "trackers", self.id) then
      width = Database:GetValue("width")
      height = Database:GetValue("height")
      locked = Database:GetValue("locked")
      xPos = Database:GetValue("xPos")
      yPos = Database:GetValue("yPos")
    end

    self.height = height
    self.width = width
    self.locked = locked

    if xPos and yPos then
      self:SetPosition(xPos, yPos, false)
    end
  end

  function Init(self)
    local prefix = self:GetClassPrefix()

    Theme:RegisterFrame(prefix..self.id..".frame", self.frame, prefix..".frame")
    Theme:RegisterFrame(prefix..self.id..".scrollbar", self.scrollbar, prefix..".scrollbar")
    Theme:RegisterTexture(prefix..self.id..".scrollbar.thumb", self.scrollbar.thumb, prefix..".scrollbar.thumb")

    Theme:SkinFrame(self.frame)
    self:SkinBorder(self.frame) -- Don't forget to skin the border, this features brought by BorderFrame
    Theme:SkinFrame(self.scrollbar)
    Theme:SkinTexture(self.scrollbar.thumb)
  end


  __Arguments__ { Block }
  function AddBlock(self, block)
    if not self.blocks:Contains(block) then
      self.blocks:Insert(block)

      block:SetParent(self.content)

      block.OnHeightChanged = function(block, newHeight, oldHeight)
        self.contentHeight = self.contentHeight + (newHeight - oldHeight)
      end

      self:Draw()
    end
  end

  __Arguments__ { Block }
  function RemoveBlock(self, block)
    self.blocks:Remove(block)
  end

  function GetBlocks(self)
    return self.blocks
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "id" { TYPE = String, DEFAULT = "", HANDLER = UpdateID}
  property "name" { TYPE = String }
  property "displayRules" { TYPE = DisplayRules }
  property "xPos" { TYPE = Number, DEFAULT = 0 }
  property "yPos" { TYPE = Number, DEFAULT = 0 }
  property "width" { TYPE = Number, DEFAULT = 200,  HANDLER = UpdateWidth }
  property "height" { TYPE = Number, DEFAULT = 200, HANDLER = UpdateHeight}
  property "locked" { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateLock }
  property "contentHeight" { TYPE = Number, DEFAULT = 50, HANDLER = SetContentHeight }
  property "displayNotifications" { TYPE = Boolean, DEFAULT = false, HANDLER = PrepareNotifications }


  __Static__() property "_prefix" { DEFAULT = "tracker" }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function Tracker(self, id)
    super(self)



    local name = string.format("EskaTracker-%s", id)
    self.id = id

    self.frame = CreateFrame("Frame", name)
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 1, 0, 1)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)
    self:SetParent(UIParent)
    self:GetFrameContainer():SetHeight(self.height)
    self:GetFrameContainer():SetWidth(self.width)
    self:GetFrameContainer():SetClampedToScreen(true)
    self:GetFrameContainer():SetFrameStrata("LOW")
    self:SetPoint("CENTER")
    self:GetFrameContainer():EnableMouse(not self.locked)
    self:GetFrameContainer():SetMovable(not self.locked)

    -- Drag and move functions
    self:GetFrameContainer():SetScript("OnMouseDown", function(_, button)
        if button == "LeftButton" and not self.locked then
          self:GetFrameContainer():StartMoving()
        end
    end)

    self:GetFrameContainer():SetScript("OnMouseUp", function(_, button)
      if button == "LeftButton" and not self.locked then
        self:GetFrameContainer():StopMovingOrSizing()


        local xPos = self:GetFrameContainer():GetLeft()
        local yPos = self:GetFrameContainer():GetBottom()
        self:SetPosition(xPos, yPos)

        self:GetFrameContainer():SetUserPlaced(false)
      end
    end)


    local scrollFrameName = string.format("%s%s", name, "ScollFrame")
    local scrollFrame = CreateFrame("ScrollFrame", name, self.frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOP")
    scrollFrame:SetPoint("LEFT")
    scrollFrame:SetPoint("RIGHT")
    scrollFrame:SetPoint("BOTTOM")
    scrollFrame:SetBackdrop(_Backdrops.Common)
    scrollFrame:SetBackdropColor(1, 1, 0, 0)
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

    self.content = content
    self.scrollFrame = scrollFrame
    self.scrollbar = scrollbar
    self.scrollbar.thumb = thumb

    _TrackerCache[self] = true

    Init(self)

    -- OnHeightChanged event handler
    function self:OnHeightChanged(new, old)
      self:GetFrameContainer():SetHeight(new)

      -- Update the scroll bar visibility
      self:UpdateScrollbarVisibility()
    end

    -- OnBorderWidthChanged
    function self:OnBorderWidthChanged(self, new)
      self:UpdateScrollbarVisibility()

      Scorpio.FireSystemEvent("EQT_TRACKER_CONTENT_SIZE_CHANGED", self.id, new)
    end
    --
    self.blocks = Array[Block]()

  end

end)

-- EQT_TRACKER_POSITION_CHANGED id, xPos, yPos
-- EQT_TRACKER_SIZE_CHANGED id, height, width
-- EQT_TRACKER_SCROLLBAR_VISIBILITY_CHANDED id


--

class "Trackers" (function(_ENV)
  _TRACKERS = Dictionary()


  function New(self, id)
    if not self:Get(id) then
      local tracker = Tracker(id)
      self:Register(tracker, false)
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

  __Arguments__ { ClassType, Tracker, Variable.Optional(Boolean, true) }
  __Static__() function Register(self, tracker, needCheck)
    if needCheck and self:Get(tracker.id) then
      return
    end

    _TRACKERS[tracker.id] = tracker
  end

  __Arguments__ {  ClassType }
  __Static__() function GetIterator()
    return _TRACKERS:GetIterator()
  end

  __Arguments__ { ClassType }
  __Static__() function LoadFromDB(self)
    Database:SelectRoot()

    if Database:SelectTable(false, "trackers") then
      for id, trackerDB in Database:IterateTable() do
        if not self:Get(id) then
          local tracker = Tracker(id)
          tracker.height = trackerDB.height
          tracker.width  = trackerDB.width
          tracker.locked = trackerDB.locked

          tracker:SetPosition(trackerDB.xPos or 0, trackerDB.yPos or 0, false)

          self:Register(tracker, false)
        end
      end
    end
  end

end)


function OnLoad()
  -- We need to have at least a tracker
  local mainTracker = Tracker("Main")
  mainTracker:Load()
  mainTracker.displayNotifications = true
  mainTracker.height = 500
  -- Register it
  Trackers:Register(mainTracker)

  -- Load all others tracker from the DB
  Trackers:LoadFromDB()
end

--[[

Trackers:Add(id)


Tracker:GetPosition()


Trackers:RegisterBlock(EQT.Blocks)
Trackers:New(id)


Tracker:AddBlockCategory("quests")

Trackers:Get(id)
Trackers:GetSelectedForBlockCategory("quests")

Tracker:SetDisplayRules()

--]]
