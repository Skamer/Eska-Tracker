--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                "EskaTracker.Options.TrackerRecipes"                   ""
-- ========================================================================== --
namespace "EKT"
-- ========================================================================== --
class "CreateTrackerRecipe" (function(_ENV)
  inherit "OptionRecipe"



  ------------------------------------------------------------------------------
  --                              Events                                      --
  --- --------------------------------------------------------------------------
  --- Fire when the user has choosen an another tracker name
  event "OnTrackerNameChanged"
  --- Fire when the user asks to create a tracker
  event "OnCreateTrackerRequest"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  --- --------------------------------------------------------------------------
  local function OnTrackerNameChangedHandler(self, new)
    OptionBuilder:SetVariable("create_tracker_name", new)
  end

  local function OnCreateTrackerRequestHandler(self)
    local name = OptionBuilder:GetVariable("create_tracker_name")
    if name then
      -- Get the patch
      local path     = OptionBuilder:GetVariable("trackers_id")
      local group    = OptionBuilder:GetVariable("trackers_group")
      local formatID = OptionBuilder:GetVariable("tracker_id_format")
      local id       = formatID:format(name:lower())

      if not Trackers:Get(id) then
        local recipe = OptionBuilder:GetRecipe(id, group)
        if not recipe then
          local tracker = Trackers:New(id, true)
          local headingText = string.format("|cffff5000%s tracker Options|r", tracker.name)

          -- Add Specific recipes
          OptionBuilder:AddRecipe(HeadingRecipe():SetText(headingText):SetOrder(1), string.format("%s/children", tracker.id))
          OptionBuilder:AddRecipe(TreeItemRecipe():SetID(id):SetText(name):SetPath(path):SetBuildingGroup("[tracker&:tracker_selected:]/children"), group)
          OptionBuilder:AddRecipe(ThemePropertyRecipe()
          :SetElementID(string.format("tracker.%s.frame", tracker.id))
          :AddFlag(Theme.SkinFlags.FRAME_BORDER_COLOR)
          :AddFlag(Theme.SkinFlags.FRAME_BORDER_WIDTH), string.format("%s/general/states", tracker.id))
          -- Redirection and rebuild
          OptionBuilder:SetVariable("tracker_selected", id)
          OptionBuilder:BuildUrl(id)
        end
      end
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  --- --------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    -- Create our group widget
    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)

    local name = _AceGUI:Create("EditBox")
    name:SetLabel("Name")
    name:SetRelativeWidth(0.3)
    name:SetCallback("OnEnterPressed", function(_, _, value) self:OnTrackerNameChanged(value) end)
    group:AddChild(name)

    local createButton = _AceGUI:Create("Button")
    createButton:SetText("Create")
    createButton:SetRelativeWidth(0.1)
    createButton:SetCallback("OnClick", function() self:OnCreateTrackerRequest() end)
    group:AddChild(createButton)
  end
  ------------------------------------------------------------------------------
  --                            Constructor                                   --
  --- --------------------------------------------------------------------------
  function CreateTrackerRecipe(self)
    super(self)

    -- Link Events
    self.OnTrackerNameChanged   = OnTrackerNameChangedHandler
    self.OnCreateTrackerRequest = OnCreateTrackerRequestHandler
  end
end)


