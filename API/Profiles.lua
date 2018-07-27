--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                 "EskaTracker.API.Profiles"                            ""
--============================================================================--
namespace                        "EKT"
--============================================================================--
_SPECS_INDEX_ID            = "__ScorpioSpecs"
_FIRST_EVENT_CALL_OCCURRED = false
GetActiveSpecGroup         = GetActiveSpecGroup
--============================================================================--
--------------------------------------------------------------------------------
--                                                                            --
--                               Profiles                                      --
--                                                                            --
--------------------------------------------------------------------------------
class "Profiles" (function(_ENV)
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Static__() function SelectSpec()
    Database:SelectRootSpec()
    Database:SetValue("profile_used", "__spec")
  end


  __Static__() function SelectChar()
    Database:SelectRootSpec()
    Database:SetValue("profile_used", "__char")
  end

  __Static__() function SelectGlobal()
    Database:SelectRootSpec()
    Database:SetValue("profile_used", nil)
  end

  __Arguments__ { ClassType, String }
  __Static__() function Select(self, name)
    Database:SelectRootSpec()
    Database:SetValue("profile_used", name)
  end

  __Arguments__ { ClassType, String }
  __Static__() function Create(self, name)
    Database:SelectRoot()
    Database:SelectTable("profiles")
    Database:SetValue(name, { __profile_name = name })
  end

  __Arguments__ { ClassType, String }
  __Static__() function Delete(self, name)
    Database:SelectRoot()
    if Database:SelectTable(false, "profiles") then
      Database:SetValue(name, nil)
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function CopyFrom(self, name)
    local sourceDB
    if self:IsGlobal(name) then
      sourceDB = Database:GetCopyTable(Database:Path())
    elseif self:IsChar(name) then
      sourceDB = Database:GetCopyTable(Database:Path():SetRelativeDB("char"))
    elseif self:IsSpec(name) then
      sourceDB = Database:GetCopyTable(Database:Path():SetRelativeDB("spec"))
    end

    self:PrepareDatabase()
    Scorpio.FireSystemEvent("EKT_COPY_PROFILE_PROCESS", sourceDB, Database:GetCurrentTable(), destProfile)
  end

  __Arguments__ { ClassType, Variable.Optional(String) }
  __Static__() function IsGlobal(self, profileName)
    return profileName == nil or profileName == "__global"
  end

  __Arguments__ { ClassType, String }
  __Static__() function IsSpec(self, profileName)
    return profileName == "__spec"
  end

  __Arguments__ { ClassType, String }
  __Static__() function IsChar(self, profileName)
    return profileName == "__char"
  end

  __Arguments__ { ClassType, String }
  __Static__() function IsUser(self, profileName)
    return not self:IsGlobal(profileName) and not self:IsSpec(profileName) and not self:IsChar(profileName)
  end

  __Arguments__ { ClassType, Number, Variable.Optional(String) }
  __Static__() function SelectForSpec(self, specIndex, profile)
    if not Database:GetChar()[_SPECS_INDEX_ID] then
      Database:GetChar()[_SPECS_INDEX_ID] = {}
    end

    if not Database:GetChar()[_SPECS_INDEX_ID][specIndex] then
      Database:GetChar()[_SPECS_INDEX_ID][specIndex] = {}
    end

    Database:GetChar()[_SPECS_INDEX_ID][specIndex].profile_used = profile

    if GetSpecialization() == specIndex then
      self:CheckProfileChange()
    end
  end

  __Arguments__ { ClassType, Number }
  __Static__() function GetProfileForSpec(self, specIndex)
    Database:SelectRootChar()
    if Database:SelectTable(false, _SPECS_INDEX_ID) then
      local value = Database:GetValue(specIndex)
      if value then
        return value.profile_used
      end
    end
  end

  __Arguments__ { ClassType, Variable.Optional(String)}
  __Static__() function PrepareDatabase(self, profile)
    if not profile then
      profile = Database:GetSpec().profile_used
    end

    if not profile or profile == "__global" then
      Database:SelectRoot()
    elseif profile == "__spec" then
      Database:SelectRootSpec()
    elseif profile == "__char" then
      Database:SelectRootChar()
    else
      Database:SelectRoot()
      Database:SelectTable(false, "profiles", profile)
    end
  end

  __Static__() function GetUserProfilesList()
    Database:SelectRoot()
    local list = {}
    if Database:SelectTable(false, "profiles") then
      for profileName in Database:IterateTable() do
        list[profileName] = profileName
      end
    end

    return list
  end

  __Async__()
  __Static__() function CheckProfileChange()
    local profile = Database:GetSpec().profile_used or "__global"
    local oldProfile = Profiles.name or "__global"
    local hasChanged = false


    if profile == "__spec" then
      hasChanged = true
    elseif profile ~= oldProfile then
      hasChanged = true
    end

    Profiles.name = profile

    if hasChanged  then
      Scorpio.FireSystemEvent("EKT_PROFILE_CHANGED", profile, oldProfile)
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  __Static__() property "name" { TYPE = String }
end)

function OnLoad(self)
  local spec = GetSpecialization()
  if not spec then
    TryToLoadProfiles()
  else
    Profiles:CheckProfileChange()
    Scorpio.FireSystemEvent("EKT_PROFILES_LOADED")
  end

end

__Async__()
function TryToLoadProfiles()
  NextEvent("PLAYER_LOGIN")

  Profiles:CheckProfileChange()
  Scorpio.FireSystemEvent("EKT_PROFILES_LOADED")
end

__SystemEvent__()
function PLAYER_SPECIALIZATION_CHANGED()
  Profiles:CheckProfileChange()
end
