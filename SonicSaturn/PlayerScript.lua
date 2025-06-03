-- What could have been.
-- This project was a cancelled Sonic fangame.
-- Why was it cancelled? Because it was too ambitious.
-- For one, I couldn't program reliable physics engines at the time, so we used EgoMoose's gravity controller, but that was still buggy at times.
-- And for second, we literally had Super Bloxy 64 as well. This would have probably gone well if we didn't have SB64 to deal with. Just sayin'.
-- Doesn't mean I want to work on it again when I say that, by the way.

plr = game.Players.LocalPlayer
content = {"rbxassetid://5921965285"}
game:GetService("ContentProvider"):PreloadAsync(content)
repeat wait() until workspace[plr.Name] ~= nil
char = script.Parent
--// Module scripts!
States = require(script:WaitForChild("States"))
Effects = require(script:WaitForChild("Effects"))
Sounds = require(script:WaitForChild("Sounds"))
-- // Loading Animations
repeat wait() until char:WaitForChild("Humanoid") ~= nil
hum = char.Humanoid
cam = workspace.CurrentCamera
hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false) -- This is to prevent flings.
hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false) -- Disable climbing to prevent bugs.
local IdleTimer = 0 -- Timer for controlling when the "bored" animation should trigger.
local BoredTrigger = 20 -- Amount of seconds for the timer to reach to start playing the bored animation.
-- Load all the R15 animations.
local AnimationsFolderR15 = script.Animations
WalkAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Walk)
RunAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Run)
IdleAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Idle)
BoredAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.BoredIdle)
FallAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Fall)
Jump1Anim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Jump1)
Jump2Anim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Jump2)
DashAnim = char.Humanoid:LoadAnimation(AnimationsFolderR15.Dash)
AnimationTracks = char.Humanoid:GetPlayingAnimationTracks()
char:FindFirstChild("Animate"):Destroy()
for i, track in pairs (AnimationTracks) do
	track:Stop()
end
local pose = "None"

local grounded = true

BoredAnim:GetMarkerReachedSignal("Step"):Connect(function()
	Sounds.PlaySound(char.HumanoidRootPart, script.step.SoundId, script.step.Volume, script.step.PlaybackSpeed)
end)

WalkAnim:GetMarkerReachedSignal("Step"):Connect(function()
	-- Player has stepped, play the sound
	Sounds.PlaySound(char.HumanoidRootPart, script.step.SoundId, script.step.Volume, script.step.PlaybackSpeed)
end)

RunAnim:GetMarkerReachedSignal("Step"):Connect(function()
	-- Player has stepped, play the sound
	Sounds.PlaySound(char.HumanoidRootPart, script.step.SoundId, script.step.Volume, script.step.PlaybackSpeed)
end)

DashAnim:GetMarkerReachedSignal("Step"):Connect(function()
	-- Player has stepped, play the sound
	Sounds.PlaySound(char.HumanoidRootPart, script.step.SoundId, script.step.Volume, script.step.PlaybackSpeed)
end)


local chara = workspace:WaitForChild(plr.Name)
local human = chara.Humanoid

local speed = 0
cananimate = true

char.HumanoidRootPart:FindFirstChild("Running").Volume = 0 -- Turn off the default run sound effect.

human.Running:connect(function(s)
	speed = s
end)
local update = game:GetService("RunService")

-- Build a "RaycastParams" object
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
raycastParams.FilterDescendantsInstances = {char}
raycastParams.IgnoreWater = true
rootpart = char.HumanoidRootPart

ball = char:FindFirstChild("ball")
ball.Transparency = 1
AnimationSpeed = 1
FadeAmount1 = 0.5
FadeAmount2 = 0.2
SecondMach = 40
ThirdMach = 60
TopSpeed = 75
OnSlope = false

char.HumanoidRootPart:FindFirstChild("Jumping").SoundId = "rbxassetid://157626116"