class "DeleteTrackerRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  --- --------------------------------------------------------------------------
  --- Fired when the user has choosen an another tracker name
  event "OnTrackerNameChanged"
  --- Fire when the user asks to delete a tracker
  event "OnDeleteTrackerRequest"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  --- --------------------------------------------------------------------------
  local function OnTrackerNameChangedHandler(self, new)
    OptionBuilder:SetVariable("tracker_to_delete", new)
  end

  local function OnDeleteTrackerRequestHandler(self)
    local trackerID = OptionBuilder:GetVariable("tracker_to_delete")
    if trackerID then
      Trackers:Delete(trackerID)

      -- And remove the recipe related to tracker deleted
      OptionBuilder:RemoveRecipe(trackerID, "RootTree")
      OptionBuilder:RemoveRecipes(string.format("%s/children", trackerID))
      OptionBuilder:RemoveRecipes(string.format("%s/general/states", trackerID))

      -- Then to finish, redirect the user to trackers category
      OptionBuilder:BuildUrl("trackers")
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  --- --------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    -- Create our group widget
    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)

    local trackersDropdown = _AceGUI:Create("Dropdown")
    local trackerList     = {}
    -- Fill the list (main-tracker is excluded)
    for _, tracker in Trackers:GetIterator() do
      if tracker.id ~= "main-tracker" then
        trackerList[tracker.id] = tracker.name
      end
    end

    -- Reset the variable to nil for 'tracker_to_delete'
    OptionBuilder:SetVariable("tracker_to_delete")

    trackersDropdown:SetLabel("Select the tracker to delete")
    trackersDropdown:SetList(trackerList)
    trackersDropdown:SetRelativeWidth(0.3)
    trackersDropdown:SetCallback("OnValueChanged", function(_, _, id) self:OnTrackerNameChanged(id) end)
    group:AddChild(trackersDropdown)

    local deleteButton = _AceGUI:Create("Button")
    deleteButton:SetText("Delete")
    deleteButton:SetCallback("OnClick", function() self:OnDeleteTrackerRequest() end)
    deleteButton:SetRelativeWidth(0.1)
    group:AddChild(deleteButton)
  end
  ------------------------------------------------------------------------------
  --                            Constructor                                   --
  --- --------------------------------------------------------------------------
  function DeleteTrackerRecipe(self)
    super(self)

    -- Links events
    self.OnTrackerNameChanged   = OnTrackerNameChangedHandler
    self.OnDeleteTrackerRequest = OnDeleteTrackerRequestHandler
  end
end)

--[[
class "BlockTrackerRecipe" inherit "OptionRecipe"
  function Build(self, context)
    local trackerSelected = context("tracker_selected")
    print("Tracker selected", trackerSelected)

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

endclass "BlockTrackerRecipe"--]]

class "BlockCategoryRowRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  --- Fired when a block has been selected
  event "CategorySelected"
  --- Fired when a block has been unchecked
  event "CategoryUnchecked"

  local function RemoveTrackerSuffix(id)
    return id:gsub("(%-tracker)$", "")
  end
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  ------------------------------------------------------------------------------
  local function CategorySelectedHandler(self, trackerSelected)
    Trackers:TransferBlock(self.id, trackerSelected)

    local category = Blocks:GetCategory(self.id)
    if category then
      category.tracker = trackerSelected
    end
  end

  local function CategoryUncheckedHandler(self, trackerSelected)
    local tracker = Trackers:GetTrackerByBlockCategoryID(self.id)
    if tracker then
      tracker:RemoveBlockByCategoryID(self.id)
    end

    local category = Blocks:GetCategory(self.id)
    if category then
      category.tracker = "none"
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    local trackerSelected = RemoveTrackerSuffix(context("tracker_selected"))
    local category = Blocks:GetCategory(self.id)

    if not category then
      return
    end

    local group = _AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    context.parentWidget:AddChild(group)

    local text
    local text
    if self.icon then
      text = string.format("|T%s:16|t%s", self.icon, self.text)
    else
      text = self.text
    end

    local checkbox = _AceGUI:Create("CheckBox")
    checkbox:SetLabel(text)
    group:AddChild(checkbox)

    if category.tracker == trackerSelected then
      checkbox:SetValue(true)
    else
      checkbox:SetValue(false)
    end

    checkbox:SetCallback("OnValueChanged", function(_, _, value)
      if value then
        self:CategorySelected(trackerSelected)
      else
        self:CategoryUnchecked(trackerSelected)
      end
    end)


  end

  function SetIcon(self, icon)
    self.icon = icon
    return self
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "icon" { TYPE = String }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function BlockCategoryRowRecipe(self)
    -- Link events
    self.CategorySelected  = CategorySelectedHandler
    self.CategoryUnchecked = CategoryUncheckedHandler
  end
end)
