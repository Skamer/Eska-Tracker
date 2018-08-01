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

  OptionBuilder:AddRecipe(CheckBoxRecipe():SetText("Enabled"):SetOrder(10):BindSetting("idle-mode-enabled"), "idle-mode/children")
end
