-- Elementos de los huevos: el nombre, los colores de su etiqueta y su ícono.
--   Elements.byId.llama -> { name = "Llama", color, light, dark, icon }
--   Elements.of(huevo)  -> los elementos del huevo (uno o dos)
--
-- Íconos: las banderas diseñadas están en assets/elementos (se generan con tools/recortar.py).
-- Roblox solo muestra imágenes subidas a Roblox: subilas una vez (Studio → Ventana → Administrador
-- de recursos → Importación masiva) y pegá el id de cada una en ICONS. Mientras un id esté vacío,
-- la etiqueta se muestra sin ícono.
local Elements = {}

local ICONS = {
	terra = "133162386954936",
	llama = "99930604096520",
	mar = "96324155425074",
	naturaleza = "129070924882681",
	electrico = "90196559458170",
	hielo = "124259891322409",
	metal = "95378355936525",
	oscuro = "134255321191683",
	luz = "91163036114408",
	guerra = "114272337707589",
	puro = "99564487278030",
	leyenda = "105154495901677",
	primitivo = "72696682020998",
	viento = "77271389316376",
	tiempo = "88784055510265",
	magia = "75805747016365",
	caos = "108002347483153",
	feliz = "117769954032282",
	sueno = "86378495127367",
	belleza = "104104452436707",
	alma = "107043223725938",
}

-- Colores sacados de cada ícono.
Elements.list = {
	{ id = "terra", name = "Terra", color = { 125, 75, 35 } },
	{ id = "llama", name = "Llama", color = { 210, 45, 55 } },
	{ id = "mar", name = "Mar", color = { 20, 95, 150 } },
	{ id = "naturaleza", name = "Naturaleza", color = { 55, 175, 75 } },
	{ id = "electrico", name = "Eléctrico", color = { 245, 200, 25 } },
	{ id = "hielo", name = "Hielo", color = { 55, 165, 205 } },
	{ id = "metal", name = "Metal", color = { 140, 143, 148 } },
	{ id = "oscuro", name = "Oscuro", color = { 70, 65, 80 } },
	{ id = "luz", name = "Luz", color = { 240, 210, 100 } },
	{ id = "guerra", name = "Guerra", color = { 200, 85, 25 } },
	{ id = "puro", name = "Puro", color = { 200, 75, 165 } },
	{ id = "leyenda", name = "Leyenda", color = { 100, 35, 170 } },
	{ id = "primitivo", name = "Primitivo", color = { 100, 70, 55 } },
	{ id = "viento", name = "Viento", color = { 30, 175, 150 } },
	{ id = "tiempo", name = "Tiempo", color = { 160, 150, 120 } },
	{ id = "magia", name = "Magia", color = { 35, 120, 120 } },
	{ id = "caos", name = "Caos", color = { 170, 65, 40 } },
	{ id = "feliz", name = "Feliz", color = { 215, 110, 50 } },
	{ id = "sueno", name = "Sueño", color = { 220, 175, 60 } },
	{ id = "belleza", name = "Belleza", color = { 215, 85, 165 } },
	{ id = "alma", name = "Alma", color = { 75, 150, 165 } },
}

-- Lista de elementos de un huevo (acepta "llama" o { "llama", "hielo" }).
function Elements.of(def): { any }
	local ids = if type(def.element) == "table" then def.element else { def.element }
	local list = {}
	for _, id in ids do
		table.insert(list, Elements.byId[id] or error(`[Elements] no existe el elemento "{tostring(id)}"`))
	end
	return list
end

Elements.byId = {}
for _, element in Elements.list do
	local rgb = element.color
	element.color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	element.light = element.color:Lerp(Color3.new(1, 1, 1), 0.55)
	element.dark = element.color:Lerp(Color3.new(0, 0, 0), 0.55)
	local icon = ICONS[element.id]
	element.icon = if icon and icon ~= "" then (if string.find(icon, "://") then icon else "rbxassetid://" .. icon) else nil
	Elements.byId[element.id] = element
end

return Elements
