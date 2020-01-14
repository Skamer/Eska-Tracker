--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska              "EskaTracker.Localization.enUS"                             ""
--============================================================================--
local L = _Locale("enUS", true)

if not L then return end


L["LDB_tooltip_click_text"] = "|cff00ffffClick|r to open the configuration window"
L["LDB_tooltip_shift_click_text"] = "|cff00ffffShift+Click|r to reload modules."
L["Dependencies_alert_deprecated"] = "Your |cffFF6A00%s|r version is deprecated. That means in the next updates of |cff7FC9FFEska Quest Tracker|r, your version will no longer be enought in order to the addon works. Update your |cffFF6A00%s|r as soon as possible !"
L["Dependecies_alert_required"] = "Your |cffFF6A00%s|r version is too older for the addon works. Update it now !"

--@localization(locale="enUS", format="lua_additive_table", same-key-is-true=true, handle-subnamespaces="concat")@
