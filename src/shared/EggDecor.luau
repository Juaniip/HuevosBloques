-- Adornos que salen de la cáscara: aletas, espinas, corales, estrella, hojas, cúpulas, puntos y pie.
-- Cada uno recibe `ctx` (lo arma EggBuilder) y sus opciones desde Eggs.luau (los colores son
-- claves de la paleta del huevo).
--   ctx.surface(grados, t) -> posición sobre la cáscara y normal hacia afuera
--                             (grados: 0 = frente, 90 = derecha · t: -1 abajo, 1 arriba)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kit = require(ReplicatedStorage.Kit)

local Parts = Kit.Parts

local EggDecor = {}

local CYLINDER = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local AXIS = CFrame.Angles(0, math.pi / 2, 0) -- lleva el eje X de un cilindro hacia -Z (afuera)
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2) -- para un cilindro parado

local function style(part: BasePart, ctx, key: string): BasePart
	local entry = ctx.palette[key] or error(`[EggDecor] el color "{key}" no está en la paleta`)
	part.Color = entry.color
	if entry.neon then
		part.Material = Enum.Material.Neon
	end
	part.Transparency = entry.glass or 0
	part.CanTouch = false
	return part
end

-- Pieza lisa (cilindros, bolas, láminas).
local function smooth(ctx, name: string, size: Vector3, cf: CFrame, key: string, shape: Enum.PartType?)
	return style(Parts.shaped(name, size, cf, Color3.new(), ctx.model, shape or Enum.PartType.Block), ctx, key)
end

-- Ladrillo con studs.
local function brick(ctx, name: string, size: Vector3, cf: CFrame, key: string)
	return style(Parts.block(name, size, cf, Color3.new(), ctx.model), ctx, key)
end

-- Marco que mira hacia afuera de la cáscara: -Z = afuera, +Y = hacia arriba.
local function frame(pos: Vector3, normal: Vector3): CFrame
	local up = if math.abs(normal.Y) > 0.95 then Vector3.zAxis else Vector3.yAxis
	return CFrame.lookAt(pos, pos + normal, up)
end

