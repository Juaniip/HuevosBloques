-- Todos los huevos (las fotos de referencia están en Escritorio/Huevos).
--
-- Cada huevo tiene:
--   element  su elemento (ver Elements.luau), o dos: { "llama", "hielo" }. Le da el color a la etiqueta
--   palette  colores por nombre: { r, g, b }, con neon = true o glass = transparencia si hace falta
--   paint(c) devuelve el nombre del color de cada ladrillo. `c` trae:
--              c.t      altura de -1 (abajo) a 1 (arriba)
--              c.theta  ángulo alrededor (0 = frente, en radianes)
--              c.u, c.v posición sobre el frente en studs, con (0, 0) en el centro
--              c.front  true si la celda está del lado de adelante (c.z < 0)
--              c.x, c.y, c.z, c.row, c.rng, c.noise(escala, capa?) -> -1..1 (manchas suaves)
--   tiles    parte de ladrillos lisos, sin studs (0 a 1; 0.25 si no se pone)
--   decor    adornos (ver EggDecor.luau) · stand: pie (o cubo) · fx: fuego, chispas, brillos, luz
local Paint = require(script.Parent.Paint)

local pick = Paint.pick

-- Vértices de un icosaedro, girado para que un pentágono quede al frente (huevo Fútbol).
local BALL_POINTS = {}
do
	local phi = (1 + math.sqrt(5)) / 2
	local raw = {}
	for _, a in { -1, 1 } do
		for _, b in { -phi, phi } do
			table.insert(raw, { 0, a, b })
			table.insert(raw, { a, b, 0 })
			table.insert(raw, { b, 0, a })
		end
	end
	-- (0, 1, phi) pasa a mirar al frente (-Z), un poco hacia arriba.
	local turn = math.atan2(0.15, -0.99) - math.atan2(1, phi)
	for _, point in raw do
		local m = math.sqrt(point[1] ^ 2 + point[2] ^ 2 + point[3] ^ 2)
		local y, z = point[2] / m, point[3] / m
		table.insert(BALL_POINTS, { point[1] / m, z * math.sin(turn) + y * math.cos(turn), z * math.cos(turn) - y * math.sin(turn) })
	end
end

local Eggs = {}

