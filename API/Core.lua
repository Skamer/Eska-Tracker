-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
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

  function AddFlag(self, flags, flag)
    if not Enum.ValidateFlags(flags, flag) then
      flags = flags + flag
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


class "DisplayRules" (function(_ENV)

  property "showInCombat" { DEFAULT = true }
  property "showInArena" { DEFAULT = true }
  property "showInRaid" { DEFAULT = true }
  property "showInKeystone" { DEFAULT = true }
  property "showInScenario" { DEFAULT = true }
end)
