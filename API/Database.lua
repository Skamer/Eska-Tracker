-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio             "EskaTracker.API.Database"                                ""
--============================================================================--
namespace "EKT"
--============================================================================--
class "Database" (function(_ENV)

  CURRENT_TABLE = nil
  CURRENT_PARENT_TABLE = nil
  CURRENT_LEVEL = 0
  CURRENT_TABLE_NAME = nil


  class "Migration" (function(_ENV)
        function Up(self)
            -- Migrate the DB to version 8 (>=1.0.1)
        end

        function Down(self)
            -- Downgrade the DB to version
        end

  end)

  __Arguments__{ ClassType, Any, Variable.Optional() }
  __Static__() function SetValue(self, index, value)
    CURRENT_TABLE[index] = value
  end

  __Arguments__ { ClassType, Any }
  __Static__() function GetValue(self, index)
    return CURRENT_TABLE[index]
  end


  __Arguments__ { ClassType }
  __Static__() function IterateTable(self)
    return pairs(CURRENT_TABLE)
  end

  __Arguments__ { ClassType }
  __Static__() function Clean()
    local function ClearEmptyTables(t)
      for k,v in pairs(t) do
        if type(v) == "table" then
          ClearEmptyTables(v)
          if next(v) == nil then
            t[k] = nil
          end
        end
      end
    end

      ClearEmptyTables(EskaQuestTrackerDB)
  end

  __Arguments__ { ClassType, Variable.Rest(String) }
  __Static__() function MoveTable(self, ...)
    local function deepcopy(orig)
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[deepcopy(orig_key)] = deepcopy(orig_value)
          end
          setmetatable(copy, deepcopy(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
    end

    local copy = deepcopy(CURRENT_TABLE)
    local oldTable = CURRENT_TABLE
    local tables = { ... }
    local destName = tables[#tables]
    tables[#tables] = nil

    self:SelectRoot()

    if #tables > 0 then
      if self:SelectTable(true, unpack(tables)) then
        Database:SetValue(destName, copy)
        wipe(oldTable)
      end
    end
  end

  __Arguments__ { ClassType, Variable.Rest(String) }
  __Static__() function CopyTable(self, ...)
    local function deepcopy(orig)
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[deepcopy(orig_key)] = deepcopy(orig_value)
          end
          setmetatable(copy, deepcopy(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
    end

    local copy = deepcopy(CURRENT_TABLE)
    local tables = { ... }
    local destName = tables[#tables]
    tables[#tables] = nil

    self:SelectRoot()
    if #tables > 0 then
      if self:SelectTable(true, unpack(tables)) then
        Database:SetValue(destName, copy)
      end
    end
  end

__Arguments__ { ClassType }
__Static__() function DeleteTable(self)
  wipe(CURRENT_TABLE)
  self:SelectRoot()
end

  __Arguments__{ ClassType, Variable.Rest(String) }
  __Static__() function SelectTable(self, ...)
    return self:SelectTable(true, ...)
  end

  __Arguments__ { ClassType, Boolean, Variable.Rest(String) }
  __Static__() function SelectTable(self, mustCreateTables, ...)
    local count = select("#", ...)

    if not CURRENT_TABLE then
      CURRENT_TABLE = self:Get()
    end
    local tb = CURRENT_TABLE
    for i = 1, count do
      local indexTable = select(i, ...)
        if not tb[indexTable] then
          if mustCreateTables then
            tb[indexTable] = {}
          else
            return false
          end
        end

        if i > 1 then
          CURRENT_PARENT_TABLE = tb
        end

        tb = tb[indexTable]
        CURRENT_LEVEL = CURRENT_LEVEL + 1
        CURRENT_TABLE_NAME = indexTable
    end
    CURRENT_TABLE = tb

    return true
  end

  __Arguments__{ ClassType }
  __Static__() function SelectRoot(self)
    CURRENT_TABLE = self:Get()
    CURRENT_LEVEL = 0
  end

  __Arguments__{ ClassType }
  __Static__() function SelectRootChar(self)
    CURRENT_TABLE = self:GetChar()
    CURRENT_LEVEL = 0
  end

  __Arguments__ { ClassType }
  __Static__() function SelectRootSpec(self)
    CURRENT_TABLE = self:GetSpec()
    CURRENT_LEVEL = 0
  end

  __Arguments__ { ClassType, Number }
  __Static__() function SetVersion(self, version)
    if self:Get() then
      self:Get().dbVersion = version
    end
  end

  __Arguments__ { ClassType }
  __Static__() function GetVersion(self)
    if self:Get() then return self:Get().dbVersion end
  end

  __Arguments__ { ClassType }
  __Static__() function Get(self)
    return _DB
  end

  __Arguments__ { ClassType }
  __Static__() function GetChar(self)
    return _DB.Char
  end

  __Arguments__ { ClassType }
  __Static__() function GetSpec(self)
    return _DB.Char.Spec
  end

end)
