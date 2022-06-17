local AT = require(game.ReplicatedStorage.AnimationTrack)

local Track = AT.new(script.RightPunch, workspace.R15)
Track.Looped = true
Track.InstantAnimation = false
Track:Play()