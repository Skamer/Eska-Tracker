--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.Options.IdleMode"                         ""
--============================================================================--
import                       "EKT"
--============================================================================--
function OnLoad(self)
  OptionBuilder:AddRecipe(TreeItemRecipe():SetID("idle-mode"):SetText("Idle Mode"):SetBuildingGroup("idle-mode/children"):SetOrder(20), "RootTree")
end
