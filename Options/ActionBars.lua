--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio               "EskaTracker.Options.ActionBars"                        ""
--============================================================================--
import                       "EKT"
--============================================================================--
function AddSuffix(id)
  return string.format("%s-action-bar", id)
end

function RemoveSuffix(id)
  return id:gsub("(%-action%-bar)$", "")
end

function GetCurrentActionBar(recipe)
  return ActionBars:Get(RemoveSuffix(recipe.context("action_bar_selected")))
end

local function GetActionBarList()
  local list = {}
  for id, actionBar in ActionBars:GetIterator() do
    list[id] = actionBar.name
  end
  return list
end

local function GetTrackerList()
  local list = {}
  list["none"] = "None"
  for id, tracker in Trackers:GetIterator() do
    list[id] = tracker.name
  end
  return list
end



function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("action-bars"):SetText("Action Bars"):SetBuildingGroup("action-bars/children"):SetOrder(200), "RootTree")

  -- Create an action bar
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(100):SetText("|cff00ff00Create an action bar|r"), "action-bars/children")

  local lineEdit = LineEditRecipe()
  lineEdit:SetText("Enter the name of your new action bar")
  lineEdit:SetOrder(110)
  lineEdit.OnValueChanged = lineEdit.OnValueChanged + function(self, name) OptionBuilder:SetVariable("create_action_bar_name", name) end
  OptionBuilder:AddRecipe(lineEdit, "action-bars/children")

  local createButton = ButtonRecipe()
  createButton:SetText("Create")
  createButton:SetOrder(120)
  createButton.OnClick = createButton.OnClick + function(recipe)
    local name = OptionBuilder:GetVariable("create_action_bar_name")
    if name then
      self:CreateActionBar(name, recipe)
    end
  end
  OptionBuilder:AddRecipe(createButton, "action-bars/children")

  -- Delete an action bar
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(200):SetText("|cffff0000Delete an action bar|r"), "action-bars/children")

  local selectActionBarToDelete = SelectRecipe()
  selectActionBarToDelete:SetText("Select the action bar to delete")
  selectActionBarToDelete:SetOrder(210)
  selectActionBarToDelete:RefreshOnRecipeEvent("ACTION_BAR_DELETED")
  selectActionBarToDelete:RefreshOnRecipeEvent("ACTION_BAR_CREATED")
  selectActionBarToDelete:SetList(GetActionBarList)
  selectActionBarToDelete.OnValueChanged = selectActionBarToDelete.OnValueChanged + function(recipe, value)
    OptionBuilder:SetVariable("delete_action_bar_id", value)
  end
  OptionBuilder:AddRecipe(selectActionBarToDelete, "action-bars/children")

  local deleteButton = ButtonRecipe()
  deleteButton:SetText("Delete")
  deleteButton:SetOrder(220)
  deleteButton.OnClick = deleteButton.OnClick + function(recipe)
    local id = OptionBuilder:GetVariable("delete_action_bar_id")
    if id then
      self:DeleteActionBar(id)
    end
  end
  OptionBuilder:AddRecipe(deleteButton, "action-bars/children")
end


function CreateActionBar(self, name, srcRecipe)
  local path  = "action-bars"
  local id    = ActionBar:GetIDFromName(name)
  local group = string.format("[action-bar&%s]/children", AddSuffix(id))

  if not ActionBars:Get(id) then
    local recipe = OptionBuilder:GetRecipe(id, group)
    if not recipe then
      local actionBar = ActionBars:New(id, true)
      local headingText = string.format("|cffff5000%s action bar Options|r", actionBar.name)

      -- Add Specific recipes
      OptionBuilder:AddRecipe(HeadingRecipe():SetText(headingText):SetOrder(1), string.format("%s/children", actionBar.id))
      OptionBuilder:AddRecipe(TreeItemRecipe():SetID(AddSuffix(id)):SetText(name):SetPath(path):SetBuildingGroup(group), "RootTree")

      -- Action Bar Theme property
      OptionBuilder:AddRecipe(ThemePropertyRecipe()
      :SetElementID(string.format("action-bar.%s.frame", actionBar.id))
      :SetElementParentID("action-bar.frame")
      :SetOrder(500)
      :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
      :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH), string.format("%s-action-bar/general", actionBar.id))

      -- Redirection and rebuild
      OptionBuilder:SetVariable("action_bar_selected", id)
      OptionBuilder:BuildUrl(id)
    end
  end
