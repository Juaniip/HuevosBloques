-- Ícono de una moneda para la interfaz. Si la moneda tiene id de imagen subido usa esa imagen;
-- si no, dibuja uno simple con formas (lingotes, gema, tomates) para poder probar sin subir nada.
--   CurrencyIcon.new(currency, parent, size) -> GuiObject
local CurrencyIcon = {}

local function frame(props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	for key, value in props do
		(f :: any)[key] = value
	end
	return f
end

local function corner(parent: Instance, scale: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(scale, 0)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thickness: number)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thickness
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

local function shine(parent: Instance, top: Color3, bottom: Color3)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(top, bottom)
	g.Parent = parent
end

local DRAW = {
	gold = function(holder: Frame)
		for i, pos in { { 0.5, 0.62 }, { 0.42, 0.42 } } do
			local bar = frame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(pos[1], pos[2]),
				Size = UDim2.fromScale(0.78, 0.34),
				Rotation = -12,
				BackgroundColor3 = Color3.fromRGB(250, 200, 50),
				ZIndex = holder.ZIndex + i,
				Parent = holder,
			})
			corner(bar, 0.2)
			stroke(bar, Color3.fromRGB(120, 70, 15), 2)
			shine(bar, Color3.fromRGB(255, 240, 150), Color3.fromRGB(225, 150, 30))
		end
	end,
	gems = function(holder: Frame)
		local gem = frame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.66, 0.66),
			Rotation = 45,
			BackgroundColor3 = Color3.fromRGB(170, 90, 230),
			ZIndex = holder.ZIndex + 1,
			Parent = holder,
		})
		corner(gem, 0.18)
		stroke(gem, Color3.fromRGB(70, 25, 110), 2)
		shine(gem, Color3.fromRGB(225, 180, 255), Color3.fromRGB(120, 50, 190))
		local facet = frame({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.45, 0.45),
			BackgroundColor3 = Color3.fromRGB(215, 160, 255),
			BackgroundTransparency = 0.25,
			ZIndex = holder.ZIndex + 2,
			Parent = gem,
		})
		corner(facet, 0.15)
	end,
	food = function(holder: Frame)
		for i, spec in { { 0.36, 0.62, 0.5 }, { 0.62, 0.58, 0.62 } } do
			local fruit = frame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(spec[1], spec[2]),
				Size = UDim2.fromScale(spec[3], spec[3]),
				BackgroundColor3 = Color3.fromRGB(235, 70, 45),
				ZIndex = holder.ZIndex + i,
				Parent = holder,
			})
			corner(fruit, 0.5)
			stroke(fruit, Color3.fromRGB(110, 25, 15), 2)
			shine(fruit, Color3.fromRGB(255, 140, 100), Color3.fromRGB(200, 40, 30))
		end
		for i, rot in { -35, 30 } do
			local leaf = frame({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5 + (i - 1.5) * 0.22, 0.2),
				Size = UDim2.fromScale(0.34, 0.16),
				Rotation = rot,
				BackgroundColor3 = Color3.fromRGB(80, 185, 60),
				ZIndex = holder.ZIndex + 3,
				Parent = holder,
			})
			corner(leaf, 0.5)
			stroke(leaf, Color3.fromRGB(25, 80, 25), 1.5)
		end
	end,
}

function CurrencyIcon.new(currency, parent: Instance?, size: number): GuiObject
	if currency.icon ~= "" then
		local image = Instance.new("ImageLabel")
		image.Name = "Icon"
		image.BackgroundTransparency = 1
		image.Size = UDim2.fromOffset(size, size)
		image.Image = currency.icon
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = parent
		return image
	end
	local holder = frame({
		Name = "Icon",
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ZIndex = 3,
		Parent = parent,
	})
	local draw = DRAW[currency.id]
	if draw then
		draw(holder)
	end
	return holder
end

-- Para hacer desaparecer un ícono (el "+99" se desvanece): sirve para imagen o dibujo.
function CurrencyIcon.fade(icon: GuiObject, transparency: number)
	if icon:IsA("ImageLabel") then
		icon.ImageTransparency = transparency
		return
	end
	for _, item in icon:GetDescendants() do
		if item:IsA("Frame") then
			item.BackgroundTransparency = math.max(item.BackgroundTransparency, transparency)
		elseif item:IsA("UIStroke") then
			item.Transparency = transparency
		end
	end
end

return CurrencyIcon
