--============================================================================--
--                          Eska Quest Tracker                                --
-- @Author  : Skamer <https://mods.curse.com/members/DevSkamer>               --
-- @Website : https://wow.curseforge.com/projects/eska-quest-tracker          --
--============================================================================--
Scorpio         "EskaTracker.API.ContextMenu"                                 ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "BaseMenuItem" (function(_ENV)
  inherit "Frame"

  function Reset(self)
    self:Hide()
    self:ClearAllPoints()
    self:SetParent()
  end

  function BaseMenuItem(self)
    self.frame = CreateFrame("Frame")

    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 0, 0, 0)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)
  end

end)

class "MenuItemSeparator" (function(_ENV)
  inherit "BaseMenuItem"

  function MenuItemSeparator(self)
    super(self)

    self.frame:SetBackdropColor(1, 1, 1, 0.15)

    self.baseHeight = 2
    self.height = self.baseHeight
  end
end)


class "MenuItem" (function(_ENV)

  inherit "BaseMenuItem"
  local function UpdateProps(self, new, old, prop)
    if prop == "text" then
      self.label:SetText(new)
    elseif prop == "icon" then
    elseif prop == "onClick" then
      if old == nil then
        self.btn:RegisterForClicks("LeftButtonUp")
      end

      if new == nil then
        self.btn:RegisterForClicks(nil)
      end
      self.btn:SetScript("OnClick", function() if not self.disabled then new(); ContextMenu():Hide() end end)
    elseif prop == "disabled" then
      if not new then
        self.label:SetTextColor(1, 1, 1)
        self.frame:SetBackdropColor(0, 0, 0, 0)
      else
        self.label:SetTextColor(0.4, 0.4, 0.4)
        --self.frame:SetBackdropColor(0.35, 0.35, 0.35, 0.5)
      end
    end
  end

  property "icon" { TYPE = String, HANDLER = UpdateProps }
  property "text" { TYPE = String, HANDLER = UpdateProps }
  property "onClick" { TYPE = Callable, HANDLER = UpdateProps }
  property "disabled" { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateProps }

  function Reset(self)
    super.Reset(self)

    self.icon = nil
    self.text = nil
    self.onClick = nil
    self.disabled = nil
  end

  function MenuItem(self)
    super(self)

    local btn = CreateFrame("button", nil, self.frame)
    btn:SetAllPoints()
    self.btn = btn

    local font = _LibSharedMedia:Fetch("font", "PT Sans Narrow Bold")

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetText("")
    label:SetPoint("TOP")
    label:SetPoint("BOTTOM")
    label:SetPoint("RIGHT", -10, 0)
    label:SetPoint("LEFT", 10, 0)
    label:SetFont(font, 12)
    label:SetJustifyH("LEFT")
    self.label = label

    btn:SetScript("OnEnter", function(btn)
      if not self.disabled then
        self.frame:SetBackdropColor(0, 148/255, 1, 0.5)
        label:SetTextColor(1, 216/255, 0)
      end
    end)
    btn:SetScript("OnLeave", function(btn)
      if not self.disabled then
        self.frame:SetBackdropColor(0, 0, 0, 0)
        label:SetTextColor(1, 1, 1)
      end
    end)

    self.baseHeight = 24
    self.height = self.baseHeight
  end

end)

class "MenuItemSeparator" (function(_ENV)
  inherit "BaseMenuItem"
  function MenuItemSeparator(self)
    super(self)

    self.frame:SetBackdropColor(1, 1, 1, 0.15)

    self.baseHeight = 2
    self.height = self.baseHeight
  end
end)