update.RenderStepped:connect(function()
	local rootvel = rootpart.Velocity.Y
    if rootvel > 0 and not grounded then
	    pose = "Jumping"
		grounded = false
    end
    if rootvel < 0 and not grounded then
		pose = "Falling"
		grounded = false
    end
	if speed == 0 and grounded then
		pose = "Standing"
		grounded = true
		Jump1Anim:Stop()
		Jump2Anim:Stop()
	end
	if speed > 0 and grounded then
		pose = "Walking"
		grounded = true
		Jump1Anim:Stop()
		Jump2Anim:Stop()
	end
	local r = Ray.new(rootpart.Position, Vector3.new(0, -5, 0))
	local p, _, n = workspace:FindPartOnRayWithIgnoreList(r, {char})
	local vector = rootpart.CFrame:VectorToObjectSpace(n)
	if p then
	    if p.CanCollide ~= false then
		   rootpart.Root.C0 = CFrame.new(0,0,0,1,0,0,0,1,0,0,0,1) * CFrame.Angles(vector.z, 0, -vector.x)
		end
	else
		rootpart.Root.C0 = CFrame.new(0,0,0,1,0,0,0,1,0,0,0,1) * CFrame.Angles(0, 0, 0)
	end
	-- Material Footsteps
	local sound = game.SoundService.Footsteps:FindFirstChild(hum.FloorMaterial)
	if sound then
		script.step.SoundId = sound.SoundId
		script.step.Volume = sound.Volume
		script.step.PlaybackSpeed = sound.PlaybackSpeed
	end
	-- Slope Physics
	if rootvel > 5 and grounded and pose == "Walking" then
		char.Humanoid.WalkSpeed = math.clamp(char.Humanoid.WalkSpeed - 0.3, 13, TopSpeed)
		OnSlope = true
	elseif rootvel < -4 and grounded and pose == "Walking" then
		char.Humanoid.WalkSpeed = math.clamp(char.Humanoid.WalkSpeed + 1, 0, TopSpeed)
		OnSlope = true
	elseif rootvel <= 0 and rootvel >= -4 and pose == "Walking" then
		OnSlope = false
	end
end)
stage = 0
hum.StateChanged:connect(function(old, new)
	if old == Enum.HumanoidStateType.Freefall and new == Enum.HumanoidStateType.Landed then
		grounded = true
		States.ChangeState("Default")
		for i,v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 0
			end
		end
		ball.Transparency = 1
	elseif new == Enum.HumanoidStateType.Running or new == Enum.HumanoidStateType.RunningNoPhysics then
		grounded = true
		for i,v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
				v.Transparency = 0
			end
		end
		ball.Transparency = 1
	elseif new == Enum.HumanoidStateType.Freefall then
		grounded = false
	elseif new == Enum.HumanoidStateType.Jumping then
		grounded = false
	end
end)

bored = false

coroutine.wrap(function() -- Idle Timer
	while true do
		wait(0.5)
		if pose == "Standing" then
			-- Count up the timer by one.
			IdleTimer = math.clamp(IdleTimer + 1, 0, BoredTrigger + 1)
			if IdleTimer > BoredTrigger - 1 then
				-- The timer has reached the trigger, we are now bored.
				bored = true
			else
				-- If the timer has not reached the trigger, we aren't bored.
				bored = false
			end
		else
			-- The player is not in the standing state, reset the timer and the bored state (just in case)
			IdleTimer = 0
			bored = false
		end
	end
end)()

