--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
import "EKT"
--============================================================================--
local EskaTheme = Theme()
EskaTheme.name    = "Eska"
EskaTheme.author  = "Skamer"
EskaTheme.version = "1.0.0"
EskaTheme.stage   = "Alpha"
Themes:Register(EskaTheme)
-- ========================================================================== --
-- == Set Default properties
-- ========================================================================== --
EskaTheme:SetElementProperty("text-size", 10)
EskaTheme:SetElementProperty("text-offsetX", 0)
EskaTheme:SetElementProperty("text-offsetY", 0)
EskaTheme:SetElementProperty("text-location", "CENTER")
EskaTheme:SetElementProperty("background-color", { r = 0, g = 0, b = 0, a = 0})
-- ========================================================================== --
-- == Tracker properties
-- ========================================================================== --
EskaTheme:SetElementProperty("tracker.frame", "background-color", { r = 125/255, g = 125/255, b = 125/255, a = 0.25 })
EskaTheme:SetElementProperty("tracker.frame", "border-color", { r = 0.1, g = 0.1, b = 0.1})
  -- Scrollbar
  EskaTheme:SetElementProperty("tracker.scrollbar", "background-color", { r = 0, g = 0, b = 0, a = 0.5})
  EskaTheme:SetElementProperty("tracker.scrollbar", "border-color", { r = 0, g = 0, b = 0 })
  -- Scrollbar thumb
  EskaTheme:SetElementProperty("tracker.scrollbar.thumb", "texture-color", { r = 1, g = 199/255, b = 0, a = 1})
-- ========================================================================== --
-- == Set Default block properties
-- ========================================================================== --
-- EskaTheme:SetElementProperty("block.*", "background-color", { r = 0, g = 0, b = 0, a = 0})
EskaTheme:SetElementProperty("block.*", "border-color", { r = 0, g = 0, b = 0, a = 0 })
-- Header properties
EskaTheme:SetElementProperty("block.header", "background-color", { r = 0, g = 0, b = 0, a = 0.5 })
EskaTheme:SetElementProperty("block.header", "border-color", { r = 0, g = 0, b = 0, a = 1})
EskaTheme:SetElementProperty("block.header.text", "text-size", 14)
EskaTheme:SetElementProperty("block.header.text", "text-color", { r = 0, g = 199/255, b = 1})
EskaTheme:SetElementProperty("block.header.text", "text-font", "PT Sans Narrow Bold")
EskaTheme:SetElementProperty("block.header.text", "text-transform", "none")
EskaTheme:SetElementProperty("block.header.text", "text-justify-h", "CENTER")
EskaTheme:SetElementProperty("block.header.text", "text-justify-v", "MIDDLE")
-- Stripe properties
EskaTheme:SetElementProperty("block.header.stripe", "texture-color", { r = 0, g = 0, b = 0, a = 0.5})