local function choose(ctx, list: { string }): string
	return list[ctx.rng:NextInteger(1, #list)]
end

local function frontArea(theta: number, t: number): boolean
	return math.abs(theta) < 45 and math.abs(t) < 0.5
end

-- Lugar al azar sobre la cáscara, lejos de los que ya se usaron.
local function randomSpot(ctx, used: { { number } }, gap: number, avoid, tMin: number?, tMax: number?): (number, number)
	local theta, t = 0, 0
	for _ = 1, 40 do
		theta, t = ctx.rng:NextNumber(-180, 180), ctx.rng:NextNumber(tMin or -0.75, tMax or 0.8)
		local ok = not (avoid and avoid(theta, t))
		for _, spot in used do
			local d = math.abs(theta - spot[1]) % 360
			d = math.min(d, 360 - d)
			if (d / 40) ^ 2 + ((t - spot[2]) / 0.25) ^ 2 < gap * gap then
				ok = false
				break
			end
		end
		if ok then
			break
		end
	end
	table.insert(used, { theta, t })
	return theta, t
end

-- Espinas: { count, colors, length?, avoidFront? }
function EggDecor.spines(ctx, o)
	local used = {}
	for _ = 1, o.count or 12 do
		local pos, normal = ctx.surface(randomSpot(ctx, used, 0.8, o.avoidFront and frontArea))
		local f = frame(pos, normal) * AXIS
		local key = choose(ctx, o.colors)
		local length = o.length or 0.7
		smooth(ctx, "SpineBase", Vector3.new(0.2, 0.8, 0.8), f * CFrame.new(0.1, 0, 0), key, CYLINDER)
		smooth(ctx, "Spine", Vector3.new(length, 0.3, 0.3), f * CFrame.new(0.2 + length / 2, 0, 0), key, CYLINDER)
	end
end

-- Puntos redondos pegados a la cáscara: { count, colors, size?, avoidFront? }
function EggDecor.dots(ctx, o)
	local used = {}
	for _ = 1, o.count or 10 do
		local pos, normal = ctx.surface(randomSpot(ctx, used, 0.7, o.avoidFront and frontArea))
		local d = o.size or ctx.rng:NextNumber(0.9, 1.3)
		smooth(ctx, "Dot", Vector3.new(0.3, d, d), frame(pos, normal) * AXIS * CFrame.new(0.1, 0, 0), choose(ctx, o.colors), CYLINDER)
	end
end

-- Cúpulas / piedras semienterradas: { count, colors, size?, tMin?, tMax? }
function EggDecor.domes(ctx, o)
	local used = {}
	local size = o.size or 2.6
	for _ = 1, o.count or 6 do
		local pos, normal = ctx.surface(randomSpot(ctx, used, 1.3, nil, o.tMin, o.tMax))
		local key = choose(ctx, o.colors)
		smooth(ctx, "Dome", Vector3.one * size, CFrame.new(pos - normal * size * 0.2), key, BALL)
		smooth(ctx, "DomeStud", Vector3.new(0.3, 0.6, 0.6), frame(pos, normal) * AXIS * CFrame.new(size * 0.3 + 0.1, 0, 0), key, CYLINDER)
	end
end

-- Aletas a los dos costados: { base, colors, t? }
function EggDecor.fins(ctx, o)
	for _, side in { -1, 1 } do
		local pos, normal = ctx.surface(90 * side, o.t or 0)
		local f = frame(pos, Vector3.new(normal.X, 0, normal.Z).Unit)
		brick(ctx, "FinBase", Vector3.new(2, 2.4, 1.6), f * CFrame.new(0, 0, -0.4), o.base)
		for i, dy in { 0.9, 0, -0.9 } do
			local key = o.colors[(i - 1) % #o.colors + 1]
			brick(ctx, "Fin", Vector3.new(0.8, 0.5, 2), f * CFrame.new(0, dy, -2), key)
			brick(ctx, "FinTip", Vector3.new(0.8, 0.5, 1), f * CFrame.new(0, dy * 1.5, -3.3), key)
		end
	end
end

-- Brazo de cactus con flor: { theta, t, color, petals, center }
function EggDecor.cactusArm(ctx, o)
	local pos, normal = ctx.surface(o.theta or -70, o.t or 0.45)
	local f = frame(pos, Vector3.new(normal.X, 0, normal.Z).Unit)
	brick(ctx, "Arm", Vector3.new(2, 1.2, 2), f * CFrame.new(0, 0, -0.8), o.color)
	brick(ctx, "Arm", Vector3.new(2, 3.6, 2), f * CFrame.new(0, 2.4, -1.8), o.color)
	local top = f * CFrame.new(0, 4.2, -1.8)
	smooth(ctx, "FlowerBase", Vector3.new(0.4, 1.4, 1.4), top * CFrame.new(0, 0.2, 0) * UPRIGHT, o.petals, CYLINDER)
	for k = 0, 5 do
		smooth(ctx, "Petal", Vector3.new(0.7, 0.3, 1.1), top * CFrame.Angles(0, k * math.pi / 3, 0) * CFrame.new(0, 0.55, -0.75), o.petals)
	end
	smooth(ctx, "FlowerCenter", Vector3.new(0.5, 0.7, 0.7), top * CFrame.new(0, 0.75, 0) * UPRIGHT, o.center, CYLINDER)
end

local function branch(ctx, key: string, from: Vector3, dir: Vector3, length: number, thick: number, depth: number)
	local to = from + dir * length
	local mid = (from + to) / 2
	smooth(ctx, "Coral", Vector3.new(length, thick, thick), frame(mid, dir) * AXIS, key, CYLINDER)
	if depth <= 0 then
		smooth(ctx, "CoralTip", Vector3.one * thick * 1.7, CFrame.new(to), key, BALL)
		return
	end
	for _ = 1, ctx.rng:NextInteger(2, 3) do
		local side = dir:Cross(ctx.rng:NextUnitVector())
		if side.Magnitude < 0.05 then
			side = dir:Cross(Vector3.xAxis)
		end
		local turn = CFrame.fromAxisAngle(side.Unit, math.rad(ctx.rng:NextNumber(20, 45)))
		branch(ctx, key, to, turn:VectorToWorldSpace(dir), length * 0.72, thick * 0.8, depth - 1)
	end
end

-- Ramas de coral: { clusters = { { theta, t, color, length?, thick?, depth? } } }
function EggDecor.coral(ctx, o)
	for _, cluster in o.clusters do
		local pos, normal = ctx.surface(cluster.theta, cluster.t)
		local dir = (normal + Vector3.yAxis * 0.8).Unit
		branch(ctx, cluster.color, pos - normal * 0.3, dir, cluster.length or 2.2, cluster.thick or 0.45, cluster.depth or 2)
	end
end

-- Estrella de 5 puntas pegada al frente: { theta, t, color, size?, backing? (cuadrado de fondo) }
function EggDecor.star(ctx, o)
	local pos, normal = ctx.surface(o.theta or 0, o.t or 0)
	local s = o.size or 1
	local f = frame(pos, normal) * CFrame.new(0, 0, -0.3)
	for k = 0, 4 do
		local arm = f * CFrame.Angles(0, 0, k * math.rad(72))
		smooth(ctx, "StarArm", Vector3.new(0.9 * s, 1.1 * s, 0.35), arm * CFrame.new(0, 0.85 * s, 0), o.color)
		smooth(ctx, "StarTip", Vector3.new(0.45 * s, 0.7 * s, 0.35), arm * CFrame.new(0, 1.7 * s, 0), o.color)
	end
	smooth(ctx, "StarCore", Vector3.new(0.35, 1.3 * s, 1.3 * s), f * AXIS, o.color, CYLINDER)
	smooth(ctx, "StarStud", Vector3.new(0.25, 0.6, 0.6), f * AXIS * CFrame.new(0.3, 0, 0), o.color, CYLINDER)
	if o.backing then
		brick(ctx, "StarBacking", Vector3.new(4.2 * s, 4.2 * s, 0.4), f * CFrame.new(0, 0, 0.3), o.backing)
	end
end

-- Hojas que brotan: { color, tip?, stem? (cabito arriba), clusters = { { theta, t, count? } } }
function EggDecor.leaves(ctx, o)
	if o.stem then
		local top = ctx.baseY + ctx.height
		smooth(ctx, "Stem", Vector3.new(2, 0.6, 0.6), CFrame.new(0, top + 0.6, 0) * UPRIGHT, o.stem, CYLINDER)
		smooth(ctx, "StemTip", Vector3.new(1, 0.5, 0.5), CFrame.new(0.3, top + 1.8, 0) * CFrame.Angles(0, 0, math.rad(60)), o.stem, CYLINDER)
	end
	for _, cluster in o.clusters do
		local pos, normal = ctx.surface(cluster.theta, cluster.t)
		local flat = Vector3.new(normal.X, 0, normal.Z)
		local f = frame(pos, if flat.Magnitude > 0.1 then flat.Unit else Vector3.zAxis)
		local count = cluster.count or 2
		for i = 1, count do
			local yaw = (i - (count + 1) / 2) * 30
			local leaf = f * CFrame.Angles(0, math.rad(yaw), 0) * CFrame.Angles(math.rad(ctx.rng:NextNumber(40, 65)), 0, 0)
			smooth(ctx, "Leaf", Vector3.new(0.9, 0.25, 2.4), leaf * CFrame.new(0, 0, -1.1), o.color)
			smooth(ctx, "LeafTip", Vector3.new(0.6, 0.25, 1.2), leaf * CFrame.new(0, 0.3, -2.6) * CFrame.Angles(math.rad(20), 0, 0), o.tip or o.color)
		end
	end
end

-- Copos de nieve chatos: { color, size?, arms?, spots = { { theta, t } } }
function EggDecor.flakes(ctx, o)
	local s = o.size or 1
	local arms = o.arms or 6
	for _, spot in o.spots do
		local pos, normal = ctx.surface(spot[1], spot[2])
		local f = frame(pos, normal) * CFrame.new(0, 0, -0.25)
		for k = 0, arms - 1 do
			local arm = f * CFrame.Angles(0, 0, k * 2 * math.pi / arms)
			smooth(ctx, "FlakeArm", Vector3.new(0.35 * s, 1.7 * s, 0.25), arm * CFrame.new(0, 0.85 * s, 0), o.color)
			for _, side in { -1, 1 } do
				local twig = arm * CFrame.new(0, 1.1 * s, 0) * CFrame.Angles(0, 0, side * 0.8) * CFrame.new(0, 0.3 * s, 0)
				smooth(ctx, "FlakeTwig", Vector3.new(0.25 * s, 0.6 * s, 0.25), twig, o.color)
			end
		end
		smooth(ctx, "FlakeCore", Vector3.new(0.3, 0.8 * s, 0.8 * s), f * AXIS, o.color, CYLINDER)
	end
end

-- Pinitos alrededor: { count, t, color, trunk }
function EggDecor.pines(ctx, o)
	local used = {}
	for _ = 1, o.count or 8 do
		local theta = randomSpot(ctx, used, 0.6, frontArea)
		local pos, normal = ctx.surface(theta, o.t or 0.15)
		local base = CFrame.new(pos + Vector3.new(normal.X, 0, normal.Z).Unit * 0.4)
		local scale = ctx.rng:NextNumber(0.8, 1.2)
		smooth(ctx, "PineTrunk", Vector3.new(0.6, 0.35, 0.35), base * CFrame.new(0, 0.3, 0) * UPRIGHT, o.trunk, CYLINDER)
		for i, width in { 1.3, 1.0, 0.7, 0.4 } do
			local y = 0.6 + (i - 1) * 0.55 * scale
			smooth(ctx, "Pine", Vector3.new(0.6 * scale, width * scale, width * scale), base * CFrame.new(0, y + 0.3, 0) * UPRIGHT, o.color, CYLINDER)
		end
	end
end

-- Cuernos que salen de arriba: { count, colors, t?, length? }
function EggDecor.horns(ctx, o)
	local count = o.count or 8
	local length = o.length or 1.6
	for k = 1, count do
		local theta = (k - 1) * 360 / count + ctx.rng:NextNumber(-8, 8)
		local pos, normal = ctx.surface(theta, (o.t or 0.75) + ctx.rng:NextNumber(-0.08, 0.12))
		local dir = (normal + Vector3.yAxis * 0.6).Unit
		local key = choose(ctx, o.colors)
		local f = frame(pos, dir) * AXIS
		smooth(ctx, "Horn", Vector3.new(length * 0.55, 0.7, 0.7), f * CFrame.new(length * 0.25, 0, 0), key, CYLINDER)
		smooth(ctx, "HornTip", Vector3.new(length * 0.5, 0.4, 0.4), f * CFrame.new(length * 0.75, 0, 0), key, CYLINDER)
		smooth(ctx, "HornPoint", Vector3.one * 0.35, f * CFrame.new(length, 0, 0), key, BALL)
	end
end

-- Visor que envuelve el huevo: { theta, t, color, rim, lens }
function EggDecor.visor(ctx, o)
	for i = -1, 1 do
		local pos, normal = ctx.surface((o.theta or 0) + i * 24, o.t or 0.6)
		local f = frame(pos, Vector3.new(normal.X, 0, normal.Z).Unit)
		smooth(ctx, "VisorRim", Vector3.new(2.6, 2.3, 1), f * CFrame.new(0, 0, -0.2), o.rim)
		smooth(ctx, "Visor", Vector3.new(2.7, 1.8, 1.1), f * CFrame.new(0, 0, -0.35), o.color)
		if i == 0 then
			smooth(ctx, "Lens", Vector3.new(0.3, 1, 1), f * AXIS * CFrame.new(0.95, 0, 0), o.lens, CYLINDER)
		end
	end
end

-- Corona en la punta: { color, gem }
function EggDecor.crown(ctx, o)
	local top = CFrame.new(0, ctx.baseY + ctx.height - 0.4, 0)
	for k = 0, 7 do
		local side = top * CFrame.Angles(0, k * math.pi / 4, 0) * CFrame.new(0, 0.5, -1.7)
		brick(ctx, "Crown", Vector3.new(1.4, 1.2, 0.5), side, o.color)
		if k % 2 == 0 then
			smooth(ctx, "CrownSpike", Vector3.new(0.5, 1.4, 0.4), side * CFrame.new(0, 1.2, 0), o.color)
		end
	end
	local front = top * CFrame.new(0, 0.6, -1.95)
	smooth(ctx, "CrownGemRing", Vector3.new(0.3, 1.1, 1.1), front * AXIS, o.color, CYLINDER)
	smooth(ctx, "CrownGem", Vector3.new(0.35, 0.7, 0.7), front * AXIS * CFrame.new(0.1, 0, 0), o.gem, CYLINDER)
end

-- Alas de plumas atrás, a los costados: { colors, t? }
function EggDecor.wings(ctx, o)
	for _, side in { -1, 1 } do
		local pos, normal = ctx.surface(side * 115, o.t or 0.35)
		local f = frame(pos, Vector3.new(normal.X, 0, normal.Z).Unit)
		for i = 1, 7 do
			local length = 6.5 - i * 0.45
			local key = o.colors[(i - 1) % #o.colors + 1]
			local feather = f * CFrame.Angles(math.rad(8 + i * 10), 0, 0) * CFrame.new(0, (i - 4) * 0.15, -length / 2 - 0.3)
			brick(ctx, "Feather", Vector3.new(1, 0.4, length), feather, key)
		end
	end
end

-- Flor de loto con hojas en la punta: { leaf, petals, inner? }
function EggDecor.lotus(ctx, o)
	local top = CFrame.new(0, ctx.baseY + ctx.height - 0.3, 0)
	for k = 0, 5 do
		local leaf = top * CFrame.Angles(0, k * math.pi / 3 + 0.3, 0) * CFrame.Angles(math.rad(-12), 0, 0)
		smooth(ctx, "LotusLeaf", Vector3.new(1.8, 0.3, 3), leaf * CFrame.new(0, 0, -2.2), o.leaf)
	end
	for ring, data in { { 8, 1.3, 35, o.petals }, { 6, 0.6, 62, o.inner or o.petals } } do
		for k = 0, data[1] - 1 do
			local petal = top
				* CFrame.new(0, 0.5 + ring * 0.3, 0)
				* CFrame.Angles(0, k * 2 * math.pi / data[1] + ring * 0.4, 0)
				* CFrame.new(0, 0, -data[2])
				* CFrame.Angles(math.rad(data[3]), 0, 0)
			smooth(ctx, "Petal", Vector3.new(1, 0.3, 1.8), petal * CFrame.new(0, 0, -0.7), data[4])
		end
	end
	smooth(ctx, "LotusCenter", Vector3.new(0.5, 0.8, 0.8), top * CFrame.new(0, 1.2, 0) * UPRIGHT, o.inner or o.petals, CYLINDER)
end

-- Mariposas posadas: { colors, spots = { { theta, t } } }
function EggDecor.butterflies(ctx, o)
	for _, spot in o.spots do
		local pos, normal = ctx.surface(spot[1], spot[2])
		local f = frame(pos, Vector3.new(normal.X, 0, normal.Z).Unit) * CFrame.new(0, 0.6, -1.2)
		smooth(ctx, "ButterflyBody", Vector3.new(1.6, 0.35, 0.35), f * UPRIGHT, o.colors[1], CYLINDER)
		for _, side in { -1, 1 } do
			local wing = f * CFrame.Angles(0, side * math.rad(35), 0)
			brick(ctx, "Wing", Vector3.new(1.6, 1.6, 0.3), wing * CFrame.new(side * 1, 0.5, 0) * CFrame.Angles(0, 0, side * 0.35), o.colors[1])
			brick(ctx, "Wing", Vector3.new(1.1, 1.1, 0.3), wing * CFrame.new(side * 0.8, -0.6, 0) * CFrame.Angles(0, 0, -side * 0.3), o.colors[2] or o.colors[1])
		end
	end
end

-- Pie donde se apoya el huevo. Devuelve su alto (el huevo empieza arriba).
function EggDecor.stand(ctx, o): number
	local height = 1.2
	smooth(ctx, "Stand", Vector3.new(height, 7, 7), CFrame.new(0, height / 2, 0) * UPRIGHT, o.color, CYLINDER)
	smooth(ctx, "StandRim", Vector3.new(0.3, 7.6, 7.6), CFrame.new(0, 0.15, 0) * UPRIGHT, o.color, CYLINDER)
	return height
end

return EggDecor
