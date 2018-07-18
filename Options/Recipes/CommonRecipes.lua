--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio          "EskaTracker.Options.CommonRecipes"                          ""
--============================================================================--
namespace                           "EKT"
--============================================================================--
--------------------------------------------------------------------------------
--                                                                            --
--                           TreeItem Recipe                                  --
--                                                                            --
--------------------------------------------------------------------------------
class "TreeItemRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local recipes = self:GetRecipes()
    if recipes then
      local childContext = OptionContext(context.parentWidget, self, context)
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(context.parentWidget, self, context))
      end
    end
  end

  __Arguments__ { String }
  function SetPath(self, path)
    self.path = path
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "path" { TYPE = String }
  property "icon" { TYPE = String + Number }
end)
--------------------------------------------------------------------------------
--                                                                            --
--                            Tree Recipe                                     --
--                                                                            --
--------------------------------------------------------------------------------
class "TreeRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  --- --------------------------------------------------------------------------
  --- Fires when the user selects an item (category)
  event "OnItemSelected"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local rootTree = {
      {
        value    = self.id,
        text     = self.text,
        icon     = self.icon,
        children = {},
      }
    }

    local treeCategories   = rootTree[1].children
    local categoriesTable  = Dictionary()
    categoriesTable[self.id] = rootTree[1]
    -- TODO: Maybe add a cache system.

    local function FindUniqueValue(id)
      local info = categoriesTable[id]


      if info.uniquePath then
        return info.uniquePath
      end

      local parentInfo = info and categoriesTable[info.path]
      local uniqueValue = id
      while parentInfo ~= nil do
        uniqueValue = parentInfo.value .."\001"..uniqueValue
        parentInfo = parentInfo.path and categoriesTable[parentInfo.path]
      end

      info.uniqueValue = uniqueValue

      return uniqueValue
    end

    -- Build the structure of tree from recipes contained in the building group.
    local recipes = self:GetRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        local list = categoriesTable[recipe.id]
        if not list then
          list = {}
        end

        list.value = recipe.id
        list.text  = recipe.text
        list.order = recipe.order
        list.icon  = recipe.icon
        list.path  = recipe.path or self.id


        if recipe.path and recipe.path ~= "" then
          local parent = categoriesTable[recipe.path]
          if parent then
            if not parent.children then
              parent.children = {}
            end
          else
            parent = {
              value    = recipe.path,
              text     = recipe.path,
              order    = recipe.order,
              children = {}
            }

            categoriesTable[recipe.path] = parent
          end
          list.isAdded = true
          tinsert(parent.children, list)

        else
          if not list.isAdded then
            list.isAdded = true
            tinsert(treeCategories, list)
          end
        end

        if not categoriesTable[recipe.id] then
          categoriesTable[recipe.id] = list
        end
      end
    end

    -- Then we sort them by order
    local function SortByOrder(t)
      table.sort(t, function(a, b) return a.order < b.order end)
      for index, child in ipairs(t) do
        if child.children then
          SortByOrder(child.children)
        end
      end
    end
    SortByOrder(treeCategories)


    -- REVIEW: Maybe used a variable to know if the children should be released in using the context.
    context.parentWidget:ReleaseChildren()

    -- Create the widgets
    local widget = _AceGUI:Create("TreeGroup")
    widget:SetTree(rootTree)
    widget:SelectByValue("EKT")
    widget:SetLayout("Flow")
    context.parentWidget:AddChild(widget)

    local scrollContainer = _AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")

    widget:AddChild(scrollContainer)

    local content  = _AceGUI:Create("ScrollFrame")
    content:SetLayout("List")
    content:SetFullWidth(true)
    scrollContainer:AddChild(content)

    -- Helpful function to select a category.
    -- A TreeItemRecipe is considered as category.
    local function SelectCategory(id, mustChangeUrlPart)
      local useDefault = false
      self:OnItemSelected(id)

      if id then
        --local recipe = OptionBuilder:GetRecipe(id, self:ResolveGroup())
        local recipe = self:GetRecipe(id)
        if recipe then
          content:ReleaseChildren()

          -- Create the child context
          local childContext = OptionContext(content, self, self.context)
          if mustChangeUrlPart then
            childContext:IncrementVariable("url_current_index", nil, childContext:GetVariable("url_part_count"))
          end
          recipe:Build(childContext)
          self.context.parentWidget:DoLayout()
        else
          useDefault = true
        end
      else
        useDefault = true
      end

      if useDefault then
        local recipes = OptionBuilder:GetRecipes(self.defaultBuildingGroup)
        if recipes then
          content:ReleaseChildren()
          -- Create the child context
          for index, recipe in recipes:GetIterator() do
            recipe:Build(OptionContext(content, self, self.context))
          end
          self.context.parentWidget:DoLayout()
        end
      end
    end

    widget:SetCallback("OnGroupSelected", function(_, _, uniquePath)
      local categories = { strsplit("\001", uniquePath) }
      local path = categories[#categories]
      if path == self.id then
        SelectCategory(nil)
      else
        SelectCategory(path)
      end
    end)

    local currentUrlPart = self:GetCurrentUrlPart()
    if currentUrlPart then
      SelectCategory(currentUrlPart, true)
      widget:SelectByValue(FindUniqueValue(currentUrlPart))
    else
    -- NOTE: By default, the recipes contained in default bulding group will be built
    -- REVIEW: I think the context should be used for setting the default category, so later
    -- need to change that.
    SelectCategory()
    end
  end

  __Arguments__ { String }
  function SetDefaultBuldingGroup(self, buildingGroup)
    self.defaultBuildingGroup = buildingGroup
    return self
  end

  function SetIcon(self, icon)
    self.icon = icon
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "defaultBuildingGroup" { TYPE = String }
  property "icon"                 { TYPE = String + Number }
end)
--------------------------------------------------------------------------------
--                                                                            --
--                              Tab Recipe                                    --
--                                                                            --
--------------------------------------------------------------------------------
class "TabRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local widget = _AceGUI:Create("TabGroup")
    widget:SetLayout("Flow")
    widget:SetFullWidth(true)

    local recipes = self:GetRecipes()
    local firstRecipe
    if recipes then
      local tabs = {}
      for index, recipe in recipes:GetIterator() do
        if index == 1 then
          firstRecipe = recipe
        end

        tinsert(tabs, {
          value = recipe.id,
          text  = recipe.text
        })
      end
      widget:SetTabs(tabs)

      local function SelectTab(id)
        --local recipe = OptionBuilder:GetRecipe(id, self:ResolveGroup())
        local recipe = self:GetRecipe(id)

        if self.saveChoiceVariable then
          self.context:SetVariable(self.saveChoiceVariable, id)
        end

        if recipe then
          widget:ReleaseChildren()
          recipe:Build(OptionContext(widget, self, self.context))
          widget:DoLayout()
        end

        self.context.parentWidget:DoLayout()
      end

      widget:SetCallback("OnGroupSelected", function(_, _, group)
        SelectTab(group)
      end)

      if firstRecipe then
        widget:SelectTab(firstRecipe.id)
      end
    end

    context.parentWidget:AddChild(widget)
  end

  __Arguments__ { String }
  function SetSaveChoiceVariable(self, variableName)
    self.saveChoiceVariable = variableName
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "saveChoiceVariable" { TYPE = String }
end)
--------------------------------------------------------------------------------
--                                                                            --
--                            TabItem Recipe                                  --
--                                                                            --
--------------------------------------------------------------------------------
class "TabItemRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local recipes = self:GetRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(context.parentWidget, self, context))
      end
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                         SimpleGroup Recipe                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "SimpleGroupRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local group = _AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    group:SetLayout(self.layout)
    context.parentWidget:AddChild(group)

    local recipes = self:GetBuildingRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(group, self, context))
      end
    end
  end

  __Arguments__ { String }
  function SetLayout(self, layout)
    self.layout = layout
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "layout"  { TYPE = String, DEFAULT = "Flow"}
end)
--------------------------------------------------------------------------------
--                                                                            --
--                         InlineGroup Recipe                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "InlineGroupRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    if not self.buildingGroup then
      return
    end

    local group = _AceGUI:Create("InlineGroup")
    group:SetFullWidth(true)
    group:SetLayout(self.layout)
    group:SetTitle(self.text)
    context.parentWidget:AddChild(group)

    local recipes = self:GetBuildingRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(group, self, context))
      end
    end

  end

  __Arguments__ { String }
  function SetLayout(self, layout)
    self.layout = layout
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "layout" { TYPE = String, DEFAULT = "Flow"}
end)
--------------------------------------------------------------------------------
--                                                                            --
--                             Heading Recipe                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "HeadingRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local heading = _AceGUI:Create("Heading")
    heading:SetRelativeWidth(1.0)
    heading:SetText(self.text)
    context.parentWidget:AddChild(heading)
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                             Checkbox Recipe                                --
--                                                                            --
--------------------------------------------------------------------------------
class "CheckBoxRecipe" (function(_ENV)
  inherit "OptionFrameRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  -- Fires when the value has changed
  event "OnValueChanged"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local checkbox = _AceGUI:Create("CheckBox")
    checkbox:SetLabel(self.text)
    checkbox:SetValue(self:GetOption())
    checkbox:SetType(self.type)
    checkbox:SetCallback("OnValueChanged", function(_, _, value)
      self:SetOption(value)
      self:OnValueChanged(value)
    end)

    if self.width then
      if self.width > 0 and self.width <= 1 then
        checkbox:SetRelativeWidth(self.width)
      else
        checkbox:SetWidth(self.width)
      end
    end

    context.parentWidget:AddChild(checkbox)
  end

  __Arguments__ { String }
  function SetType(self, type)
    self.type = type
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "type" { TYPE = String, DEFAULT = "checkbox"}
end)
--------------------------------------------------------------------------------
--                                                                            --
--                             RadioRow Recipe                                --
--                                                                            --
--------------------------------------------------------------------------------
class "RadioRowRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  event "OnValueChanged"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local radioSelected
    local optionValue = self:GetOption()
    local first
    for value, display in self.choices:GetIterator() do
      local radio = _AceGUI:Create("CheckBox")
      radio:SetLabel(display)
      radio:SetType("radio")
      radio:SetUserData("value", value)
      radio:SetCallback("OnValueChanged", function(r, _, value)
        if radioSelected then
          radioSelected:SetValue(false)
        end
        radioSelected = r
      end)

      if optionValue and optionValue == value then
        radio:SetValue(true)
        radioSelected = radio
      end

      if not first then
        first = radio
      end

      context.parentWidget:AddChild(radio)
    end

    if not radioSelected then
      radioSelected = first
      first:SetValue(true)
    end
  end

  __Arguments__ { Any, Any}
  function AddChoice(self, value, display)
    self.choices[value] = display
    return self
  end
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function RadioRowRecipe(self)
    super(self)

    self.choices = Dictionary()
  end

