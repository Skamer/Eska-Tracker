--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio               "EskaTracker.Options.Themes"                            ""
-- ========================================================================== --
import                           "EKT"
-- ========================================================================== --
function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("themes"):SetText("Themes"):SetBuildingGroup("themes/children"):SetOrder(500), "RootTree")
end



__SystemEvent__()
function EKT_THEMES_LOADED()
  OptionBuilder:SetVariable("theme_selected", Themes:GetSelected().name)
  -- Create the tab group
  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("themes/tabs"), "themes/children")
  -- Create the tab categories
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("themes/general"), "themes/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Import"):SetID("import"):SetBuildingGroup("themes/import"), "themes/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Export"):SetID("export"):SetBuildingGroup("themes/export"), "themes/tabs")

  -- General
  local function GetThemeList()
    local themeList = {}
    for _, theme in Themes:GetIterator() do
      themeList[theme.name] = theme.name
    end
    return themeList
  end

  local selectThemeRecipe = SelectRecipe()
  selectThemeRecipe:SetText("Select a theme")
  selectThemeRecipe:SetList(GetThemeList)
  selectThemeRecipe:Get(function() return Themes:GetSelected().name end)
  selectThemeRecipe:Set(function(recipe, value) Themes:Select(value) ; recipe:FireRecipeEvent("SELECT_THEME_CHANGED", value) end)
  selectThemeRecipe:SetOrder(10)

    --OptionBuilder:AddRecipe(SelectRecipe():SetText("Select a theme"):SetList(GetThemeList):SetOrder(10):BindOption("theme-selected"), "themes/general")
    OptionBuilder:AddRecipe(selectThemeRecipe, "themes/general")
    OptionBuilder:AddRecipe(HeadingRecipe():SetText("Theme Information"):SetOrder(20), "themes/general")
    OptionBuilder:AddRecipe(ThemeInformationRecipe():SetOrder(30), "themes/general")
    OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cff00ff00Create a Theme|r"):SetOrder(40), "themes/general")


  -- Import theme
  OptionBuilder:AddRecipe(ImportThemeRecipe(), "themes/import")
end
