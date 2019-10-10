--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska               "EskaTracker.Options.Trackers"                             ""
--============================================================================--
import                              "EKT"
--============================================================================--
function AddSuffix(id)
  return string.format("%s-tracker", id)
end

function RemoveSuffix(id)
  return id:gsub("(%-tracker)$", "")
end

function GetCurrentTracker(recipe)
  if recipe then
    return Trackers:Get(RemoveSuffix(recipe.context("tracker_selected")))
  else
    return Trackers:Get(RemoveSuffix(OptionBuilder:GetVariable("tracker_selected")))
  end
end

local function GetTrackerList()
  local list = {}
  for id, tracker in Trackers:GetIterator() do
    if tracker.id ~= "main" then
      list[id] = tracker.name
    end
  end
  return list
end

function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("trackers"):SetText("Trackers"):SetBuildingGroup("trackers/children"):SetOrder(10), "RootTree")

  -- Create an tracker
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(100):SetText("|cff00ff00Create a tracker|r"), "trackers/children")

  local lineEdit = LineEditRecipe()
  lineEdit:SetText("Enter the name of your new tracker")
  lineEdit:SetOrder(110)
  lineEdit.OnValueChanged = lineEdit.OnValueChanged + function(recipe, name)
    OptionBuilder:SetVariable("create_tracker_name", name)
  end
  OptionBuilder:AddRecipe(lineEdit, "trackers/children")

  local createButton = ButtonRecipe()
  createButton:SetText("Create")
  createButton:SetOrder(111)
  createButton.OnClick = createButton.OnClick + function(recipe)
    local name = OptionBuilder:GetVariable("create_tracker_name")
    if name then
      local id = Tracker:GetIDFromName(name)
      Trackers:New(id, true)
      -- Redirect the user to new
      local idWithSuffix = AddSuffix(id)
      OptionBuilder:SetVariable("tracker_selected", idWithSuffix)
      OptionBuilder:BuildUrl(idWithSuffix)
    end
  end
  OptionBuilder:AddRecipe(createButton, "trackers/children")

  -- Delete an tracker
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff0000Delete a tracker|r"):SetOrder(120), "trackers/children")

  local selectTrackerToDelete = SelectRecipe()
  selectTrackerToDelete:SetText("Select the tracker to delete")
  selectTrackerToDelete:SetOrder(121)
  selectTrackerToDelete:SetList(GetTrackerList)
  selectTrackerToDelete.OnValueChanged = selectTrackerToDelete.OnValueChanged + function(recipe, id)
    OptionBuilder:SetVariable("delete_tracker_id", id)
  end
  OptionBuilder:AddRecipe(selectTrackerToDelete, "trackers/children")

  local deleteButton = ButtonRecipe()
  deleteButton:SetText("Delete")
  deleteButton:SetOrder(122)
  deleteButton.OnClick = deleteButton.OnClick + function(recipe)
    local trackerID = OptionBuilder:GetVariable("delete_tracker_id")
    if trackerID then
      Trackers:Delete(trackerID)
    end
  end
  OptionBuilder:AddRecipe(deleteButton, "trackers/children")
end


