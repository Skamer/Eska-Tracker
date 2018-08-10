--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                 "EskaTracker.API.ObjectManager"                          ""
-- ========================================================================== --
namespace                          "EKT"
import                        "System.Recycle"
-- ========================================================================== --
class "ObjectManager" (function(_ENV)
  _Recyclers = Dictionary()

  __Arguments__ { ClassType, ClassType }
  __Static__() function Get(self, type)
    return _Recyclers[type]()
  end

  __Arguments__ { ClassType, Table }
  __Static__() function Recycle(self, obj)
    local recycler = _Recyclers[Class.GetObjectClass(obj)]
    if recycler then
      recycler(obj)
    end
  end

  __Arguments__ { ClassType, ClassType }
  __Static__() function Register(self, type)
    if not _Recyclers[type] then
      local recycler = System.Recycle(type)
      recycler.OnPush = function(_, obj)
        if obj.OnRecycle then
          obj._isUsed = false
          obj:OnRecycle()
        end
      end

      recycler.OnPop =  function(_, obj)
        local wasRecycled = not obj._isUsed
        obj._isUsed = true
        if wasRecycled and Class.IsSubType(getmetatable(self), Frame) then
          -- TODO: make specifi stuff when pop and was reycled : apply pending options, layout, ...
        end
      end

      _Recyclers[type] = recycler
    end
  end
end)

--------------------------------------------------------------------------------
--                        Attribute __Recyclable__                            --
--  __Recyclable__ will register the class targeted in the ObjectManger and   --
-- will defined aditional property and method                                 --
-- obj._isUsed -> will say if the object is currently used                    --
-- obj:Recycle() -> will recycle the object, calling the Reset method, and    --
-- push it in the reycable pool.                                              --
--------------------------------------------------------------------------------
class "__Recyclable__" (function(_ENV)
  extend "IAttachAttribute"

  function AttachAttribute(self, target, targettype, owner, name, stack)
    Attribute.IndependentCall(function()
      class(target) (function(_ENV)
        function Recycle(self)
          ObjectManager:Recycle(self)
        end
        property "_isUsed" { TYPE = Boolean, DEFAULT = true }
      end)
    end)

    ObjectManager:Register(target)
  end

  property "AttributeTargets" { DEFAULT = AttributeTargets.Class }
end)
