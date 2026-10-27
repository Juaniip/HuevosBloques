-- Monedas del juego: gemas, oro, comida y estrellas (las de la barra de arriba, en ese orden) y XP.
--   Currencies.byId.gold -> { id, name, color, icon, bar?, pad = { min, max, cooldown } }
--   bar = false: se guarda y se recolecta, pero no aparece en la barra de arriba
--   Currencies.format(1680000) -> "1.68 M"
--
-- Íconos: las imágenes diseñadas están en assets/monedas (`file`). Roblox solo muestra imágenes
-- subidas a Roblox: subilas una vez (Asset Manager → Bulk Import) y pegá el número en `icon`.
local Currencies = {}

Currencies.list = {
	{
		id = "gems",
		name = "Gemas",
		color = Color3.fromRGB(170, 90, 230),
		file = "gema.png",
		icon = "99047274716935",
		pad = { min = 1, max = 5, cooldown = 4 },
	},
	{
		id = "gold",
		name = "Oro",
		color = Color3.fromRGB(245, 195, 50),
		file = "oro.png",
		icon = "113975933017963",
		pad = { min = 50, max = 500, cooldown = 3 },
	},
	{
		id = "food",
		name = "Comida",
		color = Color3.fromRGB(235, 70, 50),
		file = "comida.png",
		icon = "117586813676807",
		pad = { min = 20, max = 200, cooldown = 3 },
	},
	{
		id = "xp",
		name = "XP",
		color = Color3.fromRGB(60, 170, 240),
		file = "xp.png",
		icon = "108618053635708",
		bar = false,
		pad = { min = 10, max = 100, cooldown = 3 },
	},
	{
		id = "stars",
		name = "Estrellas",
		color = Color3.fromRGB(255, 215, 60),
		file = "estrella.png",
		icon = "120624236031985",
		pad = { min = 1, max = 3, cooldown = 5 },
	},
}

Currencies.byId = {}
for _, currency in Currencies.list do
	if currency.icon ~= "" and not string.find(currency.icon, "://") then
		currency.icon = "rbxassetid://" .. currency.icon
	end
	Currencies.byId[currency.id] = currency
end

local SUFFIXES = { "K", "M", "B", "T" }

-- Como en la barra de arriba: hasta 9999 el número entero; después 3 cifras y la unidad ("1.68 M").
function Currencies.format(n: number): string
	n = math.floor(n)
	if n < 10000 then
		return tostring(n)
	end
	local value, i = n / 1000, 1
	while value >= 1000 and i < #SUFFIXES do
		value /= 1000
		i += 1
	end
	local text = if value >= 100
		then tostring(math.floor(value))
		elseif value >= 10 then string.format("%.1f", math.floor(value * 10) / 10)
		else string.format("%.2f", math.floor(value * 100) / 100)
	return `{text} {SUFFIXES[i]}`
end

return Currencies
