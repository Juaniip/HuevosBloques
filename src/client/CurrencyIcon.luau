-- Ícono de una moneda para la interfaz: la imagen diseñada (assets/monedas), ya subida a Roblox.
--   CurrencyIcon.new(currency, parent, size) -> ImageLabel
-- Si la moneda todavía no tiene id en Currencies.luau, el lugar queda vacío y avisa en la consola.
local CurrencyIcon = {}

local warned: { [string]: boolean } = {}

function CurrencyIcon.new(currency, parent: Instance?, size: number): ImageLabel
	if currency.icon == "" and not warned[currency.id] then
		warned[currency.id] = true
		warn(`[Monedas] Falta el id de la imagen de "{currency.name}": subí assets/monedas/{currency.file} y pegalo en Currencies.luau`)
	end
	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.BackgroundTransparency = 1
	image.Size = UDim2.fromOffset(size, size)
	image.Image = currency.icon
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = parent
	return image
end

-- Para desvanecer el ícono (el "+99" se va apagando).
function CurrencyIcon.fade(icon: ImageLabel, transparency: number)
	icon.ImageTransparency = transparency
end

return CurrencyIcon
