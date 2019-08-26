--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                      "EskaTracker.API.BorderFrame"                       ""
--============================================================================--
namespace                       "EKT"
--============================================================================--
ValidateFlags = API.ValidateFlags

class "BorderFrame" (function(_ENV)
  inherit "Frame"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  event "OnBorderWidthChanged"
  ------------------------------------------------------------------------------
  --                                Handlers                                  --
  ------------------------------------------------------------------------------
  local function UpdateFrame(self, new, old)
    self:RemoveBordersAccess(old)
    self:AddBordersAccess(new)

    local container = self:GetFrameContainer()
    new:SetParent(container)
    new:Show()
    self:UpdateBorderAnchors()
  end

  local function UpdateBorderWidth(self, new, old)
    if new > 0 then
      self:SetBorderWidth(new)
      self.showBorder = true
    else
      self.showBorder = false
    end

    OnBorderWidthChanged(self, new, old)
  end

  local function UpdateBorderVisibility(self, new, old)
    if new then
      self:ShowBorder()
    else
      self:HideBorder()
    end

    self:UpdateBorderAnchors()
  end

  local function UpdateBorderColor(self, new)
    self:SetBorderColor(new)
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function CreateBorders(self)
    if not self.borders then
      local container = self:GetFrameContainer()
      local r, g, b, a = self.borderColor.r, self.borderColor.g, self.borderColor.b, self.borderColor.a
      self.borders = {}

      local borderLeft = container:CreateTexture(nil , "BORDER")
      borderLeft:SetColorTexture(r, g, b, a)
      borderLeft:SetWidth(self.borderWidth)
      borderLeft:Show()
      self.borders.left = borderLeft

      local borderTop = container:CreateTexture(nil , "BORDER")
      borderTop:SetColorTexture(r, g, b, a)
      borderTop:SetHeight(self.borderWidth)
      borderTop:Show()
      self.borders.top = borderTop

      local borderRight = container:CreateTexture(nil, "BORDER")
      borderRight:SetColorTexture(r, g, b, a)
      borderRight:SetWidth(self.borderWidth)
      borderRight:Show()
      self.borders.right = borderRight

      local borderBot = container:CreateTexture(nil, "BORDER")
      borderBot:SetColorTexture(r, g, b, a)
      borderBot:SetHeight(self.borderWidth)
      borderBot:Show()
      self.borders.bottom = borderBot

      -- Set Anchor Points
      borderLeft:SetPoint("TOPLEFT")
      borderLeft:SetPoint("BOTTOMLEFT")

      borderRight:SetPoint("TOPRIGHT")
      borderRight:SetPoint("BOTTOMRIGHT")

      borderTop:SetPoint("TOPLEFT", borderLeft, "TOPRIGHT")
      borderTop:SetPoint("TOPRIGHT", borderRight, "TOPLEFT")

      borderBot:SetPoint("BOTTOMLEFT", borderLeft, "BOTTOMRIGHT")
      borderBot:SetPoint("BOTTOMRIGHT", borderRight, "BOTTOMLEFT")
    end
  end

  -- The method will add an access to borders in the frame given.
  -- The borders can be retrieved in using frame.borders table.
  -- e.g: frame.borders.lef will return the border left.
  function AddBordersAccess(self, frame)
    if self.borders and frame then
      frame.borders = setmetatable({}, { __mode = "v" })
      frame.borders.left    = self.borders.left
      frame.borders.top     = self.borders.top
      frame.borders.right   = self.borders.right
      frame.borders.bottom  = self.borders.bottom
    end
  end

  -- The method will rmeove the borders access from frame given.
  function RemoveBordersAccess(self, frame)
    if frame and frame.borders then
      frame.borders = nil
    end
  end
  ------------------------------------------------------------------------------
  --               Border visibility Methods                                  --
  ------------------------------------------------------------------------------
  function ShowBorder(self)
    if self.borders then
      self.borders.top:Show()
      self.borders.left:Show()
      self.borders.bottom:Show()
      self.borders.right:Show()
    else
      self:CreateBorders()
      self:AddBordersAccess(self.frame)
    end
  end

  function HideBorder(self)
    if self.borders then
      self.borders.top:Hide()
      self.borders.left:Hide()
      self.borders.bottom:Hide()
      self.borders.right:Hide()
    end
  end
  ------------------------------------------------------------------------------
  --               Border properties Methods                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { NaturalNumber }
  function SetBorderWidth(self, width)
    if self.borders then
      self.borders.left:SetWidth(width)
      self.borders.top:SetHeight(width)
      self.borders.right:SetWidth(width)
      self.borders.bottom:SetHeight(width)
    end
  end

  __Arguments__ { Table }
  function SetBorderColor(self, color)
    if self.borders then
      self.borders.top:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.left:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.bottom:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.right:SetColorTexture(color.r, color.g, color.b, color.a)
    end
  end
  ------------------------------------------------------------------------------
  --                       Others Methods                                     --
  ------------------------------------------------------------------------------
  function UpdateBorderAnchors(self)
    if not self.frame then return end

    if self.showBorder then
      self.frame:ClearAllPoints()
      --[[self.frame:SetPoint("TOP", self.borders.top, "BOTTOM")
      self.frame:SetPoint("LEFT", self.borders.left, "RIGHT")
      self.frame:SetPoint("RIGHT", self.borders.right, "LEFT")
      self.frame:SetPoint("BOTTOM", self.borders.bottom, "TOP")--]]

      self.frame:SetPoint("TOPLEFT", self.borders.top, "BOTTOMLEFT")
      self.frame:SetPoint("TOPRIGHT", self.borders.top, "BOTTOMRIGHT")
      self.frame:SetPoint("BOTTOMLEFT", self.borders.bottom, "TOPLEFT")
      self.frame:SetPoint("BOTTOMRIGHT", self.borders.bottom, "TOPRIGHT")
    else
      self.frame:ClearAllPoints()
      self.frame:SetAllPoints(self:GetFrameContainer())
    end
  end

  function GetFrameContainer(self)
    return self.containerFrame
  end
  ------------------------------------------------------------------------------
  --                   Refresh & Skin Methods                                 --
  ------------------------------------------------------------------------------
  __Arguments__ { Table, Variable.Optional(SkinFlags, Theme.SkinFlags.FRAME_BORDER_WIDTH + Theme.SkinFlags.FRAME_BORDER_COLOR )}
  function SkinBorder(self, frame, flags)
    -- Border width
    if ValidateFlags(flags, Theme.SkinFlags.FRAME_BORDER_WIDTH) then
      self.borderWidth = Themes:GetSelected():GetElementProperty(frame.elementID, "border-width", frame.inheritElementID)
    end

    if ValidateFlags(flags, Theme.SkinFlags.FRAME_BORDER_COLOR) then
      self.borderColor = Themes:GetSelected():GetElementProperty(frame.elementID, "border-color", frame.inheritElementID)
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "frame"          { TYPE = Table, HANDLER = UpdateFrame }
  property "containerFrame" { TYPE = Table }
  property "showBorder"     { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateBorderVisibility }
  property "borderWidth"    { TYPE = NaturalNumber, DEFAULT = 0, HANDLER = UpdateBorderWidth }
  property "borderColor"    { TYPE = Table, DEFAULT = { r = 0, g = 0, b = 0, a = 1}, HANDLER = UpdateBorderColor }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { Variable.Optional(Boolean, false) }
  function BorderFrame(self, isSecure)
    super(self)

    if isSecure then
      self.containerFrame = CreateFrame("Frame", nil, nil, "SecureFrameTemplate")
    else
      self.containerFrame = CreateFrame("Frame")
    end
  end

  __Arguments__ { Table, Variable.Optional(Boolean, false) }
  function BorderFrame(self, frame, isSecure)
    this(self, isSecure)

    self.frame = frame
  end
end)
