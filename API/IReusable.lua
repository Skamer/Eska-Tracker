--============================================================================--
--                         Eska Tracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Eska                  "EskaTracker.API.IReusable"                             ""
--============================================================================--
namespace "EKT"
--============================================================================--
interface "IReusable" (function(_ENV)
  ------------------------------------------------------------------------------
  --                             Handlers                                     --
  ------------------------------------------------------------------------------
  local function IsReusableChanged(self, new, old, prop)
    if new == true then
      if self.Reset then
        self:Reset()
      end

      ObjectManager:Recycle(self)
    else
      if Class.ObjectIsClass(self, Frame) then

      end
    end

  end
  ------------------------------------------------------------------------------
  --                            Properties                                    --
  ------------------------------------------------------------------------------
  property "isReusable" { TYPE = Boolean, DEFAULT = false, HANDLER = IsReusableChanged }

end)
