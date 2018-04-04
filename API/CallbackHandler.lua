-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio             "EskaTracker.API.CallbackHandler"                    ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "CallbackHandler"
  property "func" { TYPE = Callable + String }

  function __call(self, ...)
    self.func(...)
  end

  __Arguments__ { Callable + String }
  function CallbackHandler(self, func)
    self.func = func
  end

endclass "CallbackHandler"

class "CallbackObjectHandler" inherit "CallbackHandler"
  property "obj" { TYPE = Class + Table}

  function __call(self, ...)
    if type(self.func) == "string" then
      local f = self.obj[self.func]
      if f then
        f(self, ...)
      end
    else
      self.func(self.obj, ...)
    end
  end

  __Arguments__ { Class + Table, Callable + String }
  function CallbackObjectHandler(self, obj, func)
    self.obj = obj

    Super(self, func)
  end

endclass "CallbackObjectHandler"

class "CallbackPropertyHandler" inherit "CallbackObjectHandler"
  function __call(self, value)
    if self.obj[self.func] then
      self.obj[self.func] = value
    end
  end

  __Arguments__ { Class + Table, String }
  function CallbackPropertyHandler(self, obj, property)
    Super(self, obj, property)
  end
endclass "CallbackPropertyHandler"


class "CallbackHandlers"
  CALLBACK_HANDLERS = Dictionary()
  CALLBACK_HANDLERS_GROUPS = Dictionary()

  __Static__() __Arguments__ { Class, String, CallbackHandler, { Type = String, Nilable = true, IsList = true }}
  function Register(self, id, handler, ...)
    local numGroup = select("#", ...)
    for i = 1, numGroup do
      local groupName = select(i, ...)
      if not CALLBACK_HANDLERS_GROUPS[groupName] then
        local handlers = setmetatable( {}, { __mode = "v" })
        handlers[id] = handler
        CALLBACK_HANDLERS_GROUPS[groupName] = handlers
      else
        CALLBACK_HANDLERS_GROUPS[groupName][id] = handler
      end
    end

    CALLBACK_HANDLERS[id] = handler
  end


  __Static__() __Arguments__ { Class, { Type = String, Nilable = true, IsList = true } }
  function CallGroup(self, ...)
    local numGroup = select("#", ...)
    for i = 1, numGroup do
      local groupName = select(i, ...)
      local handlers = CALLBACK_HANDLERS_GROUPS[groupName]
      if handlers then
        for id, handler in pairs(handlers) do
          handler()
        end
      end
    end
  end

  function CallAll(self)

  end

  __Static__() __Arguments__ { Class, String, { Type = Any, Nilable = true, IsList = true } }
  function Call(self, id, ...)
    local handler = CALLBACK_HANDLERS[id]
    if handler then
      handler(...)
    end
  end

endclass "CallbackHandlers"
