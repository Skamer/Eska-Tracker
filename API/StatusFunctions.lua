--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                  "EskaTracker.API.StatusFunctions"                       ""
--============================================================================--
namespace                           "EKT"
--============================================================================--

struct "StatusFunction" (function(_ENV)
  member "id" { TYPE = String, REQUIRE = true }
  member "text" { TYPE = String, REQUIRE = true }
  member "func" { TYPE = Function, REQUIRE = true }
  member "category" { TYPE = String }
end)


class "StatusFunctions" (function(_ENV)
  _STATUS_FUNCTIONS = Dictionary()

  __Arguments__ { ClassType, StatusFunction }
  __Static__() function Register(self, statusFunction)
    _STATUS_FUNCTIONS[statusFunction.id] = statusFunction
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, id )
    return _STATUS_FUNCTIONS[id]
  end

  __Arguments__ { ClassType }
  __Static__() function GetAll(self, id)
    return _STATUS_FUNCTIONS
  end
end)

-- Quest
StatusFunctions:Register(StatusFunction("has-watched-quests", "Has Watched Quests", function() return  C_QuestLog.GetNumQuestWatches() > 0 end, "Quest"))
-- Achievement
StatusFunctions:Register(StatusFunction("has-achievements", "Has Achievements", function() return GetTrackedAchievements() ~= nil end, "Achievement"))

-- Dungeon
StatusFunctions:Register(StatusFunction("is-in-dungeon", "Is in Dungeon", Utils.Instance.IsInDungeon, "Dungeon"))
StatusFunctions:Register(StatusFunction("is-in-keystone", "Is in Mythic +", function() return C_ChallengeMode.GetActiveKeystoneInfo() > 0 end, "Dungeon"))
-- Battlegorund
StatusFunctions:Register(StatusFunction("is-in-battleground", "Is in Battleground", Utils.Instance.IsInBattleground, "Battleground"))
-- Arena
StatusFunctions:Register(StatusFunction("is-in-arena", "Is in Arena", IsActiveBattlefieldArena, "Arena"))
-- Pet Battle
StatusFunctions:Register(StatusFunction("is-in-pet-battle", "Is in Pet Battle", C_PetBattles.IsInBattle, "Pet Battle"))
-- Combat
StatusFunctions:Register(StatusFunction("is-in-combat", "Is in Combat", function() return UnitAffectingCombat("player") end, "Combat"))
StatusFunctions:Register(StatusFunction("is-dead", "Is Dead", function() return UnitIsDead("player") end, "Combat"))
-- Group Size
StatusFunctions:Register(StatusFunction("is-in-raid", "Is in Raid", IsInRaid, "Group Size"))
StatusFunctions:Register(StatusFunction("is-in-group", "Is in Group", IsInGroup, "Group Size"))
-- Scenario
StatusFunctions:Register(StatusFunction("is-in-scenario", "Is in Scenario", C_Scenario.IsInScenario, "Scenario"))
-- Warfront
StatusFunctions:Register(StatusFunction("is-in-warfront", "Is in Warfront", function()
  local scenarioType = select(10, C_Scenario.GetInfo())
  if scenarioType and scenarioType == LE_SCENARIO_TYPE_WARFRONT then
    return true
  end
  return false
end, "Warfront"))
