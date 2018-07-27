--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio            "EskaTracker.API.Settings"                                 ""
--============================================================================--
namespace                "EKT"
--============================================================================--
class "Setting" (function(_ENV)
  property "id" { TYPE = String }
  property "default" { TYPE = Any }
  property "func" { TYPE = Callable + String }
  ------------------------------------------------------------------------------
  --                          Meta-Methods                                    --
  ------------------------------------------------------------------------------
  function __call(self, ...)
    if self.func then
      if type(self.func) == "string" then
        CallbackHandlers:Call(self.func, ...)
      else
        self.func(...)
      end
    end
  end
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { String, Any, Variable.Optional(Callable + String) }
  function Setting(self, id, default, func)
    self.id         = id
    self.default    = default
    self.func       = func
  end
end)

class "Settings" (function(_ENV)
  SETTINGS = Dictionary()

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
  __Static__() function Get(self, setting)
    -- select the current profile (global, char or spec)
    Profiles:PrepareDatabase()

    if Database:SelectTable(false, "settings") then
      local value = Database:GetValue(setting)
      if value ~= nil then
        return value
      end
    end

    if SETTINGS[setting] then
      return SETTINGS[setting].default
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function Exists(self, setting)
      -- select the current profile (global, char or spec)
      Profiles:PrepareDatabase()

      if Database:SelectTable(false, "settings") then
        local value = Database:GetValue(setting)
        if value then
          return true
        end
      end
      return false
  end

  __Arguments__ { ClassType, String, Variable.Optional(), Variable.Optional(Boolean, true), Variable.Optional(Boolean, true)}
  __Static__() function Set(self, setting, value, useHandler, passValue)
    -- select the current profile (global, char or spec)
    Profiles:PrepareDatabase()

    Database:SelectTable("settings")
    local oldValue = Database:GetValue(setting)
    local newValue = value
    local defaultValue = SETTINGS[setting] and SETTINGS[setting].default

    if oldValue == nil then
      oldValue = defaultValue
    end

    if value and value == defaultValue then
      Database:SetValue(setting, nil)
    else
      Database:SetValue(setting, value)
    end

    if newValue == nil then
      newValue = defaultValue
    end

    if newValue ~= oldValue then
      Frame:BroadcastSetting(setting, newValue, oldValue)
      Scorpio.FireSystemEvent("EKT_SETTING_CHANGED", setting, newValue, oldValue)
    end

    -- Call the handler if needed
    if useHandler then
      local opt = SETTINGS[setting]
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
  __Static__() function Register(self, setting, default, func)
    self:Register(Setting(setting, default, func))
  end

  __Arguments__ { ClassType, Setting }
  __Static__() function Register(self, setting)
    SETTINGS[setting.id] = setting
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
  function ResetSetting(self, id)
    self:Set(id, nil)
  end
end)

__SystemEvent__()
function EKT_PROFILE_CHANGED(profile, oldProfile)
  local oldProfileData = DiffMap()
  Profiles:PrepareDatabase(oldProfile)

  if Database:SelectTable(false, "settings") then
    for k, v in Database:IterateTable() do
      oldProfileData:SetValue(k, v)
    end
  end

  local newProfileData = DiffMap()
  Profiles:PrepareDatabase(profile)

  if Database:SelectTable(false, "settings") then
    for k, v in Database:IterateTable() do
      newProfileData:SetValue(k, v)
    end
  end

  local diff = oldProfileData:Diff(newProfileData)
  for index, setting in ipairs(diff) do
    local value = Settings:Get(setting)
    if option == "theme-selected" then
      Themes:Select(value, false)
    else
      Frame:BroadcastSetting(setting, value)
    end
  end
end

__SystemEvent__()
function EKT_COPY_PROFILE_PROCESS(sourceDB, destDB, destProfile)
  if sourceDB["settings"] then
    destDB["settings"] = sourceDB["settings"]
  end
end
