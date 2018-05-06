--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio             "EskaTracker.API.BorderFrame"                        ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "BorderFrame" (function(_ENV)
  inherit "Frame"
  _BorderFrameCache = setmetatable({}, { __mode = "k" })
  event  "OnBorderWidthChanged"
  ------------------------------------------------------------------------------
  --                          Handlers                                        --
  ------------------------------------------------------------------------------
  local function UpdateFrame(self, new, old)
    self:UninstallBorders(old)
    self:InstallBorders(new)


    local container = self:GetFrameContainer()
    new:SetParent(container)
    new:Show()
    self:UpdateBorderAnchors()
  end

  local function UpdateBorderVisibility(self, new, old)
    if not self.borders then return end

    if new then
      self:ShowBorder()
    else
      self:HideBorder()
    end
    self:UpdateBorderAnchors()
  end

  local function UpdateBorderWidth(self, new, old)
    if not self.borders then return end


    self:SetBorderWidth(new)
    OnBorderWidthChanged(self, new, old)

  end

  local function UpdateBorderColor(self, new, old)
    if not self.borders then return end

    self:SetBorderColor(new)
  end

  function GetFrameContainer(self)
    return self.containerFrame
  end
  ------------------------------------------------------------------------------
  --                    Border Methods                                        --
  ------------------------------------------------------------------------------
  function CreateBorders(self)
    if not self.borders then
      local container = self:GetFrameContainer()
      self.borders = {}

      local borderLeft = container:CreateTexture(nil , "BORDER")
      borderLeft:SetColorTexture(0, 0, 0)
      borderLeft:SetWidth(self.borderWidth)
      borderLeft:Show()
      self.borders.left = borderLeft

      local borderTop = container:CreateTexture(nil , "BORDER")
      borderTop:SetColorTexture(0, 0, 0)
      borderTop:SetHeight(self.borderWidth)
      borderTop:Show()
      self.borders.top = borderTop

      local borderRight = container:CreateTexture(nil, "BORDER")
      borderRight:SetColorTexture(0, 0, 0)
      borderRight:SetWidth(self.borderWidth)
      borderRight:Show()
      self.borders.right = borderRight

      local borderBot = container:CreateTexture(nil, "BORDER")
      borderBot:SetColorTexture(0, 0, 0)
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

  -- The function will install the borders in the frame give.
  -- The border can be retrieved in doing: frame.borders
  -- e.g: frame.borders.left will return the border left frame
  function InstallBorders(self, frame)
    if self.borders then
      frame.borders = setmetatable({}, { __mode = "v" } )
      frame.borders.left = self.borders.left
      frame.borders.top = self.borders.top
      frame.borders.right = self.borders.right
      frame.borders.bottom = self.borders.bottom
    end
  end

  -- This method will uninstall the borders from frame given.
  -- It simply remove metatable containing references to border frames.
  function UninstallBorders(self, frame)
    if frame and frame.borders then
      frame.borders = nil -- @TODO: Check that
    end
  end

  function ShowBorder(self)
    if self.borders then
      self.borders.top:Show()
      self.borders.left:Show()
      self.borders.bottom:Show()
      self.borders.right:Show()
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

  function SetBorderWidth(self, width)
    if self.borders then
      self.borders.left:SetWidth(width)
      self.borders.top:SetHeight(width)
      self.borders.right:SetWidth(width)
      self.borders.bottom:SetHeight(width)

      self:UpdateBorderAnchors ()
    end
  end

  function SetBorderColor(self, color)
    if self.borders then
      self.borders.top:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.left:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.bottom:SetColorTexture(color.r, color.g, color.b, color.a)
      self.borders.right:SetColorTexture(color.r, color.g, color.b, color.a)
    end
  end

  function UpdateBorderAnchors(self)
    if self.showBorder then
      --self.frame:ClearAllPoints()
      self.frame:SetPoint("TOP", self.borders.top, "BOTTOM")
      self.frame:SetPoint("LEFT", self.borders.left, "RIGHT")
      self.frame:SetPoint("RIGHT", self.borders.right, "LEFT")
      self.frame:SetPoint("BOTTOM", self.borders.bottom, "TOP")
    else
      self.frame:ClearAllPoints()
      self.frame:SetAllPoints(self:GetFrameContainer())
    end
  end
  ------------------------------------------------------------------------------
  --                   Refresh & Skin Methods                                 --
  ------------------------------------------------------------------------------
  __Arguments__ { Table, Variable.Optional(SkinFlags, Theme.SkinFlags.FRAME_BORDER_WIDTH + Theme.SkinFlags.FRAME_BORDER_COLOR )}
  function SkinBorder(self, frame, flags)
    -- Border width
    if Enum.ValidateFlags(flags, Theme.SkinFlags.FRAME_BORDER_WIDTH) then
      self.borderWidth = Themes:GetSelected():GetElementProperty(frame.elementID, "border-width", frame.inheritElementID)
    end

    if Enum.ValidateFlags(flags, Theme.SkinFlags.FRAME_BORDER_COLOR) then
      self.borderColor = Themes:GetSelected():GetElementProperty(frame.elementID, "border-color", frame.inheritElementID)
  end
end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "frame" { TYPE = Table, HANDLER = UpdateFrame }
  property "containerFrame" { TYPE = Table } -- contains the borders and the content frame
  property "showBorder" { TYPE = Boolean, DEFAULT = true, HANDLER = UpdateBorderVisibility }
  property "borderWidth" { TYPE = Number, DEFAULT = 0, HANDLER = UpdateBorderWidth }
  property "borderColor" { TYPE = Table, DEFAULT = { r = 0, g = 0, b = 0, a = 1}, HANDLER = UpdateBorderColor }
  ------------------------------------------------------------------------------
  --                         Constructors                                     --
  ------------------------------------------------------------------------------
  __Arguments__ {}
  function BorderFrame(self)
    super(self)

    self.containerFrame = CreateFrame("Frame")
    self:CreateBorders()

    _BorderFrameCache[self] = true
  end


  __Arguments__ { Table }
  function BorderFrame(self, frame)
    this(self)

    self.frame = frame
  end
end)
