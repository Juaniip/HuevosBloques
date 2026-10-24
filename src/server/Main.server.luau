-- Galería: todos los huevos en ronda, cada uno en su pedestal mirando al centro, con su etiqueta arriba.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local EggBuilder = require(ReplicatedStorage.Shared.EggBuilder)
local Elements = require(ReplicatedStorage.Shared.Elements)

local Parts = Kit.Parts
local Ui = Kit.Ui

local SPACING = 24 -- studs entre huevo y huevo
local PEDESTAL = 2
local LABEL_GAP = 7 -- studs entre la punta del huevo y la etiqueta

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

-- Etiqueta con el nombre (una letra por TextLabel, así el cliente las hace saltar en ola) y los
-- elementos arriba, con sus colores: si son dos, el cartel va mitad y mitad.
-- La animación está en Labels.client.luau.
local function label(pedestal: BasePart, egg: Model, def)
	local elements = Elements.of(def)
	local element, second = elements[1], elements[#elements]
	local box, size = egg:GetBoundingBox()

	local anchor = Instance.new("Attachment")
	anchor.Name = "LabelAnchor"
	anchor.Parent = pedestal
	anchor.WorldCFrame = CFrame.new(box.Position.X, box.Position.Y + size.Y / 2 + LABEL_GAP, box.Position.Z)

	local gui = Ui.new("BillboardGui", {
		Name = "EggLabel",
		Size = UDim2.fromOffset(360, 110),
		MaxDistance = 160,
		LightInfluence = 0,
		Adornee = anchor,
	})

	local plate = Ui.new("Frame", {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(0, 58),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	})
	Ui.round(plate, 16)
	Ui.new("UIStroke", { Color = element.dark, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = plate })
	Ui.new("UIGradient", {
		Name = "Colors",
		Color = if second ~= element
			then ColorSequence.new({
				ColorSequenceKeypoint.new(0, element.light),
				ColorSequenceKeypoint.new(0.42, element.color),
				ColorSequenceKeypoint.new(0.58, second.color),
				ColorSequenceKeypoint.new(1, second.light),
			})
			else ColorSequence.new({
				ColorSequenceKeypoint.new(0, element.light),
				ColorSequenceKeypoint.new(0.5, element.color),
				ColorSequenceKeypoint.new(1, element.dark),
			}),
		Parent = plate,
	})
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), Parent = plate })
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = plate,
	})
	for index, char in utf8.codes(def.name) do
		local letter = utf8.char(char)
		local holder = Ui.new("Frame", {
			Name = "Letter",
			LayoutOrder = index,
			Size = UDim2.new(0, if letter == " " then 12 else 0, 1, 0),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Parent = plate,
		})
		Ui.new("TextLabel", {
			Name = "Char",
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 36,
			TextColor3 = Color3.new(1, 1, 1),
			Text = letter,
			Parent = holder,
		})
		Ui.new("UIStroke", { Color = element.dark, Thickness = 2.5, Parent = holder:FindFirstChild("Char") })
	end

	-- Una plaquita por elemento, una al lado de la otra.
	local tags = Ui.new("Frame", {
		Name = "Elements",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(0, 30),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tags,
	})
	for order, each in elements do
		local tag = Ui.new("TextLabel", {
			Name = "Element",
			LayoutOrder = order,
			Size = UDim2.fromOffset(0, 30),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = each.dark,
			Font = Enum.Font.FredokaOne,
			TextSize = 20,
			TextColor3 = each.light,
			Text = string.upper(each.name),
			Parent = tags,
		})
		Ui.round(tag, 10)
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = tag })
		Ui.new("UIStroke", { Color = each.color, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tag })
	end

	gui.Parent = anchor
end

local radius = math.max(60, #Eggs.list * SPACING / (2 * math.pi))
local started = os.clock()
local total = 0
for index, def in Eggs.list do
	local angle = (index - 1) / #Eggs.list * math.pi * 2
	local position = Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius)
	local facing = CFrame.lookAt(position, Vector3.zero) -- el frente del huevo (-Z) mira al centro

	local pedestal = Parts.cylinder("Pedestal", PEDESTAL, 16, facing * CFrame.new(0, PEDESTAL / 2, 0), Color3.fromRGB(250, 250, 252), gallery)
	Parts.cylinder("PedestalRim", 0.4, 17, facing * CFrame.new(0, 0.2, 0), Color3.fromRGB(200, 205, 215), gallery)

	local egg = EggBuilder.build(def, nil, facing * CFrame.new(0, PEDESTAL, 0))
	egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- que llegue entero al cliente (lo hace girar)
	label(pedestal, egg, def)
	egg.Parent = gallery
	total += #egg:GetDescendants()
end

print(`[HuevosBloques] {#Eggs.list} huevos armados ({total} piezas) en {string.format("%.2f", os.clock() - started)} s ✅`)