end

function DeleteActionBar(self, id)
  ActionBars:Delete(id)

  -- Then remove the recipes related to action bar which has been deleted
  OptionBuilder:RemoveRecipe(id, "RootTree")
  OptionBuilder:RemoveRecipes(string.format("%s/children", id))

  -- And to finish, redirect the user to action bar category
  OptionBuilder:BuildUrl("action-bars")
end


--- Register the recipes related to actionbar  registered
__SystemEvent__()
function EKT_ACTION_BAR_REGISTERED(actionBar)
  local idWithSuffix = AddSuffix(actionBar.id)
  local commonGroup  = string.format("[action-bar&%s]/children", idWithSuffix)
  local privateGroup = string.format("%s/children", idWithSuffix)

  --- Add specific recipes
  -- Create the heading text
  local headingText = string.format("|cffff5000%s Action Bar Options|r", actionBar.name)
  OptionBuilder:AddRecipe(HeadingRecipe():SetText(headingText):SetOrder(10), privateGroup)
  -- Create the Tree item
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID(idWithSuffix):SetText(actionBar.name):SetPath("action-bars"):SetBuildingGroup(commonGroup), "RootTree")

  -- Action Bar Theme property
  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("action-bar.%s.frame", actionBar.id))
  :SetElementParentID("action-bar.frame")
  :SetOrder(500)
  :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
  :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH), string.format("%s/general", idWithSuffix))
end

__SystemEvent__()
function EKT_ACTION_BARS_DELETED(actionBar)
  local idWithSuffix = AddSuffix(actionBar.id)

  OptionBuilder:RemoveRecipe(idWithSuffix, "RootTree")
  OptionBuilder:RemoveRecipes(string.format("%s/children", idWithSuffix))

  -- Redirect the user when it's done
  OptionBuilder:BuildUrl("action-bars")
end

__SystemEvent__()
function EKT_ACTION_BARS_LOADED()
  -- Create the tabs
  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("action-bar/tabs"), "action-bar/children")

  AddGeneralTabRecipes()
  AddActionButtonsTabRecipes()
end

function AddGeneralTabRecipes(self)
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("[action-bar&:action_bar_selected:]/general"):SetOrder(10), "action-bar/tabs")

  -- Lock
  local lockRecipe = CheckBoxRecipe()
  lockRecipe:SetWidth(150)
  lockRecipe:SetText("Lock")
  lockRecipe:SetOrder(90)
  lockRecipe:Get(function(recipe)
    return GetCurrentActionBar(recipe).locked
  end)
  lockRecipe:Set(function(recipe, value)
    GetCurrentActionBar(recipe).locked = value
  end)
  OptionBuilder:AddRecipe(lockRecipe, "action-bar/general")

  -- Show
  local showRecipe = ButtonRecipe()
  showRecipe:SetText("Show/Hide")
  showRecipe:SetOrder(91)
  showRecipe.OnClick = showRecipe.OnClick + function(recipe)
    GetCurrentActionBar(recipe):Toggle()
  end
  OptionBuilder:AddRecipe(showRecipe, "action-bar/general")


  OptionBuilder:AddRecipe(InlineGroupRecipe():SetText("Buttons"):SetBuildingGroup("action-bar/general/buttons"):SetOrder(300), "action-bar/general")
  -- Button Count
  local buttonCountRecipe = RangeRecipe()
  buttonCountRecipe:SetRange(1, 12)
  buttonCountRecipe:SetText("Buttons")
  buttonCountRecipe:SetOrder(300)
  buttonCountRecipe:Get(function(recipe)
    return GetCurrentActionBar(recipe).buttonCount
  end)
  buttonCountRecipe:Set(function(recipe, value)
    GetCurrentActionBar(recipe).buttonCount = value
  end)
  OptionBuilder:AddRecipe(buttonCountRecipe, "action-bar/general/buttons")

  -- Button Size
  local buttonSizeRecipe = RangeRecipe()
  buttonSizeRecipe:SetRange(14, 50)
  buttonSizeRecipe:SetText("Button Size")
  buttonSizeRecipe:SetOrder(301)
  buttonSizeRecipe:Get(function(recipe)
    return GetCurrentActionBar(recipe).buttonSize
  end)
  buttonSizeRecipe:Set(function(recipe, value)
    GetCurrentActionBar(recipe).buttonSize = value
  end)
  OptionBuilder:AddRecipe(buttonSizeRecipe, "action-bar/general/buttons")

  -- Direction Growth
  local directionGrowthRecipe = SelectRecipe()
  directionGrowthRecipe:SetText("Direction growth")
  directionGrowthRecipe:SetOrder(302)
  directionGrowthRecipe:SetList({
    ["LEFT"] = "Left",
    ["RIGHT"] = "Right",
    ["UP"] = "Up",
    ["DOWN"] = "Down"
  })
  directionGrowthRecipe:Get(function(recipe)
    return GetCurrentActionBar(recipe).directionGrowth
  end)
  directionGrowthRecipe:Set(function(recipe, value)
  GetCurrentActionBar(recipe).directionGrowth = value
end)
OptionBuilder:AddRecipe(directionGrowthRecipe, "action-bar/general/buttons")

