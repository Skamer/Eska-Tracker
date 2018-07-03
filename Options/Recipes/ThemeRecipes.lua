--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.Options.ThemeRecipes"                     ""
-- ========================================================================== --
_TextTransforms       = {
  ["none"] = "None",
  ["uppercase"] = "UPPER CASE",
  ["lowercase"] = "lower case",
}

_TextJustifyHorizontal = {
  ["CENTER"] = "CENTER",
  ["LEFT"]   = "LEFT",
  ["RIGHT"]  = "RIGHT",
}

_TextJustifyVertical = {
  ["BOTTOM"] = "BOTTOM",
  ["MIDDLE"] = "MIDDLE",
  ["TOP"]    = "TOP"
}

class "ThemePropertyRecipe" (function(_ENV)
  inherit "OptionRecipe"
  _FLAGS_PROPERTIES = {
    [Theme.SkinFlags.FRAME_BACKGROUND_COLOR]    = "background-color",
    [Theme.SkinFlags.FRAME_BORDER_COLOR]        = "border-color",
    [Theme.SkinFlags.FRAME_BORDER_WIDTH]        = "border-width",
    [Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE]  = "background-texture",
    [Theme.SkinFlags.TEXT_SIZE]                 = "text-size",
    [Theme.SkinFlags.TEXT_FONT]                 = "text-font",
    [Theme.SkinFlags.TEXT_COLOR]                = "text-color",
    [Theme.SkinFlags.TEXT_TRANSFORM]            = "text-transform",
    [Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL]   = "text-justify-h",
    [Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL]     = "text-justify-v",
    [Theme.SkinFlags.TEXTURE_COLOR]             = "texture-color",
  }

  ------------------------------------------------------------------------------
  --                     Helper functions                                     --
  ------------------------------------------------------------------------------
  local function CreateGroup(name)
    local g = _AceGUI:Create("InlineGroup")
    g:SetLayout("Flow")
    g:SetTitle(name or "")
    g:SetRelativeWidth(1.0)
    return g
  end

  local function CreateRow(name, controlFrame)
    local layout = _AceGUI:Create("SimpleGroup")
    layout:SetRelativeWidth(1.0)
    layout:SetLayout("Flow")

    local label = _AceGUI:Create("Label")
    label:SetRelativeWidth(0.3)
    label:SetFontObject(GameFontHighlight)
    label:SetText(name)
    layout:AddChild(label)

    controlFrame:SetRelativeWidth(0.3)
    layout:AddChild(controlFrame)

    local space = _AceGUI:Create("Label")
    space:SetRelativeWidth(0.1)
    space:SetText("")
    layout:AddChild(space)

    return layout
  end

  local function ConcatIDWithState(id, state)
    if not state or state == "none" then
      return id
    end

    return string.format("%s[%s]", id, state)
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  --- Show a reset button for a control row
  __Arguments__ { Table, Table, Theme.SkinFlags}
  function ShowReset(self, row, control, flag)
    local selectedTheme = Themes:GetSelected()
    if not selectedTheme.lua then return end

    local reset = row:GetUserData("reset")
    if not reset then
      reset = _AceGUI:Create("Button")
      reset:SetWidth(75)
      reset:SetText("Reset")
      reset:SetCallback("OnClick", function(reset)
        reset.frame:Hide()
        selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], nil)
        self:RefreshControl(control, flag)
        Frame:SkinAll(flag, self.elementID)
      end)

      row:AddChild(reset)
      row:SetUserData("reset", reset)
    end

    reset.frame:Show()
    return reset
  end

  --- Refresh the control value
  __Arguments__ { Table, Theme.SkinFlags }
  function RefreshControl(self, control, flag)
    local selectedTheme = Themes:GetSelected()
    if not selectedTheme then
      return
    end

    if flag == Theme.SkinFlags.FRAME_BACKGROUND_COLOR
      or flag == Theme.SkinFlags.FRAME_BORDER_COLOR
      or flag == Theme.SkinFlags.TEXT_COLOR
      or flag == Theme.SkinFlags.TEXTURE_COLOR then

      local color = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)

      control:SetColor(color.r, color.g, color.b, color.a or 1)

    elseif flag == Theme.SkinFlags.FRAME_BORDER_WIDTH
      or flag == Theme.SkinFlags.TEXT_SIZE then
      local value = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)
      control:SetLabel("")
      control:SetValue(value)
    elseif flag == Theme.SkinFlags.TEXT_FONT then
      local value = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)
      control:SetValue(value)
      control:SetText(value)
    elseif flag == Theme.SkinFlags.TEXT_TRANSFORM then
      local value = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)
      control:SetValue(value)
      control:SetText(_TextTransforms[value])
    elseif flag == Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL
      or flag == Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL then
      local value = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)
      control:SetValue(value)
      control:SetText(value)
    elseif flag == Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE then
      local value = selectedTheme:GetElementProperty(self.rElementID,
      _FLAGS_PROPERTIES[flag], self.inheritFromElementID)
      control:SetValue(value)
      control:SetText(value)
    end
  end

  __Arguments__ { Table, Table, Theme.SkinFlags}
  function InstallCallbacks(self, row, control, flag)
    local selectedTheme = Themes:GetSelected()
    if not selectedTheme then
      return
    end

    if flag == Theme.SkinFlags.FRAME_BACKGROUND_COLOR
      or flag == Theme.SkinFlags.FRAME_BORDER_COLOR
      or flag == Theme.SkinFlags.TEXT_COLOR
      or flag == Theme.SkinFlags.TEXTURE_COLOR then

        local function OnValueChangedCallback(_, _, r, g, b, a)
          selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], {
            r = r,
            g = g,
            b = b,
            a = a
          })

          self:ShowReset(row, control, flag)
          self:RefreshControl(control, flag)
          Frame:SkinAll(flag, self.elementID)
        end

        control:SetCallback("OnValueChanged", OnValueChangedCallback)
        control:SetCallback("OnValueConfirmed", OnValueChangedCallback)
    elseif flag == Theme.SkinFlags.FRAME_BORDER_WIDTH
      or flag == Theme.SkinFlags.TEXT_SIZE then
      control:SetCallback("OnValueChanged", function(_, _, value)
        selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], value)

        self:ShowReset(row, control, flag)
        self:RefreshControl(control, flag)
        Frame:SkinAll(flag, self.elementID)
      end)
    elseif flag == Theme.SkinFlags.TEXT_FONT then
      control:SetCallback("OnValueChanged", function(_, _, value)
        selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], value)
        self:ShowReset(row, control, flag)
        self:RefreshControl(control, flag)
        Frame:SkinAll(flag, self.elementID)
      end)
    elseif flag == Theme.SkinFlags.TEXT_TRANSFORM then
      control:SetCallback("OnValueChanged", function(_, _, value)
        selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], value)
        self:ShowReset(row, control, flag)
        self:RefreshControl(control, flag)
        Frame:SkinAll(flag, self.elementID)
      end)
    elseif flag == Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL
      or flag == Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL then
        control:SetCallback("OnValueChanged", function(_, _, value)
          selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], value)
          self:ShowReset(row, control, flag)
          self:RefreshControl(control, flag)
          Frame:SkinAll(flag, self.elementID)
        end)
    elseif flag == Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE then
      control:SetCallback("OnValueChanged", function(_, _, value)
        selectedTheme:SetElementPropertyToDB(self.rElementID, _FLAGS_PROPERTIES[flag], value)
        self:ShowReset(row, control, flag)
        self:RefreshControl(control, flag)
        Frame:SkinAll(flag, self.elementID)
      end)
    end
  end

  __Arguments__ { Theme.SkinFlags }
  function AddFlag(self, flag)
    if not Enum.ValidateFlags(self.flags, flag) then
      self.flags = self.flags + flag
    end

    return self
  end

  function ClearFlags(self)
    self.flags = 0
    return self
  end

  __Arguments__ { Theme.SkinFlags }
  function SetFlags(self, flags)
    self.flags = flags

    return self
  end

  __Arguments__ { String }
  function SetElementID(self, elementID)
    self.elementID = elementID
    return self
  end

  __Arguments__ { String }
  function SetElementParentID(self, elementID)
    self.inheritFromElementID = elementID
    return self
  end


  function Build(self, context)
    super.Build(self, context)

    -- Get the theme selected
    local selectedTheme = Themes:GetSelected()
    local stateSelected = context("state_selected")

    if not selectedTheme or not self.elementID then
      return
    end

    -- Resolve the element IDs
    self.rElementID            = ConcatIDWithState(self.elementID, stateSelected)

    local group = CreateGroup()
    context.parentWidget:AddChild(group)

    -- 1. [FRAME] Background color
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.FRAME_BACKGROUND_COLOR) then
      local flag = Theme.SkinFlags.FRAME_BACKGROUND_COLOR
      local backgroundColor = _AceGUI:Create("ColorPicker")
      backgroundColor:SetHasAlpha(true)

      local row = CreateRow("Background Color", backgroundColor)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, backgroundColor, flag)
      end

      self:RefreshControl(backgroundColor, flag)
      self:InstallCallbacks(row, backgroundColor, flag)
    end

    -- 2. [FRAME] Background texture
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE) then
      local flag = Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE
      local backgroundTexture = _AceGUI:Create("LSM30_Background")

      backgroundTexture:SetList(_Backgrounds)

      local row = CreateRow("Background Texture", backgroundTexture)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, backgroundTexture, flag)
      end
      self:RefreshControl(backgroundTexture, flag)
      self:InstallCallbacks(row, backgroundTexture, flag)
    end

    -- 3. [FRAME] Border Color
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.FRAME_BORDER_COLOR) then
      local flag = Theme.SkinFlags.FRAME_BORDER_COLOR
      local borderColor = _AceGUI:Create("ColorPicker")
      borderColor:SetHasAlpha(true)

      local row = CreateRow("Border Color", borderColor)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, borderColor, flag)
      end
      self:RefreshControl(borderColor, flag)
      self:InstallCallbacks(row, borderColor, flag)
    end

    -- 4. [FRAME] Border Width
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.FRAME_BORDER_WIDTH) then
      local flag = Theme.SkinFlags.FRAME_BORDER_WIDTH
      local borderWidth = _AceGUI:Create("Slider")
      borderWidth:SetValue(10)

      local row = CreateRow("Border Width", borderWidth)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, borderWidth, flag)
      end
      self:RefreshControl(borderWidth, flag)
      self:InstallCallbacks(row, borderWidth, flag)
    end

    -- 5. [TEXT] Text Size
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_SIZE) then
      local flag = Theme.SkinFlags.TEXT_SIZE
      local textSize = _AceGUI:Create("Slider")
      textSize:SetSliderValues(6, 32, 1)

      local row = CreateRow("Text Size", textSize)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textSize, flag)
      end
      self:RefreshControl(textSize, flag)
      self:InstallCallbacks(row, textSize, flag)
    end

    -- 6. [TEXT] Text Color
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_COLOR) then
      local flag = Theme.SkinFlags.TEXT_COLOR
      local textColor = _AceGUI:Create("ColorPicker")

      local row = CreateRow("Text Color", textColor)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textColor, flag)
      end
      self:RefreshControl(textColor, flag)
      self:InstallCallbacks(row, textColor, flag)
    end

    -- 7. [TEXT] Text Font
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_FONT) then
      local flag = Theme.SkinFlags.TEXT_FONT
      local textFont = _AceGUI:Create("LSM30_Font")
      textFont:SetList(_Fonts)

      local row = CreateRow("Text Font", textFont)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textFont, flag)
      end
      self:RefreshControl(textFont, flag)
      self:InstallCallbacks(row, textFont, flag)
    end

    -- 8. [TEXT] Text Transform
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_TRANSFORM) then
      local flag = Theme.SkinFlags.TEXT_TRANSFORM
      local textTransform = _AceGUI:Create("Dropdown")
      textTransform:SetList(_TextTransforms)

      local row = CreateRow("Text Transform", textTransform)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textTransform, flag)
      end
      self:RefreshControl(textTransform, flag)
      self:InstallCallbacks(row, textTransform, flag)
    end

    -- 9. [TEXT] Text Justify Horizontal
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL) then
      local flag = Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL
      local textJustifyH = _AceGUI:Create("Dropdown")
      textJustifyH:SetList(_TextJustifyHorizontal)

      local row = CreateRow("Text Justify Horizontal", textJustifyH)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textJustifyH, flag)
      end
      self:RefreshControl(textJustifyH, flag)
      self:InstallCallbacks(row, textJustifyH, flag)
    end

    -- 10. [TEXT] Text Justify Vertical
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL) then
      local flag = Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL
      local textJustifyV = _AceGUI:Create("Dropdown")
      textJustifyV:SetList(_TextJustifyVertical)

      local row = CreateRow("Text Justify Vertical", textJustifyV)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textJustifyV, flag)
      end
      self:RefreshControl(textJustifyV, flag)
      self:InstallCallbacks(row, textJustifyV, flag)
    end

    -- 11. [TEXTURE] Texture Color
    if Enum.ValidateFlags(self.flags, Theme.SkinFlags.TEXTURE_COLOR) then
      local flag = Theme.SkinFlags.TEXTURE_COLOR
      local textureColor = _AceGUI:Create("ColorPicker")
      textureColor:SetHasAlpha(true)

      local row = CreateRow("Texture Color", textureColor)
      group:AddChild(row)

      -- if there is a value in the DB,  add a reset button
      if selectedTheme:GetElementPropertyFromDB(self.rElementID , _FLAGS_PROPERTIES[flag]) then
        self:ShowReset(row, textureColor, flag)
      end
      self:RefreshControl(textureColor, flag)
      self:InstallCallbacks(row, textureColor, flag)
    end





    --[[

    local g = _AceGUI:Create("InlineGroup")
    g:SetLayout("Flow")
    g:SetRelativeWidth(1.0)
    g:SetTitle("")

    local label = _AceGUI:Create("Label")
    label:SetRelativeWidth(0.3)
    label:SetFontObject(GameFontHighlight)
    label:SetText("Background color")
    g:AddChild(label)


    local backgroundColor = _AceGUI:Create("ColorPicker")
    backgroundColor:SetHasAlpha(true)
    backgroundColor:SetRelativeWidth(0.3)
    g:AddChild(backgroundColor)

    local space = _AceGUI:Create("Label")
    space:SetRelativeWidth(0.1)
    space:SetText("")
    g:AddChild(space)

    context.parentWidget:AddChild(g)--]]

  end

  property "elementID"              { TYPE = String }
  property "inheritFromElementID"   { TYPE = String }
  property "flags"                  { TYPE = Theme.SkinFlags, DEFAULT = Theme.SkinFlags.FRAME_BACKGROUND_COLOR + Theme.SkinFlags.FRAME_BACKGROUND_TEXTURE }
  property "rElementID"             { TYPE = String }
  property "rInheritFromElementID"  { TYPE = String }

