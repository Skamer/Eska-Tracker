--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                     "EskaTracker.API.Action"                             ""
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
--------------------------------------------------------------------------------
--                                                                            --
--                        __Action__ Attribute                                --
--                                                                            --
--------------------------------------------------------------------------------
class "__Action__" (function(_ENV)
  extend "IAttachAttribute"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function AttachAttribute(self, target, targettype, owner, name, stack)
    local id   = self[1]
    local txt  = self[2] or ""

    Attribute.IndependentCall(function()
      class(target) (function(_ENV)
        property "id" { STATIC = true, TYPE = String, DEFAULT = id, SET = false }
        property "text" { STATIC = true, TYPE = String, DEFAULT = txt }
      end)
    end)

    Actions:Add(target)
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "AttributeTarget" { DEFAULT = AttributeTargets.Class }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
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
