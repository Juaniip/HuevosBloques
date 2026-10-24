-- Galería: todos los huevos en anillos, cada uno en su pedestal mirando al centro, con su etiqueta arriba.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local EggBuilder = require(ReplicatedStorage.Shared.EggBuilder)
local Elements = require(ReplicatedStorage.Shared.Elements)

local Parts = Kit.Parts
local Ui = Kit.Ui

local EGG_SCALE = 0.45 -- tamaño de los huevos en la galería (1 = 12 studs de ancho)
local SPACING = 12 -- studs entre huevo y huevo, a lo largo del anillo
local FIRST_RING = 26 -- radio del primer anillo
local RING_GAP = 20 -- distancia entre anillos
local PEDESTAL = 1
local PEDESTAL_SIZE = 8
local LABEL_GAP = 2.5 -- studs entre la punta del huevo y la etiqueta
local LABEL_RANGE = 70 -- más lejos que esto, la etiqueta no se ve

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
		Size = UDim2.fromOffset(220, 62),
		MaxDistance = LABEL_RANGE,
		LightInfluence = 0,
		Adornee = anchor,
	})

	local plate = Ui.new("Frame", {
		Name = "Plate",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = gui,
	})
	Ui.round(plate, 10)
	Ui.new("UIStroke", { Color = element.dark, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = plate })
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
	Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = plate })
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
			Size = UDim2.new(0, if letter == " " then 7 else 0, 1, 0),
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
			TextSize = 21,
			TextColor3 = Color3.new(1, 1, 1),
			Text = letter,
			Parent = holder,
		})
		Ui.new("UIStroke", { Color = element.dark, Thickness = 1.5, Parent = holder:FindFirstChild("Char") })
	end

	-- Una plaquita por elemento, una al lado de la otra.
	local tags = Ui.new("Frame", {
		Name = "Elements",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = tags,
	})
	for order, each in elements do
		local tag = Ui.new("Frame", {
			Name = "Element",
			LayoutOrder = order,
			Size = UDim2.fromOffset(0, 20),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = each.dark,
			Parent = tags,
		})
		Ui.round(tag, 6)
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, if each.icon then 4 else 7), PaddingRight = UDim.new(0, 7), Parent = tag })
		Ui.new("UIStroke", { Color = each.color, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tag })
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tag,
		})
		if each.icon then
			Ui.new("ImageLabel", {
				Name = "Icon",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(9, 18), -- los íconos son banderitas angostas
				BackgroundTransparency = 1,
				Image = each.icon,
				ScaleType = Enum.ScaleType.Fit,
				Parent = tag,
			})
		end
		Ui.new("TextLabel", {
			Name = "Name",
			LayoutOrder = 2,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			Font = Enum.Font.FredokaOne,
			TextSize = 12,
			TextColor3 = each.light,
			Text = string.upper(each.name),
			Parent = tag,
		})
	end

	gui.Parent = anchor
end

-- Reparte los huevos en anillos alrededor del centro: cada anillo lleva los que le entran.
local spots = {}
do
	local ring, left = 0, #Eggs.list
	while left > 0 do
		local radius = FIRST_RING + ring * RING_GAP
		local count = math.min(left, math.floor(2 * math.pi * radius / SPACING))
		local offset = ring * 0.5 -- cada anillo corrido, así no quedan uno detrás del otro
		for i = 0, count - 1 do
			local angle = (i + offset) / count * math.pi * 2
			table.insert(spots, Vector3.new(math.sin(angle) * radius, 0, math.cos(angle) * radius))
		end
		left -= count
		ring += 1
	end
end

local started = os.clock()
local total = 0
for index, def in Eggs.list do
	local position = spots[index]
	local facing = CFrame.lookAt(position, Vector3.zero) -- el frente del huevo (-Z) mira al centro

	local pedestal = Parts.cylinder("Pedestal", PEDESTAL, PEDESTAL_SIZE, facing * CFrame.new(0, PEDESTAL / 2, 0), Color3.fromRGB(250, 250, 252), gallery)
	Parts.cylinder("PedestalRim", 0.3, PEDESTAL_SIZE + 0.6, facing * CFrame.new(0, 0.15, 0), Color3.fromRGB(200, 205, 215), gallery)

	local egg = EggBuilder.build(def, nil, facing * CFrame.new(0, PEDESTAL, 0))
	egg:ScaleTo(EGG_SCALE) -- achica todo (ladrillos, adornos y efectos) desde la base
	egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- que llegue entero al cliente (lo hace girar)
	label(pedestal, egg, def)
	egg.Parent = gallery
	total += #egg:GetDescendants()
end

print(`[HuevosBloques] {#Eggs.list} huevos armados ({total} piezas) en {string.format("%.2f", os.clock() - started)} s ✅`)
