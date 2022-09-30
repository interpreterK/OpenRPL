--[[
	A custom physics engine for ROBLOX.
	
	Author: interpreterK
	https://github.com/interpreterK/OpenRPL
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

local V3 = Vector3.new
local CN, lookAt = CFrame.new, CFrame.lookAt
local insert = table.insert
local abs, min, max = math.abs, math.min, math.max
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

-- CoreGuis
if Disable_CoreGui then
	S.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
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

-- Freecam
local Freecam = New('Part', Camera, {
	Position = Root.Position,
	Anchored = true,
	Transparency = 1,
	Size = Vector3.zero
})
--

-- Player I/O
local Holding = {}
local KeyDown = {}
local Pointer3D = Vector3.zero
local Using_Freecam = false

-- Key binds
function KeyDown.g()
	Flying = not Flying
	print("Flying=",Flying)
end

function KeyDown.f()
	Using_Freecam = not Using_Freecam
	if Using_Freecam then
		SetView(Freecam)
	else
		SetView(Root)
	end
	print("Freecam=",Using_Freecam)
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

local function Controls(Part, Forward_Direction, Right_Direction) --Required to run in a loop
	if Holding.w then
		Part.Position+=Forward_Direction+Movement.z
	end
	if Holding.s then
		Part.Position-=Forward_Direction+Movement.z
	end
	if Holding.d then
		Part.Position+=Right_Direction+Movement.x
	end
	if Holding.a then
		Part.Position-=Right_Direction+Movement.x
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
local Valid = { --Not all basepart's are supported yet
	Parts = {'Part','TrussPart'},
	Shapes = {'Block'}
}

local function GetWorkspace()
	local Descendants = workspace:GetDescendants()
	local Parts = {}
	for A_n = 1, #Descendants do
		for P_n = 1, #Valid.Parts do
			local Part = Descendants[A_n]

			for S_n = 1, #Valid.Shapes do
				local Shape = Valid.Shapes[S_n]
				if Part.ClassName == Valid.Parts[P_n] and Part.Shape == Enum.PartType[Shape] then
					insert(Parts, Part)
				end
			end
		end
	end
	return Parts
end

local function Get_Sides(Object)
	local x,y,z = Object.Size.x,Object.Size.y,Object.Size.z
	return {
		X_POS = x/2,  --Left
		X_NEG = x/-2, --Right
		Y_POS = y/2,  --Top
		Y_NEG = y/-2, --Bottom
		Z_POS = z/2,  --Front
		Z_NEG = z/-2  --Back
	}
end

local function clamp2(n1, n2, n3)
	local n = 0
	pcall(function()
		n = math.clamp(n1, n2, n3)
	end)
	return n
end

local function Collision_Solver(Object, Sides)
	local Object_P = Object.Position
	local Root_P   = Root.Position
	local Left     = Object_P+V3(Sides.X_POS,0,0)
	local Right    = Object_P+V3(Sides.X_NEG,0,0)
	local Top      = Object_P+V3(0,Sides.Y_POS,0)
	local Bottom   = Object_P+V3(0,Sides.Y_NEG,0)
	local Front    = Object_P+V3(0,0,Sides.Z_POS)
	local Back     = Object_P+V3(0,0,Sides.Z_NEG)

	--s:Size ~CORD
	local function CoordinateFuse(Point, Inverse)
		local abs_size_X = Inverse and abs(Sides.X_NEG) or abs(Sides.X_POS)
		local abs_size_Y = Inverse and abs(Sides.Y_NEG) or abs(Sides.Y_POS)
		local abs_size_Z = Inverse and abs(Sides.Z_NEG) or abs(Sides.Z_POS)
		local max_sX = clamp2(-abs_size_X, -Point.x, abs_size_X)
		local max_sY = clamp2(-abs_size_Y, -Point.y, abs_size_Y)
		local max_sZ = clamp2(-abs_size_Z, -Point.z, abs_size_Z)
		return {x = max_sX, y = max_sY, z = max_sZ}
	end

	local Top_HitPhysics    = CoordinateFuse(-Root_P+Top, false)
	local Bottom_HitPhysics = CoordinateFuse(-Root_P+Bottom, true)
	local Left_HitPhysics   = CoordinateFuse(-Root_P+Left, true)
	local Right_HitPhysics  = CoordinateFuse(-Root_P+Right, false)
	local Front_HitPhysics  = CoordinateFuse(-Root_P+Front, false)
	local Back_HitPhysics   = CoordinateFuse(-Root_P+Back, true)

	return {
		Top    = V3(Object_P.x+Top_HitPhysics.x, Top.y, Object_P.z+Top_HitPhysics.z),
		Bottom = V3(Object_P.x+Bottom_HitPhysics.x, Bottom.y, Object_P.z+Bottom_HitPhysics.z),
		Front  = V3(Object_P.x+Front_HitPhysics.x, Object_P.y+Front_HitPhysics.y, Front.z),
		Back   = V3(Object_P.x+Back_HitPhysics.x, Object_P.y+Front_HitPhysics.y, Front.z),
		Left   = V3(Left.x, Object_P.y+Left_HitPhysics.y, Object_P.z+Left_HitPhysics.z),
		Right  = V3(Right.x, Object_P.y+Right_HitPhysics.y, Object_P.z+Right_HitPhysics.z)
	}
end

local Test = New('Part', workspace, {
	Color = Color3.new(1,0,0),
	Anchored = true
})
local function Detect_Collision(Object)
	local Collision = Collision_Solver(Object, Get_Sides(Object))
	if Object.Name == "Baseplate" then
		Test.Position = Collision.Top
	end
end

--https://devforum-uploads.s3.dualstack.us-east-2.amazonaws.com/uploads/original/4X/0/b/6/0b6fde38a15dd528063a92ac8916ce3cd84fc1ce.png
RunService.Stepped:Connect(function()
	if Using_Freecam then
		Controls(Freecam, Camera.CFrame.LookVector, Camera.CFrame.RightVector)
	else
		Controls(Root, Camera.CFrame.LookVector, Camera.CFrame.RightVector)
		Root.CFrame=lookAt(Root.Position, Pointer_Direction())
		Freecam.Position=Root.Position
	end
end)

RunService.Heartbeat:Connect(function(deltaTime)
	local Objects = GetWorkspace()

	for i = 1, #Objects do
		local Object = Objects[i]
		if Object.CanCollide then
			Detect_Collision(Object)
		end
	end
end)
--
