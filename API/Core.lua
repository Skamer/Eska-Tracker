--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio             "EskaTracker.API.Core"                               ""
--============================================================================--
namespace "EKT"
--============================================================================--
import "System.Serialization"
import "System.Collections"
--============================================================================--
_COMPRESSER = LibStub:GetLibrary("LibCompress")
_ENCODER    = _COMPRESSER:GetAddonEncodeTable()

bit_band    = bit.band
bit_lshift  = bit.lshift
bit_rshift  = bit.rshift
--============================================================================--
-- [[ DEPRECRATED]]
__Final__()
interface "API" (function(_ENV)
  do

    function Trim(self, str)
      return str:gsub("%s+", "")
    end

    function CalculateTextHeight(self, fontstring)
      local _, fontHeight = fontstring:GetFont()
      local numLines = fontstring:GetNumLines()
      return fontHeight * numLines
    end

    -- The below code is based on the Encode7Bit and encodeB64 from LibCompress
    -- and WeakAuras 2
    -- Credits go to Golmok (galmok@gmail.com) and WeakAuras author.
    local byteToBase64 = {
      [0]="A","B","C","D","E","F","G","H",
      "I","J","K","L","M","N","O","P",
      "Q","R","S","T","U","V","W","X",
      "Y","Z","a","b","c","d","e","f",
      "g","h","i","j","k","l","m","n",
      "o","p","q","r","s","t","u","v",
      "w","x","y","z","0","1","2","3",
      "4","5","6","7","8","9","-","_"
    }

    local base64ToByte = {
      A =  0,  B =  1,  C =  2,  D =  3,  E =  4,  F =  5,  G =  6,  H =  7,
      I =  8,  J =  9,  K = 10,  L = 11,  M = 12,  N = 13,  O = 14,  P = 15,
      Q = 16,  R = 17,  S = 18,  T = 19,  U = 20,  V = 21,  W = 22,  X = 23,
      Y = 24,  Z = 25,  a = 26,  b = 27,  c = 28,  d = 29,  e = 30,  f = 31,
      g = 32,  h = 33,  i = 34,  j = 35,  k = 36,  l = 37,  m = 38,  n = 39,
      o = 40,  p = 41,  q = 42,  r = 43,  s = 44,  t = 45,  u = 46,  v = 47,
      w = 48,  x = 49,  y = 50,  z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
      ["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["-"]=62,["_"]=63
    }
    local encodeBase64Table = {}

    function EncodeToBase64(self, data)
      local base64 = encodeBase64Table
      local remainder = 0
      local remainderLength = 0
      local encodedSize = 0
      local lengh = #data

      for i = 1, lengh do
        local code = string.byte(data, i)
        remainder = remainder + bit_lshift(code, remainderLength)
        remainderLength = remainderLength + 8
        while remainderLength >= 6 do
          encodedSize = encodedSize + 1
          base64[encodedSize] = byteToBase64[bit_band(remainder, 63)]
          remainder = bit_rshift(remainder, 6)
          remainderLength = remainderLength - 6
        end
      end

      if remainderLength > 0 then
        encodedSize = encodedSize + 1
        base64[encodedSize] = byteToBase64[remainder]
      end
      return table.concat(base64, "", 1, encodedSize)
    end

    local decodeBase64Table = {}

    function DecodeFromBase64(self, data)
      local bit8 = decodeBase64Table
      local decodedSize = 0
      local ch
      local i = 1
      local bitfieldLenght = 0
      local bitfield = 0
      local lenght = #data

      while true do
        if bitfieldLenght >= 8 then
          decodedSize = decodedSize + 1
          bit8[decodedSize] = decodedSize + 1
          bit8[decodedSize] = string.char(bit_band(bitfield, 255))
          bitfield = bit_rshift(bitfield, 8)
          bitfieldLenght = bitfieldLenght - 8
        end
        ch = base64ToByte[data:sub(i, i)]
        bitfield = bitfield + bit_lshift(ch or 0, bitfieldLenght)
        bitfieldLenght = bitfieldLenght + 6

        if i > lenght then
          break
        end
        i = i + 1
      end
      return table.concat(bit8, "", 1, decodedSize)
    end

  end

  function Encode(self, data, forChat)
    if forChat then
      return self:EncodeToBase64(data)
    else
      return _ENCODER:Encode(data)
    end
  end

  function Decode(self, data, fromChat)
    if fromChat then
      return self:DecodeFromBase64(data)
    else
      return _ENCODER:Decode(data)
    end
  end

  function Compress(self, data)
    return _COMPRESSER:CompressHuffman(data)
  end

  function Decompress(self, data)
    return _COMPRESSER:Decompress(data)
  end
  -- End encoding and compressing code

  -- Copy functions
  function DeepCopy(self, orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
  end

  function ShallowCopy(self, orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
  end

  function IsTableEqual(self, t1, t2, ignoreMT)
   local ty1 = type(t1)
   local ty2 = type(t2)

      if ty1 ~= ty2 then return false end
   -- non-table types can be directly compared
   if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
   -- as well as tables which have the metamethod __eq
   local mt = getmetatable(t1)
   if not ignoreMT and mt and mt.__eq then return t1 == t2 end
   for k1,v1 in pairs(t1) do
      local v2 = t2[k1]
      if v2 == nil or not self:IsTableEqual(v1,v2) then return false end
   end
   for k2,v2 in pairs(t2) do
      local v1 = t1[k2]
      if v1 == nil or not self:IsTableEqual(v1,v2) then return false end
   end
   return true
end

  function AddFlag(self, flags, flag)
    if not Enum.ValidateFlags(flags, flag) then
      flags = flags + flag
    end

    return flags
  end

  function RemoveFlag(self, flags, flag)
    if Enum.ValidateFlags(flags, flag) then
      flags = flags - flag
    end

    return flags
  end

  function IsInRange(self, value, min, max)
    if not min and max then
      return value <= max
    elseif not max and min then
      return value >= min
    elseif max and min then
      return (value >= min) and (value <= max)
    end

    return false
  end

  function GetDefaultValueFromClass(self, class, prop)
    return Class.GetFeature(class, prop):GetDefault()
  end

  function GetDefaultValueFromObj(self, obj, prop)
    return Class.GetFeature(Class.GetObjectClass(obj), prop):GetDefault()
  end

  function MapAll(self, fcn, tab, idx, ...)
      if idx < 1 then
          fcn(...)
      else
          local t = tab[idx]
          for i = 1, #t do self:MapAll(fcn, tab, idx-1, t[i], ...) end
      end
  end

  function UpperFirstOfEach(self, str)
    local function tchelper(first, rest)
        return first:upper()..rest
    end
    return str:gsub("(%a)([%w_']*)", tchelper)
  end

  function Round(self, number)
    return math.floor(number+0.5)
  end

  function TruncateDecimal(self, number, decimal)
    if not decimal then
      decimal = 0
    end

    local tenPower = math.pow(10, decimal)

    return math.floor(number * tenPower)/ tenPower
  end

end)
-- [[[ END DEPRECRATED ]]]

class "Utils" (function(_ENV)
  class "Instance" (function(_ENV)
    __Static__() function IsInBattleground(self)
      local inInstance, instanceType = IsInInstance()
      if IsInInstance and instanceType == "pvp" then
        return true
      end
      return false
    end

    __Static__() function IsInDungeon(self)
      local inInstance, instanceType = IsInInstance()
      if IsInInstance and instanceType == "party" then
        return true
      end
      return false
    end
  end)
  ------------------------------------------------------------------------------
  --                         String
  ------------------------------------------------------------------------------
  class "String" (function(_ENV)

    __Arguments__ { String }
    __Static__() function Trim(str)
      return str:gsub("%s+", "")
    end

    __Arguments__ { String }
    __Static__() function UpperFirstOfEach(str)
      local function tchelper(first, rest)
          return first:upper()..rest
      end
      return str:gsub("(%a)([%w_']*)", tchelper)
    end
  end)
  ------------------------------------------------------------------------------
  --                         Math
  ------------------------------------------------------------------------------
  class "Math" (function(_ENV)

    __Arguments__ { Number, Variable.Optional(Number), Variable.Optional(Number) }
    __Static__() function IsInRange(value, min, max)
      if not min and max then
        return value <= max
      elseif not max and min then
        return value >= min
      elseif max and min then
        return (value >= min) and (value <= max)
      end

      return false
    end

    __Arguments__ { Number }
    __Static__() function Round(number)
      return math.floor(number+0.5)
    end

    __Arguments__ {Number, Variable.Optional(Number, 0)}
    __Static__() function TruncateDecimal(number, decimal)
      local tenPower = math.pow(10, decimal)

      return math.floor(number * tenPower)/ tenPower
    end
  end)
  ------------------------------------------------------------------------------
  --                         Enum
  ------------------------------------------------------------------------------
  class "Enum" (function(_ENV)
    __Static__() function AddFlag(flags, flag)
      if not Enum.ValidateFlags(flags, flag) then
        flags = flags + flag
      end

      return flags
    end

    __Static__() function RemoveFlag(flags, flag)
      if Enum.ValidateFlags(flags, flag) then
        flags = flags - flag
      end

      return flags
    end
  end)
  ------------------------------------------------------------------------------
  --                         Class
  ------------------------------------------------------------------------------
  class "Class" (function(_ENV)
    __Static__() function GetDefaultValueFromClass(class, prop)
      return Class.GetFeature(class, prop):GetDefault()
    end

    __Static__() function GetDefaultValueFromObj(obj, prop)
      return Class.GetFeature(Class.GetObjectClass(obj), prop):GetDefault()
    end
  end)
  ------------------------------------------------------------------------------
  --                         Network
  ------------------------------------------------------------------------------
  class "Network" (function(_ENV)
    do
      -- The below code is based on the Encode7Bit and encodeB64 from LibCompress
      -- and WeakAuras 2
      -- Credits go to Golmok (galmok@gmail.com) and WeakAuras author.
      local byteToBase64 = {
        [0]="A","B","C","D","E","F","G","H",
        "I","J","K","L","M","N","O","P",
        "Q","R","S","T","U","V","W","X",
        "Y","Z","a","b","c","d","e","f",
        "g","h","i","j","k","l","m","n",
        "o","p","q","r","s","t","u","v",
        "w","x","y","z","0","1","2","3",
        "4","5","6","7","8","9","-","_"
      }

      local base64ToByte = {
        A =  0,  B =  1,  C =  2,  D =  3,  E =  4,  F =  5,  G =  6,  H =  7,
        I =  8,  J =  9,  K = 10,  L = 11,  M = 12,  N = 13,  O = 14,  P = 15,
        Q = 16,  R = 17,  S = 18,  T = 19,  U = 20,  V = 21,  W = 22,  X = 23,
        Y = 24,  Z = 25,  a = 26,  b = 27,  c = 28,  d = 29,  e = 30,  f = 31,
        g = 32,  h = 33,  i = 34,  j = 35,  k = 36,  l = 37,  m = 38,  n = 39,
        o = 40,  p = 41,  q = 42,  r = 43,  s = 44,  t = 45,  u = 46,  v = 47,
        w = 48,  x = 49,  y = 50,  z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
        ["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["-"]=62,["_"]=63
      }
      local encodeBase64Table = {}

      __Static__() function EncodeToBase64(data)
        local base64 = encodeBase64Table
        local remainder = 0
        local remainderLength = 0
        local encodedSize = 0
        local lengh = #data

        for i = 1, lengh do
          local code = string.byte(data, i)
          remainder = remainder + bit_lshift(code, remainderLength)
          remainderLength = remainderLength + 8
          while remainderLength >= 6 do
            encodedSize = encodedSize + 1
            base64[encodedSize] = byteToBase64[bit_band(remainder, 63)]
            remainder = bit_rshift(remainder, 6)
            remainderLength = remainderLength - 6
          end
        end

        if remainderLength > 0 then
          encodedSize = encodedSize + 1
          base64[encodedSize] = byteToBase64[remainder]
        end
        return table.concat(base64, "", 1, encodedSize)
      end

      local decodeBase64Table = {}

      __Static__() function DecodeFromBase64(data)
        local bit8 = decodeBase64Table
        local decodedSize = 0
        local ch
        local i = 1
        local bitfieldLenght = 0
        local bitfield = 0
        local lenght = #data

        while true do
          if bitfieldLenght >= 8 then
            decodedSize = decodedSize + 1
            bit8[decodedSize] = decodedSize + 1
            bit8[decodedSize] = string.char(bit_band(bitfield, 255))
            bitfield = bit_rshift(bitfield, 8)
            bitfieldLenght = bitfieldLenght - 8
          end
          ch = base64ToByte[data:sub(i, i)]
          bitfield = bitfield + bit_lshift(ch or 0, bitfieldLenght)
          bitfieldLenght = bitfieldLenght + 6

          if i > lenght then
            break
          end
          i = i + 1
        end
        return table.concat(bit8, "", 1, decodedSize)
      end

      __Static__() function Encode(data, forChat)
        if forChat then
          return EncodeToBase64(data)
        else
          return _ENCODER:Encode(data)
        end
      end

      __Static__() function Decode(data, fromChat)
        if fromChat then
          return DecodeFromBase64(data)
        else
          return _ENCODER:Decode(data)
        end
      end

      __Static__() function Compress(data)
        return _COMPRESSER:CompressHuffman(data)
      end

      __Static__() function Decompress(data)
        return _COMPRESSER:Decompress(data)
      end
    end
  end)
  ------------------------------------------------------------------------------
  --                         Misc
  ------------------------------------------------------------------------------
  __Static__() function DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
        end
        setmetatable(copy, DeepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
  end

  __Static__() function ShallowCopy(self, orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
  end

  __Static__() function IsTableEqual(t1, t2, ignoreMT)
   local ty1 = type(t1)
   local ty2 = type(t2)

      if ty1 ~= ty2 then return false end
   -- non-table types can be directly compared
   if ty1 ~= 'table' and ty2 ~= 'table' then return t1 == t2 end
   -- as well as tables which have the metamethod __eq
   local mt = getmetatable(t1)
   if not ignoreMT and mt and mt.__eq then return t1 == t2 end
   for k1,v1 in pairs(t1) do
      local v2 = t2[k1]
      if v2 == nil or not IsTableEqual(v1,v2) then return false end
   end
   for k2,v2 in pairs(t2) do
      local v1 = t1[k2]
      if v1 == nil or not IsTableEqual(v1,v2) then return false end
   end
   return true
 end
end)

--------------------------------------------------------------------------------
--                   Serializable container                                   --
--    Credit goes to Kurapice on the SList,SDictionnary and Stack code        --
--------------------------------------------------------------------------------
__Serializable__()
class "SList" (function(_ENV)
  inherit "List" extend "ISerializable"

  function Serialize(self, info)
    for i, v in ipairs(self) do
      info:SetValue(i, v)
    end
  end

  __Arguments__{ SerializationInfo }
  function __new(_, info)
    local i = 1
    local v = info:GetValue(i)
    local self = {}

    while v ~= nil do
      self[i] = v
      i = i + 1
      v = info:GetValue(i)
    end
    return self, true
  end

  __Arguments__.Rest()
  function __new(_, ...)
    return super.__new(_, ...)
  end
end)

__Serializable__()
class "SDictionary" (function(_ENV)
  inherit "Dictionary" extend "ISerializable"

  function Serialize(self, info)
    local keys = SList()
    local vals = SList()

    for k, v in pairs(self) do
      keys:Insert(k)
      vals:Insert(v)
    end

    info:SetValue(1, keys, SList)
    info:SetValue(2, vals, SList)
  end

  __Arguments__{ SerializationInfo }
  function __new(_, info)
    local keys = info:GetValue(1, SList)
    local vals = info:GetValue(2, SList)

    return super.__new(_, keys, vals)
  end

  __Arguments__.Rest()
  function __new(_, ...)
    return super.__new(_, ...)
  end
end)

class "Stack" (function (_ENV)
    extend "Iterable"

    function Push(self, item)
        table.insert(self, item)
    end

    function Pop(self, item)
        return table.remove(self)
    end

    function GetIterator(self)
        return ipairs(self)
    end
end)

--------------------------------------------------------------------------------
--                                                                            --
--                              DiffMap                                       --
--                                                                            --
--------------------------------------------------------------------------------
class "DiffMap" (function(_ENV)
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { String + Number, Variable.Optional() }
  function SetValue(self, key, value)
    self.values[key] = value
  end

  __Arguments__ { DiffMap, Variable.Optional(Boolean)}
  function Diff(self, other, ignoreTable)
    -- Get a complete keys list to iterate
    local keys = {}

    -- Start with the self object
    for index, key in self.values.Keys:ToList():GetIterator() do
        keys[key] = true
    end

    -- Then with the other object
    for index, key in other.values.Keys:ToList():GetIterator() do
      keys[key] = true
    end

    local changes = {}
    -- Check if there is changes
    for key in pairs(keys) do
      local valueA = self.values[key]
      local valueB = other.values[key]
      local valueChanged = true

      if valueA == nil and valueB == nil then
        valueChanged = false
      elseif valueA ~= nil and valueB ~= nil then
        local typeA = type(valueA)
        local typeB = type(valueB)

        if typeA == typeB then
          if not ignoreTable and typeA == "table" then
            if API:IsTableEqual(valueA, valueB, true) then
              valueChanged = false
            end
          elseif typeA == "string" or typeA == "number" or typeA == "boolean" then
            if valueA == valueB then
              valueChanged = false
            end
          end
        end
      end

      if valueChanged then
        tinsert(changes, key)
      end
    end

    -- Return changes
    return changes
  end
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function DiffMap(self)
    self.values = Dictionary()
  end

end)


class "DisplayRules" (function(_ENV)

  property "showInCombat" { DEFAULT = true }
  property "showInArena" { DEFAULT = true }
  property "showInRaid" { DEFAULT = true }
  property "showInKeystone" { DEFAULT = true }
  property "showInScenario" { DEFAULT = true }
end)
