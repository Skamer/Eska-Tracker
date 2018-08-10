--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                  "EskaTracker.Options.Themes"                            ""
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

  local function GetDeletedThemeList()
    local themeList = {}
    for _, theme in Themes:GetIterator() do
      if not theme.lua then
        themeList[theme.name] = theme.name
      end
    end
    return themeList
  end

  local selectThemeRecipe = SelectRecipe()
  selectThemeRecipe:SetText("Select a theme")
  selectThemeRecipe:SetList(GetThemeList)
  selectThemeRecipe:Get(function() return Themes:GetSelected().name end)
  selectThemeRecipe:Set(function(recipe, value) Themes:Select(value) ; recipe:FireRecipeEvent("SELECT_THEME_CHANGED", value) end)
  selectThemeRecipe:RefreshOnEvent("EKT_THEME_REGISTERED")
  selectThemeRecipe:RefreshOnEvent("EKT_THEME_DELETED")
  selectThemeRecipe:SetOrder(10)

    --OptionBuilder:AddRecipe(SelectRecipe():SetText("Select a theme"):SetList(GetThemeList):SetOrder(10):BindSetting("theme-selected"), "themes/general")
    OptionBuilder:AddRecipe(selectThemeRecipe, "themes/general")
    OptionBuilder:AddRecipe(HeadingRecipe():SetText("Theme Information"):SetOrder(20), "themes/general")
    OptionBuilder:AddRecipe(ThemeInformationRecipe():SetOrder(30), "themes/general")
    OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cff00ff00Create a Theme|r"):SetOrder(40), "themes/general")
    OptionBuilder:AddRecipe(CreateThemeRecipe():SetOrder(50), "themes/general")
    OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff0000Delete a Theme|r"):SetOrder(60), "themes/general")

    local deleteTextInfo = "|cff00ffffInfo:|r |cffffd800Only Themes that have been created from options or imported can be deleted.|r"
    OptionBuilder:AddRecipe(TextRecipe():SetText(deleteTextInfo):SetOrder(70), "themes/general")

    local selectThemeToDelete = SelectRecipe()
    selectThemeToDelete:SetText("Delete a Theme")
    selectThemeToDelete:SetOrder(80)
    selectThemeToDelete:SetList(GetDeletedThemeList)
    selectThemeToDelete:RefreshOnEvent("EKT_THEME_REGISTERED")
    selectThemeToDelete:RefreshOnEvent("EKT_THEME_DELETED")
    selectThemeToDelete.OnValueChanged = function(_, value) OptionBuilder:SetVariable("delete-theme-name", value) end
    OptionBuilder:AddRecipe(selectThemeToDelete, "themes/general")

    local deleteButton = ButtonRecipe()
    deleteButton:SetText("Delete")
    deleteButton:SetOrder(90)
    deleteButton.OnClick = function()
      local themeName = OptionBuilder:GetVariable("delete-theme-name")
      if themeName then
        Themes:Delete(themeName)
      end
    end
    OptionBuilder:AddRecipe(deleteButton, "themes/general")


  -- Import theme
  OptionBuilder:AddRecipe(ImportThemeRecipe(), "themes/import")

  -- Export theme
  OptionBuilder:AddRecipe(ExportThemeRecipe(), "themes/export")
end
