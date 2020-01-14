-- ========================================================================== --
-- 										      EskaTracker                                       --
-- @Author   : Skamer <https://mods.curse.com/members/DevSkamer>              --
-- @Website  : https://wow.curseforge.com/projects/eska-quest-tracker         --
-- ========================================================================== --
Eska                    "EskaTracker"                                         ""
--============================================================================--
import "EKT"
-- =======================[[ Localization ]}====================================
L                   = _Locale
-- ========================[[ Logger ]]========================================
Log                 = Logger("EskaTracker")

Trace               = Log:SetPrefix(1, "|cffa9a9a9[EskaTracker:Trace]|r", true)
Debug               = Log:SetPrefix(2, "|cff808080[EskaTracker:Debug]|r", true)
Info                = Log:SetPrefix(3, "|cffffffff[EskaTracker:Info]|r", true)
Warn                = Log:SetPrefix(4, "|cffffff00[EskaTracker:Warn]|r", true)
Error               = Log:SetPrefix(5, "|cffff0000[EskaTracker:Error]|r", true)
Fatal               = Log:SetPrefix(6, "|cff8b0000[EskaTracker:Fatal]|r", true)

Log.LogLevel        = 3
Log:AddHandler(print)
-- =========================[[ LibSharedMedia ]]============================= --
_LibSharedMedia      = LibStub("LibSharedMedia-3.0")
-- ======================[[ LibDataBroker & Minimap ]]======================= --
_LibDataBroker       = LibStub("LibDataBroker-1.1")
_LibDBIcon           = LibStub("LibDBIcon-1.0")
-- ========================[[ Addon version ]]------------------------------- ==
_EKT_VERSION         = GetAddOnMetadata("EskaTracker", "Version")
-- =========================[[ Dependencies Version ]]======================= --
_SCORPIO_VERSION     = tonumber(GetAddOnMetadata("Scorpio", "Version"):match("%d+$"))
_PLOOP_VERSION       = tonumber(GetAddOnMetadata("PLoop", "Version"):match("%d+$"))
-- ========================================================================== --
_EKT_ICON            = [[Interface\AddOns\EskaTracker\Media\icon]]
-- ===========================================================================--
BLOCK                = EKT_BLOCK
--============================================================================--
-- IMPORTANT !
-- Don't set stuffs related to DB (this causes error if the user doesn't have the save veriables created)
-- Set theme to OnEnable instead
function OnLoad(self)
  -- Create and init the DB
  _DB = SVManager("EskaTrackerDB")

  -- Register the options
  Settings:Register("replace-blizzard-objective-tracker", true, "Blizzard/UpdateTrackerVisibility")
  -- Register callbacks
  CallbackHandlers:Register("Blizzard/UpdateTrackerVisibility", CallbackHandler(function(replace) BLIZZARD_TRACKER_VISIBLITY_CHANGED(not replace) end))

  -- Get the same version as Eska Quest Tracker
  _DB:SetDefault{dbVersion = 2 }
  _DB:SetDefault{ minimap = { hide = false }}

  -- Setup the minimap button
  self:SetupMinimapButton()

  Settings:Register("theme-selected", "Eska")

  self:MigrateOptionsToSettings()

end

function MigrateOptionsToSettings(self)
  if Database:GetVersion() <= 2 then
    Database:RenameAllTables("options", "settings")
    Database:SetVersion(3)
  end
end



function OnEnable(self)
  BLIZZARD_TRACKER_VISIBLITY_CHANGED(not Settings:Get("replace-blizzard-objective-tracker"))
end

__SystemEvent__()
function BLIZZARD_TRACKER_VISIBLITY_CHANGED(isVisible)
  if isVisible then
    ObjectiveTracker_Initialize(ObjectiveTrackerFrame)
    ObjectiveTrackerFrame:SetScript("OnEvent", ObjectiveTracker_OnEvent)
    ObjectiveTrackerFrame:Show()
    ObjectiveTracker_Update()
  else
    ObjectiveTrackerFrame:Hide()
    ObjectiveTrackerFrame:SetScript("OnEvent", nil)
  end
