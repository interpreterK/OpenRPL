--[[
	A custom physics engine for ROBLOX.
	
	Author: interpreterK
	https://github.com/interpreterK/OpenRPL
]]

-- Modify these to your liking
local Flying  = true
local Gravity = 150

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local S = setmetatable({}, {
	__index = function(self,i)
		if not rawget(self,i) then
			self[i] = game:GetService(i)
		end
		return rawget(self,i)
	end
})
local function New(Inst, Parent, Props)
	local i = Instance.new(Inst)
	for prop, value in next, Props or {} do
		pcall(function()
			i[prop] = value
		end)
	end
	i.Parent = Parent
	return i
end

local Players    = S.Players
local RunService = S.RunService
local UIS        = S.UserInputService

local V3     = Vector3.new
local lookAt = CFrame.lookAt
local World_Origin = Vector3.yAxis*100 --Reset point if no spawnlocation(s)

-- Camera
local Camera = workspace.CurrentCamera
--If the camera does not exist yield for it, this is required
if not Camera then
	repeat
		task.wait()
	until workspace.CurrentCamera
	Camera = workspace.CurrentCamera
end

local function SetView(Object)
	Camera.CameraSubject = Object
	Camera.CameraType = Enum.CameraType.Custom
end
--

-- The player
-- Maybe limbs sometime?
local Root = New('Part', workspace, {
    Position = World_Origin,
	Size = V3(2,2,1),
	Color = Color3.new(1,1,1),
    Anchored = true,
    CanCollide = false
})
SetView(Root)
--

-- Player I/O
local Holding = {}
local KeyDown = {}
local Pointer3D = Vector3.zero

-- Key binds
function KeyDown.g()
	Flying = not Flying
	print("Flying=",Flying)
end
--

UIS.InputBegan:Connect(function(input, gp)
	if not gp then
		local KC = input.KeyCode.Name:lower()
		Holding[KC] = true

		local Bind = KeyDown[KC]
		if Bind then
			Bind()
		end
	end
end)
UIS.InputEnded:Connect(function(input, gp)
	if not gp then
		Holding[input.KeyCode.Name:lower()] = false
	end
end)
UIS.InputChanged:Connect(function(input, _)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		Pointer3D = input.Position
	end
end)

-- Player movement
local Movement  = {
	x = Vector3.xAxis/10,
	y = Vector3.yAxis,
	z = Vector3.zAxis/10
}

local function Pointer_Direction()
	local Root_CF = Root.CFrame
	local ScreenRay = Camera:ScreenPointToRay(Pointer3D.x, Pointer3D.y, 0)
	return (ScreenRay.Origin+Root_CF.LookVector+ScreenRay.Direction*(Camera.CFrame.p-Root_CF.p).Magnitude*2)
end

local function Controls(Forward_Direction, Right_Direction) --Required to run in a loop
	if Holding.w then
		Root.Position+=Forward_Direction+Movement.z
	end
	if Holding.s then
		Root.Position-=Forward_Direction+Movement.z
	end
	if Holding.d then
		Root.Position+=Right_Direction+Movement.x
	end
	if Holding.a then
		Root.Position-=Right_Direction+Movement.x
	end
	if Holding.e then
		Root.Position+=Movement.y
	end
	if Holding.q then
		Root.Position-=Movement.y
	end
end
--

-- Step loops & Physics


--https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/0/b/6/0b6fde38a15dd528063a92ac8916ce3cd84fc1ce.png
RunService.Stepped:Connect(function()
	Controls(Camera.CFrame.LookVector, Camera.CFrame.RightVector)

	Root.CFrame=lookAt(Root.Position,Pointer_Direction())
end)

RunService.Heartbeat:Connect(function()

end)
--
