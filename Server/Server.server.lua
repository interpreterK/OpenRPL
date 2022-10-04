local Storage = game:GetService("ReplicatedStorage")

local Folder = Instance.new("Folder")
Folder.Name = 'OpenRPL'
Folder.Parent = Storage
local Remote = Instance.new("RemoteFunction")
Remote.Name = "PhysicsList"
Remote.Parent = Folder

local insert, find = table.insert, table.find

local PhysicsList = {}
local Valid = {
	Parts = {'Part','TrussPart'},
	Shapes = {'Block'}
}

local function ObjectValid(obj)
	if not find(PhysicsList, obj) then
		for P_n = 1, #Valid.Parts do
			for S_n = 1, #Valid.Shapes do
				local Shape = Valid.Shapes[S_n]
				local Class = Valid.Parts[P_n]

				if obj.ClassName == Class and obj.Shape == Enum.PartType[Shape] then
					insert(PhysicsList, obj)
				end
			end
		end
	end
end

workspace.DescendantAdded:Connect(ObjectValid)
workspace.DescendantRemoving:Connect(ObjectValid)

local Descendants = workspace:GetDescendants()
for A_n = 1, #Descendants do
	ObjectValid(Descendants[A_n])
end

Remote.OnServerInvoke = function(_)
	return PhysicsList
end