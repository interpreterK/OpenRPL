--[[
	- OpenXen core engine -
	A custom physics engine for ROBLOX.
	
	Author: interpreterK
	https://github.com/interpreterK/OpenRPL

	Plans to do later:
	-Make this all Object Oriented.
	-Explode on fall damage death. (vel>1000)?
]]

-- Modify these to your liking
local Disable_CoreGui = true
local Flying          = true
local Gravity         = 150

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
local Storage    = S.ReplicatedStorage
local StarterGui = S.StarterGui

local V3 = Vector3.new
local CN, lookAt = CFrame.new, CFrame.lookAt
local abs, min, max = math.abs, math.min, math.max
local resume, create = coroutine.resume, coroutine.create
local wait = task.wait
local C3 = Color3.new
local World_Origin = Vector3.yAxis*100 --Reset point if no spawnlocation(s)

--Bind to the console
local ConsoleRun = script.Parent:WaitForChild("ConsoleRun")
local CommandGet = script.Parent:WaitForChild("CommandGet")
local print = function(...)
	ConsoleRun:Fire('print',...)
end
local warn = function(...)
	ConsoleRun:Fire('warn',...)
end
local error = function(...)
	ConsoleRun:Fire('error',...)
end
--

-- Camera
local Camera = workspace.CurrentCamera
--If the camera does not exist yield for it, this is required
if not Camera then
	repeat
		wait()
	until workspace.CurrentCamera
	Camera = workspace.CurrentCamera
end

local function SetView(Object)
	Camera.CameraSubject = Object
	Camera.CameraType = Enum.CameraType.Custom
end
--

-- CoreGuis
if Disable_CoreGui then
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
end
--