-- Button Spacing
local buttonSpacingRecipe = RangeRecipe()
buttonSpacingRecipe:SetRange(0, 20)
buttonSpacingRecipe:SetText("Button Spacing")
buttonSpacingRecipe:SetOrder(303)
buttonSpacingRecipe:Get(function(recipe)
  return GetCurrentActionBar(recipe).buttonSpacing
end)
buttonSpacingRecipe:Set(function(recipe, value)
  GetCurrentActionBar(recipe).buttonSpacing = value
end)
OptionBuilder:AddRecipe(buttonSpacingRecipe, "action-bar/general/buttons")

end

function AddActionButtonsTabRecipes(self)
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Action Buttons"):SetID("action-buttons"):SetBuildingGroup("action-bar/action-buttons"):SetOrder(20), "action-bar/tabs")
  OptionBuilder:AddRecipe(RadioGroupRecipe()
  :AddChoice("category-mode", "Category Mode")
  :AddChoice("custom-mode", "Custom Mode")
  :SetBuildingGroup("action-bar/action-buttons/[mode&:action_bar_mode_selected:]")
  :SetSaveChoiceVariable("action_bar_mode_selected"), "action-bar/action-buttons")
  --OptionBuilder:AddRecipe(SimpleGroupRecipe():SetBuildingGroup("action-bar/action-buttons/select-mode"), "action-bar/action-buttons")
  --OptionBuilder:AddRecipe(CheckBoxRecipe():SetType("radio"):SetText("Category Mode"), "action-bar/action-buttons/select-mode")
  --OptionBuilder:AddRecipe(CheckBoxRecipe():SetType("radio"):SetText("Custom Mode"), "action-bar/action-buttons/select-mode")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Category Mode"), "action-bar/action-buttons/category-mode")
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Custom Mode"), "action-bar/action-buttons/custom-mode")
end


__SystemEvent__()
function EKT_BUTTON_CATEGORY_REGISTERED(category)
  local checkbox = CheckBoxRecipe()
  checkbox:SetID(category.id)
  checkbox:SetText(category.name)
  checkbox:Get(function(recipe)
    local actionBarID = RemoveSuffix(recipe.context("action_bar_selected"))
    return category.actionBar == actionBarID
  end)
  checkbox:Set(function(recipe, value)
    local actionBarID = RemoveSuffix(recipe.context("action_bar_selected"))
    if value then
      category.actionBar = actionBarID
    else
      category.actionBar = nil
    end
  end)

  --[[
  checkbox.OnValueChanged = checkbox.OnValueChanged + function(recipe, value)
    local actionBarID = RemoveSuffix(recipe.context("action_bar_selected"))
    category.actionBar = actionBarID
  end
  --]]
  OptionBuilder:AddRecipe(checkbox, "action-bar/action-buttons/category-mode")
end
