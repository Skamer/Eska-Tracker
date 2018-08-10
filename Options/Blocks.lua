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

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Stripe"):SetOrder(30), "block/header")

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
  OptionBuilder:AddRecipe(ThemePropertyRecipe():SetElementID(string.format("block.%s.header", category.id)):SetElementParentID("block.header"):SetOrder(10), string.format("%s/header", id))
  OptionBuilder:AddRecipe(ThemePropertyRecipe()
  :SetElementID(string.format("block.%s.header.text", category.id))
  :SetElementParentID("block.header.text")
  :SetOrder(20)
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
  :SetOrder(40)
  :ClearFlags()
  :AddFlag(Theme.SkinFlags.TEXTURE_COLOR), string.format("%s/header", id))
end
