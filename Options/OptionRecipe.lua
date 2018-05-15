--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio          "EskaTracker.Options.OptionRecipe"                           ""
--============================================================================--
namespace                        "EKT"
--============================================================================--
_Module = _M
--------------------------------------------------------------------------------
--                                                                            --
--                           Option Context                                   --
--                                                                            --
--------------------------------------------------------------------------------
class "OptionContext" (function(_ENV)
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  __Arguments__ { String, Variable.Optional() }
  function SetVariable(self, name, value)
    if not self.__variables then
      self.__variables = {}
    end

    self.__variables[name] = value
  end

  function GetVariable(self, name)
    if self.__variables then
      return self.__variables[name]
    end
  end


  __Arguments__ { String, Variable.Optional(Number, 1), Variable.Optional(Number) }
  function IncrementVariable(self, var, amountToIncrement, max)
    local value = self:GetVariable(var) + 1

    if max and value > max then
      value = max
    end

    self:SetVariable(var, value)
  end
  ------------------------------------------------------------------------------
  --                          Meta-Methods                                    --
  ------------------------------------------------------------------------------
  function __call(self, var)
    local value = self:GetVariable(var)

    if value then return value end

    return OptionBuilder:GetVariable(var)
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "parentWidget" { TYPE = Table, DEFAULT = nil }
  property "parentRecipe" { TYPE = OptionRecipe, DEFAULT = nil }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  __Arguments__ { Table, Variable.Optional(OptionRecipe), Variable.Optional(OptionContext) }
  function OptionContext(self, parentWidget, parentRecipe, context)
    self.parentWidget = parentWidget
    self.parentRecipe = parentRecipe

    if context then
      if context.__variables then
        for k, v in pairs(context.__variables) do
          self:SetVariable(k, API:DeepCopy(v))
        end
      end

      local i = self("i") or 0
      i = i + 1
      self:SetVariable("i", i)
    else
      self:SetVariable("i", 1)
    end
  end

  __Arguments__ {}
  function OptionContext(self) end

end)
--------------------------------------------------------------------------------
--                                                                            --
--                           Option Recipe                                    --
--                                                                            --
--------------------------------------------------------------------------------
class "OptionRecipe" (function(_ENV)

  __Default__("NONE")
  enum "BuildingGroupDelimiterType" {
    "NONE",
    "OR",
    "AND",
    "AND_WITH_ORDER"
  }


  _EVENTS        = {}
  _RECIPE_EVENTS = {}
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    self.context = context
  end

  __Arguments__ {}
  function ResolveGroup(self)
    local result = string.gsub(self.buildingGroup, ":([%w_]*):", function(var)
      return self.context(var)
    end)

    return result
  end

  __Arguments__ {}
  function ResolveBuildingGroup(self)
    local needCache = false
    local list

    -- 1. We check if there is a class/and/or/order delimiter
    --print(ResolveGroup, self.buildingGroup, self.__buildingGroup, self._buildingGroup)
    -- TODO: Adding new character if needed here: %-
    local result = string.gsub(self.buildingGroup, "%[([:_&%w%-]*)%]", function(var)
      needCache = true -- so if we are here, we need to use cache for speeding up things
      if not list then
        list = {  strsplit("&", var) }
        self._buildingGroupDelimiterType = BuildingGroupDelimiterType.AND
        return "%s"
      end
      -- TODO Add '|' '>' delimiters
    end)

    -- 2. Check if a cache is needed, make it if yes
    if needCache then
      -- Reset/Create the class, depend of context
      self._buildingGroupCache = {}
      for index, str in pairs(list) do
        local final = string.format(result, str)
        tinsert(self._buildingGroupCache, final)
      end
    else
      -- Clear the cache if there is exists and is needed
      if self._buildingGroupCache then
        self._buildingGroupCache = nil
      end
    end

    -- NOTE: The ':' (e.g, :variable_name: or :id:) is interpreted when the user
    -- call 'GetBuildingRecipes' so during the build process.
  end


  __Arguments__{ String }
  function ReplaceVariablesFromString(self, str)
    local result = string.gsub(str, ":([%w_]*):", function(var)
      if self.context then
        return self.context(var)
      end
    end)
    return result
  end




  __Arguments__ {}
  function GetRecipes(self)
    if not self.buildingGroup then
      return
    end

    -- if a cache is availaible, this is because there is a class, '&', '|' and '>'
    -- delimiters
    if self._buildingGroupCache then
      -- For '&' and '>' delimiters
      if (self._buildingGroupDelimiterType == BuildingGroupDelimiterType.AND) or
         (self._buildingGroupDelimiterType == BuildingGroupDelimiterType.AND_WITH_ORDER) then
        local list = List()
        for _, group in ipairs(self._buildingGroupCache) do
          group = self:ReplaceVariablesFromString(group)
          local recipes = OptionBuilder:GetRecipes(group)
          if recipes then
            for _, recipe in recipes:GetIterator() do
              list:Insert(recipe)
            end
          end
        end
        -- NOTE: AND_WITH_ORDER says only this is the delimiter type '>' representing in which direction group are built
        -- Unlike to AND ('&' delimiter) that will merge the groups (order included).
        if self._buildingGroupDelimiterType == BuildingGroupDelimiterType.AND then
          return list:Sort("a,b=>a.order<b.order")
        else
          return list
        end
      elseif (self._buildingGroupCache == BuildingGroupDelimiterType.OR) then
        for _, group in ipairs(self._buildingGroupCache) do
          group = self:ReplaceVariablesFromString(group)
          local recipes = OptionBuilder:GetRecipes(group)
          if recipes then
            return recipes
          end
        end
      end
    else
    -- if there is a no cache, this is a classic building group.
      local buildingGroup = self:ReplaceVariablesFromString(self.buildingGroup)
      return OptionBuilder:GetRecipes(buildingGroup)
    end
  end

  function GetBuildingRecipes(self)
    return self:GetRecipes()
  end

  __Arguments__ { String }
  function GetRecipe(self, id)
    local recipes = self:GetRecipes()
    if recipes then
      for _, recipe in recipes:GetIterator() do
        if recipe.id == id then return recipe end
      end
    end
  end

  --- Link the recipe to a option, and will use 'Options' API
  __Arguments__ { String }
  function BindOption(self, option)
    self.option = option
    return self
  end

  --- Set the Building Group the recipe will used to build its childens
  __Arguments__ { String }
  function SetBuildingGroup(self, group)
    local hasChanged = false
    if self.buildingGroup ~= group then
      hasChanged = true
    end

    self.__buildingGroup = group

    if hasChanged then
      -- If it has changed, we need to resolve recipe group and make some
      -- stuff (parse, build cache)
      self:ResolveBuildingGroup()
    end

    return self
  end

  --- Return the Building Group
  function GetBuildingGroup(self)
    return self.__buildingGroup
  end


  --- Will set the option linked, and use the set function if there is exists.
  -- By the way, the option linked will call its handler.
  __Arguments__ { Any }
  function SetOption(self, value)
    if self.option then
      Options:Set(self.option, value)
    end

    if self.setFunc then
      self.setFunc(self, value)
    end
  end

  --- This function return the value related to option linked.
  -- If no option linked, the function will use the 'Get'
  function GetOption(self)
    if self.option then
      return Options:Get(self.option)
    end

    if self.getFunc then
      return self.getFunc(self)
    end
  end

  __Arguments__ { String }
  function SetID(self, id)
    self.id = id
    return self
  end

  __Arguments__ { String }
  function SetText(self, text)
    self.text = text
    return self
  end

  --- Set the order where this recipes will be built.
  __Arguments__ { Number }
  function SetOrder(self, order)
    self.order = order
    return self
  end

  function GetCurrentUrlPart(self)
    local currentIndex = self.context("url_current_index")
    if not currentIndex then
      return
    end

    local currentPart = self.context("url_part_"..currentIndex)
    if not currentPart then
      return
    end

    local result = string.gsub(currentPart, ":([%w_]*):", function(var)
      return self.context(var)
    end)

    return result
  end


  --- This function may be overrided
  function Refresh(self) end

  __Arguments__ { String }
  function RefreshOnEvent(self, event)
    self:RegisterEvent(event)
    self.refreshOnEvent[event] = true

    return self
  end

  __Arguments__ { String }
  function RefreshOnRecipeEvent(self, event)
    self:RegisterRecipeEvent(event)
    self.refreshOnRecipeEvent[event] = true

    return self
  end

  --- This function is called when an event (Scorpio) registered has triggered.
  -- This may be overrided if needed
  __Arguments__ { String, Variable.Rest() }
  function OnEvent(self, event, ...) end

  --- Called when a recipe has fired an event has been registered
  __Arguments__ { String, Variable.Optional(Table), Variable.Rest()}
  function OnRecipeEvent(self, event, sender, ...) end


  --- Register the recipe has been notified when an event (Scorpio) has been triggered
  __Arguments__ { String }
  function RegisterEvent(self, event)
    OptionRecipe:RegisterObjectEvent(self, event)
  end

  --- Register the recipe has been notified when a recipe event has been triggered
  function RegisterRecipeEvent(self, event)
    local t = _RECIPE_EVENTS[event]
    if not t then
      t = setmetatable({}, { __mode = "k"})
      _RECIPE_EVENTS[event] = t
    end

    if not t[self] then
      t[self] = true
    end
  end

  --- Fires an recipe event
  __Arguments__ {String, Variable.Rest()}
  function FireRecipeEvent(self, event, ...)
    OptionRecipe:BroadcastRecipeEvent(event, self, ...)
  end


  __Arguments__ { Function }
  function Get(self, func)
    self.getFunc = func
    return self
  end

  __Arguments__ { Function }
  function Set(self, func)
    self.setFunc = func
    return self
  end


  __Static__() function RegisterObjectEvent(self, obj, event)
    local t = _EVENTS[event]
    if not t then
      t = setmetatable({}, { __mode = "k"} )
      _Module:RegisterEvent(event, function(...)
        for o in pairs(t) do
          o:OnEvent(event, ...)

          if o.refreshOnEvent[event] then
            o:Refresh()
          end
        end
      end)
    end

    if not t[obj] then
      t[obj] = true
    end
  end

  __Arguments__ { ClassType, String, Variable.Optional(Table), Variable.Rest() }
  __Static__() function BroadcastRecipeEvent(self, event, obj, ...)
    local t = _RECIPE_EVENTS[event]
    if t then
      for o in pairs(t) do
        if not obj or obj ~= o then
          o:OnRecipeEvent(event, obj, ...)
          if o.refreshOnRecipeEvent[event] then
            o:Refresh()
          end
        end
      end
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "order"            { TYPE = Number, DEFAULT = 100 }
  property "id"               { TYPE = String, DEFAULT = nil }
  property "text"             { TYPE = String, DEFAULT = "" }
  property "option"           { TYPE = String, DEFAULT = nil }
  property "context"          { TYPE = OptionContext, DEFAULT = nil }
  property "buildingGroup"    { TYPE = String, DEFAULT = nil, SET = "SetBuildingGroup",  FIELD = "__buildingGroup" }
  property "needResolveGroup" { TYPE = Boolean, DEFAULT = false }
  property "setFunc"          { TYPE = Function }
  property "getFunc"          { TYPE = Function }
  -- Use internally by delimiters (don't edit this property)
  property "_buildingGroupDelimiterType" { TYPE = BuildingGroupDelimiterType }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function OptionRecipe(self)
    self.cache                = setmetatable({}, { __mode = "v" })
    self.refreshOnEvent       = {}
    self.refreshOnRecipeEvent = {}
  end
end)
--------------------------------------------------------------------------------
--                                                                            --
--                        OptionFrame Recipe                                  --
--                                                                            --
--------------------------------------------------------------------------------
class "OptionFrameRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function SetWidth(self, width)
    self.width = width
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "width" { TYPE = Number  }
end)
