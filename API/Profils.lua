--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                 "EskaTracker.API.Profils"                             ""
--============================================================================--
namespace                        "EKT"
--============================================================================--
_SPECS_INDEX_ID            = "__ScorpioSpecs"
_FIRST_EVENT_CALL_OCCURRED = false
GetActiveSpecGroup         = GetActiveSpecGroup
--============================================================================--
--------------------------------------------------------------------------------
--                                                                            --
--                               Profils                                      --
--                                                                            --
--------------------------------------------------------------------------------
class "Profils" (function(_ENV)
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

  __Static__() function Select(self, name)
    Database:SelectRootSpec()
    Database:SetValue("profile_used", name)
  end

  __Static__() function Create(self, name)
    Database:SelectRoot()
    Database:SelectTable("profils")
    Database:SetValue(name, {})
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

    if GetActiveSpecGroup() == specIndex then
      self:CheckProfilChange()
    end
  end

  -- print(EKT.Profils:GetProfileForSpec(2))
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

  __Static__() function PrepareDatabase()
    local profil = Database:GetSpec().profile_used
    if not profil then
      Database:SelectRoot()
    elseif profil == "__spec" then
      Database:SelectRootSpec()
    elseif profil == "__char" then
      Database:SelectRootChar()
    else
      Database:SelectRoot()
      Database:SelectTable(false, "profils", profil)
    end
  end

  __Static__() function GetUserProfilsList()
    Database:SelectRoot()
    local list = {}
    if Database:SelectTable(false, "profils") then
      for profilName in Database:IterateTable() do
        list[profilName] = profilName
      end
    end

    return list
  end

  __Static__() function CheckProfilChange()
    local profil = Database:GetSpec().profile_used or "__global"
    local oldProfil = Profils.name or "__global"
    local hasChanged = false

    if profil == "__spec" then
      hasChanged = true
    elseif profil ~= oldProfil then
      hasChanged = true
    end

    Profils.name = profil

    if hasChanged  then
      Scorpio.FireSystemEvent("EKT_PROFIL_CHANGED", profil)
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  __Static__() property "name" { TYPE = String }
end)

--[[
function OnSpecChanged(self)
  local profil = Database:GetSpec().profile_used or "__global"
  local oldProfil = Profils.name or "__global"
  local hasChanged = false

  if profil == "__spec" then
    hasChanged = true
  elseif profil ~= oldProfil then
    hasChanged = true
  end

  Profils.name = profil

  if hasChanged and _FIRST_EVENT_CALL_OCCURRED then
    Scorpio.FireSystemEvent("EKT_PROFIL_CHANGED", profil)
  end


end
--]]
--[[
function OnSpecChanged(self)
  Profils:CheckProfilChange()
end
--]]
__SystemEvent__()
function PLAYER_SPECIALIZATION_CHANGED()
  Profils:CheckProfilChange()
end

function OnLoad(self)
  Profils:CheckProfilChange()
end
