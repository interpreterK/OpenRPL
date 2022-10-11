--[[
	- OpenXen console -
	Console to interact with the physics engine

	Author: interpreterK
]]

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
local StarterGui = S.StarterGui

local Player = Players.LocalPlayer

local find, remove = table.find, table.remove
local wait = task.wait
local C3, rgb = Color3.new, Color3.fromRGB

--Console UI dependencies
local Console = Storage:WaitForChild("Console")
Console.Parent = Player:WaitForChild("PlayerGui")

local Storage = Console:WaitForChild("Storage")
local List = Console:WaitForChild("ScrollingFrame")
local Input = Console:WaitForChild("Input")
--

--Base functions for the commands
local function ClearOutput()
	local c = List:GetChildren()
	remove(c, find(c, List.UIListLayout))

	for i = 1, #c do
		c[i]:Destroy()
	end
end

local function CreateLog(str, color)
	local Output_obj = Storage.Output:Clone()
	Output_obj.Text = str or 'Placeholder text'
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
local info = function(...)
	local build = build_tuple_str(...)
	CreateLog(build, rgb(0,170,255))
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

local function Toggle_Console2()
	StarterGui:SetCore('DevConsoleVisible', true)
end
--

--The commands
local Commands = {
	["clear"] = ClearOutput,
	["visual_collisions"] = Visual_Collisions,
	["console2"] = Toggle_Console2,

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
	['info'] = function(args)
		remove(args,1)
		info(unpack(args))
	end,
	--testings
	["!"] = function() CreateLog() end
}
local function Process_Command(str)
	local args = str:split(' ')
	local low1 = args[1] and args[1]:lower():gsub(' ',''):gsub('\t','')

	if low1 ~= '' then
		CreateLog('>'..args[1])
		local Command = Commands[low1]

		if Command then
			Command(args)

		--Special's
		elseif low1 == 'help' or low1 == '?' then
			for c in next, Commands do
				print(c)
			end

			--Indicate the help commands
			print('help / ?')
		else
			error('Unknown Command: "'..args[1]..'".')
		end
	end
	Input.Text = ''
	wait()
	Input:CaptureFocus()
end
Input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		Process_Command(Input.Text)
	end
end)
--Indicate or hint a matching command
Input:GetPropertyChangedSignal("Text"):Connect(function()
	local text = Input.Text:lower()
	local main_focus = text:split(' ')[1]:gsub(' ',''):gsub('\t','')

	--Support the help commands
	if main_focus == 'help' or main_focus == '?' then
		Input.TextColor3 = C3(1,1,0)
	else
		for c in next, Commands do
			if main_focus == c then
				Input.TextColor3 = C3(1,1,0)
				break
			else
				Input.TextColor3 = C3(1,1,1)
			end
		end
	end
end)
--

--Bind & bind actions
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
	toggle_visible = Toggle,

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

local Command = Instance.new("BindableEvent")
Command.Name = "ConsoleRun"
Command.Parent = script.Parent
Command.Event:Connect(Func_run)
--

local Command_Get = Instance.new("BindableFunction")
Command_Get.Name = "CommandGet"
Command_Get.Parent = script.Parent

--Roblox output to the OpenXen output
LogService.MessageOut:Connect(function(message, type)
	if type == Enum.MessageType.MessageOutput then
		print(message)
	elseif type == Enum.MessageType.MessageWarning then
		warn(message)
	elseif type == Enum.MessageType.MessageError then
		error(message)
	elseif type == Enum.MessageType.MessageInfo then
		info(message)
	end
end)
--