-- Todos los huevos (las fotos de referencia están en Escritorio/Huevos).
--
-- Cada huevo tiene:
--   element  su elemento (ver Elements.luau), o dos: { "fuego", "hielo" }. Le da el color a la etiqueta
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
		element = "agua",
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
		element = "planta",
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
		element = "dulce",
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
		element = "agua",
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
		element = "cosmico",
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
		element = "fuego",
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
		element = { "agua", "luz" },
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
		element = { "tierra", "fuego" },
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
		element = "tierra",
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
		element = { "electrico", "aire" },
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
		element = "planta",
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
		element = "planta",
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
		element = { "hielo", "aire" },
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
		element = { "fuego", "tierra" },
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
		element = "agua",
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
		element = { "tierra", "agua" },
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
		element = "aire",
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
		element = { "fuego", "planta" },
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
		element = { "fuego", "aire" },
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
		element = "aire",
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
		element = { "planta", "agua" },
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
		element = "magico",
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
		element = "luz",
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
		element = { "electrico", "luz" },
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
		element = { "metal", "fuego" },
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
		element = { "hielo", "tierra" },
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
		element = "hielo",
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
		element = { "fuego", "hielo" },
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
		element = "normal",
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
		element = "hielo",
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
		element = { "dulce", "hielo" },
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
		element = "aire",
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
		element = "planta",
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
}

Eggs.byId = {}
for _, def in Eggs.list do
	Eggs.byId[def.id] = def
end

return Eggs