end

function OnQuit(self)
  -- Do a clean in the Database (remove empty tables) when the player log out
  Database:Clean()
end


function SetupMinimapButton(self)
  local LDBObject = _LibDataBroker:NewDataObject("EskaTracker", {
    type = "launcher",
    icon = _EKT_ICON,
    OnClick = function(_, button, down)
      if IsShiftKeyDown() then 
        self:FireSystemEvent("EKT_HARD_RELOAD_MODULES")
      else 
        self:FireSystemEvent("EKT_OPEN_OPTIONS")
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:AddDoubleLine("Eska Tracker", _EKT_VERSION, 1, 106/255, 0, 1, 1, 1)
      tooltip:AddLine(" ")
      -- tooltip:AddLine(L["LDB_tooltip_left_click_text"])
      tooltip:AddLine(L["LDB_tooltip_click_text"])
      tooltip:AddLine(L["LDB_tooltip_shift_click_text"] )
    end,
  })

  _LibDBIcon:Register("EskaTracker", LDBObject, _DB.minimap)
end


-- ========================================================================== --
-- == Dependecies Checks
-- ========================================================================== --
enum "DependencyState" {
  "OK",         -- The addon works fine with the current dependency version.
  "DEPRECATED", -- The addon works fine with the current dependency version, but for the next addon version, the dependency must be updated in order to the addon works.
  "OUTDATED",   -- The addon doesn't work with the current dependency version, the dependency must be updated.
}

-- MinPLoop = 220
function CheckPLoopVersion(self, printCheck)
  local deprecatedVersion = 190 -- The version below will be considered as deprecated
  local requiredVersion = 190   -- The version below will be considered as outdated and not working with the current addon version.

  if printCheck == nil then
    printCheck = true
  end

  if _PLOOP_VERSION < requiredVersion then
    if printCheck then
      Error(L.Dependecies_alert_required, "[Lib] PLoop")
    end
    return false, DependencyState.OUTDATED
  elseif _PLOOP_VERSION < deprecatedVersion then
    if printCheck then
      Warn(L.Dependencies_alert_deprecated, "[Lib] PLoop", "[Lib] PLoop")
    end
    return false, DependencyState.DEPRECATED
  end
  return true, DependencyState.OK
end

function CheckScorpioVersion(self, printCheck)
  local deprecatedVersion = 15 -- The version below will be considered as deprecated
  local requiredVersion = 13   -- The version below will be considered as outdated and not working with the current addon version.

  if printCheck == nil then
    printCheck = true
  end

  if _SCORPIO_VERSION < requiredVersion then
    if printCheck then
      Error(L.Dependecies_alert_required, "[Lib] Scorpio")
    end
    return false, DependencyState.OUTDATED
  elseif _SCORPIO_VERSION < deprecatedVersion then
    if printCheck then
      Warn(L.Dependencies_alert_deprecated, "[Lib] Scorpio", "[Lib] Scorpio")
    end
    return false, DependencyState.DEPRECATED
  end
  return true, DependencyState.OK
end

-- ========================================================================== --
-- == Slash Commands
-- ========================================================================== --
__SlashCmd__ "ekt" "scorpio" "- return the current scorpio version"
function PrintScorpioVersion()
  Info("|cff00ff00Your Scorpio version is:|r |cffff0000%s|r", GetAddOnMetadata("Scorpio", "Version"))
end

__SlashCmd__ "ekt" "ploop" "- return the current ploop version"
function PrintPLoopVersion()
  Info("|cff00ff00Your PLoop version is:|r |cffff0000%s|r", GetAddOnMetadata("PLoop", "Version"))
end

__SlashCmd__ "ekt" "show" "- show the objective tracker"
function ShowObjectiveTracker()
  --_Addon.ObjectiveTracker:Show()
end

__SlashCmd__ "ekt" "hide" "- hide the objective tracker"
function HideObjectiveTracker()
  --_Addon.ObjectiveTracker:Hide()
