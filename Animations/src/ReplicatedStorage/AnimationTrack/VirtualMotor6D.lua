local VirtualMotor = {}
VirtualMotor.__index = VirtualMotor

local BoatTween = require(script.Parent.BoatTween)

function VirtualMotor.new(Motor6D)
	local self = setmetatable({}, VirtualMotor)
	self.Motor6D = Motor6D
	self._Transform = Instance.new("CFrameValue")
	return self
end

function VirtualMotor:Transform(TweenInfo, FinalTransform)
	if not TweenInfo and FinalTransform then
		--No tweening
		self._Transform.Value = FinalTransform
		return
	end
	local Tween = BoatTween:Create(self._Transform, {
		Time = TweenInfo.Time;
		EasingStyle = TweenInfo.EasingStyle;
		EasingDirection = TweenInfo.EasingDirection;
		Reverses = TweenInfo.Reverses;
		DelayTime = TweenInfo.DelayTime;
		RepeatCount = TweenInfo.RepeatCount;
		StepType = "Stepped";
		Goal = {
			Value = FinalTransform;
		}
	})
	
	Tween:Play()
	Tween.Completed:Connect(function()
		Tween:Destroy()
	end)
end

function VirtualMotor:ApplyTransform()
	self.Motor6D.Transform = self._Transform.Value
end

return VirtualMotor