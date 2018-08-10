--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska             "EskaTracker.Options.SpecialRecipes"                         ""
-- ========================================================================== --
namespace "EKT"
--============================================================================--
_EKTAddon = _Addon

class "AddonInfoRecipe" inherit "OptionRecipe"

  function Build(self, context)

    context.parentWidget:SetLayout("List")
    local headingFont = _LibSharedMedia:Fetch("font", "PT Sans Caption Bold")
    local headingSize = 15

    local font = _LibSharedMedia:Fetch("font", "PT Sans Narrow Bold")
    local fontSize = 14

    do
      local group =  _AceGUI:Create("SimpleGroup")
      group:SetLayout("Flow")
      for key, value in pairs({ ["Version"] = _EKT_VERSION }) do
        local label = _AceGUI:Create("Label")
        label:SetText(key)
        label:SetFont(font, fontSize)
        label:SetWidth(100)
        label:SetColor(0, 148/255, 1)
        group:AddChild(label)

        local labelValue = _AceGUI:Create("Label")
        labelValue:SetText(value)
        labelValue:SetFont(font, fontSize)
        group:AddChild(labelValue)
      end
      context.parentWidget:AddChild(group)
    end

    -- Separator
    do
      local sep = _AceGUI:Create("Label")
      sep:SetText("\n\n")
      context.parentWidget:AddChild(sep)
    end

    -- Slash commands category
    local slashCommandsHeading = _AceGUI:Create("Label")
    slashCommandsHeading:SetText("Slash Commands")
    slashCommandsHeading:SetFont(headingFont, headingSize)
    slashCommandsHeading:SetColor(1, 216/255, 0)
    context.parentWidget:AddChild(slashCommandsHeading)
    -- Separator
    do
      local sep = _AceGUI:Create("Label")
      sep:SetText("\n")
      context.parentWidget:AddChild(sep)
    end
    do
      local slashCommands = {
        ["open|config|option"] = "Open the category",
        ["show"] = "Show the objective tracker",
        ["hide"] = "Hide the objective tracker",
        ["ploop"] = "Print the PLoop version",
        ["scorpio"] = "Print the Scorpio version"
      }

      local group = _AceGUI:Create("SimpleGroup")
      group:SetLayout("Flow")
      for command, desc in pairs(slashCommands) do
        local label = _AceGUI:Create("Label")
        label:SetText(string.format("|cffff6a00/ekt|r %s", command))
        label:SetFont(_LibSharedMedia:Fetch("font", "PT Sans Narrow Bold"), fontSize - 1)
        label:SetRelativeWidth(0.45)
        label:SetColor(0, 148/255, 1)
        group:AddChild(label)

        local labelValue = _AceGUI:Create("Label")
        labelValue:SetText("- "..desc)
        labelValue:SetFont(font, fontSize - 2)
        labelValue:SetRelativeWidth(0.55)
        group:AddChild(labelValue)
      end
      context.parentWidget:AddChild(group)
    end

    -- Separator
    do
      local sep = _AceGUI:Create("Label")
      sep:SetText("\n")
      context.parentWidget:AddChild(sep)
    end

    -- Dependencies category
    local dependenciesHeading = _AceGUI:Create("Label")
    dependenciesHeading:SetText("Dependencies")
    dependenciesHeading:SetFont(headingFont, headingSize)
    dependenciesHeading:SetColor(1, 0, 0)
    context.parentWidget:AddChild(dependenciesHeading)
    -- Separator
    do
      local sep = _AceGUI:Create("Label")
      sep:SetText("\n")
      context.parentWidget:AddChild(sep)
    end
    do
      local group =  _AceGUI:Create("SimpleGroup")
      group:SetLayout("Flow")

      local dependencies = {
        ["PLoop"] = {
          displayText = "|cff0094ffPLoop|r",
          version = _PLOOP_VERSION,
          state = select(2, _EKTAddon:CheckPLoopVersion(false))
        },
        ["Scorpio"] = {
          displayText = "|cffff6a00Scorpio|r",
          version = _SCORPIO_VERSION,
          state = select(2, _EKTAddon:CheckScorpioVersion(false))
        }
      }

      for libName, lib in pairs(dependencies) do

        local versionColor = "ff00ff00"

        if lib.state == DependencyState.OUTDATED then
          versionColor = "ffff0000"
        elseif lib.state == DependencyState.DEPRECATED then
          versionColor = "ffffd800"
        end

        local label = _AceGUI:Create("Label")
        label:SetText(lib.displayText)
        label:SetFont(font, fontSize)
        label:SetWidth(100)
        group:AddChild(label)

        local labelValue = _AceGUI:Create("Label")
        labelValue:SetText(string.format("|c%sv%d|r", versionColor, lib.version))
        labelValue:SetFont(font, fontSize)
        group:AddChild(labelValue)
      end
      context.parentWidget:AddChild(group)
    end


    -- Global options
    -- Separator
    do
      local sep = _AceGUI:Create("Label")
      sep:SetText("\n\n")
      context.parentWidget:AddChild(sep)
    end

  end
