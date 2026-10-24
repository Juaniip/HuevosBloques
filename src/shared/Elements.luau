-- Elementos de los huevos: el nombre y los colores de su etiqueta.
--   Elements.byId.fuego -> { name = "Fuego", color, light, dark }
--   Elements.of(huevo)  -> los elementos del huevo (uno o dos)
local Elements = {}

Elements.list = {
	{ id = "fuego", name = "Fuego", color = { 235, 85, 30 }, light = { 255, 190, 70 }, dark = { 120, 25, 10 } },
	{ id = "agua", name = "Agua", color = { 30, 130, 225 }, light = { 110, 215, 255 }, dark = { 10, 50, 120 } },
	{ id = "planta", name = "Planta", color = { 60, 170, 60 }, light = { 170, 230, 90 }, dark = { 20, 80, 30 } },
	{ id = "tierra", name = "Tierra", color = { 150, 95, 50 }, light = { 215, 165, 100 }, dark = { 70, 40, 20 } },
	{ id = "hielo", name = "Hielo", color = { 120, 200, 240 }, light = { 230, 250, 255 }, dark = { 40, 110, 170 } },
	{ id = "electrico", name = "Eléctrico", color = { 245, 200, 20 }, light = { 255, 245, 150 }, dark = { 150, 100, 0 } },
	{ id = "aire", name = "Aire", color = { 150, 190, 215 }, light = { 235, 245, 250 }, dark = { 70, 100, 135 } },
	{ id = "metal", name = "Metal", color = { 130, 135, 145 }, light = { 215, 220, 228 }, dark = { 45, 48, 55 } },
	{ id = "luz", name = "Luz", color = { 240, 195, 60 }, light = { 255, 250, 220 }, dark = { 160, 110, 20 } },
	{ id = "dulce", name = "Dulce", color = { 235, 90, 165 }, light = { 255, 190, 225 }, dark = { 140, 25, 85 } },
	{ id = "cosmico", name = "Cósmico", color = { 110, 70, 210 }, light = { 190, 160, 255 }, dark = { 35, 20, 90 } },
	{ id = "magico", name = "Mágico", color = { 200, 70, 220 }, light = { 120, 230, 255 }, dark = { 80, 20, 120 } },
	{ id = "normal", name = "Normal", color = { 175, 175, 175 }, light = { 250, 250, 250 }, dark = { 60, 60, 60 } },
}

-- Lista de elementos de un huevo (acepta "fuego" o { "fuego", "hielo" }).
function Elements.of(def): { any }
	local ids = if type(def.element) == "table" then def.element else { def.element }
	local list = {}
	for _, id in ids do
		table.insert(list, Elements.byId[id] or error(`[Elements] no existe el elemento "{tostring(id)}"`))
	end
	if #list == 0 then
		table.insert(list, Elements.byId.normal)
	end
	return list
end

Elements.byId = {}
for _, element in Elements.list do
	for _, key in { "color", "light", "dark" } do
		local rgb = element[key]
		element[key] = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	end
	Elements.byId[element.id] = element
end

return Elements
