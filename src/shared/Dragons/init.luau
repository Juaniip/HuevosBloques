-- Especies de dragones: cada archivo de esta carpeta es una especie con sus 3 fases (bebé, joven,
-- adulto) y el id del huevo del que sale. Para agregar una: copiá Fuego.luau, cambiale el `id`, el
-- `egg`, la paleta y las medidas, y sumala a SPECIES.
--   Dragons.byEgg.fuego -> la especie que sale del huevo "fuego" (o nil si todavía no está hecha)
--   Dragons.stages      -> { "bebe", "joven", "adulto" } (el orden de las fases)
local Dragons = {}

local SPECIES = {
	require(script.Fuego),
}

Dragons.stages = { "bebe", "joven", "adulto" }
Dragons.list = SPECIES
Dragons.byEgg = {}
for _, species in SPECIES do
	Dragons.byEgg[species.egg] = species
end

return Dragons
