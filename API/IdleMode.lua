--============================================================================--
--                          EskaTracker                                       --
-- Author     : Skamer <https://mods.curse.com/members/DevSkamer>             --
-- Website    : https://wow.curseforge.com/projects/eskatracker               --
--============================================================================--
Scorpio                     "EskaTracker.API.IdleMode"                        ""
--============================================================================--
namespace                          "EKT"
--============================================================================--
struct "IdleModeCountdown" (function(_ENV)
  member "paused" { TYPE = Boolean, DEFAULT = false }
  member "elapsed" { TYPE = Number, DEFAULT = 0 }
  member "duration" { TYpE = Number, DEFAULT = 0 }
end)

class "IdleMode" (function(_ENV)
  ENABLED_TRACKER = setmetatable({}, { __mode = "k"})
  TRACKER_COUNTDOWNS = Dictionary()
  BLOCK_COUNTDOWNS = Dictionary()

  function EnableForTracker(self, tracker)
    ENABLED_TRACKER[tracker] = true
  end

  function DisableForTracker(self, tracker)
    ENABLED_TRACKER[tracker] = nil
  end

  __Arguments__ { ClassType, Block, Any,  Variable.Optional(Number, 0), Variable.Optional(Boolean, false) }
  __Static__() function AddCountdown(self, block, id, duration, paused)
    local countdowns = BLOCK_COUNTDOWNS[block]
    if not countdowns then
      countdowns = Dictionary()
      BLOCK_COUNTDOWNS[block] = countdowns
    end

    countdowns[id] = IdleModeCountdown(paused, nil, duration)
  end

  __Arguments__ { ClassType, Tracker, Any,  Variable.Optional(Number, 0), Variable.Optional(Boolean, false) }
  __Static__() function AddCountdown(self, tracker, id, duration, paused)
    local countdowns = TRACKER_COUNTDOWNS[tracker]
    if not countdowns then
      countdowns = Dictionary()
      TRACKER_COUNTDOWNS[tracker] = countdowns
    end

    countdowns[id] = IdleModeCountdown(paused, nil, duration)
  end

  __Arguments__ { ClassType, Tracker, Any }
  __Static__() function ResumeCountdown(self, tracker, id)
    local countdowns = TRACKER_COUNTDOWNS[tracker]
    if countdowns then
      if countdowns[id] then
        countdowns[id].paused = false
      end
    end
  end

  __Arguments__ { ClassType, Block, Any }
  __Static__() function ResumeCountdown(self, tracker, id)
    local countdowns = BLOCK_COUNTDOWNS[tracker]
    if countdowns then
      if countdowns[id] then
        countdowns[id].paused = false
      end
    end
  end

  __Arguments__ { ClassType, Tracker, Any }
  __Static__() function PauseCountdown(self, tracker, id)
    local countdowns = TRACKER_COUNTDOWNS[tracker]
    if countdowns then
      if countdowns[id] then
        countdowns[id].paused = true
      end
    end
  end

  __Arguments__ { ClassType, Block, Any }
  __Static__() function PauseCountdown(self, tracker, id)
    local countdowns = BLOCK_COUNTDOWNS[tracker]
    if countdowns then
      if countdowns[id] then
        countdowns[id].paused = true
      end
    end
  end

  __Arguments__ { ClassType, Dictionary, Number }
  __Static__() function UpdateCountdowns(self, countdowns, delta)
    for id, info in countdowns:GetIterator() do
      if not info.paused then
        info.elapsed = info.elapsed + delta
      end
    end
  end

  __Arguments__ { ClassType, Number }
  __Static__() function UpdateCountdowns(self, delta)
    for block, countdowns in BLOCK_COUNTDOWNS:GetIterator() do
      self:UpdateCountdowns(countdowns, delta)
    end

    for tracker, countdowns in TRACKER_COUNTDOWNS:GetIterator() do
      self:UpdateCountdowns(countdowns, delta)
    end
  end

  __Arguments__ { ClassType, Number, Number, Number }
  __Static__() function GetEffectiveElapsed(self,  elapsed, duration, inactivityTimer)
    if duration == 0 or elapsed >= duration then
      return elapsed
    end

    return inactivityTimer - (duration - elapsed)
  end

  __Arguments__ { ClassType, Tracker }
  __Static__() function GetEffectiveCountdown(self, tracker)
    local inactivityTimer = tracker.inactivityTimer
    local minimumElapsed = inactivityTimer
    local minimumElapsedID

    local trackerCountdowns = TRACKER_COUNTDOWNS[tracker]
    if trackerCountdowns then
      for id, info in trackerCountdowns:GetIterator() do
        local elapsed = self:GetEffectiveElapsed(info.elapsed, info.duration, inactivityTimer)
        if elapsed < minimumElapsed then
          minimumElapsed = elapsed
          minimumElapsedID = id
        end

        if elapsed >= inactivityTimer then
          trackerCountdowns[id] = nil
        end
      end
    end

    for _, block in tracker.blocks:GetIterator() do
      local blockCountdowns = BLOCK_COUNTDOWNS[block]
      if blockCountdowns then
        for id, info in blockCountdowns:GetIterator() do
          local elapsed = self:GetEffectiveElapsed(info.elapsed, info.duration, inactivityTimer)
          if elapsed < minimumElapsed then
            minimumElapsed = elapsed
            minimumElapsedID = id
          end

          if elapsed >= inactivityTimer then
            blockCountdowns[id] = nil
          end
        end
      end
    end

    return minimumElapsed, minimumElapsedID
  end




  __Async__() __Static__() function StartInactivityTicker(self)
    if self.inactivityTickerStarted then
      return
    end

    self.inactivityTickerStarted = true

    -- Update Rate
    local updateRate = 0.1

    while self.enabled do
      Delay(updateRate)
      self:UpdateCountdowns(updateRate)

      for tracker in pairs(ENABLED_TRACKER) do
        local elapsed, id = self:GetEffectiveCountdown(tracker)
        if self.enabled and elapsed >= tracker.inactivityTimer then
          tracker.isInIdleMode = true
        else
          tracker.isInIdleMode = false
        end
      end
    end

    self.inactivityTickerStarted = nil

  end

  local function UpdateEnabled(self, new, old, prop)
    if new then
      IdleMode:StartInactivityTicker()
    end
  end

  __Static__() property "enabled" { TYPE = Boolean, DEFAULT = false, HANDLER = UpdateEnabled }
  __Static__() property "inactivityTickerStarted" { TYPE = Boolean, DEFAULT = false }

end)


function OnLoad(self)
  Settings:Register("idle-mode-enabled", false, "idle-mode/enable")

  CallbackHandlers:Register("idle-mode/enable", CallbackHandler(function(enabled)
    IdleMode.enabled = enabled
  end))

  IdleMode.enabled = Settings:Get("idle-mode-enabled")
end
