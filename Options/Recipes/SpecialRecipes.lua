-- ========================================================================== --
-- 										 EskaQuestTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Scorpio          "EskaTracker.Options.SpecialRecipes"                         ""
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
      for key, value in pairs({ ["Version"] = _EKT_VERSION, ["Stage"] = _EKT_STAGE }) do
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