function AddGeneralTabRecipes(self)
  -- Create the tab item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("tracker/general"):SetOrder(10), "tracker/tabs")

  -- Enable
  local enable = CheckBoxRecipe()
  enable:SetWidth(1.0)
  enable:SetText("Enable")
  enable:SetOrder(10)
  enable:Get(function(recipe)
    return GetCurrentTracker(recipe).enabled
  end)
  enable:Set(function(recipe, value)
    GetCurrentTracker(recipe).enabled = value
  end)
  OptionBuilder:AddRecipe(enable, "tracker/general")
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(11), "tracker/general")

  -- Top options group
  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetBuildingGroup("tracker/general/top-options"):SetOrder(20), "tracker/general")

  -- Lock
  local lockRecipe = CheckBoxRecipe()
  lockRecipe:SetWidth(150)
  lockRecipe:SetText("Lock")
  lockRecipe:Get(function(recipe)
    return GetCurrentTracker(recipe).locked
  end)
  lockRecipe:Set(function(recipe, value)
    GetCurrentTracker(recipe).locked = value
  end)
  OptionBuilder:AddRecipe(lockRecipe, "tracker/general/top-options")


  -- Size options group
  OptionBuilder:AddRecipe(InlineGroupRecipe():SetText("Size"):SetBuildingGroup("tracker/general/size"), "tracker/general")

  -- Width
  local widthRecipe = RangeRecipe()
  widthRecipe:SetText("Width")
  widthRecipe:SetRange(175, 750)
  widthRecipe:Get(function(recipe)
    return GetCurrentTracker(recipe).width
  end)
  widthRecipe:Set(function(recipe, value)
    GetCurrentTracker(recipe).width = value
  end)
  OptionBuilder:AddRecipe(widthRecipe, "tracker/general/size")

  -- height
  local heightRecipe = RangeRecipe()
  heightRecipe:SetText("Height")
  heightRecipe:SetRange(175, 1024)
  heightRecipe:Get(function(recipe)
    return GetCurrentTracker(recipe).height
  end)
  heightRecipe:Set(function(recipe, value)
    GetCurrentTracker(recipe).height = value
  end)
  OptionBuilder:AddRecipe(heightRecipe, "tracker/general/size")

  OptionBuilder:AddRecipe(StateSelectRecipe()
  :SetBuildingGroup("[tracker&:tracker_selected:]/general/states")
  :AddState("idle"), "tracker/general")
end

function AddBlocksTabRecipes(self)
  -- Create tab item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Blocks"):SetID("blocks"):SetBuildingGroup("[tracker&:tracker_selected:]/blocks"):SetOrder(20), "tracker/tabs")


  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetLayout("List"):SetBuildingGroup("tracker/blocks/categories"), "tracker/blocks")
  for categoryID, category in Blocks:IterateCategories() do
    OptionBuilder:AddRecipe(BlockCategoryRowRecipe():SetID(categoryID):SetText(category.name), "tracker/blocks/categories")
  end
end

function AddScrollbarTabRecipes(self)
  -- Create tab item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Scrollbar"):SetID("scrollbar"):SetBuildingGroup("[tracker&:tracker_selected:]/scrollbar"):SetOrder(30), "tracker/tabs")

  -- Show Scroll bar
  local showRecipe = CheckBoxRecipe()
  showRecipe:SetText("Show")
  showRecipe:SetOrder(10)
  showRecipe:Get(function(recipe)
    return GetCurrentTracker(recipe).showScrollbar
  end)
  showRecipe:Set(function(recipe, value)
    GetCurrentTracker(recipe).showScrollbar = value
  end)
  OptionBuilder:AddRecipe(showRecipe, "tracker/scrollbar")

  -- Scroll Step 
  local scrollStepRecipe = RangeRecipe()
  scrollStepRecipe:SetText("Scroll step")
  scrollStepRecipe:SetOrder(20)
  scrollStepRecipe:SetRange(1, 750)
  scrollStepRecipe:Get(function(recipe)
    return GetCurrentTracker(recipe).scrollStep
  end)
  scrollStepRecipe:Set(function(recipe, value)
    GetCurrentTracker(recipe).scrollStep = value
  end)
  OptionBuilder:AddRecipe(scrollStepRecipe, "tracker/scrollbar")

  -- Thumb Heading
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Thumb"):SetOrder(30), "tracker/scrollbar")

end

function AddAdvancedTabRecipes(self)
  -- Create advanced item
  --OptionBuilder:AddRecipe(TabItemRecipe():SetText("Advanced"):SetID("advanced"):SetBuildingGroup("[tracker&:tracker_selected:]/advanced"):SetOrder(40), "tracker/tabs")
end

