-- Ayudas para pintar huevos (las usan las funciones `paint` de Eggs.luau).
--   Paint.pick(rng, "azul", 3, "blanco", 1)   -- elige un color según pesos
--   Paint.nearLine(u, v, puntos, grosor)       -- true si (u, v) cae sobre una línea quebrada
--   Paint.oval(c, grados, ancho, alto, v?)     -- óvalo a los dos costados: < 1 adentro, 0 en el centro
local Paint = {}

function Paint.pick(rng: Random, ...): string
	local args = { ... }
	local total = 0
	for i = 2, #args, 2 do
		total += args[i]
	end
	local roll = rng:NextNumber() * total
	for i = 1, #args, 2 do
		roll -= args[i + 1]
		if roll <= 0 then
			return args[i]
		end
	end
	return args[1]
end

local function segmentDistance(px: number, py: number, ax: number, ay: number, bx: number, by: number): number
	local dx, dy = bx - ax, by - ay
	local s = math.clamp(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy), 0, 1)
	local cx, cy = ax + dx * s - px, ay + dy * s - py
	return math.sqrt(cx * cx + cy * cy)
end

-- `points` = { {u, v}, {u, v}, ... } en studs, con (0, 0) en el centro del frente del huevo.
function Paint.nearLine(u: number, v: number, points: { { number } }, thickness: number): boolean
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if segmentDistance(u, v, a[1], a[2], b[1], b[2]) < thickness then
			return true
		end
	end
	return false
end

-- Óvalo centrado a `theta` grados del frente, a la izquierda y a la derecha (ancho y alto en studs).
function Paint.oval(c, theta: number, width: number, height: number, v: number?): number
	local au = (math.abs(math.deg(c.theta)) - theta) / 9.5
	local av = c.v - (v or 0)
	return (au / width) ^ 2 + (av / height) ^ 2
end

return Paint
