--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                     "EskaTracker.API.Block"                              ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "BlockCategory" (function(_ENV)
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  event "OnOrderChanged"
  event "OnShowHeaderChanged"
  event "OnHeaderHeightChanged"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateOrder(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      if new == self._initOrder then
        Database:SetValue("order", nil)
      else
        Database:SetValue("order", new)
      end
    end

    self:OnOrderChanged(new)
  end

  local function UpdateSelected(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      if new == self._initSelected then
        Database:SetValue("selected", nil)
      else
        Database:SetValue("selected", new)
      end
    end
  end

  local function UpdateTracker(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      local defaultValue = API:GetDefaultValueFromObj(self, "tracker")
      if defaultValue == new then
        Database:SetValue("tracker", nil)
      else
        Database:SetValue("tracker", new)
      end
    end
  end

  local function UpdateShowHeader(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      Database:SetValue("show-header", new)
    end

    self:OnShowHeaderChanged(new)
  end

  local function UpdateHeaderHeight(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      Database:SetValue("header-height", new)
    end

    self:OnHeaderHeightChanged(new)
  end

  local function UpdateContentMarginTop(self, new)
    Profiles:PrepareDatabase()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      if new == self.__initContentMarginTop then 
        Database:SetValue("content-margin-top", nil)
      else 
        Database:SetValue("content-margin-top", new)
      end
    end

    self:OnContentMarginTop(new)
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function GetTracker(self)
    if not self.__tracker then
      Profiles:PrepareDatabase()
      --Database:PrepareDatabase()
      if Database:SelectTable(false, "blocks", "categories", self.id) then
        local value = Database:GetValue("tracker")
        if value then
          return value
        end
      end
    end

    return self.__tracker
  end

  function SetTracker(self, value)
    local useDefaultValue = false
    if value == nil then
      value = API:GetDefaultValueFromObj(self, "tracker")
      useDefaultValue = true
    end

    if value ~= self.tracker then
      Profiles:PrepareDatabase()
      if Database:SelectTable(true, "blocks", "categories", self.id) then
        if useDefaultValue then
          Database:SetValue("tracker", nil)
        else
          Database:SetValue("tracker", value)
        end
      end
    end
    self.__tracker = value
  end

  function TryToGetValidBlock(self)
    -- Get the block selected by category
    local selected = self.selected

    local blockClass = Blocks:Get(selected)
    if blockClass then
      return selected, blockClass
    end

    -- if block is always nil, this is because the block selected don't exists or has been not registered !
    -- so get the first block found with the category given
    blockClass = Blocks:GetFirstForCategory(self.id)
    if blockClass then
      return API:GetDefaultValueFromClass(blockClass, "id"), blockClass
    end
  end


    function LoadPropsFromDatabase(self)
      -- Load the properties contained in the profile
      Profiles:PrepareDatabase()

      local order, tracker, showHeader, headerHeight, contentMarginTop
      if Database:SelectTable(false, "blocks", "categories", self.id) then
        order             = Database:GetValue("order")
        tracker           = Database:GetValue("tracker")
        showHeader        = Database:GetValue("show-header")
        headerHeight      = Database:GetValue("header-height")
        contentMarginTop  = Database:GetValue("content-margin-top")
      end

      -- Assign the values
      self.order            = order
      self.tracker          = tracker
      self.showHeader       = showHeader
      self.headerHeight     = headerHeight
      self.contentMarginTop = contentMarginTop
    end

  property "id"             { TYPE = String, FIELD = "__id" }
  property "name"           { TYPE = String, FIELD = "__name" }
  property "order"          { TYPE = Number, HANDLER = UpdateOrder, DEFAULT = function(self) return self._initOrder end, FIELD = "__order" }
  property "selected"       { TYPE = String, HANDLER = UpdateSelected, DEFAULT = function(self) return self._initSelected end, FIELD = "__selected" }
  property "tracker"        { TYPE = String, HANDLER = UpdateTracker, DEFAULT = "main", GET = "GetTracker", SET = "SetTracker" }
  property "showHeader"     { TYPE = Boolean, HANDLER = UpdateShowHeader, DEFAULT = true }
  property "headerHeight"   { TYPE = NaturalNumber, HANDLER = UpdateHeaderHeight, DEFAULT = 34}
  property "contentMarginTop" { TYPE = Number, HANDLER = UpdateContentMarginTop, DEFAULT = function(self) return self._initContentMarginTop end, FIELD = "__contentMarginTop"}
  property "_initOrder"     { TYPE = Number, DEFAULT = 100 }
  property "_initSelected"  { TYPE = String }
  property "_initContentMarginTop" { TYPE = Number, DEFAULT = 5 }

  __Arguments__ { String, String }
  function BlockCategory(self, id, name)
    self.__id = id
    self.__name = name
  end

  __Arguments__ { String , String, Number }
  function BlockCategory(self, id, name, order)
    this(self, id, name)
    self._initOrder = order
  end

  __Arguments__ { String , String, Number, String }
  function BlockCategory(self, id, name, order, selected)
    this(self, id, name, order)
    self._initSelected = selected
  end

  __Arguments__ { String, String, String}
  function BlockCategory(self, id, name, selected)
    this(self, id, name)
    self._initSelected = selected
  end

end)

class "Block" (function(_ENV)
  inherit "Frame"
  event "OnActiveChanged"
  event "OnOrderChanged"
  _BlockCache = setmetatable( {}, { __mode = "k" })
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function SetText(self, new)
    local state = self:GetCurrentState()
    Theme:SkinText(self.frame.header.text, Theme.SkinFlags.TEXT_TRANSFORM, new, state)
  end

  local function SetContentHeight(self, new, old)
    self.frame.content:SetHeight(new)

    self.height = self.height + (new - old)
  end

  local function IsActiveChanged(self, new, old)
    if new then
      local category = Blocks:GetCategory(self.category)
      Trackers:TransferBlock(self.category, category.tracker)
    else
      local tracker = Trackers:GetTrackerByBlockCategoryID(self.category)
      if tracker then
        tracker:RemoveBlock(self)
      end
    end
  end
  ------------------------------------------------------------------------------
  --                        Idle. Methods                                     --
  ------------------------------------------------------------------------------
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
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String) }
  function OnSkin(self, flags, target)
      -- Call our super 'OnSkin'
      super.OnSkin(self, flags, target)
      -- Get the current state
      local state = self:GetCurrentState()

      -- Start Skinning stuff is needed
      if Theme:NeedSkin(self.frame, target) then
        Theme:SkinFrame(self.frame, flags, state)
      end

      if Theme:NeedSkin(self.frame.header, target) then
        Theme:SkinFrame(self.frame.header, flags, state)
      end

      if Theme:NeedSkin(self.frame.content, target) then
        Theme:SkinFrame(self.frame.content, flags, state)
      end

      if Theme:NeedSkin(self.frame.header.text, target) then
        Theme:SkinText(self.frame.header.text, flags, self.text, state)
      end

      if Theme:NeedSkin(self.frame.header.stripe, target) then
        Theme:SkinTexture(self.frame.header.stripe, flags, state)
      end
  end

  function Expand(self)
    if not self.expanded then
      -- hide the content
      self.frame.content:Show()
      -- Update the height
      self:CalculateHeight()

      self.expanded = true
    end
  end

  function Collapse(self)
    if self.expanded then
      -- Show the content
      self.frame.content:Hide()
      -- Update the height
      self.height = self.baseHeight

      self.expanded = false
    end
  end

  function ShowHeader(self)
    if not self.frame.header:IsShown() then
      self.baseHeight = self.headerHeight
      self.height = self.height + self.headerHeight

      self.frame.header:Show()
      self.frame.content:SetPoint("TOP", self.frame.header, "BOTTOM", 0, -self.contentMarginTop)
    end
  end

  function HideHeader(self)
    if self.frame.header:IsShown() then
      self.baseHeight = 0
      self.height = self.height - self.headerHeight

      self.frame.header:Hide()
      self.frame.content:SetPoint("TOP", 0, -self.contentMarginTop)
    end
  end

  __Arguments__ { NaturalNumber }
  function SetHeaderHeight(self, height)
    self.frame.header:SetHeight(height)

    if self.showHeader then
      self.height = self.height + (height - self.baseHeight)
      self.baseHeight = height
    end
  end

  __Arguments__ { Number }
  function SetContentMarginTop(self, height)
    if self.frame.header:IsShown() then 
      self.frame.content:SetPoint("TOP", self.frame.header, "BOTTOM", 0, -height)
    else 
      self.frame.content:SetPoint("TOP", 0, -height)
    end

    self.height = self.height + (height - self.contentMarginTop)
  end 

  function Init(self)
    local prefix = self:GetClassPrefix()

    Theme:RegisterFrame(prefix..".frame", self.frame, "blocK.frame")
    Theme:RegisterFrame(prefix..".header", self.frame.header, "block.header")
    Theme:RegisterFrame(prefix..".content", self.frame.content, "block.content")
    Theme:RegisterText(prefix..".header.text", self.frame.header.text, "block.header.text")
    Theme:RegisterTexture(prefix..".header.stripe", self.frame.header.stripe, "block.header.stripe")


    Theme:SkinFrame(self.frame)
    Theme:SkinFrame(self.frame.header)
    Theme:SkinFrame(self.frame.content)
    Theme:SkinText(self.frame.header.text)
    Theme:SkinTexture(self.frame.header.stripe)

    self.showHeader = Blocks:GetCategory(self.category).showHeader
    self.contentMarginTop = Blocks:GetCategory(self.category).contentMarginTop
    self:SetContentMarginTop(self.contentMarginTop)

    if not self.showHeader then
      self:HideHeader()
    end
  end
  ------------------------------------------------------------------------------
  --                   Static Functions                                       --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, Variable.Optional(String), Variable.Optional(), Variable.Optional() }
  __Static__() function BroadcastSetting(class, option, newValue, oldValue)
    Frame:BroadcastSetting(option, newValue, oldValue, _FrameCache)
  end

  __Arguments__ { ClassType, Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String)}
  __Static__() function SkinAll(class, flags, target)
    Frame:SkinAll(flags, target, _FrameCache)
  end

  __Arguments__ { ClassType }
  function ReloadAll()
    Frame:ReloadAll(_FrameCache)
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetCached(self, blockID)
    for block in pairs(_BlockCache) do
      if block.id == blockID then
        return block
      end
    end
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "id"               { TYPE = String, DEFAULT = "defaultID" }
  property "text"             { TYPE = String, DEFAULT = "Default Header Text", HANDLER = SetText }
  property "isActive"         { TYPE = Boolean, DEFAULT = true, HANDLER = IsActiveChanged }
  property "order"            { TYPE = Number, DEFAULT = 100, EVENT = "OnOrderChanged", FIELD = "__order" } -- is a shortcut of the category order
  property "category"         { TYPE = String }
  property "tracker"          { TYPE = String  }
  property "expanded"         { TYPE = Boolean, DEFAULT = true }
  property "contentHeight"    { TYPE = Number, DEFAULT = 0, HANDLER = SetContentHeight }
  property "headerHeight"     { TYPE = NaturalNumber, DEFAULT = 34 }
  property "showHeader"       { TYPE = Boolean, DEFAULT = true }
  property "contentMarginTop" { TYPE = Number, DEFAULT = 5 }


  __Static__() property "_prefix" { DEFAULT = "block"}

  function Block(self)
    super(self, CreateFrame("Frame"))
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)

    local headerFrame = CreateFrame("Button", nil, self.frame)
    headerFrame:SetPoint("TOPLEFT")
    headerFrame:SetPoint("TOPRIGHT")
    headerFrame:SetFrameStrata("HIGH")
    headerFrame:SetHeight(34)
    headerFrame:SetBackdrop(_Backdrops.Common)
    headerFrame:SetBackdropBorderColor(0, 0, 0, 0)
    headerFrame:RegisterForClicks("LeftButtonUp")
    headerFrame:SetScript("OnClick", function(_, button)
        if button == "LeftButton" then
          if self.expanded then
            self:Collapse()
          else
            self:Expand()
          end
        end
    end)
    self.frame.header = headerFrame

    local stripe = headerFrame:CreateTexture()
    stripe:SetAllPoints()
    stripe:SetTexture([[Interface\AddOns\EskaTracker\Media\Textures\Stripe]])
    stripe:SetDrawLayer("ARTWORK", 2)
    stripe:SetBlendMode("ALPHAKEY")
    stripe:SetVertexColor(0, 0, 0, 0.5)
    headerFrame.stripe = stripe

    local headerText = headerFrame:CreateFontString(nil, "OVERLAY")
    headerText:SetAllPoints()
    headerText:SetShadowColor(0, 0, 0, 0.25)
    headerText:SetShadowOffset(1, -1)
    headerFrame.text = headerText

    local content = CreateFrame("Frame", nil, self.frame)
    content:SetPoint("TOP", headerFrame, "BOTTOM", 0, -self.contentMarginTop)
    content:SetPoint("LEFT")
    content:SetPoint("RIGHT")
    content:SetPoint("BOTTOM")
    content:SetBackdrop(_Backdrops.Common)
    self.frame.content = content

    self.height = 34
    self.baseHeight = self.height

    -- Keep it in the cache
    _BlockCache[self] = true
    -- Init the block (Register, Skin and Load options)
    Init(self)
  end


endclass "Block"


class "Blocks"
  _CATEGORIES = Dictionary()
  _BLOCKS = Dictionary()
  _PENDING_BLOCKS = Dictionary()

  __Arguments__ { ClassType, BlockCategory }
  __Static__() function RegisterCategory(self, category)

    if not _CATEGORIES[category.id] then
      Scorpio.FireSystemEvent("EKT_BLOCK_CATEGORY_REGISTERED", category)
    end

    _CATEGORIES[category.id] = category

    category.OnOrderChanged = function(self, new)
      for _, tracker in Trackers:GetIterator() do
        for _, block in tracker:GetBlocks():GetIterator() do
          if block.category == category.id then
            block.order = new
          end
        end
      end
    end

    category.OnShowHeaderChanged = function(self, new)
      for _, tracker in Trackers:GetIterator() do
        for _, block in tracker:GetBlocks():GetIterator() do
          if block.category == category.id then
            block.showHeader = new
            if new then
              block:ShowHeader()
            else
              block:HideHeader()
            end
          end
        end
      end
    end

    category.OnHeaderHeightChanged = function(self, new)
      for _, tracker in Trackers:GetIterator() do
        for _, block in tracker:GetBlocks():GetIterator() do
          if block.category == category.id then
            block.headerHeight = new
            if new then
              block:SetHeaderHeight(new)
            end
          end
        end
      end
    end

    category.OnContentMarginTop = function(self, new)
      for _, tracker in Trackers:GetIterator() do
        for _, block in tracker:GetBlocks():GetIterator() do
          if block.category == category.id then
            if new then
              block:SetContentMarginTop(new)
            end
            block.contentMarginTop = new
          end
        end
      end
    end 

    category:LoadPropsFromDatabase()

  end

  __Arguments__ { ClassType, -Block }
  __Static__() function Register(self, class)
    if _BLOCKS[class] then
      return
    end

    _BLOCKS[class] = class
  end

    __Arguments__ { ClassType, String}
    __Static__() function GetCategory(self, id)
      return _CATEGORIES[id]
    end

    __Static__() function IterateCategories(self)
      return _CATEGORIES:GetIterator()
    end

    __Arguments__ { ClassType, String}
    __Static__() function Get(self, id)
      for class in _BLOCKS:GetIterator() do
        local blockID = API:GetDefaultValueFromClass(class ,"id")
        if blockID == id then
          return class
        end
      end
    end

    __Arguments__ { ClassType, String }
    __Static__() function GetFirstForCategory(self, id)
      for class in _BLOCKS:GetIterator() do
        local category = API:GetDefaultValueFromClass(class, "category")
        if category == id then
          return class
        end
      end
    end

    __Arguments__ { ClassType, Block, String }
    __Static__() function AddPendingBlock(self, block, trackerID)
      _PENDING_BLOCKS[block] = trackerID
    end

    __Static__() function ProcessPendingBlocks(self)
      for block, trackerID in _PENDING_BLOCKS:GetIterator() do
        local tracker = Trackers:Get(trackerID)
        
        if tracker then
          if block.isActive then
            tracker:AddBlock(block)
          end
          _PENDING_BLOCKS[block] = nil
        end
      end
    end

end)


