--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                  "EskaTracker.BFA"                                    ""
--============================================================================--
namespace                "EKT"
-- This file and this class is used for supporting Battle of Azeroth expasion and
-- in keeping the live version support.
class "BFASupport" (function(_ENV)
  -- Add here Static support function
  __Static__() property "isBFA" { TYPE = Boolean, DEFAULT = function() return select(4, GetBuildInfo()) >= 80000 end}
end)
