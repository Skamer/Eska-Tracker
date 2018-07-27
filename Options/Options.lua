--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                    "EskaTracker.Options"                              ""
-- ========================================================================== --
import "EKT"
-- ========================================================================== --
_AceGUI               = LibStub("AceGUI-3.0")
--============================================================================--
_Fonts                = _LibSharedMedia:HashTable("font")
_Backgrounds          = _LibSharedMedia:HashTable("background")
--============================================================================--
_OPTIONS_FRAME_WIDTH  = 1024
_OPTIONS_FRAME_HEIGHT = 600
--============================================================================--
_ROOT_FRAME           = nil
--============================================================================--
_CATEGORIES_BUILDER = Dictionary()
_CATEGORIES_INFO    = {}




function OnLoad(self)
  _ROOT_TREE = {
    {
      value    = "EKT",
      text     = "EskaTracker",
      icon     = _EKT_ICON,
      children = {}
    }
  }

  -- Set some variables for OptionBuilder
  OptionBuilder:SetVariable("state_selected", "none")

  OptionBuilder:SetVariable("trackers_id", "trackers")
  OptionBuilder:SetVariable("trackers_group", "RootTree")
  OptionBuilder:SetVariable("tracker_id_format", "%s-tracker")


  self:FireSystemEvent("EKT_OPTIONS_LOADED")

  --local treeRecipe = TreeRecipe()
  --print("Recipe", treeRecipe)
  -- OptionBuilder:GetVariable("tracker_selected")
  local function OnRootTreeCategorySelected(recipe, id)
    if id and id:find("%-tracker$") then
      OptionBuilder:SetVariable("tracker_selected", id)
    elseif id and id:find("%-block%-category$") then
      OptionBuilder:SetVariable("block_category_selected", id)
    elseif id and id:find("%-action%-bar$") then
      OptionBuilder:SetVariable("action_bar_selected", id)
    else
      OptionBuilder:SetVariable("tracker_selected", nil)
      OptionBuilder:SetVariable("block_category_selected", nil)
      OptionBuilder:SetVariable("action_bar_selected", nil)
    end
  end

  -- Create the root tree
  local rootTree = TreeRecipe()
  rootTree:SetText("EskaTracker")
  rootTree:SetBuildingGroup("RootTree")
  rootTree:SetIcon(_EKT_ICON)
  rootTree:SetDefaultBuldingGroup("RootTree/Default")
  rootTree:SetID("EKT")
  rootTree.OnItemSelected = rootTree.OnItemSelected + OnRootTreeCategorySelected
  OptionBuilder:AddRecipe(rootTree, "Root")

  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("RootTree/Default/Tabs"), "RootTree/Default")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Addon Info"):SetID("addon-info"):SetBuildingGroup("AddonInfo"), "RootTree/Default/Tabs")


  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("context-menu"):SetText("Context Menu"):SetOrder(300), "RootTree")


  OptionBuilder:AddRecipe(AddonInfoRecipe(), "AddonInfo")
  self:AddNotificationRecipes()
end

__SystemEvent__()
function EKT_BLOCK_CATEGORY_REGISTERED(blockCategory)
  OptionBuilder:AddRecipe(BlockCategoryRowRecipe():SetID(blockCategory.id):SetText(blockCategory.name), "tracker/blocks/categories")
end


__SlashCmd__ "ekt" "config" "- open the options"
__SlashCmd__ "ekt" "open" "- open the options"
__SlashCmd__ "ekt" "option" "- open the options"
__SystemEvent__ "EKT_OPEN_OPTIONS"
function Open()
  if not _ROOT_FRAME then
    _M:CreateFrame()

    for index, recipe in OptionBuilder:GetRecipes("Root"):GetIterator() do
      recipe:Build(OptionContext(_ROOT_FRAME))
    end
  end

  _ROOT_FRAME:Show()
end

function CreateFrame(self)
  _ROOT_FRAME = _AceGUI:Create("Frame")
  _ROOT_FRAME:SetWidth(_OPTIONS_FRAME_WIDTH)
  _ROOT_FRAME:SetHeight(_OPTIONS_FRAME_HEIGHT)
  _ROOT_FRAME:SetTitle("EskaTracker - Options")
  _ROOT_FRAME:SetLayout("Fill")
end




function BuildUrl(self, context)
  if not _ROOT_FRAME then
    self:CreateFrame()
  else
    _ROOT_FRAME:ReleaseChildren()
  end

  context.parentWidget = _ROOT_FRAME

  for index, recipe in OptionBuilder:GetRecipes("Root"):GetIterator() do
    recipe:Build(context)
  end

  _ROOT_FRAME:Show()
end


function RegisterTrackerRecipe(self)
end




function AddNotificationRecipes(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("notifications"):SetText("Notifications"):SetBuildingGroup("notifications/children"):SetOrder(400), "RootTree")

  local linkNotificationToTrackerRecipe = CheckBoxRecipe()
  linkNotificationToTrackerRecipe:BindSetting("link-notifications-to-a-tracker")
  linkNotificationToTrackerRecipe:SetText("Link notifications to a tracker")
  linkNotificationToTrackerRecipe:SetWidth(1.0)
  linkNotificationToTrackerRecipe:SetOrder(10)
  OptionBuilder:AddRecipe(linkNotificationToTrackerRecipe, "notifications/children")

  local function GetTrackerList()
    local trackerList = {}
    for _, tracker in Trackers:GetIterator() do
      trackerList[tracker.id] = tracker.name
    end

    return trackerList
  end

  local selectTracker = SelectRecipe()
  selectTracker:SetText("Select a tracker to link")
  selectTracker:SetList(GetTrackerList)
  selectTracker:BindSetting("tracker-used-for-notifications")
  --[[selectTracker:Get(function()
    local tracker
    for _, tracker in Trackers:GetIterator() do
      if tracker.displayNotifications then
        return tracker.id
      end
    end
   end)
  selectTracker:Set(function(_, value)
    print("Set Tracker", value)
    Trackers:Get(value).displayNotifications = true
  end)--]]
  selectTracker:SetOrder(20)
  OptionBuilder:AddRecipe(selectTracker, "notifications/children")
end