endclass "AddonInfoRecipe"




class "StateSelectRecipe" (function(_ENV)
  inherit "OptionRecipe"
  ------------------------------------------------------------------------------
  --                              Events                                      --
  --- --------------------------------------------------------------------------
  --- Fires when the user has selected a state
  event "OnStateSelected"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  --- --------------------------------------------------------------------------
  local function OnStateSelectedHandler(self, new)
    if new == "none" then
      OptionBuilder:SetVariable("state_selected", nil)
    else
      OptionBuilder:SetVariable("state_selected", new)
    end

    self:RebuildChildren()
  end

  function RebuildChildren(self)
    if self.propertiesGroup then
      local recipes = self:GetRecipes()
      self.propertiesGroup:ReleaseChildren()
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(self.propertiesGroup, self, self.context))
      end
    end
  end

  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)

    local heading = _AceGUI:Create("Heading")
    heading:SetRelativeWidth(1.0)
    heading:SetText("Select a state")
    context.parentWidget:AddChild(heading)

    local statesGroup = _AceGUI:Create("SimpleGroup")
    statesGroup:SetFullWidth(true)
    statesGroup:SetLayout("Flow")

    local currentButton

    for index, stateID in self.statesID:GetIterator() do

      local stateButton = _AceGUI:Create("Icon")
      stateButton:SetImageSize(20, 20)
      stateButton.frame:SetBackdrop(_Backdrops.Common)

      if index == 1 then
        currentButton = stateButton
        stateButton.frame:SetBackdropColor(1, 1, 1, 0.5)
      else
        stateButton.frame:SetBackdropColor(1, 1, 1, 0)
      end


      local state = States:Get(stateID)
      if state then
        stateButton:SetLabel(state:ColorText(state.text))
        if state.icon then
          stateButton:SetImage(state.icon)
        end
      end

      stateButton:SetCallback("OnClick", function()
        if currentButton ~= stateButton then
          currentButton.frame:SetBackdropColor(0, 0, 0, 0)
          stateButton.frame:SetBackdropColor(1, 1, 1, 0.5)
          currentButton = stateButton

          self:OnStateSelected(stateID)
        end
      end)

      --stateButton:SetLabel(stateID)
      --stateButton:SetImage([[Interface\AddOns\EskaTracker\Media\completed_icon]])
      statesGroup:AddChild(stateButton)
    end

    context.parentWidget:AddChild(statesGroup)

    local sep = _AceGUI:Create("Heading")
    sep:SetFullWidth(true)
    context.parentWidget:AddChild(sep)

    -- Create the group (maintly used by ThemePropertyRecipe)
    local recipes = self:GetRecipes()
    if recipes then
      local propertiesGroup = _AceGUI:Create("SimpleGroup")
      propertiesGroup:SetLayout("List")
      propertiesGroup:SetFullWidth(true)
      context.parentWidget:AddChild(propertiesGroup)
      for index, recipe in recipes:GetIterator() do
        recipe:Build(OptionContext(propertiesGroup, self, context))
      end

      self.propertiesGroup = propertiesGroup
    end
  end

  __Arguments__ { String }
  function AddState(self, id)
    self.statesID:Insert(id)
    return self
  end

  __Arguments__ { State }
  function AddState(self, state)
    return AddState(self, state.id)
  end

  ------------------------------------------------------------------------------
  --                            Constructor                                   --
  --- --------------------------------------------------------------------------
  function StateSelectRecipe(self)
    super(self)

    -- Links events
    self.OnStateSelected = OnStateSelectedHandler

    self.statesID = Array[String]()
    self:AddState("none") -- Add none by default
  end


