--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio          "EskaTracker.Options.OptionBuilder"                          ""
--============================================================================--
namespace "EKT"
_Options = _Parent
--============================================================================--
class "OptionBuilder" (function(_ENV)
  _RECIPES = List()
  _GROUP_RECIPES = Dictionary()

  _COMMON_VARIABLES = Dictionary()

  __Arguments__ { ClassType, String, Variable.Optional() }
  __Static__() function SetVariable(self, id, value)
    _COMMON_VARIABLES[id] = value
  end

  __Arguments__ { ClassType, String }
  __Static__() function GetVariable(self, id)
    return _COMMON_VARIABLES[id]
  end

  __Arguments__ { ClassType, OptionRecipe, Variable.Optional(String) }
  __Static__() function AddRecipe(self, recipe, group)
    -- If the group is availaible, add into _GROUP_RECIPES container
    if group then
      local groupRecipes = _GROUP_RECIPES[group]
      if not groupRecipes then
        groupRecipes = List()
        _GROUP_RECIPES[group] = groupRecipes
      end
      groupRecipes:Insert(recipe)
    else
      _RECIPES:Insert(recipe)
    end
  end

  __Arguments__ { ClassType, Variable.Optional(String) }
  __Static__() function GetRecipes(self, group)
    if group and _GROUP_RECIPES[group] then
      return _GROUP_RECIPES[group]:Sort("a,b=>a.order<b.order")
    else
      return _RECIPES:Sort("a,b=>a.order<b.order")
    end
  end


  __Arguments__ { ClassType, String, Variable.Optional(String) }
  __Static__() function GetRecipe(self, id, group)
    local recipes
    if group and _GROUP_RECIPES[group] then
      recipes = _GROUP_RECIPES[group]
    else
      recipes = _RECIPES
    end

    if recipes then
      for index, recipe in recipes:GetIterator() do
        if recipe.id == id then
          return recipe
        end
      end
    end
  end

  __Arguments__ { ClassType, String, Variable.Optional(String) }
  __Static__() function RemoveRecipe(self, id, group)
    local recipes
    if group and _GROUP_RECIPES[group] then
      recipes = _GROUP_RECIPES[group]
    else
      recipes = _RECIPES
    end


    if recipes then
      local index, recipe
      for i, r in recipes:GetIterator() do
        if r.id == id then
          index = i
          recipe = r
          break
        end
      end

      if index and recipe then
        recipes:RemoveByIndex(index)
      end
    end
  end

  __Arguments__ { ClassType, String }
  __Static__() function RemoveRecipes(self, group)
    local recipes = _GROUP_RECIPES[group]
    if recipes then
      recipes:Clear()
    end
  end

  __Arguments__ { ClassType, String, Variable.Optional(Table) }
  __Static__() function BuildUrl(self, url, variables)
    local context = OptionContext()
    local parts = { strsplit("/", url) }
    context:SetVariable("url", url)
    context:SetVariable("url_current_index", 1)
    context:SetVariable("url_part_count", #parts)

    for index, part in ipairs(parts) do
      context:SetVariable("url_part_"..index, part)
    end

    _Options:BuildUrl(context)
  end


--[[
  function BuildUrl(self, url, variables)
    local urlParts = { strsplit("/", url) }
    for index, part in ipairs(urlParts) do
      print("Url", index, part)
    end

    local context = OptionContext()
    context:SetVariable("url", url)
    context:SetVariable("url_part_1", urlParts)
    context:SetVariable("url_current_part_index", 1)
  end--]]

end)
