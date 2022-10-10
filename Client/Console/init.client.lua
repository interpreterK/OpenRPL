local S = setmetatable({}, {
	__index = function(self,i)
		if not rawget(self,i) then
			self[i] = game:GetService(i)
		end
		return rawget(self,i)
	end
})

local Players    = S.Players
local Storage    = S.ReplicatedStorage
local LogService = S.LogService

local Player = Players.LocalPlayer

local find, remove = table.find, table.remove
local resume, create = coroutine.resume, coroutine.create
local wait = task.wait
local C3, rgb = Color3.new, Color3.fromRGB

local Console = Storage:WaitForChild("Console")
Console.Parent = Player:WaitForChild("PlayerGui")

local Storage = Console:WaitForChild("Storage")
local List = Console:WaitForChild("ScrollingFrame")
local Input = Console:WaitForChild("Input")

local function ClearOutput()
	local c = List:GetChildren()
	remove(c, find(c, List.UIListLayout))

	for i = 1, #c do
		c[i]:Destroy()
	end
end

local function CreateLog(str, color)
	local Output_obj = Storage.Output:Clone()
	Output_obj.Text = str or 'I guess i forgot to write something...? (Error: c0mm0nhuman)'
	Output_obj.TextColor3 = color or C3(1,1,1)
	Output_obj.Visible = true
	Output_obj.Parent = List
end

local function build_tuple_str(...)
	local args = {...}
	local build, N = args[1] and args[1] or '', #args
	if N>1 then
		for i = 2,N do
			build = build..' '..tostring(args[i])
		end
	end
	return build
end
local print = function(...)
	local build = build_tuple_str(...)
	CreateLog(build, rgb(163,162,165))
end
local warn = function(...)
	local build = build_tuple_str(...)
	CreateLog(build, rgb(253,128,8))
end
local error = function(...)
	local build = build_tuple_str(...)
	CreateLog(build, C3(1,0,0))
end

local function Decision(args)
	local arg = args[2] and args[2]:lower()
	return arg == '1' or arg == 'true' or arg == 'yes' or arg == 'y' and true or
	arg == '0' or arg == 'false' or arg == 'no' or arg == 'n' and false or
	nil
end

local function Visual_Collisions(args)
	local bool = Decision(args)
	if bool ~= nil then
		
	end
end

local Commands = {
	["clear"] = ClearOutput,
	["visual_collisions"] = Visual_Collisions,

	--outputs
	['print'] = function(args)
		remove(args,1)
		print(unpack(args))
	end,
	['warn'] = function(args)
		remove(args,1)
		warn(unpack(args))
	end,
	['error'] = function(args)
		remove(args,1)
		error(unpack(args))
	end,
	--testings
	["!"] = function() CreateLog() end
}
local function Process_Command(str)
	local args = str:split(' ')
	local low1 = args[1] and args[1]:lower()
	low1 = low1:gsub(' ',''):gsub('\t','')

	if low1 ~= '' then
		CreateLog('>'..args[1])
		local Command = Commands[low1]

		if Command then
			Command(args)

		--Special's
		elseif low1 == 'help' or low1 == '?' then
			for c in next, Commands do
				CreateLog(c)
			end

			--Indicate the help commands
			CreateLog('help / ?')
		else
			CreateLog('Unknown Command: "'..args[1]..'".', C3(1,0,0))
		end
	end
	Input.Text = ''
	wait()
	Input:CaptureFocus()
end

local function Toggle(is_focused)
	List.Visible = not List.Visible
	Input.Visible = not Input.Visible

	if not is_focused then
		if Input.Visible then
			wait()
			Input:CaptureFocus()
		end
	else
		Input:ReleaseFocus()
		Input.Text = ''
	end
end

local Function_List = {
	print = print,
	warn = warn,
	error = error,
	toggle_visible = Toggle
}

local function Func_run(func, ...)
	func = func:lower()
	local f = Function_List[func]
	if f then
		f(...)
	else
		warn("Unknown BindableEvent function: ", func)
	end
end
Input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		Process_Command(Input.Text)
	end
end)

local Command = Instance.new("BindableEvent")
Command.Name = "ConsoleRun"
Command.Parent = script.Parent
Command.Event:Connect(Func_run)

LogService.MessageOut:Connect(function(message, type)
	if type == Enum.MessageType.MessageOutput then

	elseif type == Enum.MessageType.MessageWarning then

	elseif type == Enum.MessageType.MessageError then

	end
end)