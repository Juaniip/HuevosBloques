-- Arma un huevo de bloques a partir de su definición (ver Eggs.luau).
--   EggBuilder.build(def, parent, cframe?) -> Model   (cframe = dónde va la base del huevo)
-- El huevo es una cáscara de ladrillos con studs: se calcula la forma por capas, se pinta cada
-- celda con la función `paint` del huevo y las celdas vecinas del mismo color se juntan en
-- ladrillos de 1 a 4 de largo. Después se agregan los adornos y los efectos.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)
local EggDecor = require(script.Parent.EggDecor)

local Lego = Kit.Lego
local Particles = Kit.Particles

local EggBuilder = {}

EggBuilder.Shape = {
	radius = 6, -- en studs (12 de ancho)
	rows = 14, -- capas de ladrillos
	brick = 1.2, -- alto de un ladrillo
	fullness = 2.3, -- 2 = elipse; más alto = más panzón
	taper = 0.14, -- cuánto se afina la punta de arriba
}

-- Largo de cada ladrillo (en studs) y qué tan seguido sale.
local LENGTHS = { { 1, 2 }, { 2, 4 }, { 3, 1 }, { 4, 2 } }

local function radiusAt(shape, t: number): number
	local p = shape.fullness
	local base = math.max(1 - math.abs(t) ^ p, 0) ^ (1 / p)
	return shape.radius * base * (1 - shape.taper * t)
end

local function hash(text: string): number
	local h = 7
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % 2147483647
	end
	return h
end

local function resolvePalette(raw)
	local palette = {}
	for key, entry in raw do
		palette[key] = {
			color = Color3.fromRGB(entry[1], entry[2], entry[3]),
			neon = entry.neon,
			glass = entry.glass,
		}
	end
	return palette
end

local function pickLength(rng: Random): number
	local total = 0
	for _, option in LENGTHS do
		total += option[2]
	end
	local roll = rng:NextNumber() * total
	for _, option in LENGTHS do
		roll -= option[2]
		if roll <= 0 then
			return option[1]
		end
	end
	return 1
end