class "__Block__" (function(_ENV)
  extend "IApplyAttribute"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function AttachAttribute(self, target, targettype, owner, name, stack)
    local id       = self[1]
    local category = self[2]
    local prefix   = "block."..category

    local hasSuperClass = Class.GetSuperClass(target)

    if hasSuperClass then
      Attribute.IndependentCall(function()
        class(target) (function(_ENV)

          property "id" { TYPE = String, DEFAULT = id }
          property "category" { TYPE = String, DEFAULT = category }

          property "_prefix" { STATIC = true, DEFAULT = prefix }
        end)
      end)
    else
      Attribute.IndependentCall(function()
        class(target) (function(_ENV)
          inherit "Block"

          property "id" { TYPE = String, DEFAULT = id }
          property "category" { TYPE = String, DEFAULT = category }

          property "_prefix" { STATIC = true, DEFAULT = prefix }
        end)
      end)
    end

    Blocks:Register(target)
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "AttributeTarget" { DEFAULT = AttributeTargets.Class }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Rest(NEString) }
  function __new(cls, ...)
    return { ... }, true
  end

  __Arguments__ { NEString }
  function __call(self, other)
    tinsert(self, other)
    return self
  end
end)

 local function GetBlock(id)
  -- Get the category
  local category = Blocks:GetCategory(id)

  -- Don't continue if the category given has been registed by 'Blocks:RegisterCategory'
  if not category then
    return nil
  end

  -- Get the block selected by category (return the value by default or set by user if exists)
  local selected = category.selected

  local blockClass
  if selected then
    blockClass = Blocks:Get(selected)
  end

  -- if block is always nil, this is because the block selected not exists or has been not registered !
  -- so get the first block found with the category given
  if not blockClass then
    blockClass = Blocks:GetFirstForCategory(id)
  end

  -- If block is always nil, don't continue, we have do our possible to have a valid block !
  if not blockClass then
    return
  end

  local block = blockClass()
  block.order = category.order

  local tracker = Trackers:Get(category.tracker)

  if tracker then
    tracker:AddBlock(block)
  else
    Blocks:AddPendingBlock(block, category.tracker)
  end

  return block
end

_G.EKT_BLOCK = GetBlock


--- [[ Experimental ]]
Environment.RegisterGlobalKeyword{ block = GetBlock }

__SystemEvent__()
function EKT_PROFILES_LOADED()
  for _, category in Blocks:IterateCategories() do
    category:LoadPropsFromDatabase()
  end
end

__SystemEvent__()
function EKT_PROFILE_CHANGED()
  for _, category in Blocks:IterateCategories() do
    category:LoadPropsFromDatabase()
  end
end


__SystemEvent__()
function EKT_COPY_PROFILE_PROCESS(sourceDB, destDB, destProfile)
  if sourceDB["blocks"] then
    destDB["blocks"] = sourceDB["blocks"]
  end
end

__SystemEvent__()
function EKT_TRACKERS_LOADED()
  Blocks:ProcessPendingBlocks()
end
