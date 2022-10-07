local S = setmetatable({}, {
	__index = function(self,i)
		if not rawget(self,i) then
			self[i] = game:GetService(i)
		end
		return rawget(self,i)
	end
})

local Players = S.Players
local Storage = S.ReplicatedStorage

local Player = Players.LocalPlayer

local find, remove = table.find, table.remove
local C3 = Color3.new

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

local function Decision(inp)
	if inp == '1' or inp == 'true' or inp == 'yes' then
		return true
	end
	if inp == '0' or inp == 'false' or inp == 'no' then
		return false
	end
	return
end

local function Visual_Collisions(args)
	local arg = args[2] and args[2]:lower()
	local realBool = Decision(arg)
	if realBool ~= nil then
		
	end
end

local Commands = {
	["clear"] = ClearOutput,
	["visual_collisions"] = Visual_Collisions,

	--testings
	["!"] = function() CreateLog() end
}
local function Process_Command(str)
	local args = str:split(' ')
	local low1 = args[1] and args[1]:lower()

	if low1 ~= '' then
		CreateLog('>'..args[1])
		if Commands[low1] then
			Commands[low1](args)
		elseif low1 == 'help' or low1 == '?' then
			for c in next, Commands do
				CreateLog(c)
			end
		else
			CreateLog('Unknown Command: "'..args[1]..'".', C3(1,0,0))
		end
	end
	Input.Text = ''
end

local function Visible()
	List.Visible = not List.Visible
	Input.Visible = not Input.Visible

	if Input.Visible then
		task.wait()
		Input:CaptureFocus()
	end
end
Input.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		Process_Command(Input.Text)
	end
end)

local VisibleBind = Instance.new("BindableEvent")
VisibleBind.Name = "ConsoleVisibility"
VisibleBind.Parent = script.Parent
VisibleBind.Event:Connect(Visible)