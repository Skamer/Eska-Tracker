-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio          "EskaTracker.Options.CommonRecipes"                          ""
-- ========================================================================== --
namespace "EKT"
--============================================================================--

class "TreeItemRecipe" inherit "OptionRecipe"
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

  function SetPath(self, path)
    self.path = path
    return self
  end


  property "path" { TYPE = String }
  property "icon" { TYPE = String + Number }

endclass "TreeItemRecipe"


class "TreeRecipe" inherit "OptionRecipe"
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
      self.onSelectedCallback(self, id)
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

  function SetDefaultBuldingGroup(self, buildingGroup)
    self.defaultBuildingGroup = buildingGroup
    return self
  end

  function SetIcon(self, icon)
    self.icon = icon
    return self
  end

  __Arguments__ { Function }
  function OnSelected(self, func)
    self.onSelectedCallback = func
    return self
  end

  property "defaultBuildingGroup" { TYPE = String }
  property "icon" { TYPE = String + Number }
  property "onSelectedCallback" { TYPE = Function }

endclass "TreeRecipe"


class "TabRecipe" inherit "OptionRecipe"
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

endclass "TabRecipe"



class "TabItemRecipe" inherit "OptionRecipe"
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

endclass "TabItemRecipe"


class "SimpleGroupRecipe" inherit "OptionRecipe"
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

  property "layout"  { TYPE = String, DEFAULT = "Flow"}
endclass "SimpleGroupRecipe"

class "InlineGroupRecipe" inherit "OptionRecipe"
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

  property "layout" { TYPE = String, DEFAULT = "Flow"}

endclass "InlineGroupRecipe"

class "HeadingRecipe" inherit "OptionRecipe"
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local heading = _AceGUI:Create("Heading")
    heading:SetRelativeWidth(1.0)
    heading:SetText(self.text)
    context.parentWidget:AddChild(heading)
  end
endclass "HeadingRecipe"

class "CheckBoxRecipe" inherit "OptionFrameRecipe"

  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local checkbox = _AceGUI:Create("CheckBox")
    checkbox:SetLabel(self.text)
    checkbox:SetValue(self:GetOption())
    checkbox:SetCallback("OnValueChanged", function(_, _, value)
      self:SetOption(value)

      if self.onValueChangedCallback then
        self.onValueChangedCallback(self, value)
      end
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

  __Arguments__ { Function }
  function OnValueChanged(self, func)
    self.onValueChangedCallback = func
    return self
  end

  property "onValueChangedCallback" { TYPE = Function }

endclass "CheckBoxRecipe"


class "ButtonRecipe" inherit "OptionFrameRecipe"
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local button = _AceGUI:Create("Button")
    button:SetText(self.text)
    button:SetCallback("OnClick", function()
      if self.onClickCallback then
        self.onClickCallback(self)
      end
    end)

    context.parentWidget:AddChild(button)
  end

  __Arguments__ { Function }
  function OnClick(self, func)
    self.onClickCallback = func
    return self
  end

  property "onClickCallback" { TYPE = Function }

endclass "ButtonRecipe"

class "RangeRecipe" inherit "OptionRecipe"

  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local range = _AceGUI:Create("Slider")
    range:SetSliderValues(self.min, self.max, self.step)
    range:SetLabel(self.text)
    range:SetValue(self:GetOption() or 0)
    range:SetCallback("OnValueChanged", function(_, _, value) self:SetOption(value) end)
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

  property "min" { TYPE = Number, DEFAULT = 0 }
  property "max" { TYPE = Number, DEFAULT = 100 }
  property "step" { TYPE = Number, DEFAULT = 1 }


endclass "RangeRecipe"
