-- Galería: una fila por huevo con sus tres fases de dragón al lado (huevo, bebé, joven, adulto),
-- cada uno en su pedestal con su etiqueta arriba.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local Eggs = require(ReplicatedStorage.Shared.Eggs)
local EggBuilder = require(ReplicatedStorage.Shared.EggBuilder)
local DragonBuilder = require(ReplicatedStorage.Shared.DragonBuilder)
local Dragons = require(ReplicatedStorage.Shared.Dragons)
local Elements = require(ReplicatedStorage.Shared.Elements)

local Parts = Kit.Parts
local Ui = Kit.Ui

local EGG_SCALE = 0.45 -- tamaño de los huevos en la galería (1 = 12 studs de ancho)
local SLOT = 14 -- studs entre el huevo y cada fase, en la fila
local COLUMNS = 4 -- filas una al lado de la otra
local COLUMN_GAP = 18 -- espacio entre una fila y la de al lado
local ROW_GAP = 22 -- espacio hacia atrás entre filas
local FIRST_ROW = 24 -- distancia desde donde aparecés hasta la primera fila
local PEDESTAL = 1
local PEDESTAL_SIZE = 8
local DRAGON_PEDESTAL = 11
local LABEL_GAP = 2.5 -- studs entre la punta del huevo y la etiqueta
local LABEL_RANGE = 70 -- más lejos que esto, la etiqueta no se ve

-- Luz con colores vivos: menos luz ambiente (el piso blanco lavaba todo) y un poco más de
-- saturación y contraste.
Lighting.ClockTime = 14
Lighting.Brightness = 2.2
Lighting.OutdoorAmbient = Color3.fromRGB(130, 130, 140)
Lighting.Ambient = Color3.fromRGB(90, 90, 100)
Lighting.ExposureCompensation = -0.15
local colors = Lighting:FindFirstChild("VividColors") or Instance.new("ColorCorrectionEffect")
colors.Name = "VividColors"
colors.Saturation = 0.3
colors.Contrast = 0.12
colors.Parent = Lighting

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
		Size = UDim2.fromOffset(220, 104),
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

	-- Arriba de todo, la bandera de cada elemento; abajo de las banderas, una plaquita con el nombre.
	local banners = Ui.new("Frame", {
		Name = "Banners",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromOffset(0, 40),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = banners,
	})
	for order, each in elements do
		if each.icon then
			Ui.new("ImageLabel", {
				Name = "Banner",
				LayoutOrder = order,
				Size = UDim2.fromOffset(32, 40), -- las banderas son un poco más altas que anchas
				BackgroundTransparency = 1,
				Image = each.icon,
				ScaleType = Enum.ScaleType.Fit,
				Parent = banners,
			})
		end
	end

	local tags = Ui.new("Frame", {
		Name = "Elements",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 44),
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
		Ui.new("UIPadding", { PaddingLeft = UDim.new(0, 7), PaddingRight = UDim.new(0, 7), Parent = tag })
		Ui.new("UIStroke", { Color = each.color, Thickness = 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = tag })
		Ui.new("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = tag,
		})
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

-- Cartelito gris con "?" para las fases que todavía no están hechas.
local function missing(pedestal: BasePart, height: number)
	local anchor = Instance.new("Attachment")
	anchor.Name = "LabelAnchor"
	anchor.Parent = pedestal
	anchor.WorldCFrame = CFrame.new(pedestal.Position + Vector3.new(0, height, 0))
	local gui = Ui.new("BillboardGui", {
		Name = "Missing",
		Size = UDim2.fromOffset(48, 48),
		MaxDistance = LABEL_RANGE,
		LightInfluence = 0,
		Adornee = anchor,
	})
	local text = Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(60, 65, 80),
		BackgroundTransparency = 0.3,
		Font = Enum.Font.FredokaOne,
		TextSize = 32,
		TextColor3 = Color3.fromRGB(220, 225, 235),
		Text = "?",
		Parent = gui,
	})
	Ui.round(text, 24)
	gui.Parent = anchor
end

local function pedestalAt(cframe: CFrame, size: number): BasePart
	local pedestal = Parts.cylinder("Pedestal", PEDESTAL, size, cframe * CFrame.new(0, PEDESTAL / 2, 0), Color3.fromRGB(250, 250, 252), gallery)
	Parts.cylinder("PedestalRim", 0.3, size + 0.6, cframe * CFrame.new(0, 0.15, 0), Color3.fromRGB(200, 205, 215), gallery)
	return pedestal
end

-- Filas: cada huevo con sus tres fases al lado (HUEVO, BEBÉ, JOVEN, ADULTO), de izquierda a derecha
-- mirando desde donde aparecés. Primero van los huevos que ya tienen dragones.
local order = {}
for index, def in Eggs.list do
	table.insert(order, { def = def, index = index, species = Dragons.byEgg[def.id] })
end
table.sort(order, function(a, b)
	if (a.species ~= nil) ~= (b.species ~= nil) then
		return a.species ~= nil
	end
	return a.index < b.index
end)

local started = os.clock()
local total = 0
local columnWidth = SLOT * 4 + COLUMN_GAP
for i, entry in order do
	local column = (i - 1) % COLUMNS
	local row = (i - 1) // COLUMNS
	local columnX = (column - (COLUMNS - 1) / 2) * columnWidth
	local z = FIRST_ROW + row * ROW_GAP
	-- Mirando hacia +Z, la izquierda es +X: el huevo va a la izquierda y las fases a su derecha.
	local function slot(k: number): CFrame
		return CFrame.new(columnX + (1.5 - k) * SLOT, 0, z)
	end

	local def = entry.def
	local pedestal = pedestalAt(slot(0), PEDESTAL_SIZE)
	local egg = EggBuilder.build(def, nil, slot(0) * CFrame.new(0, PEDESTAL, 0))
	egg:ScaleTo(EGG_SCALE) -- achica todo (ladrillos, adornos y efectos) desde la base
	egg.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- que llegue entero al cliente (lo hace girar)
	label(pedestal, egg, def)
	egg.Parent = gallery
	total += #egg:GetDescendants()

	for k, stageId in Dragons.stages do
		local base = slot(k)
		local stand = pedestalAt(base, DRAGON_PEDESTAL)
		local species = entry.species
		if species then
			local stage = species.stages[stageId]
			-- De costado y un poco de frente (tres cuartos), con la cabeza hacia el huevo.
			local dragon = DragonBuilder.build(species, stageId, nil, base * CFrame.new(0, PEDESTAL, 0) * CFrame.Angles(0, math.rad(-35), 0))
			dragon:ScaleTo(stage.scale)
			dragon.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
			label(stand, dragon, { name = `{species.name} {stage.name}`, element = def.element })
			dragon.Parent = gallery
			total += #dragon:GetDescendants()
		else
			missing(stand, 4)
		end
	end
end

-- Dónde aparecés: delante de la primera fila, mirando hacia las filas.
local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
if spawn then
	spawn.CFrame = CFrame.new(0, spawn.Size.Y / 2, 0)
end

print(`[HuevosBloques] {#Eggs.list} huevos y {#Dragons.list} especies de dragón armados ({total} piezas) en {string.format("%.2f", os.clock() - started)} s ✅`)