end)

class "ThemeInformationRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                     Helper functions                                     --
  ------------------------------------------------------------------------------
  local function CreateRow(name, value)
    local row = _AceGUI:Create("SimpleGroup")
    row:SetRelativeWidth(1.0)
    row:SetLayout("Flow")

    local label = _AceGUI:Create("Label")
    label:SetRelativeWidth(0.2)
    label:SetFontObject(GameFontHighlight)
    label:SetText(name)
    row:AddChild(label)

    local valueFrame = _AceGUI:Create("Label")
    valueFrame:SetRelativeWidth(0.3)
    valueFrame:SetText(value)
    row:AddChild(valueFrame)
    row:SetUserData("valueFrame", valueFrame)

    return row
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local theme = Themes:GetSelected()

    self.rowName    = CreateRow("Name", theme.name)
    self.rowAuthor  = CreateRow("Author", theme.author)
    self.rowVersion = CreateRow("Version", theme.version)
    self.rowStage   = CreateRow("Stage", theme.stage)

    context.parentWidget:AddChild(self.rowName)
    context.parentWidget:AddChild(self.rowAuthor)
    context.parentWidget:AddChild(self.rowVersion)
    context.parentWidget:AddChild(self.rowStage)

  end

  function Refresh(self)
    local theme = Themes:GetSelected()
    if self.rowName and self.rowAuthor and self.rowVersion and self.rowStage then
      self.rowName:GetUserData("valueFrame"):SetText(theme.name)
      self.rowAuthor:GetUserData("valueFrame"):SetText(theme.author)
      self.rowVersion:GetUserData("valueFrame"):SetText(theme.version)
      self.rowStage:GetUserData("valueFrame"):SetText(theme.stage)
    end
  end

  __Arguments__ { String, Variable.Optional(Table), Variable.Rest()}
  function OnRecipeEvent(self, event, sender, ...)
    self:Refresh()
  end
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function ThemeInformationRecipe(self)
    super(self)

    self:RegisterEvent("EKT_OPTION_CHANGED")
    self:RegisterRecipeEvent("SELECT_THEME_CHANGED")
  end
