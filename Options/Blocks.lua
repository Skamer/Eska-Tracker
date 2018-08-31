--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                "EskaTracker.Options.Blocks"                              ""
--============================================================================--
import                       "EKT"
--============================================================================--
local function GetCategoryID(str)
  return string.gsub(str, "%-block%-category$", "")
end


function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("blocks"):SetText("Blocks"):SetBuildingGroup("blocks/children"), "RootTree")

  for categoryID, category in Blocks:IterateCategories() do
    self:AddCategoryRecipes(category, true)
  end

  OptionBuilder:AddRecipe(TabRecipe():SetBuildingGroup("[block&:block_category_selected:]/tabs"), "block/children")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("General"):SetID("general"):SetBuildingGroup("[block&:block_category_selected:]/general"), "block/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Header"):SetID("header"):SetBuildingGroup("[block&:block_category_selected:]/header"), "block/tabs")
  OptionBuilder:AddRecipe(TabItemRecipe():SetText("Content"):SetID("content"):SetBuildingGroup("[block&:block_category_selected:]/content"), "block/tabs")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Stripe"):SetOrder(300), "block/header")

  local order = RangeRecipe()
  order:SetOrder(10)
  order:SetRange(0, 500)
  order:SetText("Order")
  order:Get(function(recipe)
    return Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).order
  end)
  order:Set(function(recipe, value)
    Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).order = value
  end)
  OptionBuilder:AddRecipe(order, "block/general")

  local showHeader = CheckBoxRecipe()
  showHeader:SetOrder(10)
  showHeader:SetText("Show")
  showHeader:Get(function(recipe)
    return Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).showHeader
  end)
  showHeader:Set(function(recipe, value)
    Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).showHeader = value
  end)
  OptionBuilder:AddRecipe(showHeader, "block/header")

  local headerHeight = RangeRecipe()
  headerHeight:SetOrder(20)
  headerHeight:SetText("Height")
  headerHeight:SetRange(1, 64)
  headerHeight:Get(function(recipe)
    return Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).headerHeight
  end)
  headerHeight:Set(function(recipe, value)
    Blocks:GetCategory(GetCategoryID(recipe.context("block_category_selected"))).headerHeight = value
  end)
  OptionBuilder:AddRecipe(headerHeight, "block/header")
end


__SystemEvent__()
function EKT_BLOCK_CATEGORY_REGISTERED(category)
  _M:AddCategoryRecipes(category)
end

-- EKT.OptionBuilder:GetRecipes("quests-block-category", "RootTree")
function AddCategoryRecipes(self, category, needCheck)
  local id = string.format("%s-block-category", category.id)
  if needCheck then
    if OptionBuilder:GetRecipe(id, "RootTree") then
      return
    end
  end

  local buildingGroup = string.format("[block&%s]/children", id)

  OptionBuilder:AddRecipe(TreeItemRecipe():SetID(id):SetPath("blocks"):SetBuildingGroup(buildingGroup):SetText(category.name), "RootTree")
  OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("block.%s.frame", category.id)):SetElementParentID("block.frame"), string.format("%s/general", id))
  OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("block.%s.header", category.id)):SetElementParentID("block.header"):SetOrder(100), string.format("%s/header", id))
  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("block.%s.header.text", category.id))
  :SetElementParentID("block.header.text")
  :SetOrder(200)
  :ClearFlags()
  :AddFlag(Theme.SkinFlags.TEXT_FONT)
  :AddFlag(Theme.SkinFlags.TEXT_SIZE)
  :AddFlag(Theme.SkinFlags.TEXT_COLOR)
  :AddFlag(Theme.SkinFlags.TEXT_TRANSFORM)
  :AddFlag(Theme.SkinFlags.TEXT_JUSTIFY_HORIZONTAL)
  :AddFlag(Theme.SkinFlags.TEXT_JUSTIFY_VERTICAL) , string.format("%s/header", id))
  OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("block.%s.content", category.id)):SetElementParentID("block.content"), string.format("%s/content", id))

  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("block.%s.header.stripe", category.id))
  :SetElementParentID("block.header.stripe")
  :SetOrder(310)
  :ClearFlags()
  :AddFlag(Theme.SkinFlags.TEXTURE_COLOR), string.format("%s/header", id))
end
