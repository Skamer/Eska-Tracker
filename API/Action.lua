-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio                  "EskaTracker.API.Action"                             ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "Actions" (function(_ENV)
  _Actions = setmetatable({}, { __mode = "v"})

  __Arguments__ { ClassType, ClassType }
  __Static__() function Add(self, class)
    if not self:Get(class.id) then
      _Actions[class.id] = class
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function Remove(self, id)
    _Actions[id] = nil
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, id)
    return _Actions[id]
  end

  __Arguments__ { ClassType, String, Variable.Rest() }
  __Static__() function Exec(self, id, ...)
    local action = self:Get(id)
    if action then
      action.Exec(...)
    end
  end

  __Static__() function GetIterator()
    return pairs(_Actions)
  end
end)


--[[
__AttributeUsage__ { AttributeTarget = AttributeTargets.Class, Inherited = false, RunOnce = true, BeforeDefinition = true, AllowMultiple = true }
class "__Action__" (function(_ENV)
  extend "IAttribute"

  function __Action__:ApplyAttribute(target, targetType)
    local id   = self[1]
    local text = self[2]

    target.id = __Static__ {
      TYPE = String,
      DEFAULT = id,
      SET = false,
    }

    target.text = __Static__ {
      TYPE = String,
      DEFAULT = text,
    }

    Actions:Add(target)
  end

  __Arguments__{ Argument(NEString, true, nil, nil, true) }
  function __Action__(self, ...)
    for i = 1, select('#', ...) do
        tinsert(self, select(i, ...))
    end
  end

  __Arguments__ { NEString }
  function __call(self, other)
    tinsert(self, other)
    return self
  end

  function __eq(self, other) return false end

end)
--]]


class "__Action__" (function(_ENV)
  extend "IAttachAttribute"

  function AttachAttribute(self, target, targettype, owner, name, stack)
    local id   = self[1]
    local txt  = self[2] or ""

    --[[class(target) {
      id   = { STATIC = true, TYPE = String, DEFAULT = id, SET = false },
      text = { STATIC = true, TYPE = String, DEFAULT = txt }
    }--]]

    class(target) (function(_ENV)
      property "id" { STATIC = true, TYPE = String, DEFAULT = id, SET = false }
      property "text" { STATIC = true, TYPE = String, DEFAULT = txt }
    end)

    Actions:Add(target)
  end

  property "AttributeTarget" { DEFAULT = AttributeTargets.Class }

  __Arguments__ { Variable.Rest(NEString) }
  function __new(cls, ...)
    return { ... }, true
  end

  __Arguments__ { NEString }
  function __call(self, other)
    tinsert(self, other)
    return self
  end

end)


__Action__ "join-a-group" "Join a group"
class "JoinAGroupAction" (function(ENV)

  __Arguments__ { String }
  __Static__() function Exec(msg)
    print("Join a group with this string", msg)
  end

  __Arguments__ { Number }
  __Static__() function Exec(id)
    print("Join a group with this number", id)
  end
end)

class "JoinAGroupAction" (function(_ENV)

  __Arguments__ { Boolean }
  __Static__() function Exec(bool)
    print("Join a group with this bool", bool)
  end

  __Arguments__ { String }
  __Static__() function Exec(msg)
    print("[OVERRiDE]", "Join a group with this new string", msg)
  end
end)