-- The player
local Root = New('Part', workspace, {
    Position = World_Origin,
	Size = V3(2,2,1),
    Anchored = true,
    CanCollide = false
})
local Torso = New('Part', Root, {
    Position = World_Origin,
	Size = V3(2,2,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .5,
    Name = 'Torso'
})
local Head = New('Part', Root, {
    Position = World_Origin,
	Size = V3(2,1,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .1,
    Name = 'Head'
}) 
local LeftArm = New('Part', Root, {
	Position = World_Origin,
	Size = V3(1,2,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .1,
    Name = 'LeftArm'
})
local RightArm = New('Part', Root, {
	Position = World_Origin,
	Size = V3(1,2,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .1,
    Name = 'RightArm'
})
local LeftLeg = New('Part', Root, {
	Position = World_Origin,
	Size = V3(1,2,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .1,
    LeftLeg = 'LeftLeg'
})
local RightLeg = New('Part', Root, {
	Position = World_Origin,
	Size = V3(1,2,1),
    Anchored = true,
    CanCollide = false,
    Transparency = .1,
    Name = 'RightLeg'
})

local HitBall = New('Part', workspace, {
	Shape = Enum.PartType.Ball,
	Color = C3(0,0,1),
	Size = V3(.5,.5,.5),
	Anchored = true,
	CanCollide = false
})

SetView(Root)
New('Decal', Head, {Texture = 'rbxasset://textures/face.png'}) --silly
--

-- Freecam
local Freecam = New('Part', Camera, {
	Position = Root.Position,
	Anchored = true,
	Transparency = 1,
	Size = Vector3.zero
})
--

-- PhysicsList
local PhysicsList_Remote = Storage:WaitForChild("OpenRPL"):WaitForChild("PhysicsList")
local PhysicsList = PhysicsList_Remote:InvokeServer()
--

-- Player I/O
local Holding = {}
local KeyDown = {
	gp = {},
	nongp = {}
}
local Pointer3D = Vector3.zero
local Using_Freecam = false

-- Key binds
function KeyDown.nongp.g()
	Flying = not Flying
	print("Flying=",Flying)
end

function KeyDown.nongp.f()
	Using_Freecam = not Using_Freecam
	if Using_Freecam then
		SetView(Freecam)
	else
		SetView(Root)
	end
	print("Freecam=",Using_Freecam)
end

function KeyDown.nongp.backquote()
	ConsoleRun:Fire('toggle_visible', false)
end
function KeyDown.gp.backquote()
	ConsoleRun:Fire('toggle_visible', true)
end
function KeyDown.nongp.f9()
	StarterGui:SetCore('DevConsoleVisible', false)
	ConsoleRun:Fire('toggle_visible', false)
end
function KeyDown.gp.f9()
	StarterGui:SetCore('DevConsoleVisible', false)
	ConsoleRun:Fire('toggle_visible', true)
end
--

UIS.InputBegan:Connect(function(input, _gp)
	local gp = _gp and 'gp' or 'nongp'
	local KC = input.KeyCode.Name:lower()
	
	if not _gp then
		Holding[KC] = true
	end	
	local Bind = KeyDown[gp][KC]
	if Bind then
		Bind()
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
local WalkSpeed = 50

local Movement  = {
	x = Vector3.xAxis/10,
	y = Vector3.yAxis,
	z = Vector3.zAxis/10,
	Alpha = .5
}

local function Pointer_Direction()
	local Root_CF = Root.CFrame
	local ScreenRay = Camera:ScreenPointToRay(Pointer3D.x, Pointer3D.y, 0)
	return (ScreenRay.Origin+Root_CF.LookVector+ScreenRay.Direction*(Camera.CFrame.p-Root_CF.p).Magnitude*2)
end

local function Controls(Part, Forward_Direction, Right_Direction) --Required to run in a loop
	if Holding.w then
		Part.Position=Part.Position:Lerp(Part.Position+Forward_Direction+Movement.z, Movement.Alpha)
	end
	if Holding.s then
		Part.Position=Part.Position:Lerp(Part.Position-Forward_Direction+Movement.z, Movement.Alpha)
	end
	if Holding.d then
		Part.Position=Part.Position:Lerp(Part.Position+Right_Direction+Movement.x, Movement.Alpha)
	end
	if Holding.a then
		Part.Position=Part.Position:Lerp(Part.Position-Right_Direction+Movement.x, Movement.Alpha)
	end
	if Holding.e then
		Part.Position+=Movement.y
	end
	if Holding.q then
		Part.Position-=Movement.y
	end
end
--

-- Step loops & Physics
local function E_clamp(n1, n2, n3) --Errorless clamp
	return max(n1, min(n2, n3))
end

local function Get_Sides(Object)
	local x, y, z = Object.Size.x, Object.Size.y, Object.Size.z
	local Axis = {
		X_POS = x/2,  --Left
		X_NEG = x/-2, --Right
		Y_POS = y/2,  --Top
		Y_NEG = y/-2, --Bottom
		Z_POS = z/2,  --Front
		Z_NEG = z/-2  --Back
	}
	local Matrix = {
		X_POS = V3(Axis.X_POS,0,0),
		X_NEG = V3(Axis.X_NEG,0,0),
		Y_POS = V3(0,Axis.Y_POS,0),
		Y_NEG = V3(0,Axis.Y_NEG,0),
		Z_POS = V3(0,0,Axis.Z_POS),
		Z_NEG = V3(0,0,Axis.Z_NEG)
	}
	return {Axis=Axis,Matrix=Matrix}
end

local function Collision_Solver(Object, Sides)
	local Object_P = Object.Position
	local Root_P   = Root.Position

	local Left   = Object_P+Sides.Matrix.X_POS
	local Right  = Object_P+Sides.Matrix.X_NEG
	local Top    = Object_P+Sides.Matrix.Y_POS
	local Bottom = Object_P+Sides.Matrix.Y_NEG
	local Front  = Object_P+Sides.Matrix.Z_POS
	local Back   = Object_P+Sides.Matrix.Z_NEG

	--s:Size ~CORD
	local function rect(Point, Inverse)
		local abs_size_X = Inverse and abs(Sides.Axis.X_NEG) or abs(Sides.Axis.X_POS)
		local abs_size_Y = Inverse and abs(Sides.Axis.Y_NEG) or abs(Sides.Axis.Y_POS)
		local abs_size_Z = Inverse and abs(Sides.Axis.Z_NEG) or abs(Sides.Axis.Z_POS)
		local max_sX = E_clamp(-abs_size_X, -Point.x, abs_size_X)
		local max_sY = E_clamp(-abs_size_Y, -Point.y, abs_size_Y)
		local max_sZ = E_clamp(-abs_size_Z, -Point.z, abs_size_Z)
		return {x = max_sX, y = max_sY, z = max_sZ}
	end

	local Top_Hit    = rect(-Root_P+Top,    false)
	local Bottom_Hit = rect(-Root_P+Bottom, true)
	local Left_Hit   = rect(-Root_P+Left,   true)
	local Right_Hit  = rect(-Root_P+Right,  false)
	local Front_Hit  = rect(-Root_P+Front,  false)
	local Back_Hit   = rect(-Root_P+Back,   true)
	return {
		Top    = V3(Object_P.x+Top_Hit.x, Top.y, Object_P.z+Top_Hit.z),
		Bottom = V3(Object_P.x+Bottom_Hit.x, Bottom.y, Object_P.z+Bottom_Hit.z),
		Front  = V3(Object_P.x+Front_Hit.x, Object_P.y+Front_Hit.y, Front.z),
		Back   = V3(Object_P.x+Back_Hit.x, Object_P.y+Front_Hit.y, Front.z),
		Left   = V3(Left.x, Object_P.y+Left_Hit.y, Object_P.z+Left_Hit.z),
		Right  = V3(Right.x, Object_P.y+Right_Hit.y, Object_P.z+Right_Hit.z)
	}
end

local function Detect_Collision(Object)
	local Mover_p = Root.Position
	local Center = Object.Position
	local ObjectSize = Object.Size

	local Object_Sides     = Get_Sides(Object)
	local Root_Sides       = Get_Sides(Root)
	local Collision_Object = Collision_Solver(Object, Object_Sides)
	local Collision_Root   = Collision_Solver(Root, Root_Sides)

	local Bottom_Hit = Object_Sides.Matrix.Y_POS+Center-Collision_Root.Bottom

	
	--Collision indicators
	if CommandGet:Invoke('ShowingCollisions') then
		print"now showing"
	else
		print"not showing"
	end
end

local function Glue(P1, P2, C0)
	C0 = C0 or CN()
	P1.CFrame=P2.CFrame*C0
	return {P1=P1,P2=P2,C0=C0}
end

--https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/0/b/6/0b6fde38a15dd528063a92ac8916ce3cd84fc1ce.png
RunService.Stepped:Connect(function()
	if Using_Freecam then
		Controls(Freecam, Camera.CFrame.LookVector, Camera.CFrame.RightVector)
	else
		local dir = Pointer_Direction()

		Controls(Root, Camera.CFrame.LookVector, Camera.CFrame.RightVector)
		Root.CFrame=lookAt(Root.Position,dir)
		HitBall.Position=dir
		Freecam.Position=Root.Position
	end
end)

RunService.Heartbeat:Connect(function(dt)
	for i = 1, #PhysicsList do
		local Object = PhysicsList[i]
		if Object.CanCollide then
			Detect_Collision(Object)
		end
		if not Object.Anchored then
			--Gravity & Velocity stuff

		end
	end
	resume(create(function()
		PhysicsList = PhysicsList_Remote:InvokeServer()
	end))
end)

--Rig & Animations
RunService.RenderStepped:Connect(function()
	local t = tick()
	--local float_test = (1.5*math.cos(t*2))/2
	local RJ = Glue(Torso,    Root)
	local NK = Glue(Head,     Torso, CN(0,1.5,0))
	local RS = Glue(RightArm, Torso, CN(1.5,0,0))
	local LS = Glue(LeftArm,  Torso, CN(-1.5,0,0))
	local RH = Glue(RightLeg, Torso, CN(-.5,-2,0))
	local LH = Glue(LeftLeg,  Torso, CN(.5,-2,0))

	
end)
--