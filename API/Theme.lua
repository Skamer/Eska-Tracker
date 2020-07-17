--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                     "EskaTracker.API.Theme"                              ""
--============================================================================--
namespace "EKT"
--============================================================================--
import "System.Serialization"
_EKTAddon = _Addon

ValidateFlags = API.ValidateFlags
--------------------------------------------------------------------------------
--                          THEME SYSTEM                                      --
--------------------------------------------------------------------------------
__Serializable__() class "Theme" (function(_ENV)
  extend "ISerializable"
  _REGISTERED_FRAMES = {}

  -- Skin Frame Queue
  _SKIN_FRAME_QUEUE = List()
  _SKIN_FRAME_PROCESS_STARTED = false

  -- Skin Text Queue
  _SKIN_TEXT_QUEUE = List()
  _SKIN_TEXT_PROCESS_STARTED = false

  -- Skin Texture Queue
  _SKIN_TEXTURE_QUEUE = List()
  _SKIN_TEXTURE_PROCESS_STARTED = false
  ------------------------------------------------------------------------------
  --                       Register Methods                                   --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, String, Table, Variable.Optional(String), Variable.Optional(String, "FRAME") }
  __Static__() function RegisterFrame(self, elementID, frame, inheritElementID, type)
    if not frame then
      return
    end

    local frames = _REGISTERED_FRAMES[elementID]
    if not frames then
      frames = setmetatable({}, { __mode = "k"})
      _REGISTERED_FRAMES[elementID] = frames
    end

    if frames[frame] then return end

    frames[frame] = true
    frame.elementID = elementID
    frame.type = type

    if inheritElementID then
      frame.inheritElementID = inheritElementID
    end

    Theme:InstallScript(frame)
  end

  __Arguments__ { ClassType, String, Table, Variable.Optional(String) }
  __Static__() function RegisterTexture(self, elementID, frame, inheritElementID)
    Theme:RegisterFrame(elementID, frame, inheritElementID, "TEXTURE")
  end

  __Arguments__ { ClassType, String, Table, Variable.Optional(String) }
  __Static__() function RegisterText(self, elementID, frame, inheritElementID)
    Theme:RegisterFrame(elementID, frame, inheritElementID, "TEXT")
  end

  __Arguments__ { ClassType, String, String }
  __Static__() function RegisterFont(self, fontID, fontFile)
    if _LibSharedMedia then
      _LibSharedMedia:Register("font", fontID, fontFile)
    end
  end

  ------------------------------------------------------------------------------
  --                     Skin Methods                                         --
  ------------------------------------------------------------------------------
  __Flags__()
  enum "SkinFlags" {
    NONE = 0,
    FRAME_BACKGROUND_COLOR = 1,
    FRAME_BORDER_COLOR = 2,
    FRAME_BORDER_WIDTH = 4,
    TEXT_SIZE = 8,
    TEXT_COLOR = 16,
    TEXT_FONT = 32,
    TEXT_TRANSFORM = 64,
    TEXT_JUSTIFY_HORIZONTAL = 128,
    TEXT_JUSTIFY_VERTICAL = 256,
    TEXTURE_COLOR = 512,
    FRAME_BACKGROUND_TEXTURE = 1024,
    TEXT_FONT_FLAGS = 2048
  }

  DefaultSkinFlags = SkinFlags.FRAME_BACKGROUND_COLOR     +
                      SkinFlags.FRAME_BORDER_COLOR        +
                      SkinFlags.FRAME_BORDER_WIDTH        +
                      SkinFlags.TEXT_SIZE                 +
                      SkinFlags.TEXT_COLOR                +
                      SkinFlags.TEXT_FONT                 +
                      SkinFlags.TEXT_TRANSFORM            +
                      SkinFlags.TEXT_JUSTIFY_HORIZONTAL   +
                      SkinFlags.TEXT_JUSTIFY_VERTICAL     +
                      SkinFlags.TEXTURE_COLOR             +
                      SkinFlags.FRAME_BACKGROUND_TEXTURE  +
                      SkinFlags.TEXT_FONT_FLAGS;

  __Static__() property "DefaultSkinFlags" {
    TYPE    = SkinFlags,
    DEFAULT = DefaultSkinFlags,
    SET     = false
  }

  struct "SkinRequest" (function(_ENV)
    member "obj"              { TYPE = Table }
    member "flags"            { TYPE = SkinFlags }
    member "state"            { TYPE = String }
    member "customElementID"  { TYPE = String }
    member "customParentID"   { TYPE = String }
    member "text"             { TYPE = String }
    member "onEvent"          { TYPE = Function }
  end)

  __Arguments__ { ClassType, Table, Variable.Optional(String) }
  __Static__() function NeedSkin(self, frame, target)
    if target == nil or target == "ALL" then
      return true
    end

    if frame.elementID and frame.elementID == target then
      return true
    end

    return false
  end

  __Arguments__ { ClassType, Table }
  __Static__() function GetElementID(self, frame)
    return frame.elementID
  end

  __Arguments__ { ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String) }
  __Static__() function ProcessSkinFrame(self, frame, flags, state, customElementID, customParentID)
    local theme = Themes:GetSelected()

    if not theme then return end -- TODO: Add error msg
    if not frame then return end -- TODO: Add error msg

    local elementID = customElementID or frame.elementID
    local inheritElementID = customParentID or frame.inheritElementID

    if not elementID then
      return
    end

    if state then
      elementID = elementID.."["..state.."]"
    end

    if frame.type == "FRAME" then
      local color
      -- Background color
      if frame.SetBackdropColor and ValidateFlags(flags, SkinFlags.FRAME_BACKGROUND_COLOR) then
        color = theme:GetElementProperty(elementID, "background-color", inheritElementID)
        frame:SetBackdropColor(color.r, color.g, color.b, color.a)
      end

      -- Background texture
      if ValidateFlags(flags, SkinFlags.FRAME_BACKGROUND_TEXTURE) then
        local background = _LibSharedMedia:Fetch("background", theme:GetElementProperty(elementID, "background-texture", inheritElementID))
        local r,g,b,a = frame:GetBackdropColor()
        frame:SetBackdrop({
          bgFile = background,
          insets = { left = 0, right = 0, top = 0, bottom = 0}
        })

        frame:SetBackdropColor(r, g, b, a)
      end
    end
  end


  __Arguments__ { ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String) }
  __Static__() function SkinFrame(self, frame, flags, state, customElementID, customParentID)
    -- Create the request
    local request = SkinRequest()
    request.obj             = frame
    request.flags           = flags
    request.state           = state
    request.customElementID = customElementID
    request.customParentID  = customParentID

    -- Add in the queue of skin procress
    _SKIN_FRAME_QUEUE:Insert(request)

    -- Run skin process
    if not _SKIN_FRAME_PROCESS_STARTED then
      self:RunSkinFrameProcess()
    end
  end

  __Async__()
  __Static__() function RunSkinFrameProcess(self)
    if _SKIN_FRAME_PROCESS_STARTED then
      return
    end

    _SKIN_FRAME_PROCESS_STARTED = true
    while _SKIN_FRAME_QUEUE.Count >= 1 do
      local request = _SKIN_FRAME_QUEUE:RemoveByIndex(1)
      if request then
        self:ProcessSkinFrame(request.obj, request.flags, request.state, request.customElementID, request.customParentID)
      end
      Continue()
    end
    _SKIN_FRAME_PROCESS_STARTED = false
  end

  __Arguments__ { ClassType, String, String, Variable.Optional(String), Variable.Optional(String) }
  __Static__() function GetTransformedText(self, text, elementID, state, parentID)
    local theme = Themes:GetSelected()

    if state then
      elementID = elementID.."["..state.."]"
    end

    local transform = theme:GetElementProperty(elementID, "text-transform", parentID)
    if transform == "uppercase" then
      text = text:upper()
    elseif transform == "lowercase" then
      text = text:lower()
    end

    return text
  end

  __Arguments__ { ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String + Number), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String), Variable.Optional(Function) }
  __Static__() function ProcessSkinText(self, obj, flags, text, state, customElementID, customParentID, onEventCallback)
    local theme = Themes:GetSelected()

    if not theme then return end -- TODO: Add error msg
    if not obj then return end   -- TODO: Add error msg

    local fontstring
    if obj.type == "FRAME" then
      fontstring = obj.text
    else
      fontstring = obj
    end
    if not fontstring then return end -- TODO: Add error msg

    local elementID = customElementID or fontstring.elementID
    local inheritElementID = customParentID or fontstring.inheritElementID


    if not elementID then return end  -- TODO: Add error msg

    if state then
      elementID = elementID.."["..state.."]"
    end

    -- REMOVE:
    local font, size, fontFlags = fontstring:GetFont()
    if not font then
      flags = API:AddFlag(flags, SkinFlags.TEXT_FONT)
      flags = API:AddFlag(flags, SkinFlags.TEXT_SIZE)
      flags = API:AddFlag(flags, SkinFlags.TEXT_FONT_FLAGS)
    end

    local textColor = {}
    textColor.r, textColor.g, textColor.b, textColor.a = fontstring:GetTextColor()

    if ValidateFlags(flags, SkinFlags.TEXT_SIZE) then
      size = theme:GetElementProperty(elementID, "text-size", inheritElementID)
    end

    if ValidateFlags(flags, SkinFlags.TEXT_FONT) then
      font = _LibSharedMedia:Fetch("font", theme:GetElementProperty(elementID, "text-font", inheritElementID))
    end

    if ValidateFlags(flags, SkinFlags.TEXT_FONT_FLAGS) then 
      fontFlags = theme:GetElementProperty(elementID, "text-font-flags", inheritElementID)
    end

    fontstring:SetFont(font, size, fontFlags)

    if ValidateFlags(flags, SkinFlags.TEXT_COLOR) then
      textColor = theme:GetElementProperty(elementID, "text-color", inheritElementID)
    end
    fontstring:SetTextColor(textColor.r, textColor.g, textColor.b, textColor.a)

    if ValidateFlags(flags, SkinFlags.TEXT_JUSTIFY_HORIZONTAL) then
      fontstring:SetJustifyH(theme:GetElementProperty(elementID, "text-justify-h", inheritElementID))
    end

    if ValidateFlags(flags, SkinFlags.TEXT_JUSTIFY_VERTICAL) then
      fontstring:SetJustifyV(theme:GetElementProperty(elementID, "text-justify-v", inheritElementID))
    end

    -- Check if we need to transform the text
    local needTextTransform = true
    local fontstringText = fontstring:GetText()
    if not text or type(text) == "number" then
      needTextTransform = false
    elseif fontstringText and text:lower() == fontstringText:lower() then
      needTextTransform = false
    end

    if needTextTransform then
      API:AddFlag(flags, SkinFlags.TEXT_TRANSFORM)
    end

    if not text then
      text = fontstringText
    end

    if ValidateFlags(flags, SkinFlags.TEXT_TRANSFORM) then
      if text then
        if text == "" then
          fontstring:SetText(text)
        else
          local transform = theme:GetElementProperty(elementID, "text-transform", inheritElementID)
          if transform == "uppercase" then
            text = text:upper()
          elseif transform == "lowercase" then
            text = text:lower()
          end
          fontstring:SetText(text)
        end
      end
    end

    if onEventCallback then
      onEventCallback("SKIN_PROCESS_FINISHED")
    end
  end

  __Arguments__ { ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String + Number), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String), Variable.Optional(Function) }
  __Static__() function SkinText(self, obj, flags, text, state, customElementID, customParentID, onEventCallback)
    -- Create the request
    local request = SkinRequest()
    request.obj             = obj
    request.flags           = flags
    request.state           = state
    request.customElementID = customElementID
    request.customParentID  = customParentID
    request.text            = text
    request.onEvent         = onEventCallback

    -- Add in the queue of skin procress
    _SKIN_TEXT_QUEUE:Insert(request)

    -- Run skin process
    if not _SKIN_TEXT_PROCESS_STARTED then
      self:RunSkinTextProcess()
    end
  end

  __Async__()
  __Static__() function RunSkinTextProcess(self)
    if _SKIN_TEXT_PROCESS_STARTED then
      return
    end

    _SKIN_TEXT_PROCESS_STARTED = true
    while _SKIN_TEXT_QUEUE.Count >= 1 do
      local request = _SKIN_TEXT_QUEUE:RemoveByIndex(1)
      if request then
        self:ProcessSkinText(request.obj, request.flags, request.text, request.state, request.customElementID, request.customParentID, request.onEvent)
      end
      Continue()
    end

    _SKIN_TEXT_PROCESS_STARTED = false
  end

  __Arguments__{ ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String) }
  __Static__() function ProcessSkinTexture(self, obj, flags, state, customElementID, customParentID)
    local theme = Themes:GetSelected()

    if not theme then return end -- TODO: Add error msg
    if not obj then return end -- TODO: Add error msg

    local texture
    if obj.type == "FRAME" then
      texture = obj.texture
    else
      texture = obj
    end

    if not texture then return end -- TODO: Add error msg

    local elementID = customElementID or texture.elementID
    local inheritElementID = customParentID or texture.inheritElementID

    if not elementID then return end -- TODO: Add error msg

    if state then
      elementID = elementID.."["..state.."]"
    end

    if ValidateFlags(flags, SkinFlags.TEXTURE_COLOR) then
      local color = theme:GetElementProperty(elementID, "texture-color", inheritElementID)
      texture:SetVertexColor(color.r, color.g, color.b, color.a)
    end
  end

  __Arguments__{ ClassType, Table, Variable.Optional(SkinFlags, DefaultSkinFlags), Variable.Optional(String), Variable.Optional(String), Variable.Optional(String) }
  __Static__() function SkinTexture(self, obj, flags, state, customElementID, customParentID)
    -- Create the request
    local request = SkinRequest()
    request.obj             = obj
    request.flags           = flags
    request.state           = state
    request.customElementID = customElementID
    request.customParentID  = customParentID

    -- Add in the queue of skin procress
    _SKIN_TEXTURE_QUEUE:Insert(request)

    -- Run skin process
    if not _SKIN_TEXTURE_PROCESS_STARTED then
      self:RunSkinTextureProcess()
    end
  end

  __Async__()
  __Static__() function RunSkinTextureProcess(self)
    if _SKIN_TEXTURE_PROCESS_STARTED then
      return
    end

    _SKIN_TEXTURE_PROCESS_STARTED = true
    while _SKIN_TEXTURE_QUEUE.Count >= 1 do
      local request = _SKIN_TEXTURE_QUEUE:RemoveByIndex(1)
      if request then
        self:ProcessSkinTexture(request.obj, request.flags, request.state, request.customElementID, request.customParentID)
      end
      Continue()
    end
    _SKIN_TEXTURE_PROCESS_STARTED = false
  end
  ------------------------------------------------------------------------------
  --              Element Property Methods                                    --
  ------------------------------------------------------------------------------
  __Flags__()
  enum "ElementFlags" {
    INCLUDE_PARENT = 1,
    INCLUDE_DATABASE = 2,
    INCLUDE_DEFAULT_VALUES = 4,
    INCLUDE_STATE = 8,
    IGNORE_WITHOUT_STATE = 16
  }

  __Arguments__ { String, String , String }
  function SetElementLink(self, elementID, property, destElementID)
    local links = self.links[elementID] or SDictionary()
    links[property] = destElementID

    if not self.links[elementID] then
      self.links[elementID] = links
    end
  end

  __Arguments__ { String, String }
  function GetElementLink(self, elementID, property)
    return  self.links[elementID] and self.links[elementID][property]
  end

  __Arguments__ { String }
  function ClearElementLinks(self, elementID)
    local links = self.links[elementID]
    if links then
      for k,v in links:GetIterator() do links[k] = nil end
      self.links[elementID] = nil
      links = nil
    end
  end

  __Arguments__ {}
  function ClearAllElementLinks(self)
    for elementID, links in self.links:GetIterator() do
      for k,v in links:GetIterator() do links[k] = nil end
      self.links[elementID] = nil
      links = nil
    end
  end


  function SetElementPropertyLink(self, elementID, property, destElementID)
    --elementID = elementID:gsub("%s+", "") -- Remove the space
      -- Get the possible element Ids
      local IDs =  { Theme:GetPossibleElementIDs(elementID) }
      for _, id in ipairs(IDs) do
        local elementProps = self.properties[id] or SDictionary()
        elementProps[property] = value

        if not self.properties[id] then
          self.properties[id] = elementProps
        end
      end

  end

  __Arguments__ { String, String, Variable.Optional(String), Variable.Optional(ElementFlags, 15)}
  function GetElementProperty(self, elementID, property, inheritElementID, flags)
      --elementID = elementID:gsub("%s+", "") -- Remove the space

      local value
      if ValidateFlags(flags, ElementFlags.INCLUDE_DATABASE) then
        value = self:GetElementPropertyFromDB(elementID, property)
        if value then
          return value
        end
      end

      value = self.properties[elementID] and self.properties[elementID][property]
      if value then
        return value
      end

      if not ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
        if ValidateFlags(flags,ElementFlags.INCLUDE_DEFAULT_VALUES) then
          return Theme:GetDefaultProperty(property)
        end
        return value
      end

      local elementLink = self:GetElementLink(elementID, property)
      if elementLink then
        value = self:GetElementPropertyFromDB(elementLink, property)
        if value then
          return value
        end

        value = self.properties[elementLink] and self.properties[elementLink][property]
        if value then
          return value
        end
      else
        for _, id in Theme:GetReadingIDList(elementID, inheritElementID, flags):GetIterator() do
            if ValidateFlags(flags, ElementFlags.INCLUDE_DATABASE) then
              value = self:GetElementPropertyFromDB(id, property)
              if value then
                self:SetElementLink(elementID, property, id)
                return value
              end
            end

            value = self.properties[id] and self.properties[id][property]
            if value then
              self:SetElementLink(elementID, property, id)
              return value
            end
        end
      end

      if ValidateFlags(flags, ElementFlags.INCLUDE_DEFAULT_VALUES) then
        return Theme:GetDefaultProperty(property)
      end
  end

  __Arguments__{ String, String, Variable.Optional() }
  function SetElementProperty(self, elementID, property, value)
    -- NOTE Make the *
    --elementID = elementID:gsub("%s+", "") -- Remove the space
      -- Get the possible element Ids
      local IDs =  { Theme:GetPossibleElementIDs(elementID) }
      for _, id in ipairs(IDs) do
        local elementProps = self.properties[id] or SDictionary()
        elementProps[property] = value

        if not self.properties[id] then
          self.properties[id] = elementProps
        end
      end

      self:ClearAllElementLinks()
  end

  __Arguments__ { String, Any }
  function SetElementProperty(self, property, value)
    SetElementProperty(self, "*", property, value)
  end



  -- ElementFlags (3) = INCLUDE_PARENT (1) + INCLUDE_DATABASE (2)
  __Arguments__{ String, String, Variable.Optional(String), Variable.Optional(ElementFlags, 3) }
  function ElementHasState(self, elementID, state, inheritElementID, flags)
    flags = flags + ElementFlags.IGNORE_WITHOUT_STATE + ElementFlags.INCLUDE_STATE
    elementID = string.format("%s[%s]", elementID, state)

    for _, id in Theme:GetReadingIDList(elementID, inheritElementID, flags):GetIterator() do
      if ValidateFlags(flags, INCLUDE_DATABASE) and self:ElementExistsFromDB(id) then
        return true
      end

      if self.properties[id] then return true end
    end

    return false
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetDefaultProperty(self, property)
      local defaults = {
        ["background-color"] = { r = 0, g = 0, b = 0 },
        ["background-texture"] = "EskaTracker Background",
        ["border-color"] = { r = 0, g = 0, b = 0 },
        ["border-width"] = 2,
        ["offsetX"] = 0,
        ["offsetY"] = 0,
        ["text-size"] = 10,
        ["text-font"] = "PT Sans Bold",
        ["text-color"] = { r = 0, g = 0, b = 0},
        ["text-transform"] = "none",
        ["text-location"] = "CENTER",
        ["text-offsetX"] = 0,
        ["text-offsetY"] = 0,
        ["text-justify-h"] = "LEFT",
        ["text-justify-v"] = "MIDDLE",
        ["text-font-flags"] = "NONE",
        ["vertex-color"] = { r = 1, g = 1, b = 1},
        ["texture-color"] = { r = 1, g = 1, b = 1}
      }

      return defaults[property]
  end

  __Arguments__ { String, String }
  function GetElementPropertyFromDB(self, elementID, property)
    Database:SelectRoot()

    if Database:SelectTable(false, "themes", self.name, "properties", elementID) then
      return Database:GetValue(property)
    end
  end

  __Arguments__ { String, String, Variable.Optional() }
  function SetElementPropertyToDB(self, elementID, property, value)
    Database:SelectRoot()

    if Database:SelectTable(true, "themes", self.name, "properties", elementID) then
      Database:SetValue(property, value )
    end

    self:ClearAllElementLinks()
  end

  __Arguments__ { String }
  function ElementExistsFromDB(self, elementID)
    Database:SelectRoot()

    if Database:SelectTable(false, "themes", self.name, "properties", elementID) then
      return true
    end

    return false
  end

  ------------------------------------------------------------------------------
  --                        Helper Methods                                    --
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, Table }
  __Static__() function InstallScript(self, frame)
    if not frame.GetScript or not frame.SetScript then
      return
    end
  end

  __Arguments__ { ClassType, String, Variable.Optional(String), Variable.Optional(ElementFlags, 9) }
  __Static__() function GetReadingIDList(self, elementID, inheritElementID, flags)
    local rawElementID, states = self:RemoveStates(elementID)
    local categories = { strsplit(".", rawElementID) }
    local list = List()

    local parentIDs, parentIDNum
    if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
      if inheritElementID then
        parentIDs = { strsplit(".", inheritElementID) }
        parentIDNum = #parentIDs
      end
    end


    -- We start to create the list without state
    local currentID = ""
    if not ValidateFlags(flags, ElementFlags.IGNORE_WITHOUT_STATE) then
      if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
        list:Insert("*")
      end
      for index, category in ipairs(categories) do
        if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
          if parentIDNum and parentIDNum == index then
            list:Insert(inheritElementID)
          end
        end

        if index ~= #categories then
          if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
            if inheritElementID then
              list:Insert(parentIDs[index]..".*")
            end
            list:Insert(currentID..category..".*")
          end
        else
          list:Insert(currentID..category)
        end
        currentID = currentID .. category .. "."
      end
    end

    -- Then we do the same things with the state if exists
    if ValidateFlags(flags, ElementFlags.INCLUDE_STATE) then
      if states then
        currentID = ""
        if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
          list:Insert("*"..states)
        end
        for index, category in ipairs(categories) do
          if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
            if parentIDNum and parentIDNum == index then
              list:Insert(inheritElementID..states)
            end
          end

          if index ~= #categories then
            if ValidateFlags(flags, ElementFlags.INCLUDE_PARENT) then
              if inheritElementID then
                list:Insert(parentIDs[index]..".*"..states)
              end

              list:Insert(currentID..category..".*"..states)
            end
          else
            list:Insert(currentID..category..states)
          end
          currentID = currentID .. category .. "."

        end
      end
    end
    return list:Range(-1, 1, -1):ToList()
  end

  __Arguments__ { ClassType, String, Variable.Optional(Boolean, false) }
  __Static__() function GetElementNameFromString(self, str, includeFlags)

    local categories = {strsplit(".", str) }
    if includeFlags then
      return categories[#categories]
    else
      local elementName = categories[#categories]
      local elementName = elementName:gsub("(%[[@,|%w]*%])", "")
      return elementName
    end
  end

  __Arguments__ { ClassType, String}
  __Static__() function RemoveStates(self, str)
    local states = str:match("(%[[,|%w]*%])")
    local str =  str:gsub("(%[[,|%w]*%])", "")
    return str, states
  end

  ------------------------------------------------------------------------------
  --         EXPERIMETAL
  ------------------------------------------------------------------------------
  __Arguments__ { ClassType, String }
  __Static__() function GetValidID(self, id)
    -- Trim the string
    id = API:Trim(id)

    -- Get the states
    local states = id:match("%[([,%w]*)%]")
    -- Remove the states
    local idWithoutStates = id:gsub("(%[[,|%w]*%])", "")
    --
    local statesString = ""

    -- Order the states in the right order (hover is always first, then is ordered by alphabetically)
    if states then
      local stateList = List(strsplit(",", states))
      local function SortStates(a,b)
        if a == "hover" then
          return true
        elseif b == "hover" then
          return false
        else
          return a < b
        end
      end
      for index, state in stateList:Sort(SortStates):GetIterator() do
        if index == 1 then
          statesString = state
        else
          statesString = statesString .. "," .. state
        end
      end
    end

    -- Build the complete valid id
    if states and states ~= "" then
      id = string.format("%s[%s]", idWithoutStates, statesString)
    else
      id = idWithoutStates
    end

    return id, idWithoutStates, statesString
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetPossibleElementIDs(self, str)
    local elementID = self:GetValidID(str)
    return elementID
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetReadingStateList(self, states)
    local hasHover = false
    local otherState = ""
    local index = 0
    for i, state in List(strsplit(",", states)):GetIterator() do
      if state == "hover" then
        hasHover = true
      else
        otherState = state
      end
      index = i
    end

    if hasHover then
      if index > 1 then
        return List("["..otherState.."]", "[hover]", string.format("[hover,%s]",otherState))
      else
        return List("[hover]")
      end
    else
      return List("["..otherState.."]")
    end
  end

  __Arguments__ { Variable.Optional(Boolean, true) }
  function ExportToText(self, includeDB)


    local theme = Theme(self)
    theme.name = self.name
    theme.author = self.author
    theme.verison = self.version
    theme.stage = self.stage

    if includeDB and self.lua then
      Database:SelectRoot()
      if Database:SelectTable(false, "themes", self.name, "properties") then
        for elementID, properties in Database:IterateTable() do
          for property, value in pairs(properties) do
            local copy = API:ShallowCopy(value)
            theme:SetElementProperty(elementID, property, copy)
          end
        end
      end
    end

    local data = Serialization.Serialize( StringFormatProvider(), theme)
    local compressedData = API:Compress(data)
    local encode = API:EncodeToBase64(compressedData)
    return encode
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetFromText(self, text)
    -- decode from base 64
    local decode = API:DecodeFromBase64(text)
    local decompress, msg = API:Decompress(decode)

    if not decompress then
      return nil, "Error decompressing: ".. msg
    end

    local isOK, theme = pcall(Serialization.Deserialize, StringFormatProvider(), decompress, Theme)
    if isOK then
      return theme
    else
      return nil, "Error deserializing"
    end
  end

  function MovePropertiesToDB(self)
    for elementID, properties in self.properties:GetIterator() do
      if properties then
        for property, value in properties:GetIterator() do
          self:SetElementPropertyToDB(elementID, property, value)
        end
      end
    end
    self.properties = SDictionary()
  end

  function SyncToDB(self)
    if not self.lua then
      Database:SelectRoot()
      if Database:SelectTable(true, "themes", self.name) then
        Database:SetValue("name", self.name)
        Database:SetValue("author", self.author)
        Database:SetValue("stage", self.stage)
        Database:SetValue("version", self.version)
      end
    end
  end

  function SetAuthor(self, author)
    -- If the theme isn't created from lua file, we need persist the value in the DB
    if not self.lua then
      Database:SelectRoot()

      if Database:SelectTable(true, "themes", self.name) then
        Database:SetValue("author", author)
      end
    end

    self.__author = author
  end

  function SetVersion(self, version)
    -- If the theme isn't created from lua file, we need persist the value in the DB
    if not self.lua then
      Database:SelectRoot()

      if Database:SelectTable(true, "themes", self.name) then
        Database:SetValue("version", version)
      end
    end

    self.__version = version
  end

  function SetName(self, name)
    -- If the theme isn't created from lua file, we need persist the value in the DB
    if not self.lua then
      Database:SelectRoot()
      if Database:SelectTable(true, "themes", name) then
        Database:SetValue("name", name)
        Database:MoveTable("themes", name)
      end

    end

    self.__name = name
  end

  function SetStage(self, stage)
    -- If the theme isn't created from lua file, we need persist the value in the DB
    if not self.lua then
      Database:SelectRoot()

      if Database:SelectTable(true, "themes", self.name) then
        Database:SetValue("stage", stage)
      end
    end

    self.__stage = stage
  end

  property "author" { TYPE = String, SET = "SetAuthor", GET = function(self) return self.__author end }
  property "version" { TYPE = String, DEFAULT = "1.0.0", SET = "SetVersion", GET = function(self) return self.__version end }
  property "name" {  TYPE = String, SET = "SetName", GET = function(self) return self.__name end }
  property "stage" { TYPE = String, DEFAULT = "Release", SET = "SetStage", GET = function(self) return self.__stage end }
  property "lua" { TYPE = Boolean, DEFAULT = true}

  function Serialize(self, info)
    info:SetValue("name", self.name, String)
    info:SetValue("author", self.author, String)
    info:SetValue("version", self.version, String)
    info:SetValue("stage", self.stage, String)
    info:SetValue("func", self.func, String)

    info:SetValue("properties", self.properties, SDictionary)
    info:SetValue("scripts", self.scripts, SDictionary)
    info:SetValue("options", self.options, SDictionary)

  end

  __Flags__()
  enum "OverrideFlags" {
    NONE = 0,
    OVERRIDE_THEME_INFO = 1,
  }

  __Flags__()
  enum "SourceFlags" {
    NONE = 0,
    DATABASE = 1,
    LUA_TABLE = 2,
  }

  __Arguments__ { Theme, Variable.Optional(SourceType, SourceFlags.DATABASE + SourceFlags.LUA_TABLE), Variable.Optional(OverrideFlags, OverrideFlags.OVERRIDE_THEME_INFO) }
  function Override(self, theme, sourceFlags, overrideFlags)
    if ValidateFlags(overrideFlags, OverrideFlags.OVERRIDE_THEME_INFO) then
      self.name = theme.name
      self.author = theme.author
      self.version = theme.version
      self.stage = theme.stage
    end

    if ValidateFlags(sourceFlags, SourceFlags.LUA_TABLE) then
      for elementID, properties in theme.properties:GetIterator() do
        for property, value in properties:GetIterator() do
          self:SetElementPropertyToDB(elementID, property, API:ShallowCopy(value))
        end
      end
    end

    if ValidateFlags(sourceFlags, SourceFlags.DATABASE) then
      Database:SelectRoot()
      if Database:SelectTable(false, "themes", theme.name, "properties") then
        for elementID, properties in Database:IterateTable() do
          for property, value in pairs(properties) do
            self:SetElementPropertyToDB(elementID, property, API:ShallowCopy(value))
          end
        end
      end
    end
  end

  --[[__Arguments__ { Theme }
  function Override(self, theme)
    self.name = theme.name
    self.author = theme.name
    self.version = theme.version
    self.stage = theme.stage

    for elementID, properties in theme.properties:GetIterator() do
      for property, value in properties:GetIterator() do
        self:SetElementPropertyToDB(elementID, property, API:ShallowCopy(value))
      end
    end
  end--]]



  __Arguments__{}
  function Theme(self)
    self.properties = SDictionary()
    self.scripts = SDictionary()
    self.options = SDictionary()

    self.links = SDictionary() -- used as cache to improve get performance
  end

  __Arguments__{ SerializationInfo }
  function Theme(self, info)
    this(self)

    self.name = info:GetValue("name", String)
    self.author = info:GetValue("author", String)
    self.version = info:GetValue("version", String)
    self.stage = info:GetValue("stage", String)

    self.properties = info:GetValue("properties", SDictionary)
  end

  __Arguments__ { Theme, Variable.Optional(Boolean, true) }
  function Theme(self, orig)
    this(self)

    if orig.lua then
      for elementID, properties in orig.properties:GetIterator() do
        for property, value in properties:GetIterator() do
          local copyValue = API:ShallowCopy(value)
          self:SetElementProperty(elementID, property, copyValue)
        end
      end
    else
      Database:SelectRoot()
      if Database:SelectTable(false, "themes", orig.name, "properties") then
        for elementID, properties in Database:IterateTable() do
          for property, value in pairs(properties) do
            local copyValue = API:ShallowCopy(value)
            self:SetElementProperty(elementID, property, copyValue)
          end
        end
      end
    end
  end

end)

class "Themes" (function(_ENV)
  _CURRENT_THEME = nil
  _THEMES = Dictionary()

  __Arguments__ { ClassType, Theme }
  __Static__() function Register(self, theme)
    if not _THEMES[theme.name] then
      _THEMES[theme.name] = theme

      Scorpio.FireSystemEvent("EKT_THEME_REGISTERED", theme)
    end
  end

  __Arguments__ { ClassType, String, Variable.Optional(Boolean, true) }
  __Static__() function Select(self, themeName, saveInDB)
    local theme = _THEMES[themeName]
    if theme then
      _CURRENT_THEME = theme

      if saveInDB then
        Settings:Set("theme-selected", themeName)
      end

      Frame:SkinAll()
    end
  end

  __Arguments__ { ClassType }
  __Static__() function GetSelected(self)
    -- In case where no theme has been selected
    if not _CURRENT_THEME then
      -- Check in the DB if the user has selected a theme
      local selected = Settings:Get("theme-selected")
      -- The user has slected a theme
      if selected then
        _CURRENT_THEME = self:Get(selected)
        -- If the selected theme isn't available, return the first
        if not _CURRENT_THEME then
          _CURRENT_THEME = self:GetFirst()
        end
      else
        _CURRENT_THEME = self:GetFirst()
      end
    end

    return _CURRENT_THEME
  end

  __Arguments__ { ClassType }
  __Static__() function ClearSelectedCache(self)
    _CURRENT_THEME = nil
  end

  __Arguments__ { ClassType }
  __Static__() function GetIterator(self)
    return _THEMES:GetIterator()
  end

  __Arguments__ { ClassType, String }
  __Static__() function Get(self, name)
    for _, theme in _THEMES:GetIterator() do
      if theme.name == name then
        return theme
      end
    end
  end

  __Arguments__  { ClassType }
  __Static__() function GetFirst(self)
    for _, theme in _THEMES:GetIterator() do return theme end
  end

  __Arguments__ { ClassType }
  __Static__() function LoadFromDB(self)
    Database:SelectRoot()

    if Database:SelectTable(false, "themes") then
      for name, themeDB in Database:IterateTable() do
        local name = themeDB.name
        local author = themeDB.author
        local version = themeDB.version
        local stage = themeDB.stage
        -- if the theme has these four properties, this say it not a lua theme.
        if name and author and version and stage then
          local theme = Theme()
          theme.name = name
          theme.author = author
          theme.version = version
          theme.stage = stage
          -- @NOTE It's important to edit the lua variable to last to avoid to useless sync with DB while loading.
          theme.lua = false -- [IMPORTANT]

          self:Register(theme)
        end
      end
    end
  end

  enum "ThemeCreateError" {
    ThemeAlreadyExists = 1,
    ThemeToCopyNotExists = 2,
  }



  -- Create a DB Theme, it hightly advised to use this function
  __Arguments__ { ClassType, String, String, String, String, Variable.Optional(String, "none"), Variable.Optional(Boolean, false) }
  __Static__() function CreateDBTheme(self, name, author, version, stage, themeToCopy, includeDB )
    -- Check if a theme already exists before to continue
    Database:SelectRoot()
    if Database:SelectTable(false, "themes", name) then
      return nil, Themes.ThemeAlreadyExists, "A theme with this name already exists."
    end

    Database:SelectRoot()
    if Database:SelectTable(true, "themes", name) then
      if themeToCopy == "none" then
        local theme = Theme()
        theme.lua = false
        theme.name = name
        theme.author = author
        theme.version = version
        theme.stage = stage

        self:Register(theme)
        return theme
      else
        local parentTheme = self:Get(themeToCopy)
        if not parentTheme then return nil, Themes.ThemeToCopyNotExists,"The theme to copy not exists." end

      -- If the theme copied is a lua theme
        if parentTheme.lua then
          --[[local theme = Theme(parentTheme)
          theme.lua = false
          theme.name = name
          theme.author = author
          theme.version = version
          theme:MovePropertiesToDB()
          self:Register(theme) --]]

          ---------
          local theme = Theme()
          theme.lua = false
          theme.name = name
          theme.author = author
          theme.version = version
          theme.stage = stage

          if includeDB then
              theme:Override(parentTheme, nil, Theme.OverrideFlags.NONE)
          else
              theme:Override(parentTheme, Theme.SourceFlags.DATABASE, Theme.OverrideFlags.NONE)
          end
          self:Register(theme)
        else
          local theme = Theme()
          theme.lua     = false
          theme.name    = name
          theme.author  = author
          theme.version = version
          theme.stage   = stage

          theme:Override(parentTheme, nil, Theme.OverrideFlags.NONE)
          self:Register(theme)
        end
      end
    end
  end


  __Arguments__ { ClassType, String }
  __Static__() function Delete(self, name)
    local theme = self:Get(name)
    if theme and theme.lua == false then
      Database:SelectRoot()
      if Database:SelectTable(false, "themes", theme.name) then
        Database:DeleteTable()
        _THEMES[name] = nil

        Scorpio.FireSystemEvent("EKT_THEME_DELETED", theme)
        return true
      end
    end

    return false
  end

  __Arguments__ { ClassType, String, Variable.Optional(String) }
  __Static__() function Import(self, importText, destName)
    local theme, msg = Theme:GetFromText(importText)
    if theme then
      if destName then
        theme.name = destName
      end
      theme.lua = false
      theme:SyncToDB()
      theme:MovePropertiesToDB()
      self:Register(theme)
    end
  end

  function Override(self, importText)
    local overrideTheme = Theme:GetFromText(importText)
    local theme = Themes:Get(overrideTheme.name)
    if theme then
      theme:Override(overrideTheme)

      if theme.name == Themes:GetSelected().name then
        CallbackHandlers:CallGroup("refresher")
      end
    end
  end


  __Arguments__ { ClassType }
  __Static__() function Print(self)
    print("----[[ Themes ]]----")
    local i = 1
    for _, theme in _THEMES:GetIterator() do
      print(i, "Name:", theme.name, " | Author:", theme.author, " | Version:", theme.version, " | Stage:", theme.stage, " | LUA:", theme.lua)
      i = i + 1
    end
    print("--------------------")
  end


end)

function CheckSelectedTheme(tracker)
  local selected = Settings:Get("theme-selected")
  if selected and selected == tracker.name then
    if selected ~= Themes:GetSelected().name then
      Themes:Select(selected, false)
    end
  end
end


__SystemEvent__()
function EKT_PROFILES_LOADED()
  _M:RegisterEvent("EKT_THEME_REGISTERED", CheckSelectedTheme)
  Themes:LoadFromDB()

  Scorpio.FireSystemEvent("EKT_THEMES_LOADED")
end