function EggBuilder.build(def, parent: Instance?, cframe: CFrame?): Model
	local shape = EggBuilder.Shape
	local rows, unit = shape.rows, shape.brick
	local height = rows * unit
	local rng = Random.new(def.seed or hash(def.id))
	local palette = resolvePalette(def.palette)
	local tileChance = def.tiles or 0.25

	local model = Instance.new("Model")
	model.Name = def.name
	model:SetAttribute("EggId", def.id)

	local ctx = { model = model, palette = palette, rng = rng, shape = shape, height = height, baseY = 0 }

	-- Pie (lo construye antes para saber a qué altura empieza el huevo).
	if def.stand then
		ctx.baseY = EggDecor.stand(ctx, def.stand)
	end
	local baseY = ctx.baseY

	-- Forma: radio de cada capa y qué celdas quedan adentro.
	local radii = {}
	for row = 0, rows - 1 do
		radii[row] = radiusAt(shape, ((row + 0.5) / rows) * 2 - 1)
	end
	local M = math.ceil(shape.radius) + 1
	local function inside(k: number, j: number, row: number): boolean
		if row < 0 or row >= rows then
			return false
		end
		local x, z = k + 0.5, j + 0.5
		return x * x + z * z <= radii[row] * radii[row]
	end

	-- Punto de la cáscara: `theta` en grados (0 = frente), `t` de -1 (abajo) a 1 (arriba).
	-- Devuelve la posición sobre los ladrillos (no sobre la curva ideal) y la normal hacia afuera.
	function ctx.surface(theta: number, t: number): (Vector3, Vector3)
		t = math.clamp(t, -0.97, 0.97)
		local a = math.rad(theta)
		local dir = Vector3.new(math.sin(a), 0, -math.cos(a))
		local slope = (radiusAt(shape, t + 0.02) - radiusAt(shape, t - 0.02)) / 0.04 * (2 / height)
		local normal = (dir - Vector3.yAxis * slope).Unit
		local ideal = Vector3.new(0, baseY + (t + 1) / 2 * height, 0) + dir * radiusAt(shape, t)
		local point = ideal + normal * 1.5
		for _ = 1, 40 do
			local row = math.floor((point.Y - baseY) / unit)
			if inside(math.floor(point.X), math.floor(point.Z), row) then
				break
			end
			point -= normal * 0.1
		end
		return point, normal
	end

	-- Pintura: solo las celdas de la superficie (el huevo es hueco).
	local seedX, seedZ = rng:NextNumber(0, 500), rng:NextNumber(0, 500)
	local c = { rng = rng }
	function c.noise(scale: number, layer: number?): number
		return math.noise(c.x * scale + seedX + (layer or 0) * 31.7, c.y * scale, c.z * scale + seedZ)
	end

	local cells = {}
	for row = 0, rows - 1 do
		cells[row] = {}
		for k = -M, M - 1 do
			for j = -M, M - 1 do
				local surface = inside(k, j, row)
					and not (
						inside(k + 1, j, row)
						and inside(k - 1, j, row)
						and inside(k, j + 1, row)
						and inside(k, j - 1, row)
						and inside(k, j, row + 1)
						and inside(k, j, row - 1)
					)
				if surface then
					c.x, c.z = k + 0.5, j + 0.5
					c.y = row * unit + unit / 2
					c.row = row
					c.t = ((row + 0.5) / rows) * 2 - 1
					c.theta = math.atan2(c.x, -c.z)
					c.u, c.v = c.x, c.y - height / 2
					c.front = c.z < 0
					local key = def.paint(c)
					if not palette[key] then
						warn(`[EggBuilder] {def.id}: el color "{tostring(key)}" no está en la paleta`)
						key = next(palette)
					end
					cells[row][k * 100 + j] = key
				end
			end
		end
	end

	local function brick(size: Vector3, position: Vector3, key: string)
		local entry = palette[key]
		local part = Instance.new("Part")
		part.Name = "Brick"
		part.Anchored = true
		part.CanTouch = false
		part.Size = size
		part.CFrame = CFrame.new(position)
		part.Color = entry.color
		part.Material = if entry.neon then Enum.Material.Neon else Enum.Material.Plastic
		part.Transparency = entry.glass or 0
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		if rng:NextNumber() >= tileChance then
			Lego.apply(part)
		end
		part.Parent = model
	end

	-- Junta celdas iguales en ladrillos: al frente y atrás van a lo ancho (X); a los costados, a lo hondo (Z).
	local function alongX(k: number, j: number): boolean
		return math.abs(j + 0.5) >= math.abs(k + 0.5)
	end
	for row = 0, rows - 1 do
		local layer = cells[row]
		local y = baseY + row * unit + unit / 2
		for _, axisX in { true, false } do
			for a = -M, M - 1 do
				local b = -M
				while b <= M - 1 do
					local k, j = if axisX then b else a, if axisX then a else b
					local key = layer[k * 100 + j]
					if key and alongX(k, j) == axisX then
						local start = b
						while true do
							local nk, nj = if axisX then b + 1 else a, if axisX then a else b + 1
							if b + 1 <= M - 1 and layer[nk * 100 + nj] == key and alongX(nk, nj) == axisX then
								b += 1
							else
								break
							end
						end
						local pos = start
						local remaining = b - start + 1
						while remaining > 0 do
							local length = math.min(remaining, pickLength(rng))
							local center = pos + length / 2
							if axisX then
								brick(Vector3.new(length, unit, 1), Vector3.new(center, y, a + 0.5), key)
							else
								brick(Vector3.new(1, unit, length), Vector3.new(a + 0.5, y, center), key)
							end
							pos += length
							remaining -= length
						end
					end
					b += 1
				end
			end
		end
	end

	-- Adornos.
	for _, item in def.decor or {} do
		local builder = EggDecor[item.kind]
		if builder then
			builder(ctx, item)
		else
			warn(`[EggBuilder] {def.id}: no existe el adorno "{item.kind}"`)
		end
	end

	-- Efectos: salen de una caja invisible del tamaño del huevo.
	local fx = def.fx
	if fx then
		local aura = Instance.new("Part")
		aura.Name = "Aura"
		aura.Anchored = true
		aura.CanCollide = false
		aura.CanQuery = false
		aura.CanTouch = false
		aura.Transparency = 1
		aura.Size = Vector3.new(shape.radius * 2, height, shape.radius * 2)
		aura.CFrame = CFrame.new(0, baseY + height / 2, 0)
		aura.Parent = model
		local function color(rgb)
			return Color3.fromRGB(rgb[1], rgb[2], rgb[3])
		end
		if fx.fire then
			local top = Instance.new("Attachment")
			top.Position = Vector3.new(0, height / 2 - 0.5, 0)
			top.Parent = aura
			Particles.fire(top, { Rate = 18, Size = NumberSequence.new(2, 0.3), Speed = NumberRange.new(2, 4) })
		end
		if fx.sparks then
			Particles.sparks(aura, { Color = ColorSequence.new(color(fx.sparks)), Rate = 8, SpreadAngle = Vector2.new(180, 180) })
		end
		if fx.sparkles then
			Particles.sparkles(aura, { Color = ColorSequence.new(color(fx.sparkles)), Rate = 6, SpreadAngle = Vector2.new(180, 180) })
		end
		if fx.light then
			Particles.light(aura, color(fx.light), fx.light[4] or 16, fx.light[5] or 1.5)
		end
	end

	model.WorldPivot = CFrame.new()
	if cframe then
		model:PivotTo(cframe)
	end
	model.Parent = parent
	return model
end

return EggBuilder