end)


class "ImportThemeRecipe" (function(_ENV)
  inherit "OptionRecipe"

  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  event "OnTextChanged"
  event "OnImportThemeRequest"

  local function ValidateName(name)
    if Themes:Get(name) then
      return false, "Name already taken"
    end

    return true, "Name is avalaible"
  end

  StaticPopupDialogs["EKT_THEME_NEW_NAME"] = {
    text = "A theme with this name already exists.\nChoose an another one to continue",
    subText = "",
    button1 = OKAY,
    hasEditBox = true,
    OnAccept = function(self, data) Themes:Import(data, self.editBox:GetText()) end,
    OnShow = function(self)
      self.button1:Disable()
      self.editBox:SetFocus()
    end,
    OnHide = function(self)
      self.editBox:SetText("")
    end,
    EditBoxOnTextChanged = function(self)
      local name = self:GetText()
      local parent = self:GetParent()
      local validate, msg = ValidateName(name)
      if name ~= "" then
        if validate then
          parent.button1:Enable()
          parent.SubText:SetText(string.format("|cff00ff00%s|r", msg))
        else
          parent.button1:Disable()
          parent.SubText:SetText(string.format("|cffff0000%s|r", msg))
        end
      end
    end
  }

  local function CreateRow(name, value)
    local row = _AceGUI:Create("SimpleGroup")
    row:SetRelativeWidth(1.0)
    row:SetLayout("Flow")

    local label = _AceGUI:Create("Label")
    label:SetRelativeWidth(0.2)
    label:SetFontObject(GameFontHighlight)
    label:SetText(name)
    row:AddChild(label)

    local valueFrame = _AceGUI:Create("Label")
    valueFrame:SetRelativeWidth(0.3)
    valueFrame:SetText(value)
    row:AddChild(valueFrame)

    return row, valueFrame
  end

  function Build(self, context)
    super.Build(self, context)

    -- local default values
    local defaultForceOverride = OptionBuilder:GetVariable("import-theme-force-override") or false

    local textBox = _AceGUI:Create("MultiLineEditBox")
    textBox:SetLabel("Paste text below to import the theme")
    textBox:SetRelativeWidth(1.0)
    textBox:DisableButton(true)
    textBox:SetNumLines(10)
    context.parentWidget:AddChild(textBox)

    local headingThemeInfo = _AceGUI:Create("Heading")
    headingThemeInfo:SetText("Theme Information")
    context.parentWidget:AddChild(headingThemeInfo)


    local rowName, name = CreateRow("Name:")
    context.parentWidget:AddChild(rowName)

    local rowAuthor, author = CreateRow("Author:")
    context.parentWidget:AddChild(rowAuthor)

    local rowVersion, version = CreateRow("Version:")
    context.parentWidget:AddChild(rowVersion)

    local rowStage, stage = CreateRow("Stage:")
    context.parentWidget:AddChild(rowStage)

    local importFlags = _AceGUI:Create("Heading")
    importFlags:SetText("Import flags")
    context.parentWidget:AddChild(importFlags)

    local override = _AceGUI:Create("CheckBox")
    override:SetLabel("Force override")
    override:SetValue(false)
    context.parentWidget:AddChild(override)

    local separator = _AceGUI:Create("Heading")
    separator:SetText("")
    separator:SetRelativeWidth(1.0)
    context.parentWidget:AddChild(separator)

    local import = _AceGUI:Create("Button")
    import:SetText("Import")
    import:SetRelativeWidth(1.0)
    context.parentWidget:AddChild(import)

    -- Callback
    import:SetCallback("OnClick", function()
      local forceOverride = override:GetValue()
      if not forceOverride then
        local themeName = OptionBuilder:GetVariable("import-theme-name")
        if ValidateName(themeName) then
          Themes:Import(textBox:GetText())
        else
          local dialog = StaticPopup_Show("EKT_THEME_NEW_NAME")
          if dialog then
            dialog.data = textBox:GetText()
          end
        end
      else
        Themes:Override(textBox:GetText())
      end
    end)


    textBox:SetCallback("OnTextChanged", function()
      local theme, msg = Theme:GetFromText(textBox:GetText())
      local successColor = "ff00ff00"
      local failedColor = "ffff0000"

      if theme then
        name:SetText(string.format("|c%s%s|r", successColor, theme.name))
        author:SetText(string.format("|c%s%s|r", successColor, theme.author))
        version:SetText(string.format("|c%s%s|r", successColor, theme.version))
        stage:SetText(string.format("|c%s%s|r", successColor, theme.stage))
        OptionBuilder:SetVariable("import-theme-name", theme.name)
      else
        name:SetText(string.format("|c%s%s|r", failedColor, msg))
        author:SetText(string.format("|c%s%s|r", failedColor, msg))
        version:SetText(string.format("|c%s%s|r", failedColor, msg))
        stage:SetText(string.format("|c%s%s|r", failedColor, msg))
      end
    end)
  end
end)

