--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                     "EskaTracker.API.State"                              ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "State" (function(_ENV)
  property "id"     { TYPE = String }
  property "text"   { TYPE = String }
  property "color"  { TYPE = Color }
  property "icon"   { TYPE = String }

  local function RGBPercToHex(r, g, b)
  	r = r <= 1 and r >= 0 and r or 0
  	g = g <= 1 and g >= 0 and g or 0
  	b = b <= 1 and b >= 0 and b or 0
  	return string.format("%02x%02x%02x", r*255, g*255, b*255)
  end

  function ColorText(self, str)
    if not self.color then
      return str
    end

    return string.format("|cff%s%s|r", RGBPercToHex(self.color.r, self.color.g, self.color.b), str)
  end

  __Arguments__ { String, String, Color, Variable.Optional(String) }
  function State(self, id, text, color, icon)
    self.id     = id
    self.text   = text
    self.color  = color
    self.icon   = icon
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
  States:Add(State("none", "None", Color(1, 1, 1), [[Interface\AddOns\EskaTracker\Media\none_icon]]))
  States:Add(State("completed", "Completed", Color(0, 1, 0), [[Interface\AddOns\EskaTracker\Media\completed_icon]]))
  States:Add(State("progress", "Progress", Color(0.5, 0.5, 0.5), [[Interface\AddOns\EskaTracker\Media\progress_icon]]))
  States:Add(State("tracked", "Tracked", Color(1.0, 0.5, 0), [[Interface\AddOns\EskaTracker\Media\tracked_icon]]))
  States:Add(State("failed", "Failed", Color(1.0, 0, 0), [[Interface\AddOns\EskaTracker\Media\failed_icon]]))
  States:Add(State("idle", "Idle", Color(1, 1, 1), [[Interface\AddOns\EskaTracker\Media\idle_icon]]))
end
