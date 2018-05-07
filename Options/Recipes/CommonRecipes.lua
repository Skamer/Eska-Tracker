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
        if recipe then
          widget:ReleaseChildren()
          recipe:Build(OptionContext(widget, self, self.context))
          widget:DoLayout()
        end
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
    select:SetCallback("OnValueChanged", function(_, _, value) self:OnValueChanged() ; self:SetOption(value) end)
    context.parentWidget:AddChild(select)
  end

  __Arguments__ { Function }
  function SetList(self, func)
    self.getListFunc = func
    return self
  end

  __Arguments__ { Table }
  function SetList(self, list)
    return SetList(function() return list end)
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
    super.Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)

    local lineEdit = _AceGUI:Create("EditBox")
    lineEdit:SetLabel(self.text)
    lineEdit:SetText(self:GetOption())
    lineEdit:SetCallback("OnTextChanged", function(_, _, value) self:OnValueChanged(value) end)
    lineEdit:SetCallback("OnEnterPressed", function(_, _, value) self:OnValueConfirmed(value) ; self:SetOption(value) end)
    context.parentWidget:AddChild(lineEdit)
  end

end)
