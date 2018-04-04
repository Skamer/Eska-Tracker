-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio                    "EskaTracker.Options"                              ""
-- ========================================================================== --
import "EKT"
-- ========================================================================== --
_AceGUI               = LibStub("AceGUI-3.0")
--============================================================================--
_Fonts                = _LibSharedMedia:List("font")
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
  OptionBuilder:SetVariable("theme_selected", Themes:GetSelected().name)

  OptionBuilder:SetVariable("trackers_id", "trackers")
  OptionBuilder:SetVariable("trackers_group", "RootTree")
  OptionBuilder:SetVariable("tracker_id_format", "tracker_%s")


  self:FireSystemEvent("EKT_OPTIONS_LOADED")

  --local treeRecipe = TreeRecipe()
  --print("Recipe", treeRecipe)
  -- OptionBuilder:GetVariable("tracker_selected")
  local function OnRootTreeCategorySelected(recipe, id)
    if id and id:find("-tracker$") then
      OptionBuilder:SetVariable("tracker_selected", id)
    else
      OptionBuilder:SetVariable("tracker_selected", nil)
    end
  end

  OptionBuilder:AddRecipe(TreeRecipe():SetText("EskaTracker"):SetBuildingGroup("RootTree"):SetIcon(_EKT_ICON):SetDefaultBuldingGroup("RootTree/Default"):SetID("EKT"):OnSelected(OnRootTreeCategorySelected), "Root")
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("trackers"):SetText("Trackers"):SetBuildingGroup("Trackers/Children"), "RootTree")
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("main-tracker"):SetText("Main"):SetPath("trackers"):SetBuildingGroup("[tracker&:tracker_selected:]/children"), "RootTree")
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("quest-tracker"):SetText("Quest Tracker"):SetPath("trackers"):SetBuildingGroup("[tracker&:tracker_selected:]/children"), "RootTree")



  -- Create tracker category
  --OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffffff00Tracker Options|r"):SetOrder(1), "tracker/children")
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff5000Main Tracker Options|r"):SetOrder(2), "main-tracker/children")
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff5000Quest Tracker  Options|r"):SetOrder(2), "quest-tracker/children")
  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("tracker/tabs"), "tracker/children")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("tracker/general"), "tracker/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Blocks"):SetID("blocks"):SetBuildingGroup("tracker/blocks"), "tracker/tabs")

  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetBuildingGroup("tracker/general/top-options"), "tracker/general")
  OptionBuilder:AddRecipe(CheckBoxRecipe():SetWidth(150):SetText("Lock"):Get(function() return true end):Set(function(...) print("SET", ...) end), "tracker/general/top-options")
  OptionBuilder:AddRecipe(ButtonRecipe():SetText("Show/Hide"), "tracker/general/top-options")

  OptionBuilder:AddRecipe(InlineGroupRecipe():SetText("Size"):SetBuildingGroup("tracker/general/size"), "tracker/general")
  OptionBuilder:AddRecipe(RangeRecipe():SetText("Width"), "tracker/general/size")
  OptionBuilder:AddRecipe(RangeRecipe():SetText("Height"), "tracker/general/size")


  OptionBuilder:AddRecipe(SimpleGroupRecipe():SetLayout("List"):SetBuildingGroup("tracker/blocks/categories"), "tracker/blocks")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetIcon("Interface\\Icons\\INV_Misc_Coin_01"):SetText("|cff0094FFEska|r Gold"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r Quests"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r World Quests"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r Achievements"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r Scenario"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r Dungeon"), "tracker/blocks/categories")
  OptionBuilder:AddRecipe(BlockTrackerRecipe():SetText("|cff0094FFEska|r Keystone"), "tracker/blocks/categories")



  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("RootTree/Default/Tabs"), "RootTree/Default")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Addon Info"):SetID("addon-info"):SetBuildingGroup("AddonInfo"), "RootTree/Default/Tabs")

    OptionBuilder:AddRecipe(TreeItemRecipe():SetID("blocks"):SetText("Blocks"), "RootTree")

  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("item-bar"):SetText("Item Bar"), "RootTree")

  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("context-menu"):SetText("Context Menu"), "RootTree")

  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("themes"):SetText("Themes"), "RootTree")

  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("profils"):SetText("Profils"):SetBuildingGroup("[Profils&ErrorProfil]/Children"), "RootTree")


  OptionBuilder:AddRecipe(AddonInfoRecipe(), "AddonInfo")
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(100):SetText("|cff00ff00Create a tracker|r"), "Trackers/Children")
  OptionBuilder:AddRecipe(CreateTrackerRecipe():SetOrder(200), "Trackers/Children")
  OptionBuilder:AddRecipe(HeadingRecipe():SetOrder(300):SetText("|cffff0000Delete a tracker|r"), "Trackers/Children")
  OptionBuilder:AddRecipe(DeleteTrackerRecipe():SetOrder(400), "Trackers/Children")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Test Recipe"), "Profils/Children")
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff0000And this text Recipe|r"):SetOrder(1), "ErrorProfil/Children")

  -- [tracker&:tracker_selected:]/children


  -- SetBuildingGroup("")

  --OptionBuilder:BuildUrl("main-tracker")
  --OptionBuilder:AddRecipe(HeadingRecipe():SetText("AddonInfo Headling 2"), "AddonInfo")
end

__SlashCmd__ "ekt" "config" "- open the options"
__SlashCmd__ "ekt" "open" "- open the options"
__SlashCmd__ "ekt" "option" "- open the options"
__SystemEvent__ "EKT_OPEN_OPTIONS"
function Open()
  if not _ROOT_FRAME then
    _M:CreateFrame()

    --local treeRecipe = TreeRecipe()
    --treeRecipe:Build(OptionContext(_ROOT_FRAME))

    for index, recipe in OptionBuilder:GetRecipes("Root"):GetIterator() do
      recipe:Build(OptionContext(_ROOT_FRAME))
    end

    --[[_ROOT_TREE_FRAME = _AceGUI:Create("TreeGroup")

    --_ROOT_TREE_FRAME:SetTree(_ROOT_TREE)
    --_ROOT_TREE_FRAME:SelectByValue("EKT")
    --_ROOT_TREE_FRAME:SetLayout("Flow")
    --_ROOT_FRAME:AddChild(_ROOT_TREE_FRAME)
    local treeRecipe = TreeRecipe()
    treeRecipe:Build(OptionContext(_ROOT_FRAME))

    local scrollContainer = _AceGUI:Create("SimpleGroup")
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetFullHeight(true)
    scrollContainer:SetLayout("Fill")

    _ROOT_TREE_FRAME:AddChild(scrollContainer)

    _CONTENT = _AceGUI:Create("ScrollFrame")
    _CONTENT:SetLayout("List")
    _CONTENT:SetFullWidth(true)
    scrollContainer:AddChild(_CONTENT) --]]

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
    print("BuildUrl", index, recipe)
    recipe:Build(context)
  end

  _ROOT_FRAME:Show()
end


function RegisterTrackerRecipe(self)


end
