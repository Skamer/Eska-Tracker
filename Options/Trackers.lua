-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio            "EskaTracker.Options.Trackers"                             ""
--============================================================================--
import "EKT"
--============================================================================--
function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("trackers"):SetText("Trackers"):SetBuildingGroup("trackers/children"):SetOrder(10), "RootTree")
end


__SystemEvent__()
function EKT_TRACKERS_LOADED()
  for trackerID, tracker in Trackers:GetIterator() do
    local recipe = TreeItemRecipe()
    recipe:SetID(tracker.id)
    recipe:SetText(tracker.name)
    recipe:SetPath("trackers")
    recipe:SetBuildingGroup(string.format("[tracker&%s]/children", tracker.id))
    --recipe:SetBuildingGroup("[tracker&:tracker_selected:]/children")
    OptionBuilder:AddRecipe(recipe, "RootTree")

    -- Add the heading recipe
    local headingText = string.format("|cffff5000%s tracker Options|r", tracker.name)
    OptionBuilder:AddRecipe(HeadingRecipe():SetText(headingText):SetOrder(1), string.format("%s/children", tracker.id))

    -- Add the tracker property recipes
    OptionBuilder:AddRecipe(ThemePropertyRecipe()
    :SetElementID(string.format("tracker.%s.frame", tracker.id))
    :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
    :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH), string.format("%s/general/states", tracker.id))


    -- Scrollbar theme property
    OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("tracker.%s.scrollbar", tracker.id)):SetOrder(20), string.format("%s/scrollbar", tracker.id))
    OptionBuilder:AddRecipe(ThemePropertyRecipe()
    :SetElementID(string.format("tracker.%s.scrollbar.thumb", tracker.id))
    :SetElementParentID("tracker.scrollbar.thumb")
    :ClearFlags()
    :AddFlag(Theme.SkinFlags.TEXTURE_COLOR)
    :SetOrder(40), string.format("%s/scrollbar", tracker.id))

  end

  -- Create the tabs
  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("tracker/tabs"), "tracker/children")

  AddGeneralTabRecipes()
  AddScrollbarRecipes()

  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Blocks"):SetID("blocks"):SetBuildingGroup("[tracker&:tracker_selected:]/blocks"):SetOrder(20), "tracker/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Scrollbar"):SetID("scrollbar"):SetBuildingGroup("[tracker&:tracker_selected:]/scrollbar"):SetOrder(30), "tracker/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Advanced"):SetID("advanced"):SetBuildingGroup("[tracker&:tracker_selected:]/advanced"):SetOrder(40), "tracker/tabs")
end


function AddGeneralTabRecipes(self)
    OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("tracker/general"):SetOrder(10), "tracker/tabs")
  -- General tabs
  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetBuildingGroup("tracker/general/top-options"), "tracker/general")
  -- lock
  local lockRecipe = CheckBoxRecipe()
  lockRecipe:SetWidth(150)
  lockRecipe:SetText("Lock")
  lockRecipe:Get(function(recipe)
    return Trackers:Get(recipe.context("tracker_selected")).locked
  end)
  lockRecipe:Set(function(recipe, value)
    Trackers:Get(recipe.context("tracker_selected")).locked = value
  end)
  OptionBuilder:AddRecipe(lockRecipe, "tracker/general/top-options")
  -- Show
  local showRecipe = ButtonRecipe()
  showRecipe:SetText("Show/Hide")
  showRecipe.OnClick = showRecipe.OnClick + function(recipe)
    Trackers:Get(recipe.context("tracker_selected")):Toggle()
  end

  OptionBuilder:AddRecipe(showRecipe, "tracker/general/top-options")
  -- Size
  OptionBuilder:AddRecipe(InlineGroupRecipe():SetText("Size"):SetBuildingGroup("tracker/general/size"), "tracker/general")
    -- width
    local widthRecipe = RangeRecipe()
    widthRecipe:SetText("Width")
    widthRecipe:SetRange(175, 750)
    widthRecipe:Set(function(recipe, value)
      Trackers:Get(recipe.context("tracker_selected")).width = value
    end)
    widthRecipe:Get(function(recipe)
      return Trackers:Get(recipe.context("tracker_selected")).width
    end)
    OptionBuilder:AddRecipe(widthRecipe, "tracker/general/size")
    -- height
    local heightRecipe = RangeRecipe()
    heightRecipe:SetText("Height")
    heightRecipe:SetRange(175, 1024)
    heightRecipe:Set(function(recipe, value)
      Trackers:Get(recipe.context("tracker_selected")).height = value
    end)
    heightRecipe:Get(function(recipe)
      return Trackers:Get(recipe.context("tracker_selected")).height
    end)

    OptionBuilder:AddRecipe(heightRecipe, "tracker/general/size")

    OptionBuilder:AddRecipe(StateSelectRecipe():SetBuildingGroup("[tracker&:tracker_selected:]/general/states"), "tracker/general")
    OptionBuilder:AddRecipe(ThemePropertyRecipe()
    :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
    :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH)
    :AddFlag(Theme.SkinFlags.TEXT_SIZE)
    :AddFlag(Theme.SkinFlags.TEXT_COLOR)
    :AddFlag(Theme.SkinFlags.TEXT_FONT)
    :AddFlag(Theme.SkinFlags.TEXT_TRANSFORM)
    :AddFlag(Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL)
    :AddFlag(Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL)
    :AddFlag(Theme.SkinFlags.TEXTURE_COLOR),
    "tracker/general/states")
end

function AddBlocksTabRecipes(self)

end

function AddScrollbarRecipes(self)
  local showRecipe = CheckBoxRecipe()
  showRecipe:SetText("Show")
  showRecipe:SetOrder(10)
  showRecipe:Get(function(recipe)
    return Trackers:Get(recipe.context("tracker_selected")).showScrollbar
  end)
  showRecipe:Set(function(recipe, value)
    Trackers:Get(recipe.context("tracker_selected")).showScrollbar = value
  end)
  OptionBuilder:AddRecipe(showRecipe, "tracker/scrollbar")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Thumb"):SetOrder(30), "tracker/scrollbar")
  --OptionBuilder:AddRecipe(InlineGroupRecipe():SetBuildingGroup("[tracker&:tracker_selected:]/scrollbar/thumb"):SetText("Thumb"):SetOrder(30), "tracker/scrollbar")
end



function AddTrackersRecipes(self)
  --OptionBuilder:AddRecipe(TreeItemRecipe("Trackers", "Trackers/Children"):SetID("trackers"):SetOrder(10), "RootTree")

  -- Trackers:GetIterator()
  --OptionBuilder:AddRecipe(TreeItemRecipe("Main", "Trackers/Main/Children"):SetID("main"):SetPath("trackers"):SetOrder(10), "RootTree")
end




--OptionRecipe


-- Trackers - [Create a tracker] - [Delete a tracker]

--[[
  General
    Width, Height

  Blocks
    Choose some blocks you want display

  Display Rules
    Hide when no block is linked
    Hide when i'm in combat
    Hide when i'm in raid


  OptionBuilder:SetLink()


  local OptionRecipe

  OptionRecipe:Build(parent)

  SimpleFrameRecipe

  [Main]


  SetLink(url, variables)


  OptionRecipe

  id
  parent

  OptionBuilder:Rebuild()




  TreeItemRecipe


-]]
