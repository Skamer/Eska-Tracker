Scorpio           "EskaTracker.Localization.enUS"                             ""

local L = _Locale("enUS", true)

if not L then return end

print("Localization US")


-- L[LDB_TOOLTIP_LEFT_CLICK]
-- L.LDB_TOOLTIP_LEFT_CLICK

-- LDB_TOOLTIP_LEFT_CLICK
-- LDB_TOOLTIP_LEFT_CLICK
-- L["LDB_TOOLTIP_LEFT_CLICK"]
-- L["LDB_TOOLTIP_LEFT_CLICK"]
-- L["LDB_TOOLTIP_RIGHT_CLICK"]
-- L["DEPENDENCIES_ALERT_DEPECATED"]
-- L["DEPENDENCIES_ALERT_REQUIRED"]

L["LDB_tooltip_left_click_text"] = "|cff00ffffClick|r to show/hide all trackers"
L["LDB_tooltip_right_click_text"] = "|cff00ffffRight Click|r to open the configuration window"

print("Locale 1", L["Dependencies_alert_deprecated"] )
L["Dependencies_alert_deprecated"] = "Your |cffFF6A00%s|r version is deprecated. That means in the next updates of |cff7FC9FFEska Quest Tracker|r, your version will no longer be enought in order to the addon works. Update your |cffFF6A00%s|r as soon as possible !"
print("Locale 2", L["Dependencies_alert_deprecated"] )
L["Dependecies_alert_required"] = "Your |cffFF6A00%s|r version is too older for the addon works. Update it now !"
