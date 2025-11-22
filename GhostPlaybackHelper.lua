-- Helper module to be paired with Ghost Generator. 
-- Allows you to make a model playback a Ghost Generator recording.
-- Created by Triarawn, 11/21/2025
-- :]

local playbackHelper = {}

type PlaybackChunk = { -- A chunk of playback data, used to store movement.
	Position:CFrame,
	AnimationsPlaying:{string},
	CurrHumState:string
}
-- LerpTime determines how smooth you want the playback to be. Set it to 1 to have it be choppy.
-- Having a low LerpTime makes it appear smoother, and more like an actual player.
playbackHelper.LerpTime = 0.25
playbackHelper.RecordingStorage = game.ReplicatedStorage.GameStorage.GhostPlaybacks -- This is where all recordings will be stored.
playbackHelper.playbacksActive = {}
local smoothness_factor = 0.01585420034825802

local rand = function()
	return math.random(2147483647)
end

local ids = {
	
}


local runService = game:GetService("RunService")
function doPlayback(Model, data_piece)
	local playback_info = {
		["AlreadyPlayingAnims"] = {},
		["NextTargetedPosition"] = data_piece[1].Position,
	}
	-- Make the model play the recording
	local has_humanoid = Model:FindFirstChildOfClass("Humanoid") ~= nil
	Model.PrimaryPart.CFrame = data_piece[1].Position -- eliminate that weird zooming issue
	ids[Model] = rand()
	runService:BindToRenderStep("UpdateGhostPlayback" .. ids[Model], Enum.RenderPriority.Last.Value, function(deltaTime)
		Model.PrimaryPart.CFrame = Model.PrimaryPart.CFrame:Lerp(playback_info.NextTargetedPosition, (playbackHelper.LerpTime / smoothness_factor) * deltaTime)
	end)
	for i : number,v : PlaybackChunk in pairs(data_piece) do
		if (typeof(v) == "table") then
			task.wait(1/20) -- "Framerate" of the recording.
			-- Lerp to our new position
			playback_info.NextTargetedPosition = v.Position
			-- Set our HumanoidState
			if has_humanoid == true then
				Model.Humanoid:ChangeState(Enum.HumanoidStateType:FromName(v.CurrHumState))
			end
			local loader = has_humanoid == true and Model.Humanoid or Model.AnimationController
			-- Now play animations
			local ids = {}
			for _,q in pairs(v.AnimationsPlaying) do
				-- load our Animation onto it
				local id = "nil"
				local speed = 1
				if typeof(q) == "string" then
					-- Old format 
					id = q
					speed = 1
				elseif typeof(q) == "table" then
					-- New format
					id = q[1]
					speed = q[2]
				end
				table.insert(ids, id)
				if playback_info.AlreadyPlayingAnims[id] == nil then
					local animinst = Instance.new("Animation")
					animinst.AnimationId = id
					local anim : AnimationTrack = loader:LoadAnimation(animinst)
					anim:AdjustSpeed(speed)
					playback_info.AlreadyPlayingAnims[id] = anim
					anim:Play()
				else
					local anim = playback_info.AlreadyPlayingAnims[id]
					if (anim.IsPlaying == false) then
						anim:Play()
					end
					anim:AdjustSpeed(speed) -- adjust speed always so it doesn't look weird
				end
			end
			-- Check if any playing animations are playing (even when they're not mentioned)
			for a : string, c : AnimationTrack in pairs(playback_info.AlreadyPlayingAnims) do
				if c.IsPlaying == true and table.find(ids, c.Animation.AnimationId) == nil then
					c:Stop() -- Stop it if it's playing
				end
			end
		elseif (typeof(v) == "string") then
			-- This is a split, find the other recording from storage and playback that until we're finished.
			runService:UnbindFromRenderStep("UpdateGhostPlayback" .. ids[Model])
			doPlayback(Model, require(playbackHelper.RecordingStorage[v]))
			break
		end
	end
end


function playbackHelper.playGhostRecording(Model : Model, Recording : ModuleScript)
	-- Plays back a recording, from start to finish.
	if Model.PrimaryPart == nil then
		warn("GhostPlaybackHelper: Unable to play recording! (PrimaryPart is nil)")
	else
		local oldPos = Model.PrimaryPart.CFrame
		local data_piece = require(Recording)
		playbackHelper.playbacksActive[Model] = true
		doPlayback(Model, data_piece)
		playbackHelper.playbacksActive[Model] = nil
		print("Finished playback!")
		local has_humanoid = Model:FindFirstChildOfClass("Humanoid") ~= nil
		local loader = has_humanoid == true and Model.Humanoid or Model.AnimationController
		runService:UnbindFromRenderStep("UpdateGhostPlayback" .. ids[Model])
		Model.PrimaryPart.CFrame = oldPos
		for i,v in pairs(loader:GetPlayingAnimationTracks()) do
			v:Stop()
		end
	end
end


return playbackHelper
