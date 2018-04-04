-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio                "EskaTracker.Options.TrackerRecipes"                   ""
-- ========================================================================== --
namespace "EKT"
-- ========================================================================== --
class "CreateTrackerRecipe" inherit "OptionRecipe"
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local nameChoosen

    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)


    local name = _AceGUI:Create("EditBox")
    name:SetLabel("Name")
    name:SetRelativeWidth(0.3)
    name:SetCallback("OnEnterPressed", function(_, _, value) nameChoosen = value; print("OnValueChanged", nameChoosen, value) end)
    group:AddChild(name)

    local createButton = _AceGUI:Create("Button")
    createButton:SetText("Create")
    createButton:SetRelativeWidth(0.1)
    createButton:SetCallback("OnClick", function()
      print("OnClick", nameChoosen)
      if nameChoosen then
        local path = OptionBuilder:GetVariable("trackers_id")
        local group = OptionBuilder:GetVariable("trackers_group")
        local fID = OptionBuilder:GetVariable("tracker_id_format")
        local id = fID:format(nameChoosen)


        local recipe = OptionBuilder:GetRecipe(id, group)
        if not recipe then
          print("Create Recipe")
          OptionBuilder:AddRecipe(TreeItemRecipe():SetID(id):SetText(nameChoosen):SetPath(path):SetBuildingGroup("[tracker&:tracker_selected:]/children"), group)
          OptionBuilder:BuildUrl(id)
        end
      end
    end)
    group:AddChild(createButton)
  end
endclass "CreateTrackerRecipe"

class "DeleteTrackerRecipe" inherit "OptionRecipe"
  function Build(self, context)
    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)

    local trackerDropdown = _AceGUI:Create("Dropdown")

    local trackerList = {}

    for _, tracker in Trackers:GetIterator() do
        trackerList[tracker.id] = tracker.id
    end

    trackerDropdown:SetLabel("Select the tracker to delete")
    trackerDropdown:SetList(trackerList)
    trackerDropdown:SetRelativeWidth(0.3)
    group:AddChild(trackerDropdown)

    local deleteBtn = _AceGUI:Create("Button")
    deleteBtn:SetText("Delete")
    deleteBtn:SetRelativeWidth(0.1)
    group:AddChild(deleteBtn)
  end
endclass "DeleteTrackerRecipe"


class "BlockTrackerRecipe" inherit "OptionRecipe"
  function Build(self, context)
    local group = _AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)

    local text
    if self.icon then
      text = string.format("|T%s:16|t%s", self.icon, self.text)
    else
      text = self.text
    end


    local checkbox = _AceGUI:Create("CheckBox")
    --checkbox:SetLabel("|TInterface\\Icons\\INV_Misc_Coin_01:16|tEska-Quests")
    checkbox:SetLabel(text)
    group:AddChild(checkbox)
  end

  function SetIcon(self, icon)
    self.icon = icon
    return self
  end

  property "icon" { TYPE = String }

endclass "BlockTrackerRecipe"
