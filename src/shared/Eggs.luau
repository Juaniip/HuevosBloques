-- Los 16 huevos (las fotos de referencia están en Escritorio/Huevos).
--
-- Cada huevo tiene:
--   palette  colores por nombre: { r, g, b }, con neon = true o glass = transparencia si hace falta
--   paint(c) devuelve el nombre del color de cada ladrillo. `c` trae:
--              c.t      altura de -1 (abajo) a 1 (arriba)
--              c.theta  ángulo alrededor (0 = frente, en radianes)
--              c.u, c.v posición sobre el frente en studs, con (0, 0) en el centro
--              c.front  true si la celda está del lado de adelante (c.z < 0)
--              c.x, c.y, c.z, c.row, c.rng, c.noise(escala, capa?) -> -1..1 (manchas suaves)
--   tiles    parte de ladrillos lisos, sin studs (0 a 1; 0.25 si no se pone)
--   decor    adornos (ver EggDecor.luau) · stand: pie · fx: fuego, chispas, brillos, luz
local Paint = require(script.Parent.Paint)

local pick = Paint.pick

local Eggs = {}

Eggs.list = {
	{
		id = "caballito_mar",
		name = "Caballito de Mar",
		icon = "🐴",
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
		name = "Cactus",
		icon = "🌵",
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
		name = "Chicle",
		icon = "🍬",
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
		name = "Coral",
		icon = "🪸",
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
		name = "Eléctrico",
		icon = "⚡",
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
		name = "Estrella",
		icon = "⭐",
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
		name = "Fuego",
		icon = "🔥",
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
		name = "Pez Linterna",
		icon = "🐟",
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
		name = "Roca Flamante",
		icon = "🪨",
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
		name = "Tierra",
		icon = "🟫",
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
		name = "Tormenta",
		icon = "⛈️",
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
		name = "Tropical",
		icon = "🌴",
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
		name = "Vegetal",
		icon = "🌿",
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
		name = "Ventisca",
		icon = "🌨️",
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
		name = "Volcán",
		icon = "🌋",
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
		name = "Hielo",
		icon = "🧊",
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
}

Eggs.byId = {}
for _, def in Eggs.list do
	Eggs.byId[def.id] = def
end

return Eggs