end)



--------------------------------------------------------------------------------
--                                                                            --
--                          Spec Profil                                       --
--                                                                            --
--------------------------------------------------------------------------------
class "SpecProfileRecipe" (function(_ENV)
  inherit "OptionRecipe"

  ------------------------------------------------------------------------------
  --                              Events                                      --
  ------------------------------------------------------------------------------
  --- Fired when a profile has changed
  event "OnProfileChanged"
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  ------------------------------------------------------------------------------
  local function OnProfileChangedHandler(self, new)
    Profiles:SelectForSpec(self.specIndex, new)
  end
  ------------------------------------------------------------------------------
  --                             Methods                                      --
  ------------------------------------------------------------------------------
  function Build(self, context)
    -- Call our super build method (will set some usefull properties so don't forget it)
    super.Build(self, context)


    local _, sName, _, sIcon = GetSpecializationInfo(self.specIndex)
    local row = _AceGUI:Create("SimpleGroup")
    row:SetFullWidth(true)
    row:SetLayout("Flow")

    local icon = _AceGUI:Create("Label")
    icon:SetRelativeWidth(0.15)
    icon:SetText(string.format("|T%s:24:24|t", sIcon))
    row:AddChild(icon)

    local specName = _AceGUI:Create("Label")
    specName:SetText(sName)
    specName:SetRelativeWidth(0.3)
    row:AddChild(specName)

    local profileList = _AceGUI:Create("Dropdown")
    profileList:SetList(self:GetAllProfilesList())
    profileList:SetValue(Profiles:GetProfileForSpec(self.specIndex) or "__global")
    profileList:SetCallback("OnValueChanged", function(_, _,value) self:OnProfileChanged(value) end)
    row:AddChild(profileList)

    context.parentWidget:AddChild(row)

    -- Register frames in the cache
    self.cache["dropdown"] = profileList
  end

  function SetSpecIndex(self, index)
    self.specIndex = index
    return self
  end

  function GetAllProfilesList(self)
    local list = {
      ["__global"] = "Global profile",
      ["__char"]   = "Character profile",
      ["__spec"]   = "Specialization profile",
    }

    for profileName in pairs(Profiles:GetUserProfilesList()) do
      list[profileName] = profileName
    end

    return list
  end

  function Refresh(self)
    if self.cache["dropdown"] then
      self.cache["dropdown"]:SetList(self:GetAllProfilesList())
    end
  end

  ------------------------------------------------------------------------------
  --                         Properties                                       --
  ------------------------------------------------------------------------------
  property "specIndex" { TYPE = Number }
  ------------------------------------------------------------------------------
  --                            Constructors                                  --
  ------------------------------------------------------------------------------
  function SpecProfileRecipe(self)
    super(self)

    -- Link event
    self.OnProfileChanged = OnProfileChangedHandler

    -- Refresh when a profile is created
    self:RefreshOnRecipeEvent("PROFILE_CREATED")
    self:RefreshOnRecipeEvent("PROFILE_DELETED")
  end
end)
