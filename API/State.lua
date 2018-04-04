-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio               "EskaTracker.API.State"                            ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "State" (function(_ENV)
  property "id" { TYPE = String }
  property "text" { TYPE = String }
  property "color" { TYPE = Color }

  __Arguments__ { String, String, Color }
  function State(self, id, text, color)
    self.id = id
    self.text = text
    self.color = color
  end

end)

class "States" (function(_ENV)
  _STATES = Dictionary()

  __Arguments__ { ClassType, State}
  __Static__() function Add(self, state)
    _STATES[state.id] = state
  end

  __Arguments__ { ClassType }
  __Static__() function GetIterator()
    return _STATES:GetIterator()
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, stateID)
    return _STATES[stateID]
  end

end)

function OnLoad(self)
  -- Add some basic state
  States:Add(State("none", "None", Color(1, 1, 1)))
  States:Add(State("completed", "Completed", Color(0, 1, 0)))
  States:Add(State("progress", "Progress", Color(0.5, 0.5, 0.5)))
  States:Add(State("tracked", "Tracked", Color(1.0, 0.5, 0)))
  States:Add(State("failed", "Failed", Color(1.0, 0, 0)))
end
