-- Galería: los 16 huevos en ronda, cada uno en su pedestal mirando al centro, con su nombre arriba.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local EggBuilder = require(ReplicatedStorage.Shared.EggBuilder)

local Parts = Kit.Parts

local RADIUS = 60
local PEDESTAL = 2

Lighting.ClockTime = 14
Lighting.Brightness = 2.5
Lighting.OutdoorAmbient = Color3.fromRGB(170, 170, 180)

local baseplate = workspace:FindFirstChild("Baseplate")
if baseplate and baseplate:IsA("BasePart") then
	baseplate.Color = Color3.fromRGB(235, 235, 240)
	baseplate.Material = Enum.Material.SmoothPlastic
end

local gallery = Instance.new("Folder")
gallery.Name = "Gallery"
gallery.Parent = workspace

local function label(pedestal: BasePart, def)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(240, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, EggBuilder.Shape.rows * EggBuilder.Shape.brick + 5, 0)
	gui.MaxDistance = 90
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.FredokaOne
	text.TextScaled = true
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.2
	text.Text = `{def.icon} {def.name}`
	text.Parent = gui
	gui.Parent = pedestal
end

local started = os.clock()
local total = 0
for index, def in Eggs.list do
	local angle = (index - 1) / #Eggs.list * math.pi * 2
	local position = Vector3.new(math.sin(angle) * RADIUS, 0, math.cos(angle) * RADIUS)
	local facing = CFrame.lookAt(position, Vector3.zero) -- el frente del huevo (-Z) mira al centro

	local pedestal = Parts.cylinder("Pedestal", PEDESTAL, 16, facing * CFrame.new(0, PEDESTAL / 2, 0), Color3.fromRGB(250, 250, 252), gallery)
	Parts.cylinder("PedestalRim", 0.4, 17, facing * CFrame.new(0, 0.2, 0), Color3.fromRGB(200, 205, 215), gallery)

	local egg = EggBuilder.build(def, nil, facing * CFrame.new(0, PEDESTAL, 0))
	egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- que llegue entero al cliente (lo hace girar)
	label(pedestal, def)
	egg.Parent = gallery
	total += #egg:GetDescendants()
end

print(`[HuevosBloques] {#Eggs.list} huevos armados ({total} piezas) en {string.format("%.2f", os.clock() - started)} s ✅`)