end


__SlashCmd__ "ekt" "config" "- open the options"
__SlashCmd__ "ekt" "open" "- open the options"
__SlashCmd__ "ekt" "option" "- open the options"
function OpenOptions(self)
  self:FireSystemEvent("EKT_OPEN_OPTIONS")
end

__SlashCmd__ "ekt" "reload" "- Reload all modules"
function Reload()
  _M:FireSystemEvent("EKT_HARD_RELOAD_MODULES")
end

-- ========================================================================== --
-- == Register the fonts
-- ========================================================================== --
-- PT Sans Family Font
_LibSharedMedia:Register("font", "PT Sans", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Regular.ttf]])
_LibSharedMedia:Register("font", "PT Sans Bold", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Bold.ttf]])
_LibSharedMedia:Register("font", "PT Sans Bold Italic", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Bold-Italic.ttf]])
_LibSharedMedia:Register("font", "PT Sans Narrow", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Narrow.ttf]])
_LibSharedMedia:Register("font", "PT Sans Narrow Bold", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Narrow-Bold.ttf]])
_LibSharedMedia:Register("font", "PT Sans Caption", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Caption.ttf]])
_LibSharedMedia:Register("font", "PT Sans Caption Bold", [[Interface\AddOns\EskaTracker\Media\Fonts\PTSans-Caption-Bold.ttf]])
-- DejaVuSans Family Font
_LibSharedMedia:Register("font", "Deja Vu Sans", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSans.ttf]])
_LibSharedMedia:Register("font", "Deja Vu Sans Bold", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSans-Bold.ttf]])
_LibSharedMedia:Register("font", "Deja Vu Sans Bold Italic", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSans-BoldOblique.ttf]])
_LibSharedMedia:Register("font", "DejaVuSansCondensed", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSansCondensed.ttf]])
_LibSharedMedia:Register("font", "DejaVuSansCondensed Bold", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSansCondensed-Bold.ttf]])
_LibSharedMedia:Register("font", "DejaVuSansCondensed Bold Italic", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSansCondensed-BoldOblique.ttf]])
_LibSharedMedia:Register("font", "DejaVuSansCondensed Italic", [[Interface\AddOns\EskaTracker\Media\Fonts\DejaVuSansCondensed-Oblique.ttf]])
-- ========================================================================== --
-- == Register the background
-- ========================================================================== --
_LibSharedMedia:Register("background", "EskaTracker Background", [[Interface\AddOns\EskaTracker\Media\Textures\Frame-Background]])
-- ========================================================================== --
-- Backdrops
-- ========================================================================== --
_Backdrops = {
  Common = {
    bgFile = [[Interface\AddOns\EskaTracker\Media\Textures\Frame-Background]],
    insets = { left = 0, right = 0, top = 0, bottom = 0}
  },
  CommonWithBiggerBorder = {
    bgFile = [[Interface\AddOns\EskaTracker\Media\Textures\Frame-Background]],
    edgeFile = [[Interface\AddOns\EskaTracker\Media\Textures\Frame-Border]],
    tile = false, tileSize = 32, edgeSize = 6,
    insets = { left = 0, right = 0, top = 0, bottom = 0}
  }
}

_JUSTIFY_H_FROM_ANCHOR = {
  CENTER = "CENTER", TOP = "CENTER", BOTTOM = "CENTER", LEFT = "LEFT", RIGHT = "RIGHT",
  TOPLEFT = "LEFT", TOPRIGHT = "RIGHT", BOTTOMLEFT = "LEFT", BOTTOMRIGHT = "RIGHT"
}

_JUSTIFY_V_FROM_ANCHOR = {
  CENTER = "CENTER", TOP = "TOP", BOTTOM = "BOTTOM", LEFT = "CENTER", RIGHT = "CENTER",
  TOPLEFT = "TOP", TOPRIGHT = "TOP", BOTTOMLEFT = "BOTTOM", BOTTOMRIGHT = "BOTTOM"
}
