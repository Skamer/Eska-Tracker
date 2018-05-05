-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio             "EskaTracker.API.Option"                                  ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "Option" (function(_ENV)

  property "id" { Type = String }
  property "default" { Type = Any }
  property "func" { Type = Callable + String }

  function __call(self, ...)
    if self.func then
      if type(self.func) == "string" then
        CallbackHandlers:Call(self.func, ...)
      else
        self.func(...)
      end
    end
  end

  __Arguments__ { String, Any, Variable.Optional(Callable + String) }
  function Option(self, id,  default, func)
    self.id = id
    self.default = default
    self.func = func
  end

end)


class "Options" (function(_ENV)
  OPTIONS = Dictionary()

  __Arguments__ { ClassType }
  __Static__() function SelectCurrentProfile(self)
    -- Get the current profile for this character
    local dbUsed = self:GetCurrentProfile()

    if dbUsed == "spec" then
      Database:SelectRootSpec()
    elseif dbUsed == "char" then
      Database:SelectRootChar()
    else
      Database:SelectRoot()
    end
  end


  __Arguments__ { ClassType, String }
  __Static__() function Get(self, option)
    -- select the current profile (global, char or spec)
    Profils:PrepareDatabase()

    if Database:SelectTable(false, "options") then
      local value = Database:GetValue(option)
      if value ~= nil then
        return value
      end
    end

    if OPTIONS[option] then
      return OPTIONS[option].default
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function Exists(self, option)
      -- select the current profile (global, char or spec)
      Profils:PrepareDatabase()

      if Database:SelectTable(false, "options") then
        local value = Database:GetValue(option)
        if value then
          return true
        end
      end
      return false
  end

  __Arguments__ { ClassType, String, Variable.Optional(), Variable.Optional(Boolean, true), Variable.Optional(Boolean, true)}
  __Static__() function Set(self, option, value, useHandler, passValue)
    -- select the current profile (global, char or spec)
    Profils:PrepareDatabase()

    Database:SelectTable("options")
    local oldValue = Database:GetValue(option)
    local newValue = value
    local defaultValue = OPTIONS[option] and OPTIONS[option].default

    if oldValue == nil then
      oldValue = defaultValue
    end

    if value and value == defaultValue then
      Database:SetValue(option, nil)
    else
      Database:SetValue(option, value)
    end

    if newValue == nil then
      newValue = defaultValue
    end

    if newValue ~= oldValue then
      Frame:BroadcastOption(option, newValue, oldValue)
      Scorpio.FireSystemEvent("EKT_OPTION_CHANGED", option, newValue, oldValue)
    end

    -- Call the handler if needed
    if useHandler then
      local opt = OPTIONS[option]
      if opt then
        if passValue then
          opt(value)
        else
          opt()
        end
      end
    end
  end


  __Arguments__ { ClassType, String, Any, Variable.Optional(Callable + String) }
  __Static__() function Register(self, option, default, func)
    self:Register(Option(option, default, func))
  end

  __Arguments__ { ClassType, Option }
  __Static__() function Register(self, option)
      OPTIONS[option.id] = option
  end

  __Arguments__ { ClassType, Variable.Optional(String, "global") }
  __Static__() function SelectProfile(self, profile)
    Database:SelectRoot()
    Database:SelectTable("dbUsed")

    local name, realm = UnitFullName("player")
    name = realm .. "-" .. name

    Database:SetValue(name, profile)
  end

  __Arguments__ { ClassType }
  __Static__() function GetCurrentProfile(self)
    Database:SelectRoot()
    if Database:SelectTable(false, "dbUsed") then
      local name  = UnitFullName("player")
      local realm = GetRealmName()
      name = realm .. "-" .. name
      local dbUsed = Database:GetValue(name)
      if dbUsed then
        return dbUsed
      end
    end
    return "global"
  end


  __Arguments__ { ClassType, String }
  function ResetOption(self, id)
      self:Set(id, nil)
  end

  function ResetAllOptions(self)

  end

end)


__SystemEvent__()
function EKT_PROFIL_CHANGED(profil, oldProfil)
  local oldProfilData = DiffMap()
  Profils:PrepareDatabase(oldProfil)

  if Database:SelectTable(false, "options") then
    for k, v in Database:IterateTable() do
      oldProfilData:SetValue(k, v)
    end
  end

  local newProfilData = DiffMap()
  Profils:PrepareDatabase(profil)

  if Database:SelectTable(false, "options") then
    for k, v in Database:IterateTable() do
      newProfilData:SetValue(k, v)
    end
  end

  local diff = oldProfilData:Diff(newProfilData)
  for index, option in ipairs(diff) do
    local value = Options:Get(option)
    if option == "theme-selected" then
      Themes:Select(value, false)
    else
      Frame:BroadcastOption(option, value)
    end
  end
end