class "ContextMenu" (function(_ENV)
  inherit "Frame"

  _Obj = nil

  _ARROW_TEX_COORDS = {
    ["RIGHT"] = { left = 0, right = 32/128, top = 0, bottom = 1 },
    ["BOTTOM"] = { left = 32/128, right = 64/128, top = 0, bottom = 1 },
    ["LEFT"] = { left = 64/128, right = 96/128, top = 0, bottom = 1 },
    ["TOP"] = { left = 96/128, right = 1, top = 0, bottom = 1 }
  }

  _ARROW_POINTS = {
    ["RIGHT"] = { fromPoint = "RIGHT", toPoint = "LEFT", offsetX = 5, offsetY = 0},
    ["BOTTOM"] = { fromPoint = "BOTTOM", toPoint = "TOP", offsetX = 0, offsetY = -5 },
    ["LEFT"] = { fromPoint = "LEFT", toPoint = "RIGHT", offsetX = -5, offsetY = 0},
    ["TOP"] = { fromPoint = "TOP", toPoint = "BOTTOM", offsetX = 0, offsetY = 5}
  }
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateProps(self, new, old, prop)
    if prop == "orientation" then
      self:UpdateArrowOrientation()
    end
  end
  ------------------------------------------------------------------------------
  --                                Methods                                   --
  ------------------------------------------------------------------------------
  function UpdateArrowOrientation(self)
    local coords = _ARROW_TEX_COORDS[self.orientation]
    self.arrow:SetTexCoord(coords.left, coords.right, coords.top, coords.bottom)

    local p = _ARROW_POINTS[self.orientation]
    self.frame:ClearAllPoints()
    self.frame:SetPoint(p.fromPoint, self.arrow, p.toPoint, p.offsetX, p.offsetY)

    self:UpdateAnchorPoint()
  end

  function UpdateAnchorPoint(self)
    local frame = self.anchorFrames[self.orientation]
    if not frame then
      if self.anchorFrames["RIGHT"] then
        frame = self.anchorFrames["RIGHT"]
      elseif self.anchorFrames["LEFT"] then
        frame = self.anchorFrames["LEFT"]
      end
    end

    if not frame then
      return
    end

    self.arrow:ClearAllPoints()
    local relativePoint = _ARROW_POINTS[self.orientation].toPoint
    self.arrow:SetPoint(self.orientation, frame, relativePoint)
  end

  __Arguments__ { BaseMenuItem }
  function AddItem(self, item)
    self.items:Insert(item)
    return item
  end

  __Arguments__ { String, Variable.Optional(String), Variable.Optional(Callable )}
  function AddItem(self, text, icon, onClick)
    --print("(AddItem)", self, text, icon, onClick)
    local item = ObjectManager:Get(MenuItem)
    item.text = text
    item.icon = icon
    item.onClick = onClick

    return AddItem(self, item)
  end

  __Arguments__ { String, Variable.Rest() }
  function AddAction(self, id, ...)
    local action = Actions:Get(id)
    if action then
      local item = self:AddItem(action.text)
      local count = self.items.Count
      self.actionsArgs[count] = { ... }
      item.onClick = function()
        if self.actionsArgs[count] then
          action.Exec(unpack(self.actionsArgs[count]))
        else
          action.Exec()
        end
      end

      return item
    end
  end


  function SetAnchorFrame(self, orientation, frame)
    self.anchorFrames[orientation] = frame
    return self
  end

  function ClearAnchorFrames(self)
    self:SetAnchorFrame("RIGHT", nil)
    self:SetAnchorFrame("LEFT", nil)
    self:SetAnchorFrame("TOP", nil)
    self:SetAnchorFrame("BOTTOM", nil)
    return self
  end

  function ClearAll(self)
    self:ClearAnchorFrames()
    self:ClearItems()
    self.orientation = "RIGHT"
    return self
  end

  function ClearItems(self)
    for index, item in self.items:GetIterator() do
      ObjectManager:Recycle(item)
    end

    self.items:Clear()

    return self
  end



  __Arguments__ { Table }
  function AnchorTo(self, frame)
    return self:AnchorTo(frame, frame, frame, frame)
  end

  __Arguments__ { Table, Table, Variable.Optional(Table), Variable.Optional(Table) }
  function AnchorTo(self, frameWhenRight, frameWhenLeft, frameWhenTop, frameWhenBottom)
    self:SetAnchorFrame("RIGHT", frameWhenRight)
    self:SetAnchorFrame("LEFT", frameWhenLeft)
    self:SetAnchorFrame("TOP", frameWhenTop)
    self:SetAnchorFrame("BOTTOM", frameWhenBottom)
    return self
  end

  function OnLayout(self)
    local previousFrame
    local height = 0

    for index, menuItem in self.items:GetIterator() do
      menuItem:ClearAllPoints()
      menuItem:SetParent(self:GetFrameContainer())
      menuItem:Show()

      if index == 1 then
        menuItem:SetPoint("TOPLEFT")
      else
        menuItem:SetPoint("TOPLEFT", previousFrame, "BOTTOMLEFT", 0, 0)
      end
      menuItem.width = self.width

      previousFrame = menuItem.frame
      height = height + menuItem.height
    end

    if height < self.baseHeight then
      self.height = self.baseHeight
    else
      self.height = height
    end
  end

  function OnShow(self)
    super.OnShow(self)

    self.arrow:Show()
  end

  function OnHide(self)
    super.OnHide(self)

    self.arrow:Hide()
  end

  function Finish(self)
    self:Layout()
  end





  --[[
  function AnchorTo(self, frameWhenRight, frameWhenLeft, frameWhenTop, frameWhenBottom)


  end
  --]]

  function UseBestOrientation(self)

  end

  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "orientation" { TYPE = String, DEFAULT = "RIGHT", HANDLER = UpdateProps }

  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function ContextMenu(self)
    --if _init then
      --return
    --end

    super(self)

    local arrow = UIParent:CreateTexture()
    arrow:SetTexture([[Interface\AddOns\EskaQuestTracker\Media\Textures\MenuContext-Arrow]])
    arrow:SetPoint("CENTER", UIParent, "CENTER", 350, 350)
    arrow:SetSize(24, 24)
    arrow:SetVertexColor(0, 0, 0, 0.6)
    self.arrow = arrow

    self.frame = CreateFrame("Frame", "EKT-ContextMenu", UIParent)
    self.frame:SetBackdrop(_Backdrops.Common)
    self.frame:SetBackdropColor(0, 0, 0, 0.6)
    self.frame:SetBackdropBorderColor(0, 0, 0, 0)
    self.frame:SetFrameStrata("HIGH")
    self.frame:SetPoint("RIGHT", arrow, "LEFT")
    self.frame:SetScript("OnUpdate", function(f)
      local top = f:GetTop()
      local left = f:GetLeft()
      local right = f:GetRight()
      local bottom = f:GetBottom()

      if left < 0 then
        self.orientation = "LEFT"
      elseif right > GetScreenWidth() then
        self.orientation = "RIGHT"
      end
    end)

    self.width = 125
    self.baseHeight = 75
    self.height = self.baseHeight

    self.items = List()
    self.actionsArgs = {}
    self.anchorFrames = setmetatable( {}, { __mode = "v"})

    self:UpdateArrowOrientation()
    self:Hide()

    _Obj = self

    --_init = true
  end

  function __exist(self)
    return _Obj
  end

end)

function OnLoad(self)
  -- Register the class in the object manager
  ObjectManager:Register(MenuItem)
end