function AddDisplyingRulesRecipes(self)
  -- Create displaying item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Display Rules"):SetID("display-rules"):SetBuildingGroup("[tracker&:tracker_selected:]/display-rules"):SetOrder(40), "tracker/tabs")

  local defaultState = SelectRecipe()
  defaultState:SetText("By default, the tracker is:")
  defaultState:SetOrder(10)
  defaultState:Get(function(recipe) return GetCurrentTracker(recipe).defaultDisplayState end)
  defaultState:Set(function(recipe, value) GetCurrentTracker(recipe).defaultDisplayState = value end)
  defaultState:SetList({
    ["show"] = "|cff00ff00Displayed|r",
    ["hide"] = "|cffff0000Hidden|r",
   })
   OptionBuilder:AddRecipe(defaultState, "tracker/display-rules")
   OptionBuilder:AddRecipe(HeadingRecipe(), "tracker/display-rules")


  local displayRulesType = RadioGroupRecipe()
  displayRulesType:SetOrder(101)
  displayRulesType:AddChoice("predefined-type", "Predefined")
  displayRulesType:AddChoice("macro-type", "Macro conditionals")
  displayRulesType:AddChoice("function-type", "Status function")
  displayRulesType:Get(function(recipe) return GetCurrentTracker(recipe).displayRulesType end)
  displayRulesType:Set(function(recipe, value) GetCurrentTracker(recipe).displayRulesType = value end)
  displayRulesType:SetBuildingGroup("tracker/display-rules/[type&:tracker_display_rules_type:]")
  displayRulesType:SetSaveChoiceVariable("tracker_display_rules_type")
  displayRulesType:SetAddSeparator(true)
  OptionBuilder:AddRecipe(displayRulesType, "tracker/display-rules")


   local addNewRuleButton = ButtonRecipe()
   addNewRuleButton:SetText("Add a new rule")
   addNewRuleButton:SetOrder(20)
   addNewRuleButton.OnClick = addNewRuleButton.OnClick + function(recipe)
     GetCurrentTracker(recipe):AddDisplayRule(DisplayRule())
   end


   local displayRulesRecipe = DisplayRulesRecipe()
   displayRulesRecipe:SetOrder(40)
   --displayRulesRecipe:RefreshOnEvent("EKT_TRACKER_DISPLAY_RULE_ADDED")
   --displayRulesRecipe:RefreshOnEvent("EKT_TRACKER_DISPLAY_RULE_REMOVED")
   --displayRulesRecipe:RefreshOnEvent("EKT_TRACKER_DISPLAY_RULE_ORDER_CHANGED")

  OptionBuilder:AddRecipe(addNewRuleButton, "tracker/display-rules/predefined-type")
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(30), "tracker/display-rules/predefined-type")
  OptionBuilder:AddRecipe(displayRulesRecipe, "tracker/display-rules/predefined-type")

  -- conditionals Macro
  local macro = TextEditRecipe()
  macro:SetOrder(101)
  macro:SetWidth(1.0)
  macro:SetNumLines(1)
  macro:DisableButton(false)
  macro:Get(function(recipe) return GetCurrentTracker(recipe).displayMacro end)
  macro.OnValueConfirmed = function(recipe, macro) GetCurrentTracker(recipe).displayMacro = macro end
  OptionBuilder:AddRecipe(macro, "tracker/display-rules/macro-type")

  -- status function
  local statusFunction = TextEditRecipe()
  statusFunction:SetOrder(101)
  statusFunction:SetWidth(1.0)
  statusFunction:SetNumLines(20)
  statusFunction:DisableButton(false)
  statusFunction:SetLUASyntaxHighlighting(true)
  statusFunction:Get(function(recipe) return GetCurrentTracker(recipe).displayFunction end)
  statusFunction.OnValueConfirmed = function(recipe, funcStr) GetCurrentTracker(recipe).displayFunction = funcStr end
  OptionBuilder:AddRecipe(statusFunction, "tracker/display-rules/function-type")

end