class "ExportThemeRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    super.Build(self, context)

    -- Get the selected theme
    local theme = Themes:GetSelected()
    OptionBuilder:SetVariable("export-theme-selected", theme.name)
    -- default values
    local defaultIncludeDBValues = OptionBuilder:GetVariable("export-theme-include-db-values") or true

    local selectTheme = _AceGUI:Create("Dropdown")
    selectTheme:SetLabel("Select Theme to export")
    selectTheme:SetRelativeWidth(0.25)
    selectTheme:SetText(theme.name)
    context.parentWidget:AddChild(selectTheme)

    local themeList = {}
    for _, theme in Themes:GetIterator() do
      themeList[theme.name] = theme.name
    end
    selectTheme:SetList(themeList)

    -- Line
    local headingTop = _AceGUI:Create("Heading")
    headingTop:SetText("")
    context.parentWidget:AddChild(headingTop)

    -- Export text
    local textBox = _AceGUI:Create("MultiLineEditBox")
    textBox:SetLabel("Theme text export")
    textBox:SetRelativeWidth(1.0)
    textBox:DisableButton(true)
    context.parentWidget:AddChild(textBox)

    textBox:SetText(theme:ExportToText(defaultIncludeDBValues))
    textBox:SetNumLines(20)
    textBox:HighlightText()

    -- Export Flags line
    local headingFlags = _AceGUI:Create("Heading")
    headingFlags:SetText("Export flags")
    context.parentWidget:AddChild(headingFlags)

    local includeDBValue = _AceGUI:Create("CheckBox")
    includeDBValue:SetLabel("Include database values")
    includeDBValue:SetCallback("OnValueChanged", function(_, _, value)
      OptionBuilder:SetVariable("export-theme-include-db-values", value)
      textBox:SetText(Themes:Get(OptionBuilder:GetVariable("export-theme-selected")):ExportToText(value))
      textBox:HighlightText()
    end)
    context.parentWidget:AddChild(includeDBValue)

    -- Callback
    selectTheme:SetCallback("OnValueChanged", function(_, _, themeName)
      OptionBuilder:SetVariable("export-theme-selected", themeName)
      textBox:SetText(Themes:Get(themeName):ExportToText(OptionBuilder:GetVariable("export-theme-include-db-values")))
      textBox:HighlightText()
    end)
  end

