--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio            "EskaTracker.Options.Trackers"                             ""
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
  return Trackers:Get(RemoveSuffix(recipe.context("tracker_selected")))
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

  -- Top options group
  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetBuildingGroup("tracker/general/top-options"), "tracker/general")

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

  -- Show
  local showRecipe = ButtonRecipe()
  showRecipe:SetText("Show/Hide")
  showRecipe.OnClick = showRecipe.OnClick + function(recipe)
    GetCurrentTracker(recipe):Toggle()
  end
  OptionBuilder:AddRecipe(showRecipe, "tracker/general/top-options")


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

  -- Thumb Heading
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Thumb"):SetOrder(30), "tracker/scrollbar")

end

function AddAdvancedTabRecipes(self)
  -- Create advanced item
  --OptionBuilder:AddRecipe(TabItemRecipe():SetText("Advanced"):SetID("advanced"):SetBuildingGroup("[tracker&:tracker_selected:]/advanced"):SetOrder(40), "tracker/tabs")
end

function AddDisplyingRulesRecipes(self)
  -- Create displaying item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Displaying Rules"):SetID("displaying-rules"):SetBuildingGroup("[tracker&:tracker_selected:]/displaying-rules"):SetOrder(40), "tracker/tabs")
end

function AddIdleModeRecipes(self)
  -- Create idle mode item
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Idle Mode"):SetID("idle-mode"):SetBuildingGroup("[tracker&:tracker_selected:]/idle-mode"):SetOrder(50), "tracker/tabs")

  --OptionBuilder:AddRecipe(HeadingRecipe():SetText("Idle Mode Activation"):SetOrder(101), "tracker/idle-mode")
  OptionBuilder:AddRecipe(TextRecipe()
  :SetWidth(1.0)
  :SetText("NOTE: Setting '0' value will disable the idle mode."), "tracker/idle-mode")


  local enable = RangeRecipe()
  enable:SetText("Enable after x second(s) inactivity")
  enable:SetOrder(102)
  enable:SetWidth(0.75)
  enable:SetRange(0, 1800)
  enable:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModeTimer
  end)
  enable:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModeTimer = value
  end)
  OptionBuilder:AddRecipe(enable, "tracker/idle-mode")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Idle Mode Behaviors"):SetOrder(201), "tracker/idle-mode")
  local alpha = RangeRecipe()
  alpha:SetText("Set the tracker alpha")
  alpha:SetOrder(202)
  alpha:SetRange(0, 1)
  alpha:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModeAlpha
  end)
  alpha:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModeAlpha = value
  end)
  OptionBuilder:AddRecipe(alpha, "tracker/idle-mode")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Other Options"):SetOrder(301), "tracker/idle-mode")

  local preventMouseover = CheckBoxRecipe()
  preventMouseover:SetText("Prevent the mouseover to leave the idle mode")
  preventMouseover:SetOrder(302)
  preventMouseover:SetWidth(1.0)
  preventMouseover:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModePreventMouseover
  end)
  preventMouseover:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModePreventMouseover = value
  end)
  OptionBuilder:AddRecipe(preventMouseover, "tracker/idle-mode")

  local resumeAfterMouveover = CheckBoxRecipe()
  resumeAfterMouveover:SetText("Resume the idle mode after mouseover if no activity has occured")
  resumeAfterMouveover:SetOrder(303)
  resumeAfterMouveover:SetWidth(1.0)
  resumeAfterMouveover:Get(function(recipe)
    return GetCurrentTracker(recipe).idleModeResumeAfterMouseover
  end)
  resumeAfterMouveover:Set(function(recipe, value)
    GetCurrentTracker(recipe).idleModeResumeAfterMouseover = value
  end)
  OptionBuilder:AddRecipe(resumeAfterMouveover, "tracker/idle-mode")

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
