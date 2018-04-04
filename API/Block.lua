--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio                  "EskaTracker.API.Block"                              ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "BlockCategory" (function(_ENV)
  event "OnOrderChanged"


  local function UpdateOrder(self, new)
    Database:SelectRoot()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      if new == self._initOrder then
        Database:SetValue("order", nil)
      else
        Database:SetValue("order", new)
      end
    end
  end

  local function UpdateSelected(self, new)
    Database:SelectRoot()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      if new == self._initSelected then
        Database:SetValue("selected", nil)
      else
        Database:SetValue("selected", new)
      end
    end
  end

  local function UpdateTracker(self, new)
    Database:SelectRoot()
    if Database:SelectTable(true, "blocks", "categories", self.id) then
      local defaultValue = API:GetDefaultValueFromObj(self, "tracker")
      if defaultValue == new then
        Database:SetValue("tracker", nil)
      else
        Database:SetValue("tracker", new)
      end
    end
  end


--[[
  function GetTracker(self)
    print("GetTracker", self.__tracker)
  end--]]

  function GetTracker(self)
    if not self.__tracker then
      Database:SelectRoot()
      if Database:SelectTable(true, "blocks", "categories", self.id) then
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
      Database:SelectRoot()
      if Database:SelectTable(true, "blocks", "categories", self.id) then
        if useDefaultValue then
          Database:SetValue("tracker", nil)
        else
          Database:SetValue("tracker", value)
        end
      end
      self.__tracker = value
    end
  end

  property "id" { TYPE = String, FIELD = "__id" }
  property "name" { TYPE = String, FIELD = "__name" }
  property "order" { TYPE = Number, HANDLER = UpdateOrder, DEFAULT = function(self) return self._initOrder end, FIELD = "__order" }
  property "selected" { TYPE = String, HANDLER = UpdateSelected, DEFAULT = function(self) return self._initSelected end, FIELD = "__selected" }
  property "tracker" { TYPE = String, HANDLER = UpdateTracker, DEFAULT = "Main", GET = "GetTracker", SET = "SetTracker" }
  property "_initOrder" { TYPE = Number, DEFAULT = 100 }
  property "_initSelected" { TYPE = String }

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
      if Theme:NeedSkin(target, self.frame) then
        Theme:SkinFrame(self.frame, flags, state)
      end

      if Theme:NeedSkin(target, self.frame.header) then
        Theme:SkinFrame(self.frame.header, flags, state)
      end

      if Theme:NeedSkin(target, self.frame.content) then
        Theme:SkinFrame(self.frame.content, flags, state)
      end

      if Theme:NeedSkin(target, self.frame.header.text) then
        Theme:SkinText(self.frame.header.text, flags, self.text, state)
      end

      if Theme:NeedSkin(target, self.frame.header.stripe) then
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
  end
  ------------------------------------------------------------------------------
  --                   Static Functions                                       --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, Variable.Optional(String), Variable.Optional(), Variable.Optional() }
  __Static__() function BroadcastOption(class, option, newValue, oldValue)
    Frame:BroadcastOption(option, newValue, oldValue, _FrameCache)
  end

  __Arguments__ { ClassType, Variable.Optional(SkinFlags, Theme.DefaultSkinFlags), Variable.Optional(String)}
  __Static__() function SkinAll(class, flags, target)
    Frame:SkinAll(flags, target, _FrameCache)
  end

  __Arguments__ { ClassType }
  function ReloadAll()
    Frame:ReloadAll(_FrameCache)
  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "id" { TYPE = String, DEFAULT = "defaultID" }
  property "text" { TYPE = String, DEFAULT = "Default Header Text", HANDLER = SetText }
  property "isActive" { TYPE = Boolean, DEFAULT = true }
  property "order" { TYPE = Number, DEFAULT = 100 } -- is a shortcut of the category order
  property "category" { TYPE = String }
  property "tracker" { TYPE = String }
  property "expanded" { TYPE = Boolean, DEFAULT = true }

  __Static__() property "_prefix" { DEFAULT = "block"}

  function Block(self)
    self.frame = CreateFrame("Frame")
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
    stripe:SetTexture([[Interface\AddOns\EskaQuestTracker\Media\Textures\Stripe]])
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
    content:SetPoint("TOP", headerFrame, "BOTTOM")
    content:SetPoint("LEFT")
    content:SetPoint("RIGHT")
    content:SetPoint("BOTTOM")
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

  __Arguments__ { ClassType, BlockCategory }
  __Static__() function RegisterCategory(self, category)
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

end)



Blocks:RegisterCategory(BlockCategory("quests", "Quests", 50, "eska-quests"))
Blocks:RegisterCategory(BlockCategory("bonus-objectives", "Bonus objectives", 12, "eska-bonus-objectives"))
Blocks:RegisterCategory(BlockCategory("world-quests", "World quests", 15, "eska-world-quests"))
Blocks:RegisterCategory(BlockCategory("achievements", "Achievements", 10, "eska-achievements"))
Blocks:RegisterCategory(BlockCategory("dungeon", "Dungeon", 10, "eska-dungeon"))
Blocks:RegisterCategory(BlockCategory("keystone", "Keystone", 5, "eska-keystone"))
Blocks:RegisterCategory(BlockCategory("scenario", "Scenario", 10, "eska-scenario"))

--[[
_G.EKT_BLOCK = function(id)
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
  local tracker = Trackers:Get(category.tracker)

  tracker:AddBlock(block)

  return block
end --]]


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
  local tracker = Trackers:Get(category.tracker)

  tracker:AddBlock(block)

  return block
end

_G.EKT_BLOCK = GetBlock


--- [[ Experimental ]]
Environment.RegisterGlobalKeyword{ block = GetBlock }
