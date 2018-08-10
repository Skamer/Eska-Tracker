--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                   "EskaTracker.Loader"                                   ""
--============================================================================--
namespace              "EKT"
--============================================================================--
--------------------------------------------------------------------------------
--                                                                            --
--                         __EnablingOnEvent__                                --
--                                                                            --
--------------------------------------------------------------------------------
class "__EnablingOnEvent__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, cond, ...)
    while true do
      if owner._Enabled then
        Next()
      else
        local eventInfo = { Wait(...) }
        local enabled = cond(owner, unpack(eventInfo))
        if enabled then
          owner._EnablingEvent = eventInfo[1]
          owner._EnablingEventArgs = { select(2, unpack(eventInfo)) }
          owner._Enabled = true
        end
      end
    end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, unpack(self))
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                        __DisablingOnEvent__                                --
--                                                                            --
--------------------------------------------------------------------------------
class "__DisablingOnEvent__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, cond, ...)
    while true do
      if owner._Disabled then
        Next()
      else
        owner._Enabled = not cond(owner, Wait(...))
      end
    end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, unpack(self))
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                         __SafeDisablingOnEvent__                           --
--                                                                            --
--------------------------------------------------------------------------------
class "__SafeDisablingOnEvent__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, cond, ...)
    while true do
      if owner._Disabled then
        Next()
      else
        local eventInfo = { Wait(...) }
        local disabled = cond(owner, unpack(eventInfo))
        if disabled then
          local handler = owner:GetRegisteredEventHandler(eventInfo[1])
          if handler then
            handler(select(2, unpack(eventInfo)))
          end
        end
        owner._Enabled = not disabled
      end
    end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, unpack(self))
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                      __SafeActivatingOnEvent__                             --
--                                                                            --
--------------------------------------------------------------------------------
class "__SafeActivatingOnEvent__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, cond, ...)
    while true do
      local eventInfo = { Wait(...) }
      local enabled = cond(owner, unpack(eventInfo))
      if owner._Enabled and not enabled then
        local handler = owner:GetRegisteredEventHandler(eventInfo[1])
        if handler then
          handler(select(2, unpack(eventInfo)))
        end
      elseif not owner._Enabled and enabled then
        owner._EnablingEvent = eventInfo[1]
      end
      owner._Enabled = enabled
    end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, unpack(self))
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                        __ActivatingOnEvent__                               --
--                                                                            --
--------------------------------------------------------------------------------
class "__ActivatingOnEvent__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, cond, ...)
    while true do
      local eventInfo = { Wait(...) }
      local enabled = cond(owner, unpack(eventInfo))
      if not owner._Enabled and enabled then
        owner._EnablingEvent = eventInfo[1]
      end

      owner._Enabled = enabled
    end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, unpack(self))
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                        __ForceSecureHook__                                 --
--                                                                            --
--------------------------------------------------------------------------------
class "__ForceSecureHook__" (function(_ENV)
  inherit "__SystemEvent__"

  local function RegisterModule(owner, func, secureFunc)
      while true do
        func(NextSecureCall(secureFunc))
      end
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      ThreadCall(RegisterModule, owner, target, self[1])
    else
      ThreadCall(RegisterModule, owner, target, name)
    end
  end
end)


class "__BlocksReloader__" (function(_ENV)
  inherit "__SystemEvent__"

  _BLOCK_RELOADING_INFO = setmetatable({}, { __mode = "k"} )

  local function RegisterModule(owner, func, ...)
    _BLOCK_RELOADING_INFO[owner] = {
      func = func,
      bCategoriesUsed = List(...)
    }
  end

  function AttachAttribute(self, target, targetType, owner, name)
    if #self > 0 then
      RegisterModule(owner, target, unpack(self))
    end
  end


  __Static__() function BroadcastChanges(self, ...)
    for module, info in pairs(_BLOCK_RELOADING_INFO) do
      for i = 1, select("#", ...) do
        local category = select(i, ...)
        if info.bCategoriesUsed:Contains(category) then
          info.func(module)
          break
        end
      end
    end
  end
end)