end)
--------------------------------------------------------------------------------
--                                                                            --
--                           RadioGroup Recipe                                --
--                                                                            --
--------------------------------------------------------------------------------
class "RadioGroupRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    -- Avoid to continue if there is no building group
    if not self.buildingGroup then
      return
    end

    local radioSelected
    local optionValue = self:GetOption()
    local first
    for index, info in self.choices:GetIterator() do
      local radio = _AceGUI:Create("CheckBox")
      radio:SetLabel(info.display)
      radio:SetType("radio")

      if self.itemWidth > 0 and self.itemWidth <= 1 then
        radio:SetRelativeWidth(self.itemWidth)
      elseif self.itemWidth > 1 then
        radio:SetWidth(self.itemWidth)
      end
      radio:SetUserData("value", info.value)
      radio:SetCallback("OnValueChanged", function(r, _, value)
        if radioSelected then
          radioSelected:SetValue(false)
        end
        radioSelected = r

        if self.saveChoiceVariable then
          context:SetVariable(self.saveChoiceVariable, radioSelected:GetUserData("value"))
        end

        self:SetOption(info.value)

        self:RebuildChildren()
      end)

      -- Select the radio if it's defined by the user
      if optionValue and optionValue == info.value then
        radio:SetValue(true)
        radioSelected = radio
      end

      if not first then
        first = radio
      end

      context.parentWidget:AddChild(radio)
    end

    -- if no radio is slected, select the first
    if not radioSelected then
      radioSelected = first
      first:SetValue(true)
    end

    if self.saveChoiceVariable then
      context:SetVariable(self.saveChoiceVariable, radioSelected:GetUserData("value"))
    end

    if self.addSeparator then
      context.parentWidget:AddChild(_AceGUI:Create("Heading"))
    end

    -- Create the group
    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetRelativeWidth(1.0)
    context.parentWidget:AddChild(group)
    -- Set it in the cache for rebuilding its children
    self.cache["group"] = group

    -- Build the first time its children
    local recipes = self:GetRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(group, self, context))
      end
    end
    self.context.parentWidget:DoLayout()
  end

  function RebuildChildren(self)
    local group = self.cache["group"]
    group:ReleaseChildren()

    local recipes = self:GetRecipes()
    if recipes then
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(group, self, self.context))
      end
    end
    group:DoLayout()
    self.context.parentWidget:DoLayout()
  end

  __Arguments__ { Any, Any }
  function AddChoice(self, value, display)
    self.choices:Insert({ value = value, display = display })
    return self
  end

  __Arguments__ { String }
  function SetSaveChoiceVariable(self, variableName)
    self.saveChoiceVariable = variableName
    return self
  end

  __Arguments__ { Boolean }
  function SetAddSeparator(self, add)
    self.addSeparator = add
    return true
  end

  __Arguments__ { Number }
  function SetItemWidth(self, width)
    self.itemWidth = width
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "saveChoiceVariable" { TYPE = String }
  property "addSeparator"       { TYPE = Boolean, DEFAULT = false }
  property "itemWidth"          { TYPE = Number, DEFAULT = 0 }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function RadioGroupRecipe(self)
    super(self)

    self.choices = List()
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                               Button Recipe                                --
--                                                                            --
--------------------------------------------------------------------------------
class "ButtonRecipe" (function(_ENV)
  inherit "OptionFrameRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  --- Fires when the button has clicked
  event "OnClick"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local button = _AceGUI:Create("Button")
    button:SetText(self.text)
    button:SetCallback("OnClick", function()
      self:OnClick()
    end)

    context.parentWidget:AddChild(button)
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                               Range Recipe                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "RangeRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  -- Fires when the value has changed
  event "OnValueChanged"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local range = _AceGUI:Create("Slider")
    range:SetSliderValues(self.min, self.max, self.step)
    range:SetLabel(self.text or "")
    range:SetValue(self:GetOption() or 0)
    range:SetCallback("OnValueChanged", function(_, _, value)
      self:SetOption(value)
      self:OnValueChanged(value)
    end)

    if self.width then
      if self.width <= 1 then
        range:SetRelativeWidth(self.width)
      else
        range:SetWidth(self.width)
      end
    end

    context.parentWidget:AddChild(range)
  end

  function SetRange(self, min, max)
    self.min = min
    self.max = max
    return self
  end


  function SetStep(self, step)
    self.step = step
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "min"      { TYPE = Number, DEFAULT = 0 }
  property "max"      { TYPE = Number, DEFAULT = 100 }
  property "step"     { TYPE = Number, DEFAULT = 1 }
end)
--------------------------------------------------------------------------------
--                                                                            --
--                              Select Recipe                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "SelectRecipe" (function(_ENV)
  inherit "OptionFrameRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  --- --------------------------------------------------------------------------
  --- Fires when the value has changed
  event "OnValueChanged"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local select = _AceGUI:Create("Dropdown")
    select:SetLabel(self.text)

    if self.width then
      if self.width > 0 and self.width <= 1 then
        select:SetRelativeWidth(self.width)
      else
        select:SetWidth(self.width)
      end
    end

    if self.getListFunc then
      select:SetList(self.getListFunc())
    end
    select:SetValue(self:GetOption())
    select:SetCallback("OnValueChanged", function(_, _, value) self:OnValueChanged(value) ; self:SetOption(value) end)
    context.parentWidget:AddChild(select)

    -- Register the frame in the cache
    self.cache["select"] = select
  end

  __Arguments__ { Function }
  function SetList(self, func)
    self.getListFunc = func
    return self
  end

  __Arguments__ {  RawTable + Table }
  function SetList(self, list)
    return SetList(self, function() return list end)
  end

  function Refresh(self)
    if self.cache["select"] then
      self.cache["select"]:SetValue(self:GetOption())
      self.cache["select"]:SetList(self.getListFunc())
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                         LineEdit Recipe                                    --
--                                                                            --
--------------------------------------------------------------------------------
class "LineEditRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  --- Fired when the value has changed
  event "OnValueChanged"
  --- Fired when the value has been confirmed (enter button and confirmation button)
  event "OnValueConfirmed"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local lineEdit = _AceGUI:Create("EditBox")
    lineEdit:SetLabel(self.text)
    lineEdit:SetText(self:GetOption())
    lineEdit:SetCallback("OnTextChanged", function(_, _, value) self:OnValueChanged(value) end)
    lineEdit:SetCallback("OnEnterPressed", function(_, _, value) self:OnValueConfirmed(value) ; self:SetOption(value) end)
    context.parentWidget:AddChild(lineEdit)
  end

end)
--------------------------------------------------------------------------------
--                                                                            --
--                         TextEdit Recipe                                    --
--                                                                            --
--------------------------------------------------------------------------------
class "TextEditRecipe" (function(_ENV)
  inherit "OptionRecipe"
  --- Fired when the value has changed
  event "OnValueChanged"
  --- Fired when the value has been confirmed (enter button and confirmation button)
  event "OnValueConfirmed"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local textEdit = self.luaSyntaxHighlighting and _AceGUI:Create("EskaTrackerMultiLineEditBox") or _AceGUI:Create("MultiLineEditBox")
    textEdit:SetLabel(self.text)
    textEdit:DisableButton(self.disableButton)
    textEdit:SetText(self:GetOption() or "")
    textEdit:SetNumLines(self.numLines)
    textEdit:SetCallback("OnTextChanged", function(_, _, value) self:OnValueChanged(value) end)
    textEdit:SetCallback("OnEnterPressed", function(_, _, value) self:OnValueConfirmed(value) ; self:SetOption(value) end)
    context.parentWidget:AddChild(textEdit)

    -- Do specific stuff when the lua syntax highlighting is enabled
    if self.luaSyntaxHighlighting then
      IndentationLib.enable(textEdit.editBox, nil, 2)
    end

    if self.width then
      if self.width > 0 and self.width <= 1 then
        textEdit:SetRelativeWidth(self.width)
      else
        textEdit:SetWidth(self.width)
      end
    end
  end

  __Arguments__ { Number }
  function SetNumLines(self, numLines)
    self.numLines = numLines
    return self
  end

  __Arguments__ { Boolean }
  function DisableButton(self, disable)
    self.disableButton = disable
    return self
  end

  __Arguments__{ Boolean }
  function SetLUASyntaxHighlighting(self, enable)
    self.luaSyntaxHighlighting = enable
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "numLines"               { TYPE = Number, DEFAULT =  10 }
  property "disableButton"          { TYPE = Boolean, DEFAULT = true }
  property "luaSyntaxHighlighting"  { TYPE = Boolean, DEFAULT = false }
end)
--------------------------------------------------------------------------------
--                                                                            --
--                         Text Recipe                                    --
--                                                                            --
--------------------------------------------------------------------------------
class "TextRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local text = _AceGUI:Create("Label")
    text:SetText(self.text)
    context.parentWidget:AddChild(text)

    if self.width then
      if self.width > 0 and self.width <= 1 then
        text:SetRelativeWidth(self.width)
      else
        text:SetWidth(self.width)
      end
    end
  end
end)
