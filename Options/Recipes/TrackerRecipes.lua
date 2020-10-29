--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                   "EskaTracker.Options.TrackerRecipes"                   ""
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

class "DisplayRulesRecipe" (function(_ENV)
  inherit "OptionRecipe"

  _UP_ARROW_ICON = [[Interface\AddOns\EskaTracker\Media\up_arrow_icon]]
  _DOWN_ARROW_ICON = [[Interface\AddOns\EskaTracker\Media\down_arrow_icon]]
  _CONTINUE_ARROW_ICON = [[Interface\AddOns\EskaTracker\Media\continue_arrow_icon]]
  _REMOVE_ICON = [[Interface\AddOns\EskaTracker\Media\failed_icon]]

  local function RemoveTrackerSuffix(id)
    return id:gsub("(%-tracker)$", "")
  end

  local function SortedByGroup(a, b)
    if a.category and b.category then
      return a.category < b.category
    elseif a.category and not b.category then
      return true
    elseif not a.category and b.category then
      return false
    end
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local trackerSelected = RemoveTrackerSuffix(context("tracker_selected"))
    local tracker = Trackers:Get(trackerSelected)

    if not tracker then
      return
    end

    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("List")
    group:SetRelativeWidth(1.0)
    context.parentWidget:AddChild(group)

    self.cache["group"]   = group
    self.cache["tracker"] = tracker
    self.cache["rules"]   = nil
    self.cache["pages"]   = nil
    self.cache["current-page"] = nil
    self.cache["headline"] = nil

    self:BuildPages()
    self:BuildRows(self.currentPage)
  end

  function BuildPages(self)
    local tracker = self.cache["tracker"]
    local group   = self.cache["group"]

    local pageCount = ceil(tracker:GetDisplayRules().Count / 5)
    self.pageCount = pageCount
    if pageCount >= 0 then
      local pages = self.cache["pages"]
      if not pages then
        pages = _AceGUI:Create("SimpleGroup")
        pages:SetRelativeWidth(1.0)
        pages:SetLayout("Flow")
        group:AddChild(pages)
        self.cache["pages"] = pages
      end

      local previousPage = _AceGUI:Create("InteractiveLabel")
      previousPage:SetText("<<")
      previousPage:SetWidth(30)
      previousPage:SetFont(self.pageFont, self.pageFontSize)
      pages:AddChild(previousPage)

      for i = 1, pageCount do
        local page = _AceGUI:Create("InteractiveLabel")
        page:SetText(i)
        page:SetWidth(20)
        page:SetFont(self.pageFont, self.pageFontSize)
        page:SetCallback("OnClick", function()
          self.currentPage = i
          local currentPage = self.cache["current-page"]
          if currentPage ~= page then
            page:SetColor(28/255, 209/255, 1.0)
            currentPage:SetColor(1.0, 216/255, 0)

            self.cache["current-page"] = page

            self:RebuildRows()
          end
        end)
        pages:AddChild(page)

        if self.currentPage == i then
          self.cache["current-page"] = page
          page:SetColor(28/255, 209/255, 1.0)
        else
          page:SetColor(1.0, 216/255, 0)
        end
      end

      local nextPage = _AceGUI:Create("InteractiveLabel")
      nextPage:SetText(">>")
      nextPage:SetWidth(30)
      nextPage:SetFont(self.pageFont, self.pageFontSize)
      pages:AddChild(nextPage)

      if not self.cache["headline"] then
        local headline = _AceGUI:Create("Heading")
        headline:SetFullWidth(true)
        group:AddChild(headline)
        self.cache["headline"] = headline
      end

    end
  end



  function RebuildPages(self)
    local pages = self.cache["pages"]
    if pages then
      pages:ReleaseChildren()
    end

    self:BuildPages()
  end

  function Rebuild(self)
    local group = self.cache["group"]

    self.cache["rules"]         = nil
    self.cache["pages"]         = nil
    self.cache["current-page"]  = nil
    self.cache["headline"]      = nil
    group:ReleaseChildren()

    self:BuildPages()
    self:BuildRows(self.currentPage)
  end

  function RebuildRows(self)
    local rules = self.cache["rules"]
    if rules then
      rules:ReleaseChildren()
    end
    self:BuildRows(self.currentPage)
  end

  function BuildRows(self, page)
    local tracker = self.cache["tracker"]
    local group = self.cache["group"]

    local rulesGroup = self.cache["rules"]
    if not rulesGroup then
      rulesGroup = _AceGUI:Create("SimpleGroup")
      rulesGroup:SetLayout("List")
      rulesGroup:SetFullWidth(true)
      group:AddChild(rulesGroup)
      self.cache["rules"] = rulesGroup
    end

    local rules = tracker:GetDisplayRules()
    if page > 0 then

      for i = 1, self.pageRulesNum do
        local index = (page - 1) * 5 + i
        local rule =  rules[index]
        if not rule then
          break;
        end

        local row = self:CreateRow(tracker, rule, index, index == 1, index == rules.Count)
        rulesGroup:AddChild(row)
      end
    end
  end

  __Arguments__ { Tracker, DisplayRule, Number, Variable.Optional(Boolean, false), Variable.Optional(Boolean, false) }
  function CreateRow(self, tracker, rule, index, first, last)
    local group = _AceGUI:Create("SimpleGroup")
    group:SetLayout("Flow")
    group:SetRelativeWidth(1.0)

    local removeIcon = _AceGUI:Create("EKT-Icon")
    removeIcon:SetImage(_REMOVE_ICON)
    removeIcon:SetImageSize(16, 16)
    removeIcon:SetWidth(20)
    removeIcon.frame:SetBackdropColor(0, 0, 0, 0)
    removeIcon:SetCallback("OnClick", function()
      tracker:RemoveDisplayRule(rule)
    end)
    group:AddChild(removeIcon)

    local labelSpace = _AceGUI:Create("Label")
    labelSpace:SetText("")
    labelSpace:SetWidth(16)
    group:AddChild(labelSpace)

    local numLabel = _AceGUI:Create("Label")
    numLabel:SetText(string.format("%i.", index))
    numLabel:SetWidth(24)
    group:AddChild(numLabel)

    local dropdown = _AceGUI:Create("EKT-Dropdown")
    dropdown:SetLabel("If")
    dropdown:SetWidth(200)
    dropdown:SetCallback("OnValueChanged", function(_, _, value)
      rule.ifValue = value
      tracker:SaveDisplayRule(rule)
    end)
    group:AddChild(dropdown)

    local statusCategory = {}
    local statusFunctions = StatusFunctions:GetAll().Values:ToList()
    for index, statusFunction in statusFunctions:Sort(SortedByGroup):GetIterator() do
      dropdown:AddItem(statusFunction.id, statusFunction.text, statusFunction.category)
    end
    dropdown:SetValue(rule.ifValue)

    local valueDropdown = _AceGUI:Create("Dropdown")
    valueDropdown:SetWidth(72)
    valueDropdown:SetList({
      ["true"] = "True",
      ["false"] = "False",
    })

    if rule.condValue == nil then
      valueDropdown:SetValue("")
    else
      valueDropdown:SetValue(rule.condValue and "true" or "false")
    end

    valueDropdown:SetCallback("OnValueChanged", function(_, _, value)
      if value == "true" then
        rule.condValue = true
      elseif value == "false" then
        rule.condValue = false
      end
      tracker:SaveDisplayRule(rule)
    end)
    group:AddChild(valueDropdown)

    local behaviorDropdown = _AceGUI:Create("Dropdown")
    behaviorDropdown:SetWidth(200)
    behaviorDropdown:SetLabel("Then")
    behaviorDropdown:SetList({
      ["hide-tracker"] = "|cffff0000Hide the tracker|r",
      ["show-tracker"] = "|cff00ff00Show the tracker|r",
    })
    group:AddChild(behaviorDropdown)
    behaviorDropdown:SetCallback("OnValueChanged", function(_, _, value)
      rule.thenValue = value
      tracker:SaveDisplayRule(rule)
    end)
    behaviorDropdown:SetValue(rule.thenValue)

    local continueCheckbox = _AceGUI:Create("CheckBox")
    continueCheckbox:SetLabel(string.format("|T%s:16:16|t", _CONTINUE_ARROW_ICON))
    continueCheckbox:SetWidth(62)
    continueCheckbox:SetValue(rule.continue)
    continueCheckbox:SetCallback("OnValueChanged", function(_, _, value)
      rule.continue = value
      tracker:SaveDisplayRule(rule)
    end)
    group:AddChild(continueCheckbox)

    if not first then
      local upIcon = _AceGUI:Create("EKT-Icon")
      upIcon.frame:SetBackdropColor(0, 0, 0, 0)
      upIcon:SetImage(_UP_ARROW_ICON)
      upIcon:SetImageSize(16, 16)
      upIcon:SetWidth(24)
      upIcon:SetCallback("OnClick", function()
        tracker:UpDisplayRuleOrder(rule)
      end)
      group:AddChild(upIcon)
    end

    if not last then
      local downIcon = _AceGUI:Create("EKT-Icon")
      downIcon:SetImage(_DOWN_ARROW_ICON)
      downIcon:SetImageSize(16, 16)
      downIcon:SetWidth(24)
      downIcon:SetCallback("OnClick", function()
        tracker:DownDisplayRuleOrder(rule)
      end)
      group:AddChild(downIcon)
    end

    return group
  end

  __Async__()
  function Refresh(self)
    if self.cache["group"] then
      self.cache["group"]:ReleaseChildren()
      self:CreatePages()
      self:CreateRows(self.currentPage)
    end

    -- Update the layout
    self:FireRecipeEvent("UPDATE_LAYOUT")
  end

  __Arguments__ { String, Variable.Rest()}
  function OnEvent(self, event, ...)
    super.OnEvent(self, event, ...)

    local tracker = self.cache["tracker"]
    local rebuildGroup = false
    local rebuildPages = false
    local rebuildRules = false

    local rulesCount = tracker:GetDisplayRules().Count
    local pageCount = ceil(rulesCount / 5)

    if event == "EKT_TRACKER_DISPLAY_RULE_ADDED" then
      if pageCount ~= self.pageCount then
        rebuildPages = true
      end

      if self.currentPage == 0 then
        self.currentPage = 1
      end

      if self.currentPage == pageCount then
        rebuildRules = true
      end
    elseif event == "EKT_TRACKER_DISPLAY_RULE_REMOVED" then
      if pageCount ~= self.pageCount then
        rebuildPages = true
      end

      rebuildRules = true

      if self.currentPage > pageCount then
        self.currentPage = pageCount
      end
    elseif event == "EKT_TRACKER_DISPLAY_RULE_ORDER_CHANGED" then
      rebuildRules = true
    end

    if rebuildGroup then
      self:Rebuild()
    else
      if rebuildPages then
        self:RebuildPages()
      end
      if rebuildRules then
        self:RebuildRows()
      end
    end
  end
  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "pageFontSize" { TYPE = Number, DEFAULT = 13 }
  property "currentPage"  { TYPE = Number, DEFAULT = 1 }
  property "pageCount"    { TYPE = Number, DEFAULT = 1 }
  property "pageRulesNum" { TYPE = Number, DEFAULT = 5 }

  function DisplayRulesRecipe(self)
    super(self)

    self.pageFontSize = 13
    self.pageFont     = _LibSharedMedia:Fetch("font", "DejaVuSansCondensed Bold")

    self:RegisterEvent("EKT_TRACKER_DISPLAY_RULE_ADDED")
    self:RegisterEvent("EKT_TRACKER_DISPLAY_RULE_REMOVED")
    self:RegisterEvent("EKT_TRACKER_DISPLAY_RULE_ORDER_CHANGED")
  end

end)
