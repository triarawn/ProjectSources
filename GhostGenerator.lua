-- Ghost Generator. Generates Ghost Data that you can play back!
-- Coded by Hexibin, 11/21/2025
-- Last Updated 3/4/2026

local toolbar = plugin:CreateToolbar("Ghost Generator")
local recordButton = toolbar:CreateButton("Start Recording", "Start recording a Ghost", "rbxassetid://115273269847299")
local stopRecording = toolbar:CreateButton("Stop Recording", "Stop recording a Ghost, if active", "rbxassetid://73145794492715")

stopRecording.Enabled = false

type AnimationChunk = { -- A chunk of animation data.
	ID:string,
	Speed:number,
	Priority:string,
	Weight:number
}

type PlaybackChunk = { -- A chunk of playback data, used to store movement.
	Position:CFrame,
	AnimationsPlaying:{AnimationChunk},
	CurrHumState:Enum.HumanoidStateType
}

local recording = false
local recording_name = "LastPlaybackData"
local recording_playback_data : {PlaybackChunk} = {}
local MAX_SIZE_UNTIL_SPLIT = 200 -- How many chunks until we have to split? 

local SpecialCharacters = {['\a'] = '\\a', ['\b'] = '\\b', ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t', ['\v'] = '\\v', ['\0'] = '\\0'}
local Keywords = { ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true, ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true, ['function'] = true, ['if'] = true, ['in'] = true, ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true, ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true, ['until'] = true, ['while'] = true, ['continue'] = true}
local Functions = {[CFrame.new] = "CFrame.new";}

function GetHierarchy(Object)
	local Hierarchy = {}

	local ChainLength = 1
	local Parent = Object

	while Parent do
		Parent = Parent.Parent
		ChainLength = ChainLength + 1
	end

	Parent = Object
	local Num = 0
	while Parent do
		Num = Num + 1

		local ObjName = string.gsub(Parent.Name, '[%c%z]', SpecialCharacters)
		ObjName = Parent == game and 'game' or ObjName

		if Keywords[ObjName] or not string.match(ObjName, '^[_%a][_%w]*$') then
			ObjName = '["' .. ObjName .. '"]'
		elseif Num ~= ChainLength - 1 then
			ObjName = '.' .. ObjName
		end

		Hierarchy[ChainLength - Num] = ObjName
		Parent = Parent.Parent
	end

	return table.concat(Hierarchy)
end
local function SerializeType(Value, Class)
	if Class == 'string' then
		-- Not using %q as it messes up the special characters fix
		return string.format('"%s"', string.gsub(Value, '[%c%z]', SpecialCharacters))
	elseif Class == 'Instance' then
		return GetHierarchy(Value)
	elseif type(Value) ~= Class then -- CFrame, Vector3, UDim2, ...
		return Class .. '.new(' .. tostring(Value) .. ')'
	elseif Class == 'thread' then
		return '\'' .. tostring(Value) ..  ', status: ' .. coroutine.status(Value) .. '\''
	else -- thread, number, boolean, nil, ...
		return tostring(Value)
	end
end
local function TableToString(Table, IgnoredTables, DepthData, Path)
	IgnoredTables = IgnoredTables or {}
	local CyclicData = IgnoredTables[Table]
	if CyclicData then
		return ((CyclicData[1] == DepthData[1] - 1 and '\'[Cyclic Parent ' or '\'[Cyclic ') .. tostring(Table) .. ', path: ' .. CyclicData[2] .. ']\'')
	end

	Path = Path or 'ROOT'
	DepthData = DepthData or {0, Path}
	local Depth = DepthData[1] + 1
	DepthData[1] = Depth
	DepthData[2] = Path

	IgnoredTables[Table] = DepthData
	local Tab = string.rep('    ', Depth)
	local TrailingTab = string.rep('    ', Depth - 1)
	local Result = '{'

	local LineTab = '\n' .. Tab
	local HasOrder = true
	local Index = 1

	local IsEmpty = true
	for Key, Value in next, Table do
		IsEmpty = false
		if Index ~= Key then
			HasOrder = false
		else
			Index = Index + 1
		end

		local KeyClass, ValueClass = typeof(Key), typeof(Value)
		local HasBrackets = false
		if KeyClass == 'string' then
			Key = string.gsub(Key, '[%c%z]', SpecialCharacters)
			if Keywords[Key] or not string.match(Key, '^[_%a][_%w]*$') then
				HasBrackets = true
				Key = string.format('["%s"]', Key)
			end
		else
			HasBrackets = true
			Key = '[' .. (KeyClass == 'table' and string.gsub(TableToString(Key, IgnoredTables, {Depth, Path}), '^%s*(.-)%s*$', '%1') or SerializeType(Key, KeyClass)) .. ']'
		end

		Value = ValueClass == 'table' and TableToString(Value, IgnoredTables, {Depth, Path}, Path .. (HasBrackets and '' or '.') .. Key) or SerializeType(Value, ValueClass)
		Result = Result .. LineTab .. (HasOrder and Value or Key .. ' = ' .. Value) .. ','
	end

	return IsEmpty and Result .. '}' or string.sub(Result,  1, -2) .. '\n' .. TrailingTab .. '}'
end

local RunService = game:GetService("RunService")
local StudioService = game:GetService("StudioService")

local record_beep = Instance.new("Sound", script)
record_beep.SoundId = "rbxassetid://908892507"
record_beep.Volume = 1
local record_finish = Instance.new("Sound", script)
record_finish.SoundId = "rbxassetid://114717620978137"
record_finish.Volume = 1

local plr = game.Players:GetPlayerByUserId(StudioService:GetUserId())

recordButton.Click:Connect(function()
	-- Check if we're in the game
	local running = RunService:IsRunning()
	if running == true then
		-- Ask for the recording name
		local ScreenGui = Instance.new("ScreenGui", plr.PlayerGui)
		ScreenGui.DisplayOrder = 8000
		local TextBox = Instance.new("TextBox", ScreenGui)
		TextBox.Position = UDim2.new(0.5,0,0.5,0)
		TextBox.Size = UDim2.new(0.4,0,0.05,0)
		TextBox.PlaceholderText = "Recording name.."
		TextBox.Text = ""
		TextBox.TextScaled = true
		TextBox.AnchorPoint = Vector2.new(0.5,0.5)
		TextBox.FocusLost:Wait()
		recording_name = TextBox.Text
		ScreenGui:Destroy()
		table.clear(recording_playback_data)
		-- We start recording
		recording = true
		print("Recording!!")
		record_beep:Play()
		recordButton.Enabled = false
		stopRecording.Enabled = true
	else
		warn("A game must be currently running in order to record a Ghost playback!")
	end
end)

stopRecording.Click:Connect(function()
	-- Check if we're recording
	if recording == true then
		-- Save our playback data to a ModuleScript
		print("Saving playback data...")
		local current_split_data = {}
		local SplitName = recording_name
		local splits = 0
		
		local function CreateModuleScript(name, table)
			local module_script = Instance.new("ModuleScript")
			module_script.Source = "return " .. TableToString(table)
			module_script.Name = name
			module_script.Parent = game.ReplicatedFirst
		end
	
		
		if #recording_playback_data > MAX_SIZE_UNTIL_SPLIT then
			local c = 0
			for i,v in pairs(recording_playback_data) do
				c += 1
				if c > MAX_SIZE_UNTIL_SPLIT then
					-- we need to split
					c = c - MAX_SIZE_UNTIL_SPLIT
					splits += 1
					SplitName = recording_name .. "_split" .. splits
					table.insert(current_split_data, recording_name .. "_split" .. splits + 1)
					-- Save to a moduleScript
					CreateModuleScript(SplitName, current_split_data)
					table.clear(current_split_data)
				else
					table.insert(current_split_data, v)
				end
			end
			if #current_split_data < MAX_SIZE_UNTIL_SPLIT then
				SplitName = recording_name .. "_split" .. splits + 1
				CreateModuleScript(SplitName, current_split_data)
			end
		else
			CreateModuleScript(recording_name, recording_playback_data)
		end
		
		record_finish:Play()
		recordButton.Enabled = true
		stopRecording.Enabled = false
		
		print("Saved playback data! You can find it in ReplicatedFirst!")
	end
end)

while true do
	task.wait(1/20)
	if (recording == true) then
		if (RunService:IsRunning() == false) then
			recording = false
		else
			-- We initated a recording, that must mean we're in playtest mode.
			local char = plr.Character 
			if char ~= nil then
				local tracks = {}
				local anims = char.Humanoid.Animator:GetPlayingAnimationTracks()
				local state : Enum.HumanoidStateType = char.Humanoid:GetState()
				for i,v : AnimationTrack in pairs(anims) do
					local animchunk : AnimationChunk = {
						ID = v.Animation.AnimationId -- ID will always be there, that's the one thing we need.
					}
					if (v.Priority ~= Enum.AnimationPriority.Core) then
						-- If our Priority is Core, don't save it.
						animchunk.Priority = v.Priority.Name
					end
					if (v.WeightCurrent ~= 1) then
						-- If our Weight equals one, don't save it.
						animchunk.Weight = v.WeightCurrent
					end
					if (v.Speed ~= 1) then
						-- If our Speed equals one, don't save it.
						animchunk.Speed = v.Speed
					end
					table.insert(tracks, animchunk)
				end
				local chunk : PlaybackChunk = {
					Position=char.PrimaryPart.CFrame,
					AnimationsPlaying=tracks,
					CurrHumState=state.Name
				}
				-- Save our current playback data.
				table.insert(recording_playback_data, chunk)
			end
		end
	end
end