function AddIdleModeRecipes(self)
  -- Create idle mode item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Idle Mode"):SetID("idle-mode"):SetBuildingGroup("[tracker&:tracker_selected:]/idle-mode"):SetOrder(50), "tracker/tabs")

  --OptionBuilder:AddRecipe(HeadingRecipe():SetText("Idle Mode Activation"):SetOrder(101), "tracker/idle-mode")
  local enable = CheckBoxRecipe()
  enable:SetText("Enable")
  enable:SetOrder(101)
  enable:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModeEnabled
  end)
  enable:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModeEnabled = value
  end)
  OptionBuilder:AddRecipe(enable, "tracker/idle-mode")



  local inactivityTimer = RangeRecipe()
  inactivityTimer:SetText("Enter in idle mode after x second(s) inactivity")
  inactivityTimer:SetOrder(102)
  inactivityTimer:SetWidth(0.75)
  inactivityTimer:SetRange(0, 900)
  inactivityTimer:Get(function(recipe)
    return GetCurrentTracker(recipe).inactivityTimer
  end)
  inactivityTimer:Set(function(recipe, value)
    GetCurrentTracker(recipe).inactivityTimer = value
  end)
  OptionBuilder:AddRecipe(inactivityTimer, "tracker/idle-mode")

  local inactivityAlphaText = TextRecipe()
  inactivityAlphaText:SetText("|cffffd8000: Transparent (invisible)\n1: Fully opaque\n|r")
  inactivityAlphaText:SetOrder(201)
  OptionBuilder:AddRecipe(inactivityAlphaText, "tracker/idle-mode")

  local alpha = RangeRecipe()
  alpha:SetText("Inactivity alpha")
  alpha:SetOrder(202)
  alpha:SetRange(0, 1)
  alpha:SetStep(0.05)
  alpha:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModeAlpha
  end)
  alpha:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModeAlpha = value
  end)
  OptionBuilder:AddRecipe(alpha, "tracker/idle-mode")
end

--- Register the recipes related to tracker registered
__SystemEvent__()
function EKT_TRACKER_REGISTERED(tracker)
  local idWithSuffix = AddSuffix(tracker.id)
  local commonGroup  = string.format("[tracker&%s]/children", idWithSuffix)
  local privateGroup = string.format("%s/children", idWithSuffix)

  --- Add specific recipes
  -- Create the heading text
  local headingText = string.format("|cffff5000%s Tracker Options|r", tracker.name)
  OptionBuilder:AddRecipe(HeadingRecipe():SetText(headingText):SetOrder(10), privateGroup)
  -- Create the Tree item
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID(idWithSuffix):SetText(tracker.name):SetPath("trackers"):SetBuildingGroup(commonGroup), "RootTree")

  --- Theme properties
  -- Frame properties
  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("tracker.%s.frame", tracker.id))
  :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
  :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH), string.format("%s/general/states", idWithSuffix))

  -- Scrollbar properties
  OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("tracker.%s.scrollbar", tracker.id)):SetOrder(20), string.format("%s/scrollbar", idWithSuffix))

  -- Scrollbar thumb properies
  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("tracker.%s.scrollbar.thumb", tracker.id))
  :SetElementParentID("tracker.scrollbar.thumb")
  :ClearFlags()
  :AddFlag(Theme.SkinFlags.TEXTURE_COLOR)
  :SetOrder(40), string.format("%s/scrollbar", idWithSuffix))

end

--- Remove the recipes related to tracker which has been deleted
__SystemEvent__()
function EKT_TRACKER_DELETED(tracker)
  local idWithSuffix = AddSuffix(tracker.id)

  OptionBuilder:RemoveRecipe(idWithSuffix, "RootTree")
  OptionBuilder:RemoveRecipes(string.format("%s/children", idWithSuffix))

  -- Redirect the user when it's done
  OptionBuilder:BuildUrl("trackers")
end


-- Register the generic recipes
__SystemEvent__()
function EKT_TRACKERS_LOADED()
  -- Create the tabs
  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("tracker/tabs"), "tracker/children")

  AddGeneralTabRecipes()
  AddBlocksTabRecipes()
  AddScrollbarTabRecipes()
  AddAdvancedTabRecipes()
  AddDisplyingRulesRecipes()
  AddIdleModeRecipes()

end