Eggs.list = {
	{
		id = "caballito_mar",
		element = { "mar", "naturaleza" },
		name = "Caballito de Mar",
		palette = {
			lavender = { 180, 150, 230 },
			glassBlue = { 60, 150, 230, glass = 0.3 },
			azure = { 60, 160, 215 },
			sky = { 125, 195, 235 },
			teal = { 40, 175, 190 },
			aqua = { 115, 215, 200 },
			mint = { 165, 225, 190 },
			yellow = { 250, 225, 110 },
			cream = { 245, 215, 160 },
			orange = { 245, 130, 30 },
			red = { 210, 45, 35 },
		},
		paint = function(c)
			-- Remolino amarillo (la cola del caballito) al frente.
			if c.front and c.z < -2 then
				local du, dv = c.u - 0.3, c.v + 0.8
				local r = math.sqrt(du * du + dv * dv)
				if r < 4.6 then
					local turn = math.atan2(dv, du) / (2 * math.pi)
					if r > 0.8 and (turn + r / 3.4) % 1 < 0.3 then
						return "yellow"
					end
					return pick(c.rng, "teal", 3, "aqua", 1)
				end
			end
			if c.t > 0.8 then
				return "lavender"
			elseif c.t > 0.6 then
				return pick(c.rng, "glassBlue", 3, "azure", 1)
			elseif c.t > 0.25 then
				return pick(c.rng, "sky", 3, "azure", 2)
			elseif c.t > -0.45 then
				return pick(c.rng, "teal", 3, "aqua", 2, "sky", 1)
			elseif c.t > -0.75 then
				return pick(c.rng, "aqua", 3, "mint", 2)
			end
			return pick(c.rng, "yellow", 2, "cream", 2)
		end,
		decor = {
			{ kind = "fins", base = "azure", colors = { "orange", "red", "orange" }, t = 0.05 },
		},
	},
	{
		id = "cactus",
		element = { "terra", "naturaleza" },
		name = "Cactus",
		palette = {
			green = { 40, 140, 60 },
			lime = { 150, 195, 50 },
			white = { 245, 245, 240 },
			cream = { 240, 220, 160 },
			pink = { 235, 120, 190 },
			magenta = { 200, 30, 130 },
		},
		paint = function(c)
			if c.t > 0.75 then
				return pick(c.rng, "lime", 4, "green", 1)
			end
			local n = c.noise(0.3) + c.rng:NextNumber(-0.15, 0.15)
			return if n > 0 then "green" else "lime"
		end,
		decor = {
			{ kind = "spines", count = 14, colors = { "white", "white", "cream" } },
			{ kind = "cactusArm", theta = -70, t = 0.45, color = "green", petals = "magenta", center = "pink" },
		},
	},
	{
		id = "chicle",
		element = { "naturaleza", "electrico" },
		name = "Chicle",
		tiles = 0.45,
		palette = {
			pink = { 235, 130, 185 },
			hot = { 210, 40, 130 },
			light = { 248, 180, 210 },
			lilac = { 230, 150, 225 },
		},
		paint = function(c)
			return pick(c.rng, "pink", 3, "hot", 3, "light", 2, "lilac", 1)
		end,
	},
	{
		id = "coral",
		element = { "naturaleza", "mar" },
		name = "Coral",
		palette = {
			coral = { 240, 110, 100 },
			red = { 200, 40, 40 },
			salmon = { 250, 145, 125 },
			pink = { 240, 135, 190 },
			yellow = { 250, 240, 150 },
			purple = { 90, 40, 150 },
		},
		paint = function(c)
			-- Rombos concéntricos al frente.
			if c.front and c.z < -2 then
				local d = math.abs(c.u) + math.abs(c.v + 0.5) * 0.8
				if d < 2.2 then
					return "coral"
				elseif d < 7 then
					return if math.floor((d - 2.2) / 1.3) % 2 == 0 then "pink" else "coral"
				end
			end
			return pick(c.rng, "coral", 4, "red", 2, "salmon", 2, "pink", 1)
		end,
		decor = {
			{
				kind = "coral",
				clusters = {
					{ theta = -40, t = 0.62, color = "yellow", depth = 2, length = 1.8 },
					{ theta = -62, t = 0.42, color = "purple", depth = 2, length = 1.5 },
					{ theta = 20, t = 0.9, color = "coral", depth = 2, length = 2.4 },
					{ theta = 72, t = 0.55, color = "coral", depth = 2, length = 2.2 },
				},
			},
		},
	},
	{
		id = "electrico",
		element = "electrico",
		name = "Eléctrico",
		palette = {
			yellow = { 250, 205, 30 },
			lime = { 190, 220, 50 },
			cyan = { 40, 175, 215 },
			blue = { 20, 100, 200 },
		},
		paint = function(c)
			if c.t < -0.55 then
				return pick(c.rng, "blue", 3, "yellow", 2, "cyan", 1)
			end
			-- Franjas en diagonal que se retuercen.
			local band = c.theta / math.pi * 2 + c.t * 3 + c.noise(0.25) * 1.5
			return ({ "yellow", "lime", "cyan", "blue" })[math.floor(band) % 4 + 1]
		end,
		fx = { sparks = { 255, 235, 80 }, light = { 255, 230, 90, 14, 1 } },
	},
	{
		id = "estrella",
		element = { "terra", "electrico" },
		name = "Estrella",
		palette = {
			blue = { 70, 155, 215 },
			dark = { 40, 100, 190 },
			teal = { 75, 180, 200 },
			mint = { 120, 210, 170 },
			green = { 160, 205, 90 },
			pale = { 205, 235, 220 },
			white = { 245, 248, 245 },
			yellow = { 250, 205, 50 },
		},
		paint = function(c)
			if c.t < -0.6 or c.t > 0.86 then
				return pick(c.rng, "dark", 4, "blue", 2, "white", 0.5)
			end
			local n = c.noise(0.3)
			if n > 0.25 then
				return pick(c.rng, "mint", 2, "green", 2)
			elseif n < -0.3 then
				return pick(c.rng, "teal", 2, "pale", 1)
			end
			return pick(c.rng, "blue", 4, "teal", 2, "yellow", 0.3, "white", 0.3)
		end,
		decor = {
			{ kind = "star", theta = 30, t = -0.05, color = "yellow", size = 1.1 },
			{ kind = "dots", count = 14, colors = { "pale", "green", "yellow", "mint", "white" }, avoidFront = true },
		},
	},
	{
		id = "fuego",
		element = "llama",
		name = "Fuego",
		tiles = 0.4,
		palette = {
			dark = { 140, 30, 30 },
			crimson = { 170, 35, 30 },
			red = { 205, 55, 40 },
			orange = { 240, 130, 40 },
			yellow = { 250, 220, 40 },
		},
		paint = function(c)
			-- Llama al frente: angosta arriba, redonda abajo.
			if c.front and c.v > -5.5 and c.v < 7 then
				local width = if c.v > -1 then 3.6 * (1 - (c.v + 1) / 9) else 3.6 * math.sqrt(math.max(0, 1 - ((c.v + 1) / 4.5) ^ 2))
				local e = math.abs(c.u) / math.max(width, 0.6) + c.noise(0.5) * 0.35
				if e < 0.4 then
					return "yellow"
				elseif e < 0.75 then
					return "orange"
				elseif e < 1.05 then
					return "red"
				end
			end
			return pick(c.rng, "dark", 3, "red", 2, "crimson", 2)
		end,
		fx = { fire = true, light = { 255, 140, 40, 16, 1.5 } },
	},
	{
		id = "pez_linterna",
		element = { "mar", "electrico" },
		name = "Pez Linterna",
		palette = {
			navy = { 30, 50, 90 },
			blue = { 40, 95, 185 },
			royal = { 65, 115, 205 },
			purple = { 105, 70, 165 },
			violet = { 145, 115, 195 },
			sand = { 115, 145, 195 },
			yellow = { 245, 200, 30 },
			cream = { 245, 230, 150 },
			glowCyan = { 120, 230, 255, neon = true },
			glowYellow = { 255, 240, 120, neon = true },
			white = { 240, 240, 240 },
		},
		paint = function(c)
			-- La "boca" amarilla en V con la luz en el medio.
			if c.front and c.z < -2 then
				local au = math.abs(c.u)
				if c.v > 0 and c.v < 2.6 and au < 3.2 and math.abs(au - c.v * 1.1) < 0.9 then
					return "yellow"
				elseif au < 1.1 and c.v > -1.3 and c.v <= 0 then
					return "cream"
				elseif au < 1.1 and c.v > -2.5 and c.v <= -1.3 then
					return "yellow"
				end
			end
			return pick(c.rng, "navy", 3, "blue", 3, "royal", 2, "purple", 3, "sand", 1, "violet", 1)
		end,
		decor = {
			{ kind = "dots", count = 10, colors = { "glowCyan", "glowCyan", "glowYellow" }, size = 0.8, avoidFront = true },
		},
		stand = { color = "white" },
		fx = { light = { 120, 220, 255, 12, 0.8 } },
	},
	{
		id = "roca_flamante",
		element = { "terra", "llama" },
		name = "Roca Flamante",
		tiles = 0.55,
		palette = {
			dark = { 120, 25, 25 },
			red = { 170, 40, 30 },
			amber = { 220, 100, 30 },
			orange = { 240, 145, 40 },
		},
		paint = function(c)
			-- Mármol: dos capas de manchas.
			local n = c.noise(0.28) + c.noise(0.7, 1) * 0.5
			if n > 0.3 then
				return "orange"
			elseif n > 0.1 then
				return "amber"
			elseif n > -0.25 then
				return "red"
			end
			return "dark"
		end,
		decor = {
			{ kind = "domes", count = 6, size = 1.8, colors = { "dark", "red", "amber" } },
		},
	},
	{
		id = "tierra",
		element = "terra",
		name = "Tierra",
		palette = {
			dark = { 90, 55, 35 },
			brown = { 125, 72, 40 },
			reddish = { 160, 85, 50 },
			tan = { 190, 130, 70 },
			sand = { 220, 170, 90 },
		},
		paint = function(c)
			local up = (c.t + 1) / 2 -- más claro arriba
			return pick(c.rng, "dark", 1, "brown", 3, "reddish", 2, "tan", 1 + 3 * up, "sand", up * up * 4)
		end,
	},
	{
		id = "tormenta",
		element = { "mar", "electrico" },
		name = "Tormenta",
		palette = {
			navy = { 30, 45, 75 },
			black = { 25, 25, 30 },
			deep = { 35, 60, 105 },
			slate = { 95, 115, 135 },
		},
		paint = function(c)
			return pick(c.rng, "navy", 5, "black", 3, "deep", 2, "slate", 1)
		end,
		decor = {
			{ kind = "domes", count = 6, size = 2.8, colors = { "navy", "navy", "black" } },
		},
		fx = { sparks = { 160, 200, 255 } },
	},
	{
		id = "tropical",
		element = { "terra", "naturaleza" },
		name = "Tropical",
		palette = {
			brown = { 110, 65, 35 },
			tan = { 170, 110, 60 },
			light = { 205, 150, 85 },
			green = { 50, 170, 60 },
			lime = { 100, 205, 70 },
		},
		paint = function(c)
			-- Cinturón verde con su hebilla al frente.
			if math.abs(c.t + 0.22) < 0.07 then
				return "green"
			end
			if c.front and c.z < -2 and math.abs(c.u) < 1.3 and c.t < -0.22 and c.t > -0.42 then
				return pick(c.rng, "green", 2, "lime", 1)
			end
			local up = (c.t + 1) / 2
			return pick(c.rng, "brown", 3 - up, "tan", 2 + up, "light", 1 + up * 2)
		end,
		decor = {
			{
				kind = "leaves",
				color = "green",
				tip = "lime",
				clusters = { { theta = -70, t = 0.72, count = 3 }, { theta = 35, t = 0.95, count = 2 } },
			},
		},
	},
	{
		id = "vegetal",
		element = "naturaleza",
		name = "Vegetal",
		palette = {
			dark = { 30, 90, 40 },
			green = { 40, 150, 60 },
			lime = { 150, 200, 40 },
			yellow = { 250, 200, 30 },
		},
		paint = function(c)
			-- Rayo amarillo que baja por el frente.
			if c.front and Paint.nearLine(c.u, c.v, { { 0.5, 6 }, { -1.5, 2 }, { 1.5, 0.5 }, { -1, -4 } }, 0.85) then
				return "yellow"
			end
			if c.t < -0.5 then
				return pick(c.rng, "dark", 3, "green", 2, "lime", 1)
			end
			local n = c.noise(0.3)
			if n > 0.15 then
				return pick(c.rng, "lime", 3, "green", 1)
			end
			return pick(c.rng, "green", 3, "lime", 1, "dark", 1)
		end,
	},
	{
		id = "ventisca",
		element = { "mar", "llama" },
		name = "Ventisca",
		palette = {
			white = { 240, 245, 250 },
			ice = { 185, 215, 240 },
			sky = { 105, 180, 230 },
			blue = { 60, 130, 210 },
		},
		paint = function(c)
			if math.abs(c.t + 0.08) < 0.12 then
				return pick(c.rng, "white", 4, "ice", 1)
			elseif c.t > 0.4 then
				return pick(c.rng, "white", 2, "ice", 2, "sky", 1)
			end
			return pick(c.rng, "sky", 3, "ice", 2, "blue", 1, "white", 1)
		end,
		fx = { sparkles = { 230, 245, 255 } },
	},
	{
		id = "volcan",
		element = { "llama", "terra" },
		name = "Volcán",
		palette = {
			black = { 28, 28, 32 },
			gray = { 90, 90, 95 },
			lava = { 255, 120, 20, neon = true, glass = 0.1 },
			lavaRed = { 225, 45, 20, neon = true, glass = 0.1 },
		},
		paint = function(c)
			-- Grietas de lava entre las piedras negras.
			if math.abs(c.noise(0.22)) < 0.035 or math.abs(c.noise(0.3, 2)) < 0.02 then
				return pick(c.rng, "lava", 2, "lavaRed", 1)
			end
			return pick(c.rng, "black", 9, "gray", 1)
		end,
		decor = {
			{ kind = "spines", count = 10, colors = { "lava", "lavaRed" }, length = 0.5 },
		},
		fx = { fire = true, sparks = { 255, 150, 50 }, light = { 255, 110, 30, 18, 2 } },
	},
	{
		id = "hielo",
		element = "hielo",
		name = "Hielo",
		tiles = 0.3,
		palette = {
			pale = { 190, 230, 245 },
			sky = { 120, 205, 235 },
			azure = { 70, 180, 220 },
			white = { 245, 250, 250 },
			cream = { 245, 240, 190 },
			clear = { 225, 245, 255, glass = 0.45 },
		},
		paint = function(c)
			-- Rombo blanco al frente.
			if c.front and c.z < -2 then
				local d = math.abs(c.u) + math.abs(c.v + 0.5) * 0.75
				if d < 2.4 then
					return "white"
				elseif d < 3.6 then
					return pick(c.rng, "cream", 2, "white", 1)
				elseif d < 4.6 then
					return pick(c.rng, "pale", 1, "sky", 1)
				end
			end
			return pick(c.rng, "sky", 3, "pale", 3, "azure", 2, "white", 1, "clear", 1)
		end,
		fx = { sparkles = { 200, 240, 255 } },
	},
	{
		id = "agua",
		element = "mar",
		name = "Agua",
		palette = {
			navy = { 30, 60, 110 },
			blue = { 30, 90, 170 },
			royal = { 25, 115, 205 },
			slate = { 70, 90, 125 },
			glass = { 40, 150, 210, glass = 0.35 },
			cyan = { 45, 175, 215 },
			teal = { 45, 195, 170 },
		},
		paint = function(c)
			-- Dos olas trenzadas que bajan, una al frente, atrás y a cada costado.
			local a = ((math.deg(c.theta) + 45) % 90 - 45) / 9.5
			if c.v > -7 and c.v < 5 then
				local wave = math.sin(c.v * 0.75) * 1.3
				if math.abs(a - wave) < 0.75 then
					return "cyan"
				elseif math.abs(a + wave - 0.4) < 0.75 then
					return "teal"
				end
			end
			if c.t > 0.8 then
				return pick(c.rng, "blue", 2, "glass", 1, "royal", 1)
			end
			return pick(c.rng, "navy", 3, "blue", 4, "royal", 2, "slate", 1, "glass", 1)
		end,
	},
	{
		id = "barro",
		element = { "terra", "mar" },
		name = "Barro",
		tiles = 0.15,
		palette = {
			mud = { 125, 75, 45 },
			dark = { 85, 50, 32 },
			reddish = { 105, 60, 40 },
		},
		paint = function(c)
			return pick(c.rng, "mud", 5, "dark", 2, "reddish", 2)
		end,
	},
	{
		id = "nube",
		element = { "llama", "mar" },
		name = "Nube",
		tiles = 0.45,
		palette = {
			white = { 245, 245, 245 },
			pale = { 205, 222, 238 },
			mist = { 185, 200, 225 },
		},
		paint = function(c)
			local e = Paint.oval(c, 55, 2.3, 3.2, -1)
			if e < 0.5 then
				return "white"
			elseif e < 1 then
				return "pale"
			elseif c.t > 0.75 or (c.t > 0.3 and c.t < 0.55) then
				return "white"
			elseif c.t > 0.55 then
				return "pale"
			elseif c.t < -0.55 then
				return pick(c.rng, "pale", 2, "mist", 2)
			end
			return pick(c.rng, "white", 3, "pale", 2)
		end,
		decor = {
			{ kind = "domes", count = 7, size = 2, colors = { "white", "pale" }, tMin = 0.35, tMax = 0.6 },
		},
	},
	{
		id = "picante",
		element = { "llama", "naturaleza" },
		name = "Picante",
		palette = {
			yellow = { 250, 205, 40 },
			orange = { 240, 120, 30 },
			red = { 200, 40, 30 },
			dark = { 160, 30, 25 },
			green = { 50, 150, 70 },
		},
		paint = function(c)
			if c.t > 0.45 then
				return pick(c.rng, "yellow", 5, "orange", 1)
			elseif c.t > -0.25 then
				return if c.noise(0.6) > 0.3 then "yellow" else "orange"
			end
			return pick(c.rng, "red", 4, "dark", 1)
		end,
		decor = {
			{ kind = "leaves", color = "green", stem = "green", clusters = { { theta = -30, t = 0.97, count = 2 }, { theta = 120, t = 0.97, count = 2 } } },
		},
	},
	{
		id = "pajaro_fuego",
		element = { "llama", "naturaleza" },
		name = "Pájaro de Fuego",
		palette = {
			dark = { 160, 30, 25 },
			red = { 205, 60, 35 },
			orange = { 240, 120, 30 },
			yellow = { 250, 210, 40 },
		},
		paint = function(c)
			if c.t > -0.15 and c.t < 0.2 then
				return pick(c.rng, "yellow", 3, "orange", 2, "dark", 0.5)
			end
			return pick(c.rng, "orange", 3, "dark", 3, "red", 1)
		end,
		fx = { sparks = { 255, 170, 60 } },
	},
	{
		id = "mariposa",
		element = { "naturaleza", "llama" },
		name = "Mariposa",
		palette = {
			yellow = { 250, 200, 40 },
			orange = { 240, 140, 40 },
			gold = { 235, 170, 40 },
			pink = { 225, 70, 150 },
			cyan = { 40, 170, 210 },
			blue = { 45, 95, 200 },
			teal = { 40, 165, 175 },
		},
		paint = function(c)
			local n = c.noise(0.5)
			if n > 0.35 then
				return "pink"
			elseif n < -0.4 then
				return "cyan"
			end
			return pick(c.rng, "yellow", 4, "orange", 2, "gold", 1)
		end,
		decor = {
			{ kind = "dots", count = 8, size = 0.8, colors = { "pink", "cyan" } },
			{ kind = "butterflies", colors = { "blue", "teal" }, spots = { { -55, 0.8 }, { 55, 0.8 } } },
		},
	},
	{
		id = "nenufar",
		element = { "mar", "naturaleza" },
		name = "Nenúfar",
		palette = {
			dark = { 30, 80, 45 },
			green = { 45, 130, 65 },
			mid = { 60, 150, 80 },
			lime = { 160, 195, 70 },
			pink = { 215, 70, 145 },
			magenta = { 165, 30, 100 },
		},
		paint = function(c)
			if c.row % 3 == 0 then
				return pick(c.rng, "dark", 4, "green", 1)
			end
			return pick(c.rng, "green", 4, "mid", 1, "dark", 1)
		end,
		decor = {
			{ kind = "lotus", leaf = "green", petals = "magenta", inner = "pink" },
			{ kind = "dots", count = 4, size = 0.6, colors = { "lime" } },
			{ kind = "flakes", color = "green", size = 0.7, spots = { { -95, 0 }, { 80, -0.15 } } },
		},
	},
	{
		id = "camaleon",
		element = { "terra", "electrico" },
		name = "Camaleón",
		palette = {
			lime = { 150, 210, 50 },
			pink = { 230, 70, 160 },
			blue = { 40, 160, 220 },
			yellow = { 250, 210, 40 },
			orange = { 245, 130, 40 },
			green = { 40, 170, 70 },
			red = { 210, 40, 40 },
		},
		paint = function(c)
			local e = Paint.oval(c, 52, 2.3, 3.4, -1)
			if e < 0.25 then
				return "orange"
			elseif e < 0.5 then
				return "green"
			elseif e < 0.75 then
				return "blue"
			elseif e < 1 then
				return "pink"
			end
			return pick(c.rng, "lime", 2, "pink", 2, "blue", 2, "yellow", 2, "orange", 1, "green", 1)
		end,
		decor = {
			{ kind = "horns", count = 9, colors = { "lime", "lime", "yellow", "blue" }, t = 0.72 },
		},
	},
	{
		id = "paladin",
		element = { "electrico", "terra" },
		name = "Paladín",
		palette = {
			white = { 240, 240, 238 },
			light = { 210, 214, 220 },
			silver = { 165, 170, 178 },
			gold = { 240, 190, 40 },
			blue = { 30, 110, 210 },
			teal = { 40, 180, 175 },
		},
		paint = function(c)
			local deg = math.abs(math.deg(c.theta))
			if c.t > -0.35 and c.t < -0.15 then
				return "gold" -- cinturón
			elseif c.t > 0.02 and c.t < 0.12 then
				return pick(c.rng, "gold", 2, "silver", 1)
			elseif c.t > 0 and (deg < 6 or math.abs(deg - 90) < 6) then
				return "gold" -- tiras que suben
			end
			return pick(c.rng, "white", 4, "light", 2, "silver", 0.5)
		end,
		decor = {
			{ kind = "wings", colors = { "blue", "teal", "blue" }, t = 0.4 },
			{ kind = "crown", color = "gold", gem = "blue" },
		},
		fx = { sparkles = { 255, 230, 120 } },
	},
	{
		id = "laser",
		element = { "llama", "electrico" },
		name = "Láser",
		palette = {
			yellow = { 250, 205, 40 },
			orange = { 240, 140, 40 },
			red = { 210, 50, 40 },
			black = { 25, 25, 28 },
			neonRed = { 255, 40, 40, neon = true },
		},
		paint = function(c)
			local e = Paint.oval(c, 55, 2.2, 3, -1.5)
			if e < 0.55 then
				return if c.v < -2 then "red" else "orange"
			elseif e < 0.75 then
				return "yellow"
			elseif e < 1 then
				return "orange"
			end
			if c.front and math.abs(c.u) < 1.2 and c.t < 0.4 then
				return if c.row % 2 == 0 then "orange" else "yellow"
			end
			return pick(c.rng, "yellow", 4, "orange", 2)
		end,
		decor = {
			{ kind = "visor", theta = -30, t = 0.6, color = "black", rim = "neonRed", lens = "neonRed" },
		},
	},
	{
		id = "metal_caliente",
		element = { "electrico", "llama" },
		name = "Metal Caliente",
		palette = {
			black = { 30, 30, 32 },
			dark = { 55, 55, 60 },
			gray = { 90, 90, 96 },
			orange = { 245, 135, 30 },
			yellow = { 250, 210, 40 },
			lava = { 230, 60, 20, neon = true, glass = 0.2 },
		},
		paint = function(c)
			local e = Paint.oval(c, 55, 2.2, 3.6, -0.5)
			if e < 0.65 then
				return pick(c.rng, "gray", 2, "lava", 1, "dark", 1)
			elseif e < 1 then
				return "orange"
			end
			if c.front and c.v > 2.5 and math.abs(c.u) < (8 - c.v) * 0.45 then
				return pick(c.rng, "yellow", 2, "lava", 1, "orange", 1)
			end
			return pick(c.rng, "black", 4, "dark", 3, "gray", 2)
		end,
		fx = { light = { 255, 130, 40, 12, 1 } },
	},
	{
		id = "alpino",
		element = { "terra", "hielo" },
		name = "Alpino",
		palette = {
			white = { 240, 240, 240 },
			light = { 195, 198, 202 },
			gray = { 140, 142, 148 },
			dark = { 95, 97, 103 },
			sky = { 160, 205, 235 },
			pine = { 30, 120, 60 },
			trunk = { 100, 65, 40 },
		},
		paint = function(c)
			local e = Paint.oval(c, 55, 2, 2.6, -2)
			if e < 0.4 then
				return "gray"
			elseif e < 1 then
				return "white"
			end
			if c.t < -0.55 then
				return pick(c.rng, "dark", 3, "gray", 2)
			elseif c.t < -0.2 then
				return pick(c.rng, "gray", 2, "light", 2, "white", 1)
			elseif c.t > 0.42 + math.abs(math.sin(c.theta)) * 0.12 and c.t < 0.72 then
				return pick(c.rng, "sky", 4, "white", 1)
			end
			return if c.noise(0.4) > 0.3 then "light" else "white"
		end,
		decor = {
			{ kind = "pines", count = 9, t = 0.15, color = "pine", trunk = "trunk" },
		},
	},
	{
		id = "copo_nieve",
		element = { "terra", "hielo" },
		name = "Copo de Nieve",
		palette = {
			white = { 248, 250, 252 },
			pale = { 180, 220, 240 },
			sky = { 120, 190, 235 },
			azure = { 60, 150, 220 },
			blue = { 30, 110, 200 },
			glass = { 140, 200, 240, glass = 0.35 },
		},
		paint = function(c)
			-- Copo grande de 8 brazos al frente.
			if c.front and c.z < -2 then
				local du, dv = c.u, c.v + 0.5
				local r = math.sqrt(du * du + dv * dv)
				if r < 0.8 then
					return "sky"
				elseif r < 4.4 then
					local angle = math.atan2(dv, du) % (math.pi / 4)
					local off = math.min(angle, math.pi / 4 - angle)
					if r * math.sin(off) < 0.6 then
						return "white"
					end
				end
			end
			return pick(c.rng, "sky", 3, "azure", 3, "blue", 1, "pale", 2, "glass", 1)
		end,
		decor = {
			{ kind = "flakes", color = "white", size = 1, spots = { { -45, 0.6 }, { 45, 0.6 }, { -45, -0.55 }, { 45, -0.55 } } },
		},
		fx = { sparkles = { 220, 240, 255 } },
	},
	{
		id = "fuego_fresco",
		element = { "llama", "hielo" },
		name = "Fuego Fresco",
		palette = {
			navy = { 25, 40, 75 },
			blue = { 30, 110, 200 },
			azure = { 60, 155, 220 },
			sky = { 120, 205, 235 },
			ice = { 210, 240, 250 },
			orange = { 245, 130, 30 },
			red = { 215, 55, 35 },
			deep = { 160, 35, 30 },
			light = { 250, 175, 70 },
			yellow = { 250, 210, 50 },
		},
		paint = function(c)
			-- Mitad fría (izquierda, mirando de frente) y mitad caliente, con una costura azul noche.
			if math.abs(c.x) < 1.2 then
				return "navy"
			end
			local cold = c.x > 0
			local e = Paint.oval(c, 55, 2.2, 3.2, -0.5)
			if e < 0.35 then
				return if cold then "sky" else "orange"
			elseif e < 0.75 then
				return if cold then "ice" else "light"
			elseif e < 1 then
				return if cold then "sky" else "yellow"
			end
			if cold then
				return pick(c.rng, "blue", 3, "azure", 2, "sky", 2)
			end
			return pick(c.rng, "orange", 3, "red", 2, "deep", 1)
		end,
	},
	{
		id = "futbol",
		element = { "hielo", "llama" },
		name = "Fútbol",
		palette = {
			white = { 245, 245, 242 },
			cream = { 230, 230, 225 },
			black = { 25, 25, 28 },
			gold = { 220, 175, 60 },
			wine = { 130, 25, 30 },
		},
		paint = function(c)
			-- Pentágonos negros donde caen los 12 vértices de un icosaedro (como una pelota).
			local half = 8.4
			local dx, dy, dz = c.x / 6, (c.v + 0.3) / half, c.z / 6
			local m = math.sqrt(dx * dx + dy * dy + dz * dz)
			for _, p in BALL_POINTS do
				if (dx * p[1] + dy * p[2] + dz * p[3]) / m > 0.955 then
					return "black"
				end
			end
			return pick(c.rng, "white", 6, "cream", 1)
		end,
		decor = {
			{ kind = "star", theta = 0, t = 0.38, color = "gold", size = 0.4, backing = "wine" },
		},
	},
	{
		id = "cubo_hielo",
		element = { "mar", "hielo" },
		name = "Cubo de Hielo",
		tiles = 0.3,
		palette = {
			pale = { 170, 215, 240 },
			sky = { 110, 185, 235 },
			azure = { 60, 150, 225 },
			blue = { 30, 100, 200 },
			glass = { 120, 200, 245, glass = 0.4 },
			crystal = { 170, 225, 255, glass = 0.35 },
			cube = { 90, 190, 235, glass = 0.45 },
		},
		paint = function(c)
			local e = Paint.oval(c, 52, 1.8, 2.6, -1.5)
			if e < 0.5 then
				return "blue"
			elseif e < 1 then
				return "azure"
			end
			return pick(c.rng, "sky", 3, "pale", 2, "glass", 2, "azure", 1)
		end,
		decor = {
			{ kind = "horns", count = 8, colors = { "crystal" }, t = 0.8, length = 1.2 },
		},
		stand = { color = "cube", cube = true },
	},
	{
		id = "helado",
		element = { "mar", "hielo" },
		name = "Helado",
		palette = {
			cream = { 245, 240, 220 },
			vanilla = { 235, 225, 195 },
			red = { 200, 30, 35 },
			dark = { 150, 20, 30 },
			cherry = { 150, 15, 25 },
			stem = { 120, 40, 30 },
		},
		paint = function(c)
			-- Crema arriba que chorrea en gotas sobre el rojo.
			local drip = 0.1 + math.sin(c.theta * 6) * 0.12 + c.noise(0.5) * 0.08
			if c.t > drip then
				return pick(c.rng, "cream", 4, "vanilla", 1)
			elseif c.t < -0.45 then
				return pick(c.rng, "dark", 3, "red", 1)
			end
			return pick(c.rng, "red", 4, "dark", 1)
		end,
		decor = {
			{ kind = "cherry", color = "cherry", stem = "stem" },
		},
	},
	{
		id = "diente_leon",
		element = { "naturaleza", "hielo" },
		name = "Diente de León",
		tiles = 0.35,
		palette = {
			white = { 245, 245, 242 },
			light = { 205, 208, 212 },
			gray = { 160, 163, 170 },
		},
		paint = function(c)
			if Paint.oval(c, 58, 0.9, 1.6, -1) < 1 then
				return "gray"
			end
			return pick(c.rng, "white", 5, "light", 2, "gray", 0.3)
		end,
		fx = { sparkles = { 255, 255, 255 } },
	},
	{
		id = "mojito",
		element = { "naturaleza", "hielo" },
		name = "Mojito",
		palette = {
			yellow = { 250, 210, 40 },
			citrus = { 215, 220, 50 },
			lime = { 150, 200, 50 },
			green = { 60, 160, 60 },
			dark = { 30, 95, 45 },
			mint = { 70, 180, 90 },
		},
		paint = function(c)
			if Paint.oval(c, 55, 2, 3, -1) < 1 then
				return if c.t > -0.1 then "citrus" else "lime"
			end
			if c.t > 0.45 then
				return pick(c.rng, "yellow", 4, "citrus", 1)
			elseif c.t > 0.1 then
				return pick(c.rng, "citrus", 3, "yellow", 1, "lime", 1)
			elseif c.t > -0.3 then
				return pick(c.rng, "lime", 4, "citrus", 1)
			elseif c.t > -0.6 then
				return pick(c.rng, "green", 4, "lime", 1)
			end
			return pick(c.rng, "dark", 4, "green", 1)
		end,
		decor = {
			{ kind = "leaves", color = "mint", tip = "green", stem = "green", clusters = { { theta = 40, t = 0.97, count = 3 } } },
		},
	},
	{
		id = "puro_fuego",
		element = { "puro", "llama" },
		name = "Puro Fuego",
		palette = {
			red = { 215, 45, 30 },
			orange = { 245, 120, 25 },
			yellow = { 250, 205, 40 },
			cream = { 230, 210, 170 },
			gold = { 235, 185, 45, shine = 0.15 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Llamas en franjas onduladas.
			local wave = c.t * 5 + math.sin(c.theta * 3) * 0.6 + c.noise(0.4) * 1.2
			local band = math.floor(wave) % 3
			return if band == 0 then "red" elseif band == 1 then "orange" else pick(c.rng, "yellow", 3, "orange", 1)
		end,
		decor = {
			{ kind = "necklace", color = "gold", t = 0.55, drop = 0.35 },
			{ kind = "horns", count = 2, colors = { "cream" }, t = 0.82, length = 2.6 },
		},
		stand = { color = "stand" },
	},
	{
		id = "pura_tierra",
		element = { "puro", "terra" },
		name = "Pura Tierra",
		palette = {
			brown = { 120, 70, 40 },
			dark = { 85, 50, 30 },
			orange = { 200, 110, 45 },
			tan = { 205, 160, 110 },
			cream = { 235, 220, 185 },
			gold = { 235, 185, 45, shine = 0.15 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			local n = c.noise(0.45)
			if n > 0.3 then
				return "orange"
			elseif n < -0.3 then
				return "tan"
			end
			return pick(c.rng, "brown", 3, "dark", 2, "orange", 1)
		end,
		decor = {
			{ kind = "necklace", color = "gold", t = 0.55, drop = 0.35 },
			{ kind = "fangs", color = "cream", down = true, length = 1.6, ring = { t = -0.6, count = 9 } },
			{ kind = "flaps", color = "dark", t = 0.8, size = 0.8 },
		},
		stand = { color = "stand" },
	},
	{
		id = "puro",
		element = "puro",
		name = "Puro",
		palette = {
			sky = { 150, 205, 240 },
			pale = { 200, 230, 248 },
			white = { 248, 250, 252 },
			azure = { 95, 170, 225 },
			gold = { 235, 185, 45, shine = 0.15 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			if c.t > 0.6 then
				return pick(c.rng, "white", 3, "pale", 1)
			elseif c.noise(0.35) > 0.3 then
				return "white"
			end
			return pick(c.rng, "sky", 3, "pale", 2, "azure", 1)
		end,
		decor = {
			{ kind = "necklace", color = "gold", t = 0.55, drop = 0.35 },
			{ kind = "domes", size = 2, colors = { "white", "pale" }, tMin = 0.6, tMax = 0.85, count = 6 },
		},
		stand = { color = "stand" },
		fx = { sparkles = { 255, 245, 200 } },
	},
	{
		id = "espejo",
		element = "leyenda",
		name = "Espejo",
		tiles = 0.4,
		palette = {
			chrome = { 175, 178, 185, shine = 0.5 },
			light = { 215, 218, 224, shine = 0.6 },
			bright = { 245, 246, 250, shine = 0.7 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Reflejo en diagonal.
			local d = c.u * 0.8 + c.v
			if math.abs(d - 0.5) < 1.6 then
				return "bright"
			end
			return if c.t < -0.3 then "light" else "chrome"
		end,
		stand = { color = "stand" },
	},
	{
		id = "viento",
		element = "viento",
		name = "Viento",
		palette = {
			white = { 245, 246, 248 },
			cloud = { 215, 222, 230 },
			steel = { 130, 155, 180 },
			blue = { 160, 185, 210 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Arriba blanco con un remolino; abajo azul acero con vetas.
			local edge = 0.1 + math.sin(c.theta * 2) * 0.15
			if c.t > edge then
				local du, dv = c.u + 1.5, c.v - 4
				if c.front and math.sqrt(du * du + dv * dv) < 2.2 and math.sqrt(du * du + dv * dv) > 1.2 then
					return "cloud"
				end
				return pick(c.rng, "white", 5, "cloud", 1)
			end
			return if c.noise(0.4) > 0.2 then "blue" else "steel"
		end,
		stand = { color = "stand" },
	},
	{
		id = "zombie",
		element = { "metal", "oscuro" },
		name = "Zombi",
		palette = {
			sage = { 160, 175, 160 },
			gray = { 120, 125, 125 },
			pale = { 205, 210, 200 },
			moss = { 130, 150, 125 },
			crystal = { 190, 165, 235, glass = 0.25 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			local n = c.noise(0.5)
			if math.abs(n) < 0.05 then
				return "gray" -- grietas
			end
			return pick(c.rng, "sage", 4, "pale", 2, "moss", 2, "gray", 1)
		end,
		decor = {
			{ kind = "fangs", color = "crystal", down = true, length = 2.4, spots = { { -22, 0.15 }, { -10, 0.12 }, { 10, 0.12 }, { 22, 0.15 } } },
		},
		stand = { color = "stand" },
	},
	{
		id = "fosil",
		element = { "oscuro", "hielo" },
		name = "Fósil",
		palette = {
			ice = { 165, 210, 235 },
			white = { 240, 244, 248 },
			gray = { 165, 170, 178 },
			window = { 70, 95, 120, glass = 0.2 },
			bone = { 220, 215, 200 },
			wing = { 120, 200, 240, glass = 0.35 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Ventana cuadrada al frente con huesitos adentro.
			if c.front and c.z < -2 and math.abs(c.u) < 2.6 and c.v > -3 and c.v < 2.2 then
				if c.rng:NextNumber() < 0.35 then
					return "bone"
				end
				return "window"
			end
			return pick(c.rng, "ice", 4, "white", 2, "gray", 2)
		end,
		decor = {
			{ kind = "flaps", color = "wing", t = 0.82 },
		},
		stand = { color = "stand" },
	},
	{
		id = "pinguino",
		element = { "hielo", "oscuro" },
		name = "Pingüino",
		palette = {
			black = { 25, 25, 30 },
			dark = { 50, 52, 60 },
			white = { 245, 246, 248 },
			orange = { 245, 150, 40 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Panza blanca y carita blanca al frente.
			if c.front then
				local belly = (c.u / 3.4) ^ 2 + ((c.v + 2.5) / 5) ^ 2
				local face = (c.u / 2.2) ^ 2 + ((c.v - 4.4) / 1.6) ^ 2
				if belly < 1 or face < 1 then
					return "white"
				end
			end
			return pick(c.rng, "black", 5, "dark", 1)
		end,
		decor = {
			{ kind = "fangs", color = "orange", length = 1, spots = { { 0, 0.42 } } },
		},
		stand = { color = "stand" },
	},
	{
		id = "neon",
		element = { "electrico", "oscuro" },
		name = "Neón",
		palette = {
			base = { 40, 85, 110 },
			pink = { 255, 90, 170, neon = true, glass = 0.15 },
			green = { 150, 255, 80, neon = true, glass = 0.15 },
			cyan = { 70, 220, 255, neon = true, glass = 0.15 },
			yellow = { 255, 230, 80, neon = true, glass = 0.15 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Franjas de neón en diagonal sobre un fondo oscuro.
			local d = (c.theta * 4 + c.t * 6 + c.noise(0.3)) % 4
			if d < 0.8 then
				return "pink"
			elseif d < 1.5 then
				return "base"
			elseif d < 2.3 then
				return "cyan"
			elseif d < 3 then
				return "base"
			elseif d < 3.5 then
				return "green"
			end
			return if c.t < -0.3 then "yellow" else "green"
		end,
		stand = { color = "stand" },
		fx = { light = { 180, 120, 255, 14, 1 } },
	},
	{
		id = "serpiente_cascabel",
		element = { "oscuro", "naturaleza" },
		name = "Serpiente de Cascabel",
		palette = {
			green = { 60, 140, 70 },
			light = { 110, 180, 110 },
			white = { 230, 235, 225 },
			dark = { 35, 85, 45 },
			rattle = { 225, 190, 100 },
			stand = { 225, 235, 240, glass = 0.5 },
		},
		paint = function(c)
			-- Serpiente enroscada al frente, con el cascabel abajo.
			if c.front and c.z < -1.5 then
				local du, dv = c.u, c.v + 0.5
				local r = math.sqrt(du * du + dv * dv)
				local turn = math.atan2(dv, du) / (2 * math.pi)
				if r < 5.5 and (turn + r / 2.8) % 1 < 0.35 then
					return "dark"
				end
				if c.v < -5.5 and math.abs(c.u) < 3 then
					return "rattle"
				end
			end
			return pick(c.rng, "green", 4, "light", 2, "white", 1)
		end,
		stand = { color = "stand" },
	},
	{
		id = "fuego_oscuro",
		element = { "oscuro", "llama" },
		name = "Fuego Oscuro",
		palette = {
			black = { 25, 25, 30 },
			gray = { 75, 75, 80 },
			purple = { 110, 70, 165 },
			white = { 235, 235, 235 },
		},
		paint = function(c)
			-- Tres brazos violetas que giran.
			local du, dv = c.u, c.v + 1
			local r = math.sqrt(du * du + dv * dv)
			local turn = math.atan2(dv, du) / (2 * math.pi)
			if (turn * 3 + r / 3) % 1 < 0.32 and r > 0.8 then
				return "purple"
			end
			return if c.noise(0.35) > 0 then "gray" else "black"
		end,
		decor = {
			{ kind = "fangs", color = "white", length = 0.9, spots = { { -40, 0.7 }, { -35, 0.6 }, { -30, 0.5 } } },
		},
	},
	{
		id = "vampiro",
		element = { "llama", "oscuro" },
		name = "Vampiro",
		palette = {
			yellow = { 250, 205, 40 },
			orange = { 245, 130, 30 },
			red = { 200, 35, 30 },
			dark = { 140, 20, 25 },
			gold = { 225, 175, 70, shine = 0.15 },
			ruby = { 220, 30, 50, glass = 0.15 },
		},
		paint = function(c)
			local n = c.noise(0.4) + c.noise(0.9, 1) * 0.4
			if n > 0.25 then
				return "yellow"
			elseif n > 0 then
				return "orange"
			elseif n > -0.3 then
				return "red"
			end
			return "dark"
		end,
		decor = {
			{ kind = "necklace", color = "gold", gem = "ruby", t = -0.05, drop = 0, links = 26 },
		},
		fx = { light = { 255, 90, 40, 12, 1 } },
	},
	{
		id = "veneno",
		element = { "terra", "oscuro" },
		name = "Veneno",
		palette = {
			red = { 175, 25, 35 },
			dark = { 130, 15, 25 },
			lime = { 200, 230, 50 },
			green = { 40, 160, 60 },
		},
		paint = function(c)
			if math.abs(c.noise(0.35)) < 0.05 or math.abs(c.noise(0.5, 3)) < 0.03 then
				return "lime" -- venas
			end
			return pick(c.rng, "red", 3, "dark", 2)
		end,
		decor = {
			{ kind = "spines", count = 18, colors = { "green" }, length = 1.2 },
		},
	},
	{
		id = "erizo",
		element = { "terra", "oscuro" },
		name = "Erizo",
		palette = {
			brown = { 120, 65, 35 },
			orange = { 175, 100, 50 },
			dark = { 85, 45, 25 },
			black = { 25, 25, 25 },
			tan = { 190, 145, 100 },
		},
		paint = function(c)
			return pick(c.rng, "brown", 3, "orange", 2, "dark", 2)
		end,
		decor = {
			{ kind = "spines", count = 26, colors = { "dark", "dark", "black" }, length = 1.3 },
			{ kind = "snout", theta = 25, t = -0.35, color = "tan", nose = "black", ears = "tan" },
		},
	},
	{
		id = "oscuro",
		element = "oscuro",
		name = "Oscuro",
		palette = {
			black = { 22, 22, 25 },
			dark = { 50, 52, 58 },
		},
		paint = function(c)
			return pick(c.rng, "black", 6, "dark", 1)
		end,
		decor = {
			{ kind = "fangs", color = "black", length = 1.4, ring = { t = 0.45, count = 8 } },
		},
	},
	{
		id = "bateria",
		element = { "electrico", "metal" },
		name = "Batería",
		palette = {
			brown = { 110, 60, 35 },
			dark = { 80, 45, 30 },
			yellow = { 250, 205, 30 },
			orange = { 245, 160, 40 },
			red = { 220, 40, 30 },
			white = { 235, 235, 230 },
			metal = { 160, 165, 170, shine = 0.4 },
		},
		paint = function(c)
			-- Franja amarilla con un rayo rojo.
			if c.t > -0.35 and c.t < 0.35 + math.sin(c.theta) * 0.1 then
				if c.front and Paint.nearLine(c.u, c.v, { { 0.5, 4 }, { -1, 1 }, { 1, 0 }, { -0.5, -3 } }, 0.7) then
					return "red"
				end
				return pick(c.rng, "yellow", 4, "orange", 1)
			end
			if c.t > 0.6 and c.noise(0.6) > 0.35 then
				return "white"
			end
			return pick(c.rng, "brown", 3, "dark", 2)
		end,
		decor = {
			{ kind = "cap", color = "metal" },
		},
		fx = { sparks = { 255, 230, 80 } },
	},
	{
		id = "libelula",
		element = { "naturaleza", "metal" },
		name = "Libélula",
		palette = {
			dark = { 25, 60, 40 },
			green = { 40, 150, 70 },
			blue = { 50, 100, 140 },
			eye = { 70, 160, 230, glass = 0.25 },
			wing = { 150, 210, 245, glass = 0.45 },
			black = { 25, 25, 25 },
		},
		paint = function(c)
			local n = c.noise(0.45)
			if n > 0.3 then
				return "green"
			elseif n < -0.35 then
				return "blue"
			end
			return "dark"
		end,
		decor = {
			{ kind = "domes", size = 3, colors = { "eye" }, spots = { { -30, 0.6 }, { 30, 0.6 } } },
			{ kind = "insectWings", color = "wing", t = 0.35 },
			{ kind = "horns", count = 2, colors = { "black" }, t = 0.9, length = 1.4 },
		},
	},
	{
		id = "jade",
		element = { "naturaleza", "metal" },
		name = "Jade",
		tiles = 0.35,
		palette = {
			jade = { 145, 190, 160, shine = 0.1 },
			mint = { 180, 215, 190, shine = 0.1 },
			deep = { 110, 160, 125, shine = 0.1 },
			olive = { 175, 180, 120, shine = 0.1 },
			gray = { 150, 155, 150 },
		},
		paint = function(c)
			if math.abs(c.t + 0.05) < 0.08 then
				return "olive"
			end
			return pick(c.rng, "jade", 4, "mint", 2, "deep", 2, "gray", 0.5)
		end,
	},
	{
		id = "concha",
		element = { "mar", "metal" },
		name = "Concha",
		palette = {
			cream = { 240, 230, 200 },
			pink = { 245, 175, 200 },
			lilac = { 210, 180, 235 },
			blue = { 160, 205, 240 },
		},
		paint = function(c)
			if c.t > -0.3 and c.t < 0.3 then
				return pick(c.rng, "pink", 3, "lilac", 2, "blue", 1, "cream", 1)
			end
			return pick(c.rng, "cream", 5, "pink", 1)
		end,
		decor = {
			{ kind = "dots", count = 14, size = 1.4, colors = { "blue", "lilac", "pink" } },
		},
	},
	{
		id = "mercurio",
		element = { "mar", "metal" },
		name = "Mercurio",
		palette = {
			silver = { 150, 155, 162, shine = 0.35 },
			gray = { 105, 108, 115, shine = 0.3 },
			light = { 190, 192, 198, shine = 0.4 },
			black = { 35, 35, 40 },
			blue = { 40, 120, 230, glass = 0.2, neon = true },
		},
		paint = function(c)
			if c.rng:NextNumber() < 0.05 then
				return "blue"
			end
			return pick(c.rng, "silver", 4, "gray", 3, "light", 2, "black", 1)
		end,
		decor = {
			{ kind = "domes", size = 2.4, colors = { "silver", "gray" }, spots = { { 40, 0.85 }, { 60, 0.65 }, { 70, 0.45 } } },
		},
	},
	{
		id = "cristal",
		element = "leyenda",
		name = "Cristal",
		palette = {
			blue = { 40, 120, 220 },
			cyan = { 50, 185, 220 },
			sky = { 110, 200, 240 },
			clear = { 220, 240, 255, glass = 0.5 },
		},
		paint = function(c)
			return pick(c.rng, "blue", 3, "cyan", 3, "sky", 1, "clear", 1)
		end,
		decor = {
			{ kind = "shards", count = 12, colors = { "clear" }, size = 1.1 },
		},
		fx = { sparkles = { 200, 240, 255 } },
	},
	{
		id = "popo",
		element = { "terra", "mar", "oscuro" },
		name = "Popó",
		palette = {
			brown = { 115, 60, 35 },
			light = { 150, 85, 50 },
			dark = { 85, 45, 28 },
		},
		paint = function(c)
			-- Anillos como una montañita.
			return if math.floor((c.t + 1) * 4 + math.sin(c.theta) * 0.3) % 2 == 0 then pick(c.rng, "brown", 3, "dark", 1) else pick(c.rng, "light", 3, "brown", 1)
		end,
		decor = {
			{ kind = "domes", size = 1.4, colors = { "brown" }, spots = { { 0, 0.97 } } },
		},
	},
	{
		id = "legendario",
		element = "leyenda",
		name = "Legendario",
		palette = {
			red = { 215, 40, 40 },
			orange = { 245, 140, 40 },
			yellow = { 250, 215, 40 },
			lime = { 160, 210, 50 },
			green = { 40, 165, 70 },
			blue = { 40, 110, 210 },
			purple = { 120, 70, 190 },
			white = { 245, 248, 252 },
			cloud = { 190, 220, 245 },
			star = { 250, 240, 170 },
		},
		paint = function(c)
			-- Arcoíris de abajo hacia arriba, con una nube blanca arriba.
			if c.t > 0.5 and c.u > 0 and c.front then
				return pick(c.rng, "white", 2, "cloud", 1)
			end
			local bands = { "red", "orange", "yellow", "lime", "green", "blue", "purple" }
			return bands[math.clamp(math.floor((c.t + 1) / 2 * 7) + 1, 1, 7)]
		end,
		decor = {
			{ kind = "flakes", color = "star", size = 0.45, arms = 5, spots = { { -40, 0.35 }, { 10, 0.3 }, { 35, 0.55 }, { -15, -0.25 }, { 45, -0.1 }, { -60, 0.05 }, { 70, 0.4 } } },
		},
		fx = { sparkles = { 255, 245, 180 } },
	},
	{
		id = "platino",
		element = { "metal", "hielo" },
		name = "Platino",
		palette = {
			silver = { 185, 188, 195, shine = 0.35 },
			light = { 215, 218, 222, shine = 0.4 },
			gray = { 140, 143, 150, shine = 0.3 },
			red = { 230, 50, 50, neon = true },
			blue = { 60, 140, 255, neon = true },
		},
		paint = function(c)
			if c.front and math.abs(c.u) < 0.6 then
				return "gray" -- costura del frente
			end
			return pick(c.rng, "silver", 4, "light", 2, "gray", 1)
		end,
		decor = {
			{ kind = "dots", count = 4, size = 0.6, colors = { "red", "blue" }, avoidFront = true },
			{ kind = "flakes", color = "gray", size = 0.45, arms = 8, spots = { { 35, 0.1 } } },
		},
	},
	{
		id = "petroleo",
		element = { "mar", "oscuro" },
		name = "Petróleo",
		palette = {
			black = { 22, 22, 25, shine = 0.2 },
			dark = { 55, 58, 65, shine = 0.2 },
			slate = { 85, 90, 100 },
			cap = { 30, 30, 32 },
			ring = { 170, 175, 180, shine = 0.4 },
		},
		paint = function(c)
			if math.abs(c.t + 0.1) < 0.09 then
				return "slate"
			end
			return pick(c.rng, "black", 5, "dark", 2)
		end,
		decor = {
			{ kind = "cap", color = "ring", ring = "cap" },
		},
	},
	{
		id = "pirata",
		element = { "oscuro", "mar" },
		name = "Pirata",
		palette = {
			skin = { 130, 70, 40 },
			dark = { 105, 55, 35 },
			black = { 25, 25, 28 },
			white = { 240, 240, 235 },
			blue = { 40, 70, 140 },
			red = { 180, 40, 35 },
			gold = { 235, 185, 45, shine = 0.2 },
		},
		paint = function(c)
			if c.t > 0.5 then
				-- Sombrero negro con la calavera blanca.
				if c.front and math.abs(c.u) < 1.2 and c.v > 5.5 and c.v < 7.5 then
					return "white"
				end
				return "black"
			end
			if c.front then
				if math.abs(c.v - 2.5 - c.u * 0.35) < 0.6 then
					return "black" -- parche
				elseif math.abs(c.v + 1) < 0.6 and math.abs(c.u) < 2.5 then
					return "black" -- bigote
				elseif c.v < -4.5 and c.v > -6 and math.abs(c.u) < 1 then
					return "gold" -- hebilla
				end
			end
			if c.t < -0.45 and c.t > -0.7 then
				return pick(c.rng, "blue", 3, "red", 1)
			end
			return pick(c.rng, "skin", 3, "dark", 1)
		end,
	},
	{
		id = "planta_carnivora",
		element = { "naturaleza", "oscuro" },
		name = "Planta Carnívora",
		palette = {
			red = { 210, 35, 35 },
			dark = { 160, 25, 30 },
			green = { 40, 150, 60 },
			lime = { 140, 200, 60 },
			white = { 245, 240, 225 },
		},
		paint = function(c)
			if c.t > 0.15 then
				return pick(c.rng, "green", 3, "lime", 2)
			end
			return pick(c.rng, "red", 4, "dark", 1)
		end,
		decor = {
			{ kind = "fangs", color = "white", length = 1.4, ring = { t = 0.72, count = 9 } },
			{ kind = "leaves", color = "green", tip = "lime", clusters = { { theta = -80, t = 0.3, count = 3 }, { theta = 60, t = 0.85, count = 2 } } },
		},
	},
	{
		id = "perla",
		element = { "hielo", "metal" },
		name = "Perla",
		tiles = 0.35,
		palette = {
			white = { 245, 245, 242, shine = 0.25 },
			cream = { 235, 228, 210, shine = 0.25 },
			gray = { 210, 212, 215, shine = 0.25 },
		},
		paint = function(c)
			return pick(c.rng, "white", 4, "cream", 2, "gray", 1)
		end,
		fx = { sparkles = { 255, 250, 235 } },
	},
	{
		id = "oro",
		element = { "metal", "electrico" },
		name = "Oro",
		tiles = 0.35,
		palette = {
			gold = { 235, 180, 40, shine = 0.3 },
			light = { 245, 205, 80, shine = 0.3 },
			deep = { 215, 145, 40, shine = 0.3 },
		},
		paint = function(c)
			if c.t < -0.2 then
				return pick(c.rng, "deep", 3, "gold", 2)
			end
			return pick(c.rng, "gold", 4, "light", 2, "deep", 1)
		end,
		fx = { sparkles = { 255, 225, 120 } },
	},
	{
		id = "robot",
		element = { "llama", "metal" },
		name = "Robot",
		palette = {
			steel = { 140, 160, 185, shine = 0.25 },
			light = { 175, 190, 210, shine = 0.25 },
			gray = { 110, 120, 135, shine = 0.2 },
			dark = { 60, 65, 75 },
			lens = { 40, 160, 255, neon = true, glass = 0.1 },
		},
		paint = function(c)
			if c.rng:NextNumber() < 0.04 then
				return "dark" -- rejillas
			end
			return pick(c.rng, "steel", 4, "light", 2, "gray", 2)
		end,
		decor = {
			{ kind = "domes", size = 2.2, colors = { "lens" }, spots = { { -35, 0.45 } } },
			{ kind = "dots", count = 5, size = 0.6, colors = { "lens" }, avoidFront = true },
			{ kind = "flakes", color = "gray", size = 0.6, arms = 8, spots = { { 80, 0.1 } } },
		},
	},
	{
		id = "steampunk",
		element = { "llama", "metal" },
		name = "Steampunk",
		palette = {
			brass = { 200, 160, 70, shine = 0.2 },
			bronze = { 180, 120, 60, shine = 0.2 },
			copper = { 205, 120, 75, shine = 0.35 },
			gold = { 225, 185, 60, shine = 0.3 },
			gear = { 150, 90, 50, shine = 0.2 },
			red = { 220, 50, 40, neon = true },
		},
		paint = function(c)
			if c.t > 0.45 then
				return "copper" -- cúpula de cobre
			end
			return pick(c.rng, "brass", 3, "bronze", 2, "gold", 1)
		end,
		decor = {
			{ kind = "flakes", color = "gear", size = 1, arms = 10, spots = { { -70, -0.05 } } },
			{ kind = "horns", count = 1, colors = { "gold" }, t = 0.8, length = 2.6 },
			{ kind = "domes", size = 1.3, colors = { "red" }, spots = { { -45, 0.6 } } },
		},
	},
	{
		id = "medieval",
		element = { "llama", "metal" },
		name = "Medieval",
		palette = {
			red = { 215, 30, 30 },
			orange = { 240, 110, 30 },
			dark = { 170, 25, 25 },
			helmet = { 190, 192, 198, shine = 0.3 },
			slot = { 70, 72, 80 },
		},
		paint = function(c)
			-- Casco de caballero arriba, con la rejilla al frente.
			if c.t > 0.35 then
				if c.front and c.t < 0.6 and math.floor(c.x) % 2 == 0 then
					return "slot"
				end
				return "helmet"
			end
			return pick(c.rng, "red", 4, "orange", 1, "dark", 1)
		end,
		decor = {
			{ kind = "flakes", color = "helmet", size = 0.8, arms = 8, spots = { { -85, 0.35 } } },
		},
	},
}

Eggs.byId = {}
for _, def in Eggs.list do
	Eggs.byId[def.id] = def
end

return Eggs