end)

class "CreateThemeRecipe" (function(_ENV)
  inherit "OptionRecipe"

  function Build(self, context)
    super.Build(self, context)

    -- Set the default values
    local defaultAuthor           = UnitName("player")
    local defaultStage            = "Release"
    local defaultVersion          = "1.0.0"
    local defaultCopyFrom         = "none"
    local defaultIncludeDBValues  = OptionBuilder:GetVariable("create-theme-include-db-values") or true

    local name = _AceGUI:Create("EditBox")
    name:SetLabel("Name")
    name:SetRelativeWidth(0.2)
    context.parentWidget:AddChild(name)

    local author = _AceGUI:Create("EditBox")
    author:SetLabel("Author")
    author:SetRelativeWidth(0.19)
    author:SetText(defaultAuthor)
    context.parentWidget:AddChild(author)

    local version = _AceGUI:Create("EditBox")
    version:SetLabel("Version")
    version:SetRelativeWidth(0.15)
    version:SetText(defaultVersion)
    context.parentWidget:AddChild(version)

    local stage = _AceGUI:Create("Dropdown")
    stage:SetLabel("Stage")
    stage:SetText(defaultStage)
    stage:SetRelativeWidth(0.15)
    stage:SetList({
      ["Alpha"]     = "Alpha",
      ["Beta"]      = "Beta",
      ["Release"]   = "Release"
    })
    stage:SetCallback("OnValueChanged", function(_, _,  stage) OptionBuilder:SetVariable("create-theme-stage", stage) end)
    context.parentWidget:AddChild(stage)

    local copyFrom = _AceGUI:Create("Dropdown")
    copyFrom:SetLabel("Copy From")
    copyFrom:SetRelativeWidth(0.2)
    context.parentWidget:AddChild(copyFrom)

    local createButton = _AceGUI:Create("Button")
    createButton:SetText("Create")
    createButton:SetRelativeWidth(0.1)
    context.parentWidget:AddChild(createButton)

    local includeDBValues = _AceGUI:Create("CheckBox")
    includeDBValues:SetLabel("Include database values")
    includeDBValues:SetValue(defaultIncludeDBValues)
    context.parentWidget:AddChild(includeDBValues)

    createButton:SetCallback("OnClick", function()
      local themeToCopy = OptionBuilder:GetVariable("create-theme-copy-from") or defaultCopyFrom
      local themeName = name:GetText()
      local themeAuthor = author:GetText() or defaultAuthor
      local themeVersion = version:GetText() or defaultVersion
      local themeStage = OptionBuilder:GetVariable("create-theme-stage") or defaultStage
      local themeToCopy = OptionBuilder:GetVariable("create-theme-copy-from") or defaultCopyFrom
      local includeDBValues = OptionBuilder:GetVariable("create-theme-include-db-values") or defaultIncludeDBValues

      if themeToCopy and themeToCopy ~= "none" then
        Themes:CreateDBTheme(themeName, themeAuthor, themeVersion, themeStage, themeToCopy, includeDBValues)
      else
        Themes:CreateDBTheme(themeName, themeAuthor, themeVersion, themeStage)
      end
    end)

    local themeList = {}
    themeList["none"] = "None"
    for _, theme in Themes:GetIterator() do
      themeList[theme.name] = theme.name
    end
    copyFrom:SetList(themeList)
    copyFrom:SetText(themeList[defaultCopyFrom])
    copyFrom:SetCallback("OnValueChanged", function(_, _, theme) OptionBuilder:SetVariable("create-theme-copy-from", theme) end)

  end

end)