while true do
	    wait()
		AnimationTracks = hum:GetPlayingAnimationTracks()
		if pose == "Walking" and cananimate then
			if char.Humanoid.WalkSpeed < SecondMach then
				stage = 1
				for i, track in pairs (AnimationTracks) do
					if track ~= WalkAnim then
						track:Stop()
					end
				end
				WalkAnim:AdjustSpeed(AnimationSpeed)
				    if stage ~= 2 and stage ~= 3 then
					    if WalkAnim.IsPlaying ~= true then
						WalkAnim:Play()
					    end
				    end
			elseif char.Humanoid.WalkSpeed < ThirdMach then
				stage = 2
				for i, track in pairs (AnimationTracks) do
					if track ~= RunAnim and track ~= Jump1Anim and track ~= Jump2Anim then
						track:Stop(FadeAmount1)
					end
				end
				RunAnim:AdjustSpeed(AnimationSpeed)
				if stage ~= 1 and stage ~= 3 then
					if RunAnim.IsPlaying ~= true then
						RunAnim:Play(FadeAmount1)
					end
				end
			elseif char.Humanoid.WalkSpeed < TopSpeed + 1 then
				stage = 3
				for i, track in pairs (AnimationTracks) do
					if track ~= DashAnim and track ~= Jump1Anim and track ~= Jump2Anim then
						track:Stop(FadeAmount1)
					end
				end
				DashAnim:AdjustSpeed(AnimationSpeed)
				if stage ~= 1 and stage ~= 2 then
					if DashAnim.IsPlaying ~= true then
						DashAnim:Play(FadeAmount1)
					end
				end
			end
		end
		if pose == "Walking" and cananimate then
			if not OnSlope then
				char.Humanoid.WalkSpeed = math.clamp(char.Humanoid.WalkSpeed + 1, 0, TopSpeed)
			end
		    AnimationSpeed = math.clamp(human.WalkSpeed / 15, 1, 2.5)
		end
		if pose == "Standing" and cananimate then
			for i, track in pairs (AnimationTracks) do
				if track ~= IdleAnim and track ~= BoredAnim then
					track:Stop()
				end
		    end
			AnimationSpeed = 1
			if script.MaxSpeed.Value ~= true then
				char.Humanoid.WalkSpeed = 13
		    end
		    if bored then
			   IdleAnim:Stop()
		    end
		    if IdleAnim.IsPlaying ~= true and BoredAnim.IsPlaying ~= true then
			    if not bored then
				   IdleAnim:Play()
			    else
				   BoredAnim:Play()
			    end
			end
		elseif pose == "Jumping" and cananimate then
			Jump1Anim:AdjustSpeed(AnimationSpeed)
			if char.Humanoid.WalkSpeed > SecondMach and char.Humanoid.WalkSpeed < ThirdMach then
				AnimationSpeed = 3
			elseif char.Humanoid.WalkSpeed > ThirdMach then
				AnimationSpeed = 4
			end
			for i, track in pairs (AnimationTracks) do
				if track ~= Jump1Anim and track ~= Jump2Anim then
					track:Stop()
				end
			end
			if States:GetState() == "Spring" then
				Jump1Anim:Stop()
				for i,v in pairs(char:GetChildren()) do
					if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
						v.Transparency = 0
					end
				end
				ball.Transparency = 1
			end
			if Jump1Anim.IsPlaying ~= true and Jump2Anim.IsPlaying ~= true then
				if States:GetState() ~= "Spring" then
					for i,v in pairs(char:GetChildren()) do
						if v:IsA("BasePart") and v.Name ~= "ball" then
							v.Transparency = 1
						end
					end
					ball.Transparency = 0
					Jump1Anim:Play()
				else
					for i,v in pairs(char:GetChildren()) do
						if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
							v.Transparency = 0
						end
					end
					ball.Transparency = 1
					Jump1Anim:Stop()
					Jump2Anim:Play()
				end
			end
		elseif pose == "Falling" and cananimate then
			for i, track in pairs (AnimationTracks) do
				if track ~= FallAnim and track ~= Jump1Anim then
					track:Stop(FadeAmount2)
				end
			end
			if FallAnim.IsPlaying ~= true and Jump1Anim.IsPlaying ~= true then
				FallAnim:Play(FadeAmount2)
			end
	end
end
