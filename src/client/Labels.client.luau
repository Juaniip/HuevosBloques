-- Anima las etiquetas de los huevos: las letras del nombre saltan en ola, el cartel flota
-- y los colores del elemento giran. Solo anima las que están cerca de la cámara.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kit = require(ReplicatedStorage.Kit)

local RANGE = 70 -- studs (igual que el MaxDistance de la etiqueta)

local gallery = workspace:WaitForChild("Gallery")
local labels: { [BillboardGui]: { chars: { TextLabel }, phase: number } } = {}

local function track(gui: Instance)
	if not gui:IsA("BillboardGui") or gui.Name ~= "EggLabel" or labels[gui] then
		return
	end
	local plate = gui:WaitForChild("Plate", 5)
	if not plate then
		return
	end
	local chars = {}
	local letters = {}
	for _, holder in plate:GetChildren() do
		if holder.Name == "Letter" then
			table.insert(letters, holder)
		end
	end
	table.sort(letters, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for _, holder in letters do
		table.insert(chars, holder:FindFirstChild("Char") :: TextLabel)
	end
	local colors = plate:FindFirstChild("Colors")
	if colors then
		Kit.Ui.spinGradient(colors :: UIGradient, 5)
	end
	labels[gui :: BillboardGui] = { chars = chars, phase = math.random() * math.pi * 2 }
end

for _, item in gallery:GetDescendants() do
	task.spawn(track, item)
end
gallery.DescendantAdded:Connect(function(item)
	task.spawn(track, item)
end)
gallery.DescendantRemoving:Connect(function(item)
	labels[item :: BillboardGui] = nil
end)

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local now = os.clock()
	for gui, data in labels do
		local anchor = gui.Adornee :: Attachment?
		if not anchor or (anchor.WorldPosition - camera.CFrame.Position).Magnitude > RANGE then
			continue
		end
		gui.StudsOffset = Vector3.new(0, math.sin(now * 1.6 + data.phase) * 0.25, 0)
		for i, char in data.chars do
			local wave = math.sin(now * 5 - i * 0.55 + data.phase)
			char.Position = UDim2.fromOffset(0, -math.max(wave, 0) * 4)
			char.Rotation = wave * 6
		end
	end
end)
