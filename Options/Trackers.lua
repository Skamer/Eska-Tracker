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
  self:AddTrackersRecipes()
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
