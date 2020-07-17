--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
import "EKT"
--============================================================================--
local TransparenceTheme = Theme()
TransparenceTheme.name     = "Transparence"
TransparenceTheme.author   = "Skamer"
TransparenceTheme.version  = "1.0.0"
TransparenceTheme.stage    = "Alpha"
Themes:Register(TransparenceTheme)
-- ========================================================================== --
-- == Set Default properties
-- ========================================================================== --
TransparenceTheme:SetElementProperty("*", "text-font-flags", "OUTLINE")
TransparenceTheme:SetElementProperty("text-size", 10)
TransparenceTheme:SetElementProperty("text-location", "CENTER")
TransparenceTheme:SetElementProperty("background-color", { r = 0, g = 0, b = 0, a = 0})
TransparenceTheme:SetElementProperty("border-color", { r = 0, g = 0, b = 0, a = 0})
-- ========================================================================== --
-- == Tracker properties
-- ========================================================================== --
TransparenceTheme:SetElementProperty("tracker.frame", "border-width", 0)
TransparenceTheme:SetElementProperty("tracker.scrollbar.thumb", "texture-color", { r = 1, g = 199/255, b = 0, a = 0})
-- ========================================================================== --
-- == Set Default block properties
-- ========================================================================== --
TransparenceTheme:SetElementProperty("block.header.text", "text-size", 14)
TransparenceTheme:SetElementProperty("block.header.text", "text-font", "PT Sans Narrow Bold")
TransparenceTheme:SetElementProperty("block.header", "background-color", { r = 0.11, g = 0.09, b = 0.11, a = 0.61})
TransparenceTheme:SetElementProperty("block.header", "border-color", { r = 0, g = 0, b = 0, a = 0.15})
TransparenceTheme:SetElementProperty("block.header.text", "text-color", { r = 0.18, g = 0.71, b = 1 })
TransparenceTheme:SetElementProperty("block.header.text", "text-location", "CENTER")
TransparenceTheme:SetElementProperty("block.header.text", "text-transform", "none")
TransparenceTheme:SetElementProperty("block.header.text", "text-justify-h", "CENTER")
TransparenceTheme:SetElementProperty("block.header.text", "text-justify-v", "MIDDLE")
-- Stripe properties
TransparenceTheme:SetElementProperty("block.header.stripe", "texture-color", { r = 0, g = 0, b = 0, a = 0})
