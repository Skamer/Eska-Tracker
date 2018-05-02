--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.Options.Profils"                          ""
--============================================================================--
import                         "EKT"
--============================================================================--

local function GetNumSpec()
  local _, class = UnitClass("player")
  if class == "DEMONHUNTER" then
    return 2
  elseif class == "DRUID" then
    return 4
  else
    return 3
  end
end

--- GetActiveSpecGroup
-- GetSpecializationInfo
-- GetNumSpecializations

function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("profils"):SetText("Profils"):SetBuildingGroup("profils/childrens"), "RootTree")

  self:AddProfilRecipes()
end

function AddProfilRecipes(self)
  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Select a profil for your specialization"):SetOrder(10), "profils/childrens")
  for i = 1, GetNumSpec() do
    OptionBuilder:AddRecipe(SpecProfilRecipe():SetSpecIndex(i):SetOrder(20 + 10 * i), "profils/childrens")
  end

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cff00ff00Create a profil|r"):SetOrder(90), "profils/childrens")

  --- [PART] Create a profil
  local lineEdit = LineEditRecipe()
  lineEdit:SetText("Enter the name of your new profils")
  lineEdit:SetOrder(100)
  lineEdit.OnValueConfirmed = lineEdit.OnValueConfirmed + function(self, profilName) Profils:Create(profilName) end
  OptionBuilder:AddRecipe(lineEdit, "profils/childrens")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("Copy from another profil"):SetOrder(110), "profils/childrens")
  OptionBuilder:AddRecipe(SelectRecipe():SetText("Select the profil you want copy"):SetOrder(111), "profils/childrens")

  OptionBuilder:AddRecipe(HeadingRecipe():SetText("|cffff0000Delete a profil|r"):SetOrder(120), "profils/childrens")
  OptionBuilder:AddRecipe(SelectRecipe():SetText("Select the profile to delete"):SetOrder(121), "profils/childrens")

end
