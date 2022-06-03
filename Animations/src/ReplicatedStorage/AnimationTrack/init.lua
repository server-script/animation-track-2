local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack

local RunSvc = game:GetService("RunService")
local TweenSvc = game:GetService("TweenService")
local Bindable = Instance.new("BindableEvent")

local Animation = require(script.Animation)
local VirtualMtr6D = require(script.VirtualMotor6D)

local function sortKeyframes(kf1 : Keyframe, kf2 : Keyframe)
	return kf1.Time < kf2.Time
end

function AnimationTrack.new(KeyframeSequence : KeyframeSequence, Rig : Model)
	local self = setmetatable({}, AnimationTrack)
	self.Time = 0 --To emulate the original behaviour.
	self.IsPlaying = false
	self.Looped = KeyframeSequence.Loop
	self.Priority = KeyframeSequence.Priority
	self.TimePosition = 0
	
	--READ-ONLY
	self._Speed = 1
	self._FadeTime = .1
	self._WeightCurrent = 1
	self._WeightTarget = 1
	self._Rig = Rig
	
	--INTERNALS
	self._Virtual6Ds = {}
	
	--CACHE
	self._KeyframeReachedEvents = {}
	self._Motor6Ds = {}
	self._SteppedEvent = nil
	self._CurrentTweenTbl = {}
	self._CurrentDuration = 0
	
	--EVENTS
	self._DidLoopEvent = Bindable:Clone()
	self._StoppedEvent = Bindable:Clone()
	self._KeyframeReachedEvent = Bindable:Clone()
	
	self.Animation = Animation.new()
	
	self:_Load(KeyframeSequence)
	return self
end

function AnimationTrack:_Load(KeyframeSequence : KeyframeSequence)
	self._OrganizedKeyframes = KeyframeSequence:GetChildren()
	table.sort(self._OrganizedKeyframes, sortKeyframes)
	self.Length = self._OrganizedKeyframes[#self._OrganizedKeyframes].Time
	for _, v in ipairs(self._Rig:GetChildren()) do
		local Motor = v:FindFirstChildWhichIsA("Motor6D")
		if Motor and Motor.Part1 == v then
			self._Motor6Ds[v.Name] = Motor
			self._Virtual6Ds[v.Name] = VirtualMtr6D.new(Motor)
			print(v.Name)
		end
	end
end

local function poseHasChildren(pose: Pose)
	return #(pose:GetChildren()) > 0
end

local function setHrpTransform(self, pose)
	local Info = {
		Time = self._CurrentKFTime;
		EasingStyle = (string.split(tostring(pose.EasingStyle), "."))[3];
		EasingDirection = (string.split(tostring(pose.EasingDirection), "."))[3];
		Reverses = false; --Subject to change
		DelayTime = 0;
		RepeatCount = 0;
	}
	self._Virtual6Ds[pose.Name]:Transform(nil, pose.CFrame)
end

--The first keyframe just sets the CFrames of the motors of the rig.
local function fromParentPoseOfK1(self, children)
	--setHrpTransform(self, self._OrganizedKeyframes[1].HumanoidRootPart)
	
	for _, pose : Pose in ipairs(children or self._OrganizedKeyframes[1].HumanoidRootPart:GetChildren()) do
		local Info = {
			Time = self._CurrentKFTime;
			EasingStyle = (string.split(tostring(pose.EasingStyle), "."))[3];
			EasingDirection = (string.split(tostring(pose.EasingDirection), "."))[3];
			Reverses = false; --Subject to change
			DelayTime = 0;
			RepeatCount = 0;
		}
		self._Virtual6Ds[pose.Name]:Transform(nil, pose.CFrame)
		if poseHasChildren(pose) then
			fromParentPoseOfK1(self, pose:GetSubPoses())
		end
	end
end

local function fromParentPose(self, nextKeyframe, children)
	--setHrpTransform(self, nextKeyframe.HumanoidRootPart)
	
	for _, pose : Pose in ipairs(children or nextKeyframe.HumanoidRootPart:GetChildren()) do
		local Info = {
			Time = self._CurrentKFTime;
			EasingStyle = (string.split(tostring(pose.EasingStyle), "."))[3];
			EasingDirection = (string.split(tostring(pose.EasingDirection), "."))[3];
			Reverses = false; --Subject to change
			DelayTime = 0;
			RepeatCount = 0;
		}
		
		self._Virtual6Ds[pose.Name]:Transform(Info, pose.CFrame)
		if poseHasChildren(pose) then
			fromParentPose(self, nextKeyframe, pose:GetSubPoses())
		end
	end
end

function AnimationTrack:_InitFirstKf()
	fromParentPoseOfK1(self)
end

function AnimationTrack:_InitRestOfKfs(NextKeyframe)
	fromParentPose(self, NextKeyframe)
end

function AnimationTrack:_LoopPlay()
	print("k")
	while self.IsPlaying do
		for i, kf : Keyframe in ipairs(self._OrganizedKeyframes) do
			local kf_begin = os.clock()
			local NextKf : Keyframe = self._OrganizedKeyframes[i + 1] 
			if NextKf then
				self._CurrentKFTime =  math.abs(NextKf.Time - kf.Time)
				self:_InitRestOfKfs(NextKf)
				repeat task.wait() until (os.clock()-kf_begin) >= self._CurrentKFTime
			else
				self._CurrentKFTime =  .1
				self:_InitRestOfKfs(kf)
			end
			print("KF")
		end
		RunSvc.Stepped:Wait()
	end
end

function AnimationTrack:_Play()
	for i, kf : Keyframe in ipairs(self._OrganizedKeyframes) do
		local kf_begin = os.clock()
		local NextKf : Keyframe = self._OrganizedKeyframes[i + 1] 
		if NextKf then
			self._CurrentKFTime =  math.abs(NextKf.Time - kf.Time)
			self:_InitRestOfKfs(NextKf)
			repeat task.wait() until (os.clock()-kf_begin) >= self._CurrentKFTime
		else
			self._CurrentKFTime =  .1
			self:_InitRestOfKfs(kf)
		end
		print("KF")
	end
end

function AnimationTrack:Play()
	--self._SteppedEvent = RunSvc.Stepped:Connect(function(time, deltaTime)
	coroutine.wrap(function()
		self.IsPlaying = true
		self._SteppedEvent = RunSvc.Stepped:Connect(function()
			for MotorName, VMotor in pairs(self._Virtual6Ds) do
				VMotor:ApplyTransform()
			end
		end)
	
		self:_InitFirstKf()

		--Keyframes begin playing here.
		if self.Looped then
			self:_LoopPlay()
		else
			self:_Play()
		end
	end)()
end

function AnimationTrack:AdjustSpeed(speed: number)
	self._Speed = speed
end

function AnimationTrack:AdjustWeight(weight: number, fadeTime: number?)
	self._WeightTarget = weight
	self._FadeTime = fadeTime or .1
end

--EVENTS
function AnimationTrack:DidLoop() : RBXScriptSignal
	return self._DidLoopEvent.Event
end

function AnimationTrack:Stopped() : RBXScriptSignal
	return self._StoppedEvent.Event
end

function AnimationTrack:KeyframeReached(keyframeName: string) : RBXScriptSignal
	if not self._KeyframeReachedEvents[keyframeName] then
		local event = self._KeyframeReachedEvent:Clone()
		return event.Event
	end
	return self._KeyframeReachedEvents[keyframeName]
end

return AnimationTrack