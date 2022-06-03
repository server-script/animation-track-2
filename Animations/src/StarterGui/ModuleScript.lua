local keyfr = game:GetService("KeyframeSequenceProvider")

local animationid = keyfr:RegisterKeyframeSequence(script.CombatIdle_Boxing)

local anim = Instance.new("Animation")
anim.AnimationId = animationid

local track = workspace.R15.Humanoid.Animator:LoadAnimation(anim)
while true do
	task.wait(1)
	print(track.Length)
end